// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {StateValidator} from "../../src/libraries/StateValidator.sol";

contract MockStateValidator {
    function validateState(
        address account,
        StateValidator.StateProofParameters memory stateProofParams,
        StateValidator.AccountProofParameters memory accountProofParams
    ) external view returns (bool) {
        return StateValidator.validateState(account, stateProofParams, accountProofParams);
    }

    function validateAccountStorage(
        address account,
        bytes32 stateRoot,
        StateValidator.AccountProofParameters memory accountProofParams
    ) external pure returns (bool) {
        return StateValidator.validateAccountStorage(account, stateRoot, accountProofParams);
    }

    function extractStorageRoot(bytes memory encodedAccount) external pure returns (bytes32) {
        return StateValidator._extractStorageRoot(encodedAccount);
    }

    // Including to block from coverage report
    function test() external {}
}
