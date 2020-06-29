const CurveProtocol = artifacts.require("CurveProtocol");
const CurveSBTCProtocol = artifacts.require("CurveSBTCProtocol");

module.exports = function(deployer) {
  deployer.deploy(CurveProtocol);
  deployer.deploy(CurveSBTCProtocol);
};
