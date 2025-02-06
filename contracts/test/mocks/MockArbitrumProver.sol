// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RRC7755OutboxToArbitrum} from "../../src/outboxes/RRC7755OutboxToArbitrum.sol";

contract MockArbitrumProver is RRC7755OutboxToArbitrum {
    function validateProof(bytes memory storageKey, address inbox, bytes[] calldata attributes, bytes calldata proof)
        external
        view
    {
        _validateProof(storageKey, inbox, attributes, proof);
    }

    // Including to block from coverage report
    function test() external {}
}
