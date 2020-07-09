// const CurveProtocol = artifacts.require("CurveProtocol");
// const ConnectSBTCCurve = artifacts.require("ConnectSBTCCurve");
const MockContract = artifacts.require("MockContract");

module.exports = async function(deployer) {
  // deployer.deploy(CurveProtocol);
  deployer.deploy(MockContract);
  // let connectorLength = await connectorInstance.methods.connectorLength().call();
  // deployer.deploy(ConnectSBTCCurve, 1, +connectorLength + 1);
};
