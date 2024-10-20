import mongoose from "mongoose";

const callSchema = new mongoose.Schema({
  to: String,
  data: String,
  value: String,
});

const requestSchema = new mongoose.Schema({
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

const submissionSchema = new mongoose.Schema({
  requestHash: String,
  claimAvailableAt: Number,
  txnSubmittedHash: String,
  request: requestSchema,
  createdAt: Date,
  updatedAt: Date,
});

export const Submission = mongoose.model("Submission", submissionSchema);

submissionSchema.index({ claimAvailableAt: 1 });
