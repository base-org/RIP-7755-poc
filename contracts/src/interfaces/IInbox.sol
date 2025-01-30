// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IInbox {
    function storeExecutionReceipt(bytes32 requestHash, address fulfiller) external;
}
