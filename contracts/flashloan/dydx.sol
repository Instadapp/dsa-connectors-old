pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@studydefi/money-legos/dydx/contracts/DydxFlashloanBase.sol";
import "@studydefi/money-legos/dydx/contracts/ICallee.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface DSAInterface {
    function cast(address[] calldata _targets, bytes[] calldata _datas, address _origin) external payable;
}

contract DydxFlashloaner is ICallee, DydxFlashloanBase {

    address public constant soloAddr = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    struct CastData {
        address[] targets;
        bytes[] data;
    }

    // check9898 - add block re-entrance
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        CastData memory cd = abi.decode(data, (CastData));

        // check9898 - change to DSA address & origin address too
        DSAInterface(address(0)).cast(cd.targets, cd.data, address(0));
    }

    // check9898 - if ETH then change 0xeeeee into WETH address and change the token into ETH before sending
    function initiateFlashLoan(address _token, uint256 _amount, bytes calldata data)
        external
    {
        ISoloMargin solo = ISoloMargin(soloAddr);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(soloAddr, _token);

        IERC20(_token).approve(soloAddr, _amount + 2);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(data);
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        IERC20 _tokenContract = IERC20(_token);
        uint iniBal = _tokenContract.balanceOf(address(this));

        solo.operate(accountInfos, operations);

        uint finBal = _tokenContract.balanceOf(address(this));
        require(sub(iniBal, finBal) < 10, "amount-paid-less");
    }
}