// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IProver} from "../../src/interfaces/IProver.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest} from "../../src/RIP7755Structs.sol";

contract MockProver is IProver {
    function validateProof(
        bytes memory,
        RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata,
        bytes calldata
    ) external pure {}

    // Including to block from coverage report
    function test() external {}
}
