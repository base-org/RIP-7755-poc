// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {BlockHeaders} from "../../src/libraries/BlockHeaders.sol";

contract MockBlockHeaders {
    function toBlockHash(bytes memory blockHeaders) external pure returns (bytes32) {
        return BlockHeaders.toBlockHash(blockHeaders);
    }

    function extractStateRootBlockNumberAndTimestamp(bytes memory blockHeaders)
        external
        pure
        returns (bytes32, uint256, uint256)
    {
        return BlockHeaders.extractStateRootBlockNumberAndTimestamp(blockHeaders);
    }

    function extractStateRoot(bytes memory blockHeaders) external pure returns (bytes32) {
        return BlockHeaders.extractStateRoot(blockHeaders);
    }
}
