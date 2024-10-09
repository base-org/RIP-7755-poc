// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {CrossChainCall, Call} from "./RIP7755Structs.sol";
import {RIP7755Verifier} from "./RIP7755Verifier.sol";

abstract contract RIP7755Source {
    struct CrossChainRequest {
        // Array of calls to make on the destination chain
        Call[] calls;
        // The chainId of the destination chain
        uint256 destinationChainId;
        // The L2 contract on destination chain that's storage will be used to verify whether or not this call was made
        address verifyingContract;
        // The L1 address of the contract that should have L2 block info stored
        address l2Oracle;
        // The storage key at which we expect to find the L2 block info on the l2Oracle
        bytes32 l2OracleStorageKey;
        // The address of the ERC20 reward asset to be paid to whoever proves they filled this call
        // Native asset specified as in ERC-7528 format
        address rewardAsset;
        // The reward amount to pay
        uint256 rewardAmount;
        // The minimum age of the L1 block used for the proof
        uint256 finalityDelaySeconds;
        // An optional pre-check contract address on the destination chain
        // Zero address represents no pre-check contract desired
        // Can be used for arbitrary validation of fill conditions
        address precheckContract;
        // Arbitrary encoded precheck data
        bytes precheckData;
    }

    enum CrossChainCallStatus {
        None,
        Requested,
        CancelRequested,
        Canceled,
        Completed
    }

    error InvalidValue(uint256 expected, uint256 received);
    error InvalidStatusForRequestCancel(CrossChainCallStatus status);
    error InvalidStatusForFinalizeCancel(CrossChainCallStatus status);

    event CrossChainCallRequested(bytes32 indexed callHash, CrossChainCall call);
    event CrossChainCallCancelRequested(bytes32 indexed callHash);
    event CrossChainCallCancelFinalized(bytes32 indexed callHash);

    mapping(bytes32 callHash => CrossChainCallStatus status) public requestStatus;
    mapping(bytes32 callHash => uint256 timestampSeconds) public cancelRequestedAt;

    /// @dev The duration, in excess of
    /// CrossChainRequest.finalityDelaySeconds, which must pass
    /// between requesting and finalizing a request cancellation
    uint256 public cancelDelaySeconds = 1 days;

    address internal NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal _nonce;

    function requestCrossChainCall(CrossChainRequest calldata request) external payable {
        CrossChainCall memory crossChainCall = CrossChainCall({
            calls: request.calls,
            originationContract: address(this),
            originChainId: block.chainid,
            destinationChainId: request.destinationChainId,
            nonce: ++_nonce,
            verifyingContract: request.verifyingContract,
            precheckContract: request.precheckContract,
            precheckData: request.precheckData
        });

        bytes32 hash = callHash(request);
        requestStatus[hash] = CrossChainCallStatus.Requested;

        if (request.rewardAsset == NATIVE_ASSET) {
            if (request.rewardAmount != msg.value) {
                revert InvalidValue(request.rewardAmount, msg.value);
            }
        } else {
            _pullERC20(msg.sender, request.rewardAsset, request.rewardAmount);
        }

        emit CrossChainCallRequested(hash, crossChainCall);
    }

    function claimReward(
        CrossChainRequest calldata crossChainCall,
        RIP7755Verifier.FulfillmentInfo calldata fillInfo,
        bytes calldata storageProofData,
        address payTo
    ) external payable {
        bytes32 hash = callHashCalldata(crossChainCall);
        bytes32 storageKey = keccak256(
            abi.encodePacked(
                hash,
                uint256(0) // Must be at slot 0
            )
        );

        _validate(storageKey, fillInfo, crossChainCall, storageProofData);
        requestStatus[hash] = CrossChainCallStatus.Completed;

        if (crossChainCall.rewardAsset == NATIVE_ASSET) {
            payable(payTo).call{value: crossChainCall.rewardAmount, gas: 100_000}("");
        } else {
            _sendERC20(payTo, crossChainCall.rewardAsset, crossChainCall.rewardAmount);
        }
    }

    function requestCancel(CrossChainRequest calldata crossChainCall) external {
        bytes32 hash = callHashCalldata(crossChainCall);
        CrossChainCallStatus status = requestStatus[hash];
        if (status != CrossChainCallStatus.Requested) {
            revert InvalidStatusForRequestCancel(status);
        }

        requestStatus[hash] = CrossChainCallStatus.CancelRequested;

        emit CrossChainCallCancelRequested(hash);
    }

    function finalizeCancel(CrossChainRequest calldata crossChainCall) external {
        bytes32 hash = callHashCalldata(crossChainCall);
        CrossChainCallStatus status = requestStatus[hash];
        if (status != CrossChainCallStatus.CancelRequested) {
            revert InvalidStatusForFinalizeCancel(status);
        }

        requestStatus[hash] = CrossChainCallStatus.Canceled;

        emit CrossChainCallCancelFinalized(hash);
    }

    function callHash(CrossChainRequest memory crossChainCall) public pure returns (bytes32) {
        return keccak256(abi.encode(crossChainCall));
    }

    function callHashCalldata(CrossChainRequest calldata crossChainCall) public pure returns (bytes32) {
        return keccak256(abi.encode(crossChainCall));
    }

    /// @notice Validates storage proofs and verifies fill
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fillInfo not found at verifyingContractStorageKey on crossChainCall.verifyingContract
    /// @custom:reverts If fillInfo.timestamp is less than
    /// crossChainCall.finalityDelaySeconds from current destination chain block timestamp.
    /// @dev Implementation will vary by L2
    function _validate(
        bytes32 verifyingContractStorageKey,
        RIP7755Verifier.FulfillmentInfo calldata fillInfo,
        CrossChainRequest calldata crossChainCall,
        bytes calldata storageProofData
    ) internal view virtual;

    /// @notice Pulls `amount` of `asset` from `owner` to address(this)
    /// @dev Left abstract to minimize imports and maximize simplicity for this example
    function _pullERC20(address owner, address asset, uint256 amount) internal virtual;

    /// @notice Sends `amount` of `asset` to `to`
    /// @dev Left abstract to minimize imports and maximize simplicity for this example
    function _sendERC20(address to, address asset, uint256 amount) internal virtual;
}
