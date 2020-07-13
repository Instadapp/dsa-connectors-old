const {
  BN,           // Big Number support
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  balance,
  ether
} = require('@openzeppelin/test-helpers');

const MockContract = artifacts.require("MockContract");
const MockSynthetixStaking = artifacts.require('MockSynthetixStaking');
// const ConnectSynthetixStaking = artifacts.require('ConnectSynthetixStaking');
const erc20ABI = require("./abi/erc20.js");
const synthetixStaking = require("./abi/synthetixStaking.json");

contract('ConnectSynthetixStaking', async accounts => {
  const [sender, receiver] =  accounts;
  let mock, mockSynthetixStaking, stakingContract, token;

  before(async function () {
    // const connectSynthetixStaking = await ConnectSynthetixStaking.deployed();
    mock = await MockContract.new();
    mockSynthetixStaking = await MockSynthetixStaking.new(mock.address);
    stakingContract = new web3.eth.Contract(synthetixStaking, mock.address);
    token = new web3.eth.Contract(erc20ABI, mock.address);

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
      mock.address,
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
      mock.address,
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
      mock.address,
      112
    )
    expectEvent(tx, "LogClaimedReward");
  });
})