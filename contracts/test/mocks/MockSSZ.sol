// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {SSZ} from "../../src/libraries/SSZ.sol";

contract MockSSZ {
    function verifyProof(bytes32[] memory proof, bytes32 root, bytes32 leaf, uint256 index)
        external
        view
        returns (bool isValid)
    {
        return SSZ.verifyProof(proof, root, leaf, index);
    }
}
