pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@studydefi/money-legos/dydx/contracts/DydxFlashloanBase.sol";
import "@studydefi/money-legos/dydx/contracts/ICallee.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { DSMath } from "../common/math.sol";

interface DSAInterface {
    function cast(address[] calldata _targets, bytes[] calldata _datas, address _origin) external payable;
}

contract Helper {
    struct CastData {
        address dsa;
        address token;
        uint amount;
        address[] targets;
        bytes[] data;
    }

    function encodeDsaAddr(address dsa, bytes memory data) internal view returns (bytes memory _data) {
        CastData memory cd;
        (cd.token, cd.amount, cd.targets, cd.data) = abi.decode(data, (address, uint256, address[], bytes[]));
        _data = abi.encode(dsa, cd.token, cd.amount, cd.targets, cd.data);
    }
}

contract DydxFlashloaner is ICallee, DydxFlashloanBase, DSMath, Helper {
    using SafeERC20 for IERC20;

    // address public constant soloAddr = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    // address public constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address public constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public constant soloAddr = 0x4EC3570cADaAEE08Ae384779B0f3A45EF85289DE;
    address public constant wethAddr = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address public constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event LogDydxFlashLoan(
        address indexed sender,
        address indexed token,
        uint amount
    );

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public override {
        require(sender == address(this), "not-same-sender");
        CastData memory cd;
        (cd.dsa, cd.token, cd.amount, cd.targets, cd.data) = abi.decode(
            data,
            (address, address, uint256, address[], bytes[])
        );

        IERC20 tokenContract;
        if (cd.token == ethAddr) {
            tokenContract = IERC20(wethAddr);
            tokenContract.approve(wethAddr, cd.amount);
            tokenContract.withdraw(cd.amount);
            payable(cd.dsa).transfer(cd.amount);
        } else {
            tokenContract = IERC20(cd.token);
            tokenContract.safeTransfer(cd.dsa, cd.amount);
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
        operations[1] = _getCallAction(encodeDsaAddr(data));
        operations[2] = _getDepositAction(marketId, _amount + 2);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        IERC20 _tokenContract = IERC20(_token);
        uint iniBal = _tokenContract.balanceOf(address(this));

        solo.operate(accountInfos, operations);

        uint finBal = _tokenContract.balanceOf(address(this));
        require(sub(iniBal, finBal) < 5, "amount-paid-less");
    }

}

contract InstaDydxFlashLoan is DydxFlashloaner {

    receive() external payable {}
}