// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IProver} from "../../src/interfaces/IProver.sol";
import {RIP7755Inbox} from "../../src/RIP7755Inbox.sol";
import {CrossChainRequest} from "../../src/RIP7755Structs.sol";

contract MockProver is IProver {
    function isValidProof(
        bytes32,
        RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata,
        bytes calldata
    ) external pure returns (bool) {
        return fulfillmentInfo.filler != address(0);
    }
}
