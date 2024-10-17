import type { Address, Block, GetProofReturnType, Hex } from "viem";

import type { SupportedChains } from "./chains";

export type StateRootProofReturnType = { proof: Hex[]; leaf: Hex };

export type Proofs = {
  storageProof: GetProofReturnType;
  l2StorageProof: GetProofReturnType;
  l2MessagePasserStorageProof?: GetProofReturnType;
};

export type GetStorageProofsInput = {
  dstChain: SupportedChains;
  l1BlockNumber: bigint;
  l2Block: Block;
  l2Slot: Address;
  nodeIndex: bigint | null;
};
