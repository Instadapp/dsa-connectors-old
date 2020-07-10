pragma solidity ^0.6.0;

import { ConnectSynthetixStaking } from "../connectors/synthetix.sol";

contract MockSynthetixStaking is ConnectSynthetixStaking{
  // uint public _model;
  // uint public _id;
  address public synthetixStakingAddr;

  constructor(address _synthetixStakingAddr) public {
    // _model = model;
    // _id = id;
    synthetixStakingAddr = _synthetixStakingAddr;
  }

  function getSynthetixStakingAddr(address token) override internal view returns (address){
    return synthetixStakingAddr;
  }
}
