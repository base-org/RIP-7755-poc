// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755Outbox} from "../../src/source/RIP7755Outbox.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest} from "../../src/RIP7755Structs.sol";

contract MockOutbox is RIP7755Outbox {
    error InvalidProof();

    function _validate(
        bytes32,
        RIP7755Inbox.FulfillmentInfo calldata,
        CrossChainRequest calldata,
        bytes calldata storageProofData
    ) internal pure override {
        bool validProof = abi.decode(storageProofData, (bool));

        if (!validProof) {
            revert InvalidProof();
        }
    }
}
