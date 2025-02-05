// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

import {GlobalTypes} from "./libraries/GlobalTypes.sol";
import {RIP7755Base} from "./RIP7755Base.sol";
import {RIP7755Inbox} from "./RIP7755Inbox.sol";

/// @title RIP7755Outbox
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice A source contract for initiating RIP-7755 Cross Chain Requests as well as reward fulfillment to Fulfillers
///         that submit the cross chain calls to destination chains.
abstract contract RIP7755Outbox is RIP7755Base {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using GlobalTypes for address;
    using GlobalTypes for bytes32;

    /// @notice An enum representing the status of an RIP-7755 cross chain call
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

    /// @notice The selector for the inbox attribute
    bytes4 internal constant _INBOX_ATTRIBUTE_SELECTOR = 0xbd362374; // inbox(bytes32)

    /// @notice A mapping from the keccak256 hash of a message request to its current status
    mapping(bytes32 messageId => CrossChainCallStatus status) private _messageStatus;

    /// @notice The bytes32 representation of the address representing the native currency of the blockchain this
    ///         contract is deployed on following ERC-7528
    bytes32 private constant _NATIVE_ASSET = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    /// @notice Main storage location used as the base for the fulfillmentInfo mapping following EIP-7201. Derived from
    ///         the equation keccak256(abi.encode(uint256(keccak256(bytes("RIP-7755"))) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _VERIFIER_STORAGE_LOCATION =
        0xfd1017d80ffe8da8a74488ee7408c9efa1877e094afa95857de95797c1228500;

    /// @notice The duration, in excess of CrossChainRequest.expiry, which must pass before a request can be canceled
    uint256 public constant CANCEL_DELAY_SECONDS = 1 days;

    /// @notice The expected length of the attributes array supplied to `sendMessage`
    uint256 private constant _EXPECTED_ATTRIBUTE_LENGTH = 3;

    /// @notice An incrementing nonce value to ensure no two `CrossChainRequest` can be exactly the same
    uint256 private _nonce;

    /// @notice Event emitted when a user sends a message to the `RIP7755Inbox`
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

    /// @notice This error is thrown if the attribute length supplied to `sendMessage` is not equal to the expected
    ///         length
    ///
    /// @param expected The expected length of the attributes
    /// @param actual   The actual length of the attributes
    error InvalidAttributeLength(uint256 expected, uint256 actual);

    /// @notice This error is thrown if a required attribute is missing from the global attributes array for a 7755
    ///         request
    ///
    /// @param selector The selector of the missing attribute
    error MissingRequiredAttribute(bytes4 selector);

    /// @notice Initiates the sending of a 7755 request containing a single message
    ///
    /// @custom:reverts If the attributes array length is less than 3
    /// @custom:reverts If a required attribute is missing from the global attributes array. Required attributes are:
    ///                   - Reward attribute
    ///                   - Delay attribute
    ///                   - Inbox attribute
    /// @custom:reverts If an unsupported attribute is provided
    ///
    /// @param destinationChain The CAIP-2 chain identifier of the destination chain
    /// @param receiver         The CAIP-10 account address of the receiver (not including the chain identifier)
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
        bytes[] memory expandedAttributes = _processAttributes(attributes);
        bytes32 sender = address(this).addressToBytes32();
        bytes32 sourceChain = bytes32(block.chainid);

        bytes32 messageId =
            getRequestIdMemory(sourceChain, sender, destinationChain, receiver, payload, expandedAttributes);
        _messageStatus[messageId] = CrossChainCallStatus.Requested;

        emit MessagePosted(
            messageId, sourceChain, sender, destinationChain, receiver, payload, msg.value, expandedAttributes
        );

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
    /// @param destinationChain   The chain identifier of the destination chain
    /// @param receiver           The account address of the receiver
    /// @param payload            The encoded calls array
    /// @param expandedAttributes The attributes to be included in the message
    /// @param proof              A proof that cryptographically verifies that `fulfillmentInfo` does, indeed, exist in
    ///                           storage on the destination chain
    /// @param payTo              The address the Filler wants to receive the reward
    function claimReward(
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata expandedAttributes,
        bytes calldata proof,
        address payTo
    ) external {
        bytes32 sender = address(this).addressToBytes32();
        bytes32 sourceChain = bytes32(block.chainid);
        bytes32 messageId = getRequestId(sourceChain, sender, destinationChain, receiver, payload, expandedAttributes);
        bytes memory storageKey = abi.encode(keccak256(abi.encodePacked(messageId, _VERIFIER_STORAGE_LOCATION)));
        (address inbox, bytes32 rewardAsset, uint256 rewardAmount) = _getInboxAndReward(expandedAttributes);

        _checkValidStatus({requestHash: messageId, expectedStatus: CrossChainCallStatus.Requested});

        _validateProof(storageKey, inbox, expandedAttributes, proof);

        _messageStatus[messageId] = CrossChainCallStatus.Completed;

        _sendReward(payTo, rewardAsset, rewardAmount);

        emit CrossChainCallCompleted(messageId, msg.sender);
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
    /// @param destinationChain   The CAIP-2 chain identifier of the destination chain
    /// @param receiver           The account address of the receiver
    /// @param payload            The encoded calls to be included in the request
    /// @param expandedAttributes The attributes to be included in the message
    function cancelMessage(
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] calldata expandedAttributes
    ) external {
        bytes32 sender = address(this).addressToBytes32();
        bytes32 sourceChain = bytes32(block.chainid);
        bytes32 messageId = getRequestId(sourceChain, sender, destinationChain, receiver, payload, expandedAttributes);

        _checkValidStatus({requestHash: messageId, expectedStatus: CrossChainCallStatus.Requested});

        (bytes32 requester, uint256 expiry, bytes32 rewardAsset, uint256 rewardAmount) =
            _getRequesterAndExpiryAndReward(expandedAttributes);

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

    /// @notice Returns the keccak256 hash of a message request
    ///
    /// @param sourceChain      The source chain identifier
    /// @param sender           The CAIP-10 account address of the sender
    /// @param destinationChain The CAIP-2 chain identifier of the destination chain
    /// @param receiver         The account address of the receiver
    /// @param payload          The messages to be included in the request
    /// @param attributes       The attributes to be included in the message
    ///
    /// @return _ The keccak256 hash of the message request
    function getRequestIdMemory(
        bytes32 sourceChain,
        bytes32 sender,
        bytes32 destinationChain,
        bytes32 receiver,
        bytes calldata payload,
        bytes[] memory attributes
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(sourceChain, sender, destinationChain, receiver, payload, attributes));
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
    ///                                `RIP7755Inbox` contract
    /// @param inbox                   The address of the `RIP7755Inbox` contract
    /// @param attributes              The attributes to be included in the message
    /// @param proofData               The proof to validate
    function _validateProof(
        bytes memory inboxContractStorageKey,
        address inbox,
        bytes[] calldata attributes,
        bytes calldata proofData
    ) internal view virtual;

    /// @notice Decodes the `FulfillmentInfo` struct from the `RIP7755Inbox` storage slot
    ///
    /// @param inboxContractStorageValue The storage value of the `RIP7755Inbox` storage slot
    ///
    /// @return fulfillmentInfo The decoded `FulfillmentInfo` struct
    function _decodeFulfillmentInfo(bytes32 inboxContractStorageValue)
        internal
        pure
        returns (RIP7755Inbox.FulfillmentInfo memory)
    {
        RIP7755Inbox.FulfillmentInfo memory fulfillmentInfo;
        fulfillmentInfo.fulfiller = address(uint160((uint256(inboxContractStorageValue) >> 96) & type(uint160).max));
        fulfillmentInfo.timestamp = uint96(uint256(inboxContractStorageValue));
        return fulfillmentInfo;
    }

    function _processAttributes(bytes[] calldata attributes) private returns (bytes[] memory) {
        if (attributes.length < _EXPECTED_ATTRIBUTE_LENGTH) {
            revert InvalidAttributeLength(_EXPECTED_ATTRIBUTE_LENGTH, attributes.length);
        }

        bytes[] memory adjustedAttributes = new bytes[](attributes.length + 2);
        bool[3] memory attributeProcessed = [false, false, false];

        for (uint256 i; i < attributes.length; i++) {
            bytes4 attributeSelector = bytes4(attributes[i]);

            if (attributeSelector == _REWARD_ATTRIBUTE_SELECTOR && !attributeProcessed[0]) {
                _handleRewardAttribute(attributes[i]);
                attributeProcessed[0] = true;
            } else if (attributeSelector == _DELAY_ATTRIBUTE_SELECTOR && !attributeProcessed[1]) {
                _handleDelayAttribute(attributes[i]);
                attributeProcessed[1] = true;
            } else if (attributeSelector == _INBOX_ATTRIBUTE_SELECTOR && !attributeProcessed[2]) {
                attributeProcessed[2] = true;
            } else if (!_isOptionalAttribute(attributeSelector)) {
                revert UnsupportedAttribute(attributeSelector);
            }

            adjustedAttributes[i] = attributes[i];
        }

        if (!attributeProcessed[0]) {
            revert MissingRequiredAttribute(_REWARD_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[1]) {
            revert MissingRequiredAttribute(_DELAY_ATTRIBUTE_SELECTOR);
        }

        if (!attributeProcessed[2]) {
            revert MissingRequiredAttribute(_INBOX_ATTRIBUTE_SELECTOR);
        }

        adjustedAttributes[attributes.length] = abi.encodeWithSelector(_NONCE_ATTRIBUTE_SELECTOR, _getNextNonce());
        adjustedAttributes[attributes.length + 1] =
            abi.encodeWithSelector(_REQUESTER_ATTRIBUTE_SELECTOR, msg.sender.addressToBytes32());

        return adjustedAttributes;
    }

    function _handleRewardAttribute(bytes calldata attribute) private {
        (bytes32 rewardAsset, uint256 rewardAmount) = abi.decode(attribute[4:], (bytes32, uint256));

        bool usingNativeCurrency = rewardAsset == _NATIVE_ASSET;
        uint256 expectedValue = usingNativeCurrency ? rewardAmount : 0;

        if (msg.value != expectedValue) {
            revert InvalidValue(expectedValue, msg.value);
        }

        if (!usingNativeCurrency) {
            IERC20(rewardAsset.bytes32ToAddress()).safeTransferFrom(msg.sender, address(this), rewardAmount);
        }
    }

    function _getNextNonce() private returns (uint256) {
        unchecked {
            // It would take ~3,671,743,063,080,802,746,815,416,825,491,118,336,290,905,145,409,708,398,004 years
            // with a sustained request rate of 1 trillion requests per second to overflow the nonce counter
            return ++_nonce;
        }
    }

    function _sendReward(address to, bytes32 rewardAsset, uint256 rewardAmount) private {
        if (rewardAsset == _NATIVE_ASSET) {
            payable(to).sendValue(rewardAmount);
        } else {
            IERC20(rewardAsset.bytes32ToAddress()).safeTransfer(to, rewardAmount);
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

    function _isOptionalAttribute(bytes4 selector) internal pure virtual returns (bool) {
        return selector == _PRECHECK_ATTRIBUTE_SELECTOR || selector == _L2_ORACLE_ATTRIBUTE_SELECTOR
            || selector == _USER_OP_ATTRIBUTE_SELECTOR;
    }

    function _getInboxAndReward(bytes[] calldata attributes) private pure returns (address, bytes32, uint256) {
        bytes32 inbox;
        bytes32 rewardAsset;
        uint256 rewardAmount;

        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) == _INBOX_ATTRIBUTE_SELECTOR) {
                inbox = abi.decode(attributes[i][4:], (bytes32));
            } else if (bytes4(attributes[i]) == _REWARD_ATTRIBUTE_SELECTOR) {
                (rewardAsset, rewardAmount) = abi.decode(attributes[i][4:], (bytes32, uint256));
            }
        }

        return (inbox.bytes32ToAddress(), rewardAsset, rewardAmount);
    }

    function _getRequesterAndExpiryAndReward(bytes[] calldata attributes)
        private
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
}
