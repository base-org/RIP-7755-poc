// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755Outbox} from "../../src/RIP7755Outbox.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest} from "../../src/RIP7755Structs.sol";

contract MockOutbox is RIP7755Outbox {
    function _validateProof(
        bytes memory inboxContractStorageKey,
        RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata request,
        bytes calldata proofData
    ) internal override {}
}
