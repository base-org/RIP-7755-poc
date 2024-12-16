// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.2.0-rc.0) (utils/CAIP10.sol)

pragma solidity ^0.8.24;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {StringsHelper} from "./StringsHelper.sol";

/**
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
        string memory caip2 = format("eip155", block.chainid.toString());
        return format(caip2, account.toChecksumHexString());
    }

    /**
     * @dev Return the CAIP-10 identifier for a given caip2 chain and account.
     *
     * NOTE: This function does not verify that the inputs are properly formatted.
     */
    function format(string memory caip2, string memory account) internal pure returns (string memory) {
        return string.concat(caip2, ":", account);
    }
}
