import { sleep } from "bun";
import { decodeEventLog, type Address, type Hex } from "viem";

import ChainService from "../chain/chain.service";
import chains from "../chain/chains";
import ConfigService from "../config/config.service";
import { SupportedChains } from "../common/types/chain";
import OutboxAbi from "../abis/RIP7755Outbox";
import type { RequestType } from "../common/types/request";
import SignerService from "../signer/signer.service";
import DBService from "../database/db.service";
import HandlerService from "../handler/handler.service";
import config from "../config";
import CAIP10 from "../common/utils/caip10";
import Attributes from "../common/utils/attributes";

export default class IndexerService {
  constructor(
    private readonly dbService: DBService,
    private readonly configService: ConfigService
  ) {}

  async startPoll(
    sourceChain: SupportedChains,
    startingBlock: number,
    outboxAddress: Address
  ) {
    let success = false;

    while (true) {
      try {
        startingBlock = await this.poll(
          sourceChain,
          startingBlock,
          outboxAddress
        );
        success = true;
      } catch (e) {
        console.error(e);

        if (!success) {
          console.error("First process failed - exiting...");
          break;
        }
      } finally {
        await sleep(3000);
      }
    }
  }

  private async poll(
    sourceChain: SupportedChains,
    startingBlock: number,
    outboxAddress: Address
  ): Promise<number> {
    const configChains = {
      src: chains[sourceChain],
      l1: chains[SupportedChains.Sepolia],
      dst: chains[SupportedChains.BaseSepolia],
    };
    const chainService = new ChainService(configChains, this.configService);

    const logs = await chainService.getOutboxLogs(startingBlock, outboxAddress);

    if (logs.length === 0) {
      return startingBlock;
    }

    console.log(`Found ${logs.length} logs to consider`);

    return await this.handleLogs(sourceChain, startingBlock, logs);
  }

  private async handleLogs(
    sourceChain: SupportedChains,
    startingBlock: number,
    logs: any
  ): Promise<number> {
    let maxBlock = startingBlock;
    const calls = [];

    for (let i = 0; i < logs.length; i++) {
      maxBlock = Math.max(maxBlock, Number(BigInt(logs[i].blockNumber)));
      calls.push(this.handleLog(sourceChain, logs[i]));
    }

    const responses = await Promise.allSettled(calls);

    for (let i = 0; i < responses.length; i++) {
      if (responses[i].status !== "fulfilled") {
        console.error("Error processing log", responses[i]);
      }
    }

    return maxBlock + 1;
  }

  private async handleLog(
    sourceChain: SupportedChains,
    log: any
  ): Promise<void> {
    const topics = decodeEventLog({
      abi: OutboxAbi,
      data: log.data,
      topics: log.topics,
    });

    console.log(topics);

    if (!topics.args) {
      throw new Error("Error decoding CrossChainCallRequested logs");
    }

    const { outboxId, sender, receiver, payload, value, attributes } =
      topics.args as {
        outboxId: Hex;
        sender: string;
        receiver: string;
        payload: Hex;
        value: bigint;
        attributes: Hex[];
      };

    const wrappedSender = new CAIP10(sender);
    const wrappedReceiver = new CAIP10(receiver);

    const activeChains = {
      src: chains[sourceChain],
      l1: chains[config.l1],
      dst: chains[wrappedReceiver.getChainId()],
    };

    if (!activeChains.src) {
      throw new Error(`Invalid Source Chain: ${sourceChain}`);
    }
    if (!activeChains.l1) {
      throw new Error(`Invalid L1 Chain: ${config.l1}`);
    }
    if (!activeChains.dst) {
      throw new Error(
        `Invalid Destination Chain: ${wrappedReceiver.getChainId()}`
      );
    }

    const signerService = new SignerService(activeChains.dst);
    const handlerService = new HandlerService(
      activeChains,
      signerService,
      this.dbService
    );

    await handlerService.handleRequest(
      outboxId,
      wrappedSender,
      wrappedReceiver,
      payload,
      value,
      new Attributes(attributes)
    );
  }
}
