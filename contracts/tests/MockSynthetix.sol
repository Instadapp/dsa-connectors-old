pragma solidity ^0.6.0;

import { ConnectSynthetixStaking } from "../connectors/synthetix.sol";

contract MockSynthetixStaking is ConnectSynthetixStaking{
  address public synthetixStakingAddr;

  constructor(address _synthetixStakingAddr) ConnectSynthetixStaking(_synthetixStakingAddr) public {
    synthetixStakingAddr = _synthetixStakingAddr;
  }

  function getSynthetixStakingAddr(address token) override internal{}

  function emitEvent(bytes32 eventCode, bytes memory eventData) override internal {}

  function getSnxAddr() override internal view returns (address) {
    return synthetixStakingAddr;
  }

  function setUint(uint setId, uint val) override internal {}
}
