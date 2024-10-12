// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {StateValidator} from "./libraries/StateValidator.sol";
import {RIP7755Source} from "./RIP7755Source.sol";
import {CrossChainRequest} from "./RIP7755Structs.sol";
import {RIP7755Verifier} from "./RIP7755Verifier.sol";

/// @title RIP7755SourceBaseValidator
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This contract implements Base-compliant storage proof validation to ensure that requested calls actually
/// happened on a target L2
contract RIP7755SourceBaseValidator is RIP7755Source {
    using StateValidator for address;

    /// @notice Parameters needed for a full nested cross-L2 storage proof
    struct RIP7755Proof {
        /// @dev Parameters needed to validate the authenticity of Ethereum's execution client's state root
        StateValidator.StateProofParameters stateProofParams;
        /// @dev Parameters needed to validate the authenticity of the l2Oracle for the destination L2 chain on Eth
        /// mainnet
        StateValidator.AccountProofParameters dstL2StateRootProofParams;
        /// @dev Parameters needed to validate the authenticity of a specified storage location in `RIP7755Verifier` on
        /// the destination L2 chain
        StateValidator.AccountProofParameters dstL2AccountProofParams;
    }

    /// @notice This error is thrown when fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from
    /// current destination chain block timestamp.
    error FinalityDelaySecondsInProgress();

    /// @notice This error is thrown when verification of the authenticity of the l2Oracle for the destination L2 chain
    /// on Eth mainnet fails
    error InvalidStateRoot();

    /// @notice This error is thrown when verification of the authenticity of the `RIP7755Verifier` storage on the
    /// destination L2 chain fails
    error InvalidL2Storage();

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If storage proof invalid.
    /// @custom:reverts If fulfillmentInfo not found at verifyingContractStorageKey on request.verifyingContract
    /// @custom:reverts If fulfillmentInfo.timestamp is less than request.finalityDelaySeconds from current destination
    /// chain block timestamp.
    ///
    /// @dev Implementation will vary by L2
    ///
    /// @param verifyingContractStorageKey The storage location of the data to verify on the destination chain
    /// `RIP7755Verifier` contract
    /// @param fulfillmentInfo The fulfillment info that should be located at `verifyingContractStorageKey` in storage
    /// on the destination chain `RIP7755Verifier` contract
    /// @param request The original cross chain request submitted to this contract
    /// @param storageProofData The storage proof to validate
    function _validate(
        bytes32 verifyingContractStorageKey,
        RIP7755Verifier.FulfillmentInfo calldata fulfillmentInfo,
        CrossChainRequest calldata request,
        bytes calldata storageProofData
    ) internal view override {
        if (block.timestamp - fulfillmentInfo.timestamp < request.finalityDelaySeconds) {
            revert FinalityDelaySecondsInProgress();
        }

        RIP7755Proof memory proofData = abi.decode(storageProofData, (RIP7755Proof));
        proofData.dstL2StateRootProofParams.storageKey = abi.encode(request.l2OracleStorageKey);
        proofData.dstL2AccountProofParams.storageKey = abi.encode(verifyingContractStorageKey);
        proofData.dstL2AccountProofParams.storageValue = abi.encode(fulfillmentInfo);

        // We first need to validate knowledge of the destination L2 chain's state root.
        // StateValidator.validateState will accomplish each of the following 4 steps:
        //      1. Confirm beacon root
        //      2. Validate L1 state root
        //      3. Validate L1 account proof where `account` here is the destination chain's inbox contract
        //      4. Validate storage proof proving destination L2 root stored in L1 inbox contract
        bool validState =
            request.l2Oracle.validateState(proofData.stateProofParams, proofData.dstL2StateRootProofParams);

        if (!validState) {
            revert InvalidStateRoot();
        }

        // Because the previous step confirmed L1 state, we do not need to repeat steps 1 and 2 again
        // We now just need to validate account storage on the destination L2 using StateValidator.validateAccountStorage
        // This library function will accomplish the following 2 steps:
        //      5. Validate L2 account proof where `account` here is `RIP7755Verifier` on destination chain
        //      6. Validate storage proof proving FulfillmentInfo in `RIP7755Verifier` storage
        bytes32 dstChainStorageRoot = bytes32(proofData.dstL2StateRootProofParams.storageValue);
        bool validL2Storage =
            request.verifyingContract.validateAccountStorage(dstChainStorageRoot, proofData.dstL2AccountProofParams);

        if (!validL2Storage) {
            revert InvalidL2Storage();
        }
    }
}
