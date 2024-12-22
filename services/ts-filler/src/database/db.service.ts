import mongoose, { type ObjectId } from "mongoose";
import type { Address, Hex } from "viem";

import { Submission } from "./submissions.schema";
import type { ActiveChains } from "../common/types/chain";
import type { SubmissionType } from "../common/types/submission";
import exponentialBackoff from "../common/utils/exponentialBackoff";
import type Attributes from "../common/utils/attributes";

export default class DBService {
  constructor() {
    this.connect().catch((err) => console.error(err));
  }

  private async connect(): Promise<void> {
    await mongoose.connect(process.env.MONGO_URI as string);
    console.log("DB successfully connected");
  }

  async storeSuccessfulCall(
    requestHash: Address,
    txnHash: Address,
    sender: string,
    receiver: string,
    payload: Hex,
    value: bigint,
    attributes: Attributes,
    activeChains: ActiveChains
  ): Promise<boolean> {
    const { finalityDelaySeconds } = attributes.getDelay();
    const doc = new Submission({
      requestHash,
      claimAvailableAt:
        Math.floor(Date.now() / 1000) + Number(finalityDelaySeconds),
      txnSubmittedHash: txnHash,
      activeChains: {
        src: activeChains.src.chainId,
        l1: activeChains.l1.chainId,
        dst: activeChains.dst.chainId,
      },
      sender,
      receiver,
      payload,
      value,
      attributes: attributes.getAttributes(),
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await exponentialBackoff(async () => await doc.save());

    return true;
  }

  async getClaimableRewards(): Promise<SubmissionType[]> {
    return await exponentialBackoff(async () => {
      return await Submission.find({
        claimAvailableAt: { $lte: Math.floor(Date.now() / 1000) },
        rewardClaimedTxnHash: null,
      });
    });
  }

  async updateRewardClaimed(_id: ObjectId, txnHash: Address): Promise<void> {
    const res = await exponentialBackoff(async () => {
      return await Submission.updateOne(
        { _id },
        { rewardClaimedTxnHash: txnHash }
      );
    });

    if (res.modifiedCount === 0) {
      throw new Error("Error updating submission document");
    }
  }
}
