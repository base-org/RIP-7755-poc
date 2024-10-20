import mongoose from "mongoose";
import type { Address } from "viem";

import type { Request } from "../types/request";
import { Submission } from "./submissions.schema";

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
    request: Request
  ): Promise<boolean> {
    const doc = new Submission({
      requestHash,
      claimAvailableAt:
        Math.floor(Date.now() / 1000) + Number(request.finalityDelaySeconds),
      txnSubmittedHash: txnHash,
      request,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await doc.save();

    return true;
  }
}
