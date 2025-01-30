// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PackedUserOperation} from "account-abstraction/core/EntryPoint.sol";

contract MockAccount {
    receive() external payable {}

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        pure
        returns (uint256 validationData)
    {
        return 0;
    }

    function executeUserOp(address paymaster) external {
        bytes4 selector = bytes4(keccak256("withdrawGasExcess()"));
        (bool success,) = paymaster.call(abi.encodeWithSelector(selector));
        require(success, "Failed to call withdrawGasExcess");
    }
}
