
# DeFi Smart Account Connectors

## Requirements

- Should not have delegate call in it.

- Use `uint(-1)` for maximum amount everywhere.

```javascript
contract Sample {
  /**
   * @dev Depositing ETH
   */
  function deposit(address token, uint amt, uint getId, uint setId) external payable{
    uint _amt = getUint(getId, amt);
    _amt = _amt == uint(-1) ? address(this).balance : _amt;
    // code code
    // event stuff
  }
}
```

- Use of ETH address as:

```javascript
/**
 * @dev Return ethereum address
 */
function getAddressETH() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
}
```

- Use of getId & setId.
  
```javascript
interface MemoryInterface {
    function getUint(uint _id) external returns (uint _num);
    function setUint(uint _id, uint _val) external;
}

contract Sample {
  /**
   * @dev Return Memory Variable Address
   */
  function getMemoryAddr() internal pure returns (address) {
      return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
  }
  
  /**
   * @dev Get Uint value from InstaMemory Contract.
  */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
      returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
  }
  
  /**
   * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) internal {
      if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
  }
  
  /**
   * @dev Sample function
  */
  function deposit(address token, uint amt, uint getId, uint setId) external payable{
      uint _amt = getUint(getId, amt); // If getId = 0 then _amt = amt.
      // Core code
      setUint(setId, _amt); // If setId = 0 then nothing happens.
      // Event emitting
  }
}
```

- Use of event emitter.
```javascript
interface EventInterface {
    function emitEvent(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external;
}

contract Sample {
  /**
   * @dev Connector Details. DSA team will set the ID at the time of deployment.
  */
  function connectorID() public pure returns(uint _type, uint _id) {
      (_type, _id) = (1, 0);
  }
  /**
   * @dev Return InstaEvent Address.
   */
  function getEventAddr() internal pure returns (address) {
      return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97; // InstaEvent Address
  }

  // Smaple Event
  event LogDeposit(address indexed token, address cToken, uint256 tokenAmt, uint256 getId, uint256 setId);

  /**
   * @dev Sample function
  */
  function deposit(address token, uint amt, uint getId, uint setId) external payable{
    // Function Code
    emit LogDeposit(token, cToken, _amt, getId, setId);
    bytes32 _eventCode = keccak256("LogDeposit(address,address,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(token, cToken, _amt, getId, setId);
    (uint _type, uint _id) = connectorID();
    EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
  }
}
```

## Installation

1. Install Truffle and Ganache CLI globally.

```javascript
npm  install -g  truffle@beta
npm  install -g  ganache-cli
npm instal
```

2. Create a `.env` file in the root directory and use the below format for .`env` file.

```javascript
infura_key = [Infura key] //For deploying
mnemonic_key = [Mnemonic Key] // Also called as seed key
etherscan_key = [Etherscan API dev Key]
```  

## Commands:

```
Compile contracts: truffle compile
Migrate contracts: truffle migrate
Test contracts: truffle test
Run eslint: npm run lint
Run solium: npm run solium
Run solidity-coverage: npm run coverage
Run lint, solium, and truffle test: npm run test
```