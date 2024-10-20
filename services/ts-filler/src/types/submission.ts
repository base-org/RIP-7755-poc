import type { Address } from "viem";
import type { ObjectId } from "mongoose";

import type { RequestType } from "./request";

export type SubmissionType = {
  _id: ObjectId;
  requestHash: Address;
  claimAvailableAt: number;
  txnSubmittedHash: Address;
  rewardClaimedTxnHash: Address;
  request: RequestType;
  activeChains: {
    src: number;
    l1: number;
    dst: number;
  };
  createdAt: Date;
  updatedAt: Date;
};
