pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { DSMath } from '../common/math.sol';


// Gelato Data Types
struct Provider {
    address addr;  //  if msg.sender == provider => self-Provider
    address module;  //  can be address(0) for self-Providers
}

struct Condition {
    address inst;  // can be AddressZero for self-conditional Actions
    bytes data;  // can be bytes32(0) for self-conditional Actions
}

enum Operation { Call, Delegatecall }

enum DataFlow { None, In, Out, InAndOut }

struct Action {
    address addr;
    bytes data;
    Operation operation;
    DataFlow dataFlow;
    uint256 value;
    bool termsOkCheck;
}

struct Task {
    Condition[] conditions;  // optional
    Action[] actions;
    uint256 selfProviderGasLimit;  // optional: 0 defaults to gelatoMaxGas
    uint256 selfProviderGasPriceCeil;  // optional: 0 defaults to NO_CEIL
}

struct TaskReceipt {
    uint256 id;
    address userProxy;
    Provider provider;
    uint256 index;
    Task[] tasks;
    uint256 expiryDate;
    uint256 cycleId;  // auto-filled by GelatoCore. 0 for non-cyclic/chained tasks
    uint256 submissionsLeft;
}

struct TaskSpec {
    address[] conditions;   // Address: optional AddressZero for self-conditional actions
    Action[] actions;
    uint256 gasPriceCeil;
}

// Gelato Interface
interface IGelatoInterface {

    /**
     * @dev API to submit a single Task.
    */
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external;


    /**
     * @dev A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
     * the next one, after they have been executed, where the total number of tasks can
     * be only be an even number
    */
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external;


    /**
     * @dev A Gelato Task Chain consists of 1 or more Tasks that automatically submit
     * the next one, after they have been executed, where the total number of tasks can
     * be an odd number
    */
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external;

    /**
     * @dev Cancel multiple tasks at once
    */
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts) external;

    /**
     * @dev Whitelist new executor, TaskSpec(s) and Module(s) in one tx
    */
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    )
        external
        payable;


    /**
     * @dev De-Whitelist TaskSpec(s), Module(s) and withdraw funds from gelato in one tx
    */
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    )
        external;
}


interface MemoryInterface {
    function setUint(uint _id, uint _val) external;
}

contract Helpers {

    /**
     * @dev Return Memory Variable Address
    */
    function getMemoryAddr() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
    }

    /**
     * @dev Set Uint value in InstaMemory Contract.
    */
    function setUint(uint setId, uint val) internal {
        if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
    }

    /**
     * @dev Connector Details
    */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 420);
    }
}

contract GelatoHelpers is Helpers, DSMath {

    /**
     * @dev Return Gelato Core Address
    */
    function getGelatoCoreAddr() internal pure returns (address) {
        return 0x1d681d76ce96E4d70a88A00EBbcfc1E47808d0b8; // Gelato Core address
    }

    /**
     * @dev Return Instapp DSA Provider Module Address
    */
    function getInstadappProviderModuleAddr() internal pure returns (address) {
        return 0x0C25452d20cdFeEd2983fa9b9b9Cf4E81D6f2fE2; // ProviderModuleDSA Address
    }

}


contract GelatoResolver is GelatoHelpers {

    // ===== Gelato ENTRY APIs ======

    /**
     * @dev Enables first time users to  pre-fund eth, whitelist an executor & register the
     * ProviderModuleDSA.sol to be able to use Gelato
     * @param _executor address of single execot node or gelato'S decentralized execution market
     * @param _taskSpecs enables external providers to whitelist TaskSpecs on gelato
     * @param _modules address of ProviderModuleDSA
     * @param _ethToDeposit amount of eth to deposit on Gelato, only for self-providers
    */
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules,
        uint256 _ethToDeposit
    )
        external
        payable
    {
        try IGelatoInterface(getGelatoCoreAddr()).multiProvide{value: _ethToDeposit}(
            _executor,
            _taskSpecs,
            _modules
        ) {
        } catch Error(string memory error) {
            revert(string(abi.encodePacked("ConnectGelato.multiProvide:", error)));
        } catch {
            revert("ConnectGelato.multiProvide: unknown error");
        }
    }

    /**
     * @dev Submits a single, one-time task to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _task Task specifying the condition and the action connectors
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
    */
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external
    {
        try IGelatoInterface(getGelatoCoreAddr()).submitTask(_provider, _task, _expiryDate) {
        } catch Error(string memory error) {
            revert(string(abi.encodePacked("ConnectGelato.submitTask:", error)));
        } catch {
            revert("ConnectGelato.submitTask: unknown error");
        }
    }

    /**
     * @dev Submits single or mulitple Task Sequences to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _tasks A sequence of Tasks, can be a single or multiples
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     * @param _cycles How often the Task List should be executed, e.g. 5 times
    */
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external
    {
        try IGelatoInterface(getGelatoCoreAddr()).submitTaskCycle(
            _provider,
            _tasks,
            _expiryDate,
            _cycles
        ) {
        } catch Error(string memory error) {
            revert(string(abi.encodePacked("ConnectGelato.submitTaskCycle:", error)));
        } catch {
            revert("ConnectGelato.submitTaskCycle: unknown error");
        }
    }

    /**
     * @dev Submits single or mulitple Task Chains to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _tasks A sequence of Tasks, can be a single or multiples
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     * @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
     * that should have occured once the cycle is complete
    */
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external
    {
        try IGelatoInterface(getGelatoCoreAddr()).submitTaskChain(
            _provider,
            _tasks,
            _expiryDate,
            _sumOfRequestedTaskSubmits
        ) {
        } catch Error(string memory error) {
            revert(string(abi.encodePacked("ConnectGelato.submitTaskChain:", error)));
        } catch {
            revert("ConnectGelato.submitTaskChain: unknown error");
        }
    }

    // ===== Gelato EXIT APIs ======

    /**
     * @dev Withdraws funds from Gelato, de-whitelists TaskSpecs and Provider Modules
     * in one tx
     * @param _withdrawAmount Amount of ETH to withdraw from Gelato
     * @param _taskSpecs List of Task Specs to de-whitelist, default empty []
     * @param _modules List of Provider Modules to de-whitelist, default empty []
    */
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules,
        uint256 _setId
    )
        external
    {
        uint256 balanceBefore = address(this).balance;
        try IGelatoInterface(getGelatoCoreAddr()).multiUnprovide(
            _withdrawAmount,
            _taskSpecs,
            _modules
        ) {
            setUint(_setId, sub(address(this).balance, balanceBefore));
        } catch Error(string memory error) {
            revert(string(abi.encodePacked("ConnectGelato.multiUnprovide:", error)));
        } catch {
            revert("ConnectGelato.multiUnprovide: unknown error");
        }
    }

    /**
     * @dev Cancels outstanding Tasks
     * @param _taskReceipts List of Task Receipts to cancel
    */
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts)
        external
    {
        try IGelatoInterface(getGelatoCoreAddr()).multiCancelTasks(_taskReceipts) {
        } catch Error(string memory error) {
            revert(string(abi.encodePacked("ConnectGelato.multiCancelTasks:", error)));
        } catch {
            revert("ConnectGelato.multiCancelTasks: unknown error");
        }
    }
}


contract ConnectGelato is GelatoResolver {
    string public name = "Gelato-v1.0";
}