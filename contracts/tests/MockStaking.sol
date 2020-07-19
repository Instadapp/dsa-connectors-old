pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { ConnectStaking } from "../connectors/staking.sol";

contract MockSynthetixStaking is ConnectStaking{
  address public synthetixStakingAddr;
  address public instaMappingAddr;

  constructor(address _synthetixStakingAddr, address _instaMappingAddr) public {
    synthetixStakingAddr = _synthetixStakingAddr;
    instaMappingAddr = _instaMappingAddr;
  }

  function emitEvent(bytes32 eventCode, bytes memory eventData) override internal {}

  function getMappingAddr() override internal view returns (address) {
    return instaMappingAddr;
  }

  function setUint(uint setId, uint val) override internal {}
}
