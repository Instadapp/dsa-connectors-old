pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import files from common directory
import {TokenInterface, MemoryInterface, EventInterface} from "../common/interfaces.sol";
import {Stores} from "../common/stores.sol";
import {DSMath} from "../common/math.sol";

contract MatchaHelpers is Stores, DSMath {
    /**
     * @dev Return Matcha Address
     */
    function getMatchaAddress() internal pure returns (address) {
        return 0x61935CbDd02287B511119DDb11Aeb42F1593b7Ef;
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
}

contract MatchaResolver is MatchaHelpers {
    struct MatchaData {
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint256 _sellAmt;
        uint256 _buyAmt;
        uint256 unitAmt;
        bytes callData;
    }

    function matchaSwap(MatchaData memory matchaData, uint256 ethAmt) internal returns (uint256 buyAmt) {
        TokenInterface buyToken = matchaData.buyToken;
        (uint256 _buyDec, uint256 _sellDec) = getTokensDec(buyToken, matchaData.sellToken);
        uint256 _sellAmt18 = convertTo18(_sellDec, matchaData._sellAmt);
        uint256 _slippageAmt = convert18ToDec(_buyDec, wmul(matchaData.unitAmt, _sellAmt18));

        uint256 initalBal = getTokenBal(buyToken);

        (bool success, ) = address(getMatchaAddress()).call.value(ethAmt)(matchaData.callData);
        if (!success) revert("matcha-swap-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }
}

contract MatchaEventResolver is MatchaResolver {
    event LogSwap(address indexed buyToken, address indexed sellToken, uint256 buyAmt, uint256 sellAmt, uint256 getId, uint256 setId);

    function emitLogSwap(MatchaData memory matchaData, uint256 setId) internal {
        bytes32 _eventCode;
        bytes memory _eventParam;
        emit LogSwap(address(matchaData.buyToken), address(matchaData.sellToken), matchaData._buyAmt, matchaData._sellAmt, 0, setId);
        _eventCode = keccak256("LogSwap(address,address,uint256,uint256,uint256,uint256)");
        _eventParam = abi.encode(address(matchaData.buyToken), address(matchaData.sellToken), matchaData._buyAmt, matchaData._sellAmt, 0, setId);
        emitEvent(_eventCode, _eventParam);
    }
}

contract MatchaResolverHelpers is MatchaEventResolver {
    function _swap(MatchaData memory matchaData, uint256 setId) internal {
        TokenInterface _sellAddr = matchaData.sellToken;

        uint256 ethAmt;
        if (address(_sellAddr) == getEthAddr()) {
            ethAmt = matchaData._sellAmt;
        } else {
            TokenInterface(_sellAddr).approve(getMatchaAddress(), matchaData._sellAmt);
        }

        matchaData._buyAmt = matchaSwap(matchaData, ethAmt);
        setUint(setId, matchaData._buyAmt);

        emitLogSwap(matchaData, setId);
    }
}

contract Matcha is MatchaResolverHelpers {
    /**
     * @dev Swap ETH/ERC20_Token using matcha.
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
        MatchaData memory matchaData =
            MatchaData({
                buyToken: TokenInterface(buyAddr),
                sellToken: TokenInterface(sellAddr),
                unitAmt: unitAmt,
                callData: callData,
                _sellAmt: sellAmt,
                _buyAmt: 0
            });

        _swap(matchaData, setId);
    }
}

contract ConnectMatcha is MatchaResolver {
    string public name = "matcha-v1";
}
