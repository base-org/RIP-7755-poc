import type { Address } from "viem";

import type { RequestType } from "../common/types/request";
import type SignerService from "../signer/signer.service";
import type DBService from "../database/db.service";
import { Provers, type ActiveChains } from "../common/types/chain";
import RIP7755Inbox from "../abis/RIP7755Inbox";
import bytes32ToAddress from "../common/utils/bytes32ToAddress";

export default class HandlerService {
  constructor(
    private readonly activeChains: ActiveChains,
    private readonly signerService: SignerService,
    private readonly dbService: DBService
  ) {}

  async handleRequest(
    requestHash: Address,
    request: RequestType
  ): Promise<void> {
    // - Confirm outbox is associated with destination chain ID
    // Use Hashi if source chain doesn't expose L1 state OR dst chain doesn't share state with L1
    const proverName =
      this.activeChains.src.exposesL1State &&
      this.activeChains.dst.sharesStateWithL1
        ? this.activeChains.dst.targetProver
        : Provers.Hashi;

    const expectedProverAddr =
      this.activeChains.src.outboxContracts[proverName];

    if (
      expectedProverAddr &&
      bytes32ToAddress(request.origin) !== expectedProverAddr.toLowerCase()
    ) {
      throw new Error("Unknown Prover contract");
    }

    // - Make sure inboxContract matches the trusted inbox for dst chain Id
    if (
      this.activeChains.dst.contracts.inbox.toLowerCase() !==
      bytes32ToAddress(request.inboxContract)
    ) {
      throw new Error("Unknown Inbox contract on dst chain");
    }

    // - Confirm l2Oracle is valid for dst chain
    if (
      bytes32ToAddress(request.l2Oracle) !==
      this.activeChains.dst.l2Oracle.toLowerCase()
    ) {
      throw new Error("Unkown Oracle contract for dst chain");
    }

    // - Add up total value needed
    let valueNeeded = 0n;

    for (let i = 0; i < request.calls.length; i++) {
      valueNeeded += request.calls[i].value;
    }

    // Gather transaction params
    const fulfillerAddr = this.signerService.getFulfillerAddress();
    const address = bytes32ToAddress(request.inboxContract);
    const abi = RIP7755Inbox;
    const functionName = "fulfill";
    const args = [request, fulfillerAddr];
    const estimatedDestinationGas = await this.signerService.estimateGas(
      address,
      abi,
      functionName,
      args,
      valueNeeded
    );

    // - rewardAsset + rewardAmount should make sense given requested calls
    if (!this.isValidReward(request, valueNeeded, estimatedDestinationGas)) {
      console.error("Undesirable reward");
      throw new Error("Undesirable reward");
    }

    // function fulfill(CrossChainRequest calldata request, address fulfiller) external
    // submit dst txn
    console.log(
      "Request passed validation - preparing transaction for submission to destination chain"
    );
    const txnHash = await this.signerService.sendTransaction(
      address,
      abi,
      functionName,
      args,
      valueNeeded
    );

    if (!txnHash) {
      throw new Error("Failed to submit transaction");
    }

    console.log(
      `Destination chain transaction successful! Storing record in DB. TxHash: ${txnHash}`
    );

    // record db instance to be picked up later for reward collection
    const dbSuccess = await this.dbService.storeSuccessfulCall(
      requestHash,
      txnHash,
      request,
      this.activeChains
    );

    if (!dbSuccess) {
      throw new Error("Failed to store successful call in db");
    }

    console.log("Record successfully stored to DB");
  }

  private isValidReward(
    request: RequestType,
    valueNeeded: bigint,
    estimatedDestinationGas: bigint
  ): boolean {
    console.log("Validating reward");
    // This is a simplified case to just support ETH rewards. More sophisticated validation needed to support ERC20 rewards
    return (
      bytes32ToAddress(request.rewardAsset) ===
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE".toLowerCase() &&
      request.rewardAmount > valueNeeded + estimatedDestinationGas // likely would want to add some extra threshold here but if this is true then the fulfiller will make money
    );
  }
}
