const {
  BN,           // Big Number support
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  balance,
  ether
} = require('@openzeppelin/test-helpers');

const MockContract = artifacts.require("MockContract.sol")

const ConnectSynthetixStaking = artifacts.require('ConnectSynthetixStaking');
const erc20ABI = require("./abi/erc20.js");
contract('ConnectSynthetixStaking', async accounts => {
  const [sender, receiver] =  accounts;
  before(async function () {
    const mock = await MockContract.new()
    const crvRenWSBTCContract = new web3.eth.Contract(erc20ABI, mock.address);
    let methodId = await crvRenWSBTCContract.methods.banlanceOf.getData(0,0);
    console.log("methodId: ", methodId);
    await mock.givenMethodReturn(methodId, abi.rawEncode(['uint'], [10000000]).toString());

    let crvRenWSBTC = await crvRenWSBTCContract.methods.balanceOf(sender).call();
    console.log("Sender crvRenWSBTC Before: ", crvRenWSBTC.toString());

    expect(crvRenWSBTC).to.be(10000000);
    // expect(wbtcAfter - wbtcBefore).to.be.at.least(10000000);
  })
})
