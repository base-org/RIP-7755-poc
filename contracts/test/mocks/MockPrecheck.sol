// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IPrecheckContract} from "../../src/interfaces/IPrecheckContract.sol";
import {ERC7786Base} from "../../src/ERC7786Base.sol";

contract MockPrecheck is ERC7786Base, IPrecheckContract {
    function precheckCall(
        string calldata, // [CAIP-2] chain identifier
        string calldata, // [CAIP-10] account address
        Message[] calldata,
        bytes[] calldata attributes,
        address caller
    ) external pure {
        bytes calldata fulfillerAttribute = _locateAttribute(attributes, _FULFILLER_ATTRIBUTE_SELECTOR);
        address expectedCaller = abi.decode(fulfillerAttribute[4:], (address));

        if (expectedCaller != caller) {
            revert();
        }
    }

    // Including to block from coverage report
    function test() external {}
}
