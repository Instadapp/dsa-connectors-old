pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface AaveInterface {
    function deposit(address _asset, uint256 _amount, address _onBehalfOf, uint16 _referralCode) external;
    function withdraw(address _asset, uint256 _amount, address _to) external;
    function borrow(
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    ) external;
    function repay(address _asset, uint256 _amount, uint256 _rateMode, address _onBehalfOf) external;
    function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external;
    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}

interface AaveLendingPoolProviderInterface {
    function getLendingPool() external view returns (address);
}

// Aave Protocol Data Provider
interface AaveDataProviderInterface {
    function getReserveTokensAddresses(address _asset) external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );
    function getUserReserveData(address _asset, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
}

interface AaveAddressProviderRegistryInterface {
    function getAddressesProvidersList() external view returns (address[] memory);
}

interface ATokenInterface {
    function scaledBalanceOf(address _user) external view returns (uint256);
    function isTransferAllowed(address _user, uint256 _amount) external view returns (bool);
    function balanceOf(address _user) external view returns(uint256);
}

contract AaveHelpers is DSMath, Stores {
    /**
     * @dev get Aave Lending Pool Provider
    */
    function getAaveProvider() internal pure returns (AaveLendingPoolProviderInterface) {
        // return AaveLendingPoolProviderInterface(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8); //mainnet
        return AaveLendingPoolProviderInterface(0x652B2937Efd0B5beA1c8d54293FC1289672AFC6b); //kovan
    }

    /**
     * @dev get Aave Protocol Data Provider
    */
    function getAaveDataProvider() internal pure returns (AaveDataProviderInterface) {
        // return AaveProtocolDataProviderInterface(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8); //mainnet
        return AaveDataProviderInterface(0x744C1aaA95232EeF8A9994C4E0b3a89659D9AB79); //kovan
    }

    /**
     * @dev Return Weth address
    */
    function getWethAddr() internal pure returns (address) {
        return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // Kovan WETH Address
    }

    /**
     * @dev get Referral Code
    */
    function getReferralCode() internal pure returns (uint16) {
        return 0;
    }

    function getIsColl(AaveDataProviderInterface aaveData, address token, address user) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(token, user);
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit.value(amount)();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            token.approve(address(token), amount);
            token.withdraw(amount);
        }
    }
}

contract BasicResolver is AaveHelpers {
    event LogDeposit(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(address indexed token, uint256 tokenAmt, uint256 indexed rateMode, uint256 getId, uint256 setId);
    event LogPayback(address indexed token, uint256 tokenAmt, uint256 indexed rateMode, uint256 getId, uint256 setId);

    function deposit(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        AaveDataProviderInterface aaveData = getAaveDataProvider();

        bool isEth = token == getEthAddr();
        address _token = isEth ? getWethAddr() : token;

        TokenInterface tokenContract = TokenInterface(_token);

        if (isEth) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            convertEthToWeth(isEth, tokenContract, _amt);
        } else {
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
        }

        tokenContract.approve(address(aave), _amt);

        aave.deposit(_token, _amt, address(this), getReferralCode());

        if (!getIsColl(aaveData, _token, address(this))) {
            aave.setUserUseReserveAsCollateral(_token, true);
        }

        setUint(setId, _amt);

        emit LogDeposit(token, _amt, getId, setId);
        // bytes32 _eventCode = keccak256("LogDeposit(address,uint256,uint256,uint256)");
        // bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        // emitEvent(_eventCode, _eventParam);
    }

    function withdraw(address token, uint amt, uint getId, uint setId) external {
        uint _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        bool isEth = token == getEthAddr();
        address _token = isEth ? getWethAddr() : token;

        TokenInterface tokenContract = TokenInterface(_token);

        uint initialBal = tokenContract.balanceOf(address(this));
        aave.withdraw(_token, _amt, address(this));
        uint finalBal = tokenContract.balanceOf(address(this));

        convertWethToEth(isEth, tokenContract, finalBal);
        
        _amt = sub(finalBal, initialBal);
        setUint(setId, _amt);

        emit LogWithdraw(token, _amt, getId, setId);
        // bytes32 _eventCode = keccak256("LogWithdraw(address,uint256,uint256,uint256)");
        // bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        // emitEvent(_eventCode, _eventParam);
    }

    function borrow(address token, uint amt, uint rateMode, uint getId, uint setId) external {
        uint _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());

        bool isEth = token == getEthAddr();
        address _token = isEth ? getWethAddr() : token;

        aave.borrow(_token, _amt, rateMode, getReferralCode(), address(this));
        convertWethToEth(isEth, TokenInterface(_token), _amt);

        setUint(setId, _amt);

        emit LogBorrow(token, _amt, rateMode, getId, setId);
        // bytes32 _eventCode = keccak256("LogBorrow(address,uint256,uint256,uint256,uint256)");
        // bytes memory _eventParam = abi.encode(token, _amt, rateMode, getId, setId);
        // emitEvent(_eventCode, _eventParam);
    }

    function payback(address token, uint amt, uint rateMode, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());

        bool isEth = token == getEthAddr();
        address _token = isEth ? getWethAddr() : token;

        TokenInterface tokenContract = TokenInterface(_token);

        if (isEth) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            convertEthToWeth(isEth, tokenContract, _amt);
        } else {
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
        }

        tokenContract.approve(address(aave), _amt);

        aave.repay(_token, _amt, rateMode, address(this));

        setUint(setId, _amt);

        emit LogPayback(token, _amt, rateMode, getId, setId);
        // bytes32 _eventCode = keccak256("LogPayback(address,uint256,uint256,uint256,uint256)");
        // bytes memory _eventParam = abi.encode(token, _amt, rateMode, getId, setId);
        // emitEvent(_eventCode, _eventParam);
    }
}

contract ConnectAaveV2 is BasicResolver {
    string public name = "Aave-v2";
}