var Usergroup = artifacts.require('Usergroup');
var Voting = artifacts.require('Voting');
var VotingSystem = artifacts.require('VotingSystem');

module.exports = function(deployer) {
    deployer.deploy(Usergroup);
    deployer.link(Usergroup, VotingSystem);
    deployer.link(Usergroup, Voting);

    deployer.deploy(Voting);
    deployer.link(Voting, VotingSystem);

    deployer.deploy(VotingSystem);
}
