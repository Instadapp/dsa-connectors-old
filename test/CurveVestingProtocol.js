const {
  BN,           // Big Number support
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  balance,
  ether
} = require('@openzeppelin/test-helpers');

const MockContract = artifacts.require("MockContract");
const MockConnectCurveVestingProtocol = artifacts.require('MockConnectCurveVestingProtocol');
const erc20ABI = require("./abi/erc20.js");
const curveVestingABI = require("./abi/curveVesting.json");

contract("ConnectCurveVestingProtocol", async accounts => {
  const [sender, receiver] =  accounts;
  let mock, token, curveVesting;

  before(async function(){
    mock = await MockContract.new();
    mockConnectCurveVestingProtocol = await MockConnectCurveVestingProtocol.new(mock.address, mock.address)
    token = new web3.eth.Contract(erc20ABI, mock.address);
    curveVesting = new web3.eth.Contract(curveVestingABI, mock.address);

    // mocking balanceOf
    let balanceOf = await token.methods.balanceOf(mockConnectCurveVestingProtocol.address).encodeABI();
    await mock.givenMethodReturnUint(balanceOf, 10000000);
  })

  it('can claim CRV', async function() {
    const tx = await mockConnectCurveVestingProtocol.claim(
      sender,
      0,
      0
    )
    expectEvent(tx, "LogClaim");
  });
})
