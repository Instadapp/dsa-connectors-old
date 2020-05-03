const Connector = artifacts.require("MockProtocol"); // Change the Connector name while deploying.

module.exports = function(deployer) {
  deployer.deploy(Connector);
};
