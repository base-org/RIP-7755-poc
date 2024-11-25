// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755OutboxToArbitrum} from "../../src/outboxes/RIP7755OutboxToArbitrum.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest} from "../../src/RIP7755Structs.sol";

contract MockArbitrumProver is RIP7755OutboxToArbitrum {
    function validateProof(bytes memory storageKey, CrossChainRequest calldata request, bytes calldata proof)
        external
        view
    {
        _validateProof(storageKey, request, proof);
    }
}
