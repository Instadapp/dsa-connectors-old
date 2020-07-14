pragma solidity ^0.6.0;

import { InstaMapping } from "../mapping/staking.sol";

contract MockInstaMapping is InstaMapping {
  modifier isChief override {_;}
}
