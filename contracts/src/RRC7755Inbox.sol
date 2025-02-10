// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";

import {IPrecheckContract} from "./interfaces/IPrecheckContract.sol";
import {GlobalTypes} from "./libraries/GlobalTypes.sol";
import {RRC7755Base} from "./RRC7755Base.sol";
import {Paymaster} from "./Paymaster.sol";

/// @title RRC7755Inbox
///
/// @author Coinbase (https://github.com/base-org/RRC-7755-poc)
///
/// @notice An inbox contract within RRC-7755. This contract's sole purpose is to route requested transactions on
///         destination chains and store record of their fulfillment.
contract RRC7755Inbox is RRC7755Base, Paymaster {
    using GlobalTypes for bytes32;
    using GlobalTypes for address;

    struct MainStorage {
        /// @notice A mapping from the keccak256 hash of a 7755 request to its `FulfillmentInfo`. This can only be set
        ///         once per call
        mapping(bytes32 requestHash => FulfillmentInfo) fulfillmentInfo;
    }

    /// @notice Stored on verifyingContract and proved against in originationContract
    struct FulfillmentInfo {
        /// @dev Block timestamp when fulfilled
        uint96 timestamp;
        /// @dev Msg.sender of fulfillment call
        address fulfiller;
    }

    /// @notice Main storage location used as the base for the fulfillmentInfo mapping following EIP-7201.
    ///         keccak256(abi.encode(uint256(keccak256(bytes("RRC-7755"))) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _MAIN_STORAGE_LOCATION = 0x40f2eef6aad3cb0e74d3b59b45d3d5f2d5fc8dc382e739617b693cdd4bc30c00;

    /// @notice Event emitted when a cross chain call is fulfilled
    ///
    /// @param requestHash The keccak256 hash of a 7755 request
    /// @param fulfilledBy The account that fulfilled the cross chain call
    event CallFulfilled(bytes32 indexed requestHash, address indexed fulfilledBy);

    /// @notice This error is thrown when an account attempts to submit a cross chain call that has already been
    ///         fulfilled
    error CallAlreadyFulfilled();

    /// @notice This error is thrown when a User Operation is detected during an `executeMessages` call
    error UserOp();

    /// @dev Stores the address of the ERC-4337 EntryPoint contract
    ///
    /// @param entryPoint The address of the ERC-4337 EntryPoint contract
    constructor(address entryPoint) Paymaster(entryPoint) {}

    /// @notice Delivery of a message sent from another chain.
    ///
    /// @param sourceChain The source chain identifier
    /// @param sender      The account address of the sender
    /// @param payload     The encoded calls to be included in the request
    /// @param attributes  The attributes to be included in the message
    /// @param fulfiller   The account address of the fulfiller
    function fulfill(
        bytes32 sourceChain,
        bytes32 sender,
        bytes calldata payload,
        bytes[] calldata attributes,
        address fulfiller
    ) external payable {
        (bool isUserOp, address precheckContract) = _processAttributes(attributes);

        if (isUserOp) {
            revert UserOp();
        }

        bytes32 messageId = getRequestId(
            sourceChain, sender, bytes32(block.chainid), address(this).addressToBytes32(), payload, attributes
        );

        _runPrecheck(sourceChain, sender, payload, attributes, precheckContract);

        if (_getFulfillmentInfo(messageId).timestamp != 0) {
            revert CallAlreadyFulfilled();
        }

        _setFulfillmentInfo(messageId, fulfiller);

        _sendCallsAndValidateMsgValue(payload);

        emit CallFulfilled({requestHash: messageId, fulfilledBy: fulfiller});
    }

    /// @notice Returns the stored fulfillment info for a passed in call hash
    ///
    /// @param requestHash A keccak256 hash of a 7755 request
    ///
    /// @return _ Fulfillment info stored for the call hash
    function getFulfillmentInfo(bytes32 requestHash) external view returns (FulfillmentInfo memory) {
        return _getFulfillmentInfo(requestHash);
    }

    function _sendCallsAndValidateMsgValue(bytes calldata payload) private {
        Call[] memory calls = abi.decode(payload, (Call[]));
        uint256 valueSent;

        for (uint256 i; i < calls.length; i++) {
            address to = calls[i].to.bytes32ToAddress();
            _call(to, calls[i].data, calls[i].value);

            unchecked {
                valueSent += calls[i].value;
            }
        }

        if (valueSent != msg.value) {
            revert InvalidValue(valueSent, msg.value);
        }
    }

    function _call(address to, bytes memory data, uint256 value) private {
        (bool success, bytes memory result) = to.call{value: value}(data);
        if (!success) {
            assembly ("memory-safe") {
                revert(add(result, 32), mload(result))
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
        bytes32 sourceChain,
        bytes32 sender,
        bytes calldata payload,
        bytes[] calldata attributes,
        address precheck
    ) private view {
        if (precheck == address(0)) {
            return;
        }

        IPrecheckContract(precheck).precheckCall(sourceChain, sender, payload, attributes, msg.sender);
    }

    function _getFulfillmentInfo(bytes32 requestHash) private view returns (FulfillmentInfo memory) {
        MainStorage storage $ = _getMainStorage();
        return $.fulfillmentInfo[requestHash];
    }

    function _processAttributes(bytes[] calldata attributes) private pure returns (bool, address) {
        bool isUserOp = attributes.length == 0;
        bytes32 precheckContract;

        for (uint256 i; i < attributes.length; i++) {
            if (bytes4(attributes[i]) == _PRECHECK_ATTRIBUTE_SELECTOR) {
                precheckContract = abi.decode(attributes[i][4:], (bytes32));
            }
        }

        return (isUserOp, precheckContract.bytes32ToAddress());
    }

    function _getMainStorage() private pure returns (MainStorage storage $) {
        assembly {
            $.slot := _MAIN_STORAGE_LOCATION
        }
    }
}
