// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755Outbox} from "../../src/RIP7755Outbox.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest} from "../../src/RIP7755Structs.sol";

contract MockOutbox is RIP7755Outbox {
    function _validateProof(
        bytes memory inboxContractStorageKey,
        CrossChainRequest calldata request,
        bytes calldata proofData
    ) internal {}

    function _validateProof2(
        bytes memory inboxContractStorageKey,
        bytes[] calldata attributes,
        bytes calldata proofData
    ) internal view override {}
}
