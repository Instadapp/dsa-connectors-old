pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

contract MatchaHelpers is Stores, DSMath {

    /**
     * @dev Return  1Inch Address
     */
    function getMatchaAddress() internal pure returns (address) {
        return 0x61935CbDd02287B511119DDb11Aeb42F1593b7Ef;
    }

    function getWETHAddress() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == getEthAddr() ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == getEthAddr() ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == getEthAddr() ?  18 : sellAddr.decimals();
    }
}

// A partial WETH interfaec.
interface IWETH is IERC20 {
    function deposit() external payable;
}

contract Matcha {

    IWETH WETH = getWETHAddress();

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

    // Transfer tokens held by this contrat to the sender/owner.
    function withdrawToken(TokenInterface token, uint256 amount)
        external
    {
        require(token.transfer(address(this), amount));
    }

    // Transfer ETH held by this contrat to the sender/owner.
    function withdrawETH(uint256 amount)
        external
    {
        (address(this)).transfer(amount);
    }

    function depositETH()
        external
        payable
    {
        WETH.deposit{value: msg.value}();
    }
    event BoughtTokens(
        address indexed sellAddr,
        address indexed buyAddr,
        uint256 buyAmt,
        uint256 setId
    );
 /**
     * @dev swap ERC20_Token/ERC20_Token using Matcha.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param spender  The `allowanceTarget` field from the API response.
     * @param swapTarget The `to` field from the API response.
     * @param swapCallData  The `data` field from the API response.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
     
    */
    function fillQuote(
        TokenInterface sellAddr,
        TokenInterface buyAddr,
        address spender,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint ethAmt,    
        uint setId
    ) external payable {
        // Track our balance of the buyAddr to determine how much we've bought.
        uint256 initial = getTokenBal(buyAddr);

        uint buyAmt;

        // Give `spender` an infinite allowance to spend this contract's `sellToken`.
        // Note that for some tokens (e.g., USDT, KNC), you must first reset any existing
        // allowance to 0 before being able to update it.
        require(sellAddr.approve(spender, uint(-1)));
        // Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success,) = swapTarget.call.value(ethAmt)(swapCallData);
        require(success, 'SWAP_CALL_FAILED');
        // Refund any unspent protocol fees to the sender.
        address(this).transfer(address(this).balance);

        // Use our current buyToken balance to determine how much we've bought.
        uint finalBal = getTokenBal(buyAddr);

        buyAmt = sub(finalBal, initialBal);

        setUint(setId, buyAmt);

        emit BoughtTokens(sellAddr, buyAddr, boughtAmount, setId);
    }

    
}

contract ConnectOne is Matcha {
    string public name = "Matcha-v1";
}