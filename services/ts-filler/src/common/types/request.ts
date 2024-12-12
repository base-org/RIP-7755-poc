import type { Address } from "viem";

export type CallType = {
  to: Address;
  data: Address;
  value: bigint;
};

export type RequestType = {
  requester: Address;
  calls: CallType[];
  sourceChainId: bigint;
  origin: Address;
  destinationChainId: bigint;
  inboxContract: Address;
  l2Oracle: Address;
  rewardAsset: Address;
  rewardAmount: bigint;
  finalityDelaySeconds: bigint;
  nonce: bigint;
  expiry: bigint;
  extraData: Address[];
};
