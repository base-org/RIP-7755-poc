// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";

library BlockHeaders {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @notice This error is thrown when the number of bytes to convert into an uin256 is greather than 32
    error BytesLengthExceeds32();

    /// @notice This error is thrown when the encoded block headers does not contain all 16 fields
    error InvalidBlockFieldRLP();

    function toBlockHash(bytes memory blockHeaders) internal pure returns (bytes32) {
        return keccak256(blockHeaders);
    }

    function extractStateRootAndTimestamp(bytes memory blockHeaders) internal pure returns (bytes32, uint256) {
        RLPReader.RLPItem[] memory blockFields = blockHeaders.readList();

        if (blockFields.length < 15) {
            revert InvalidBlockFieldRLP();
        }

        return (bytes32(blockFields[3].readBytes()), _bytesToUint256(blockFields[11].readBytes()));
    }

    /// @notice Converts a sequence of bytes into an uint256
    function _bytesToUint256(bytes memory b) private pure returns (uint256) {
        if (b.length > 32) revert BytesLengthExceeds32();
        return abi.decode(abi.encodePacked(new bytes(32 - b.length), b), (uint256));
    }
}
