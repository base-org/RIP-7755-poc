import mongoose from "mongoose";

import type { SubmissionType } from "../common/types/submission";
import type { RequestType } from "../common/types/request";
import type { ActiveChains } from "../common/types/chain";

const callSchema = new mongoose.Schema({
  to: String,
  data: String,
  value: String,
});

const requestSchema = new mongoose.Schema<RequestType>({
  requester: String,
  calls: [callSchema],
  proverContract: String,
  destinationChainId: String,
  inboxContract: String,
  l2Oracle: String,
  l2OracleStorageKey: String,
  rewardAsset: String,
  rewardAmount: String,
  finalityDelaySeconds: String,
  nonce: String,
  expiry: String,
  precheckContract: String,
  precheckData: String,
});

const activeChainsSchema = new mongoose.Schema<ActiveChains>({
  src: Number,
  l1: Number,
  dst: Number,
});

const submissionSchema = new mongoose.Schema<SubmissionType>({
  requestHash: String,
  claimAvailableAt: Number,
  txnSubmittedHash: String,
  rewardClaimedTxnHash: String,
  request: requestSchema,
  activeChains: activeChainsSchema,
  createdAt: Date,
  updatedAt: Date,
});

export const Submission = mongoose.model("Submission", submissionSchema);

submissionSchema.index({ claimAvailableAt: 1 });
