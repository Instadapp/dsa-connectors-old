pragma solidity ^0.6.0;

// import files from common directory
import { Stores } from "../common/stores.sol";
// import { DSMath } from "../common/math.sol";
import { TokenInterface } from "../common/interfaces.sol";

interface IStakingRewards {
  function stake(uint256 amount) public;
  function exit() external;
}

contract Helper is Stores {
  function getSynthetixStakingAddr(address token) internal view returns(address){
    // SBTC
    if (token == address(0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3)){
      return 0x13c1542a468319688b89e323fe9a3be3a90ebb27;
    // SUSD
    }else if (token == address(0xC25a3A3b969415c80451098fa907EC722572917F)){
      return 0xdcb6a51ea3ca5d3fd898fd6564757c7aaec3ca92;
    }else{
      revert("token-not-found");
    }
  }
}

contract SynthetixStakingRewardsProtocol is Helper {

  // Events
  event LogStake(
    address stakeAddr,
    uint256 stakeAmt
  );
  event LogExit(
    address stakeAddr
  );

  /**
  * @dev Stake Token.
  * @param stakeAddr staking token address.
  * @param stakeAmt staking token amount.
  */
  function stake(
    address stakeAddr,
    uint stakeAmt,
    uint getId,
  ) external {
    uint _stakeAmt = getUint(getId, stakeAmt);
    IStakingRewards rewardPool = IStakingRewards(getSynthetixStakingAddr(stakeAddr));
    TokenInterface _stakeToken = TokenInterface(stakeAddr);
    _stakeAmt = _stakeAmt == uint(-1) ? _stakeToken.balanceOf(address(this)) : _stakeAmt;
    _stakeToken.approve(address(rewardPool), _stakeAmt);

    rewardPool.stake(_stakeAmt);

    emit LogStake(address(this), _stakeAmt);
    bytes32 _eventCode = keccak256("LogStake(address,uint256)");
    bytes memory _eventParam = abi.encode(stakeAddr, _stakeAmt);
    emitEvent(_eventCode, _eventParam);
  }

  /**
  * @dev Exit Token.
  * @param token token address.
  * @param amt token amount.
  * @param unitAmt unit amount of curve_amt/token_amt with slippage.
  * @param getId Get token amount at this ID from `InstaMemory` Contract.
  * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function exit(
    address stakeAddr
  ) external {
    IStakingRewards rewardPool = IStakingRewards(getSynthetixStakingAddr(stakeAddr));

    rewardPool.exit();

    emit LogExit(stakeAddr);
    bytes32 _eventCode = keccak256("LogExit(address)");
    bytes memory _eventParam = abi.encode(stakeAddr);
    emitEvent(_eventCode, _eventParam);
  }

}

contract ConnectSynthetixStakingRewardsProtocol is SynthetixStakingRewardsProtocol {
  string public name = "synthetix-staking-v1";
}
