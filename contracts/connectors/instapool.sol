pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface LiqudityInterface {
    function deposit(address, uint) external payable;
    function withdraw(address, uint) external;

    function accessLiquidity(address[] calldata, uint[] calldata) external;
    function returnLiquidity(address[] calldata) external payable;

    function isTknAllowed(address) external view returns(bool);
    function tknToCTkn(address) external view returns(address);
    function liquidityBalance(address, address) external view returns(uint);

    function borrowedToken(address) external view returns(uint);
}

interface InstaPoolFeeInterface {
    function getFee() external view returns(uint);
    function getFeeCollector() external view returns(address);
}

interface CTokenInterface {
    function borrowBalanceCurrent(address account) external returns (uint);
    function balanceOf(address owner) external view returns (uint256 balance);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint); // For ERC20
}

interface CETHInterface {
    function borrowBalanceCurrent(address account) external returns (uint);
    function repayBorrowBehalf(address borrower) external payable;
}


interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface MemoryInterface {
    function getUint(uint _id) external returns (uint _num);
    function setUint(uint _id, uint _val) external;
}

interface EventInterface {
    function emitEvent(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external;
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}


contract Helpers is DSMath {

    using SafeERC20 for IERC20;

    /**
     * @dev Return ethereum address
     */
    function getAddressETH() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return Memory Variable Address
     */
    function getMemoryAddr() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
    }

    /**
     * @dev Return InstaEvent Address.
     */
    function getEventAddr() internal pure returns (address) {
        return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97; // InstaEvent Address
    }

    /**
     * @dev Get Uint value from InstaMemory Contract.
    */
    function getUint(uint getId, uint val) internal returns (uint returnVal) {
        returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
    }

    /**
     * @dev Set Uint value in InstaMemory Contract.
    */
    function setUint(uint setId, uint val) internal {
        if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
    }

    /**
     * @dev Connector Details
    */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 8);
    }

    function _transfer(address payable to, address token, uint _amt) internal {
        token == getAddressETH() ?
            to.transfer(_amt) :
            IERC20(token).safeTransfer(to, _amt);
    }

    function _getBalance(address token) internal view returns (uint256) {
        return token == getAddressETH() ?
            address(this).balance :
            TokenInterface(token).balanceOf(address(this));
    }
}


contract LiquidityHelpers is Helpers {
    /**
     * @dev Return InstaPool address
     */
    function getLiquidityAddress() internal pure returns (address) {
        return 0x06cB7C24990cBE6b9F99982f975f9147c000fec6;
    }

    /**
     * @dev Return InstaPoolFee address
     */
    function getInstaPoolFeeAddr() internal pure returns (address) {
        return 0x06cB7C24990cBE6b9F99982f975f9147c000fec6; // TODO - change
    }

    function calculateFeeAmt(address token, uint amt) internal view returns (uint feeAmt, uint totalAmt) {
        uint fee = InstaPoolFeeInterface(getInstaPoolFeeAddr()).getFee();
        if(fee == 0) {
            feeAmt = 0;
            totalAmt = amt;
        } else {
            feeAmt = wmul(amt, fee);
            totalAmt = add(amt, feeAmt);

            uint totalBal = _getBalance(token);
            require(totalBal >= totalAmt - 10, "Not-enough-balance");
            feeAmt = totalBal > totalAmt ? feeAmt : sub(totalBal, amt);
        }
    }

    function calculateFeeAmtOrigin(address token, uint amt) internal view returns (uint poolFeeAmt, uint originFee) {
        (uint feeAmt,) = calculateFeeAmt(token, amt);
        if(feeAmt == 0) {
            poolFeeAmt = 0;
            originFee = 0;
        } else {
            originFee = wmul(feeAmt, 20 * 10 ** 16);
            poolFeeAmt = sub(feeAmt, originFee);
        }
    }
}


contract LiquidityManage is LiquidityHelpers {

    event LogDepositLiquidity(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdrawLiquidity(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);

    /**
     * @dev Deposit Liquidity in InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        uint ethAmt;
        if (token == getAddressETH()) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            ethAmt = _amt;
        } else {
            _amt = _amt == uint(-1) ? TokenInterface(token).balanceOf(address(this)) : _amt;
            TokenInterface(token).approve(getLiquidityAddress(), _amt);
        }

        LiqudityInterface(getLiquidityAddress()).deposit.value(ethAmt)(token, _amt);
        setUint(setId, _amt);

        emit LogDepositLiquidity(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogDepositLiquidity(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Withdraw Liquidity in InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        LiqudityInterface(getLiquidityAddress()).withdraw(token, _amt);
        setUint(setId, _amt);

        emit LogWithdrawLiquidity(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogWithdrawLiquidity(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }
}


contract LiquidityAccess is LiquidityManage {
    event LogFlashBorrow(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogFlashPayback(address indexed token, uint256 tokenAmt, uint256 feeCollected, uint256 getId, uint256 setId);

    event LogOriginFeeCollector(address indexed origin, address indexed token, uint256 tokenAmt, uint256 originFeeAmt);

    /**
     * @dev Access Token Liquidity from InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashBorrow(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        address[] memory _tknAddrs = new address[](1);
        _tknAddrs[0] = token;
        uint[] memory _amts = new uint[](1);
        _amts[0] = _amt;

        LiqudityInterface(getLiquidityAddress()).accessLiquidity(_tknAddrs, _amts);

        setUint(setId, _amt);

        emit LogFlashBorrow(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogFlashBorrow(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Return Token Liquidity from InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashPayback(address token, uint getId, uint setId) external payable {
        LiqudityInterface liquidityContract = LiqudityInterface(getLiquidityAddress());
        uint _amt = liquidityContract.borrowedToken(token);

        (uint feeAmt,) = calculateFeeAmt(token, _amt);

        address[] memory _tknAddrs = new address[](1);
        _tknAddrs[0] = token;

        _transfer(payable(address(liquidityContract)), token, _amt);
        liquidityContract.returnLiquidity(_tknAddrs);

        _transfer(payable(InstaPoolFeeInterface(getInstaPoolFeeAddr()).getFeeCollector()), token, feeAmt);

        setUint(setId, _amt);

        emit LogFlashPayback(token, _amt, feeAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogFlashPayback(address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, feeAmt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Access Multiple Token liquidity from InstaPool.
     * @param tokens Array of token addresses.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amts Array of token amount.
     * @param getId get token amounts at this IDs from `InstaMemory` Contract.
     * @param setId set token amounts at this IDs in `InstaMemory` Contract.
    */
    function flashMultiBorrow(
        address[] calldata tokens,
        uint[] calldata amts,
        uint[] calldata getId,
        uint[] calldata setId
    ) external payable {
        uint _length = tokens.length;
        uint[] memory _amts = new uint[](_length);
        for (uint i = 0; i < _length; i++) {
            _amts[i] = getUint(getId[i], amts[i]);
        }

        LiqudityInterface(getLiquidityAddress()).accessLiquidity(tokens, _amts);

        for (uint i = 0; i < _length; i++) {
            setUint(setId[i], _amts[i]);

            emit LogFlashBorrow(tokens[i], _amts[i], getId[i], setId[i]);
            bytes32 _eventCode = keccak256("LogFlashBorrow(address,uint256,uint256,uint256)");
            bytes memory _eventParam = abi.encode(tokens[i], _amts[i], getId[i], setId[i]);
            (uint _type, uint _id) = connectorID();
            EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
        }
    }

    /**
     * @dev Return Multiple token liquidity from InstaPool.
     * @param tokens Array of token addresses.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId get token amounts at this IDs from `InstaMemory` Contract.
     * @param setId set token amounts at this IDs in `InstaMemory` Contract.
    */
    function flashMultiPayback(address[] calldata tokens, uint[] calldata getId, uint[] calldata setId) external payable {
        LiqudityInterface liquidityContract = LiqudityInterface(getLiquidityAddress());

        uint _length = tokens.length;

        for (uint i = 0; i < _length; i++) {
            uint _amt = liquidityContract.borrowedToken(tokens[i]);
            (uint feeAmt,) = calculateFeeAmt(tokens[i], _amt);

            _transfer(payable(address(liquidityContract)), tokens[i], _amt);
            _transfer(
                payable(InstaPoolFeeInterface(getInstaPoolFeeAddr()).getFeeCollector()),
                tokens[i],
                feeAmt
            );

            setUint(setId[i], _amt);

            emit LogFlashPayback(tokens[i], _amt, feeAmt, getId[i], setId[i]);
            bytes32 _eventCode = keccak256("LogFlashPayback(address,uint256,uint256,uint256,uint256)");
            bytes memory _eventParam = abi.encode(tokens[i], _amt, feeAmt, getId[i], setId[i]);
            (uint _type, uint _id) = connectorID();
            EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
        }

        liquidityContract.returnLiquidity(tokens);
    }

    /**
     * @dev Return Token Liquidity from InstaPool.
     * @param origin origin address to transfer 20% of the collected fee.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashPaybackOrigin(address origin, address token, uint getId, uint setId) external payable {
        require(origin != address(0), "origin-is-address(0)");
        LiqudityInterface liquidityContract = LiqudityInterface(getLiquidityAddress());
        uint _amt = liquidityContract.borrowedToken(token);

        (uint poolFeeAmt, uint originFeeAmt) = calculateFeeAmtOrigin(token, _amt);

        address[] memory _tknAddrs = new address[](1);
        _tknAddrs[0] = token;

        _transfer(payable(address(liquidityContract)), token, _amt);
        liquidityContract.returnLiquidity(_tknAddrs);
        _transfer(
            payable(InstaPoolFeeInterface(getInstaPoolFeeAddr()).getFeeCollector()),
            token,
            poolFeeAmt
        );
        _transfer(payable(origin), token, originFeeAmt);


        setUint(setId, _amt);

        (uint _type, uint _id) = connectorID();

        emit LogFlashPayback(token, _amt, poolFeeAmt, getId, setId);
        bytes32 _eventCodePayback = keccak256("LogFlashPayback(address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParamPayback = abi.encode(token, _amt, poolFeeAmt, getId, setId);
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCodePayback, _eventParamPayback);

        emit LogOriginFeeCollector(origin, token, _amt, originFeeAmt);
        bytes32 _eventCodeOrigin = keccak256("LogOriginFeeCollector(address,address,uint256,uint256)");
        bytes memory _eventParamOrigin = abi.encode(origin, token, _amt, poolFeeAmt);
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCodeOrigin, _eventParamOrigin);
    }
}


contract ConnectInstaPool is LiquidityAccess {
    string public name = "InstaPool-v2";
}
