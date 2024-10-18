import type { Address, Block, GetProofReturnType, Hex } from "viem";

export type StateRootProofReturnType = { proof: Hex[]; leaf: Hex };

export type Proofs = {
  storageProof: GetProofReturnType;
  l2StorageProof: GetProofReturnType;
  l2MessagePasserStorageProof?: GetProofReturnType;
};

export type GetStorageProofsInput = {
  l1BlockNumber: bigint;
  l2Block: Block;
  l2Slot: Address;
  nodeIndex: bigint | null;
};
