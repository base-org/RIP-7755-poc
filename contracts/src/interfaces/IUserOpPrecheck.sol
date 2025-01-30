// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";

/// @title IUserOpPrecheck
///
/// @author Coinbase (https://github.com/base-org/7755-poc)
///
/// @notice A precheck interface for ERC-4337 User Operations
interface IUserOpPrecheck {
    function precheckUserOp(PackedUserOperation calldata userOp, address fulfiller) external view;
}
