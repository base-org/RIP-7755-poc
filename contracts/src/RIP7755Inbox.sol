// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {CAIP10} from "openzeppelin-contracts/contracts/utils/CAIP10.sol";
import {CAIP2} from "openzeppelin-contracts/contracts/utils/CAIP2.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {IPrecheckContract} from "./interfaces/IPrecheckContract.sol";
import {ERC7786Base} from "./ERC7786Base.sol";
import {Paymaster} from "./Paymaster.sol";

/// @title RIP7755Inbox
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice An inbox contract within RIP-7755. This contract's sole purpose is to route requested transactions on
///         destination chains and store record of their fulfillment.
contract RIP7755Inbox is ERC7786Base, Paymaster {
    using Strings for string;

    struct MainStorage {
        /// @notice A mapping from the keccak256 hash of a `CrossChainRequest` to its `FulfillmentInfo`. This can only
        ///         be set once per call
        mapping(bytes32 requestHash => FulfillmentInfo) fulfillmentInfo;
    }

    /// @notice Stored on verifyingContract and proved against in originationContract
    struct FulfillmentInfo {
        /// @dev Block timestamp when fulfilled
        uint96 timestamp;
        /// @dev Msg.sender of fulfillment call
        address fulfiller;
    }

    /// @notice A message structure used for internal processing
    struct InternalMessage {
        /// @dev The fulfiller address allowed to claim on source chain
        address fulfiller;
        /// @dev Boolean value specifying if the request represents an ERC-4337 UserOp
        bool isUserOp;
        /// @dev Address of the specified precheck contract. This is optional.
        address precheckContract;
    }

    /// @notice Main storage location used as the base for the fulfillmentInfo mapping following EIP-7201. Derived from
    ///         the equation keccak256(abi.encode(uint256(keccak256(bytes("RIP-7755"))) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _MAIN_STORAGE_LOCATION = 0xfd1017d80ffe8da8a74488ee7408c9efa1877e094afa95857de95797c1228500;

    /// @notice Event emitted when a cross chain call is fulfilled
    ///
    /// @param requestHash The keccak256 hash of a `CrossChainRequest`
    /// @param fulfilledBy The account that fulfilled the cross chain call
    event CallFulfilled(bytes32 indexed requestHash, address indexed fulfilledBy);

    /// @notice This error is thrown when an account attempts to submit a cross chain call that has already been
    ///         fulfilled
    error CallAlreadyFulfilled();

    /// @notice This error is thrown if a fulfiller submits a `msg.value` greater than the total value needed for all
    ///         the calls
    ///
    /// @param expected The total value needed for all the calls
    /// @param actual   The received `msg.value`
    error InvalidValue(uint256 expected, uint256 actual);

    /// @notice This error is thrown when an invalid caller is detected
    error InvalidCaller();

    /// @notice This error is thrown when a User Operation is detected during an `executeMessages` call
    error UserOp();

    /// @dev Stores the address of the ERC-4337 EntryPoint contract
    ///
    /// @param entryPoint The address of the ERC-4337 EntryPoint contract
    constructor(address entryPoint) Paymaster(entryPoint) {}

    /// @notice Delivery of a message sent from another chain.
    ///
    /// @param sourceChain      The CAIP-2 source chain identifier
    /// @param sender           The CAIP-10 account address of the sender
    /// @param messages         The messages to be included in the request
    /// @param globalAttributes The attributes to be included in the message
    ///
    /// @return selector The selector of the function
    function executeMessages(
        string calldata sourceChain,
        string calldata sender,
        Message[] calldata messages,
        bytes[] calldata globalAttributes
    ) external payable returns (bytes4) {
        InternalMessage memory m = _processAttributes(globalAttributes);

        if (m.fulfiller == address(0)) {
            revert AttributeNotFound(_FULFILLER_ATTRIBUTE_SELECTOR);
        }

        if (m.isUserOp) {
            revert UserOp();
        }

        bytes32 messageId = getRequestId(sourceChain, sender, messages, globalAttributes);

        _runPrecheck(sourceChain, sender, messages, globalAttributes, m.precheckContract);

        if (_getFulfillmentInfo(messageId).timestamp != 0) {
            revert CallAlreadyFulfilled();
        }

        _setFulfillmentInfo(messageId, m.fulfiller);

        _sendCallsAndValidateMsgValue(messages);

        emit CallFulfilled({requestHash: messageId, fulfilledBy: m.fulfiller});

        return 0x675b049b; // this function's sig
    }

    /// @notice Returns the stored fulfillment info for a passed in call hash
    ///
    /// @param requestHash A keccak256 hash of a CrossChainRequest
    ///
    /// @return _ Fulfillment info stored for the call hash
    function getFulfillmentInfo(bytes32 requestHash) external view returns (FulfillmentInfo memory) {
        return _getFulfillmentInfo(requestHash);
    }

    /// @notice Returns the keccak256 hash of a message request
    ///
    /// @dev Filters out the fulfiller attribute from the attributes array
    ///
    /// @param sourceChain The CAIP-2 source chain identifier
    /// @param sender      The CAIP-10 account address of the sender
    /// @param messages    The messages to be included in the request
    /// @param attributes  The attributes to be included in the message
    ///
    /// @return _ The keccak256 hash of the message request
    function getRequestId(
        string calldata sourceChain,
        string calldata sender,
        Message[] calldata messages,
        bytes[] calldata attributes
    ) public view returns (bytes32) {
        string memory combinedSender = CAIP10.format(sourceChain, sender);
        string memory destinationChain = CAIP2.local();
        return keccak256(abi.encode(combinedSender, destinationChain, messages, _filterOutFulfiller(attributes)));
    }

    function _sendCallsAndValidateMsgValue(Message[] calldata messages) private {
        uint256 valueSent;

        for (uint256 i; i < messages.length; i++) {
            address to = messages[i].receiver.parseAddress();
            uint256 value = _locateAttributeValue(messages[i].attributes);
            _call(to, messages[i].payload, value);

            unchecked {
                valueSent += value;
            }
        }

        if (valueSent != msg.value) {
            revert InvalidValue(valueSent, msg.value);
        }
    }

    function _call(address to, bytes memory data, uint256 value) private {
        bytes memory result;
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            if iszero(call(gas(), to, value, add(data, 0x20), mload(data), codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
        }
    }

    function _setFulfillmentInfo(bytes32 requestHash, address fulfiller) internal override {
        FulfillmentInfo memory fulfillmentInfo =
            FulfillmentInfo({timestamp: uint96(block.timestamp), fulfiller: fulfiller});
        MainStorage storage $ = _getMainStorage();
        $.fulfillmentInfo[requestHash] = fulfillmentInfo;
    }

    function _runPrecheck(
        string calldata sourceChain, // [CAIP-2] chain identifier
        string calldata sender, // [CAIP-10] account address
        Message[] calldata messages,
        bytes[] calldata attributes,
        address precheck
    ) private view {
        if (precheck == address(0)) {
            return;
        }

        IPrecheckContract(precheck).precheckCall(sourceChain, sender, messages, attributes, msg.sender);
    }

    function _getFulfillmentInfo(bytes32 requestHash) private view returns (FulfillmentInfo memory) {
        MainStorage storage $ = _getMainStorage();
        return $.fulfillmentInfo[requestHash];
    }

    function _processAttributes(bytes[] calldata attributes) private pure returns (InternalMessage memory) {
        InternalMessage memory message;

        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) == _FULFILLER_ATTRIBUTE_SELECTOR) {
                message.fulfiller = abi.decode(attributes[i][4:], (address));
            } else if (bytes4(attributes[i]) == _USER_OP_ATTRIBUTE_SELECTOR) {
                message.isUserOp = abi.decode(attributes[i][4:], (bool));
            } else if (bytes4(attributes[i]) == _PRECHECK_ATTRIBUTE_SELECTOR) {
                message.precheckContract = abi.decode(attributes[i][4:], (address));
            }
        }

        return message;
    }

    function _filterOutFulfiller(bytes[] calldata attributes) private pure returns (bytes[] memory) {
        bytes[] memory filteredAttributes = new bytes[](attributes.length - 1);
        uint256 filteredIndex;
        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) != _FULFILLER_ATTRIBUTE_SELECTOR) {
                filteredAttributes[filteredIndex] = attributes[i];
                unchecked {
                    filteredIndex++;
                }
            }
        }
        return filteredAttributes;
    }

    function _getMainStorage() private pure returns (MainStorage storage $) {
        assembly {
            $.slot := _MAIN_STORAGE_LOCATION
        }
    }
}
