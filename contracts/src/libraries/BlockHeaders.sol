// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";

/// @title BlockHeaders
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This library contains utility functions for interacting with RLP-encoded block headers
library BlockHeaders {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @notice The minimum block fields length
    uint256 private constant MINIMUM_BLOCK_FIELDS_LENGTH = 12;

    /// @notice This error is thrown when the number of bytes to convert into an uin256 is greather than 32
    error BytesLengthExceeds32();

    /// @notice This error is thrown when the encoded block headers does not contain all 16 fields
    error InvalidBlockFieldRLP();

    /// @notice Converts an RLP-encoded block header into a block hash
    /// @param blockHeaders The RLP-encoded block headers
    /// @return The block hash
    function toBlockHash(bytes memory blockHeaders) internal pure returns (bytes32) {
        return keccak256(blockHeaders);
    }

    /// @notice Extracts the stateRoot, blockNumber and timestamp from the RLP-encoded block headers array
    ///
    /// @custom:reverts If the encoded block array has less than 9 elements
    ///
    /// @dev The stateRoot should be the 4th element, the blockNumber the 9th and the timestamp should be the 12th element
    function extractStateRootBlockNumberAndTimestamp(bytes memory blockHeaders)
        internal
        pure
        returns (bytes32, uint256, uint256)
    {
        RLPReader.RLPItem[] memory blockFields = blockHeaders.readList();
        if (blockFields.length < MINIMUM_BLOCK_FIELDS_LENGTH) {
            revert InvalidBlockFieldRLP();
        }

        return (
            bytes32(blockFields[3].readBytes()),
            _bytesToUint256(blockFields[8].readBytes()),
            uint256(bytes32(blockFields[11].readBytes()))
        );
    }

    /// @notice Extracts the state root and timestamp from an RLP-encoded block header
    /// @param blockHeaders The RLP-encoded block headers
    /// @return The state root and timestamp
    function extractStateRootAndTimestamp(bytes memory blockHeaders) internal pure returns (bytes32, uint256) {
        RLPReader.RLPItem[] memory blockFields = blockHeaders.readList();

        if (blockFields.length < MINIMUM_BLOCK_FIELDS_LENGTH) {
            revert InvalidBlockFieldRLP();
        }

        return (bytes32(blockFields[3].readBytes()), _bytesToUint256(blockFields[11].readBytes()));
    }

    /// @notice Converts a sequence of bytes into an uint256
    /// @param b The bytes to convert
    /// @return The uint256
    function _bytesToUint256(bytes memory b) private pure returns (uint256) {
        if (b.length > 32) revert BytesLengthExceeds32();
        return abi.decode(abi.encodePacked(new bytes(32 - b.length), b), (uint256));
    }
}
