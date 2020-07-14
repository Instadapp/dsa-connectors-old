const {
  BN,           // Big Number support
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  balance,
  ether
} = require('@openzeppelin/test-helpers');

const MockContract = artifacts.require("MockContract");
const MockSynthetixStaking = artifacts.require('MockSynthetixStaking');
const MockInstaMapping = artifacts.require('MockInstaMapping');
const erc20ABI = require("./abi/erc20.js");
const synthetixStaking = require("./abi/synthetixStaking.json");

contract('ConnectSynthetixStaking', async accounts => {
  const [sender, receiver] =  accounts;
  let mock, mockSynthetixStaking, stakingContract, token;
  let instaMapping;

  before(async function () {
    mock = await MockContract.new();
    mockInstaMapping = await MockInstaMapping.new();
    mockSynthetixStaking = await MockSynthetixStaking.new(mock.address, mockInstaMapping.address);
    stakingContract = new web3.eth.Contract(synthetixStaking, mock.address);
    token = new web3.eth.Contract(erc20ABI, mock.address);
    mockInstaMapping.addStakingMapping('snx', mock.address, mock.address);

    // mocking balanceOf
    let balanceOf = await token.methods.balanceOf(mockSynthetixStaking.address).encodeABI();
    await mock.givenMethodReturnUint(balanceOf, 10000000);

    // mocking approve
    let approve = await token.methods.approve(mockSynthetixStaking.address, 10000000).encodeABI();
    await mock.givenMethodReturnBool(approve, "true");

  })

  it('can deposit', async function() {
    // mocking stake
    let stake = await stakingContract.methods.stake(10000000).encodeABI();
    await mock.givenMethodReturnBool(stake, "true");

    const tx = await mockSynthetixStaking.deposit(
      "snx",
      10000000,
      0,
      0
    )
    expectEvent(tx, "LogDeposit");
  });

  it('can withdraw', async function() {
    // mocking withdraw
    let withdraw = await stakingContract.methods.withdraw(10000000).encodeABI();
    await mock.givenMethodReturnBool(withdraw, "true");
    // mocking getReward
    let reward = await stakingContract.methods.getReward().encodeABI();
    await mock.givenMethodReturnBool(reward, "true");

    const tx = await mockSynthetixStaking.withdraw(
      "snx",
      10000000,
      0,
      111,
      112
    )
    expectEvent(tx, "LogWithdraw");
    expectEvent(tx, "LogClaimedReward");
  });

  it('can claim reward', async function() {
    // mocking getReward
    let reward = await stakingContract.methods.getReward().encodeABI();
    await mock.givenMethodReturnBool(reward, "true");
    const tx = await mockSynthetixStaking.claimReward(
      "snx",
      112
    )
    expectEvent(tx, "LogClaimedReward");
  });

  it('cannot deposit if pool removed', async function() {
    mockInstaMapping.removeStakingMapping('snx', mock.address);
    // mocking stake
    let stake = await stakingContract.methods.stake(10000000).encodeABI();
    await mock.givenMethodReturnBool(stake, "true");

    const tx = mockSynthetixStaking.deposit(
      "snx",
      10000000,
      0,
      0
    )
    expectRevert(tx, "Wrong Staking Name");
  });

})
