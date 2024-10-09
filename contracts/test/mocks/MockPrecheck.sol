// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IPrecheckContract} from "../../src/IPrecheckContract.sol";
import {CrossChainCall} from "../../src/RIP7755Structs.sol";

contract MockPrecheck is IPrecheckContract {
    function precheckCall(CrossChainCall calldata request, address caller) external pure {
        address _expectedCaller = abi.decode(request.precheckData, (address));

        if (_expectedCaller != caller) {
            revert();
        }
    }
}
