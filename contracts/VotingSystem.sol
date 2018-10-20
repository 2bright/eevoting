pragma solidity ^0.4.24;

import "./Usergroup.sol";
import "./Voting.sol";

contract VotingSystem {
  using Usergroup for Usergroup.Manager;
  Usergroup.Manager usergroups;

  using Voting for Voting.Manager;
  Voting.Manager votings;

  function createUsergroup(bytes32 _name, string _description, address[] _members)
  public
  {
    usergroups.createUsergroup(_name, _description, _members);
  }

  function hasUsergroupName(bytes32 _name)
  public
  view
  returns(bool)
  {
    return usergroups.hasUsergroupName(_name);
  }

  function getUsergroup(uint32 _id)
  public
  view
  returns(address _owner, bytes32 _name, string _description, bytes32 _mix, address[] _members, uint32[] _members_time)
  {
    return usergroups.getUsergroup(_id);
  }

  function getUsergroupsICreated(uint32 _page, uint32 _pagesize)
  public
  view
  returns(uint32 _total, bytes32[] _mixes, bytes32[] _names)
  {
    return usergroups.paginateUsergroups(Usergroup.UsergroupCategory.ICreated, _page, _pagesize);
  }

  function getUsergroupsIAmIn(uint32 _page, uint32 _pagesize)
  public
  view
  returns(uint32 _total, bytes32[] _mixes, bytes32[] _names)
  {
    return usergroups.paginateUsergroups(Usergroup.UsergroupCategory.IAmIn, _page, _pagesize);
  }

  function getVotingNonce()
  public
  view
  returns(uint32 _nonce)
  {
    return votings.getVotingNonce();
  }

  function validateVotingParams(bytes32[2] _params, bytes _title)
  public
  view
  returns(string _error)
  {
    Voting.Params memory params;
    (params, _error) = Voting.parseParams(_params, _title, usergroups);
  }

  function publishVoting(bytes32 _meta, bytes _slice, bytes32[2] _params, bytes _title)
  public
  {
    votings.publishVoting(_meta, _slice, _params, _title, usergroups);
  }

  function publishVotingSlice(bytes32 _meta, bytes _slice)
  public
  {
    votings.publishVotingSlice(_meta, _slice, usergroups);
  }

  function getVotingMix(uint32 _id)
  public
  view
  returns(bytes _title, bytes32[] _options_mix, bytes32[4] _mixes)
  {
    return votings.getVotingMix(_id);
  }

  function getVotingSlice(uint32 _voting_id, uint32 _slice_index_in)
  public
  view
  returns(uint32 _slices_num, uint32 _slice_index, bytes _slice)
  {
    return votings.getVotingSlice(_voting_id, _slice_index_in);
  }

  function getVotings(Voting.VotingCategory _category, uint32 _page, uint32 _pagesize)
  public
  view
  returns(uint32 _total, uint32[] _voting_ids)
  {
    return votings.getVotings(_category, _page, _pagesize);
  }

  function validateVote(uint32 _voting_id, uint32[] _option_ids)
  public
  view
  returns(string _error)
  {
    return votings.validateVote(_voting_id, _option_ids, usergroups);
  }

  function vote(uint32 _voting_id, uint32[] _option_ids)
  public
  {
    votings.vote(_voting_id, _option_ids, usergroups);
  }
}
