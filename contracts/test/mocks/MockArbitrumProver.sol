// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755OutboxToArbitrum} from "../../src/outboxes/RIP7755OutboxToArbitrum.sol";

contract MockArbitrumProver is RIP7755OutboxToArbitrum {
    function validateProof(bytes memory storageKey, address inbox, bytes[] calldata attributes, bytes calldata proof)
        external
        view
    {
        _validateProof(storageKey, inbox, attributes, proof);
    }
}
