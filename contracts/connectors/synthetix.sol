pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface } from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface IStakingRewards {
  function stake(uint256 amount) external;
  function exit() external;
  function withdraw(uint256 amount) external;
  function getReward() external;
  function balanceOf(address) external view returns (uint256);
}

contract SynthetixStakingHelper is DSMath, Stores {
  /**
   * @dev Return Synthetix staking pool address.
  */
  function getSynthetixStakingAddr(address token) internal pure returns (address){
    if (token == address(0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3)){
      // SBTC
      return 0x13C1542A468319688B89E323fe9A3Be3A90EBb27;
    } else if (token == address(0xC25a3A3b969415c80451098fa907EC722572917F)){
      // SUSD
      return 0xDCB6A51eA3CA5d3Fd898Fd6564757c7aAeC3ca92;
    } else {
      revert("token-not-found");
    }
  }

  /**
   * @dev Return Synthetix Token address.
  */
  function getSnxAddr() internal pure returns (address) {
    return 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
  }
}

contract SynthetixStaking is SynthetixStakingHelper {

  // Events
  event LogDeposit(
    address token,
    uint256 amount,
    uint getId,
    uint setId
  );
  event LogWithdraw(
    address token,
    uint256 amount,
    uint getId,
    uint setId
  );
  event LogClaimedReward(
    address token,
    uint256 rewardAmt,
    uint setId
  );

  /**
  * @dev Deposit Token.
  * @param token staking token address.
  * @param amt staking token amount.
  * @param getId Get token amount at this ID from `InstaMemory` Contract.
  * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function deposit(
    address token,
    uint amt,
    uint getId,
    uint setId
  ) external payable {
    uint _amt = getUint(getId, amt);
    IStakingRewards stakingContract = IStakingRewards(getSynthetixStakingAddr(token));
    TokenInterface _stakeToken = TokenInterface(token);
    _amt = _amt == uint(-1) ? _stakeToken.balanceOf(address(this)) : _amt;

    _stakeToken.approve(address(stakingContract), _amt);
    stakingContract.stake(_amt);

    setUint(setId, _amt);
    emit LogDeposit(token, _amt, getId, setId);
    bytes32 _eventCode = keccak256("LogDeposit(address,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }

  /**
  * @dev Withdraw Token.
  * @param token staking token address.
  * @param amt staking token amount.
  * @param getId Get token amount at this ID from `InstaMemory` Contract.
  * @param setIdAmount Set token amount at this ID in `InstaMemory` Contract.
  * @param setIdReward Set reward amount at this ID in `InstaMemory` Contract.
  */
  function withdraw(
    address token,
    uint amt,
    uint getId,
    uint setIdAmount,
    uint setIdReward
  ) external payable {
    uint _amt = getUint(getId, amt);
    IStakingRewards stakingContract = IStakingRewards(getSynthetixStakingAddr(token));
    TokenInterface snxToken = TokenInterface(getSnxAddr());
    _amt = _amt == uint(-1) ? stakingContract.balanceOf(address(this)) : _amt;

    uint intialBal = snxToken.balanceOf(address(this));
    stakingContract.withdraw(_amt);
    stakingContract.getReward();
    uint finalBal = snxToken.balanceOf(address(this));

    uint rewardAmt = sub(finalBal, intialBal);

    setUint(setIdAmount, _amt);
    setUint(setIdReward, rewardAmt);

    emit LogWithdraw(token, _amt, getId, setIdAmount);
    bytes32 _eventCodeWithdraw = keccak256("LogWithdraw(address,uint256,uint256,uint256)");
    bytes memory _eventParamWithdraw = abi.encode(token, _amt, getId, setIdAmount);
    emitEvent(_eventCodeWithdraw, _eventParamWithdraw);

    emit LogClaimedReward(token, rewardAmt, setIdReward);
    bytes32 _eventCodeReward = keccak256("LogClaimedReward(address,uint256,uint256)");
    bytes memory _eventParamReward = abi.encode(token, rewardAmt, setIdReward);
    emitEvent(_eventCodeReward, _eventParamReward);
  }

  /**
  * @dev Claim Reward.
  * @param token staking token address.
  * @param setId Set reward amount at this ID in `InstaMemory` Contract.
  */
  function claimReward(
    address token,
    uint setId
  ) external payable {
    IStakingRewards stakingContract = IStakingRewards(getSynthetixStakingAddr(token));
    TokenInterface snxToken = TokenInterface(getSnxAddr());

    uint intialBal = snxToken.balanceOf(address(this));
    stakingContract.getReward();
    uint finalBal = snxToken.balanceOf(address(this));

    uint rewardAmt = sub(finalBal, intialBal);

    setUint(setId, rewardAmt);
    emit LogClaimedReward(token, rewardAmt, setId);
    bytes32 _eventCode = keccak256("LogClaimedReward(address,uint256,uint256)");
    bytes memory _eventParam = abi.encode(token, rewardAmt, setId);
    emitEvent(_eventCode, _eventParam);
  }
}

contract ConnectSynthetixStaking is SynthetixStaking {
  string public name = "synthetix-staking-v1";
}
