import type { Address } from "viem";

export type Call = {
  to: Address;
  data: Address;
  value: bigint;
};

export type Request = {
  requester: Address;
  calls: Call[];
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
