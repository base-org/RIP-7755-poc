// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";
import {MerkleTrie} from "optimism/packages/contracts-bedrock/src/libraries/trie/MerkleTrie.sol";
import {SecureMerkleTrie} from "optimism/packages/contracts-bedrock/src/libraries/trie/SecureMerkleTrie.sol";

import {SSZ} from "./SSZ.sol";

library StateValidator {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    address private constant BEACON_ROOTS_ORACLE = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;
    uint256 private constant STATE_ROOT_GINDEX = 6434;

    struct StateProofParameters {
        bytes32 beaconRoot;
        uint256 beaconOracleTimestamp;
        bytes32 executionStateRoot;
        bytes32[] stateRootProof;
    }

    struct AccountProofParameters {
        bytes storageKey;
        bytes storageValue;
        bytes[] accountProof;
        bytes[] storageProof;
    }

    error BeaconRootDoesNotMatch(bytes32 expected, bytes32 actual);
    error BeaconRootsOracleCallFailed(bytes callData);
    error ExecutionStateRootMerkleProofFailed();
    error AccountProofVerificationFailed();

    function validateState(
        address account,
        StateProofParameters memory stateProofParams,
        AccountProofParameters memory accountProofParams
    ) internal view returns (bool) {
        // 1. Confirm beacon root
        // Getting L1 Beacon Root that is stored on L2 in `BEACON_ROOTS_ORACLE`
        _checkValidBeaconRoot(stateProofParams.beaconRoot, stateProofParams.beaconOracleTimestamp);
        // 2. Validate L1 state root
        // Prove the state root of the execution client based on a valid beacon root
        _checkValidStateRoot(
            stateProofParams.beaconRoot, stateProofParams.executionStateRoot, stateProofParams.stateRootProof
        );

        return validateAccountStorage(account, stateProofParams.executionStateRoot, accountProofParams);
    }

    function validateAccountStorage(
        address account,
        bytes32 stateRoot,
        AccountProofParameters memory accountProofParams
    ) internal pure returns (bool) {
        // 3. Validate L1 account proof where `account` here is the destination chain's inbox contract
        bytes memory accountKey = abi.encodePacked(keccak256(abi.encodePacked(account)));
        bytes memory encodedAccount = _verifyAccountProof(accountKey, accountProofParams.accountProof, stateRoot);

        // Extract storage root from account data
        bytes32 storageRoot = _extractStorageRoot(encodedAccount);

        // 4. Validate storage proof proving destination L2 root stored in L1 inbox contract
        return _verifyStorageProof({
            storageKey: accountProofParams.storageKey,
            expectedStorageValue: accountProofParams.storageValue,
            storageRoot: storageRoot,
            storageProof: accountProofParams.storageProof
        });
    }

    function _checkValidBeaconRoot(bytes32 root, uint256 timestamp) private view {
        (bool success, bytes memory result) = BEACON_ROOTS_ORACLE.staticcall(abi.encode(timestamp));

        if (!success) {
            revert BeaconRootsOracleCallFailed(abi.encode(timestamp));
        }

        bytes32 resultRoot = abi.decode(result, (bytes32));

        if (resultRoot != root) {
            revert BeaconRootDoesNotMatch({expected: root, actual: resultRoot});
        }
    }

    function _checkValidStateRoot(bytes32 beaconRoot, bytes32 executionStateRoot, bytes32[] memory proof)
        private
        view
    {
        if (!SSZ.verifyProof({proof: proof, root: beaconRoot, leaf: executionStateRoot, index: STATE_ROOT_GINDEX})) {
            revert ExecutionStateRootMerkleProofFailed();
        }
    }

    function _verifyAccountProof(bytes memory accountKey, bytes[] memory accountProof, bytes32 stateRoot)
        private
        pure
        returns (bytes memory)
    {
        bytes memory encodedAccount = MerkleTrie.get(accountKey, accountProof, stateRoot);
        if (encodedAccount.length == 0) {
            revert AccountProofVerificationFailed();
        }
        return encodedAccount;
    }

    function _extractStorageRoot(bytes memory encodedAccount) private pure returns (bytes32) {
        RLPReader.RLPItem[] memory accountFields = encodedAccount.readList();
        require(accountFields.length == 4, "Invalid account RLP");
        return bytes32(RLPReader.readBytes(accountFields[2])); // storage root is the third field
    }

    function _verifyStorageProof(
        bytes memory storageKey,
        bytes memory expectedStorageValue,
        bytes32 storageRoot,
        bytes[] memory storageProof
    ) private pure returns (bool) {
        bytes memory rlpValue = SecureMerkleTrie.get({_key: storageKey, _proof: storageProof, _root: storageRoot});
        bytes memory value = RLPReader.readBytes(rlpValue);
        return keccak256(value) == keccak256(expectedStorageValue);
    }
}
