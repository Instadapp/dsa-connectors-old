pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { CurveGaugeMapping } from "../mapping/curve_gauge_mapping.sol";

contract MockCurveGaugeMapping is CurveGaugeMapping {
    constructor(
    string[] memory gaugeNames,
    address[] memory gaugeAddresses,
    bool[] memory rewardTokens
    ) public CurveGaugeMapping(gaugeNames, gaugeAddresses, rewardTokens) {
  }
  modifier isChief override {_;}
}
