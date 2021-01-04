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
     * @dev enter compound market
     */
    function enterMarkets(address[] memory cErc20) internal {
        ComptrollerInterface(getComptrollerAddress()).enterMarkets(cErc20);
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
                if (tokens[i] != getEthAddr()) {
                    TokenInterface tokenContract = TokenInterface(tokens[i]);
                    tokenContract.approve(cToken, amts[i]);
                    require(cTokenContract.repayBorrow(amts[i]) == 0, "repay-failed.");
                } else {
                    CETHInterface(cToken).repayBorrow.value(amts[i])();
                }
            }
        }
    }
}
