pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { CurveGaugeMapping } from "../mapping/curve_gauge_mapping.sol";

contract MockCurveGaugeMapping is CurveGaugeMapping {
  modifier isChief override {_;}
}
