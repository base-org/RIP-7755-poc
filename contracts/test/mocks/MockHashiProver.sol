// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RRC7755OutboxToHashi} from "../../src/outboxes/RRC7755OutboxToHashi.sol";

contract MockHashiProver is RRC7755OutboxToHashi {
    function validateProof(bytes memory storageKey, address inbox, bytes[] calldata attributes, bytes calldata proof)
        external
        view
    {
        _validateProof(storageKey, inbox, attributes, proof);
    }

    function isOptionalAttribute(bytes4 selector) external pure returns (bool) {
        return _isOptionalAttribute(selector);
    }

    // Including to block from coverage report
    function test() external {}
}
