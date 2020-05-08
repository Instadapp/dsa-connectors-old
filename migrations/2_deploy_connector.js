const Connector = artifacts.require("CurveProtocol"); // Change the Connector name while deploying.

module.exports = function(deployer) {
  deployer.deploy(Connector);
};
