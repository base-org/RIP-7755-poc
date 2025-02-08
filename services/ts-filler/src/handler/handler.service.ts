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
import type CAIP10 from "../common/utils/caip10";
import type Attributes from "../common/utils/attributes";
import bytes32ToAddress from "../common/utils/bytes32ToAddress";

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
    if (
      this.activeChains.dst.contracts.inbox.toLowerCase() !==
      receiverAddr.toLowerCase()
    ) {
      throw new Error("Unknown Inbox contract on dst chain");
    }

    // - Confirm l2Oracle is valid for dst chain
    const expectedOracle =
      proverName === Provers.Hashi
        ? zeroAddress
        : this.activeChains.dst.l2Oracle;
    if (
      attributes.getL2Oracle().toLowerCase() !== expectedOracle.toLowerCase()
    ) {
      throw new Error("Unkown Oracle contract for dst chain");
    }

    const [calls] = decodeAbiParameters(
      [
        {
          name: "calls",
          type: "tuple[]",
          internalType: "struct Call[]",
          components: [
            { name: "to", type: "bytes32", internalType: "bytes32" },
            { name: "data", type: "bytes", internalType: "bytes" },
            { name: "value", type: "uint256", internalType: "uint256" },
          ],
        },
      ],
      payload
    );

    // - Add up total value needed
    let valueNeeded = 0n;

    for (let i = 0; i < calls.length; i++) {
      valueNeeded += calls[i].value;
    }

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
    const estimatedDestinationGas = await this.signerService.estimateGas(
      receiverAddr,
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

    // function fulfill(CrossChainRequest calldata request, address fulfiller) external
    // submit dst txn
    console.log(
      "Request passed validation - preparing transaction for submission to destination chain"
    );
    const txnHash = await this.signerService.sendTransaction(
      receiverAddr,
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
      outboxId,
      txnHash,
      sender,
      receiver,
      payload,
      value,
      attributes,
      this.activeChains
    );

    if (!dbSuccess) {
      throw new Error("Failed to store successful call in db");
    }

    console.log("Record successfully stored to DB");
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
}
