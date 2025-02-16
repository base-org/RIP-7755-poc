// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PackedUserOperation} from "account-abstraction/core/EntryPoint.sol";

contract MockAccount {
    receive() external payable {}

    function validateUserOp(PackedUserOperation calldata, bytes32, uint256)
        external
        pure
        returns (uint256 validationData)
    {
        return 0;
    }

    function executeUserOp(address paymaster, bytes32 token) external {
        bytes4 selector = bytes4(keccak256("withdrawGasExcess(bytes32)"));
        (bool success,) = paymaster.call(abi.encodeWithSelector(selector, token));
        require(success, "Failed to call withdrawGasExcess");
    }

    // Including to block from coverage report
    function test() external {}
}
