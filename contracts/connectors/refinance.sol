pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface MemoryInterface {
    function getUint(uint _id) external returns (uint _num);
    function setUint(uint _id, uint _val) external;
}

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface DSAInterface {
    function isAuth(address) external view returns(bool);
}

// Compound Helpers
interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint); // For ERC20
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function exchangeRateCurrent() external returns (uint);

    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address, address, uint) external returns (bool);
}

interface CETHInterface {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cTokenAddress) external returns (uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
}
// End Compound Helpers

// Aave v1 Helpers
interface AaveV1Interface {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external payable;
    function redeemUnderlying(
        address _reserve,
        address payable _user,
        uint256 _amount,
        uint256 _aTokenBalanceAfterRedeem
    ) external;
    
    function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external;
    function getUserReserveData(address _reserve, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentBorrowBalance,
        uint256 principalBorrowBalance,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint256 liquidityRate,
        uint256 originationFee,
        uint256 variableBorrowIndex,
        uint256 lastUpdateTimestamp,
        bool usageAsCollateralEnabled
    );
    function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external;
    function repay(address _reserve, uint256 _amount, address payable _onBehalfOf) external payable;
}

interface AaveV1ProviderInterface {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
}

interface AaveV1CoreInterface {
    function getReserveATokenAddress(address _reserve) external view returns (address);
}

interface ATokenV1Interface {
    function redeem(uint256 _amount) external;
    function balanceOf(address _user) external view returns(uint256);
    function principalBalanceOf(address _user) external view returns(uint256);

    function allowance(address, address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}
// End Aave v1 Helpers

// Aave v2 Helpers
interface AaveV2Interface {
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

interface AaveV2LendingPoolProviderInterface {
    function getLendingPool() external view returns (address);
}

// Aave Protocol Data Provider
interface AaveV2DataProviderInterface {
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
    function getReserveConfigurationData(address asset) external view returns (
        uint256 decimals,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool usageAsCollateralEnabled,
        bool borrowingEnabled,
        bool stableBorrowRateEnabled,
        bool isActive,
        bool isFrozen
    );
}

interface AaveV2AddressProviderRegistryInterface {
    function getAddressesProvidersList() external view returns (address[] memory);
}

interface ATokenV2Interface {
    function scaledBalanceOf(address _user) external view returns (uint256);
    function isTransferAllowed(address _user, uint256 _amount) external view returns (bool);
    function balanceOf(address _user) external view returns(uint256);
    function transferFrom(address, address, uint) external returns (bool);
}
// End Aave v2 Helpers

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
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
    /**
     * @dev Return ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return Weth address
    */
    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH Address
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // Kovan WETH Address
    }

    /**
     * @dev Return Memory Variable Address
     */
    function getMemoryAddr() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
    }

    /**
     * @dev Return InstaDApp Mapping Address
     */
    function getMappingAddr() internal pure returns (address) {
        return 0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88; // InstaMapping Address
    }

    /**
     * @dev Return CETH Address
     */
    function getCETHAddr() internal pure returns (address) {
        return 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    }

    /**
     * @dev Return Compound Comptroller Address
     */
    function getComptrollerAddress() internal pure returns (address) {
        return 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    }

    /**
     * @dev get Aave Provider
    */
    function getAaveProvider() internal pure returns (AaveV1ProviderInterface) {
        return AaveV1ProviderInterface(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8); //mainnet
        // return AaveV1ProviderInterface(0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5); //kovan
    }

    /**
     * @dev get Aave Lending Pool Provider
    */
    function getAaveV2Provider() internal pure returns (AaveV2LendingPoolProviderInterface) {
        return AaveV2LendingPoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5); //mainnet
        // return AaveV2LendingPoolProviderInterface(0x652B2937Efd0B5beA1c8d54293FC1289672AFC6b); //kovan
    }

    /**
     * @dev get Aave Protocol Data Provider
    */
    function getAaveV2DataProvider() internal pure returns (AaveV2DataProviderInterface) {
        return AaveV2DataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d); //mainnet
        // return AaveV2DataProviderInterface(0x744C1aaA95232EeF8A9994C4E0b3a89659D9AB79); //kovan
    }

    /**
     * @dev get Referral Code
    */
    function getReferralCode() internal pure returns (uint16) {
        return 3228;
    }

   /**
     * @dev enter compound market
     */
    function enterMarkets(address[] memory cErc20) internal {
        ComptrollerInterface(getComptrollerAddress()).enterMarkets(cErc20);
    }

    function getBorrowRateMode(AaveV1Interface aave, address token) internal view returns (uint rateMode) {
        (, , , rateMode, , , , , , ) = aave.getUserReserveData(token, address(this));
    }

    function getWithdrawBalance(AaveV1Interface aave, address token) internal view returns (uint bal) {
        (bal, , , , , , , , , ) = aave.getUserReserveData(token, address(this));
    }

    function getPaybackBalance(AaveV1Interface aave, address account, address token) internal view returns (uint bal, uint fee) {
        (, bal, , , , , fee, , , ) = aave.getUserReserveData(token, account);
    }

    function getTotalBorrowBalance(AaveV1Interface aave, address account, address token) internal view returns (uint amt) {
        (, uint bal, , , , , uint fee, , , ) = aave.getUserReserveData(token, account);
        amt = add(bal, fee);
    }

    function getIsColl(AaveDataProviderInterface aaveData, address token) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(token, address(this));
    }

    function getIsCollV2(AaveV2DataProviderInterface aaveData, address token) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(token, address(this));
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
}

contract CompoundHelpers is Helpers {

    function _compEnterMarkets(uint length, address[] memory tokens) {
        ComptrollerInterface troller = ComptrollerInterface(getComptrollerAddress());
        address[] memory cTokens = new address[](length);

        for (uint i = 0; i < length; i++) {
            cTokens[i] = InstaMapping(getMappingAddr()).cTokenMapping(tokens[i]);
        }
        troller.enterMarkets(cTokens);
    }

    function _compBorrow(
        uint length,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0)
                address cToken = InstaMapping(getMappingAddr()).cTokenMapping(tokens[i]);
                require(CTokenInterface(cToken).borrow(amts[i]) == 0, "borrow-failed-collateral?");
        }
    }

    function _compDeposit(
        uint length,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                address cToken = InstaMapping(getMappingAddr()).cTokenMapping(tokens[i]);
                if (tokens[i] != getEthAddr()) {
                    TokenInterface tokenContract = TokenInterface(tokens[i]);
                    tokenContract.approve(cToken, amts[i]);
                    require(CTokenInterface(cToken).mint(amts[i]) == 0, "deposit-failed");
                } else {
                    CETHInterface(cToken).mint.value(amts[i])();
                }
            }
        }
    }

    function _compWithdraw(
        uint length,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                address cToken = InstaMapping(getMappingAddr()).cTokenMapping(tokens[i]);
                CTokenInterface cTokenContract = CTokenInterface(cToken);
                uint _amt = amts[i];
                if (_amt == uint(-1)) {
                    _amt = cTokenContract.balanceOf(address(this));
                }
                require(cTokenContract.redeemUnderlying(amts[i]) == 0, "withdraw-failed");
            }
        }
    }

    function _compPayback(
        uint length,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                address cToken = InstaMapping(getMappingAddr()).cTokenMapping(tokens[i]);
                CTokenInterface cTokenContract = CTokenInterface(cToken);

                uint _amt = amts[i];
                if (_amt == uint(-1)) {
                    _amt = cTokenContract.borrowBalanceCurrent(address(this));
                }
                if (tokens[i] != getEthAddr()) {
                    TokenInterface tokenContract = TokenInterface(tokens[i]);
                    tokenContract.approve(cToken, _amt);
                    require(cTokenContract.repayBorrow(_amt) == 0, "repay-failed.");
                } else {
                    CETHInterface(cToken).repayBorrow.value(_amt)();
                }
            }
        }
    }
}

contract AaveV1Helpers is CompoundHelpers {

    function _aaveV1Borrow(
        AaveV1Interface aave,
        uint length,
        address[] memory tokens,
        uint[] memory amts,
        uint[] memory rateModes
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                aave.borrow(tokens[i], amts[i], rateModes[i], getReferralCode());
            }
        }
    }

    function _aaveV1Deposit(
        AaveV1Interface aave,
        uint length,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                uint ethAmt;
                bool isEth = tokens[i] == getEthAddr();
                if (isEth) {
                    ethAmt = amts[i];
                } else {
                    TokenInterface tokenContract = TokenInterface(tokens[i]);
                    tokenContract.approve(address(aave), amts[i]);
                }

                aave.deposit.value(ethAmt)(tokens[i], amts[i], getReferralCode());

                if (!getIsColl(aave, tokens[i]))
                    aave.setUserUseReserveAsCollateral(token, true);
            }
        }
    }

    function _aaveV1Withdraw(
        AaveV1CoreInterface aaveCore,
        uint length,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                ATokenV1Interface atoken = ATokenV1Interface(aaveCore.getReserveATokenAddress(tokens[i]));
                atoken.redeem(amts[i]);
            }
        }
    }

    function _aaveV1Payback(
        AaveV1Interface aave,
        uint length,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                uint ethAmt;
                bool isEth = tokens[i] == getEthAddr();
                if (isEth) {
                    ethAmt = amts[i];
                } else {
                    TokenInterface tokenContract = TokenInterface(tokens[i]);
                    tokenContract.approve(address(aave), amts[i]);
                }

                aave.repay.value(ethAmt)(tokens[i], amts[i], payable(address(this)));
            }
        }
    }
}
