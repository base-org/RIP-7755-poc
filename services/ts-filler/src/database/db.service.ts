import mongoose, { type ObjectId } from "mongoose";
import type { Address } from "viem";

import type { RequestType } from "../types/request";
import { Submission } from "./submissions.schema";
import type { ActiveChains } from "../types/chain";

export default class DBService {
  constructor() {
    console.log("Connecting", process.env.MONGO_URI);
    this.connect().catch((err) => console.error(err));
  }

  private async connect() {
    await mongoose.connect(process.env.MONGO_URI as string);
    console.log("DB successfully connected");
  }

  async storeSuccessfulCall(
    requestHash: Address,
    txnHash: Address,
    request: RequestType,
    activeChains: ActiveChains
  ): Promise<boolean> {
    const doc = new Submission({
      requestHash,
      claimAvailableAt:
        Math.floor(Date.now() / 1000) + Number(request.finalityDelaySeconds),
      txnSubmittedHash: txnHash,
      activeChains: {
        src: activeChains.src.chainId,
        l1: activeChains.l1.chainId,
        dst: activeChains.dst.chainId,
      },
      request,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await doc.save();

    return true;
  }

  async getClaimableRewards() {
    return await Submission.find({
      claimAvailableAt: { $lte: Math.floor(Date.now() / 1000) },
      rewardClaimedTxnHash: null,
    });
  }

  async updateRewardClaimed(_id: ObjectId, txnHash: Address) {
    const res = await Submission.updateOne(
      { _id },
      { rewardClaimedTxnHash: txnHash }
    );

    if (res.modifiedCount === 0) {
      throw new Error("Error updating submission document");
    }
  }
}
