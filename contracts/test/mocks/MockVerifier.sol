// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract MockVerifier {
    struct MainStorage {
        /// @notice A mapping from the keccak256 hash of a `CrossChainRequest` to its `FulfillmentInfo`. This can only be set once per call
        mapping(bytes32 => FulfillmentInfo) fulfillmentInfo;
    }

    /// @notice Stored on verifyingContract and proved against in originationContract
    struct FulfillmentInfo {
        /// @dev Block timestamp when fulfilled
        uint96 timestamp;
        /// @dev Msg.sender of fulfillment call
        address fulfiller;
    }

    // Main storage location used as the base for the fulfillmentInfo mapping following EIP-7201.
    // keccak256(abi.encode(uint256(keccak256(bytes("RRC-7755"))) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _MAIN_STORAGE_LOCATION = 0x40f2eef6aad3cb0e74d3b59b45d3d5f2d5fc8dc382e739617b693cdd4bc30c00;

    function storeFulfillmentInfo(bytes32 requestHash, address fulfiller) external {
        _setFulfillmentInfo(requestHash, FulfillmentInfo({timestamp: uint96(block.timestamp), filler: fulfiller}));
    }

    function getFulfillmentInfo(bytes32 requestHash) external view returns (FulfillmentInfo memory) {
        return _getFulfillmentInfo(requestHash);
    }

    // Including to block from coverage report
    function test() external {}

    function _getMainStorage() private pure returns (MainStorage storage $) {
        assembly {
            $.slot := _MAIN_STORAGE_LOCATION
        }
    }

    function _getFulfillmentInfo(bytes32 requestHash) private view returns (FulfillmentInfo memory) {
        MainStorage storage $ = _getMainStorage();
        return $.fulfillmentInfo[requestHash];
    }

    function _setFulfillmentInfo(bytes32 requestHash, FulfillmentInfo memory fulfillmentInfo) private {
        MainStorage storage $ = _getMainStorage();
        $.fulfillmentInfo[requestHash] = fulfillmentInfo;
    }
}
