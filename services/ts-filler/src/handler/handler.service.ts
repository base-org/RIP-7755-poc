import type { Address } from "viem";

import type { Request } from "../types/request";
import chains from "../chain/chains";
import type SignerService from "../signer/signer.service";
import type DBService from "../database/db.service";

export default class HandlerService {
  constructor(
    private readonly sourceChainId: number,
    private readonly signerService: SignerService,
    private readonly dbService: DBService
  ) {}

  async handleRequest(requestHash: Address, request: Request): Promise<void> {
    const srcChainConfig = chains[this.sourceChainId];
    const dstChainConfig = chains[Number(request.destinationChainId)];

    if (!srcChainConfig) {
      throw new Error("Unknown source chain");
    }
    if (!dstChainConfig) {
      throw new Error("Unknown destination chain");
    }

    // - Confirm valid proverContract address on source chain
    if (!srcChainConfig.proverContracts[Number(request.destinationChainId)]) {
      throw new Error("Unknown Prover contract");
    }

    // - Use destination chain Id to instantiate wallet client
    // - Make sure inboxContract matches the trusted inbox for dst chain Id
    if (dstChainConfig.inboxContract !== request.inboxContract) {
      throw new Error("Unknown Inbox contract on dst chain");
    }

    // - Confirm l2Oracle and l2OracleStorageKey are valid for dst chain
    if (request.l2Oracle !== dstChainConfig.l2Oracle) {
      throw new Error("Unkown Oracle contract for dst chain");
    }
    if (request.l2OracleStorageKey !== dstChainConfig.l2OracleStorageKey) {
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

    // record db instance to be picked up later for reward collection
    const dbSuccess = await this.dbService.storeSuccessfulCall(requestHash);

    if (!dbSuccess) {
      // Probably want to retry here
      throw new Error("Failed to store successful call in db");
    }
  }

  private isValidReward(request: Request): boolean {
    return true; // TODO
  }
}
