const Connector = artifacts.require("ConnectAuth"); // Change the Connector name while deploying.

module.exports = function(deployer) {
  deployer.deploy(Connector);
};
