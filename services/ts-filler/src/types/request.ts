import type { Address } from "viem";

export type CallType = {
  to: Address;
  data: Address;
  value: bigint;
};

export type RequestType = {
  requester: Address;
  calls: CallType[];
  proverContract: Address;
  destinationChainId: bigint;
  inboxContract: Address;
  l2Oracle: Address;
  l2OracleStorageKey: Address;
  rewardAsset: Address;
  rewardAmount: bigint;
  finalityDelaySeconds: bigint;
  nonce: bigint;
  expiry: bigint;
  precheckContract: Address;
  precheckData: Address;
};
