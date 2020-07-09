const {
  BN,           // Big Number support
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  balance,
  ether
} = require('@openzeppelin/test-helpers');

const MockContract = artifacts.require("MockContract");

const ConnectSynthetixStaking = artifacts.require('ConnectSynthetixStaking');
const erc20ABI = require("./abi/erc20.js");

contract('ConnectSynthetixStaking', async accounts => {
  const [sender, receiver] =  accounts;
  const mock = await MockContract.new();
  const crvRenWSBTCContract = new web3.eth.Contract(erc20ABI, mock.address);

  before(async function () {
    let methodId = await crvRenWSBTCContract.methods.balanceOf(sender).encodeABI();
    await mock.givenMethodReturnUint(methodId, 10000000);

    let crvRenWSBTC = await crvRenWSBTCContract.methods.balanceOf(sender).call();

    expect(crvRenWSBTC).to.equal("10000000");
  })

  it('can mock token', async function() {
    // expect(wbtcAfter - wbtcBefore).to.be.at.least(10000000);
  });
})
