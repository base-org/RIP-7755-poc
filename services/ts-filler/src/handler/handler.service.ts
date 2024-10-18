import type { Address } from "viem";

import type { Request } from "../types/request";
import type SignerService from "../signer/signer.service";
import type DBService from "../database/db.service";
import type { ActiveChains } from "../types/chain";

export default class HandlerService {
  constructor(
    private readonly activeChains: ActiveChains,
    private readonly signerService: SignerService,
    private readonly dbService: DBService
  ) {}

  async handleRequest(requestHash: Address, request: Request): Promise<void> {
    // - Confirm valid proverContract address on source chain
    if (
      !this.activeChains.src.proverContracts[Number(request.destinationChainId)]
    ) {
      throw new Error("Unknown Prover contract");
    }

    // - Make sure inboxContract matches the trusted inbox for dst chain Id
    if (
      this.activeChains.dst.inboxContract.toLowerCase() !==
      request.inboxContract.toLowerCase()
    ) {
      throw new Error("Unknown Inbox contract on dst chain");
    }

    // - Confirm l2Oracle and l2OracleStorageKey are valid for dst chain
    if (
      request.l2Oracle.toLowerCase() !==
      this.activeChains.dst.l2Oracle.toLowerCase()
    ) {
      throw new Error("Unkown Oracle contract for dst chain");
    }
    if (
      request.l2OracleStorageKey.toLowerCase() !==
      this.activeChains.dst.l2OracleStorageKey.toLowerCase()
    ) {
      throw new Error("Unknown storage key for dst L2Oracle");
    }

    // - Add up total value needed
    let valueNeeded = 0n;

    for (let i = 0; i < request.calls.length; i++) {
      valueNeeded += request.calls[i].value;
    }

    // - rewardAsset + rewardAmount should make sense given requested calls
    if (!this.isValidReward(request)) {
      throw new Error("Undesirable reward");
    }

    // function fulfill(CrossChainRequest calldata request, address fulfiller) external
    // submit dst txn
    console.log(
      "Request passed validation - preparing transaction for submission to destination chain"
    );
    const fulfillerAddr = this.signerService.getFulfillerAddress();
    const txnSuccess = await this.signerService.sendTransaction(
      Number(request.destinationChainId),
      request.inboxContract,
      "fulfill",
      [request, fulfillerAddr],
      valueNeeded
    );

    if (!txnSuccess) {
      // Probably want to retry here
      throw new Error("Failed to submit transaction");
    }

    console.log(
      "Destination chain transaction successful! Storing record in DB"
    );

    // record db instance to be picked up later for reward collection
    const dbSuccess = await this.dbService.storeSuccessfulCall(requestHash);

    if (!dbSuccess) {
      // Probably want to retry here
      throw new Error("Failed to store successful call in db");
    }

    console.log("Record successfully stored to DB");
  }

  private isValidReward(request: Request): boolean {
    console.log("Validating reward");
    return true; // TODO
  }
}
