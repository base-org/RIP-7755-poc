// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IShoyuBashi} from "../../interfaces/IShoyuBashi.sol";
import {BlockHeaders} from "../BlockHeaders.sol";
import {StateValidator} from "../StateValidator.sol";

/// @title HashiProver
///
/// @author Crosschain Alliance
///
/// @notice This is a utility library for validating storage proofs using Hashi's block headers.
library HashiProver {
    using StateValidator for address;
    using BlockHeaders for bytes;

    /// @notice The address and storage keys to validate on L1 and L2
    struct Target {
        /// @dev The address of the destination contract to validate
        address addr;
        /// @dev The storage key on the destination contract to validate
        bytes storageKey;
        /// @dev The ID of the destination chain where the validation is expected to occur
        uint256 destinationChainId;
        /// @dev The address of the Shoyu Bashi contract
        address shoyuBashi;
    }

    /// @notice Parameters needed for a full nested cross-chain storage proof
    struct RIP7755Proof {
        /// @dev The RLP-encoded block from which we want to retrieve its hash from Hashi
        bytes rlpEncodedBlockHeader;
        /// @dev Parameters needed to validate the authenticity of a specified storage location on the destination chain
        StateValidator.AccountProofParameters dstAccountProofParams;
    }

    /// @notice This error is thrown when verification of proof.blockHash agaist the one stored in Hashi fails
    error InvalidBlockHeader();

    /// @notice This error is thrown when verification of the authenticity of the `RIP7755Inbox` storage on the
    ///         destination chain fails
    error InvalidStorage();

    /// @notice Validates storage proofs and verifies fulfillment
    ///
    /// @custom:reverts If RLP-encoded block header does not correspond to the block hash stored in Hashi
    /// @custom:reverts If storage proof invalid.
    ///
    /// @param proof  The proof to validate
    /// @param target The proof target on L1 and dst L2
    ///
    /// @return l2Timestamp    The timestamp of the validated L2 state root
    /// @return l2StorageValue The storage value of the `RIP7755Inbox` storage slot
    function validate(bytes calldata proof, Target memory target) internal view returns (uint256, bytes memory) {
        RIP7755Proof memory data = abi.decode(proof, (RIP7755Proof));

        data.dstAccountProofParams.storageKey = target.storageKey;

        (bytes32 stateRoot, uint256 blockNumber, uint256 timestamp) =
            data.rlpEncodedBlockHeader.extractStateRootBlockNumberAndTimestamp();
        bytes32 blockHeaderHash =
            IShoyuBashi(target.shoyuBashi).getThresholdHash(target.destinationChainId, blockNumber);

        if (blockHeaderHash != data.rlpEncodedBlockHeader.toBlockHash()) {
            revert InvalidBlockHeader();
        }

        if (!target.addr.validateAccountStorage(stateRoot, data.dstAccountProofParams)) {
            revert InvalidStorage();
        }

        return (timestamp, data.dstAccountProofParams.storageValue);
    }
}
