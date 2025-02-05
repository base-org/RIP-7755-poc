// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IPrecheckContract} from "../../src/interfaces/IPrecheckContract.sol";

contract MockPrecheck is IPrecheckContract {
    function precheckCall(bytes32, bytes32, bytes calldata, bytes[] calldata, address caller) external view {
        if (caller != tx.origin) {
            revert();
        }
    }

    // Including to block from coverage report
    function test() external {}
}
