// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755OutboxToHashi} from "../../src/outboxes/RIP7755OutboxToHashi.sol";

contract MockHashiProver is RIP7755OutboxToHashi {
    function validateProof(
        bytes memory storageKey,
        string calldata receiver,
        bytes[] calldata attributes,
        bytes calldata proof
    ) external view {
        _validateProof(storageKey, receiver, attributes, proof);
    }
}
