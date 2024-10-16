// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755Source} from "../../src/source/RIP7755Source.sol";
import {CrossChainRequest} from "../../src/RIP7755Structs.sol";
import {RIP7755Verifier} from "../../src/RIP7755Verifier.sol";

contract MockSource is RIP7755Source {
    error InvalidProof();

    function _validate(
        bytes32,
        RIP7755Verifier.FulfillmentInfo calldata,
        CrossChainRequest calldata,
        bytes calldata storageProofData
    ) internal pure override {
        bool validProof = abi.decode(storageProofData, (bool));

        if (!validProof) {
            revert InvalidProof();
        }
    }
}
