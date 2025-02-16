// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {UserOperationLib} from "account-abstraction/core/UserOperationLib.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {GlobalTypes} from "./libraries/GlobalTypes.sol";
import {NonceManager} from "./NonceManager.sol";
import {RRC7755Base} from "./RRC7755Base.sol";
import {RRC7755Inbox} from "./RRC7755Inbox.sol";

/// @title RRC7755Outbox
///
/// @author Coinbase (https://github.com/base/RRC-7755-poc)
///
/// @notice A source contract for initiating RRC-7755 Cross Chain Requests as well as reward fulfillment to Fulfillers
///         that submit the cross chain calls to destination chains.
abstract contract RRC7755Outbox is RRC7755Base, NonceManager {
    using GlobalTypes for address;
    using GlobalTypes for bytes32;
    using UserOperationLib for PackedUserOperation;
    using SafeTransferLib for address;

    /// @notice An enum representing the status of an RRC-7755 cross chain call
    enum CrossChainCallStatus {
        None,
        Requested,
        Canceled,
        Completed
    }

    /// @notice The selector for the nonce attribute
    bytes4 internal constant _NONCE_ATTRIBUTE_SELECTOR = 0xce03fdab; // nonce(uint256)

    /// @notice The selector for the reward attribute
    bytes4 internal constant _REWARD_ATTRIBUTE_SELECTOR = 0xa362e5db; // reward(bytes32,uint256) rewardAsset, rewardAmount

    /// @notice The selector for the delay attribute
    bytes4 internal constant _DELAY_ATTRIBUTE_SELECTOR = 0x84f550e0; // delay(uint256,uint256) finalityDelaySeconds, expiry

    /// @notice The selector for the requester attribute
    bytes4 internal constant _REQUESTER_ATTRIBUTE_SELECTOR = 0x3bd94e4c; // requester(bytes32)

    /// @notice The selector for the l2Oracle attribute
    bytes4 internal constant _L2_ORACLE_ATTRIBUTE_SELECTOR = 0x7ff7245a; // l2Oracle(address)

    /// @notice A mapping from the keccak256 hash of a message request to its current status
    mapping(bytes32 => CrossChainCallStatus) private _messageStatus;

    /// @notice The bytes32 representation of the address representing the native currency of the blockchain this
    ///         contract is deployed on following ERC-7528
    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    /// @notice Main storage location used as the base for the fulfillmentInfo mapping following EIP-7201.
    ///         keccak256(abi.encode(uint256(keccak256(bytes("RRC-7755"))) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _VERIFIER_STORAGE_LOCATION =
        0x40f2eef6aad3cb0e74d3b59b45d3d5f2d5fc8dc382e739617b693cdd4bc30c00;

    /// @notice The duration, in excess of CrossChainRequest.expiry, which must pass before a request can be canceled
    uint256 public constant CANCEL_DELAY_SECONDS = 1 days;

    /// @notice Event emitted when a user sends a message to the `RRC7755Inbox`
    ///
    /// @param outboxId         The keccak256 hash of the message request
    /// @param sourceChain      The chain identifier of the source chain
    /// @param sender           The account address of the sender
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param payload          The messages to be included in the request
    /// @param value            The native asset value of the call
    /// @param attributes       The attributes to be included in the message
    event MessagePosted(
        bytes32 indexed outboxId,
        bytes32 sourceChain,
        bytes32 sender,
        bytes32 destinationChain,
        bytes32 receiver,
        bytes payload,
        uint256 value,
        bytes[] attributes
    );

    /// @notice Event emitted when a cross chain call is successfully completed
    ///
    /// @param requestHash The keccak256 hash of a `CrossChainRequest`
    /// @param submitter   The address of the fulfiller that successfully completed the cross chain call
    event CrossChainCallCompleted(bytes32 indexed requestHash, address submitter);

    /// @notice Event emitted when an expired cross chain call request is canceled
    ///
    /// @param requestHash The keccak256 hash of a `CrossChainRequest`
    event CrossChainCallCanceled(bytes32 indexed requestHash);

    /// @notice This error is thrown when a cross chain request specifies the native currency as the reward type but
    ///         does not send the correct `msg.value`
    ///
    /// @param expected The expected `msg.value` that should have been sent with the transaction
    /// @param received The actual `msg.value` that was sent with the transaction
    error InvalidValue(uint256 expected, uint256 received);

    /// @notice This error is thrown if a user attempts to cancel a request or a Filler attempts to claim a reward for
    ///         a request that is not in the `CrossChainCallStatus.Requested` state
    ///
    /// @param expected The expected status during the transaction
    /// @param actual   The actual request status during the transaction
    error InvalidStatus(CrossChainCallStatus expected, CrossChainCallStatus actual);

    /// @notice This error is thrown if an attempt to cancel a request is made before the request's expiry timestamp
    ///
    /// @param currentTimestamp The current block timestamp
    /// @param expiry           The timestamp at which the request expires
    error CannotCancelRequestBeforeExpiry(uint256 currentTimestamp, uint256 expiry);

    /// @notice This error is thrown if an account attempts to cancel a request that did not originate from that account
    ///
    /// @param caller         The account attempting the request cancellation
    /// @param expectedCaller The account that created the request
    error InvalidCaller(address caller, address expectedCaller);

    /// @notice This error is thrown if a request expiry does not give enough time for the delay attribute to pass
    error ExpiryTooSoon();

    /// @notice This error is thrown if an unsupported attribute is provided
    ///
    /// @param selector The selector of the unsupported attribute
    error UnsupportedAttribute(bytes4 selector);

    /// @notice This error is thrown if a required attribute is missing from the global attributes array for a 7755
    ///         request
    ///
    /// @param selector The selector of the missing attribute
    error MissingRequiredAttribute(bytes4 selector);

    /// @notice This error is thrown if the passed in nonce is incorrect
    error InvalidNonce();

    /// @notice This error is thrown if the passed in requester is not equal to msg.sender
    error InvalidRequester();

    /// @notice Initiates the sending of a 7755 request containing a single message
    ///
    /// @custom:reverts If the attributes array length is less than 3
    /// @custom:reverts If a required attribute is missing from the global attributes array. Required attributes are:
    ///                   - Reward attribute
    ///                   - Delay attribute
    ///                   - Inbox attribute
    /// @custom:reverts If an unsupported attribute is provided
    ///
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param payload          The encoded calls array
    /// @param attributes       The attributes to be included in the message
    ///
    /// @return messageId The generated request id
    function sendMessage(
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata attributes
    ) external payable returns (bytes32) {
        if (attributes.length == 0) {
            bytes[] memory userOpAttributes = _getUserOpAttributes(payload);
            this.processAttributes(userOpAttributes, msg.sender, msg.value);
        } else {
            this.processAttributes(attributes, msg.sender, msg.value);
        }

        bytes32 sender = address(this).addressToBytes32();
        bytes32 sourceChain = bytes32(block.chainid);

        bytes32 messageId = getRequestId(sourceChain, sender, destinationChain, receiver, payload, attributes);
        _messageStatus[messageId] = CrossChainCallStatus.Requested;

        emit MessagePosted(messageId, sourceChain, sender, destinationChain, receiver, payload, msg.value, attributes);

        return messageId;
    }

    /// @notice To be called by a Filler that successfully submitted a cross chain request to the destination chain and
    ///         can prove it with a valid nested storage proof
    ///
    /// @custom:reverts If the request is not in the `CrossChainCallStatus.Requested` state
    /// @custom:reverts If storage proof invalid
    /// @custom:reverts If finality delay seconds have not passed since the request was fulfilled on destination chain
    /// @custom:reverts If the reward attribute is not found in the attributes array
    ///
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param payload          The encoded calls array
    /// @param attributes       The attributes to be included in the message
    /// @param proof            A proof that cryptographically verifies that `fulfillmentInfo` does, indeed, exist in
    ///                         storage on the destination chain
    /// @param payTo            The address the Filler wants to receive the reward
    function claimReward(
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata attributes,
        bytes calldata proof,
        address payTo
    ) external {
        bytes32 sender = address(this).addressToBytes32();
        bytes32 sourceChain = bytes32(block.chainid);
        bytes32 messageId = getRequestId(sourceChain, sender, destinationChain, receiver, payload, attributes);

        bytes memory storageKey = abi.encode(keccak256(abi.encodePacked(messageId, _VERIFIER_STORAGE_LOCATION)));
        _validateProof(storageKey, receiver.bytes32ToAddress(), attributes, proof);

        (bytes32 rewardAsset, uint256 rewardAmount) = _getReward(attributes);

        _processClaim(messageId, payTo, rewardAsset, rewardAmount);
    }

    /// @notice To be called by a Filler that successfully submitted a cross chain user operation to the destination chain
    ///
    /// @custom:reverts If the request is not in the `CrossChainCallStatus.Requested` state
    /// @custom:reverts If storage proof invalid
    /// @custom:reverts If finality delay seconds have not passed since the request was fulfilled on destination chain
    /// @custom:reverts If the reward attribute is not found in the attributes array
    ///
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param userOp           The ERC-4337 User Operation
    /// @param proof            A proof that cryptographically verifies that `fulfillmentInfo` does, indeed, exist in
    ///                         storage on the destination chain
    /// @param payTo            The address the Filler wants to receive the reward
    function claimReward(
        bytes32 destinationChain,
        bytes32 receiver,
        PackedUserOperation calldata userOp,
        bytes calldata proof,
        address payTo
    ) external {
        bytes32 messageId = getUserOpHash(userOp, receiver, destinationChain);

        bytes memory storageKey = abi.encode(keccak256(abi.encodePacked(messageId, _VERIFIER_STORAGE_LOCATION)));
        address inbox = address(bytes20(userOp.paymasterAndData[:20]));
        bytes[] memory attributes = getUserOpAttributes(userOp);
        (bytes32 rewardAsset, uint256 rewardAmount) =
            this.innerValidateProofAndGetReward(storageKey, inbox, attributes, proof);

        _processClaim(messageId, payTo, rewardAsset, rewardAmount);
    }

    /// @notice Cancels a pending request that has expired
    ///
    /// @custom:reverts If the request is not in the `CrossChainCallStatus.Requested` state
    /// @custom:reverts If the requester attribute is not found in the attributes array
    /// @custom:reverts If the delay attribute is not found in the attributes array
    /// @custom:reverts If `msg.sender` is not the requester defined by the requester attribute
    /// @custom:reverts If the current block timestamp is less than the expiry timestamp plus the cancel delay seconds
    /// @custom:reverts If the reward attribute is not found in the attributes array
    ///
    /// @param destinationChain The CAIP-2 chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param payload          The encoded calls to be included in the request
    /// @param attributes       The attributes to be included in the message
    function cancelMessage(
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata attributes
    ) external {
        bytes32 sender = address(this).addressToBytes32();
        bytes32 sourceChain = bytes32(block.chainid);
        bytes32 messageId = getRequestId(sourceChain, sender, destinationChain, receiver, payload, attributes);

        (bytes32 requester, uint256 expiry, bytes32 rewardAsset, uint256 rewardAmount) =
            getRequesterAndExpiryAndReward(attributes);

        _processCancellation(messageId, requester, expiry, rewardAsset, rewardAmount);
    }

    /// @notice Cancels a pending user op request that has expired
    ///
    /// @custom:reverts If the request is not in the `CrossChainCallStatus.Requested` state
    /// @custom:reverts If the requester attribute is not found in the attributes array
    /// @custom:reverts If the delay attribute is not found in the attributes array
    /// @custom:reverts If `msg.sender` is not the requester defined by the requester attribute
    /// @custom:reverts If the current block timestamp is less than the expiry timestamp plus the cancel delay seconds
    ///
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param userOp           The ERC-4337 User Operation
    function cancelUserOp(bytes32 destinationChain, bytes32 receiver, PackedUserOperation calldata userOp) external {
        bytes32 messageId = getUserOpHash(userOp, receiver, destinationChain);
        bytes[] memory attributes = getUserOpAttributes(userOp);

        (bytes32 requester, uint256 expiry, bytes32 rewardAsset, uint256 rewardAmount) =
            this.getRequesterAndExpiryAndReward(attributes);

        _processCancellation(messageId, requester, expiry, rewardAsset, rewardAmount);
    }

    /// @notice Returns the cross chain call request status for a hashed request
    ///
    /// @param messageId The keccak256 hash of a message request
    ///
    /// @return _ The `CrossChainCallStatus` status for the associated message request
    function getMessageStatus(bytes32 messageId) external view returns (CrossChainCallStatus) {
        return _messageStatus[messageId];
    }

    /// @notice Returns true if the attribute selector is supported by this contract
    ///
    /// @param selector The selector of the attribute
    ///
    /// @return _ True if the attribute selector is supported by this contract
    function supportsAttribute(bytes4 selector) external pure returns (bool) {
        return selector == _REWARD_ATTRIBUTE_SELECTOR || selector == _DELAY_ATTRIBUTE_SELECTOR;
    }

    /// @notice This is only to be called by this contract during a `sendMessage` call
    ///
    /// @custom:reverts If the caller is not this contract
    ///
    /// @param attributes The attributes to be processed
    /// @param requester  The address of the requester
    /// @param value      The value of the message
    function processAttributes(bytes[] calldata attributes, address requester, uint256 value) public {
        if (msg.sender != address(this)) {
            revert InvalidCaller({caller: msg.sender, expectedCaller: address(this)});
        }

        bool[4] memory attributeProcessed = [false, false, false, false];

        for (uint256 i; i < attributes.length; i++) {
            bytes4 attributeSelector = bytes4(attributes[i]);

            if (attributeSelector == _REWARD_ATTRIBUTE_SELECTOR && !attributeProcessed[0]) {
                _handleRewardAttribute(attributes[i], requester, value);
                attributeProcessed[0] = true;
            } else if (attributeSelector == _DELAY_ATTRIBUTE_SELECTOR && !attributeProcessed[1]) {
                _handleDelayAttribute(attributes[i]);
                attributeProcessed[1] = true;
            } else if (attributeSelector == _NONCE_ATTRIBUTE_SELECTOR && !attributeProcessed[2]) {
                // confirm passed in nonce == _incrementNonce()
                if (abi.decode(attributes[i][4:], (uint256)) != _incrementNonce(requester)) {
                    revert InvalidNonce();
                }
                attributeProcessed[2] = true;
            } else if (attributeSelector == _REQUESTER_ATTRIBUTE_SELECTOR && !attributeProcessed[3]) {
                // confirm passed in requester == msg.sender
                if (abi.decode(attributes[i][4:], (bytes32)) != requester.addressToBytes32()) {
                    revert InvalidRequester();
                }
                attributeProcessed[3] = true;
            } else if (!_isOptionalAttribute(attributeSelector)) {
                revert UnsupportedAttribute(attributeSelector);
            }
        }

        if (!attributeProcessed[0]) {
            revert MissingRequiredAttribute(_REWARD_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[1]) {
            revert MissingRequiredAttribute(_DELAY_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[2]) {
            revert MissingRequiredAttribute(_NONCE_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[3]) {
            revert MissingRequiredAttribute(_REQUESTER_ATTRIBUTE_SELECTOR);
        }
    }

    /// @notice Validates storage proofs and verifies fill
    ///
    /// @custom:reverts If storage proof invalid
    /// @custom:reverts If fillInfo not found at inboxContractStorageKey on crossChainCall.verifyingContract
    /// @custom:reverts If fillInfo.timestamp is less than crossChainCall.finalityDelaySeconds from current destination
    ///                 chain block timestamp
    ///
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    ///                                `RRC7755Inbox` contract
    /// @param inbox                   The address of the `RRC7755Inbox` contract
    /// @param attributes              The attributes to be included in the message
    /// @param proofData               The proof to validate
    function innerValidateProofAndGetReward(
        bytes memory inboxContractStorageKey,
        address inbox,
        bytes[] calldata attributes,
        bytes calldata proofData
    ) public view returns (bytes32, uint256) {
        _validateProof(inboxContractStorageKey, inbox, attributes, proofData);
        (bytes32 rewardAsset, uint256 rewardAmount) = _getReward(attributes);
        return (rewardAsset, rewardAmount);
    }

    /// @notice Returns the keccak256 hash of a message request or the user op hash if the request is an ERC-4337 User
    ///         Operation
    ///
    /// @param sourceChain      The source chain identifier
    /// @param sender           The account address of the sender
    /// @param destinationChain The chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param payload          The messages to be included in the request
    /// @param attributes       The attributes to be included in the message
    ///
    /// @return _ The keccak256 hash of the message request
    function getRequestId(
        bytes32 sourceChain,
        bytes32 sender,
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata attributes
    ) public view override returns (bytes32) {
        return attributes.length == 0
            ? this.getUserOpHash(abi.decode(payload, (PackedUserOperation)), receiver, destinationChain)
            : super.getRequestId(sourceChain, sender, destinationChain, receiver, payload, attributes);
    }

    /// @notice Returns the hash of an ERC-4337 User Operation
    ///
    /// @param userOp           The ERC-4337 User Operation
    /// @param receiver         The destination chain EntryPoint contract address
    /// @param destinationChain The destination chain identifier
    ///
    /// @return _ The hash of the ERC-4337 User Operation
    function getUserOpHash(PackedUserOperation calldata userOp, bytes32 receiver, bytes32 destinationChain)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(userOp.hash(), receiver.bytes32ToAddress(), uint256(destinationChain)));
    }

    /// @notice Returns the requester, expiry, reward asset, and reward amount from the attributes array
    ///
    /// @param attributes The attributes to be included in the message
    ///
    /// @return _ The requester, expiry, reward asset, and reward amount
    function getRequesterAndExpiryAndReward(bytes[] calldata attributes)
        public
        pure
        returns (bytes32, uint256, bytes32, uint256)
    {
        bytes32 requester;
        uint256 expiry;
        bytes32 rewardAsset;
        uint256 rewardAmount;

        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) == _REQUESTER_ATTRIBUTE_SELECTOR) {
                requester = abi.decode(attributes[i][4:], (bytes32));
            } else if (bytes4(attributes[i]) == _DELAY_ATTRIBUTE_SELECTOR) {
                (, expiry) = abi.decode(attributes[i][4:], (uint256, uint256));
            } else if (bytes4(attributes[i]) == _REWARD_ATTRIBUTE_SELECTOR) {
                (rewardAsset, rewardAmount) = abi.decode(attributes[i][4:], (bytes32, uint256));
            }
        }

        return (requester, expiry, rewardAsset, rewardAmount);
    }

    /// @notice Returns the attributes for an ERC-4337 User Operation
    ///
    /// @param userOp The ERC-4337 User Operation
    ///
    /// @return _ The attributes for the ERC-4337 User Operation
    function getUserOpAttributes(PackedUserOperation calldata userOp) public pure returns (bytes[] memory) {
        (,,, bytes[] memory userOpAttributes) =
            abi.decode(userOp.paymasterAndData[52:], (address, uint256, address, bytes[]));
        return userOpAttributes;
    }

    /// @notice Validates storage proofs and verifies fill
    ///
    /// @custom:reverts If storage proof invalid
    /// @custom:reverts If fillInfo not found at inboxContractStorageKey on crossChainCall.verifyingContract
    /// @custom:reverts If fillInfo.timestamp is less than crossChainCall.finalityDelaySeconds from current destination
    ///                 chain block timestamp
    ///
    /// @dev Implementation will vary by L2
    ///
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    ///                                `RRC7755Inbox` contract
    /// @param inbox                   The address of the `RRC7755Inbox` contract
    /// @param attributes              The attributes to be included in the message
    /// @param proofData               The proof to validate
    function _validateProof(
        bytes memory inboxContractStorageKey,
        address inbox,
        bytes[] calldata attributes,
        bytes calldata proofData
    ) internal view virtual;

    /// @notice Decodes the `FulfillmentInfo` struct from the `RRC7755Inbox` storage slot
    ///
    /// @param inboxContractStorageValue The storage value of the `RRC7755Inbox` storage slot
    ///
    /// @return fulfillmentInfo The decoded `FulfillmentInfo` struct
    function _decodeFulfillmentInfo(bytes32 inboxContractStorageValue)
        internal
        pure
        returns (RRC7755Inbox.FulfillmentInfo memory)
    {
        RRC7755Inbox.FulfillmentInfo memory fulfillmentInfo;
        fulfillmentInfo.fulfiller = address(uint160((uint256(inboxContractStorageValue) >> 96) & type(uint160).max));
        fulfillmentInfo.timestamp = uint96(uint256(inboxContractStorageValue));
        return fulfillmentInfo;
    }

    function _isOptionalAttribute(bytes4 selector) internal pure virtual returns (bool) {
        return selector == _PRECHECK_ATTRIBUTE_SELECTOR || selector == _L2_ORACLE_ATTRIBUTE_SELECTOR;
    }

    function _handleRewardAttribute(bytes calldata attribute, address requester, uint256 value) private {
        (bytes32 rewardAsset, uint256 rewardAmount) = abi.decode(attribute[4:], (bytes32, uint256));

        bool usingNativeCurrency = rewardAsset == _NATIVE_ASSET;
        uint256 expectedValue = usingNativeCurrency ? rewardAmount : 0;

        if (value != expectedValue) {
            revert InvalidValue(expectedValue, value);
        }

        if (!usingNativeCurrency) {
            rewardAsset.bytes32ToAddress().safeTransferFrom(requester, address(this), rewardAmount);
        }
    }

    function _processClaim(bytes32 messageId, address payTo, bytes32 rewardAsset, uint256 rewardAmount) private {
        _checkValidStatus({requestHash: messageId, expectedStatus: CrossChainCallStatus.Requested});
        _messageStatus[messageId] = CrossChainCallStatus.Completed;
        _sendReward(payTo, rewardAsset, rewardAmount);

        emit CrossChainCallCompleted(messageId, msg.sender);
    }

    function _processCancellation(
        bytes32 messageId,
        bytes32 requester,
        uint256 expiry,
        bytes32 rewardAsset,
        uint256 rewardAmount
    ) private {
        _checkValidStatus({requestHash: messageId, expectedStatus: CrossChainCallStatus.Requested});

        if (msg.sender.addressToBytes32() != requester) {
            revert InvalidCaller({caller: msg.sender, expectedCaller: requester.bytes32ToAddress()});
        }
        if (block.timestamp < expiry + CANCEL_DELAY_SECONDS) {
            revert CannotCancelRequestBeforeExpiry({
                currentTimestamp: block.timestamp,
                expiry: expiry + CANCEL_DELAY_SECONDS
            });
        }

        _messageStatus[messageId] = CrossChainCallStatus.Canceled;

        // Return the stored reward back to the original requester
        _sendReward(requester.bytes32ToAddress(), rewardAsset, rewardAmount);

        emit CrossChainCallCanceled(messageId);
    }

    function _sendReward(address to, bytes32 rewardAsset, uint256 rewardAmount) private {
        if (rewardAsset == _NATIVE_ASSET) {
            to.safeTransferETH(rewardAmount);
        } else {
            rewardAsset.bytes32ToAddress().safeTransfer(to, rewardAmount);
        }
    }

    function _handleDelayAttribute(bytes calldata attribute) private view {
        (uint256 finalityDelaySeconds, uint256 expiry) = abi.decode(attribute[4:], (uint256, uint256));

        if (expiry < block.timestamp + finalityDelaySeconds) {
            revert ExpiryTooSoon();
        }
    }

    function _checkValidStatus(bytes32 requestHash, CrossChainCallStatus expectedStatus) private view {
        CrossChainCallStatus status = _messageStatus[requestHash];

        if (status != expectedStatus) {
            revert InvalidStatus({expected: expectedStatus, actual: status});
        }
    }

    function _getUserOpAttributes(bytes calldata payload) private view returns (bytes[] memory) {
        PackedUserOperation memory userOp = abi.decode(payload, (PackedUserOperation));
        return this.getUserOpAttributes(userOp);
    }

    function _getReward(bytes[] calldata attributes) private pure returns (bytes32, uint256) {
        bytes32 rewardAsset;
        uint256 rewardAmount;

        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) == _REWARD_ATTRIBUTE_SELECTOR) {
                (rewardAsset, rewardAmount) = abi.decode(attributes[i][4:], (bytes32, uint256));
            }
        }

        return (rewardAsset, rewardAmount);
    }
}
