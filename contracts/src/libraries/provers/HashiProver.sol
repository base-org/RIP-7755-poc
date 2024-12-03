// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";
import {StateValidator} from "../StateValidator.sol";
import {RIP7755Inbox} from "../../RIP7755Inbox.sol";
import {CrossChainRequest} from "../../RIP7755Structs.sol";
import {IShoyuBashi} from "../../interfaces/IShoyuBashi.sol";

/// @title HashiProver
///
/// @author Crosschain Alliance
///
/// @notice This is a utility library for validating storage proofs using Hashi's block headers.
library HashiProver {
    using StateValidator for address;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @notice The minimum block fields length
    uint256 private constant MINIMUM_BLOCK_FIELDS_LENGTH = 9;

    /// @notice The address and storage keys to validate on L1 and L2
    struct Target {
        /// @dev The address of the contract to validate. Should be Hashi's `RIP7755Inbox` contract
        address addr;
        /// @dev The storage key on to validate. Should be the `RIP7755Inbox` storage slot containing the
        /// `FulfillmentInfo` struct
        bytes32 storageKey;
        /// @dev The ID of the destination chain where the validation is expected to occur
        uint256 destinationChainId;
        /// @dev The address of the Shoyu Bashi contract
        address shoyuBashi;
    }

    /// @notice Parameters needed for a full nested cross-chain storage proof
    struct RIP7755Proof {
        /// @dev The RLP-encoded block from which we want to retrieve its hash from Hashi
        bytes rlpEncodedBlockHeader;
        /// @dev Parameters needed to validate the authenticity of a specified storage location in `RIP7755Inbox` on
        /// the destination chain
        StateValidator.AccountProofParameters dstAccountProofParams;
    }

    /// @notice This error is thrown when the number of bytes to convert into an uin256 is greather than 32
    error BytesLengthExceeds32();

    /// @notice This error is thrown when verification of proof.blockHash agaist the one stored in Hashi fails
    error InvalidBlockHeader();

    /// @notice This error is thrown when the block fields length is less than MINIMUM_BLOCK_FIELDS_LENGTH
    error InvalidBlockFieldsLength();

    /// @notice This error is thrown when verification of the authenticity of the `RIP7755Inbox` storage on the
    /// destination chain fails
    error InvalidStorage();

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

        // Set the expected storage key for the `RIP7755Inbox`
        proofData.dstAccountProofParams.storageKey = abi.encode(target.storageKey);

        (bytes32 stateRoot, uint256 blockNumber, uint256 timestamp) =
            _extractStateRootBlockNumberAndTimestamp(proofData.rlpEncodedBlockHeader);
        bytes32 blockHeaderHash =
            IShoyuBashi(target.shoyuBashi).getThresholdHash(target.destinationChainId, blockNumber);
        if (blockHeaderHash != keccak256(proofData.rlpEncodedBlockHeader)) revert InvalidBlockHeader();

        bool validStorage = target.addr.validateAccountStorage(stateRoot, proofData.dstAccountProofParams);
        if (!validStorage) {
            revert InvalidStorage();
        }

        return (timestamp, proofData.dstAccountProofParams.storageValue);
    }

    /// @notice Extracts the stateRoot, blockNumber and timestamp from the RLP-encoded block headers array
    ///
    /// @custom:reverts If the encoded block array has less than 9 elements
    ///
    /// @dev The stateRoot should be the 4th element, the blockNumber the 9th and the timestamp should be the 12th element
    function _extractStateRootBlockNumberAndTimestamp(bytes memory encodedBlockArray)
        private
        pure
        returns (bytes32, uint256, uint256)
    {
        RLPReader.RLPItem[] memory blockFields = encodedBlockArray.readList();
        if (blockFields.length < MINIMUM_BLOCK_FIELDS_LENGTH) revert InvalidBlockFieldsLength();
        return (
            bytes32(blockFields[3].readBytes()),
            _bytesToUint256(blockFields[8].readBytes()),
            uint256(bytes32(blockFields[11].readBytes()))
        );
    }

    /// @notice Converts a sequence of bytes into an uint256
    function _bytesToUint256(bytes memory b) private pure returns (uint256) {
        if (b.length > 32) revert BytesLengthExceeds32();
        return abi.decode(abi.encodePacked(new bytes(32 - b.length), b), (uint256));
    }
}
