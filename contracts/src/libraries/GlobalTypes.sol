// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title GlobalTypes
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This library contains utility functions for converting addresses to bytes32 and vice versa.
library GlobalTypes {
    /// @notice Converts an address to a bytes32
    ///
    /// @param addr The address to convert
    ///
    /// @return bytes32Addr The bytes32 representation of the address
    function addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /// @notice Converts a bytes32 to an address
    ///
    /// @param bytes32Addr The bytes32 to convert
    ///
    /// @return addr The address representation of the bytes32
    function bytes32ToAddress(bytes32 bytes32Addr) internal pure returns (address) {
        return address(uint160(uint256(bytes32Addr)));
    }
}
