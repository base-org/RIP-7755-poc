import { decodeEventLog, type Address } from "viem";

import ChainService from "../chain/chain.service";
import chains from "../chain/chains";
import ConfigService from "../config/config.service";
import { SupportedChains } from "../types/chain";
import OutboxAbi from "../abis/RIP7755Outbox";
import type { Request } from "../types/request";
import SignerService from "../signer/signer.service";
import DBService from "../database/db.service";
import HandlerService from "../handler/handler.service";

export default class IndexerService {
  constructor(private readonly dbService: DBService) {}

  async poll(sourceChain: SupportedChains, startingBlock: number) {
    const configService = new ConfigService();
    const configChains = {
      src: chains[sourceChain],
      l1: chains[SupportedChains.Sepolia],
      dst: chains[SupportedChains.BaseSepolia],
    };
    const chainService = new ChainService(configChains, configService);

    const logs = await chainService.getOutboxLogs(startingBlock);

    if (logs.length === 0) {
      return startingBlock + 1;
    }

    console.log(`Found ${logs.length} logs to consider`);

    return await this.handleLogs(sourceChain, startingBlock, logs);
  }

  private async handleLogs(
    sourceChain: SupportedChains,
    startingBlock: number,
    logs: any
  ) {
    let maxBlock = startingBlock;

    for (let i = 0; i < logs.length; i++) {
      try {
        maxBlock = await this.handleLog(sourceChain, logs[i], maxBlock);
      } catch (e) {
        console.error("Error handling log:", e);
      }
    }

    return maxBlock + 1;
  }

  private async handleLog(
    sourceChain: SupportedChains,
    log: any,
    maxBlock: number
  ) {
    const topics = decodeEventLog({
      abi: OutboxAbi,
      data: log.data,
      topics: log.topics,
    });

    console.log(topics);

    if (!topics.args) {
      throw new Error("Error decoding CrossChainCallRequested logs");
    }

    const { requestHash, request } = topics.args as {
      requestHash: Address;
      request: Request;
    };

    const activeChains = {
      src: chains[sourceChain],
      l1: chains[SupportedChains.Sepolia],
      dst: chains[Number(request.destinationChainId)],
    };

    if (!activeChains.src) {
      throw new Error(`Invalid Source Chain: ${sourceChain}`);
    }
    if (!activeChains.l1) {
      throw new Error(`Invalid L1 Chain: ${SupportedChains.Sepolia}`);
    }
    if (!activeChains.dst) {
      throw new Error(
        `Invalid Destination Chain: ${Number(request.destinationChainId)}`
      );
    }

    const signerService = new SignerService(activeChains.dst);
    const handlerService = new HandlerService(
      activeChains,
      signerService,
      this.dbService
    );

    await handlerService.handleRequest(requestHash, request);

    return Math.max(maxBlock, Number(BigInt(log.blockNumber)));
  }
}