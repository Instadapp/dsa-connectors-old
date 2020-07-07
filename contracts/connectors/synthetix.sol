pragma solidity ^0.6.0;

// import files from common directory
import { Stores } from "../common/stores.sol";
// import { DSMath } from "../common/math.sol";
import { TokenInterface } from "../common/interfaces.sol";

interface IStakingRewards {
  function stake(uint256 amount) external;
  function exit() external;
  function withdraw(uint256 amount) external;
  function getReward() external;
}

contract Helper is Stores {
  function getSynthetixStakingAddr(address token) internal view returns(address){
    // SBTC
    if (token == address(0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3)){
      return 0x13C1542A468319688B89E323fe9A3Be3A90EBb27;
    // SUSD
    }else if (token == address(0xC25a3A3b969415c80451098fa907EC722572917F)){
      return 0xDCB6A51eA3CA5d3Fd898Fd6564757c7aAeC3ca92;
    }else{
      revert("token-not-found");
    }
  }
}

contract SynthetixStakingRewardsProtocol is Helper {

  // Events
  event LogStake(
    address stakeAddr,
    uint256 stakeAmt,
    uint getId
  );
  event LogExit(
    address stakeAddr,
    uint256 stakeAmt,
    uint getId
  );

  /**
  * @dev Stake Token.
  * @param stakeAddr staking token address.
  * @param stakeAmt staking token amount.
  * @param getId Get token amount at this ID from `InstaMemory` Contract.
  */
  function stake(
    address stakeAddr,
    uint stakeAmt,
    uint getId
  ) external {
    uint _stakeAmt = getUint(getId, stakeAmt);
    IStakingRewards rewardPool = IStakingRewards(getSynthetixStakingAddr(stakeAddr));
    TokenInterface _stakeToken = TokenInterface(stakeAddr);
    _stakeAmt = _stakeAmt == uint(-1) ? _stakeToken.balanceOf(address(this)) : _stakeAmt;
    _stakeToken.approve(address(rewardPool), _stakeAmt);

    rewardPool.stake(_stakeAmt);

    emit LogStake(stakeAddr, _stakeAmt, getId);
    bytes32 _eventCode = keccak256("LogStake(address,uint256, uint256)");
    bytes memory _eventParam = abi.encode(stakeAddr, _stakeAmt, getId);
    emitEvent(_eventCode, _eventParam);
  }

  /**
  * @dev Exit Token.
  * @param stakeAddr staking token address.
  * @param stakeAmt staking token amount.
  * @param getId Get token amount at this ID from `InstaMemory` Contract.
  */
  function exit(
    address stakeAddr,
    uint stakeAmt,
    uint getId
  ) external {
    uint _stakeAmt = getUint(getId, stakeAmt);
    IStakingRewards rewardPool = IStakingRewards(getSynthetixStakingAddr(stakeAddr));

    if(_stakeAmt == uint(-1)){
      rewardPool.exit();
    }
    else{
      rewardPool.withdraw(_stakeAmt);
      rewardPool.getReward();
    }

    emit LogExit(stakeAddr, _stakeAmt, getId);
    bytes32 _eventCode = keccak256("LogExit(address, uint256, uint256)");
    bytes memory _eventParam = abi.encode(stakeAddr, _stakeAmt, getId);
    emitEvent(_eventCode, _eventParam);
  }

}

contract ConnectSynthetixStakingRewardsProtocol is SynthetixStakingRewardsProtocol {
  string public name = "synthetix-staking-v1";
}
