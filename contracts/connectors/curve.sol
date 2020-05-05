pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface ICurve {
    function get_virtual_price() external returns (uint256 out);

    function calc_token_amount(uint256[4] calldata amounts, bool deposit) external returns (uint256 amount);

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;

    function get_dy(int128 i, int128 j, uint256 dx)
        external
        returns (uint256 out);

    function get_dy_underlying(int128 i, int128 j, uint256 dx)
        external
        returns (uint256 out);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256[4] calldata min_amounts
    ) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount)
        external;
}

interface ICurveZap {
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external returns (uint256 amount);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;

}


contract CurveProtocol is Stores, DSMath {

    event LogBuy(address sellAddr, address buyAddr, uint256 sellAmount, uint256 buyAmount);
    event LogAddLiquidity(uint256[4] amounts, uint256 mintAmount);
    event LogRemoveLiquidityImbalance(uint256[4] amounts, uint256 burnAmount);
    event LogRemoveLiquidityOneCoin(address receiveCoin, uint256 amount);

    address public constant sCurveSwap = address(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    address public constant sCurveToken = address(0xC25a3A3b969415c80451098fa907EC722572917F);
    address public constant sCurveZap = address(0xFCBa3E75865d2d561BE8D220616520c171F12851);

    address public constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public constant sUSD = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);

    mapping (int128 => address) addresses;

    constructor() public {
        addresses[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        addresses[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        addresses[2] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        addresses[3] = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    }

    function get_virtual_price() external returns (uint256) {
        ICurve curve = ICurve(sCurveSwap);
        return curve.get_virtual_price();
    }


    function get_dy(int128 i, int128 j, uint256 dx) public returns(uint256) {
        ICurve curve = ICurve(sCurveSwap);
        return curve.get_dy(i, j, dx);
    }

    function exchange(int128 i, int128 j, uint256 dx, uint256 slippage) external {
        TokenInterface(addresses[i]).approve(sCurveSwap, dx);
        uint256 dy = get_dy(i, j, dx);
        uint256 min_dy = mul(dy, sub(100, slippage)) / 100;
        ICurve(sCurveSwap).exchange(i, j, dx, min_dy);

        uint256 bought = TokenInterface(addresses[j]).balanceOf(address(this));
        emit LogBuy(addresses[i], addresses[j], dx, bought);

    }

    function add_liquidity(uint256[4] calldata amounts, uint256 slippage) external {
        for(uint256 i = 0; i < 4; i++) {
            uint256 amount = amounts[i];
            if(amount == 0) continue;
            int128 coin_i = int128(i);
            TokenInterface(addresses[coin_i]).approve(sCurveSwap, amount);
        }
        uint256 min_mint_amount = ICurve(sCurveSwap).calc_token_amount(amounts, true);
        ICurve(sCurveSwap).add_liquidity(amounts, mul(min_mint_amount, sub(100, slippage)) / 100);

        uint256 mintAmount = TokenInterface(sCurveToken).balanceOf(address(this));
        emit LogAddLiquidity(amounts, mintAmount);
    }

    function remove_liquidity_imbalance(uint256[4] calldata amounts) external {
        uint256 max_burn_amount = ICurve(sCurveSwap).calc_token_amount(amounts, false);
        uint256 balance = TokenInterface(sCurveToken).balanceOf(address(this));

        ICurve(sCurveSwap).remove_liquidity_imbalance(amounts, mul(max_burn_amount, 101) / 100);

        uint burnAmount = sub(balance, TokenInterface(sCurveToken).balanceOf(address(this)));
        emit LogRemoveLiquidityImbalance(amounts, burnAmount);
    }

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 slippage) external {
        uint256 min_uamount = ICurveZap(sCurveZap).calc_withdraw_one_coin(_token_amount, i);
        min_uamount = mul(min_uamount, sub(100, slippage) / 100);
        uint256 balance = TokenInterface(addresses[i]).balanceOf(address(this));

        TokenInterface(sCurveToken).approve(sCurveZap, _token_amount);
        ICurveZap(sCurveZap).remove_liquidity_one_coin(_token_amount, i, min_uamount);

        uint256 newBalance = TokenInterface(addresses[i]).balanceOf(address(this));
        uint256 received_amount = sub(newBalance, balance);
        emit LogRemoveLiquidityOneCoin(addresses[i], received_amount);
    }

}

contract ConnectCurve is CurveProtocol {
    string public name = "Curve-susdv2-v1";
}
