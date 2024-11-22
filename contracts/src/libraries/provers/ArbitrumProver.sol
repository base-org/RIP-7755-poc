// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";

import {StateValidator} from "../StateValidator.sol";
import {RIP7755Inbox} from "../../RIP7755Inbox.sol";
import {RIP7755Outbox} from "../../RIP7755Outbox.sol";
import {CrossChainRequest} from "../../RIP7755Structs.sol";

/// @title ArbitrumProver
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This is a utility library for validating Arbitrum storage proofs.
library ArbitrumProver {
    using StateValidator for address;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @notice The address and storage keys to validate on L1 and L2
    struct Target {
        /// @dev The address of the L1 contract to validate. Should be Arbitrum's Rollup contract
        address l1Address;
        /// @dev The storage key on L1 to validate
        bytes32 l1StorageKey;
        /// @dev The address of the L2 contract to validate. Should be Arbitrum's `RIP7755Inbox` contract
        address l2Address;
        /// @dev The storage key on L2 to validate. Should be the `RIP7755Inbox` storage slot containing the
        /// `FulfillmentInfo` struct
        bytes32 l2StorageKey;
    }

    /// @notice Parameters needed for a full nested cross-L2 storage proof with Arbitrum as the destination chain
    struct RIP7755Proof {
        /// @dev The root hash of a Merkle tree that contains all the messages sent from Arbitrum to L1
        bytes sendRoot;
        /// @dev The index of Arbitrum's RBlock containing the state root to use in our storage proof
        uint64 nodeIndex;
        /// @dev The RLP-encoded array of block headers of Arbitrum's L2 block corresponding to the above RBlock. Hashing this bytes string should produce the blockhash.
        bytes encodedBlockArray;
        /// @dev Parameters needed to validate the authenticity of Ethereum's execution client's state root
        StateValidator.StateProofParameters stateProofParams;
        /// @dev Parameters needed to validate the authenticity of the l2Oracle for the destination L2 chain on Eth
        /// mainnet
        StateValidator.AccountProofParameters dstL2StateRootProofParams;
        /// @dev Parameters needed to validate the authenticity of a specified storage location in `RIP7755Inbox` on
        /// the destination L2 chain
        StateValidator.AccountProofParameters dstL2AccountProofParams;
    }

    /// @notice The storage slot offset of the `confirmData` field in an Arbitrum RBlock
    uint256 private constant _ARBITRUM_RBLOCK_CONFIRMDATA_STORAGE_OFFSET = 2;

    /// @notice This error is thrown when verification of the authenticity of the l2Oracle for the destination L2 chain
    /// on Eth mainnet fails
    error InvalidStateRoot();

    /// @notice This error is thrown when verification of the authenticity of the `RIP7755Inbox` storage on the
    /// destination L2 chain fails
    error InvalidL2Storage();

    /// @notice This error is thrown when the derived `confirmData` does not match the value in the validated L1 storage slot
    error InvalidConfirmData();

    /// @notice This error is thrown when the encoded block headers does not contain all 16 fields
    error InvalidBlockFieldRLP();

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo not found at verifyingContractStorageKey on request.verifyingContract
    /// @custom:reverts If fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from current destination
    /// chain block timestamp.
    /// @custom:reverts If the L2StorageRoot does not correspond to our validated L1 storage slot
    ///
    /// @param proof The proof to validate
    /// @param target The proof target on L1 and dst L2
    ///
    /// @return l2Timestamp The timestamp of the validated L2 state root
    /// @return l2StorageValue The storage value of the `RIP7755Inbox` storage slot
    function validate(bytes calldata proof, Target memory target) internal view returns (uint256, bytes memory) {
        RIP7755Proof memory proofData = abi.decode(proof, (RIP7755Proof));

        // Set the expected storage key and value for the `RIP7755Inbox` on Arbitrum
        proofData.dstL2AccountProofParams.storageKey = abi.encode(target.l2StorageKey);

        // Derive the L1 storage key to use in the storage proof. For Arbitrum, we will use the storage slot containing
        // the `confirmData` field in a posted RBlock
        // See https://github.com/OffchainLabs/nitro-contracts/blob/main/src/rollup/Node.sol#L21 for the RBlock structure
        // See https://github.com/OffchainLabs/nitro-contracts/blob/main/src/rollup/RollupCore.sol#L64 for the mapping location
        proofData.dstL2StateRootProofParams.storageKey = _deriveL1StorageKey(proofData, target.l1StorageKey);

        // We first need to validate knowledge of the destination L2 chain's state root.
        // StateValidator.validateState will accomplish each of the following 4 steps:
        //      1. Confirm beacon root
        //      2. Validate L1 state root
        //      3. Validate L1 account proof where `account` here is Arbitrum's Rollup contract
        //      4. Validate storage proof proving destination L2 root stored in Rollup contract
        bool validState =
            target.l1Address.validateState(proofData.stateProofParams, proofData.dstL2StateRootProofParams);

        if (!validState) {
            revert InvalidStateRoot();
        }

        // As an intermediate step, we need to prove that `proofData.dstL2StateRootProofParams.storageValue` is linked
        // to the correct l2StateRoot before we can prove l2Storage

        // Derive the L2 blockhash
        bytes32 l2BlockHash = keccak256(proofData.encodedBlockArray);
        // Derive the RBlock's `confirmData` field
        bytes32 confirmData = keccak256(abi.encodePacked(l2BlockHash, proofData.sendRoot));
        // Extract the L2 stateRoot and timestamp from the RLP-encoded block array
        (bytes32 l2StateRoot, uint256 l2Timestamp) = _extractL2StateRootAndTimestamp(proofData.encodedBlockArray);

        // The L1 storage value we proved was the node's confirmData
        if (bytes32(proofData.dstL2StateRootProofParams.storageValue) != confirmData) {
            revert InvalidConfirmData();
        }

        // Because the previous step confirmed L1 state, we do not need to repeat steps 1 and 2 again
        // We now just need to validate account storage on the destination L2 using StateValidator.validateAccountStorage
        // This library function will accomplish the following 2 steps:
        //      5. Validate L2 account proof where `account` here is `RIP7755Inbox` on destination chain
        //      6. Validate storage proof proving FulfillmentInfo in `RIP7755Inbox` storage
        bool validL2Storage = target.l2Address.validateAccountStorage(l2StateRoot, proofData.dstL2AccountProofParams);

        if (!validL2Storage) {
            revert InvalidL2Storage();
        }

        return (l2Timestamp, proofData.dstL2AccountProofParams.storageValue);
    }

    /// @notice Derives the L1 storageKey using the supplied `nodeIndex` and the `confirmData` storage slot offset
    function _deriveL1StorageKey(RIP7755Proof memory proofData, bytes32 l1StorageKey)
        private
        pure
        returns (bytes memory)
    {
        uint256 startingStorageSlot = uint256(keccak256(abi.encode(proofData.nodeIndex, l1StorageKey)));
        return abi.encodePacked(startingStorageSlot + _ARBITRUM_RBLOCK_CONFIRMDATA_STORAGE_OFFSET);
    }

    /// @notice Extracts the l2StateRoot and l2Timestamp from the RLP-encoded block headers array
    ///
    /// @custom:reverts If the encoded block array has less than 15 elements
    ///
    /// @dev The stateRoot should be the 4th element, and the timestamp should be the 12th element
    function _extractL2StateRootAndTimestamp(bytes memory encodedBlockArray) private pure returns (bytes32, uint256) {
        RLPReader.RLPItem[] memory blockFields = encodedBlockArray.readList();

        if (blockFields.length < 15) {
            revert InvalidBlockFieldRLP();
        }

        return (bytes32(blockFields[3].readBytes()), uint256(bytes32(blockFields[11].readBytes())));
    }
}
