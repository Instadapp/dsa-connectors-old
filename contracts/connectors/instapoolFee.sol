pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IndexInterface {
    function master() external view returns (address);
}

contract Helpers {
    address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    uint64 internal fee;

    modifier isChief {
        require(IndexInterface(instaIndex).master() == msg.sender, "not-Master");
        _;
    }

    function changeFee(uint _fee) external isChief {
        require(fee <= 2 * 10 ** 15, "Fee is more than 0.2%");
        fee = uint64(_fee);
    }
}

contract InstaPoolFee is Helpers {
    constructor () public {
        fee = 9 * 10 ** 14;
    }

    function getFee() public view returns (uint256) {
        return uint256(fee);
    }
}
