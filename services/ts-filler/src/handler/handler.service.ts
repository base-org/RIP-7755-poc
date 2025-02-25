import {
  decodeAbiParameters,
  toHex,
  zeroAddress,
  type Address,
  type Hex,
} from "viem";

import type SignerService from "../signer/signer.service";
import type DBService from "../database/db.service";
import { Provers, type ActiveChains } from "../common/types/chain";
import RRC7755Inbox from "../abis/RRC7755Inbox";
import Attributes from "../common/utils/attributes";
import bytes32ToAddress from "../common/utils/bytes32ToAddress";
import EntryPoint from "../abis/EntryPoint";
import extractAttributesFromUserOp from "../common/utils/extractAttributesFromUserOp";
import decodeUserOp from "../common/utils/decodeUserOp";
import Calls from "../abis/Calls";

export default class HandlerService {
  constructor(
    private readonly activeChains: ActiveChains,
    private readonly signerService: SignerService,
    private readonly dbService: DBService
  ) {}

  async handleRequest(
    outboxId: Hex,
    sender: Hex,
    receiver: Hex,
    payload: Hex,
    value: bigint,
    attributes: Attributes
  ): Promise<void> {
    // - Confirm outbox is associated with destination chain ID
    // Use Hashi if source chain doesn't expose L1 state OR dst chain doesn't share state with L1
    const proverName =
      this.activeChains.src.exposesL1State &&
      this.activeChains.dst.sharesStateWithL1
        ? this.activeChains.dst.targetProver
        : Provers.Hashi;

    let userOpAttributes = new Attributes([]);

    if (attributes.count() === 0) {
      userOpAttributes = extractAttributesFromUserOp(decodeUserOp(payload));
    }

    const senderAddr = bytes32ToAddress(sender);
    const receiverAddr = bytes32ToAddress(receiver);

    const expectedProverAddr =
      this.activeChains.src.outboxContracts[proverName];

    if (
      expectedProverAddr &&
      senderAddr.toLowerCase() !== expectedProverAddr.toLowerCase()
    ) {
      throw new Error("Unknown Prover contract");
    }

    // - Make sure inboxContract matches the trusted inbox for dst chain Id
    const expectedReceiverAddress =
      attributes.count() > 0
        ? this.activeChains.dst.contracts.inbox.toLowerCase()
        : this.activeChains.dst.contracts.entryPoint.toLowerCase();

    if (expectedReceiverAddress !== receiverAddr.toLowerCase()) {
      throw new Error("Unknown Inbox contract on dst chain");
    }

    // - Confirm l2Oracle is valid for dst chain
    const expectedOracle =
      proverName === Provers.Hashi
        ? zeroAddress
        : this.activeChains.dst.l2Oracle;
    const selectedOracle =
      attributes.count() === 0
        ? userOpAttributes.getL2Oracle().toLowerCase()
        : attributes.getL2Oracle().toLowerCase();
    if (selectedOracle !== expectedOracle.toLowerCase()) {
      throw new Error("Unknown Oracle contract for dst chain");
    }

    const txnHash = await this.submit(
      sender,
      receiverAddr,
      payload,
      attributes
    );

    console.log(
      `Destination chain transaction successful! Storing record in DB. TxHash: ${txnHash}`
    );

    const finalityDelaySeconds = this.getFinalityDelaySeconds(
      proverName,
      attributes,
      userOpAttributes
    );

    // record db instance to be picked up later for reward collection
    const dbSuccess = await this.dbService.storeSuccessfulCall(
      outboxId,
      txnHash,
      sender,
      receiver,
      payload,
      value,
      attributes,
      this.activeChains,
      finalityDelaySeconds
    );

    if (!dbSuccess) {
      throw new Error("Failed to store successful call in db");
    }

    console.log("Record successfully stored to DB");
  }

  private async submit(
    sender: Hex,
    receiver: Address,
    payload: Hex,
    attributes: Attributes
  ): Promise<Hex> {
    if (attributes.count() > 0) {
      return await this.submitStandardTransaction(
        sender,
        receiver,
        payload,
        attributes
      );
    }

    return await this.submitUserOperation(receiver, payload);
  }

  private async submitUserOperation(
    receiver: Address,
    payload: Hex
  ): Promise<Hex> {
    const op = decodeUserOp(payload);
    const attributes = extractAttributesFromUserOp(op);

    const abi = EntryPoint;
    const functionName = "handleOps";
    const args = [[op], this.signerService.getFulfillerAddress()];
    const valueNeeded = 0n;
    return await this.submitTransaction(
      receiver,
      attributes,
      abi,
      functionName,
      args,
      valueNeeded
    );
  }

  private async submitStandardTransaction(
    sender: Hex,
    receiver: Address,
    payload: Hex,
    attributes: Attributes
  ): Promise<Hex> {
    const valueNeeded = this.extractValueNeededFromCalls(payload);

    // Gather transaction params
    const abi = RRC7755Inbox;
    const functionName = "fulfill";
    const args = [
      toHex(this.activeChains.src.chainId, { size: 32 }),
      sender,
      payload,
      attributes.getAttributes(),
      this.signerService.getFulfillerAddress(),
    ];

    return await this.submitTransaction(
      receiver,
      attributes,
      abi,
      functionName,
      args,
      valueNeeded
    );
  }

  private async submitTransaction(
    receiver: Address,
    attributes: Attributes,
    abi: any,
    functionName: string,
    args: any[],
    valueNeeded: bigint
  ): Promise<Hex> {
    const estimatedDestinationGas = await this.signerService.estimateGas(
      receiver,
      abi,
      functionName,
      args,
      valueNeeded
    );

    // - rewardAsset + rewardAmount should make sense given requested calls
    if (!this.isValidReward(attributes, valueNeeded, estimatedDestinationGas)) {
      console.error("Undesirable reward");
      throw new Error("Undesirable reward");
    }

    // submit dst txn
    console.log(
      "Request passed validation - preparing transaction for submission to destination chain"
    );
    const txnHash = await this.signerService.writeContract(
      receiver,
      abi,
      functionName,
      args,
      valueNeeded
    );

    if (!txnHash) {
      throw new Error("Failed to submit transaction");
    }

    return txnHash;
  }

  private extractValueNeededFromCalls(payload: Hex): bigint {
    const [calls] = decodeAbiParameters(Calls, payload);

    // - Add up total value needed
    let valueNeeded = 0n;

    for (let i = 0; i < calls.length; i++) {
      valueNeeded += calls[i].value;
    }

    return valueNeeded;
  }

  private isValidReward(
    attributes: Attributes,
    valueNeeded: bigint,
    estimatedDestinationGas: bigint
  ): boolean {
    console.log("Validating reward");
    const { asset, amount } = attributes.getReward();
    // This is a simplified case to just support ETH rewards. More sophisticated validation needed to support ERC20 rewards
    return (
      asset === "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE".toLowerCase() &&
      amount > valueNeeded + estimatedDestinationGas // likely would want to add some extra threshold here but if this is true then the fulfiller will make money
    );
  }

  private getFinalityDelaySeconds(
    proverName: Provers,
    attributes: Attributes,
    userOpAttributes: Attributes
  ): number {
    switch (proverName) {
      case Provers.Hashi:
        return attributes.count() > 0
          ? attributes.getDelay().finalityDelaySeconds
          : userOpAttributes.getDelay().finalityDelaySeconds;
      case Provers.Arbitrum:
        return 3600; // 1 hour NOTE: This is only used for testnet testing. Arbitrum mainnet uses 1 week
      case Provers.OPStack:
        return 345600; // 4 days
      default:
        throw new Error("Unknown prover");
    }
  }
}
