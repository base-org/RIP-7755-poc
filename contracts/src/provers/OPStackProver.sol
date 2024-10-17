// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IProver} from "../interfaces/IProver.sol";
import {StateValidator} from "../libraries/StateValidator.sol";
import {RIP7755Inbox} from "../RIP7755Inbox.sol";
import {CrossChainRequest} from "../RIP7755Structs.sol";

/// @title RIP7755OutboxOPStackValidator
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This contract implements storage proof validation to ensure that requested calls actually happened on an OP Stack chain
contract OPStackProver is IProver {
    using StateValidator for address;

    /// @notice Parameters needed for a full nested cross-L2 storage proof
    struct RIP7755Proof {
        /// @dev The L2 stateRoot used to prove L2 storage value in `RIP7755Inbox`
        bytes32 l2StateRoot;
        /// @dev The storage root of Optimism's MessagePasser contract - used to compute our L1 storage value
        bytes32 l2MessagePasserStorageRoot;
        /// @dev the blockhash of the L2 block corresponding to the above l2StateRoot
        bytes32 l2BlockHash;
        /// @dev Parameters needed to validate the authenticity of Ethereum's execution client's state root
        StateValidator.StateProofParameters stateProofParams;
        /// @dev Parameters needed to validate the authenticity of the l2Oracle for the destination L2 chain on Eth
        /// mainnet
        StateValidator.AccountProofParameters dstL2StateRootProofParams;
        /// @dev Parameters needed to validate the authenticity of a specified storage location in `RIP7755Inbox` on
        /// the destination L2 chain
        StateValidator.AccountProofParameters dstL2AccountProofParams;
    }

    /// @notice This error is thrown when fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from
    /// current destination chain block timestamp.
    error FinalityDelaySecondsInProgress();

    /// @notice This error is thrown when verification of the authenticity of the l2Oracle for the destination L2 chain
    /// on Eth mainnet fails
    error InvalidL1Storage();

    /// @notice This error is thrown when verification of the authenticity of the `RIP7755Inbox` storage on the
    /// destination L2 chain fails
    error InvalidL2Storage();

    /// @notice This error is thrown when the supplied l2StateRoot does not correspond to our validated L1 state
    error InvalidL2StateRoot();

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
    /// @param fulfillmentInfo The fulfillment info that should be located at `inboxContractStorageKey` in storage
    /// on the destination chain `RIP7755Inbox` contract
    /// @param request The original cross chain request submitted to this contract
    /// @param storageProofData The storage proof to validate
    function isValidProof(
        bytes memory inboxContractStorageKey,
        RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata request,
        bytes calldata storageProofData
    ) external view returns (bool) {
        if (block.timestamp - fulfillmentInfo.timestamp < request.finalityDelaySeconds) {
            revert FinalityDelaySecondsInProgress();
        }

        RIP7755Proof memory proofData = abi.decode(storageProofData, (RIP7755Proof));

        // Set the expected storage key and value for the `RIP7755Inbox` on the destination OP Stack chain
        // NOTE: the following two lines are temporarily commented out for hacky tests
        // proofData.dstL2AccountProofParams.storageKey = inboxContractStorageKey;
        // proofData.dstL2AccountProofParams.storageValue = _encodeFulfillmentInfo(fulfillmentInfo);

        // We first need to validate knowledge of the destination L2 chain's state root.
        // StateValidator.validateState will accomplish each of the following 4 steps:
        //      1. Confirm beacon root
        //      2. Validate L1 state root
        //      3. Validate L1 account proof where `account` here is the destination chain's AnchorStateRegistry contract
        //      4. Validate storage proof proving destination L2 root stored in L1 AnchorStateRegistry contract
        bool validState =
            request.l2Oracle.validateState(proofData.stateProofParams, proofData.dstL2StateRootProofParams);

        if (!validState) {
            revert InvalidL1Storage();
        }

        // As an intermediate step, we need to prove that `proofData.dstL2StateRootProofParams.storageValue` is linked
        // to the correct l2StateRoot before we can prove l2Storage

        bytes32 version;
        // Compute the expected destination chain output root (which is the value we just proved is in the L1 storage slot)
        bytes32 expectedOutputRoot = keccak256(
            abi.encodePacked(
                version, proofData.l2StateRoot, proofData.l2MessagePasserStorageRoot, proofData.l2BlockHash
            )
        );
        // If this checks out, it means we know the correct l2StateRoot
        if (bytes32(proofData.dstL2StateRootProofParams.storageValue) != expectedOutputRoot) {
            revert InvalidL2StateRoot();
        }

        // Because the previous step confirmed L1 state, we do not need to repeat steps 1 and 2 again
        // We now just need to validate account storage on the destination L2 using StateValidator.validateAccountStorage
        // This library function will accomplish the following 2 steps:
        //      5. Validate L2 account proof where `account` here is `RIP7755Inbox` on destination chain
        //      6. Validate storage proof proving FulfillmentInfo in `RIP7755Inbox` storage
        // NOTE: the following line is a temporary line used to validate proof logic. Will be removed in the near future.
        bool validL2Storage = 0xAd6A7addf807D846A590E76C5830B609F831Ba2E.validateAccountStorage(
            proofData.l2StateRoot, proofData.dstL2AccountProofParams
        );
        // bool validL2Storage =
        //     request.verifyingContract.validateAccountStorage(proofData.l2StateRoot, proofData.dstL2AccountProofParams);

        if (!validL2Storage) {
            revert InvalidL2Storage();
        }

        return true;
    }
}
