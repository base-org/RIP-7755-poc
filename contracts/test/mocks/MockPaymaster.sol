// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Paymaster} from "../../src/Paymaster.sol";

contract MockPaymaster is Paymaster {
    bytes32 public requestHash;
    address public fulfiller;

    constructor(address entryPoint) Paymaster(entryPoint) {}

    function _setFulfillmentInfo(bytes32 _requestHash, address _fulfiller) internal override {
        requestHash = _requestHash;
        fulfiller = _fulfiller;
    }
}
