pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { ConnectOne } from "../connectors/1proto.sol";

contract MockConnectOne is ConnectOne {
  address public oneProtoAddr;

  constructor(address _oneProtoAddr) public {
    oneProtoAddr = _oneProtoAddr;
  }

  function emitEvent(bytes32 eventCode, bytes memory eventData) override internal {}

  function setUint(uint setId, uint val) override internal {}

  function sub(uint x, uint y) internal override pure returns (uint z) {
      z = 100000;
  }
}
