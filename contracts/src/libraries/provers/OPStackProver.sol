// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";

import {StateValidator} from "../StateValidator.sol";
import {RIP7755Inbox} from "../../RIP7755Inbox.sol";
import {RIP7755Outbox} from "../../RIP7755Outbox.sol";
import {CrossChainRequest} from "../../RIP7755Structs.sol";

/// @title OPStackProver
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This is a utility library for validating OP Stack storage proofs.
library OPStackProver {
    using StateValidator for address;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @notice The address and storage keys to validate on L1 and L2
    struct Target {
        /// @dev The address of the L1 contract to validate. Should be Optimism's AnchorStateRegistry contract
        address l1Address;
        /// @dev The storage key on L1 to validate
        bytes32 l1StorageKey;
        /// @dev The address of the L2 contract to validate. Should be Optimism's `RIP7755Inbox` contract
        address l2Address;
        /// @dev The storage key on L2 to validate. Should be the `RIP7755Inbox` storage slot containing the
        /// `FulfillmentInfo` struct
        bytes32 l2StorageKey;
    }

    /// @notice Parameters needed for a full nested cross-L2 storage proof
    struct RIP7755Proof {
        /// @dev The storage root of Optimism's MessagePasser contract - used to compute our L1 storage value
        bytes32 l2MessagePasserStorageRoot;
        /// @dev The RLP-encoded array of block headers of the chain's L2 block used for the proof. Hashing this bytes string should produce the blockhash.
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

    /// @notice This error is thrown when verification of the authenticity of the l2Oracle for the destination L2 chain
    /// on Eth mainnet fails
    error InvalidL1Storage();

    /// @notice This error is thrown when verification of the authenticity of the `RIP7755Inbox` storage on the
    /// destination L2 chain fails
    error InvalidL2Storage();

    /// @notice This error is thrown when the supplied l2StateRoot does not correspond to our validated L1 state
    error InvalidL2StateRoot();

    /// @notice This error is thrown when the encoded block headers does not contain all 16 fields
    error InvalidBlockFieldRLP();

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo not found at inboxContractStorageKey on request.inboxContract
    /// @custom:reverts If fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from current destination
    /// chain block timestamp.
    /// @custom:reverts If the L2StateRoot does not correspond to the validated L1 storage slot
    ///
    /// @dev Implementation will vary by L2
    ///
    /// @param proof The proof to validate
    /// @param target The proof target on L1 and dst L2
    ///
    /// @return l2Timestamp The timestamp of the validated L2 state root
    /// @return l2StorageValue The storage value of the `RIP7755Inbox` storage slot
    function validate(bytes calldata proof, Target memory target) internal view returns (uint256, bytes memory) {
        RIP7755Proof memory proofData = abi.decode(proof, (RIP7755Proof));

        // Set the expected storage key for the L1 storage slot
        proofData.dstL2StateRootProofParams.storageKey = abi.encode(target.l1StorageKey);
        // Set the expected storage key for the `RIP7755Inbox` storage slot
        proofData.dstL2AccountProofParams.storageKey = abi.encode(target.l2StorageKey);

        // We first need to validate knowledge of the destination L2 chain's state root.
        // StateValidator.validateState will accomplish each of the following 4 steps:
        //      1. Confirm beacon root
        //      2. Validate L1 state root
        //      3. Validate L1 account proof where `account` here is the destination chain's AnchorStateRegistry contract
        //      4. Validate storage proof proving destination L2 root stored in L1 AnchorStateRegistry contract
        bool validState =
            target.l1Address.validateState(proofData.stateProofParams, proofData.dstL2StateRootProofParams);

        if (!validState) {
            revert InvalidL1Storage();
        }

        // As an intermediate step, we need to prove that `proofData.dstL2StateRootProofParams.storageValue` is linked
        // to the correct l2StateRoot before we can prove l2Storage

        bytes32 version;
        // Extract the L2 stateRoot and timestamp from the RLP-encoded block array
        (bytes32 l2StateRoot, uint256 l2Timestamp) = _extractL2StateRootAndTimestamp(proofData.encodedBlockArray);
        // Derive the L2 blockhash
        bytes32 l2BlockHash = keccak256(proofData.encodedBlockArray);

        // Compute the expected destination chain output root (which is the value we just proved is in the L1 storage slot)
        bytes32 expectedOutputRoot =
            keccak256(abi.encodePacked(version, l2StateRoot, proofData.l2MessagePasserStorageRoot, l2BlockHash));
        // If this checks out, it means we know the correct l2StateRoot
        if (bytes32(proofData.dstL2StateRootProofParams.storageValue) != expectedOutputRoot) {
            revert InvalidL2StateRoot();
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
