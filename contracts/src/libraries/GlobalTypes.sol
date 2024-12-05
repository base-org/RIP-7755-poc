// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

library GlobalTypes {
    function addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function bytes32ToAddress(bytes32 bytes32Addr) internal pure returns (address) {
        return address(uint160(uint256(bytes32Addr)));
    }
}
