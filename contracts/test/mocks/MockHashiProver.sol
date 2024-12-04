// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755OutboxToHashi} from "../../src/outboxes/RIP7755OutboxToHashi.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest} from "../../src/RIP7755Structs.sol";

contract MockHashiProver is RIP7755OutboxToHashi {
    function validateProof(bytes memory storageKey, CrossChainRequest calldata request, bytes calldata proof)
        external
        view
    {
        _validateProof(storageKey, request, proof);
    }
}
