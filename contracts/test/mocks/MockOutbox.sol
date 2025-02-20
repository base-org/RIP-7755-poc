// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RRC7755Outbox} from "../../src/RRC7755Outbox.sol";

contract MockOutbox is RRC7755Outbox {
    function _minExpiryTime(uint256) internal pure override returns (uint256) {
        return 10;
    }

    function _validateProof(
        bytes memory inboxContractStorageKey,
        address inbox,
        bytes[] calldata attributes,
        bytes calldata proofData
    ) internal view override {}

    // Including to block from coverage report
    function test() external {}
}
