const {
    BN,           // Big Number support
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
    balance,
    ether
  } = require('@openzeppelin/test-helpers');
  
  const MockContract = artifacts.require("MockContract");
  const MockConnectOne = artifacts.require('MockConnectOne');
  const erc20ABI = require("./abi/erc20.js");
  const oneProto = require("./abi/1proto.json");
  
  contract('ConnectOneProto', async accounts => {
    const [sender, receiver] =  accounts;
    let mock, mockConnectOneProto, oneProtoContract, sellToken, buyToken, sellAmt;

    before(async function () {
      mock = await MockContract.new();
      mockConnectOneProto = await MockConnectOne.new(mock.address);
      oneProtoContract = new web3.eth.Contract(oneProto, mock.address);
      sellToken = new web3.eth.Contract(erc20ABI, mock.address);
      buyToken = new web3.eth.Contract(erc20ABI, mock.address);
      sellAmt = String(20 * 10 ** 18);

        
      // mocking balanceOf
      let balanceOf = await sellToken.methods.balanceOf(mockConnectOneProto.address).encodeABI();
      await mock.givenMethodReturnUint(balanceOf, sellAmt);

      // mocking balanceOf
      let decimals = await sellToken.methods.decimals().encodeABI();
      await mock.givenMethodReturnUint(decimals, 18);

      // mocking balanceOf
      let decimalsBuy = await buyToken.methods.decimals().encodeABI();
      await mock.givenMethodReturnUint(decimalsBuy, 18);
  
      // mocking approve
      let approve = await sellToken.methods.approve(mockConnectOneProto.address, sellAmt).encodeABI();
      await mock.givenMethodReturnBool(approve, "true");
  
    })
  
    it('can sell DAI <> USDC', async function() {
        let getExpectedReturn = await oneProtoContract.methods.getExpectedReturn(
            mock.address,
            mock.address,
            sellAmt,
            5,
            0
        ).encodeABI();
        await mock.givenMethodReturn(getExpectedReturn, web3.eth.abi.encodeParameters(["uint256", "uint256[]"], [20000, [0,0,0,1]]));
      // mocking stake
      let swapWithReferral = await oneProtoContract.methods.swapWithReferral(
            mock.address,
            mock.address,
            sellAmt,
            1,
            [0,1,0],
            0,
            mock.address,
            0
        ).encodeABI();
        await mock.givenMethodReturnBool(swapWithReferral, "true");
  
        const tx = await mockConnectOneProto.sell(
            mock.address,
            mock.address,
            sellAmt,
            String(99 * 10 ** 16),
            0,
            0
        )
        let obj = {
            buyAmt: 100000
        };
        expectEvent(tx, "LogSell", obj);
    });
  
    // it('can withdraw', async function() {
    //   // mocking withdraw
    //   let withdraw = await stakingContract.methods.withdraw(10000000).encodeABI();
    //   await mock.givenMethodReturnBool(withdraw, "true");
    //   // mocking getReward
    //   let reward = await stakingContract.methods.getReward().encodeABI();
    //   await mock.givenMethodReturnBool(reward, "true");
  
    //   const tx = await mockSynthetixStaking.withdraw(
    //     "snx",
    //     10000000,
    //     0,
    //     111,
    //     112
    //   )
    //   expectEvent(tx, "LogWithdraw");
    //   expectEvent(tx, "LogClaimedReward");
    // });
  
    // it('can claim reward', async function() {
    //   // mocking getReward
    //   let reward = await stakingContract.methods.getReward().encodeABI();
    //   await mock.givenMethodReturnBool(reward, "true");
    //   const tx = await mockSynthetixStaking.claimReward(
    //     "snx",
    //     112
    //   )
    //   expectEvent(tx, "LogClaimedReward");
    // });
  
    // it('cannot deposit if pool removed', async function() {
    //   mockInstaMapping.removeStakingMapping('snx', mock.address);
    //   // mocking stake
    //   let stake = await stakingContract.methods.stake(10000000).encodeABI();
    //   await mock.givenMethodReturnBool(stake, "true");
  
    //   const tx = mockSynthetixStaking.deposit(
    //     "snx",
    //     10000000,
    //     0,
    //     0
    //   )
    //   expectRevert(tx, "Wrong Staking Name");
    // });
  
  })
  