pragma solidity ^0.4.24;

library Usergroup {
  struct Manager {
    mapping(address => uint32[]) usergroupsICreated;
    mapping(address => uint32[]) usergroupsIAmIn;
    mapping(bytes32 => uint32) nameToUsergroupIndex;
    Record[] usergroups;
  }

  struct Record {
    address owner;
    bytes32 name;
    string description;
    uint32 id;
    uint32 create_time;
    Member[] members;
    mapping(address => uint32) members_index;
  }

  struct Member {
    address addr;
    uint32 add_time;
  }

  enum UsergroupCategory {ICreated, IAmIn}

  event CreateUsergroup(uint32 id, bytes32 name);

  /**
    * @dev create usergroup
    * 
    * NOTE: this function consumes gas, defining as internal to inline bytecode into contract
    */
  function createUsergroup(Manager storage self, bytes32 _name, string _description, address[] _members)
  internal
  {
    // 0 index store nothing
    if (self.usergroups.length == 0) {
      self.usergroups.length = 1;
      self.usergroups[0].members.length = 1;
      self.nameToUsergroupIndex[bytes32(0)] = ~uint32(0);
    }

    require(self.nameToUsergroupIndex[_name] == 0, 'usergroup name has been used.');

    uint32 index = uint32(self.usergroups.length);
    uint32 _now = uint32(now);

    self.usergroups.length++;

    Record storage ug = self.usergroups[index];

    ug.owner = msg.sender;
    ug.name = _name;
    ug.description = _description;
    ug.id = uint32(index);
    ug.create_time = _now;
    ug.members.length = 1;

    uint32 member_index;

    member_index = uint32(ug.members.length);
    ug.members_index[msg.sender] = member_index;
    ug.members.length++;
    ug.members[member_index].addr = msg.sender;
    ug.members[member_index].add_time = _now;

    uint32 i = 0;
    address addr;

    for (i = 0; i < _members.length; i++) {
      addr = _members[i];
      if (ug.members_index[addr] == 0) {
        member_index = uint32(ug.members.length);
        ug.members_index[addr] = member_index;
        ug.members.length++;
        ug.members[member_index].addr = addr;
        ug.members[member_index].add_time = _now;

        self.usergroupsIAmIn[addr].push(index);
      }
    }

    self.nameToUsergroupIndex[_name] = index;
    self.usergroupsICreated[msg.sender].push(index);
    self.usergroupsIAmIn[msg.sender].push(index);

    emit CreateUsergroup(ug.id, ug.name);
  }

  /**
    * @return _total total number of usergroups in this category
    * @return _mixes from right to left per uint32, uint32[0]: id, uint32[1]: create_time, uint32[2]: members_num
    * @return _names usergroup name
    */
  function paginateUsergroups(Manager storage self, UsergroupCategory c, uint32 _page, uint32 _pagesize)
    public
    view
    returns(uint32 _total, bytes32[] _mixes, bytes32[] _names)
  {
    _page = _page < 1 ? 1 : _page;
    _pagesize = _pagesize < 1 ? 10 : _pagesize;

    uint32[] storage usergroupIndices = (c == UsergroupCategory.ICreated) ? self.usergroupsICreated[msg.sender] : self.usergroupsIAmIn[msg.sender];
    _total = uint32(usergroupIndices.length);

    uint32 page_start = (_page - 1) * _pagesize;
    uint32 page_end = (_page * _pagesize) < _total ? (_page * _pagesize) : _total;
    uint32 page_len = page_end > page_start ? page_end - page_start : 0;

    _mixes = new bytes32[](page_len);
    _names = new bytes32[](page_len);

    for (uint32 i = 0; i < page_len; i++) {
      Record storage ug = self.usergroups[usergroupIndices[_total - 1 - page_start - i]];

      _mixes[i] = bytes32((uint(ug.id) << 32*0) | (uint(ug.create_time) << 32*1) | (ug.members.length - 1) << 32*2);
      _names[i] = ug.name;
    }
  }

  function hasUsergroupName(Manager storage self, bytes32 _name)
  public
  view
  returns(bool)
  {
    return self.nameToUsergroupIndex[_name] > 0;
  }

  function getUsergroup(Manager storage self, uint32 _id)
  public
  view
  returns(address _owner, bytes32 _name, string _description, bytes32 _mix, address[] _members, uint32[] _members_time)
  {
    require(_id > 0 && _id < self.usergroups.length, 'usergroup id invalid');

    Record memory ug = self.usergroups[_id];

    _owner = ug.owner;
    _name = ug.name;
    _description = ug.description;
    _mix = bytes32((uint(ug.id) << 32*0) | (uint(ug.create_time) << 32*1) | (ug.members.length - 1) << 32*2);

    _members = new address[](ug.members.length - 1);
    _members_time = new uint32[](ug.members.length - 1);

    for (uint32 i = 1; i < ug.members.length; i++) {
      _members[i - 1] = ug.members[i].addr;
      _members_time[i - 1] = ug.members[i].add_time;
    }
  }

  function hasMember(Manager storage self, address _member_addr, uint32 _usergroup_id)
  public
  view
  returns(bool _has)
  {
    return self.usergroups[_usergroup_id].members_index[_member_addr] > 0;
  }

  function hasMemberBefore(Manager storage self, address _member_addr, uint32 _usergroup_id, uint32 _time)
  public
  view
  returns(bool _has)
  {
    Record storage ug = self.usergroups[_usergroup_id];
    uint32 add_time = ug.members[ug.members_index[_member_addr]].add_time;
    return add_time > 0 && add_time < _time;
  }

  function membersNum(Manager storage self, uint32 _usergroup_id)
  public
  view
  returns(uint32 _num)
  {
    return uint32(self.usergroups[_usergroup_id].members.length - 1);
  }

  function membersNumBefore(Manager storage self, uint32 _usergroup_id, uint32 _time)
  public
  view
  returns(uint32 _num)
  {
    Member[] storage members = self.usergroups[_usergroup_id].members;
    uint32 len = uint32(members.length);

    if (len <= 1) {
      return 0;
    }

    // short cut
    if (members[len - 1].add_time < _time) {
      return len - 1;
    }

    // binary search
    uint32 index_min = 1;
    uint32 index_max = len - 1;
    uint32 index_mid = (index_min + index_max) / 2;

    while (true) {
      if (index_max - index_min <= 1) {
        break;
      }
      if (members[index_mid].add_time < _time) {
        index_min = index_mid;
      } else {
        index_max = index_mid;
      }
      index_mid = (index_min + index_max) / 2;
    }

    if (members[index_min].add_time >= _time) {
      return index_min - 1;
    } else if (members[index_max].add_time >= _time) {
      return index_max - 1;
    } else {
      return index_max;
    }
  }
}
