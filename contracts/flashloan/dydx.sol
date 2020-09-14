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
    address public constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct CastData {
        address dsa;
        address token;
        uint amount;
        address[] targets;
        bytes[] data;
    }

    // check9898 - add block re-entrance
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        require(sender == address(this), "not-same-sender");
        CastData memory cd = abi.decode(data, (CastData));

        IERC20 tokenContract;
        if (cd.token == ethAddr) {
            tokenContract = IERC20(wethAddr);
            tokenContract.approve(getAddressWETH(), cd.amount);
            tokenContract.withdraw(cd.amount);
            payable(cd.dsa).transfer(cd.amount);
        } else {
            tokenContract = IERC20(cd.token);
            tokenContract.transfer(cd.dsa, cd.amount);
        }

        DSAInterface(cd.dsa).cast(cd.targets, cd.data, 0xB7fA44c2E964B6EB24893f7082Ecc08c8d0c0F87);

        if (cd.token == ethAddr) {
            tokenContract.deposit.value(cd.amount)();
        }

    }

    function initiateFlashLoan(address _token, uint256 _amount, bytes calldata data) external {
        ISoloMargin solo = ISoloMargin(soloAddr);

        uint256 marketId = _getMarketIdFromTokenAddress(soloAddr, _token);

        IERC20(_token).approve(soloAddr, _amount + 2);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(data);
        operations[2] = _getDepositAction(marketId, _amount + 2);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        IERC20 _tokenContract = IERC20(_token);
        uint iniBal = _tokenContract.balanceOf(address(this));

        solo.operate(accountInfos, operations);

        uint finBal = _tokenContract.balanceOf(address(this));
        require(sub(iniBal, finBal) < 5, "amount-paid-less");
    }

    receive() external payable {}
}