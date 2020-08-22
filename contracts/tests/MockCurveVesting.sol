pragma solidity ^0.6.0;

import { ConnectCurveVestingProtocol } from "../connectors/curve_vesting.sol";

contract MockConnectCurveVestingProtocol is ConnectCurveVestingProtocol{
  address public curveTokenAddr;
  address public curveVestingAddr;

  constructor(address _curveVestingAddr, address _curveTokenAddr) public {
    curveVestingAddr = _curveVestingAddr;
    curveTokenAddr = _curveTokenAddr;
  }

  function getCurveTokenAddr() override internal view returns (address) {
    return curveTokenAddr;
  }

  function getCurveVestingAddr() override internal view returns (address) {
    return curveVestingAddr;
  }

  function emitEvent(bytes32 eventCode, bytes memory eventData) override internal {}
  function setUint(uint setId, uint val) override internal {}
}
