pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

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

interface OneSplitInterface {
    function swap(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 disableFlags // 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken, 1024 - bDAI
    ) external payable;

    function getExpectedReturn(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
    external
    view
    returns(
        uint256 returnAmount,
        uint256[] memory distribution
    );
}


contract OneHelpers is Stores, DSMath {
    /**
     * @dev Return  1Inch Address
     */
    function getOneInchAddress() internal pure returns (address) {
        return 0x11111254369792b2Ca5d084aB5eEA397cA8fa48B;
    }

    /**
     * @dev Return 1Split Address
     */
    function getOneSplitAddress() internal pure returns (address payable) {
        return 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
    }

    /**
     * @dev Return 1Split swap function sig
     */
    function getOneSplitSig() internal pure returns (bytes4) {
        return 0xf88309d7;
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


contract Resolver is OneHelpers {
    function checkOneInchSig(bytes memory callData) internal pure returns(bool isOk) {
        bytes memory _data = callData;
        bytes4 sig;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            sig := mload(add(_data, 32))
        }
        isOk = sig == getOneSplitSig();
    }

    function oneSplitSwap(
        OneSplitInterface oneSplitContract,
        TokenInterface _sellAddr,
        TokenInterface _buyAddr,
        uint _sellAmt,
        uint unitAmt,
        uint[] memory distribution,
        uint disableDexes
    ) internal returns (uint buyAmt){
        (uint _buyDec, uint _sellDec) = getTokensDec(_buyAddr, _sellAddr);
        uint _sellAmt18 = convertTo18(_sellDec, _sellAmt);
        uint _slippageAmt = convert18ToDec(_buyDec, wmul(unitAmt, _sellAmt18));

        uint ethAmt;
        if (address(_sellAddr) == getEthAddr()) {
            ethAmt = _sellAmt;
        } else {
            _sellAddr.approve(address(oneSplitContract), _sellAmt);
        }

        uint initalBal = getTokenBal(_buyAddr);

        oneSplitContract.swap.value(ethAmt)(
            _sellAddr,
            _buyAddr,
            _sellAmt,
            _slippageAmt,
            distribution,
            disableDexes
        );

        uint finalBal = getTokenBal(_buyAddr);
        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    function oneInchSwap(
        TokenInterface _buyAddr,
        TokenInterface _sellAddr,
        bytes memory callData,
        uint sellAmt,
        uint unitAmt,
        uint ethAmt
    ) internal returns (uint buyAmt) {
        (uint _buyDec, uint _sellDec) = getTokensDec(_buyAddr, _sellAddr);
        uint _sellAmt18 = convertTo18(_sellDec, sellAmt);
        uint _slippageAmt = convert18ToDec(_buyDec, wmul(unitAmt, _sellAmt18));
        uint initalBal = getTokenBal(_buyAddr);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = address(getOneInchAddress()).call.value(ethAmt)(callData);
        if (!success) revert("1Inch-swap-failed");

        uint finalBal = getTokenBal(_buyAddr);
        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }
}

contract BasicResolver is Resolver {
    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event LogSellTwo(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event LogSellThree(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable {
        uint _sellAmt = getUint(getId, sellAmt);

        TokenInterface _buyAddr = TokenInterface(buyAddr);
        TokenInterface _sellAddr = TokenInterface(sellAddr);

        _sellAmt = _sellAmt == uint(-1) ? getTokenBal(_sellAddr) : _sellAmt;

        OneSplitInterface oneSplitContract = OneSplitInterface(getOneSplitAddress());

        (, uint[] memory distribution) = oneSplitContract.getExpectedReturn(
                _sellAddr,
                _buyAddr,
                _sellAmt,
                3, // TODO - shall we hardcode?
                0
            );

        uint _buyAmt = oneSplitSwap(
            oneSplitContract,
            _sellAddr,
            _buyAddr,
            _sellAmt,
            unitAmt,
            distribution,
            0
        );

        setUint(setId, _buyAmt);

        emit LogSell(address(_buyAddr), address(_sellAddr), _buyAmt, _sellAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogSell(address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(address(_buyAddr), address(_sellAddr), _buyAmt, _sellAmt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }

    function sellTwo(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint[] calldata distribution,
        uint disableDexes,
        uint getId,
        uint setId
    ) external payable {
        uint _sellAmt = getUint(getId, sellAmt);

        TokenInterface _buyAddr = TokenInterface(buyAddr);
        TokenInterface _sellAddr = TokenInterface(sellAddr);

        _sellAmt = _sellAmt == uint(-1) ? getTokenBal(_sellAddr) : _sellAmt;

        uint _buyAmt = oneSplitSwap(
            OneSplitInterface(getOneSplitAddress()),
            _sellAddr,
            _buyAddr,
            _sellAmt,
            unitAmt,
            distribution,
            disableDexes
        );

        setUint(setId, _buyAmt);

        emit LogSellTwo(address(_buyAddr), address(_sellAddr), _buyAmt, _sellAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogSellTwo(address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(address(_buyAddr), address(_sellAddr), _buyAmt, _sellAmt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }

    function sellThree(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        bytes calldata callData,
        uint setId
    ) external payable {
        TokenInterface _buyAddr = TokenInterface(buyAddr);
        TokenInterface _sellAddr = TokenInterface(sellAddr);

        uint ethAmt;
        if (address(_sellAddr) == getEthAddr()) {
            ethAmt = sellAmt;
        } else {
            TokenInterface(_sellAddr).approve(getOneInchAddress(), sellAmt);
        }

        require(checkOneInchSig(callData), "Not-swap-function");

        uint buyAmt = oneInchSwap(_buyAddr, _sellAddr, callData, sellAmt, unitAmt, ethAmt);

        setUint(setId, buyAmt);

        emit LogSellThree(address(_buyAddr), address(_sellAddr), buyAmt, sellAmt, 0, setId);
        bytes32 _eventCode = keccak256("LogSellThree(address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(address(_buyAddr), address(_sellAddr), buyAmt, sellAmt, 0, setId);
        emitEvent(_eventCode, _eventParam);
    }
}

contract ConnectOne is BasicResolver {
    string public name = "1Inch-1Split-v1";
}