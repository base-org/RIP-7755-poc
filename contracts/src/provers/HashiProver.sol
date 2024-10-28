// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";
import {IProver} from "../interfaces/IProver.sol";
import {IShoyuBashi} from "../interfaces/IShoyuBashi.sol";
import {StateValidator} from "../libraries/StateValidator.sol";
import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {CrossChainRequest} from "../RIP7755Structs.sol";

/// @title HashiProver
///
/// @author Crosschain Alliance
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on a chain where Hashi is available
contract HashiProver is IProver {
    using StateValidator for address;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @notice Parameters needed for a full nested cross-chain storage proof
    struct RIP7755Proof {
        /// @dev The parameter specifies the chain ID for retrieving the block header from Hashi
        uint256 dstChainId;
        /// @dev The RLP-encoded block from which we want to retrieve its hash from Hashi
        bytes rlpEncodedBlockHeader;
        /// @dev Parameters needed to validate the authenticity of a specified storage location in `RIP7755Inbox` on
        /// the destination chain
        StateValidator.AccountProofParameters dstAccountProofParams;
    }

    /// @notice This error is thrown when fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from
    /// current destination chain block timestamp.
    error FinalityDelaySecondsInProgress();

    /// @notice This error is thrown when verification of the authenticity of the `RIP7755Inbox` storage on the
    /// destination chain fails
    error InvalidStorage();

    /// @notice This error is thrown when verification of proof.blockHash agaist the one stored in Hashi fails
    error InvalidBlockHeader();

    /// @notice This error is thrown when the number of bytes to convert into an uin256 is greather than 32
    error BytesLengthExeceed32();

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo not found at inboxContractStorageKey on request.inboxContract
    /// @custom:reverts If fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from current destination
    /// chain block timestamp.
    ///
    ///
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    /// `RIP7755Inbox` contract
    /// @param fulfillmentInfo The fulfillment info that should be located at `inboxContractStorageKey` in storage
    /// on the destination chain `RIP7755Inbox` contract
    /// @param request The original cross chain request submitted to this contract
    /// @param proof The proof to validate
    function validateProof(
        bytes memory inboxContractStorageKey,
        RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata request,
        bytes calldata proof
    ) external view {
        if (block.timestamp - fulfillmentInfo.timestamp < request.finalityDelaySeconds) {
            revert FinalityDelaySecondsInProgress();
        }

        RIP7755Proof memory proofData = abi.decode(proof, (RIP7755Proof));
        // Set the expected storage key and value for the `RIP7755Inbox`
        proofData.dstAccountProofParams.storageKey = inboxContractStorageKey;
        proofData.dstAccountProofParams.storageValue = _encodeFulfillmentInfo(fulfillmentInfo);

        (uint256 blockNumber, bytes32 stateRoot) = _extractBlockNumberAndStateRoot(proofData.rlpEncodedBlockHeader);

        /// @notice The ShoyuBashi check should be performed within the PrecheckContract to ensure the correct ShoyuBashi is being used.
        (address shoyuBashi) = abi.decode(request.precheckData, (address));
        bytes32 blockHeaderHash = IShoyuBashi(shoyuBashi).getThresholdHash(proofData.dstChainId, blockNumber);
        if (blockHeaderHash != keccak256(proofData.rlpEncodedBlockHeader)) revert InvalidBlockHeader();

        bool validStorage = request.inboxContract.validateAccountStorage(stateRoot, proofData.dstAccountProofParams);
        if (!validStorage) {
            revert InvalidStorage();
        }
    }

    /// @notice Converts a sequence of bytes into an uint256
    function _bytesToUint256(bytes memory b) private pure returns (uint256) {
        if (b.length > 32) revert BytesLengthExeceed32();
        return abi.decode(abi.encodePacked(new bytes(32 - b.length), b), (uint256));
    }

    /// @dev Encodes the FulfillmentInfo struct the way it should be stored on the destination chain
    function _encodeFulfillmentInfo(RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(fulfillmentInfo.filler, fulfillmentInfo.timestamp);
    }

    /// @notice Extracts the blockNumber and stateRoot from the RLP-encoded block header
    ///
    /// @dev The blockNumber should be the ninth element
    /// @dev The stateRoot should be the fourth element
    function _extractBlockNumberAndStateRoot(bytes memory encodedBlockArray) private pure returns (uint256, bytes32) {
        RLPReader.RLPItem[] memory blockFields = encodedBlockArray.readList();
        return (_bytesToUint256(blockFields[8].readBytes()), bytes32(blockFields[3].readBytes()));
    }
}
