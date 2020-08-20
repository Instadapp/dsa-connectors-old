const {
  BN,           // Big Number support
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  balance,
  ether
} = require('@openzeppelin/test-helpers');

const MockContract = artifacts.require("MockContract");
const MockCurveGauge = artifacts.require('MockCurveGauge');
const MockCurveGaugeMapping = artifacts.require('MockCurveGaugeMapping');
const erc20ABI = require("./abi/erc20.js");
const gaugeABI = require("./abi/curveGauge.json");

contract("ConnectCurveGauge", async accounts => {
  const [sender, receiver] =  accounts;
  let mock, mockCurveGauge, mockCurveGaugeMapping;

  before(async function () {
    mock = await MockContract.new();
    mockCurveGaugeMapping = await MockCurveGaugeMapping.new();
    mockCurveGauge = await MockCurveGauge.new(mock.address, mockCurveGaugeMapping.address);
    // lp_token = new web3.eth.Contract(erc20ABI, mock.address);
    curveGauge = new web3.eth.Contract(gaugeABI, mock.address)
    // mocking lp_token
    let lp_token = await curveGauge.methods.lp_token().encodeABI();
    await mock.givenMethodReturnAddress(lp_token, mock.address);
    // mocking crv_token
    let crv_token = await curveGauge.methods.crv_token().encodeABI();
    await mock.givenMethodReturnAddress(crv_token, mock.address);
    // mocking rewarded_token
    let rewarded_token = await curveGauge.methods.rewarded_token().encodeABI();
    await mock.givenMethodReturnAddress(rewarded_token, mock.address);

    mockCurveGaugeMapping.addGaugeMapping('compound', mock.address, false);
    mockCurveGaugeMapping.addGaugeMapping('susd', mock.address, true);
  })

  it('can deposit into compound gauge', async function() {
    const tx = await mockCurveGauge.deposit(
      "compound",
      10000000,
      0,
      0
    )
    expectEvent(tx, "LogDeposit", {
      amount: "10000000",
      getId: "0",
      setId: "0"
    });
  });

  it('can claim reward from compound gauge', async function() {
    const tx = await mockCurveGauge.claimReward(
      "compound",
      0,
      0
    )
    expectEvent(tx, "LogClaimedReward");
  });

  it('can withdraw from compound gauge', async function() {
    const tx = await mockCurveGauge.withdraw(
      "compound",
      10000000,
      0,
      0,
      0,
      0
    )
    expectEvent(tx, "LogClaimedReward");
    expectEvent(tx, "LogWithdraw", {
      amount: "10000000",
      getId: "0",
      setId: "0"
    });
  });

  it('can deposit into susd gauge', async function() {
    const tx = await mockCurveGauge.deposit(
      "susd",
      10000000,
      0,
      0
    )
    expectEvent(tx, "LogDeposit", {
      amount: "10000000",
      getId: "0",
      setId: "0"
    });
  });

  it('can claim reward from susd gauge', async function() {
    const tx = await mockCurveGauge.claimReward(
      "susd",
      0,
      0
    )
    expectEvent(tx, "LogClaimedReward");
  });

  it('can withdraw from susd gauge', async function() {
    const tx = await mockCurveGauge.withdraw(
      "susd",
      10000000,
      0,
      0,
      0,
      0
    )
    expectEvent(tx, "LogClaimedReward");
    expectEvent(tx, "LogWithdraw", {
      amount: "10000000",
      getId: "0",
      setId: "0"
    });
  });

  it('cannot deposit into unknown gauge', async function() {
    const tx = mockCurveGauge.deposit(
      "unknown",
      10000000,
      0,
      0
    )
    await expectRevert(tx, "wrong-gauge-pool-name")
  });

  it('cannot claim reward from unknown gauge', async function() {
    const tx = mockCurveGauge.claimReward(
      "unknown",
      0,
      0
    )
    await expectRevert(tx, "wrong-gauge-pool-name")
  });

  it('cannot withdraw from unknown gauge', async function() {
    const tx = mockCurveGauge.withdraw(
      "unknown",
      10000000,
      0,
      0,
      0,
      0
    )
    await expectRevert(tx, "wrong-gauge-pool-name")
  });
})
