pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

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

interface ICurveGaugeMapping {

  struct GaugeData {
    address gaugeAddress;
    bool rewardToken;
  }

  function gaugeMapping(bytes32) external view returns(GaugeData memory);
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
    uint setId
  );

  event LogClaimedReward(
    string indexed gaugePoolName,
    uint amount,
    uint rewardAmt,
    uint setId,
    uint setIdReward
  );

  event LogClaimedReward(
    string indexed gaugePoolName,
    uint amount,
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
    ICurveGaugeMapping curveGaugeMapping = ICurveGaugeMapping(getCurveGaugeMappingAddr());
    ICurveGaugeMapping.GaugeData memory curveGaugeData = curveGaugeMapping.gaugeMapping(bytes32(stringToBytes32(gaugePoolName)));
    require(curveGaugeData.gaugeAddress != address(0), "wrong-gauge-pool-name");
    IGauge gauge = IGauge(curveGaugeData.gaugeAddress);
    TokenInterface lp_token = TokenInterface(address(gauge.lp_token()));

    _amt = _amt == uint(-1) ? lp_token.balanceOf(address(this)) : _amt;
    lp_token.approve(address(curveGaugeData.gaugeAddress), _amt);
    gauge.deposit(_amt);
    setUint(setId, _amt);

    emit LogDeposit(gaugePoolName, _amt, getId, setId);
    bytes32 _eventCode = keccak256("LogDeposit(string,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(gaugePoolName, _amt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }

  /**
  * @dev Withdraw LP Token and claim both CRV and Reward token.
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
    ICurveGaugeMapping curveGaugeMapping = ICurveGaugeMapping(getCurveGaugeMappingAddr());
    ICurveGaugeMapping.GaugeData memory curveGaugeData = curveGaugeMapping.gaugeMapping(bytes32(stringToBytes32(gaugePoolName)));
    require(curveGaugeData.gaugeAddress != address(0), "wrong-gauge-pool-name");
    IGauge gauge = IGauge(curveGaugeData.gaugeAddress);
    TokenInterface crv_token = TokenInterface(address(gauge.crv_token()));
    Balances memory balances;

    _amt = _amt == uint(-1) ? gauge.balanceOf(address(this)) : _amt;
    balances.intialCRVBal = crv_token.balanceOf(address(this));

    if(curveGaugeData.rewardToken == true){
      TokenInterface rewarded_token = TokenInterface(address(gauge.rewarded_token()));
      balances.intialRewardBal = rewarded_token.balanceOf(address(this));
    }

    IMintor(getCurveMintorAddr()).mint(curveGaugeData.gaugeAddress);
    gauge.withdraw(_amt);

    balances.finalCRVBal = crv_token.balanceOf(address(this));
    balances.crvRewardAmt = sub(balances.finalCRVBal, balances.intialCRVBal);
    setUint(setId, _amt);
    setUint(setIdCRVReward, balances.crvRewardAmt);

    emitLogWithdraw(gaugePoolName, _amt, getId, setId);

    if(curveGaugeData.rewardToken == true){
      TokenInterface rewarded_token = TokenInterface(address(gauge.rewarded_token()));
      balances.finalRewardBal = rewarded_token.balanceOf(address(this));
      balances.rewardAmt = sub(balances.finalRewardBal, balances.intialRewardBal);
      setUint(setIdReward, balances.rewardAmt);
      emit LogClaimedReward(gaugePoolName, balances.crvRewardAmt, setIdCRVReward, balances.rewardAmt, setIdReward);
      bytes32 _eventCode = keccak256("LogClaimedReward(string,uint256,uint256,uint256,uint256)");
      bytes memory _eventParam = abi.encode(gaugePoolName, balances.crvRewardAmt, setIdCRVReward, balances.rewardAmt, setIdReward);
      emitEvent(_eventCode, _eventParam);
    }else{
      emit LogClaimedReward(gaugePoolName, balances.crvRewardAmt, setIdCRVReward);
      bytes32 _eventCode = keccak256("LogClaimedReward(string,uint256,uint256");
      bytes memory _eventParam = abi.encode(gaugePoolName, balances.crvRewardAmt, setIdCRVReward);
      emitEvent(_eventCode, _eventParam);
    }
  }

  /**
  * @dev emit LogWithdraw event
    * @param gaugePoolName gauge pool name.
    * @param _amt LP token amount.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function emitLogWithdraw(string memory gaugePoolName, uint _amt, uint getId, uint setId) internal {
    emit LogWithdraw(gaugePoolName, _amt, getId, setId);
    bytes32 _eventCodeWithdraw = keccak256("LogWithdraw(string,uint256,uint256,uint256)");
    bytes memory _eventParamWithdraw = abi.encode(gaugePoolName, _amt, getId, setId);
    emitEvent(_eventCodeWithdraw, _eventParamWithdraw);
  }

  /**
  * @dev Claim CRV Reward with Staked Reward token
    * @param gaugePoolName gauge pool name.
    * @param setId Set CRV reward amount at this ID in `InstaMemory` Contract.
    * @param setIdReward Set token reward amount at this ID in `InstaMemory` Contract.
  */
  function claimReward(
    string calldata gaugePoolName,
    uint setId,
    uint setIdReward
  ) external payable {
    ICurveGaugeMapping curveGaugeMapping = ICurveGaugeMapping(getCurveGaugeMappingAddr());
    ICurveGaugeMapping.GaugeData memory curveGaugeData = curveGaugeMapping.gaugeMapping(bytes32(stringToBytes32(gaugePoolName)));
    require(curveGaugeData.gaugeAddress != address(0), "wrong-gauge-pool-name");
    IMintor mintor = IMintor(getCurveMintorAddr());
    IGauge gauge = IGauge(curveGaugeData.gaugeAddress);
    TokenInterface crv_token = TokenInterface(address(gauge.crv_token()));
    Balances memory balances;

    if(curveGaugeData.rewardToken == true){
      TokenInterface rewarded_token = TokenInterface(address(gauge.rewarded_token()));
      balances.intialRewardBal = rewarded_token.balanceOf(address(this));
    }

    balances.intialCRVBal = crv_token.balanceOf(address(this));

    mintor.mint(curveGaugeData.gaugeAddress);

    balances.finalCRVBal = crv_token.balanceOf(address(this));
    balances.crvRewardAmt = sub(balances.finalCRVBal, balances.intialCRVBal);
    setUint(setId, balances.crvRewardAmt);

    if(curveGaugeData.rewardToken == true){
      TokenInterface rewarded_token = TokenInterface(address(gauge.rewarded_token()));
      balances.finalRewardBal = rewarded_token.balanceOf(address(this));
      balances.rewardAmt = sub(balances.finalRewardBal, balances.intialRewardBal);
      setUint(setIdReward, balances.rewardAmt);
      emit LogClaimedReward(gaugePoolName, balances.crvRewardAmt, setId, balances.rewardAmt, setIdReward);
      bytes32 _eventCode = keccak256("LogClaimedReward(string,uint256,uint256,uint256,uint256)");
      bytes memory _eventParam = abi.encode(gaugePoolName, balances.crvRewardAmt, setId, balances.rewardAmt, setIdReward);
      emitEvent(_eventCode, _eventParam);
    }else{
      emit LogClaimedReward(gaugePoolName, balances.crvRewardAmt, setId);
      bytes32 _eventCode = keccak256("LogClaimedReward(string,uint256,uint256");
      bytes memory _eventParam = abi.encode(gaugePoolName, balances.crvRewardAmt, setId);
      emitEvent(_eventCode, _eventParam);
    }
  }

}

contract ConnectCurveGauge is CurveGauge {
  string public name = "Curve-Gauge-v1.0";
}
