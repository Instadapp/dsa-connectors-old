pragma solidity ^0.6.0;

// import files from common directory
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";
import { TokenInterface } from "../common/interfaces.sol";

interface IGauge {
  function claim_rewards() external;
  function deposit(uint256 value) external;
  function withdraw(uint256 value) external;
  function lp_token() external view returns(address token);
  function rewarded_token() external view returns(address token);
  function crv_token() external view returns(address token);
  function balanceOf(address user) external view returns(uint256 amt);
}

interface IMintor{
  function mint(address gauge) external;
}

interface CurveGaugeMapping {
  function gaugeMapping(bytes32) external view returns(address gaugeAddress);
}

contract GaugeHelper is DSMath, Stores{
  function getCurveGaugeMappingAddr() internal virtual view returns (address){
    // Change this to the deployed address
    return 0x0000000000000000000000000000000000000000;
  }

  function getCurveMintorAddr() internal virtual view returns (address){
    return 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
  }

  /**
   * @dev Convert String to bytes32.
   */
  function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
    require(bytes(str).length != 0, "string-empty");
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      result := mload(add(str, 32))
    }
  }
}

contract CurveGauge is GaugeHelper {
  event LogDeposit(
    string indexed gaugePoolName,
    uint amount,
    uint getId,
    uint setId
  );

  event LogWithdraw(
    string indexed gaugePoolName,
    uint amount,
    uint getId,
    uint setId,
    uint setIdCRVReward,
    uint setIdReward
  );

  event LogWithdraw(
    string indexed gaugePoolName,
    uint amount,
    uint getId,
    uint setId,
    uint setIdCRVReward
  );

  event LogClaimedReward(
    string indexed gaugePoolName,
    uint setId,
    uint setIdReward
  );

  event LogClaimedReward(
    string indexed gaugePoolName,
    uint setId
  );

  struct Balances{
    uint intialCRVBal;
    uint intialRewardBal;
    uint finalCRVBal;
    uint finalRewardBal;
    uint crvRewardAmt;
    uint rewardAmt;
  }

  /**
  * @dev Deposit Cruve LP Token.
    * @param gaugePoolName Curve gauge pool name.
    * @param amt deposit amount.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function deposit(
    string calldata gaugePoolName,
    uint amt,
    uint getId,
    uint setId
  ) external payable {
    uint _amt = getUint(getId, amt);
    CurveGaugeMapping curveGaugeMapping = CurveGaugeMapping(getCurveGaugeMappingAddr());
    address curveGaugeAddr = curveGaugeMapping.gaugeMapping(bytes32(stringToBytes32(gaugePoolName)));
    require(curveGaugeAddr != address(0), "wrong-gauge-pool-name");
    IGauge gauge = IGauge(curveGaugeAddr);
    TokenInterface lp_token = TokenInterface(address(gauge.lp_token()));

    _amt = _amt == uint(-1) ? lp_token.balanceOf(address(this)) : _amt;
    lp_token.approve(address(curveGaugeAddr), _amt);
    gauge.deposit(_amt);
    setUint(setId, _amt);

    emit LogDeposit(gaugePoolName, _amt, getId, setId);
    bytes32 _eventCode = keccak256("LogDeposit(string,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(gaugePoolName, _amt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }

  /**
  * @dev Withdraw LP Token.
    * @param gaugePoolName gauge pool name.
    * @param amt LP token amount.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setId Set token amount at this ID in `InstaMemory` Contract.
    * @param setIdCRVReward Set CRV token reward amount at this ID in `InstaMemory` Contract.
    * @param setIdReward Set reward amount at this ID in `InstaMemory` Contract.
  */
  function withdraw(
    string calldata gaugePoolName,
    uint amt,
    uint getId,
    uint setId,
    uint setIdCRVReward,
    uint setIdReward
  ) external payable {
    uint _amt = getUint(getId, amt);
    address curveGaugeAddr = CurveGaugeMapping(getCurveGaugeMappingAddr())
      .gaugeMapping(bytes32(stringToBytes32(gaugePoolName)));
    require(curveGaugeAddr != address(0), "wrong-gauge-pool-name");
    IGauge gauge = IGauge(curveGaugeAddr);
    TokenInterface crv_token = TokenInterface(address(gauge.crv_token()));
    TokenInterface rewarded_token = TokenInterface(address(gauge.rewarded_token()));
    Balances memory balances;

    _amt = _amt == uint(-1) ? TokenInterface(address(gauge.lp_token())).balanceOf(address(this)) : _amt;
    balances.intialCRVBal = crv_token.balanceOf(address(this));
    balances.intialRewardBal = rewarded_token.balanceOf(address(this));
    IMintor(getCurveMintorAddr()).mint(curveGaugeAddr);
    gauge.withdraw(_amt);
    balances.finalCRVBal = crv_token.balanceOf(address(this));
    balances.finalRewardBal = rewarded_token.balanceOf(address(this));
    balances.crvRewardAmt = sub(balances.finalCRVBal, balances.intialCRVBal);
    balances.rewardAmt = sub(balances.finalRewardBal, balances.intialRewardBal);

    setUint(setId, _amt);
    setUint(setIdCRVReward, balances.crvRewardAmt);
    setUint(setIdReward, balances.rewardAmt);

    emitLogWithdraw(gaugePoolName, _amt, getId, setId, setIdCRVReward, setIdReward);
  }

  function emitLogWithdraw(string memory gaugePoolName, uint _amt, uint getId, uint setId, uint setIdCRVReward, uint setIdReward) internal {
    emit LogWithdraw(gaugePoolName, _amt, getId, setId, setIdCRVReward, setIdReward);
    bytes32 _eventCodeWithdraw = keccak256("LogWithdraw(string,uint256,uint256,uint256,uint256,uint256)");
    bytes memory _eventParamWithdraw = abi.encode(gaugePoolName, _amt, getId, setId, setIdCRVReward, setIdReward);
    emitEvent(_eventCodeWithdraw, _eventParamWithdraw);
  }

  /**
  * @dev Claim Reward.
    * @param gaugePoolName gauge pool name.
    * @param setId Set CRV reward amount at this ID in `InstaMemory` Contract.
    * @param setIdReward Set token reward amount at this ID in `InstaMemory` Contract.
  */
  function claimReward(
    string calldata gaugePoolName,
    uint setId,
    uint setIdReward
  ) external payable {
    CurveGaugeMapping curveGaugeMapping = CurveGaugeMapping(getCurveGaugeMappingAddr());
    address curveGaugeAddr = curveGaugeMapping.gaugeMapping(bytes32(stringToBytes32(gaugePoolName)));
    require(curveGaugeAddr != address(0), "wrong-gauge-pool-name");
    IMintor mintor = IMintor(getCurveMintorAddr());
    IGauge gauge = IGauge(curveGaugeAddr);
    TokenInterface crv_token = TokenInterface(address(gauge.crv_token()));
    TokenInterface rewarded_token = TokenInterface(address(gauge.rewarded_token()));
    Balances memory balances;

    balances.intialCRVBal = crv_token.balanceOf(address(this));
    balances.intialRewardBal = rewarded_token.balanceOf(address(this));
    mintor.mint(curveGaugeAddr);
    balances.finalCRVBal = crv_token.balanceOf(address(this));
    balances.finalRewardBal = rewarded_token.balanceOf(address(this));
    balances.crvRewardAmt = sub(balances.finalCRVBal, balances.intialCRVBal);
    balances.rewardAmt = sub(balances.finalRewardBal, balances.intialRewardBal);

    setUint(setId, balances.crvRewardAmt);
    setUint(setIdReward, balances.rewardAmt);

    emit LogClaimedReward(gaugePoolName, setId, setIdReward);
    bytes32 _eventCode = keccak256("LogClaimedReward(string,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(gaugePoolName, setId, setIdReward);
    emitEvent(_eventCode, _eventParam);
  }

  /**
  * @dev Withdraw LP Token.
    * @param gaugePoolName gauge pool name.
    * @param amt LP token amount.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setId Set token amount at this ID in `InstaMemory` Contract.
    * @param setIdCRVReward Set CRV token reward amount at this ID in `InstaMemory` Contract.
  */
  function withdraw(
    string calldata gaugePoolName,
    uint amt,
    uint getId,
    uint setId,
    uint setIdCRVReward
  ) external payable {
    uint _amt = getUint(getId, amt);
    address curveGaugeAddr = CurveGaugeMapping(getCurveGaugeMappingAddr())
      .gaugeMapping(bytes32(stringToBytes32(gaugePoolName)));
    require(curveGaugeAddr != address(0), "wrong-gauge-pool-name");
    IGauge gauge = IGauge(curveGaugeAddr);
    TokenInterface crv_token = TokenInterface(address(gauge.crv_token()));
    Balances memory balances;

    _amt = _amt == uint(-1) ? TokenInterface(address(gauge.lp_token())).balanceOf(address(this)) : _amt;
    balances.intialCRVBal = crv_token.balanceOf(address(this));
    IMintor(getCurveMintorAddr()).mint(curveGaugeAddr);
    gauge.withdraw(_amt);
    balances.finalCRVBal = crv_token.balanceOf(address(this));
    balances.crvRewardAmt = sub(balances.finalCRVBal, balances.intialCRVBal);

    setUint(setId, _amt);
    setUint(setIdCRVReward, balances.crvRewardAmt);

    emitLogWithdraw(gaugePoolName, _amt, getId, setId, setIdCRVReward);
  }

  function emitLogWithdraw(string memory gaugePoolName, uint _amt, uint getId, uint setId, uint setIdCRVReward) internal {
    emit LogWithdraw(gaugePoolName, _amt, getId, setId, setIdCRVReward);
    bytes32 _eventCodeWithdraw = keccak256("LogWithdraw(string,uint256,uint256,uint256,uint256)");
    bytes memory _eventParamWithdraw = abi.encode(gaugePoolName, _amt, getId, setId, setIdCRVReward);
    emitEvent(_eventCodeWithdraw, _eventParamWithdraw);
  }

  /**
  * @dev Claim Reward.
    * @param gaugePoolName gauge pool name.
    * @param setId Set CRV reward amount at this ID in `InstaMemory` Contract.
  */
  function claimReward(
    string calldata gaugePoolName,
    uint setId
  ) external payable {
    CurveGaugeMapping curveGaugeMapping = CurveGaugeMapping(getCurveGaugeMappingAddr());
    address curveGaugeAddr = curveGaugeMapping.gaugeMapping(bytes32(stringToBytes32(gaugePoolName)));
    require(curveGaugeAddr != address(0), "wrong-gauge-pool-name");
    IMintor mintor = IMintor(getCurveMintorAddr());
    IGauge gauge = IGauge(curveGaugeAddr);
    TokenInterface crv_token = TokenInterface(address(gauge.crv_token()));
    Balances memory balances;

    balances.intialCRVBal = crv_token.balanceOf(address(this));
    mintor.mint(curveGaugeAddr);
    balances.finalCRVBal = crv_token.balanceOf(address(this));
    balances.crvRewardAmt = sub(balances.finalCRVBal, balances.intialCRVBal);

    setUint(setId, balances.crvRewardAmt);

    emit LogClaimedReward(gaugePoolName, setId);
    bytes32 _eventCode = keccak256("LogClaimedReward(string,uint256,uint256)");
    bytes memory _eventParam = abi.encode(gaugePoolName, setId);
    emitEvent(_eventCode, _eventParam);
  }
}

contract ConnectCurveGauge is CurveGauge {
  string public name = "Curve-Gauge-v1.0";
}
