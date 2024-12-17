// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755OutboxToOPStack} from "../../src/outboxes/RIP7755OutboxToOPStack.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest} from "../../src/RIP7755Structs.sol";

contract MockOPStackProver is RIP7755OutboxToOPStack {
    function validateProof2(
        bytes memory storageKey,
        address inboxContract,
        bytes[] calldata attributes,
        bytes calldata proof
    ) external view {
        _validateProof2(storageKey, inboxContract, attributes, proof);
    }
}
