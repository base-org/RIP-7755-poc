import type { Address } from "viem";

export type AccountProofParams = {
  storageKey: Address;
  storageValue: Address;
  accountProof: Address[];
  storageProof: Address[];
};

export type StateProofParams = {
  beaconRoot: Address;
  beaconOracleTimestamp: bigint;
  executionStateRoot: Address;
  stateRootProof: Address[];
};

export type ArbitrumProofType = {
  stateProofParams: StateProofParams;
  dstL2StateRootProofParams: AccountProofParams;
  dstL2AccountProofParams: AccountProofParams;
  sendRoot: Address;
  encodedBlockArray: Address;
  nodeIndex: bigint;
};

export type OPStackProofType = {
  l2StateRoot: Address;
  l2BlockHash: Address;
  stateProofParams: StateProofParams;
  dstL2StateRootProofParams: AccountProofParams;
  dstL2AccountProofParams: AccountProofParams;
  l2MessagePasserStorageRoot: Address;
};
