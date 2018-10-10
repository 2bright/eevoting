pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/VotingSystem.sol";

contract TestVotingSystem {
    function testVotingSystem() public {
        VotingSystem vSys = VotingSystem(DeployedAddresses.VotingSystem());

        bytes memory _content = "123456";
        bytes32 _content_hash = keccak256(_content);

        uint64[8] memory _params = [uint64(2), uint64(1), uint64(1), uint64(0), uint64(1), uint64(0), uint64(50), uint64(67)];
        uint64[2] memory _time = [uint64(0), uint64(0)];
        address _user_repo = 0;
        address[] memory user_repos;

        address voting1 = vSys.createVoting(_content_hash, _content, _params, _time, _user_repo);
        Assert.notEqual(0, voting1, "createVoting error");

        _user_repo = vSys.createUserRepository();
        Assert.notEqual(0, _user_repo, "getVotings error");

        _params[4] = 0;
        address voting2 = vSys.createVoting(_content_hash, _content, _params, _time, _user_repo);
        Assert.notEqual(0, voting2, "createVoting error");

        user_repos = vSys.getUserRepositories();
        Assert.equal(1, user_repos.length, "getVotings error");
        Assert.equal(_user_repo, user_repos[0], "getVotings error");

        address[] memory vs = vSys.getVotings();
        Assert.equal(2, vs.length, "getVotings error");
        Assert.equal(voting1, vs[0], "getVotings error");
        Assert.equal(voting2, vs[1], "getVotings error");
    }
}
