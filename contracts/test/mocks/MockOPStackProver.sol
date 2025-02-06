// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RRC7755OutboxToOPStack} from "../../src/outboxes/RRC7755OutboxToOPStack.sol";

contract MockOPStackProver is RRC7755OutboxToOPStack {
    function validateProof(bytes memory storageKey, address inbox, bytes[] calldata attributes, bytes calldata proof)
        external
        view
    {
        _validateProof(storageKey, inbox, attributes, proof);
    }

    // Including to block from coverage report
    function test() external {}
}
