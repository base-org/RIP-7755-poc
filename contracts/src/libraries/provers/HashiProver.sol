// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RLPReader} from "optimism/packages/contracts-bedrock/src/libraries/rlp/RLPReader.sol";
import {StateValidator} from "../StateValidator.sol";
import {RIP7755Inbox} from "../../RIP7755Inbox.sol";
import {CrossChainRequest} from "../../RIP7755Structs.sol";

/// @title HashiProver
///
/// @author Crosschain Alliance
///
/// @notice This is a utility library for validating storage proofs using Hashi's block headers.
library HashiProver {
    using StateValidator for address;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @notice The address and storage keys to validate on L1 and L2
    struct Target {
        /// @dev The address of the contract to validate. Should be Hashi's `RIP7755Inbox` contract
        address addr;
        /// @dev The storage key on to validate. Should be the `RIP7755Inbox` storage slot containing the
        /// `FulfillmentInfo` struct
        bytes32 storageKey;
    }

    /// @notice Parameters needed for a full nested cross-chain storage proof
    struct RIP7755Proof {
        /// @dev The RLP-encoded block from which we want to retrieve its hash from Hashi
        bytes rlpEncodedBlockHeader;
        /// @dev Parameters needed to validate the authenticity of a specified storage location in `RIP7755Inbox` on
        /// the destination chain
        StateValidator.AccountProofParameters dstAccountProofParams;
    }

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
    function validate(bytes calldata proof, Target memory target) internal pure returns (uint256, bytes memory) {
        RIP7755Proof memory proofData = abi.decode(proof, (RIP7755Proof));

        // Set the expected storage key and value for the `RIP7755Inbox`
        proofData.dstAccountProofParams.storageKey = abi.encode(target.storageKey);

        (bytes32 stateRoot, uint256 timestamp) = _extractStateRootAndTimestamp(proofData.rlpEncodedBlockHeader);

        bool validStorage = target.addr.validateAccountStorage(stateRoot, proofData.dstAccountProofParams);
        if (!validStorage) {
            revert InvalidStorage();
        }

        return (timestamp, proofData.dstAccountProofParams.storageValue);
    }

    /// @dev Encodes the FulfillmentInfo struct the way it should be stored on the destination chain
    function _encodeFulfillmentInfo(RIP7755Inbox.FulfillmentInfo calldata fulfillmentInfo)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(fulfillmentInfo.filler, fulfillmentInfo.timestamp);
    }

    /// @notice Extracts the l2StateRoot and l2Timestamp from the RLP-encoded block headers array
    ///
    /// @custom:reverts If the encoded block array has less than 15 elements
    ///
    /// @dev The stateRoot should be the 4th element, and the timestamp should be the 12th element
    function _extractStateRootAndTimestamp(bytes memory encodedBlockArray) private pure returns (bytes32, uint256) {
        RLPReader.RLPItem[] memory blockFields = encodedBlockArray.readList();
        return (bytes32(blockFields[3].readBytes()), uint256(bytes32(blockFields[11].readBytes())));
    }
}
