pragma solidity ^0.6.0;

import { ConnectSynthetixStaking } from "../connectors/synthetix.sol";

contract MockSynthetixStaking is ConnectSynthetixStaking{
  address public synthetixStakingAddr;

  constructor(address _synthetixStakingAddr) public {
    synthetixStakingAddr = _synthetixStakingAddr;
  }

  function getSynthetixStakingAddr(address token) override internal returns (address) {
    return synthetixStakingAddr;
  }

  function emitEvent(bytes32 eventCode, bytes memory eventData) override internal {}

  function getSnxAddr() override internal view returns (address) {
    return synthetixStakingAddr;
  }

  function setUint(uint setId, uint val) override internal {}
}
