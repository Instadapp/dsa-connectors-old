const {
  BN,           // Big Number support
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  balance,
  ether
} = require('@openzeppelin/test-helpers');

const CurveSBTCProtocol = artifacts.require('CurveSBTCProtocol');
const erc20 = require("@studydefi/money-legos/erc20");
const uniswap = require("@studydefi/money-legos/uniswap");
const sbtcABI = require("./abi/sbtc.json");
const erc20ABI = require("./abi/erc20.js");

contract('CurveSBTCProtocol', async accounts => {
  const [sender, receiver] =  accounts;
  let contract;

  beforeEach(async function () {
    contract = await CurveSBTCProtocol.deployed()

    let wbtcContract = new web3.eth.Contract(erc20.wbtc.abi, erc20.wbtc.address);

    let uniswapFactory = new web3.eth.Contract(
      uniswap.factory.abi,
      uniswap.factory.address
    );

    const wbtcExchangeAddress = await uniswapFactory.methods.getExchange(
      erc20.wbtc.address,
    ).call();

    const wbtcExchange = new web3.eth.Contract(
      uniswap.exchange.abi,
      wbtcExchangeAddress
    );

    const wbtcBefore = await wbtcContract.methods.balanceOf(sender).call();

    await wbtcExchange.methods.ethToTokenSwapInput(
      1, // min amount of token retrieved
      2525644800, // random timestamp in the future (year 2050)
    ).send(
      {
        gas: 4000000,
        value: ether("5"),
        from: sender
      }
    );

    let wbtcAfter = await wbtcContract.methods.balanceOf(sender).call();

    expect(wbtcAfter - wbtcBefore).to.be.at.least(10000000);
  });

  it('can sell WBTC for SBTC', async function () {
    const sbtcContract = new web3.eth.Contract(sbtcABI, "0xfe18be6b3bd88a2d2a7f928d00292e7a9963cfc6");

    const sbtcBefore = await sbtcContract.methods.balanceOf(sender).call();

    const tx = await contract.sell(
      "0xfe18be6b3bd88a2d2a7f928d00292e7a9963cfc6",
      erc20.wbtc.address,
      10000000,
      ( 0.09 / 0.1 * 1e18 ).toString(),
      0,
      0,
      {
        gas: 4000000,
        from: sender
      }
    );
    console.log(tx);

    const sbtcAfter = await sbtcContract.methods.balanceOf(sender).call();
    expect(sbtcAfter - sbtcBefore).to.be.at.least(ether("0.09"));
  });

  it('can add liquidity for wbtc', async function() {
    const curveTokenContract = new web3.eth.Contract(
      erc20ABI,
      "0x075b1bb99792c9e1041ba13afef80c91a1e70fb3"
    )

    const txDeposit = await contract.deposit(
      erc20.wbtc.address,
      10000000,
      ( 0.09 / 0.1 * 1e18 ).toString(),
      0,
      0,
      {
        gas: 4000000,
        from: sender
      }
    );
    console.log(txDeposit);

    const balanceDeposit = await curveTokenContract.methods.balanceOf(sender);

    expect(balanceDeposit).to.be.at.least(ether("0.09"));

    const txWithdraw = await contract.withdraw(
      erc20.wbtc.address,
      10000000,
      ( 0.09 / 0.1 * 1e18 ).toString(),
      0,
      0,
      {
        gas: 4000000,
        from: sender
      }
    );
    console.log(txWithdraw);

    const balanceWithdraw = await curveTokenContract.methods.balanceOf(sender);

    expect(balanceWithdraw).to.equal(0);
  });

});
