var UserRepositoryFactory = artifacts.require('UserRepositoryFactory');
var VotingFactory = artifacts.require('VotingFactory');
var VotingSystem = artifacts.require('VotingSystem');

module.exports = function(deployer) {
    deployer.deploy(UserRepositoryFactory);
    deployer.link(UserRepositoryFactory, VotingSystem);

    deployer.deploy(VotingFactory);
    deployer.link(VotingFactory, VotingSystem);

    deployer.deploy(VotingSystem);
}
