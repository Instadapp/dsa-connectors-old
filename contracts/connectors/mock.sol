pragma solidity ^0.6.0;

import { DSMath } from "../common/math.sol";
import { Stores } from "../common/stores.sol";

contract MockProtocol is Stores, DSMath {

    event LogMock(uint mockOne, uint mockTwo, uint getId, uint setId);

    function mockFunction(uint mockNumber, uint getId, uint setId) external payable {
        uint mockBalance = mockNumber == uint(-1) ? address(this).balance : mockNumber;

        emit LogMock(mockNumber, mockBalance, getId, setId);
        bytes32 eventCode = keccak256("LogMock(uint256,uint256,uint256,uint256)");
        bytes memory eventData = abi.encode(mockNumber, mockBalance, getId, setId);
        emitEvent(eventCode, eventData);
    }

}

contract ConnectMock is MockProtocol {
    string public name = "Mock-v1";
}