pragma solidity ^0.4.24;

library UserRepositoryFactory {
    function createUserRepository() internal returns(address) {
        return new UserRepository();
    }
}

contract UserRepository {
    address owner;
    
    // map from user address to users index
    mapping(address => uint) users_index;
    
    // all users
    // index 0 stores no user.
    User[] users;
    
    struct User {
        address addr;
        uint64 add_time;
    }
    
    constructor() public {
        owner = tx.origin;
        users.push(User(0,0));
    }

    function addUsers(address[] _addrs) public returns(bool) {
        require(tx.origin == owner);
        
        for (uint i = 0; i < _addrs.length; i++) {
            if (0 == users_index[_addrs[i]]) {
                users.push(User({addr:_addrs[i], add_time: uint64(now)}));
                users_index[_addrs[i]] = users.length - 1;
            }
        }
        
        return true;
    }
    
    function hasUser(address _addr) public view returns(bool) {
        return users_index[_addr] > 0;
    }

    function hasUsers(address[] _users) public view returns(bool) {
        for (uint i = 0; i < _users.length; i++) {
            if (users_index[_users[i]] == 0) {
                return false;
            }
        }
        return true;
    }
    
    function getUser(address _addr) public view returns(address _o_addr, uint64 _add_time) {
        uint index = users_index[_addr];
        if (index > 0) {
            User memory v = users[index];
            _o_addr = v.addr;
            _add_time = v.add_time;
        }
    }
    
    function count() public view returns(uint64) {
        return uint64(users.length - 1);
    }
    
    function countBefore(uint64 time) public view returns(uint64) {
        uint len = users.length;
        
        if (len <= 1) {
            return 0;
        }
        
        // binary search
        uint index_min = 1;
        uint index_max = len - 1;
        uint index_mid = (index_min + index_max) / 2;
        
        while (true) {
            if (index_max - index_min <= 1) {
                break;
            }
            if (users[index_mid].add_time <= time) {
                index_min = index_mid;
            } else {
                index_max = index_mid;
            }
            index_mid = (index_min + index_max) / 2;
        }
        
        if (users[index_min].add_time > time) {
            return uint64(index_min - 1);
        } else if (users[index_max].add_time > time) {
            return uint64(index_max - 1);
        } else {
            return uint64(index_max);
        }
    }
}
