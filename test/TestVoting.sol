pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/VotingSystem.sol";

contract TestVoting {
    Voting voting;

    VotingSystem vSys;

    address owner;
    bytes content = "123456";
    bytes32 content_hash;
    
    // option_count, select_min, select_max, isAnonymous, isPublic, multiWinner, thresholdWinnerVotes, thresholdTotalVotes
    uint64[8] params = [uint64(2), uint64(1), uint64(1), uint64(0), uint64(0), uint64(0), uint64(50), uint64(66)];

    // to_start_time, to_end_time
    uint64[2] time = [uint64(0), uint64(0)];

    address user_repo = 0;

    address addr_0 = 0;

    function testCreateVoting() public {
        vSys = VotingSystem(DeployedAddresses.VotingSystem());

        owner = this;
        content_hash = keccak256(content);

        user_repo = vSys.createUserRepository();
        Assert.notEqual(0, user_repo, "createUserRepository error");

        voting = Voting(vSys.createVoting(content_hash, content, params, time, user_repo));
        Assert.notEqual(addr_0, voting, "createVoting error");
    }

    function testGetVotingInfo() public {
        address _owner;
        bytes32 _content_hash;
        uint64[8] memory _params;
        uint64[3] memory _time;
        address _user_repo;

        (_owner, _content_hash, _params, _time, _user_repo) = voting.getVotingInfo();

        Assert.equal(owner, _owner, "getVotingInfo error 1");
        Assert.equal(content_hash, _content_hash, "getVotingInfo error 2");

        uint i = 0;

        for (i = 0; i < 8; i++) {
            Assert.equal(uint(params[i]), uint(_params[i]), "getVotingInfo error 3");
        }

        Assert.equal(uint(time[0]), uint(_time[0]), "getVotingInfo error 4");
        Assert.equal(uint(time[1]), uint(_time[1]), "getVotingInfo error 5");

        // create time
        Assert.isBelow(0, uint(_time[2]), "getVotingInfo error 6");

        Assert.equal(user_repo, _user_repo, "getVotingInfo error 7");
    }

    function testVoting() public {
        uint64[] memory _winners;
        uint64[] memory _options;
        // _extra: _votes, _voters, _start_time, _end_time, _status
        uint64[5] memory _extra;
        bool ret;
        uint64 i;

        uint8 I_VOTES = 0;
        uint8 I_VOTERS = 1;
        uint8 I_START_TIME = 2;
        uint8 I_END_TIME = 3;
        uint8 I_STATUS = 4;

        //-----------------------------

        (_winners, _options, _extra) = voting.getVotingResult();
        Assert.equal(0, _winners.length, "getVotingResult error");
        Assert.equal(2, _options.length, "getVotingResult error");
        Assert.equal(0, uint(_options[0]), "getVotingResult error");
        Assert.equal(0, uint(_options[1]), "getVotingResult error");
        Assert.equal(0, uint(_extra[I_VOTES]), "getVotingResult error");
        Assert.equal(0, uint(_extra[I_VOTERS]), "getVotingResult error");
        Assert.equal(0, uint(_extra[I_START_TIME]), "getVotingResult error");
        Assert.equal(0, uint(_extra[I_END_TIME]), "getVotingResult error");
        Assert.equal(0, uint(_extra[I_STATUS]), "getVotingResult error");

        //-----------------------------

        ret = voting.startVoting();
        Assert.equal(true, ret, "getVotingResult error");

        (_winners, _options, _extra) = voting.getVotingResult();
        Assert.isBelow(0, uint(_extra[I_START_TIME]), "getVotingResult error");
        Assert.equal(1, uint(_extra[I_STATUS]), "getVotingResult error");

        //-----------------------------

        address[] memory users = new address[](10);
        for (i = 0; i < 10; i++) {
            users[i] = new UserMock();
        }
        UserRepository(user_repo).addUsers(users);

        (_winners, _options, _extra) = voting.getVotingResult();
        Assert.equal(10, uint(_extra[I_VOTERS]), "getVotingResult error 5");

        //-----------------------------

        uint64[] memory optionIDs = new uint64[](1);
        for (i = 0; i < 7; i++) {
            optionIDs[0] = i % 2;
            ret = UserMock(users[i]).vote(voting, optionIDs);
            Assert.equal(true, ret, "getVotingResult error");
        }

        (_winners, _options, _extra) = voting.getVotingResult();
        Assert.equal(4, uint(_options[0]), "getVotingResult error");
        Assert.equal(3, uint(_options[1]), "getVotingResult error");
        Assert.equal(7, uint(_extra[I_VOTES]), "getVotingResult error");

        //-----------------------------

        ret = voting.endVoting();
        Assert.equal(true, ret, "getVotingResult error");

        (_winners, _options, _extra) = voting.getVotingResult();
        Assert.isBelow(0, uint(_extra[I_END_TIME]), "getVotingResult error 1");
        Assert.equal(2, uint(_extra[I_STATUS]), "getVotingResult error");

        //-----------------------------

        ret = voting.settleVoting();
        Assert.equal(true, ret, "getVotingResult error");

        (_winners, _options, _extra) = voting.getVotingResult();
        Assert.equal(1, _winners.length, "getVotingResult error");
        Assert.equal(2, _options.length, "getVotingResult error");
        Assert.equal(4, uint(_options[0]), "getVotingResult error");
        Assert.equal(3, uint(_options[1]), "getVotingResult error");
        Assert.equal(7, uint(_extra[I_VOTES]), "getVotingResult error");
        Assert.equal(10, uint(_extra[I_VOTERS]), "getVotingResult error 4");
        Assert.isBelow(0, uint(_extra[I_START_TIME]), "getVotingResult error 2");
        Assert.isBelow(0, uint(_extra[I_END_TIME]), "getVotingResult error 3");
        Assert.equal(3, uint(_extra[I_STATUS]), "getVotingResult error");
    }
}

contract UserMock {
    function vote(address voting, uint64[] _optionIDs) public returns(bool) {
        return Voting(voting).vote(_optionIDs);
    }
}
