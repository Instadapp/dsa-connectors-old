const {
  BN,           // Big Number support
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  balance,
  ether
} = require('@openzeppelin/test-helpers');

const ConnectSBTCCurve = artifacts.require('ConnectSBTCCurve');
const erc20 = require("@studydefi/money-legos/erc20");
const uniswap = require("@studydefi/money-legos/uniswap");
const sbtcABI = require("./abi/sbtc.json");
const erc20ABI = require("./abi/erc20.js");
const connectorsABI = require("./abi/connectors.json");
const accountABI = require("./abi/account.json");
const curveSwap = require("./abi/curveSwap.json");

contract('ConnectSBTCCurve', async accounts => {
  const [sender, receiver] =  accounts;
  let masterAddress = "0xfcd22438ad6ed564a1c26151df73f6b33b817b56";
  let accountID = 7;
  let dsrAddr = "0xEEB007bea2Bbb0cA6502217E8867f8f7b021B8D5";

  let connectorsAddr = "0xD6A602C01a023B98Ecfb29Df02FBA380d3B21E0c";
  let connectorInstance = new web3.eth.Contract(connectorsABI, connectorsAddr);

  // let accountAddr = "0x939Daad09fC4A9B8f8A9352A485DAb2df4F4B3F8";
  let accountInstance = new web3.eth.Contract(accountABI, dsrAddr);
  let connectSBTCCurve;
  let wbtcContract = new web3.eth.Contract(erc20.wbtc.abi, erc20.wbtc.address);

  before(async function () {
    connectSBTCCurve = await ConnectSBTCCurve.deployed();

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
    console.log("Sender WBTC Before: ", wbtcBefore.toString());

    const balanceBefore = await web3.eth.getBalance(sender);
    console.log("Sender Balance Before: ", balanceBefore.toString());

    await wbtcExchange.methods.ethToTokenSwapInput(
      1, // min amount of token retrieved
      2525644800, // random timestamp in the future (year 2050)
    ).send(
      {
        gas: 4000000,
        value: ether("10"),
        from: sender
      }
    );

    let wbtcAfter = await wbtcContract.methods.balanceOf(sender).call();
    console.log("Sender WBTC After: ", wbtcAfter.toString());
    const balanceAfter = await web3.eth.getBalance(sender);
    console.log("Sender Balance After: ", balanceAfter.toString());

    expect(wbtcAfter - wbtcBefore).to.be.at.least(10000000);

    // send WBTC to master
    await wbtcContract.methods.transfer(dsrAddr, 10000000).send({from: sender});
    // send WBTC to connector
    // await wbtcContract.methods.transfer(connectSBTCCurve.address, 10000000).send({from: sender});

    // Send ETH to master
    await web3.eth.sendTransaction({from: sender, to: masterAddress, value: ether("5")});

    let connectorID  = await connectSBTCCurve.connectorID();

    // Enable the the given connector address
    await connectorInstance.methods.enable(connectSBTCCurve.address).send({from: masterAddress});
    // check if the give connector address is enabled.
    let isEnabled = await connectorInstance.methods.connectors(connectSBTCCurve.address).call();
    assert.ok(isEnabled);
  });

  it('can sell WBTC for SBTC', async function () {
    const sbtcContract = new web3.eth.Contract(sbtcABI, "0xfe18be6b3bd88a2d2a7f928d00292e7a9963cfc6");

    const sbtcBefore = await sbtcContract.methods.balanceOf(dsrAddr).call();
    console.log("Master SBTC Before: ", sbtcBefore.toString());
    let wbtcBefore = await wbtcContract.methods.balanceOf(dsrAddr).call();
    console.log("Master WBTC Before: ", wbtcBefore.toString());

    const encoded = await connectSBTCCurve.contract.methods.sell(
      "0xfe18be6b3bd88a2d2a7f928d00292e7a9963cfc6",
      erc20.wbtc.address,
      10000000,
      ( 0.09 / 0.1 * 1e18 ).toString(),
      0,
      0,
    ).encodeABI();

    await wbtcContract.methods.approve("0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714", 10000000).send({from: masterAddress});
    const curveSwapContract = new web3.eth.Contract(curveSwap, "0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714");
    const tx = await curveSwapContract.methods.exchange(1, 2, 1000000, 1).send({ from: masterAddress });
    console.log(tx);

    // const tx = await connectSBTCCurve.contract.methods.sell(
    //   "0xfe18be6b3bd88a2d2a7f928d00292e7a9963cfc6",
    //   erc20.wbtc.address,
    //   1000000,
    //   1,
    //   0,
    //   0,
    // ).send({from: masterAddress});
    // console.log(tx);

    //Inputs for `cast()` function of DSA Account.
    const castInputs = [
      [connectSBTCCurve.address],
      [encoded],
      masterAddress
    ]

    // Execute `cast()` function
    // const tx = await accountInstance.methods.cast(...castInputs).send({from: masterAddress});
    // console.log(tx);

    let wbtcAfter = await wbtcContract.methods.balanceOf(dsrAddr).call();
    console.log("Master WBTC After: ", wbtcAfter.toString());
    const sbtcAfter = await sbtcContract.methods.balanceOf(dsrAddr).call();
    console.log("Master SBTC After: ", sbtcAfter.toString());
    expect(sbtcAfter - sbtcBefore).to.be.at.least(+ether("0.09"));
  });

  it('can add and remove liquidity for wbtc', async function() {
    const curveTokenContract = new web3.eth.Contract(
    erc20ABI,
      "0x075b1bb99792c9e1041ba13afef80c91a1e70fb3"
  )

    let wbtcBefore = await wbtcContract.methods.balanceOf(dsrAddr).call();
    console.log("Master WBTC Before: ", wbtcBefore.toString());

    const encodedDeposit = await connectSBTCCurve.contract.methods.deposit(
      erc20.wbtc.address,
      10000000,
      ( 0.09 / 0.1 * 1e18 ).toString(),
      0,
      0
    ).encodeABI();

    //Inputs for `cast()` function of DSA Account.
    const castInputsDeposit = [
      [connectSBTCCurve.address],
      [encodedDeposit],
      masterAddress
    ]

    // Execute `cast()` function
    const txDeposit = await accountInstance.methods.cast(...castInputsDeposit).send({from: masterAddress});
    console.log(txDeposit);

    const balanceDeposit = await curveTokenContract.methods.balanceOf(dsrAddr);

    expect(balanceDeposit).to.be.at.least(ether("0.09"));

    const encodedWithdraw = await connectSBTCCurve.contract.methods.withdraw(
      erc20.wbtc.address,
      10000000,
      ( 0.09 / 0.1 * 1e18 ).toString(),
      0,
      0
    ).encodeABI();

    //Inputs for `cast()` function of DSA Account.
    const castInputsWithdraw = [
      [connectSBTCCurve.address],
      [encodedWithdraw],
      masterAddress
    ]

    // Execute `cast()` function
    const txWithdraw = await accountInstance.methods.cast(...castInputsWithdraw).send({from: masterAddress});
    console.log(txWithdraw);

    const balanceWithdraw = await curveTokenContract.methods.balanceOf(dsrAddr);

    expect(balanceWithdraw).to.equal(0);
  });

});
