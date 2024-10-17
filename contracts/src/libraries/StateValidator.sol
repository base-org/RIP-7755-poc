// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";
import {MerkleTrie} from "optimism/packages/contracts-bedrock/src/libraries/trie/MerkleTrie.sol";
import {SecureMerkleTrie} from "optimism/packages/contracts-bedrock/src/libraries/trie/SecureMerkleTrie.sol";

import {SSZ} from "./SSZ.sol";

/// @title StateValidator
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice A library for validating EVM storage proofs.
library StateValidator {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @notice The Beacon Roots Oracle contract on L2. Ethereum's Beacon Chain publishes beacon roots here as explained
    /// by EIP-4788 (https://eips.ethereum.org/EIPS/eip-4788)
    address private constant BEACON_ROOTS_ORACLE = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;

    /// @notice g-index stands for Generalized Index - a way to define the position of a node in a merkle tree. This
    /// represents the position of the execution client's state root in the merkle tree producing the beacon root.
    uint256 private constant STATE_ROOT_GINDEX = 6434;

    /// @notice Parameters needed to validate the authenticity of Ethereum's execution client's state root
    struct StateProofParameters {
        /// @dev The Beacon Chain root published to `BEACON_ROOTS_ORACLE` on this L2 chain
        bytes32 beaconRoot;
        /// @dev The timestamp associated with the provided Beacon Root
        uint256 beaconOracleTimestamp;
        /// @dev The state root of Ethereum's execution client
        bytes32 executionStateRoot;
        /// @dev A proof to verify the authenticity of `executionStateRoot`
        bytes32[] stateRootProof;
    }

    /// @notice Parameters needed to validate the authenticity of an EVM account's storage
    struct AccountProofParameters {
        /// @dev The storage location to validate
        bytes storageKey;
        /// @dev The expected value at the specified storage location
        bytes storageValue;
        /// @dev A proof used to derive an account's storage root
        bytes[] accountProof;
        /// @dev A proof to validate the account's `storageValue` at `storageKey` location
        bytes[] storageProof;
    }

    /// @notice This error is thrown when the passed in beacon root does not match what is stored in
    /// `BEACON_ROOTS_ORACLE` for the associated timestamp
    /// @param expected The beacon root passed in by the fulfiller
    /// @param actual The stored beacon root in `BEACON_ROOTS_ORACLE`
    error BeaconRootDoesNotMatch(bytes32 expected, bytes32 actual);

    /// @notice This error is thrown when the `staticcall` to `BEACON_ROOTS_ORACLE` does not complete successfully
    /// @param callData The encoded timestamp that was passed in as the calldata in the staticcall to `BEACON_ROOTS_ORACLE`
    error BeaconRootsOracleCallFailed(bytes callData);

    /// @notice This error is thrown when validation of the execution client's state root fails
    error ExecutionStateRootMerkleProofFailed();

    /// @notice This error is thrown when the RLP-encoded account object returned from
    /// `AccountProofParameters.accountProof` is formatted incorrectly
    error InvalidAccountRLP();

    /// @notice Validates the state of an EVM account at a specified storage location
    ///
    /// @dev First confirms a valid Beacon root and a valid execution state root
    ///
    /// @param account An EVM account - in most cases, either an L2Oracle contract on Eth Mainnet or `RIP7755Inbox`
    /// on a destination L2
    /// @param stateProofParams Parameters needed to validate the authenticity of Ethereum's execution client's state root
    /// @param accountProofParams Parameters needed to validate the authenticity of an EVM account's storage
    ///
    /// @return _ True if proof validation succeeds, else false
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

    /// @notice Validates the state of an EVM account at a specified storage location
    ///
    /// @dev This is intended to ONLY be called if the authenticity of the beacon root and execution client state root
    /// has already been verified
    ///
    /// @param account An EVM account - in most cases, either an L2Oracle contract on Eth Mainnet or `RIP7755Inbox`
    /// on a destination L2
    /// @param stateRoot The state root of an EVM chain's execution client
    /// @param accountProofParams Parameters needed to validate the authenticity of an EVM account's storage
    ///
    /// @return _ True if proof validation succeeds, else false
    function validateAccountStorage(
        address account,
        bytes32 stateRoot,
        AccountProofParameters memory accountProofParams
    ) internal pure returns (bool) {
        // Derive the account key that shows up in the execution client's merkle trie
        bytes memory accountKey = abi.encodePacked(keccak256(abi.encodePacked(account)));
        // Use the account proof to derive the RLP-encoded account metadata
        bytes memory encodedAccount = MerkleTrie.get(accountKey, accountProofParams.accountProof, stateRoot);

        // Extract storage root from account data
        bytes32 storageRoot = _extractStorageRoot(encodedAccount);

        return _verifyStorageProof({
            storageKey: accountProofParams.storageKey,
            expectedStorageValue: accountProofParams.storageValue,
            storageRoot: storageRoot,
            storageProof: accountProofParams.storageProof
        });
    }

    /// @notice Confirms the received beacon root is valid and associated with the received beacon oracle timestamp
    ///
    /// @custom:reverts If the staticcall to `BEACON_ROOTS_ORACLE` fails
    /// @custom:reverts If the beacon root associated with `timestamp` in `BEACON_ROOTS_ORACLE` does not match the
    /// provided root
    ///
    /// @param root The Beacon Chain root posted in `BEACON_ROOTS_ORACLE` on this L2
    /// @param timestamp The timestamp associated with when the beacon root was posted
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

    /// @notice Confirms the authenticity of the passed in execution client state root
    ///
    /// @custom:reverts If the proof does not successfully verify the execution state root
    ///
    /// @param beaconRoot The Beacon Chain root posted in `BEACON_ROOTS_ORACLE` on this L2
    /// @param executionStateRoot The state root of Ethereum's execution client
    /// @param proof A proof to verify the authenticity of `executionStateRoot`
    function _checkValidStateRoot(bytes32 beaconRoot, bytes32 executionStateRoot, bytes32[] memory proof)
        private
        view
    {
        bool isValid =
            SSZ.verifyProof({proof: proof, root: beaconRoot, leaf: executionStateRoot, index: STATE_ROOT_GINDEX});

        if (!isValid) {
            revert ExecutionStateRootMerkleProofFailed();
        }
    }

    /// @notice Extracts the storage root from an RLP-encoded account object
    ///
    /// @custom:reverts If the encoded account doesn't parse into 4 `RLPReader.RLPItem`s
    ///
    /// @param encodedAccount An RLP-encoded account object
    ///
    /// @return _ The account's storage root
    function _extractStorageRoot(bytes memory encodedAccount) private pure returns (bytes32) {
        RLPReader.RLPItem[] memory accountFields = encodedAccount.readList();

        if (accountFields.length != 4) {
            revert InvalidAccountRLP();
        }

        return bytes32(accountFields[2].readBytes()); // storage root is the third field
    }

    /// @notice Verifies an account's storage value at a specified location
    ///
    /// @param storageKey The storage location to validate
    /// @param expectedStorageValue The expected value stored at `storageKey`
    /// @param storageRoot The storage root for the account's merkle trie
    /// @param storageProof The proof that validates the storage value
    ///
    /// @return _ True if proof validation succeeds, else false
    function _verifyStorageProof(
        bytes memory storageKey,
        bytes memory expectedStorageValue,
        bytes32 storageRoot,
        bytes[] memory storageProof
    ) private pure returns (bool) {
        bytes memory rlpValue = SecureMerkleTrie.get({_key: storageKey, _proof: storageProof, _root: storageRoot});
        bytes memory value = rlpValue.readBytes();
        return keccak256(value) == keccak256(expectedStorageValue);
    }
}
