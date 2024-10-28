// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

///
/// @title IShoyuBashi
///
/// @author Crosschain Alliance
///
interface IShoyuBashi {
    ///@dev Returns the hash agreed upon by a threshold of the enabled adapters.
    ///@param domain - Uint256 identifier for the domain to query.
    ///@param id - Uint256 identifier to query.
    ///@return Bytes32 hash agreed upon by a threshold of the adapters for the given domain.
    ///@notice Reverts if the threshold is not reached.
    ///@notice Reverts if no adapters are set for the given domain.
    function getThresholdHash(uint256 domain, uint256 id) external view returns (bytes32);
}
