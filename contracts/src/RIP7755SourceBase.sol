// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RIP7755Source} from "./RIP7755Source.sol";
import {RIP7755Verifier} from "./RIP7755Verifier.sol";
import {StateValidator} from "./libraries/StateValidator.sol";

/// @title RIP7755SourceBaseValidator
///
/// @author Coinbase (https://github.com/base-org/RIP-7755-poc)
///
/// @notice This contract implements Base-compliant storage proof validation to ensure that requested calls actually
/// happened on a target L2
contract RIP7755SourceBaseValidator is RIP7755Source {
    using StateValidator for address;

    struct RIP7755Proof {
        StateValidator.StateProofParameters stateProofParams;
        StateValidator.AccountProofParameters dstL2StateRootProofParams;
        StateValidator.AccountProofParameters dstL2AccountProofParams;
    }

    error InvalidStateRoot();
    error InvalidL2Storage();
    error FinalityDelaySecondsInProgress();

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

        // 1. Confirm beacon root
        // 2. Validate L1 state root
        // 3. Validate L1 account proof where `account` here is the destination chain's inbox contract
        // 4. Validate storage proof proving destination L2 root stored in L1 inbox contract
        bool validState =
            request.l2Oracle.validateState(proofData.stateProofParams, proofData.dstL2StateRootProofParams);

        if (!validState) {
            revert InvalidStateRoot();
        }

        // 5. Validate L2 account proof where `account` here is `RIP7755Verifier` on destination chain
        // 6. Validate storage proof proving FulfillmentInfo in `RIP7755Verifier` storage
        bool validL2Storage = request.verifyingContract.validateAccountStorage(
            bytes32(proofData.dstL2StateRootProofParams.storageValue), proofData.dstL2AccountProofParams
        );

        if (!validL2Storage) {
            revert InvalidL2Storage();
        }
    }
}
