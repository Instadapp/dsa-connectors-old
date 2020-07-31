pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface OneInchInterace {
    function swap(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        uint256 guaranteedAmount,
        address payable referrer,
        address[] calldata callAddresses,
        bytes calldata callDataConcat,
        uint256[] calldata starts,
        uint256[] calldata gasLimitsAndValues
    )
    external
    payable
    returns (uint256 returnAmount);
}

contract OneHelpers is Stores, DSMath {
    using SafeERC20 for IERC20;
    /**
     * @dev Return  1Inch Address
     */
    function getOneInchAddress() internal pure returns (address) {
        return 0x11111254369792b2Ca5d084aB5eEA397cA8fa48B;
    }

    /**
     * @dev Return 1inch Token Taker Address
     */
    function getOneInchTokenTaker() internal pure returns (address payable) {
        return 0xE4C9194962532fEB467DCe8b3d42419641c6eD2E;
    }

    /**
     * @dev Return 1inch swap function sig
     */
    function getOneInchSig() internal pure returns (bytes4) {
        return 0xf88309d7;
    }

    function getReferralAddr() internal pure returns (address) {
        return 0xa7615CD307F323172331865181DC8b80a2834324;  // TODO - change address
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

    function _transfer(address payable to, IERC20 token, uint _amt) internal {
        address(token) == getEthAddr() ?
            to.transfer(_amt) :
            token.safeTransfer(to, _amt);
    }

    function takeFee(
        address token,
        uint amount,
        address feeCollector,
        uint feePercent
    ) internal returns (uint leftAmt, uint feeAmount){
        if (feeCollector != address(0)) {
            feeAmount = wmul(amount, feePercent);
            leftAmt = sub(amount, feeAmount);
            uint feeCollectorAmt = wmul(feeAmount, 3 * 10 ** 17);
            uint restAmt = sub(feeAmount, feeCollectorAmt);
            _transfer(payable(feeCollector), IERC20(token), feeCollectorAmt);
            _transfer(payable(getReferralAddr()), IERC20(token), restAmt);
        } else {
            leftAmt = amount;
        }
    }
}


contract Resolver is OneHelpers {
    function checkOneInchSig(bytes memory callData) internal pure returns(bool isOk) {
        bytes memory _data = callData;
        bytes4 sig;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            sig := mload(add(_data, 32))
        }
        isOk = sig == getOneInchSig();
    }

    struct OneInchData {
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint _sellAmt;
        uint _buyAmt;
        uint unitAmt;
        bytes callData;
        address feeCollector;
        uint256 feeAmount;
    }

    function oneInchSwap(
        OneInchData memory oneInchData,
        uint ethAmt
    ) internal returns (uint buyAmt) {
        TokenInterface buyToken = oneInchData.buyToken;
        (uint _buyDec, uint _sellDec) = getTokensDec(buyToken, oneInchData.sellToken);
        uint _sellAmt18 = convertTo18(_sellDec, oneInchData._sellAmt);
        uint _slippageAmt = convert18ToDec(_buyDec, wmul(oneInchData.unitAmt, _sellAmt18));

        uint initalBal = getTokenBal(buyToken);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = address(getOneInchAddress()).call.value(ethAmt)(oneInchData.callData);
        if (!success) revert("1Inch-swap-failed");

        uint finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

}

contract OneInchEventResolver is Resolver {
    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event LogSellFee(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        address indexed collector,
        uint256 fee,
        uint256 getId,
        uint256 setId
    );

    function emitLogSell(
        OneInchData memory oneInchData,
        uint256 setId
    ) internal {
        bytes32 _eventCode;
        bytes memory _eventParam;
        if (oneInchData.feeCollector == address(0)) {
            emit LogSell(
                address(oneInchData.buyToken),
                address(oneInchData.sellToken),
                oneInchData._buyAmt,
                oneInchData._sellAmt,
                0,
                setId
            );
            _eventCode = keccak256("LogSell(address,address,uint256,uint256,uint256,uint256)");
            _eventParam = abi.encode(
                address(oneInchData.buyToken),
                address(oneInchData.sellToken),
                oneInchData._buyAmt,
                oneInchData._sellAmt,
                0,
                setId
            );
        } else {
            emit LogSellFee(
                address(oneInchData.buyToken),
                address(oneInchData.sellToken),
                oneInchData._buyAmt,
                oneInchData._sellAmt,
                oneInchData.feeCollector,
                oneInchData.feeAmount,
                0,
                setId
            );
            _eventCode = keccak256("LogSellFee(address,address,uint256,uint256,uint256,uint256)");
            _eventParam = abi.encode(
                address(oneInchData.buyToken),
                address(oneInchData.sellToken),
                oneInchData._buyAmt,
                oneInchData._sellAmt,
                oneInchData.feeCollector,
                oneInchData.feeAmount,
                0,
                setId
            );
        }
        emitEvent(_eventCode, _eventParam);
    }
}

contract OneInchResolverHelpers is OneInchEventResolver {
    function _sell (
        OneInchData memory oneInchData,
        uint feePercent,
        uint setId
    ) internal {
        TokenInterface _buyAddr = oneInchData.buyToken;
        TokenInterface _sellAddr = oneInchData.sellToken;

        uint ethAmt;
        if (address(_sellAddr) == getEthAddr()) {
            ethAmt = oneInchData._sellAmt;
        } else {
            TokenInterface(_sellAddr).approve(getOneInchTokenTaker(), oneInchData._sellAmt);
        }

        require(checkOneInchSig(oneInchData.callData), "Not-swap-function");

        uint buyAmt = oneInchSwap(oneInchData, ethAmt);

        (uint feeAmount, uint leftBuyAmt) = takeFee(
            address(_buyAddr),
            buyAmt,
            oneInchData.feeCollector,
            feePercent
        );
        setUint(setId, leftBuyAmt);
        oneInchData.feeAmount = feeAmount;

        emitLogSell(oneInchData, setId);
    }
}

contract OneInchResolver is OneInchResolverHelpers {
    /**
     * @dev Sell ETH/ERC20_Token using 1inch.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param callData Data from 1inch API.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        bytes calldata callData,
        uint setId
    ) external payable {
        OneInchData memory oneInchData = OneInchData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            feeCollector: address(0),
            _sellAmt: sellAmt,
            _buyAmt: 0,
            feeAmount: 0
        });

        _sell(oneInchData, 0, setId);
    }

    /**
     * @dev Sell ETH/ERC20_Token using 1inch.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param callData Data from 1inch API.
     * @param feeCollector Fee amount to transfer.
     * @param feePercent Fee percentage on buyAmt.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sellFee(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        bytes calldata callData,
        address feeCollector,
        uint feePercent,
        uint setId
    ) external payable {
        require(feePercent > 0 && feePercent <= 2*10*16, "Fee more than 2%");
        require(feeCollector != address(0), "feeCollector is not vaild address");

        OneInchData memory oneInchData = OneInchData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            _sellAmt: sellAmt,
            unitAmt: unitAmt,
            callData: callData,
            feeCollector: feeCollector,
            _buyAmt: 0,
            feeAmount: 0
        });

        _sell(oneInchData, feePercent, setId);
    }
}

contract ConnectOneInch is OneInchResolver {
    string public name = "1Inch-v1";
}