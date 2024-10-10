// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

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
    using Address for address;

    /// @notice Stored on verifyingContract and proved against in originationContract
    struct FulfillmentInfo {
        /// @dev Block timestamp when fulfilled
        uint96 timestamp;
        /// @dev Msg.sender of fulfillment call
        address filler;
    }

    /// @notice A mapping from the keccak256 hash of a `CrossChainCall` to its `FulfillmentInfo`. This can only be set once per call
    mapping(bytes32 callHash => FulfillmentInfo) private _fillInfo;

    /// @notice Event emitted when a cross chain call is fulfilled
    /// @param callHash The keccak256 hash of a `CrossChainCall`
    /// @param fulfilledBy The address of the Filler that fulfilled the cross chain call
    event CallFulfilled(bytes32 indexed callHash, address indexed fulfilledBy);

    /// @notice This error is thrown when a Filler submits a cross chain call with a `destinationChainId` different than the blockchain chain ID that this is deployed to
    error InvalidChainId();

    /// @notice This error is thrown when a Filler submits a cross chain call with a `verifyingContract` different than this contract's address
    error InvalidVerifyingContract();

    /// @notice This error is thrown when a Filler attempts to submit a cross chain call that has already been fulfilled
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

        _fillInfo[callHash] = FulfillmentInfo({timestamp: uint96(block.timestamp), filler: msg.sender});

        emit CallFulfilled({callHash: callHash, fulfilledBy: msg.sender});

        for (uint256 i; i < request.calls.length; i++) {
            request.calls[i].to.functionCallWithValue(request.calls[i].data, request.calls[i].value);
        }
    }

    /// @notice Hashes a cross chain call request.
    ///
    /// @param request A cross chain call request formatted following the RIP-7755 spec. See {RIP7755Structs-CrossChainCall}.
    ///
    /// @return _ A keccak256 hash of the cross chain call request.
    function callHashCalldata(CrossChainCall calldata request) public pure returns (bytes32) {
        return keccak256(abi.encode(request));
    }
}
