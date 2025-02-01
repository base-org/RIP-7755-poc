// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755Outbox} from "../../src/RIP7755Outbox.sol";

contract MockOutbox is RIP7755Outbox {
    function _validateProof(
        bytes memory inboxContractStorageKey,
        address inbox,
        bytes[] calldata attributes,
        bytes calldata proofData
    ) internal view override {}

    // Including to block from coverage report
    function test() external {}
}
