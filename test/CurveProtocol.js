const CurveProtocol = artifacts.require('CurveProtocol')
const daiABI = require('./abi/dai');
const erc20 = require('./abi/erc20')
const swap_abi = require('./abi/swap')
const { BN, ether, balance } = require('openzeppelin-test-helpers');
const { asyncForEach } = require('./utils');

// userAddress must be unlocked using --unlock ADDRESS
const userAddress = '0x9eb7f2591ed42dee9315b6e2aaf21ba85ea69f8c';
const daiAddress = '0x6b175474e89094c44da98b954eedeac495271d0f';
const daiContract = new web3.eth.Contract(daiABI, daiAddress);

const usdcAddress = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
const usdcContract = new web3.eth.Contract(erc20, usdcAddress);

const swap = '0xA5407eAE9Ba41422680e2e00537571bcC53efBfD'
const swapContract = new web3.eth.Contract(swap_abi, swap)

const swapToken = '0xC25a3A3b969415c80451098fa907EC722572917F'
const tokenContract = new web3.eth.Contract(erc20, swapToken)

//console.log(CurveProtocol);


contract('Curve Protocol', async accounts => {


	it('should send ether to the DAI address', async () => {
		let account = accounts[0]
		let contract = await CurveProtocol.deployed()
		// Send 0.1 eth to userAddress to have gas to send an ERC20 tx.
		await web3.eth.sendTransaction({
		  from: accounts[0],
		  to: userAddress,
		  value: ether('0.1')
		});
		const ethBalance = await balance.current(userAddress);
		//expect(new BN(ethBalance)).to.be.bignumber.least(new BN(ether('0.1')));
	});

	it('should mint DAI for our first 5 generated accounts', async () => {
		let account = accounts[0]
		let contract = await CurveProtocol.deployed()
		// Get 100 DAI for first 5 accounts
		// daiAddress is passed to ganache-cli with flag `--unlock`
		// so we can use the `transfer` method
		await daiContract.methods
			.transfer(contract.address, ether('10').toString())
			.send({ from: userAddress, gasLimit: 800000 });
		const daiBalance = await daiContract.methods.balanceOf(contract.address).call();
	});

	it('should approve DAI to CurveProtocol', async() => {
		let account = accounts[0]
		let contract = await CurveProtocol.deployed()

		await daiContract.methods
	        .approve(contract.address, "1000000000000000000000000000")
	        .send({ from: account, gasLimit: 800000 });
	});

	it('should exchange', async () => {
		let account = accounts[0]
		let contract = await CurveProtocol.deployed()

		// Get 100 DAI for first 5 accounts
		let receipt = await contract.exchange(0, 1, "1000000000000000000", 1, { from: account });
		console.log(receipt.logs[0].args.sellAmount.toString(), receipt.logs[0].args.buyAmount.toString())		

	});

	it('should add liquidity', async () => {
		let account = accounts[0]
		let contract = await CurveProtocol.deployed()
		let receipt = await contract.add_liquidity(["1000000000000000000", 0, 0, 0], 1, { from: account })
		console.log(receipt.logs[0].args.amounts.map(amount=>amount.toString()), receipt.logs[0].args.mintAmount.toString())
	})

	it('should remove liquidity imbalance', async () => {
		let account = accounts[0]
		let contract = await CurveProtocol.deployed()
		let receipt = await contract.remove_liquidity_imbalance(["100000000000", 0, 0, 0], { from: account })
		console.log(receipt.logs[0].args.amounts.map(amount=>amount.toString()), receipt.logs[0].args.burnAmount.toString())
	})

	it('should remove liquidity in one coin', async() => {
		let account = accounts[0]
		let contract = await CurveProtocol.deployed()
		let receipt = await contract.remove_liquidity_one_coin("100000000000", 0, 1, { from: account })
		console.log(receipt.logs[0].args.receiveCoin, receipt.logs[0].args.amount.toString())
	})
});