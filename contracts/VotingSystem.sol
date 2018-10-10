pragma solidity ^0.4.24;

import "./Voting.sol";
import "./UserRepository.sol";

contract VotingSystem {
    using VotingFactory for *;

    mapping(address => address[]) votings;
    mapping(address => address[]) userRepositories;

    event CreateVoting(address votingContractAddress);
    
    // _params: option_count, select_min, select_max, isAnonymous, isPublic, multiWinner, thresholdWinnerVotes, thresholdTotalVotes
    // _time: to_start_time, to_end_time
    function createVoting(bytes32 _content_hash, bytes _content, uint64[8] _params, uint64[2] _time, address _user_repo)
        public
        returns(address)
    {
        address v = VotingFactory.createVoting(_content_hash, _content, _params, _time, _user_repo);
        votings[msg.sender].push(v);
        emit CreateVoting(v);
        return v;
    }

    function getVotings() public view returns(address[]) {
        return votings[msg.sender];
    }

    function createUserRepository() public returns(address) {
        address u = UserRepositoryFactory.createUserRepository();
        userRepositories[msg.sender].push(u);
        return u;
    }

    function getUserRepositories() public view returns(address[]) {
        return userRepositories[msg.sender];
    }
}
