// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";
import {HashiProver} from "../libraries/provers/HashiProver.sol";
import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {RIP7755Outbox} from "../RIP7755Outbox.sol";
import {CrossChainRequest} from "../RIP7755Structs.sol";
import {IShoyuBashi} from "../interfaces/IShoyuBashi.sol";

/// @title RIP7755OutboxToHashi
///
/// @author Crosschain Alliance
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on a EVM chain.
contract RIP7755OutboxToHashi is RIP7755Outbox {
    using HashiProver for bytes;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @notice The expected length of the request.extraData field as a constant
    uint256 private constant EXPECTED_EXTRA_DATA_LENGTH = 2;

    /// @notice The minimum block fields length
    uint256 private constant MINIMUM_BLOCK_FIELDS_LENGTH = 9;

    /// @notice This error is thrown when the number of bytes to convert into an uin256 is greather than 32
    error BytesLengthExceeds32();

    /// @notice This error is thrown when fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from
    /// current destination chain block timestamp.
    error FinalityDelaySecondsInProgress();

    /// @notice This error is thrown when the block fields length is less than MINIMUM_BLOCK_FIELDS_LENGTH
    error InvalidBlockFieldsLength();

    /// @notice This error is thrown when verification of proof.blockHash agaist the one stored in Hashi fails
    error InvalidBlockHeader();

    /// @notice This error is thrown when the request.extraData field has an invalid length
    error InvalidExtraDataLength();

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
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    /// `RIP7755Inbox` contract
    /// @param request The original cross chain request submitted to this contract
    /// @param proof The proof to validate
    function _validateProof(
        bytes memory inboxContractStorageKey,
        CrossChainRequest calldata request,
        bytes calldata proof
    ) internal view override {
        HashiProver.RIP7755Proof memory proofData = abi.decode(proof, (HashiProver.RIP7755Proof));
        uint256 blockNumber = _extractBlockNumber(proofData.rlpEncodedBlockHeader);

        if (request.extraData.length != EXPECTED_EXTRA_DATA_LENGTH) revert InvalidExtraDataLength();
        /// @notice The ShoyuBashi check should be performed within the PrecheckContract to ensure the correct ShoyuBashi is being used.
        (address shoyuBashi) = abi.decode(request.extraData[1], (address));
        bytes32 blockHeaderHash = IShoyuBashi(shoyuBashi).getThresholdHash(request.destinationChainId, blockNumber);
        if (blockHeaderHash != keccak256(proofData.rlpEncodedBlockHeader)) revert InvalidBlockHeader();

        HashiProver.Target memory target =
            HashiProver.Target({addr: request.inboxContract, storageKey: bytes32(inboxContractStorageKey)});
        (uint256 timestamp, bytes memory inboxContractStorageValue) = proof.validate(target);

        RIP7755Inbox.FulfillmentInfo memory fulfillmentInfo = _decodeFulfillmentInfo(bytes32(inboxContractStorageValue));

        // Ensure that the fulfillment timestamp is not within the finality delay
        if (fulfillmentInfo.timestamp + request.finalityDelaySeconds > timestamp) {
            revert FinalityDelaySecondsInProgress();
        }
    }

    /// @notice Extracts the blockNumber and stateRoot from the RLP-encoded block header
    ///
    /// @dev The blockNumber should be the ninth element
    function _extractBlockNumber(bytes memory encodedBlockArray) private pure returns (uint256) {
        RLPReader.RLPItem[] memory blockFields = encodedBlockArray.readList();
        if (blockFields.length < MINIMUM_BLOCK_FIELDS_LENGTH) revert InvalidBlockFieldsLength();
        return _bytesToUint256(blockFields[8].readBytes());
    }

    /// @notice Converts a sequence of bytes into an uint256
    function _bytesToUint256(bytes memory b) private pure returns (uint256) {
        if (b.length > 32) revert BytesLengthExceeds32();
        return abi.decode(abi.encodePacked(new bytes(32 - b.length), b), (uint256));
    }
}
