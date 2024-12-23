import type { Address, Hex } from "viem";
import type { ObjectId } from "mongoose";

export type SubmissionType = {
  _id: ObjectId;
  requestHash: Address;
  claimAvailableAt: number;
  txnSubmittedHash: Address;
  rewardClaimedTxnHash: Address;
  sender: string;
  receiver: string;
  payload: Hex;
  value: bigint;
  attributes: Hex[];
  devnet: boolean;
  activeChains: {
    src: number;
    l1: number;
    dst: number;
  };
  createdAt: Date;
  updatedAt: Date;
};
