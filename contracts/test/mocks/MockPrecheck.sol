// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IPrecheckContract} from "../../src/IPrecheckContract.sol";
import {CrossChainCall} from "../../src/RIP7755Structs.sol";

contract MockPrecheck is IPrecheckContract {
    function precheckCall(CrossChainCall calldata request, address caller) external pure {
        address expectedCaller = abi.decode(request.precheckData, (address));

        if (expectedCaller != caller) {
            revert();
        }
    }
}
