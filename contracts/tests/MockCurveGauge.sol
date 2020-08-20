pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { ConnectCurveGauge } from "../connectors/curve_gauge.sol";

contract MockCurveGauge is ConnectCurveGauge{
  address public curveMintorAddr;
  address public curveGaugeMappingAddr;

  constructor(address _curveMintorAddr, address _curveGaugeMappingAddr) public {
    curveMintorAddr = _curveMintorAddr;
    curveGaugeMappingAddr = _curveGaugeMappingAddr;
  }

  function emitEvent(bytes32 eventCode, bytes memory eventData) override internal {}

  function getCurveGaugeMappingAddr() override internal view returns (address) {
    return curveGaugeMappingAddr;
  }

  function getCurveMintorAddr() override internal view returns (address) {
    return curveMintorAddr;
  }

  function setUint(uint setId, uint val) override internal {}
}

