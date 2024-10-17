// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";

import {StateValidator} from "../libraries/StateValidator.sol";
import {RIP7755Source} from "./RIP7755Source.sol";
import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {CrossChainRequest} from "../RIP7755Structs.sol";

/// @title RIP7755SourceArbitrumValidator
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on Arbitrum
contract RIP7755SourceArbitrumValidator is RIP7755Source {
    using StateValidator for address;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

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

    /// @notice This error is thrown when fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from
    /// current destination chain block timestamp.
    error FinalityDelaySecondsInProgress();

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
    /// @dev Implementation will vary by L2
    ///
    /// @param verifyingContractStorageKey The storage location of the data to verify on the destination chain
    /// `RIP7755Inbox` contract
    /// @param fulfillmentInfo The fulfillment info that should be located at `verifyingContractStorageKey` in storage
    /// on the destination chain `RIP7755Inbox` contract
    /// @param request The original cross chain request submitted to this contract
    /// @param storageProofData The storage proof to validate
    function _validate(
        bytes32 verifyingContractStorageKey,
        RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata request,
        bytes calldata storageProofData
    ) internal view override {
        if (block.timestamp - fulfillmentInfo.timestamp < request.finalityDelaySeconds) {
            revert FinalityDelaySecondsInProgress();
        }

        RIP7755Proof memory proofData = abi.decode(storageProofData, (RIP7755Proof));

        // Set the expected storage key and value for the `RIP7755Inbox` on Arbitrum
        proofData.dstL2AccountProofParams.storageKey = abi.encodePacked(verifyingContractStorageKey);
        proofData.dstL2AccountProofParams.storageValue = _encodeFulfillmentInfo(fulfillmentInfo);

        // Derive the L1 storage key to use in the storage proof. For Arbitrum, we will use the storage slot containing
        // the `confirmData` field in a posted RBlock
        // See https://github.com/OffchainLabs/nitro-contracts/blob/main/src/rollup/Node.sol#L21 for the RBlock structure
        // See https://github.com/OffchainLabs/nitro-contracts/blob/main/src/rollup/RollupCore.sol#L64 for the mapping location
        proofData.dstL2StateRootProofParams.storageKey = _deriveL1StorageKey(proofData, request);

        // We first need to validate knowledge of the destination L2 chain's state root.
        // StateValidator.validateState will accomplish each of the following 4 steps:
        //      1. Confirm beacon root
        //      2. Validate L1 state root
        //      3. Validate L1 account proof where `account` here is Arbitrum's Rollup contract
        //      4. Validate storage proof proving destination L2 root stored in Rollup contract
        bool validState =
            request.l2Oracle.validateState(proofData.stateProofParams, proofData.dstL2StateRootProofParams);

        if (!validState) {
            revert InvalidStateRoot();
        }

        // As an intermediate step, we need to prove that `proofData.dstL2StateRootProofParams.storageValue` is linked
        // to the correct l2StateRoot before we can prove l2Storage

        // Derive the L2 blockhash
        bytes32 l2BlockHash = keccak256(proofData.encodedBlockArray);
        // Derive the RBlock's `confirmData` field
        bytes32 confirmData = keccak256(abi.encodePacked(l2BlockHash, proofData.sendRoot));
        // Extract the L2 stateRoot from the RLP-encoded block array
        bytes32 l2StateRoot = _extractL2StateRoot(proofData.encodedBlockArray);

        // The L1 storage value we proved was the node's confirmData
        if (bytes32(proofData.dstL2StateRootProofParams.storageValue) != confirmData) {
            revert InvalidConfirmData();
        }

        // Because the previous step confirmed L1 state, we do not need to repeat steps 1 and 2 again
        // We now just need to validate account storage on the destination L2 using StateValidator.validateAccountStorage
        // This library function will accomplish the following 2 steps:
        //      5. Validate L2 account proof where `account` here is `RIP7755Inbox` on destination chain
        //      6. Validate storage proof proving FulfillmentInfo in `RIP7755Inbox` storage
        bool validL2Storage =
            request.verifyingContract.validateAccountStorage(l2StateRoot, proofData.dstL2AccountProofParams);

        if (!validL2Storage) {
            revert InvalidL2Storage();
        }
    }

    /// @notice Derives the L1 storageKey using the supplied `nodeIndex` and the `confirmData` storage slot offset
    function _deriveL1StorageKey(RIP7755Proof memory proofData, CrossChainRequest calldata request)
        private
        pure
        returns (bytes memory)
    {
        uint256 startingStorageSlot = uint256(keccak256(abi.encode(proofData.nodeIndex, request.l2OracleStorageKey)));
        return abi.encodePacked(startingStorageSlot + _ARBITRUM_RBLOCK_CONFIRMDATA_STORAGE_OFFSET);
    }

    /// @notice Extracts the l2StateRoot from the RLP-encoded block headers array
    ///
    /// @custom:reverts If the encoded block array does not have 16 elements
    ///
    /// @dev The stateRoot should be the fourth element
    function _extractL2StateRoot(bytes memory encodedBlockArray) private pure returns (bytes32) {
        RLPReader.RLPItem[] memory blockFields = encodedBlockArray.readList();

        if (blockFields.length != 16) {
            revert InvalidBlockFieldRLP();
        }

        return bytes32(blockFields[3].readBytes()); // state root is the fourth field
    }
}
