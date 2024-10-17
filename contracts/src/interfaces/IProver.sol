// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {CrossChainRequest} from "../RIP7755Structs.sol";

interface IProver {
    function isValidProof(
        bytes32 verifyingContractStorageKey,
        RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata request,
        bytes calldata storageProofData
    ) external view returns (bool);
}
