// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {CrossChainCall} from "./RIP7755Structs.sol";

interface IPrecheckContract {
    function precheckCall(CrossChainCall calldata crossChainCall, address caller) external;
}
