pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface CHIInterface {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256);
    function balanceOf(address) external view returns (uint);
}


contract ChiHelpers is DSMath, Stores  {
    /**
     * @dev CHI token Address
     */
    function getCHIAddress() internal pure returns (address) {
        return 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;
    }
}


contract ChiResolver is ChiHelpers {
    event LogMint(uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBurn(uint256 tokenAmt, uint256 getId, uint256 setId);

    /**
     * @dev Mint CHI token.
     * @param amt token amount to mint.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
     */
    function mint(uint amt, uint getId, uint setId) public payable {
        uint _amt = getUint(getId, amt);
        _amt = _amt == uint(-1) ? 140 : _amt;
        require(_amt <= 140, "Max minting is 140 chi");

        CHIInterface(getCHIAddress()).mint(_amt);

        setUint(setId, _amt);

        emit LogMint(_amt, getId, setId);
        bytes32 _eventCode = keccak256("LogMint(uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(_amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }

    /**
     * @dev burn CHI token.
     * @param amt token amount to burn.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
     */
    function burn(uint amt, uint getId, uint setId) public payable {
        uint _amt = getUint(getId, amt);
        CHIInterface chiToken = CHIInterface(getCHIAddress());
        _amt = _amt == uint(-1) ? chiToken.balanceOf(address(this)) : _amt;

        chiToken.free(_amt);

        setUint(setId, _amt);

        emit LogBurn(_amt, getId, setId);
        bytes32 _eventCode = keccak256("LogBurn(uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(_amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }
}


contract ConnectCHI is ChiResolver {
    string public name = "CHI-v1";
}