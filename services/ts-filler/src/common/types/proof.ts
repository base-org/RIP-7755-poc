import type { Hex } from "viem";
import type { Assertion } from "./chain";

export type AccountProofParams = {
  storageKey: Hex;
  storageValue: Hex;
  accountProof: Hex[];
  storageProof: Hex[];
};

export type StateProofParams = {
  beaconRoot: Hex;
  beaconOracleTimestamp: bigint;
  executionStateRoot: Hex;
  stateRootProof: Hex[];
};

export type ArbitrumProofType = {
  stateProofParams: StateProofParams;
  dstL2StateRootProofParams: AccountProofParams;
  dstL2AccountProofParams: AccountProofParams;
  encodedBlockArray: Hex;
  afterState: Assertion;
  prevAssertionHash: Hex;
  sequencerBatchAcc: Hex;
};

export type OPStackProofType = {
  l2MessagePasserStorageRoot: Hex;
  encodedBlockArray: Hex;
  stateProofParams: StateProofParams;
  dstL2StateRootProofParams: AccountProofParams;
  dstL2AccountProofParams: AccountProofParams;
};
