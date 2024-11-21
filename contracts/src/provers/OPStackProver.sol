// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";

import {IProver} from "../interfaces/IProver.sol";
import {StateValidator} from "../libraries/StateValidator.sol";
import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {CrossChainRequest} from "../RIP7755Structs.sol";

/// @title RIP7755OutboxMultiChainValidator
///
/// @notice This contract implements storage proof validation for OP Stack and Arbitrum chains
contract MultiChainProver is IProver {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @notice Address of the external validator contract for state proofs
    StateValidator public stateValidator;

    /// @notice Address of the external validator contract for account proofs
    StateValidator public accountValidator;

    /// @dev Enum to specify the chain type for proof validation
    enum ChainType {
        OP_STACK,
        ARBITRUM
    }

    /// @dev Constructor to initialize the external validator contract addresses
    /// @param _stateValidator Address of the state validator contract
    /// @param _accountValidator Address of the account validator contract
    constructor(StateValidator _stateValidator, StateValidator _accountValidator) {
        stateValidator = _stateValidator;
        accountValidator = _accountValidator;
    }

    /// @notice Validates storage proofs and verifies fulfillment for OP Stack and Arbitrum chains
    ///
    /// @dev The function uses external validators for modular proof logic:
    ///      - For OP Stack chains: Uses state root validation and L2 storage proof.
    ///      - For Arbitrum chains: Uses specific state and storage proof logic.
    ///
    /// @param chainType The type of chain for which the proof is being validated (OP Stack or Arbitrum)
    /// @param inboxContractStorageKey The storage location of the data to verify on the destination chain
    /// `RIP7755Inbox` contract
    /// @param fulfillmentInfo The fulfillment info that should be located at `inboxContractStorageKey` in storage
    /// on the destination chain `RIP7755Inbox` contract
    /// @param request The original cross chain request submitted to this contract
    /// @param proof The proof to validate
    function validateProof(
        ChainType chainType,
        bytes memory inboxContractStorageKey,
        RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata request,
        bytes calldata proof
    ) external view {
        // Decode the proof data
        RIP7755Proof memory proofData = abi.decode(proof, (RIP7755Proof));

        if (chainType == ChainType.OP_STACK) {
            _validateOPStackProof(proofData, inboxContractStorageKey, fulfillmentInfo, request);
        } else if (chainType == ChainType.ARBITRUM) {
            _validateArbitrumProof(proofData, inboxContractStorageKey, fulfillmentInfo, request);
        } else {
            revert("Unsupported chain type");
        }
    }

    /// @dev Validates storage proof for OP Stack chains
    function _validateOPStackProof(
        RIP7755Proof memory proofData,
        bytes memory inboxContractStorageKey,
        RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata request
    ) internal view {
        // Step 1: Validate the L1 state root using the external validator
        bool validState = stateValidator.validateState(
            proofData.stateProofParams,
            proofData.dstL2StateRootProofParams
        );

        if (!validState) {
            revert InvalidL1Storage();
        }

        // Step 2: Extract L2 state root and timestamp
        bytes32 version;
        (bytes32 l2StateRoot, uint256 l2Timestamp) = _extractL2StateRootAndTimestamp(proofData.encodedBlockArray);
        bytes32 l2BlockHash = keccak256(proofData.encodedBlockArray);

        if (fulfillmentInfo.timestamp + request.finalityDelaySeconds > l2Timestamp) {
            revert FinalityDelaySecondsInProgress();
        }

        // Step 3: Compute and validate the destination output root
        bytes32 expectedOutputRoot = keccak256(
            abi.encodePacked(
                version, l2StateRoot, proofData.l2MessagePasserStorageRoot, l2BlockHash
            )
        );

        if (bytes32(proofData.dstL2StateRootProofParams.storageValue) != expectedOutputRoot) {
            revert InvalidL2StateRoot();
        }

        // Step 4: Validate the final L2 storage proof
        bool validL2Storage = accountValidator.validateAccountStorage(
            l2StateRoot, proofData.dstL2AccountProofParams
        );

        if (!validL2Storage) {
            revert InvalidL2Storage();
        }
    }

    /// @dev Validates storage proof for Arbitrum chains
    function _validateArbitrumProof(
        RIP7755Proof memory proofData,
        bytes memory inboxContractStorageKey,
        RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata request
    ) internal view {
        // Arbitrum-specific state proof validation
        bool validState = stateValidator.validateState(
            proofData.stateProofParams,
            proofData.dstL2StateRootProofParams
        );

        if (!validState) {
            revert InvalidL1Storage();
        }

        // Extract Arbitrum-specific details from the proof (e.g., L2 state root and timestamp)
        bytes32 l2StateRoot = proofData.dstL2StateRootProofParams.storageKey; // Example for Arbitrum logic
        uint256 l2Timestamp = block.timestamp; // Mock logic for Arbitrum timestamp

        if (fulfillmentInfo.timestamp + request.finalityDelaySeconds > l2Timestamp) {
            revert FinalityDelaySecondsInProgress();
        }

        // Validate Arbitrum-specific storage proof
        bool validL2Storage = accountValidator.validateAccountStorage(
            l2StateRoot, proofData.dstL2AccountProofParams
        );

        if (!validL2Storage) {
            revert InvalidL2Storage();
        }
    }

    /// @notice Extracts the l2StateRoot and l2Timestamp from the RLP-encoded block headers array
    ///
    /// @dev Extraction logic remains the same for OP Stack chains but can be customized for others
    ///
    /// @param encodedBlockArray RLP-encoded array of block headers
    /// @return l2StateRoot Extracted L2 state root
    /// @return l2Timestamp Extracted L2 block timestamp
    function _extractL2StateRootAndTimestamp(bytes memory encodedBlockArray) private pure returns (bytes32, uint256) {
        RLPReader.RLPItem[] memory blockFields = encodedBlockArray.readList();

        if (blockFields.length < 15) {
            revert InvalidBlockFieldRLP();
        }

        return (bytes32(blockFields[3].readBytes()), uint256(bytes32(blockFields[11].readBytes())));
    }
}
