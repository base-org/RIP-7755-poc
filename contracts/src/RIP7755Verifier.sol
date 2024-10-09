// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IPrecheckContract} from "./IPrecheckContract.sol";
import {CrossChainCall} from "./RIP7755Structs.sol";

/// @title RIP7755Verifier
///
/// @author Coinbase (https://github.com/base-org/7755-poc)
///
/// @notice A Verification contract within RIP-7755.
///
/// This contract's sole purpose is to route requested transactions on destination chains and store record of their fulfillment.
contract RIP7755Verifier {
    /// @notice Stored on verifyingContract and proved against in originationContract
    struct FulfillmentInfo {
        /// @dev Block timestamp when fulfilled
        uint96 timestamp;
        /// @dev Msg.sender of fulfillment call
        address filler;
    }

    mapping(bytes32 callHash => FulfillmentInfo) private _fillInfo;

    event CallFulfilled(bytes32 indexed callHash, address indexed fulfilledBy);

    error InvalidChainId();
    error InvalidVerifyingContract();
    error CallAlreadyFulfilled();

    /// @notice Returns the stored fulfillment info for a passed in call hash
    ///
    /// @param callHash A keccak256 hash of a CrossChainCall request
    ///
    /// @return _ Fulfillment info stored for the call hash
    function getFillInfo(bytes32 callHash) external view returns (FulfillmentInfo memory) {
        return _fillInfo[callHash];
    }

    /// @notice A fulfillment entrypoint for RIP7755 cross chain calls.
    ///
    /// @param request A cross chain call request formatted following the RIP-7755 spec. See {RIP7755Structs-CrossChainCall}.
    function fulfill(CrossChainCall calldata request) external payable {
        if (block.chainid != request.destinationChainId) {
            revert InvalidChainId();
        }

        if (address(this) != request.verifyingContract) {
            revert InvalidVerifyingContract();
        }

        // Run precheck - call expected to revert if precheck condition(s) not met.
        if (request.precheckContract != address(0)) {
            IPrecheckContract(request.precheckContract).precheckCall(request, msg.sender);
        }

        // TODO: Check for trusted originationContract

        bytes32 callHash = callHashCalldata(request);

        if (_fillInfo[callHash].timestamp != 0) {
            revert CallAlreadyFulfilled();
        }

        for (uint256 i; i < request.calls.length; i++) {
            _call(request.calls[i].to, request.calls[i].value, request.calls[i].data);
        }

        _fillInfo[callHash] = FulfillmentInfo({timestamp: uint96(block.timestamp), filler: msg.sender});

        emit CallFulfilled({callHash: callHash, fulfilledBy: msg.sender});
    }

    /// @notice Hashes a cross chain call request.
    ///
    /// @param request A cross chain call request formatted following the RIP-7755 spec. See {RIP7755Structs-CrossChainCall}.
    ///
    /// @return _ A keccak256 hash of the cross chain call request.
    function callHashCalldata(CrossChainCall calldata request) public pure returns (bytes32) {
        return keccak256(abi.encode(request));
    }

    function _call(address target, uint256 value, bytes memory data) private {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly ("memory-safe") {
                revert(add(result, 32), mload(result))
            }
        }
    }
}
