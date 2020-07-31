pragma solidity ^0.6.0;

import { InstaStakingMapping } from "../mapping/staking.sol";

contract MockInstaMapping is InstaStakingMapping {
  modifier isChief override {_;}
}
