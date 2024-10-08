// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IPrecheckContract} from "./IPrecheckContract.sol";
import {CrossChainCall} from "./RIP7755Structs.sol";

contract RIP7755Verifier {
    error InvalidChainId();
    error InvalidVerifyingContract();
    error CallAlreadyFulfilled();

    /// @notice Stored on verifyingContract and proved against in originationContract
    struct FulfillmentInfo {
        // Block timestamp when fulfilled
        uint96 timestamp;
        // Msg.sender of fulfillment call
        address filler;
    }

    event CallFulfilled(bytes32 indexed callHash, address indexed fulfilledBy);

    mapping(bytes32 callHash => FulfillmentInfo) public fillInfo;

    function fulfill(CrossChainCall calldata crossChainCall) external {
        if (block.chainid != crossChainCall.destinationChainId) {
            revert InvalidChainId();
        }

        if (address(this) != crossChainCall.verifyingContract) {
            revert InvalidVerifyingContract();
        }

        // Run precheck - call expected to revert if precheck condition(s) not met.
        if (crossChainCall.precheckContract != address(0)) {
            IPrecheckContract(crossChainCall.precheckContract).precheckCall(crossChainCall, msg.sender);
        }

        // TODO: Check for trusted originationContract

        bytes32 callHash = callHashCalldata(crossChainCall);

        if (fillInfo[callHash].timestamp != 0) {
            revert CallAlreadyFulfilled();
        }

        for (uint256 i; i < crossChainCall.calls.length; i++) {
            _call(crossChainCall.calls[i].to, crossChainCall.calls[i].value, crossChainCall.calls[i].data);
        }

        fillInfo[callHash] = FulfillmentInfo({timestamp: uint96(block.timestamp), filler: msg.sender});

        emit CallFulfilled({callHash: callHash, fulfilledBy: msg.sender});
    }

    function callHashCalldata(CrossChainCall calldata crossChainCall) public pure returns (bytes32) {
        return keccak256(abi.encode(crossChainCall));
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly ("memory-safe") {
                revert(add(result, 32), mload(result))
            }
        }
    }
}
