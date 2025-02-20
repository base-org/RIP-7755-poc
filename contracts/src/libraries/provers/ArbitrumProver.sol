// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BlockHeaders} from "../BlockHeaders.sol";
import {StateValidator} from "../StateValidator.sol";

/// @title ArbitrumProver
///
/// @author Coinbase (https://github.com/base/RRC-7755-poc)
///
/// @notice This is a utility library for validating Arbitrum storage proofs.
library ArbitrumProver {
    using StateValidator for address;
    using BlockHeaders for bytes;

    /// @notice The status of the sequencer machine
    enum MachineStatus {
        RUNNING,
        FINISHED,
        ERRORED
    }

    /// @notice The global state of arbitrum when the AssertionNode was created
    struct GlobalState {
        /// @dev An array containing the blockhash of the L2 block and the sendRoot
        bytes32[2] bytes32Vals;
        /// @dev An array containing the inbox position and the position in message of the assertion
        uint64[2] u64Vals;
    }

    /// @notice The state of the assertion node
    struct AssertionState {
        /// @dev The global state of arbitrum when the AssertionNode was created
        GlobalState globalState;
        /// @dev The status of the sequencer machine
        MachineStatus machineStatus;
        /// @dev The end history root of the sequencer machine
        bytes32 endHistoryRoot;
    }

    /// @notice The status of the assertion
    enum AssertionStatus {
        NoAssertion,
        Pending,
        Confirmed
    }

    /// @notice The address and storage keys to validate on L1 and L2
    struct Target {
        /// @dev The address of the L1 contract to validate. Should be Arbitrum's Rollup contract
        address l1Address;
        /// @dev The address of the L2 contract to validate.
        address l2Address;
        /// @dev The storage key on L2 to validate.
        bytes l2StorageKey;
    }

    /// @notice Parameters needed for a full nested cross-L2 storage proof with Arbitrum as the destination chain
    struct RRC7755Proof {
        /// @dev The RLP-encoded array of block headers of Arbitrum's L2 block corresponding to the above RBlock.
        ///      Hashing this bytes string should produce the blockhash.
        bytes encodedBlockArray;
        /// @dev The state of the assertion node after the sequencer machine has finished
        AssertionState afterState;
        /// @dev The hash of the previous assertion
        bytes32 prevAssertionHash;
        /// @dev The inbox accumulator of the sequencer batch
        bytes32 sequencerBatchAcc;
        /// @dev Parameters needed to validate the authenticity of Ethereum's execution client's state root
        StateValidator.StateProofParameters stateProofParams;
        /// @dev Parameters needed to validate the authenticity of the l2Oracle for the destination L2 chain on Eth
        ///      mainnet
        StateValidator.AccountProofParameters dstL2StateRootProofParams;
        /// @dev Parameters needed to validate the authenticity of a specified storage location on the destination L2
        ///      chain
        StateValidator.AccountProofParameters dstL2AccountProofParams;
    }

    /// @notice The storage key on L1 to validate
    bytes32 private constant _L1_STORAGE_KEY = 0x0000000000000000000000000000000000000000000000000000000000000075;

    /// @notice mask of highest 56 bits of a uint256
    uint256 private constant _MASK = type(uint256).max << 200;

    /// @notice This error is thrown when verification of the authenticity of the l2Oracle for the destination L2 chain
    ///         on Eth mainnet fails
    error InvalidStateRoot();

    /// @notice This error is thrown when verification of the authenticity of the storage slot on the destination L2
    ///         chain fails
    error InvalidL2Storage();

    /// @notice This error is thrown when the hashed block headers do not match Arbitrum's verified block hash
    error InvalidBlockHeaders();

    /// @notice This error is thrown when the assertion node is not confirmed
    error NodeNotConfirmed();

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If the L2 state root does not correspond to our validated L1 storage slot
    ///
    /// @param proof  The proof to validate
    /// @param target The proof target on L1 and dst L2
    function validate(bytes calldata proof, Target memory target) internal view {
        RRC7755Proof memory data = abi.decode(proof, (RRC7755Proof));

        // Set the expected storage key and value for the destination L2 storage slot
        data.dstL2AccountProofParams.storageKey = target.l2StorageKey;

        // Derive the new assertion hash which is the mapping key in the Rollup contract's storage for the assertion node
        bytes32 newAssertionHash = _assertionHash(data.prevAssertionHash, data.afterState, data.sequencerBatchAcc);

        // Derive the L1 storage key to use in the storage proof. For Arbitrum, we will use the storage slot containing
        // the assertion node
        data.dstL2StateRootProofParams.storageKey = _deriveL1StorageKey(newAssertionHash);

        // We first need to validate knowledge of the destination L2 chain's state root.
        // StateValidator.validateState will accomplish each of the following 4 steps:
        //      1. Confirm beacon root
        //      2. Validate L1 state root
        //      3. Validate L1 account proof where `account` here is Arbitrum's Rollup contract
        //      4. Validate storage proof proving destination L2 root stored in Rollup contract
        if (!target.l1Address.validateState(data.stateProofParams, data.dstL2StateRootProofParams)) {
            revert InvalidStateRoot();
        }

        // Extract the confirmation status of the assertion node
        AssertionStatus conf = _extractConfirmation(bytes32(_format(data.dstL2StateRootProofParams.storageValue)));

        if (conf != AssertionStatus.Confirmed) {
            revert NodeNotConfirmed();
        }

        // As an intermediate step, we need to prove that `data.dstL2StateRootProofParams.storageValue` is linked to
        // the correct l2StateRoot before we can prove l2Storage

        // Derive the L2 blockhash
        bytes32 l2BlockHash = data.afterState.globalState.bytes32Vals[0];

        if (l2BlockHash != data.encodedBlockArray.toBlockHash()) {
            revert InvalidBlockHeaders();
        }

        // Extract the L2 stateRoot and timestamp from the RLP-encoded block array
        bytes32 l2StateRoot = data.encodedBlockArray.extractStateRoot();

        // Because the previous step confirmed L1 state, we do not need to repeat steps 1 and 2 again
        // We now just need to validate account storage on the destination L2 using
        // StateValidator.validateAccountStorage
        // This library function will accomplish the following 2 steps:
        //      5. Validate L2 account proof where `account` here is the destination L2 contract
        //      6. Validate storage proof proving the destination L2 storage slot;
        if (!target.l2Address.validateAccountStorage(l2StateRoot, data.dstL2AccountProofParams)) {
            revert InvalidL2Storage();
        }
    }

    /// @notice Derives the L1 storageKey using the supplied `nodeIndex` and the `confirmData` storage slot offset
    function _deriveL1StorageKey(bytes32 newAssertionHash) private pure returns (bytes memory) {
        return abi.encode(keccak256(abi.encode(newAssertionHash, _L1_STORAGE_KEY)));
    }

    /// @notice Extracts the confirmation status of the assertion node from bits 200-207 of the storage value
    ///
    /// @dev Since the confirmation status is the final value stored in the first storage slot of the assertion node, we
    ///      can use a mask of the highest 56 bits to extract it
    function _extractConfirmation(bytes32 storageValue) private pure returns (AssertionStatus) {
        return AssertionStatus((uint256(storageValue) & _MASK) >> 200);
    }

    /// @notice Derives the new assertion hash
    function _assertionHash(bytes32 prevAssertionHash, AssertionState memory afterState, bytes32 sequencerBatchAcc)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(prevAssertionHash, keccak256(abi.encode(afterState)), sequencerBatchAcc));
    }

    /// @notice Formats the storage value to 32 bytes
    function _format(bytes memory value) private pure returns (bytes memory) {
        return abi.encodePacked(new bytes(32 - value.length), value);
    }
}
