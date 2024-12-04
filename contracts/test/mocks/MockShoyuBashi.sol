// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract MockShoyuBashi {
    mapping(uint256 => mapping(uint256 => bytes32)) private _hashes;

    function getThresholdHash(uint256 domain, uint256 id) external view returns (bytes32) {
        return _hashes[domain][id];
    }

    function setHash(uint256 domain, uint256 id, bytes32 hash) external {
        _hashes[domain][id] = hash;
    }
}
