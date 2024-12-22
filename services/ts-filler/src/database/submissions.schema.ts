import mongoose from "mongoose";

import type { SubmissionType } from "../common/types/submission";
import type { ActiveChains } from "../common/types/chain";

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
  activeChains: activeChainsSchema,
  sender: String,
  receiver: String,
  payload: String,
  value: String,
  attributes: [String],
  createdAt: Date,
  updatedAt: Date,
});

export const Submission = mongoose.model("Submission", submissionSchema);

submissionSchema.index({ claimAvailableAt: 1 });
