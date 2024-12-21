// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.2.0-rc.0) (utils/CAIP10.sol)

pragma solidity ^0.8.24;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {StringsHelper} from "./StringsHelper.sol";

/**
 * @notice Cloned from OpenZeppelin's CAIP10 library with slight modifications for now while it's in a draft state
 *
 * @dev Helper library to format and parse CAIP-10 identifiers
 *
 * https://github.com/ChainAgnostic/CAIPs/blob/main/CAIPs/caip-10.md[CAIP-10] defines account identifiers as:
 * account_id:        chain_id + ":" + account_address
 * chain_id:          [-a-z0-9]{3,8}:[-_a-zA-Z0-9]{1,32} (See {CAIP2})
 * account_address:   [-.%a-zA-Z0-9]{1,128}
 *
 * WARNING: According to [CAIP-10's canonicalization section](https://github.com/ChainAgnostic/CAIPs/blob/main/CAIPs/caip-10.md#canonicalization),
 * the implementation remains at the developer's discretion. Please note that case variations may introduce ambiguity.
 * For example, when building hashes to identify accounts or data associated to them, multiple representations of the
 * same account would derive to different hashes. For EVM chains, we recommend using checksummed addresses for the
 * "account_address" part. They can be generated onchain using {Strings-toChecksumHexString}.
 */
library CAIP10 {
    using Strings for uint256;
    using StringsHelper for address;

    /// @dev Return the CAIP-10 identifier for an account on the current (local) chain.
    function local(address account) internal view returns (string memory) {
        return format(localCaip2(), account.toChecksumHexString());
    }

    function localCaip2() internal view returns (string memory) {
        return formatCaip2(block.chainid);
    }

    function remote(address account, uint256 chainId) internal pure returns (string memory) {
        return format(formatCaip2(chainId), account.toChecksumHexString());
    }

    function formatCaip2(uint256 chainId) internal pure returns (string memory) {
        return format("eip155", chainId.toString());
    }

    function extractChainId(string memory caip2) internal pure returns (uint256) {
        bytes memory buffer = bytes(caip2);
        uint256 pos = _lastIndexOf(buffer, ":");
        bytes memory slice = _slice(buffer, pos + 1, buffer.length);
        return _bytesToUint(slice);
    }

    /**
     * @dev Return the CAIP-10 identifier for a given caip2 chain and account.
     *
     * NOTE: This function does not verify that the inputs are properly formatted.
     */
    function format(string memory caip2, string memory account) internal pure returns (string memory) {
        return string.concat(caip2, ":", account);
    }

    /**
     * @dev Parse a CAIP-10 identifier into its components.
     *
     * NOTE: This function does not verify that the CAIP-10 input is properly formatted. The `caip2` return can be
     * parsed using the {CAIP2} library.
     */
    function parse(string memory caip10) internal pure returns (string memory caip2, string memory account) {
        bytes memory buffer = bytes(caip10);

        uint256 pos = _lastIndexOf(buffer, ":");
        return (string(_slice(buffer, 0, pos)), string(_slice(buffer, pos + 1, buffer.length)));
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint256 i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(_hexCharToByte(strBytes[2 + i * 2]) * 16 + _hexCharToByte(strBytes[3 + i * 2]));
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function _lastIndexOf(bytes memory buffer, bytes1 value) private pure returns (uint256) {
        for (uint256 i = buffer.length - 1; i >= 0; i--) {
            if (buffer[i] == value) {
                return i;
            }
        }
        revert("Value not found");
    }

    function _slice(bytes memory buffer, uint256 start, uint256 end) private pure returns (bytes memory) {
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = buffer[i];
        }
        return result;
    }

    function _hexCharToByte(bytes1 char) private pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))) {
            return byteValue - uint8(bytes1("0"));
        } else if (byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    function _bytesToUint(bytes memory b) private pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);

            // '0' = 48 and '9' = 57 in ASCII
            if (c < 48 || c > 57) {
                revert("Non-numeric character found in string");
            }

            result = result * 10 + (c - 48);
        }
        return result;
    }
}
