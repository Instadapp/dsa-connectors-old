const CurveProtocol = artifacts.require("CurveProtocol");
const ConnectSBTCCurve = artifacts.require("ConnectSBTCCurve");

const connectorsABI = require("../test/abi/connectors.json");
let connectorsAddr = "0xD6A602C01a023B98Ecfb29Df02FBA380d3B21E0c";
let connectorInstance = new web3.eth.Contract(connectorsABI, connectorsAddr);

module.exports = async function(deployer) {
  deployer.deploy(CurveProtocol);
  let connectorLength = await connectorInstance.methods.connectorLength().call();
  deployer.deploy(ConnectSBTCCurve, 1, +connectorLength + 1);
};
