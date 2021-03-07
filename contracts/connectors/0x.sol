pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import files from common directory
import {TokenInterface, MemoryInterface, EventInterface} from "../common/interfaces.sol";
import {Stores} from "../common/stores.sol";
import {DSMath} from "../common/math.sol";

contract Helpers is Stores, DSMath {
    /**
     * @dev Return 0x Address
     */
    function get0xAddress() internal pure returns (address) {
        return 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    }

    function convert18ToDec(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10**(18 - _dec));
    }

    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns (uint256 _amt) {
        _amt = address(token) == getEthAddr() ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns (uint256 buyDec, uint256 sellDec) {
        buyDec = address(buyAddr) == getEthAddr() ? 18 : buyAddr.decimals();
        sellDec = address(sellAddr) == getEthAddr() ? 18 : sellAddr.decimals();
    }

    struct SwapData {
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint256 _sellAmt;
        uint256 _buyAmt;
        uint256 unitAmt;
        bytes callData;
    }

}

contract EventResolver is Helpers {
    event LogSwap(address indexed buyToken, address indexed sellToken, uint256 buyAmt, uint256 sellAmt, uint256 getId, uint256 setId);

    function emitLogSwap(SwapData memory swapData, uint256 setId) internal {
        bytes32 _eventCode;
        bytes memory _eventParam;
        emit LogSwap(address(swapData.buyToken), address(swapData.sellToken), swapData._buyAmt, swapData._sellAmt, 0, setId);
        _eventCode = keccak256("LogSwap(address,address,uint256,uint256,uint256,uint256)");
        _eventParam = abi.encode(address(swapData.buyToken), address(swapData.sellToken), swapData._buyAmt, swapData._sellAmt, 0, setId);
        emitEvent(_eventCode, _eventParam);
    }
}

contract Resolver is EventResolver {
    function _swapHelper(SwapData memory swapData, uint256 wethAmt) internal returns (uint256 buyAmt) {
        TokenInterface buyToken = swapData.buyToken;
        (uint256 _buyDec, uint256 _sellDec) = getTokensDec(buyToken, swapData.sellToken);
        uint256 _sellAmt18 = convertTo18(_sellDec, swapData._sellAmt);
        uint256 _slippageAmt = convert18ToDec(_buyDec, wmul(swapData.unitAmt, _sellAmt18));

        uint256 initalBal = getTokenBal(buyToken);

        (bool success, ) = address(get0xAddress()).call.value(wethAmt)(swapData.callData);
        if (!success) revert("0x-swap-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    function _swap(SwapData memory swapData, uint256 setId) internal {
        TokenInterface _sellAddr = swapData.sellToken;

        uint256 ethAmt;

        if (address(_sellAddr) == getEthAddr()) {
            ethAmt = swapData._sellAmt;
        } else {
            TokenInterface(_sellAddr).approve(get0xAddress(), swapData._sellAmt);
        }

        swapData._buyAmt = _swapHelper(swapData, ethAmt);

        setUint(setId, swapData._buyAmt);

        emitLogSwap(swapData, setId);
    }
}

contract Connector is Resolver {
    /**
     * @dev Swap ETH/ERC20_Token using 0x.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param callData Data from 0x API.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
     */
    function swap(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt,
        bytes calldata callData,
        uint256 setId
    ) external payable {
        SwapData memory swapData =
            SwapData({
                buyToken: TokenInterface(buyAddr),
                sellToken: TokenInterface(sellAddr),
                unitAmt: unitAmt,
                callData: callData,
                _sellAmt: sellAmt,
                _buyAmt: 0
            });

        _swap(swapData, setId);
    }
}

contract Connect0x is Connector {
    string public name = "0x-v1";
}