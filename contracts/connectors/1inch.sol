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

interface OneProtoInterface {
    function swapWithReferral(
        TokenInterface fromToken,
        TokenInterface destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags, // See contants in IOneSplit.sol
        address referral,
        uint256 feePercent
    ) external payable returns(uint256);

    function swapWithReferralMulti(
        TokenInterface[] calldata tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256[] calldata flags,
        address referral,
        uint256 feePercent
    ) external payable returns(uint256 returnAmount);

    function getExpectedReturn(
        TokenInterface fromToken,
        TokenInterface destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
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
     * @dev Return 1Split Token Taker Address
     */
    function getOneSplitTokenTaker() internal pure returns (address payable) {
        return 0xE4C9194962532fEB467DCe8b3d42419641c6eD2E;
    }

    /**
     * @dev Return 1Split swap function sig
     */
    function getOneSplitSig() internal pure returns (bytes4) {
        return 0xf88309d7;
    }

    function getReferralAddr() internal pure returns (address) {
        return 0xa7615CD307F323172331865181DC8b80a2834324;
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

    function getSlippageAmt(
        TokenInterface _buyAddr,
        TokenInterface _sellAddr,
        uint _sellAmt,
        uint unitAmt
    ) internal view returns(uint _slippageAmt) {
        (uint _buyDec, uint _sellDec) = getTokensDec(_buyAddr, _sellAddr);
        uint _sellAmt18 = convertTo18(_sellDec, _sellAmt);
        _slippageAmt = convert18ToDec(_buyDec, wmul(unitAmt, _sellAmt18));
    }

    function convertToTokenInterface(address[] memory tokens) internal pure returns(TokenInterface[] memory) {
        TokenInterface[] memory _tokens = new TokenInterface[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            _tokens[i] = TokenInterface(tokens[i]);
        }
        return _tokens;
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

    function oneProtoSwap(
        OneProtoInterface oneSplitContract,
        TokenInterface _sellAddr,
        TokenInterface _buyAddr,
        uint _sellAmt,
        uint unitAmt,
        uint[] memory distribution,
        uint disableDexes
    ) internal returns (uint buyAmt){
        uint _slippageAmt = getSlippageAmt(_buyAddr, _sellAddr, _sellAmt, unitAmt);

        uint ethAmt;
        if (address(_sellAddr) == getEthAddr()) {
            ethAmt = _sellAmt;
        } else {
            _sellAddr.approve(address(oneSplitContract), _sellAmt);
        }

        uint initalBal = getTokenBal(_buyAddr);

        oneSplitContract.swapWithReferral.value(ethAmt)(
            _sellAddr,
            _buyAddr,
            _sellAmt,
            _slippageAmt,
            distribution,
            disableDexes,
            getReferralAddr(),
            0
        );

        uint finalBal = getTokenBal(_buyAddr);
        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    function oneProtoSwapMulti(
        address[] memory tokens,
        TokenInterface _sellAddr,
        TokenInterface _buyAddr,
        uint _sellAmt,
        uint unitAmt,
        uint[] memory distribution,
        uint[] memory disableDexes
    ) internal returns (uint buyAmt){
        OneProtoInterface oneSplitContract = OneProtoInterface(getOneSplitAddress());
        uint _slippageAmt = getSlippageAmt(_buyAddr, _sellAddr, _sellAmt, unitAmt);

        uint ethAmt;
        if (address(_sellAddr) == getEthAddr()) {
            ethAmt = _sellAmt;
        } else {
            _sellAddr.approve(address(oneSplitContract), _sellAmt);
        }

        uint initalBal = getTokenBal(_buyAddr);
        oneSplitContract.swapWithReferralMulti.value(ethAmt)(
            convertToTokenInterface(tokens),
            _sellAmt,
            _slippageAmt,
            distribution,
            disableDexes,
            getReferralAddr(),
            0
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

contract OneProtoResolver is Resolver {
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

    event LogSellMulti(
        address[] tokens,
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    /**
     * @dev Sell ETH/ERC20_Token using 1split.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
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

        OneProtoInterface oneSplitContract = OneProtoInterface(getOneSplitAddress());

        (, uint[] memory distribution) = oneSplitContract.getExpectedReturn(
                _sellAddr,
                _buyAddr,
                _sellAmt,
                5,
                0
            );

        uint _buyAmt = oneProtoSwap(
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

    /**
     * @dev Sell ETH/ERC20_Token using 1split.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param distribution distribution of swap across different dex.
     * @param disableDexes disable a dex. (To disable none: 0)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
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

        uint _buyAmt = oneProtoSwap(
            OneProtoInterface(getOneSplitAddress()),
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

    /**
     * @dev Sell ETH/ERC20_Token using 1split using muliple token.
     * @param tokens buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param distribution distribution of swap across different dex.
     * @param disableDexes disable a dex. (To disable none: 0)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sellMulti(
        address[] calldata tokens,
        uint sellAmt,
        uint unitAmt,
        uint[] calldata distribution,
        uint[] calldata disableDexes,
        uint getId,
        uint setId
    ) external payable {
        uint _sellAmt = getUint(getId, sellAmt);
        require(tokens.length >= 2, "token tokens.lengthgth is less than 2");
        TokenInterface _sellAddr = TokenInterface(address(tokens[0]));
        TokenInterface _buyAddr = TokenInterface(address(tokens[tokens.length-1]));

        _sellAmt = _sellAmt == uint(-1) ? getTokenBal(_sellAddr) : _sellAmt;

        uint _buyAmt = oneProtoSwapMulti(
            tokens,
            _sellAddr,
            _buyAddr,
            _sellAmt,
            unitAmt,
            distribution,
            disableDexes
        );

        setUint(setId, _buyAmt);

        emitLogSellMulti(tokens, address(_sellAddr), address(_buyAddr), _buyAmt, _sellAmt, getId, setId);
    }

    function emitLogSellMulti(
        address[] memory tokens,
        address buyToken,
        address sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    ) internal {
        emit LogSellMulti(tokens, address(buyToken), address(sellToken), buyAmt, sellAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogSellMulti(address[],address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(tokens, address(buyToken), address(sellToken), buyAmt, sellAmt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }
}

contract OneInchResolver is OneProtoResolver {
    event LogSellThree(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

     /**
     * @dev Sell ETH/ERC20_Token using 1split.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param callData Data from 1inch API.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
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
            TokenInterface(_sellAddr).approve(getOneSplitTokenTaker(), sellAmt);
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
contract ConnectOne is OneInchResolver {
    string public name = "1Inch-1proto-v1";
}