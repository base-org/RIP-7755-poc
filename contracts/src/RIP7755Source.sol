// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

import {CrossChainCall, Call} from "./RIP7755Structs.sol";
import {RIP7755Verifier} from "./RIP7755Verifier.sol";

// TODO: Only requester should be able to cancel a request ?

/// @title RIP7755Source
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice A source contract for initiating RIP7755 Cross Chain Requests as well as reward fulfillment to Fillers that
/// submit the cross chain calls to destination chains.
abstract contract RIP7755Source {
    using Address for address payable;

    /// @notice A cross chain call request formatted following the RIP-7755 spec
    struct CrossChainRequest {
        /// @dev Array of calls to make on the destination chain
        Call[] calls;
        /// @dev The chainId of the destination chain
        uint256 destinationChainId;
        /// @dev The L2 contract on destination chain that's storage will be used to verify whether or not this call was made
        address verifyingContract;
        /// @dev The L1 address of the contract that should have L2 block info stored
        address l2Oracle;
        /// @dev The storage key at which we expect to find the L2 block info on the l2Oracle
        bytes32 l2OracleStorageKey;
        /// @dev The address of the ERC20 reward asset to be paid to whoever proves they filled this call
        /// @dev Native asset specified as in ERC-7528 format
        address rewardAsset;
        /// @dev The reward amount to pay
        uint256 rewardAmount;
        /// @dev The minimum age of the L1 block used for the proof
        uint256 finalityDelaySeconds;
        /// @dev The nonce of this call, to differentiate from other calls with the same values
        uint256 nonce;
        /// @dev An optional pre-check contract address on the destination chain
        /// @dev Zero address represents no pre-check contract desired
        /// @dev Can be used for arbitrary validation of fill conditions
        address precheckContract;
        /// @dev Arbitrary encoded precheck data
        bytes precheckData;
    }

    /// @notice An enum representing the status of an RIP-7755 cross chain call
    enum CrossChainCallStatus {
        None,
        Requested,
        CancelRequested,
        Canceled,
        Completed
    }

    /// @notice A mapping from the keccak256 hash of a `CrossChainRequest` to its current `CrossChainCallStatus`
    mapping(bytes32 requestHash => CrossChainCallStatus status) public requestStatus;

    /// @notice A mapping from the keccak256 hash of a `CrossChainRequest` to the timestamp it was requested to be cancelled at
    mapping(bytes32 requestHash => uint256 timestampSeconds) public cancelRequestedAt;

    /// @notice The duration, in excess of CrossChainRequest.finalityDelaySeconds, which must pass between requesting
    /// and finalizing a request cancellation
    uint256 public cancelDelaySeconds = 1 days;

    /// @notice The address representing the native currency of the blockchain this contract is deployed on
    address internal constant _NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice An incrementing nonce value to ensure no two `CrossChainRequest` can be exactly the same
    uint256 internal _nonce;

    /// @notice Event emitted when a user requests a cross chain call to be made by a filler
    /// @param callHash The keccak256 hash of a `CrossChainRequest`
    /// @param call The requested call converted to a `CrossChainCall` structure
    event CrossChainCallRequested(bytes32 indexed callHash, CrossChainCall call);

    /// @notice Event emitted when a user requests a pending cross chain call to be cancelled
    /// @param callHash The keccak256 hash of a `CrossChainRequest`
    event CrossChainCallCancelRequested(bytes32 indexed callHash);

    /// @notice Event emitted when a pending cross chain call cancellation is finalized
    /// @param callHash The keccak256 hash of a `CrossChainRequest`
    event CrossChainCallCancelFinalized(bytes32 indexed callHash);

    /// @notice This error is thrown when a cross chain request specifies the native currency as the reward type but
    /// does not send the correct `msg.value`
    /// @param expected The expected `msg.value` that should have been sent with the transaction
    /// @param received The actual `msg.value` that was sent with the transaction
    error InvalidValue(uint256 expected, uint256 received);

    /// @notice This error is thrown if a user attempts to cancel a request that is not in the `CrossChainCallStatus.Requested` state
    /// @param status The `CrossChainCallStatus` status that the request has
    error InvalidStatusForRequestCancel(CrossChainCallStatus status);

    /// @notice This error is thrown if a user attempts to finalize a cancel request for a request that is not in the `CrossChainCallStatus.CancelRequested` state
    /// @param status The `CrossChainCallStatus` status that the request has
    error InvalidStatusForFinalizeCancel(CrossChainCallStatus status);

    /// @notice Submits an RIP-7755 request for a cross chain call
    ///
    /// @param request A cross chain request structured as a `CrossChainRequest`
    function requestCrossChainCall(CrossChainRequest calldata request) external payable {
        CrossChainCall memory crossChainCall = _convertToCrossChainCallAndAssignNonce(request);

        bytes32 callHash = hashCalldataCall(request);
        requestStatus[callHash] = CrossChainCallStatus.Requested;

        if (request.rewardAsset == _NATIVE_ASSET) {
            if (request.rewardAmount != msg.value) {
                revert InvalidValue(request.rewardAmount, msg.value);
            }
        } else {
            _pullERC20(msg.sender, request.rewardAsset, request.rewardAmount);
        }

        emit CrossChainCallRequested(callHash, crossChainCall);
    }

    /// @notice To be called by a Filler that successfully submitted a cross chain request to the destination chain and
    /// can prove it with a valid nested storage proof
    ///
    /// @param request A cross chain request structured as a `CrossChainRequest`
    /// @param fillInfo The fill info that should be in storage in `RIP7755Verifier` on destination chain
    /// @param storageProofData A storage proof that cryptographically verifies that `fillInfo` does, indeed, exist in
    /// storage on the destination chain
    /// @param payTo The address the Filler wants to receive the reward
    function claimReward(
        CrossChainRequest calldata request,
        RIP7755Verifier.FulfillmentInfo calldata fillInfo,
        bytes calldata storageProofData,
        address payTo
    ) external payable {
        bytes32 callHash = hashCalldataCall(request);
        bytes32 storageKey = keccak256(
            abi.encodePacked(
                callHash,
                uint256(0) // Must be at slot 0
            )
        );

        _validate(storageKey, fillInfo, request, storageProofData);
        requestStatus[callHash] = CrossChainCallStatus.Completed;

        if (request.rewardAsset == _NATIVE_ASSET) {
            payable(payTo).sendValue(request.rewardAmount);
        } else {
            _sendERC20(payTo, request.rewardAsset, request.rewardAmount);
        }
    }

    /// @notice Requests that a pending cross chain call be cancelled
    ///
    /// @dev Can only be called if the request is in the `CrossChainCallStatus.Requested` state
    ///
    /// @param callHash The keccak256 hash of a `CrossChainRequest`
    function requestCancel(bytes32 callHash) external {
        CrossChainCallStatus status = requestStatus[callHash];

        if (status != CrossChainCallStatus.Requested) {
            revert InvalidStatusForRequestCancel(status);
        }

        requestStatus[callHash] = CrossChainCallStatus.CancelRequested;

        emit CrossChainCallCancelRequested(callHash);
    }

    /// @notice Finalizes a pending cross chain call cancellation
    ///
    /// @dev Can only be called if the request is in the `CrossChainCallStatus.CancelRequested` state
    ///
    /// @param callHash The keccak256 hash of a `CrossChainRequest`
    function finalizeCancel(bytes32 callHash) external {
        CrossChainCallStatus status = requestStatus[callHash];

        if (status != CrossChainCallStatus.CancelRequested) {
            revert InvalidStatusForFinalizeCancel(status);
        }

        requestStatus[callHash] = CrossChainCallStatus.Canceled;

        emit CrossChainCallCancelFinalized(callHash);
    }

    /// @notice Hashes a `CrossChainRequest` request to use as a request identifier
    ///
    /// @param request A cross chain request structured as a `CrossChainRequest`
    ///
    /// @return _ A keccak256 hash of the `CrossChainRequest`
    function hashCalldataCall(CrossChainRequest calldata request) public pure returns (bytes32) {
        return keccak256(abi.encode(request));
    }

    /// @notice Validates storage proofs and verifies fill
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fillInfo not found at verifyingContractStorageKey on crossChainCall.verifyingContract
    /// @custom:reverts If fillInfo.timestamp is less than
    /// crossChainCall.finalityDelaySeconds from current destination chain block timestamp.
    ///
    /// @dev Implementation will vary by L2
    function _validate(
        bytes32 verifyingContractStorageKey,
        RIP7755Verifier.FulfillmentInfo calldata fillInfo,
        CrossChainRequest calldata crossChainCall,
        bytes calldata storageProofData
    ) internal view virtual;

    /// @notice Pulls `amount` of `asset` from `owner` to address(this)
    ///
    /// @dev Left abstract to minimize imports and maximize simplicity for this example
    function _pullERC20(address owner, address asset, uint256 amount) internal virtual;

    /// @notice Sends `amount` of `asset` to `to`
    ///
    /// @dev Left abstract to minimize imports and maximize simplicity for this example
    function _sendERC20(address to, address asset, uint256 amount) internal virtual;

    function _convertToCrossChainCallAndAssignNonce(CrossChainRequest calldata request)
        private
        returns (CrossChainCall memory)
    {
        CrossChainCall memory crossChainCall = _convertToCrossChainCall(request);
        crossChainCall.nonce = ++_nonce;
        return crossChainCall;
    }

    function _convertToCrossChainCall(CrossChainRequest calldata request)
        internal
        view
        returns (CrossChainCall memory)
    {
        return CrossChainCall({
            calls: request.calls,
            originationContract: address(this),
            originChainId: block.chainid,
            destinationChainId: request.destinationChainId,
            nonce: request.nonce,
            verifyingContract: request.verifyingContract,
            precheckContract: request.precheckContract,
            precheckData: request.precheckData
        });
    }
}
