// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755Source} from "../../src/RIP7755Source.sol";
import {RIP7755Verifier} from "../../src/RIP7755Verifier.sol";

contract MockSource is RIP7755Source {
    function _validate(
        bytes32 verifyingContractStorageKey,
        RIP7755Verifier.FulfillmentInfo calldata fillInfo,
        CrossChainRequest calldata crossChainCall,
        bytes calldata storageProofData
    ) internal view override {}
}
