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
        return 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    }

    function getWETHAddress() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
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

    function convertEthToWeth(
        bool isEth,
        TokenInterface token,
        uint256 amount
    ) internal {
        if (isEth) token.deposit.value(amount)();
    }

    function convertWethToEth(
        bool isEth,
        TokenInterface token,
        uint256 amount
    ) internal {
        if (isEth) {
            token.approve(address(token), amount);
            token.withdraw(amount);
        }
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

    function matchaSwap(MatchaData memory matchaData, uint256 wethAmt) internal returns (uint256 buyAmt) {
        TokenInterface buyToken = matchaData.buyToken;
        (uint256 _buyDec, uint256 _sellDec) = getTokensDec(buyToken, matchaData.sellToken);
        uint256 _sellAmt18 = convertTo18(_sellDec, matchaData._sellAmt);
        uint256 _slippageAmt = convert18ToDec(_buyDec, wmul(matchaData.unitAmt, _sellAmt18));

        uint256 initalBal = getTokenBal(buyToken);

        (bool success, ) = address(getMatchaAddress()).call.value(wethAmt)(matchaData.callData);
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
        TokenInterface _buyAddr = matchaData.buyToken;

        uint256 ethAmt;
        TokenInterface tokenContract = TokenInterface(getWETHAddress());

        if (address(_sellAddr) == getEthAddr()) {
            ethAmt = matchaData._sellAmt;
            convertEthToWeth(true, tokenContract, ethAmt);
        } else {
            TokenInterface(_sellAddr).approve(getMatchaAddress(), matchaData._sellAmt);
        }

        matchaData._buyAmt = matchaSwap(matchaData, ethAmt);

        if (address(_buyAddr) == getEthAddr()) {
            convertWethToEth(true, tokenContract, matchaData._buyAmt);
        }

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
