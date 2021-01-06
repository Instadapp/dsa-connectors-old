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
    function gemJoinMapping(bytes32) external view returns (address);
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

// MakerDAO Helpers
interface ManagerLike {
    function cdpCan(address, uint, address) external view returns (uint);
    function ilks(uint) external view returns (bytes32);
    function last(address) external view returns (uint);
    function count(address) external view returns (uint);
    function owns(uint) external view returns (address);
    function urns(uint) external view returns (address);
    function vat() external view returns (address);
    function open(bytes32, address) external returns (uint);
    function give(uint, address) external;
    function frob(uint, int, int) external;
    function flux(uint, address, uint) external;
    function move(uint, address, uint) external;
}

interface VatLike {
    function can(address, address) external view returns (uint);
    function ilks(bytes32) external view returns (uint, uint, uint, uint, uint);
    function dai(address) external view returns (uint);
    function urns(bytes32, address) external view returns (uint, uint);
    function frob(
        bytes32,
        address,
        address,
        address,
        int,
        int
    ) external;
    function hope(address) external;
    function move(address, address, uint) external;
    function gem(bytes32, address) external view returns (uint);
}

interface TokenJoinInterface {
    function dec() external returns (uint);
    function gem() external returns (TokenInterface);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface DaiJoinInterface {
    function vat() external returns (VatLike);
    function dai() external returns (TokenInterface);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface JugLike {
    function drip(bytes32) external returns (uint);
}
// End MakerDAO Helpers

contract DSMath {

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function toRad(uint wad) internal pure returns (uint rad) {
        rad = mul(wad, 10 ** 27);
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

}

contract Helpers is DSMath {

    address payable constant feeCollector = 0xb1DC62EC38E6E3857a887210C38418E4A17Da5B2;

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
     * @dev Return Maker MCD DAI_Join Address.
    */
    function getMcdDaiJoin() internal pure returns (address) {
        return 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    }

    /**
     * @dev Return Maker MCD Manager Address.
    */
    function getMcdManager() internal pure returns (address) {
        return 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    }

    /**
     * @dev Return Maker MCD DAI Address.
    */
    function getMcdDai() internal pure returns (address) {
        return 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    }

    /**
     * @dev Return Maker MCD Jug Address.
    */
    function getMcdJug() internal pure returns (address) {
        return 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    }

    /**
     * @dev Return Maker MCD Pot Address.
    */
    function getMcdPot() internal pure returns (address) {
        return 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
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

    function getWithdrawBalanceV2(AaveV2DataProviderInterface aaveData, address token) internal view returns (uint bal) {
        (bal, , , , , , , , ) = aaveData.getUserReserveData(token, address(this));
    }

    function getPaybackBalanceV2(AaveV2DataProviderInterface aaveData, address token, uint rateMode) internal view returns (uint bal) {
        if (rateMode == 1) {
            (, bal, , , , , , , ) = aaveData.getUserReserveData(token, address(this));
        } else {
            (, , bal, , , , , , ) = aaveData.getUserReserveData(token, address(this));
        }
    }

    function getIsColl(AaveV1Interface aave, address token) internal view returns (bool isCol) {
        (, , , , , , , , , isCol) = aave.getUserReserveData(token, address(this));
    }

    function getIsCollV2(AaveV2DataProviderInterface aaveData, address token) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(token, address(this));
    }

    /**
     * @dev Get Vault's ilk.
    */
    function getVaultData(ManagerLike managerContract, uint vault) internal view returns (bytes32 ilk, address urn) {
        ilk = managerContract.ilks(vault);
        urn = managerContract.urns(vault);
    }

    /**
     * @dev Get Vault Debt Amount.
    */
    function _getVaultDebt(
        address vat,
        bytes32 ilk,
        address urn
    ) internal view returns (uint wad) {
        (, uint rate,,,) = VatLike(vat).ilks(ilk);
        (, uint art) = VatLike(vat).urns(ilk, urn);
        uint dai = VatLike(vat).dai(urn);

        uint rad = sub(mul(art, rate), dai);
        wad = rad / RAY;

        wad = mul(wad, RAY) < rad ? wad + 1 : wad;
    }

    /**
     * @dev Get Payback Amount.
    */
    function _getWipeAmt(
        address vat,
        uint amt,
        address urn,
        bytes32 ilk
    ) internal view returns (int dart)
    {
        (, uint rate,,,) = VatLike(vat).ilks(ilk);
        (, uint art) = VatLike(vat).urns(ilk, urn);
        dart = toInt(amt / rate);
        dart = uint(dart) <= art ? - dart : - toInt(art);
    }

    /**
     * @dev Convert String to bytes32.
    */
    function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
        require(bytes(str).length != 0, "string-empty");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            result := mload(add(str, 32))
        }
    }

    /**
     * @dev Get vault ID. If `vault` is 0, get last opened vault.
    */
    function getVault(ManagerLike managerContract, uint vault) internal view returns (uint _vault) {
        if (vault == 0) {
            require(managerContract.count(address(this)) > 0, "no-vault-opened");
            _vault = managerContract.last(address(this));
        } else {
            _vault = vault;
        }
    }

    /**
     * @dev Get Borrow Amount [MakerDAO]
    */
    function _getBorrowAmt(
        address vat,
        address urn,
        bytes32 ilk,
        uint amt
    ) internal returns (int dart)
    {
        address jug = getMcdJug();
        uint rate = JugLike(jug).drip(ilk);
        uint dai = VatLike(vat).dai(urn);
        if (dai < mul(amt, RAY)) {
            dart = toInt(sub(mul(amt, RAY), dai) / rate);
            dart = mul(uint(dart), rate) < mul(amt, RAY) ? dart + 1 : dart;
        }
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

    function _compEnterMarkets(uint length, address[] memory tokens) internal {
        ComptrollerInterface troller = ComptrollerInterface(getComptrollerAddress());
        address[] memory cTokens = new address[](length);

        for (uint i = 0; i < length; i++) {
            cTokens[i] = InstaMapping(getMappingAddr()).cTokenMapping(tokens[i]);
        }
        troller.enterMarkets(cTokens);
    }

    function _compBorrow(
        uint length,
        uint fee,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                address cToken = InstaMapping(getMappingAddr()).cTokenMapping(tokens[i]);

                uint feeAmt = wmul(amts[i], fee);
                uint amt = add(amts[i], feeAmt);

                require(CTokenInterface(cToken).borrow(amt) == 0, "borrow-failed-collateral?");
                if (tokens[i] == getEthAddr()) {
                    feeCollector.transfer(feeAmt);
                } else {
                    TokenInterface(tokens[i]).transfer(feeCollector, feeAmt);
                }
            }
        }
    }

    function _compDeposit(
        uint length,
        uint fee,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                address cToken = InstaMapping(getMappingAddr()).cTokenMapping(tokens[i]);

                uint feeAmt = wmul(amts[i], fee);
                uint amt = sub(amts[i], feeAmt);

                if (tokens[i] != getEthAddr()) {
                    TokenInterface tokenContract = TokenInterface(tokens[i]);
                    tokenContract.approve(cToken, amt);
                    require(CTokenInterface(cToken).mint(amt) == 0, "deposit-failed");
                    tokenContract.transfer(feeCollector, feeAmt);
                } else {
                    CETHInterface(cToken).mint.value(amt)();
                    feeCollector.transfer(feeAmt);
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
        uint fee,
        address[] memory tokens,
        uint[] memory amts,
        uint[] memory rateModes
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                uint feeAmt = wmul(amts[i], fee);
                uint amt = add(amts[i], feeAmt);

                aave.borrow(tokens[i], amt, rateModes[i], getReferralCode());
                if (tokens[i] == getEthAddr()) {
                    feeCollector.transfer(feeAmt);
                } else {
                    TokenInterface(tokens[i]).transfer(feeCollector, feeAmt);
                }
            }
        }
    }

    function _aaveV1Deposit(
        AaveV1Interface aave,
        uint length,
        uint fee,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                uint ethAmt;
                uint feeAmt = wmul(amts[i], fee);
                uint amt = sub(amts[i], feeAmt);

                bool isEth = tokens[i] == getEthAddr();
                if (isEth) {
                    ethAmt = amt;
                    feeCollector.transfer(feeAmt);
                } else {
                    TokenInterface tokenContract = TokenInterface(tokens[i]);
                    tokenContract.approve(address(aave), amt);
                    tokenContract.transfer(feeCollector, feeAmt);
                }

                aave.deposit.value(ethAmt)(tokens[i], amt, getReferralCode());

                if (!getIsColl(aave, tokens[i]))
                    aave.setUserUseReserveAsCollateral(tokens[i], true);
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

contract AaveV2Helpers is AaveV1Helpers {

    function _aaveV2Borrow(
        AaveV2Interface aave,
        uint length,
        uint fee,
        address[] memory tokens,
        uint[] memory amts,
        uint[] memory rateModes
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                uint feeAmt = wmul(amts[i], fee);
                uint amt = add(amts[i], feeAmt);

                bool isEth = tokens[i] == getEthAddr();
                address _token = isEth ? getWethAddr() : tokens[i];

                aave.borrow(_token, amt, rateModes[i], getReferralCode(), address(this));
                convertWethToEth(isEth, TokenInterface(_token), amts[i]);

                if (isEth) {
                    feeCollector.transfer(feeAmt);
                } else {
                    TokenInterface(_token).transfer(feeCollector, feeAmt);
                }
            }
        }
    }

    function _aaveV2Deposit(
        AaveV2Interface aave,
        AaveV2DataProviderInterface aaveData,
        uint length,
        uint fee,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                uint feeAmt = wmul(amts[i], fee);
                uint amt = sub(amts[i], feeAmt);

                bool isEth = tokens[i] == getEthAddr();
                address _token = isEth ? getWethAddr() : tokens[i];
                TokenInterface tokenContract = TokenInterface(_token);

                if (isEth) {
                    feeCollector.transfer(feeAmt);
                } else {
                    tokenContract.transfer(feeCollector, feeAmt);
                }

                convertEthToWeth(isEth, tokenContract, amt);

                tokenContract.approve(address(aave), amt);

                aave.deposit(_token, amt, address(this), getReferralCode());

                if (!getIsCollV2(aaveData, _token)) {
                    aave.setUserUseReserveAsCollateral(_token, true);
                }
            }
        }
    }

    function _aaveV2Withdraw(
        AaveV2Interface aave,
        AaveV2DataProviderInterface aaveData,
        uint length,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                bool isEth = tokens[i] == getEthAddr();
                address _token = isEth ? getWethAddr() : tokens[i];
                TokenInterface tokenContract = TokenInterface(_token);

                aave.withdraw(_token, amts[i], address(this));

                uint _amt = amts[i] == uint(-1) ? getWithdrawBalanceV2(aaveData, _token) : amts[i];

                convertWethToEth(isEth, tokenContract, _amt);
            }
        }
    }

    function _aaveV2Payback(
        AaveV2Interface aave,
        AaveV2DataProviderInterface aaveData,
        uint length,
        address[] memory tokens,
        uint[] memory amts,
        uint[] memory rateModes
    ) internal {
        for (uint i = 0; i < length; i++) {
            if (amts[i] > 0) {
                bool isEth = tokens[i] == getEthAddr();
                address _token = isEth ? getWethAddr() : tokens[i];
                TokenInterface tokenContract = TokenInterface(_token);

                uint _amt = amts[i] == uint(-1) ? getPaybackBalanceV2(aaveData, _token, rateModes[i]) : amts[i];

                convertEthToWeth(isEth, tokenContract, amts[i]);

                aave.repay(_token, _amt, rateModes[i], address(this));
            }
        }
    }
}

contract MakerHelpers is AaveV2Helpers {

    function _makerOpen(string memory colType) internal {
        bytes32 ilk = stringToBytes32(colType);
        require(InstaMapping(getMappingAddr()).gemJoinMapping(ilk) != address(0), "wrong-col-type");
        ManagerLike(getMcdManager()).open(ilk, address(this));
    }

    function _makerBorrow(uint vault, uint amt, uint fee) internal {
        uint feeAmt = wmul(amt, fee);
        uint _amt = add(amt, feeAmt);

        ManagerLike managerContract = ManagerLike(getMcdManager());

        uint _vault = getVault(managerContract, vault);
        (bytes32 ilk, address urn) = getVaultData(managerContract, _vault);

        address daiJoin = getMcdDaiJoin();

        VatLike vatContract = VatLike(managerContract.vat());

        managerContract.frob(
            _vault,
            0,
            _getBorrowAmt(
                address(vatContract),
                urn,
                ilk,
                _amt
            )
        );

        managerContract.move(
            _vault,
            address(this),
            toRad(_amt)
        );

        if (vatContract.can(address(this), address(daiJoin)) == 0) {
            vatContract.hope(daiJoin);
        }

        DaiJoinInterface(daiJoin).exit(address(this), _amt);

        TokenInterface(getMcdDai()).transfer(feeCollector, feeAmt);
    }

    function _makerDeposit(uint vault, uint amt, uint fee) internal {
        uint feeAmt = wmul(amt, fee);
        uint _amt = sub(amt, feeAmt);

        ManagerLike managerContract = ManagerLike(getMcdManager());

        uint _vault = getVault(managerContract, vault);
        (bytes32 ilk, address urn) = getVaultData(managerContract, _vault);

        address colAddr = InstaMapping(getMappingAddr()).gemJoinMapping(ilk);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);
        TokenInterface tokenContract = tokenJoinContract.gem();

        if (address(tokenContract) == getWethAddr()) {
            feeCollector.transfer(feeAmt);
            tokenContract.deposit.value(_amt)();
        } else {
            tokenContract.transfer(feeCollector, feeAmt);
        }

        tokenContract.approve(address(colAddr), _amt);
        tokenJoinContract.join(address(this), _amt);

        VatLike(managerContract.vat()).frob(
            ilk,
            urn,
            address(this),
            address(this),
            toInt(convertTo18(tokenJoinContract.dec(), _amt)),
            0
        );
    }

    function _makerWithdraw(uint vault, uint amt) internal {
        ManagerLike managerContract = ManagerLike(getMcdManager());

        uint _vault = getVault(managerContract, vault);
        (bytes32 ilk, address urn) = getVaultData(managerContract, _vault);

        address colAddr = InstaMapping(getMappingAddr()).gemJoinMapping(ilk);
        TokenJoinInterface tokenJoinContract = TokenJoinInterface(colAddr);

        uint _amt18;
        if (amt == uint(-1)) {
            (_amt18,) = VatLike(managerContract.vat()).urns(ilk, urn);
            amt = convert18ToDec(tokenJoinContract.dec(), _amt18);
        } else {
            _amt18 = convertTo18(tokenJoinContract.dec(), amt);
        }

        managerContract.frob(
            _vault,
            -toInt(_amt18),
            0
        );

        managerContract.flux(
            _vault,
            address(this),
            _amt18
        );

        TokenInterface tokenContract = tokenJoinContract.gem();

        if (address(tokenContract) == getWethAddr()) {
            tokenJoinContract.exit(address(this), amt);
            tokenContract.withdraw(amt);
        } else {
            tokenJoinContract.exit(address(this), amt);
        }
    }

    function _makerPayback(uint vault, uint amt) internal {
        ManagerLike managerContract = ManagerLike(getMcdManager());

        uint _vault = getVault(managerContract, vault);
        (bytes32 ilk, address urn) = getVaultData(managerContract, _vault);

        address vat = managerContract.vat();

        uint _maxDebt = _getVaultDebt(vat, ilk, urn);

        uint _amt = amt == uint(-1) ? _maxDebt : amt;

        require(_maxDebt >= _amt, "paying-excess-debt");

        DaiJoinInterface daiJoinContract = DaiJoinInterface(getMcdDaiJoin());
        daiJoinContract.dai().approve(getMcdDaiJoin(), _amt);
        daiJoinContract.join(urn, _amt);

        managerContract.frob(
            _vault,
            0,
            _getWipeAmt(
                vat,
                VatLike(vat).dai(urn),
                urn,
                ilk
            )
        );
    }
}

contract RefinanceResolver is MakerHelpers {

    // Aave v1 Id - 1
    // Aave v2 Id - 2
    // Compound Id - 3
    struct RefinanceData {
        uint source;
        uint target;
        uint collateralFee;
        uint debtFee;
        address[] tokens;
        uint[] borrowAmts;
        uint[] paybackAmts;
        uint[] withdrawAmts;
        uint[] depositAmts;
        uint[] borrowRateModes;
        uint[] paybackRateModes;
    }

    function refinance(RefinanceData calldata data) external payable {

        require(data.source != data.target, "source-and-target-unequal");

        AaveV2Interface aaveV2 = AaveV2Interface(getAaveV2Provider().getLendingPool());
        AaveV1Interface aaveV1 = AaveV1Interface(getAaveProvider().getLendingPool());
        AaveV1CoreInterface aaveCore = AaveV1CoreInterface(getAaveProvider().getLendingPoolCore());
        AaveV2DataProviderInterface aaveData = getAaveV2DataProvider();

        uint length = data.borrowAmts.length;

        if (data.source == 1 && data.target == 2) {
            _aaveV2Borrow(aaveV2, length, data.debtFee, data.tokens, data.borrowAmts, data.borrowRateModes);
            _aaveV1Payback(aaveV1, length, data.tokens, data.paybackAmts);
            _aaveV1Withdraw(aaveCore, length, data.tokens, data.withdrawAmts);
            _aaveV2Deposit(aaveV2, aaveData, length, data.collateralFee, data.tokens, data.depositAmts);
        } else if (data.source == 1 && data.target == 3) {
            _compBorrow(length, data.debtFee, data.tokens, data.borrowAmts);
            _aaveV1Payback(aaveV1, length, data.tokens, data.paybackAmts);
            _aaveV1Withdraw(aaveCore, length, data.tokens, data.withdrawAmts);
            _compDeposit(length, data.collateralFee, data.tokens, data.depositAmts);
        }
    }
}
