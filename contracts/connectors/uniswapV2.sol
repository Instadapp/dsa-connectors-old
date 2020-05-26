pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract UniswapHelpers is Stores, DSMath {
    /**
     * @dev Return WETH address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    /**
     * @dev Return uniswap v2 router Address
     */
    function getUniswapAddr() internal pure returns (address) {
        return 0x794e6e91555438aFc3ccF1c5076A74F42133d08D;
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
        _sell = sell == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    }

    function convertEthToWeth(TokenInterface token, uint amount) internal {
        if(address(token) == getAddressWETH()) token.deposit.value(amount)();
    }

    function convertWethToEth(TokenInterface token, uint amount) internal {
       if(address(token) == getAddressWETH()) {
            token.approve(getAddressWETH(), amount);
            token.withdraw(amount);
        }
    }

    function getExpectedBuyAmt(
        IUniswapV2Router01 router,
        address[] memory paths,
        uint sellAmt
    ) internal view returns(uint buyAmt) {
        uint[] memory amts = router.getAmountsOut(
            sellAmt,
            paths
        );
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(
        IUniswapV2Router01 router,
        address[] memory paths,
        uint buyAmt
    ) internal view returns(uint sellAmt) {
        uint[] memory amts = router.getAmountsOut(
            buyAmt,
            paths
        );
        sellAmt = amts[1];
    }

    function checkPair(
        IUniswapV2Router01 router,
        address[] memory paths
    ) internal view {
        address pair = IUniswapV2Factory(router.factory()).getPair(paths[0], paths[1]);
        require(pair != address(0), "No-exchange-address");
    }

    function getPaths(
        address sellAddr,
        address buyAddr
    ) internal pure returns(address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
    }
}

contract LiquidityHelpers is UniswapHelpers {

    function changeEthToWeth(
        address[] memory tokens
    ) internal pure returns(TokenInterface[] memory _tokens) {
        _tokens = new TokenInterface[](2);
        _tokens[0] = tokens[0] == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(tokens[0]);
        _tokens[1] = tokens[1] == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(tokens[1]);
       
    }

    function _addLiquidity(
        address[] memory tokens,
        uint[] memory _amts,
        uint[] memory slippages,
        uint deadline
    ) internal returns (uint _amtA, uint _amtB, uint _liquidity) {
        IUniswapV2Router01 router = IUniswapV2Router01(getUniswapAddr());
        TokenInterface[] memory _tokens = changeEthToWeth(tokens);
        _amts[0] = _amts[0] == uint(-1) ? _tokens[0].balanceOf(address(this)) : _amts[0];
        _amts[1] = _amts[1] == uint(-1) ? _tokens[1].balanceOf(address(this)) : _amts[1];

        convertEthToWeth(_tokens[0], _amts[0]);
        convertEthToWeth(_tokens[1], _amts[1]);
        _tokens[0].approve(address(router), _amts[0]);
        _tokens[0].approve(address(router), _amts[1]);
    
       (_amtA, _amtB, _liquidity) = router.addLiquidity(
            address(_tokens[0]),
            address(_tokens[1]),
            _amts[0],
            _amts[1],
            slippages[0],
            slippages[1],
            address(this),
            now + deadline // TODO - deadline?
        );
    }

    function _removeLiquidity(
        address[] memory tokens,
        uint _amt,
        uint[] memory slippages,
        uint deadline
    ) internal returns (uint _amtA, uint _amtB) {
        IUniswapV2Router01 router = IUniswapV2Router01(getUniswapAddr());
        TokenInterface[] memory _tokens = changeEthToWeth(tokens);
        address exchangeAddr = IUniswapV2Factory(router.factory()).getPair(address(_tokens[0]), address(_tokens[1]));
        require(exchangeAddr != address(0), "pair-not-found.");
        TokenInterface(exchangeAddr).approve(address(router), _amt);

       (_amtA, _amtB) = router.removeLiquidity(
            address(_tokens[0]),
            address(_tokens[1]),
            _amt,
            slippages[0],
            slippages[1],
            address(this),
            now + deadline // TODO - deadline?
        );

        convertWethToEth(_tokens[0], _amtA);
        convertWethToEth(_tokens[1], _amtB);
    }
}

contract UniswapLiquidity is LiquidityHelpers {
    event LogDepositLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint amtA,
        uint amtB,
        uint uniAmount,
        uint[] getId,
        uint setId
    );

    event LogWithdrawLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint amountA,
        uint amountB,
        uint uniAmount,
        uint getId,
        uint[] setId
    );

    function emitDeposit(
        address[] memory tokens,
        uint _amtA,
        uint _amtB,
        uint _uniAmt,
        uint[] memory getIds,
        uint setId
    ) internal {
         emit LogDepositLiquidity(
            tokens[0],
            tokens[1],
            _amtA,
            _amtB,
            _uniAmt,
            getIds,
            setId
        );

        bytes32 _eventCode = keccak256("LogDepositLiquidity(address,address,uint256,uint256,uint256,uint256[],uint256)");
        bytes memory _eventParam = abi.encode(
            tokens[0],
            tokens[1],
            _amtA,
            _amtB,
            _uniAmt,
            getIds,
            setId
        );
        emitEvent(_eventCode, _eventParam);
    }

    function emitWithdraw(
        address[] memory tokens,
        uint _amtA,
        uint _amtB,
        uint _uniAmt,
        uint getId,
        uint[] memory setIds
    ) internal {
            emit LogWithdrawLiquidity(
            tokens[0],
            tokens[1],
            _amtA,
            _amtB,
            _uniAmt,
            getId,
            setIds
        );
        bytes32 _eventCode = keccak256("LogWithdrawLiquidity(address,address,uint256,uint256,uint256,uint256[],uint256)");
        bytes memory _eventParam = abi.encode(
            tokens[0],
            tokens[1],
            _amtA,
            _amtB,
            _uniAmt,
            getId,
            setIds
        );
        emitEvent(_eventCode, _eventParam);
    }

    function deposit(
        address[]  calldata tokens,
        uint[] calldata amts,
        uint[] calldata slippages,
        uint deadline,
        uint[] calldata getIds,
        uint setId
    ) external payable {
        require(tokens.length == 2 && amts.length == 2, "length-is-not-two");
        uint[] memory _amts = new uint[](2);
        for (uint i = 0; i < getIds.length; i++) {
            _amts[i] = getUint(getIds[i], amts[i]);
        }

        (uint _amtA, uint _amtB, uint _uniAmt) = _addLiquidity(
                                            tokens,
                                            _amts,
                                            slippages,
                                            deadline
                                            );
        setUint(setId, _uniAmt);
        emitDeposit(tokens, _amtA, _amtB, _uniAmt, getIds, setId);
    }

    function withdraw(
        address[]  calldata tokens,
        uint amt,
        uint[] calldata slippages,
        uint deadline,
        uint getId,
        uint[] calldata setIds
    ) external payable {
        require(tokens.length == 2, "length-is-not-two");
        uint _uniAmt = getUint(getId, amt);

        (uint _amtA, uint _amtB) = _removeLiquidity(tokens, _uniAmt, slippages, deadline);

        setUint(setIds[0], _amtA);
        setUint(setIds[1], _amtB);
        emitWithdraw(tokens, _amtA, _amtB, _uniAmt, getId, setIds);
    }
}

contract UniswapResolver is UniswapLiquidity {
    event LogBuy(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    /**
     * @dev Buy ETH/ERC20_Token.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param buyAmt buying token amount.
     * @param unitAmt unit amount of sellAmt/buyAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function buy(
        address buyAddr,
        address sellAddr,
        uint buyAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable {
        uint _buyAmt = getUint(getId, buyAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(_buyAddr), address(_sellAddr));

        uint __buyAmt18 = convertTo18(_buyAddr.decimals(), _buyAmt);
        uint _slippageAmt = convert18ToDec(_sellAddr.decimals(), wmul(unitAmt, __buyAmt18));

        IUniswapV2Router01 router = IUniswapV2Router01(getUniswapAddr());

        checkPair(router, paths);
        uint _expectedAmt = getExpectedSellAmt(router, paths, _buyAmt);
        require(_slippageAmt >= _expectedAmt, "Too much slippage");

        convertEthToWeth(_sellAddr, _expectedAmt);
        _sellAddr.approve(address(router), _expectedAmt);

        uint[] memory _amts = router.swapTokensForExactTokens(
            _buyAmt,
            _expectedAmt,
            paths,
            address(this),
            now + 6 hours // TODO - deadline?
        );

        uint _sellAmt = _amts[0];

        convertWethToEth(_buyAddr, _buyAmt);

        setUint(setId, _sellAmt);

        emit LogBuy(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogBuy(address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Sell ETH/ERC20_Token.
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
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(_buyAddr), address(_sellAddr));

        if (_sellAmt == uint(-1)) {
            _sellAmt = sellAddr == getEthAddr() ? address(this).balance : _buyAddr.balanceOf(address(this));
        }

        uint _sellAmt18 = convertTo18(_sellAddr.decimals(), _sellAmt);
        uint _slippageAmt = convert18ToDec(_buyAddr.decimals(), wmul(unitAmt, _sellAmt18));

        IUniswapV2Router01 router = IUniswapV2Router01(getUniswapAddr());

        checkPair(router, paths);
        uint _expectedAmt = getExpectedBuyAmt(router, paths, _sellAmt);
        require(_slippageAmt >= _expectedAmt, "Too much slippage");

        convertEthToWeth(_sellAddr, _sellAmt);
        _sellAddr.approve(address(router), _sellAmt);

        uint[] memory _amts = router.swapExactTokensForTokens(
            _sellAmt,
            _expectedAmt,
            paths,
            address(this),
            now + 6 hours // TODO - deadline?
        );

        uint _buyAmt = _amts[1];

        convertWethToEth(_buyAddr, _buyAmt);

        setUint(setId, _buyAmt);

        emit LogSell(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogSell(address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }
}


contract ConnectUniswapV2 is UniswapResolver {
    string public name = "UniswapV2-v1";
}