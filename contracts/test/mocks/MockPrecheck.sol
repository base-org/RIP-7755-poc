// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IPrecheckContract} from "../../src/interfaces/IPrecheckContract.sol";
import {CrossChainRequest} from "../../src/RIP7755Structs.sol";

contract MockPrecheck is IPrecheckContract {
    function precheckCall(CrossChainRequest calldata request, address caller) external pure {
        bytes calldata precheckData = request.extraData[0];
        address expectedCaller = address(bytes20(precheckData[20:]));

        if (expectedCaller != caller) {
            revert();
        }
    }

    // Including to block from coverage report
    function test() external {}
}
