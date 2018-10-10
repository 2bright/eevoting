pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/VotingSystem.sol";

contract TestVotingFail {
    VotingSystem vSys;

    address owner;
    bytes content = "12345678";
    bytes32 content_hash;
    
    // option_count, select_min, select_max, isAnonymous, isPublic, multiWinner, thresholdWinnerVotes, thresholdTotalVotes
    uint64[8] params = [uint64(3), uint64(1), uint64(1), uint64(0), uint64(0), uint64(0), uint64(50), uint64(66)];

    // to_start_time, to_end_time
    uint64[2] time = [uint64(0), uint64(0)];

    address[] users;
    address user_repo = 0;

    address addr_0 = 0;

    uint8 I_VOTES = 0;
    uint8 I_VOTERS = 1;
    uint8 I_START_TIME = 2;
    uint8 I_END_TIME = 3;
    uint8 I_STATUS = 4;

    constructor() public {
        content_hash = keccak256(content);
    }

    function testVotingFailVotesLess66Percent() public {
        vSys = VotingSystem(DeployedAddresses.VotingSystem());

        users = new address[](10);
        for (i = 0; i < 10; i++) {
            users[i] = new UserMock();
        }
        user_repo = vSys.createUserRepository();
        UserRepository(user_repo).addUsers(users);

        Voting v = Voting(vSys.createVoting(content_hash, content, params, time, user_repo));

        uint64[] memory _winners;
        uint64[] memory _options;
        uint64[5] memory _extra;
        uint64 i;

        v.startVoting();

        uint64[] memory optionIDs = new uint64[](1);

        optionIDs[0] = 0;
        for (i = 0; i < 4; i++) {
            UserMock(users[i]).vote(v, optionIDs);
        }

        optionIDs[0] = 1;
        for (i = 4; i < 6; i++) {
            UserMock(users[i]).vote(v, optionIDs);
        }

        v.endVoting();

        v.settleVoting();

        (_winners, _options, _extra) = v.getVotingResult();
        Assert.equal(0, _winners.length, "getVotingResult error");
        Assert.equal(3, _options.length, "getVotingResult error");
        Assert.equal(4, uint(_options[0]), "getVotingResult error");
        Assert.equal(2, uint(_options[1]), "getVotingResult error");
        Assert.equal(0, uint(_options[2]), "getVotingResult error");
        Assert.equal(6, uint(_extra[I_VOTES]), "getVotingResult error");
        Assert.equal(10, uint(_extra[I_VOTERS]), "getVotingResult error 4");
        Assert.isBelow(0, uint(_extra[I_START_TIME]), "getVotingResult error 2");
        Assert.isBelow(0, uint(_extra[I_END_TIME]), "getVotingResult error 3");
        Assert.equal(3, uint(_extra[I_STATUS]), "getVotingResult error");
    }

    function testVotingFailWinnerLess50Percent() public {
        Voting v = Voting(vSys.createVoting(content_hash, content, params, time, user_repo));

        uint64[] memory _winners;
        uint64[] memory _options;
        uint64[5] memory _extra;
        uint64 i;

        v.startVoting();

        uint64[] memory optionIDs = new uint64[](1);

        optionIDs[0] = 2;
        for (i = 0; i < 3; i++) {
            UserMock(users[i]).vote(v, optionIDs);
        }

        for (i = 3; i < 7; i++) {
            optionIDs[0] = i % 2;
            UserMock(users[i]).vote(v, optionIDs);
        }

        v.endVoting();

        v.settleVoting();

        (_winners, _options, _extra) = v.getVotingResult();
        Assert.equal(0, _winners.length, "getVotingResult error");
        Assert.equal(3, _options.length, "getVotingResult error");
        Assert.equal(2, uint(_options[0]), "getVotingResult error");
        Assert.equal(2, uint(_options[1]), "getVotingResult error");
        Assert.equal(3, uint(_options[2]), "getVotingResult error");
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
