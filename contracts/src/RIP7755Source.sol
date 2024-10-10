// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {CrossChainCall, Call} from "./RIP7755Structs.sol";
import {RIP7755Verifier} from "./RIP7755Verifier.sol";

// TODO: Should `msg.value` be allowed if not using native currency for reward ?
// TODO: Potential edge case: cross chain call to send native currency but pay reward in erc20
// TODO: Potential edge case: cross chain call to send native currency to chain with different native currency ?
// TODO: Add time validation to finalize cancel
// TODO: combine mappings
// TODO: Return asset from request cancel

/// @title RIP7755Source
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice A source contract for initiating RIP-7755 Cross Chain Requests as well as reward fulfillment to Fillers that
/// submit the cross chain calls to destination chains.
abstract contract RIP7755Source {
    using Address for address payable;
    using SafeERC20 for IERC20;

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
        /// @dev The amount of seconds this request remains valid for
        uint256 validDuration;
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
        Canceled,
        Completed
    }

    /// @notice A mapping from the keccak256 hash of a `CrossChainRequest` to its current `CrossChainCallStatus`
    mapping(bytes32 requestHash => CrossChainCallStatus status) private _requestStatus;

    /// @notice A mapping from the keccak256 hash of a `CrossChainRequest` to the timestamp it expires at
    mapping(bytes32 requestHash => uint256 expiryTimestamp) private _requestExpiry;

    /// @notice The address representing the native currency of the blockchain this contract is deployed on
    address internal constant _NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice An incrementing nonce value to ensure no two `CrossChainRequest` can be exactly the same
    uint256 private _nonce;

    /// @notice Event emitted when a user requests a cross chain call to be made by a filler
    /// @param requestHash The keccak256 hash of a `CrossChainRequest`
    /// @param call The requested call converted to a `CrossChainCall` structure
    event CrossChainCallRequested(bytes32 indexed requestHash, CrossChainCall call);

    /// @notice Event emitted when an expired cross chain call request is canceled
    /// @param requestHash The keccak256 hash of a `CrossChainRequest`
    event CrossChainCallCanceled(bytes32 indexed requestHash);

    /// @notice This error is thrown when a cross chain request specifies the native currency as the reward type but
    /// does not send the correct `msg.value`
    /// @param expected The expected `msg.value` that should have been sent with the transaction
    /// @param received The actual `msg.value` that was sent with the transaction
    error InvalidValue(uint256 expected, uint256 received);

    /// @notice This error is thrown if a user attempts to cancel a request that is not in the `CrossChainCallStatus.Requested` state
    /// @param status The `CrossChainCallStatus` status that the request has
    error InvalidStatusForRequestCancel(CrossChainCallStatus status);

    /// @notice This error is thrown if a Filler attempts to claim a reward for a request that is not in a `CrossChainCallStatus.Requested` state
    /// @param status The `CrossChainCallStatus` status of the request
    error InvalidStatusForClaim(CrossChainCallStatus status);

    /// @notice Submits an RIP-7755 request for a cross chain call
    ///
    /// @param request A cross chain request structured as a `CrossChainRequest`
    function requestCrossChainCall(CrossChainRequest calldata request) external payable {
        CrossChainCall memory crossChainCall = _convertToCrossChainCallAndAssignNonce(request);
        bool usingNativeCurrency = request.rewardAsset == _NATIVE_ASSET;

        if (usingNativeCurrency && request.rewardAmount != msg.value) {
            revert InvalidValue(request.rewardAmount, msg.value);
        }

        bytes32 requestHash = hashCalldataCall(request);
        _requestStatus[requestHash] = CrossChainCallStatus.Requested;
        _requestExpiry[requestHash] = block.timestamp + request.validDuration;

        emit CrossChainCallRequested(requestHash, crossChainCall);

        if (!usingNativeCurrency) {
            _pullERC20(msg.sender, request.rewardAsset, request.rewardAmount);
        }
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
    ) external {
        bytes32 requestHash = hashCalldataCall(request);
        bytes32 storageKey = keccak256(
            abi.encodePacked(
                requestHash,
                uint256(0) // Must be at slot 0
            )
        );

        _checkValidStatusForClaim(requestHash);

        _validate(storageKey, fillInfo, request, storageProofData);
        _requestStatus[requestHash] = CrossChainCallStatus.Completed;

        if (request.rewardAsset == _NATIVE_ASSET) {
            payable(payTo).sendValue(request.rewardAmount);
        } else {
            _sendERC20(payTo, request.rewardAsset, request.rewardAmount);
        }
    }

    /// @notice Cancels a pending request that has expired
    ///
    /// @dev Can only be called if the request is in the `CrossChainCallStatus.Requested` state
    ///
    /// @param requestHash The keccak256 hash of a `CrossChainRequest`
    function cancelRequest(bytes32 requestHash) external {
        CrossChainCallStatus status = _requestStatus[requestHash];

        if (status != CrossChainCallStatus.Requested) {
            revert InvalidStatusForRequestCancel(status);
        }

        _requestStatus[requestHash] = CrossChainCallStatus.Canceled;

        emit CrossChainCallCanceled(requestHash);
    }

    /// @notice Returns the cross chain call request status for a hashed request
    ///
    /// @param requestHash The keccak256 hash of a `CrossChainRequest`
    ///
    /// @return _ The `CrossChainCallStatus` status for the associated cross chain call request
    function getRequestStatus(bytes32 requestHash) external view returns (CrossChainCallStatus) {
        return _requestStatus[requestHash];
    }

    /// @notice Converts a `CrossChainRequest` to a `CrossChainCall`
    ///
    /// @param request A cross chain request structured as a `CrossChainRequest`
    ///
    /// @return _ The converted `CrossChainCall` to be submitted to destination chain
    function convertToCrossChainCall(CrossChainRequest calldata request) public view returns (CrossChainCall memory) {
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
    function _pullERC20(address owner, address asset, uint256 amount) private {
        IERC20(asset).safeTransferFrom(owner, address(this), amount);
    }

    /// @notice Sends `amount` of `asset` to `to`
    function _sendERC20(address to, address asset, uint256 amount) private {
        IERC20(asset).safeTransfer(to, amount);
    }

    function _convertToCrossChainCallAndAssignNonce(CrossChainRequest calldata request)
        private
        returns (CrossChainCall memory)
    {
        CrossChainCall memory crossChainCall = convertToCrossChainCall(request);
        crossChainCall.nonce = ++_nonce;
        return crossChainCall;
    }

    function _checkValidStatusForClaim(bytes32 requestHash) private view {
        CrossChainCallStatus status = _requestStatus[requestHash];

        if (status != CrossChainCallStatus.Requested) {
            revert InvalidStatusForClaim(status);
        }
    }
}
