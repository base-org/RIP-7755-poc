// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";

import {IUserOpPrecheck} from "../../src/interfaces/IUserOpPrecheck.sol";

contract MockUserOpPrecheck is IUserOpPrecheck {
    function precheckUserOp(PackedUserOperation calldata userOp, address fulfiller) external pure {
        address expectedCaller = abi.decode(userOp.paymasterAndData[104:], (address));

        if (expectedCaller != fulfiller) {
            revert();
        }
    }

    // Including to block from coverage report
    function test() external {}
}
