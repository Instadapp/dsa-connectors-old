pragma solidity ^0.6.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";


/**
 * @title ConnectBasic.
 * @dev Connector to deposit/withdraw assets.
 */

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
}

interface DydxFlashInterface {
    function initiateFlashLoan(address _token, uint256 _amount, bytes calldata data) external;
}

contract BasicResolver is Stores {

    using SafeERC20 for IERC20;

    /**
        * @dev Return ethereum address
    */
    function getDydxLoanAddr() internal pure returns (address) {
        return address(0); // check9898 - change to dydx flash contract address
    }

    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    /**
     * @dev Deposit Assets To Smart Account.
     * @param token Token Address.
     * @param tokenAmt Token Amount.
     * @param data targets & data for cast.
     */
    function borrowAndCast(address token, uint tokenAmt, bytes memory data) public payable {
        AccountInterface(address(this)).enable(getDydxLoanAddr());

        address _token = token == getEthAddr() ? getWethAddr() : token;

        DydxFlashInterface(getDydxLoanAddr()).initiateFlashLoan(_token, tokenAmt, data);

        if (token == getEthAddr()) {
            payable(getDydxLoanAddr()).transfer(tokenAmt);
        } else {
            IERC20(token).transfer(getDydxLoanAddr(), tokenAmt);
        }

        AccountInterface(address(this)).disable(getDydxLoanAddr());
    }

}


contract ConnectBasic is BasicResolver {
    string public constant name = "dydx-flashloan-v1";
}
