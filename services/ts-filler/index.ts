import { SupportedChains } from "./src/common/types/chain";
import IndexerService from "./src/indexer/indexer.service";
import DBService from "./src/database/db.service";
import RewardMonitorService from "./src/rewards/monitor.service";
import ConfigService from "./src/config/config.service";
import chains from "./src/chain/chains";

async function main() {
  const sourceChain = SupportedChains.ArbitrumSepolia;
  const dbService = new DBService();
  const configService = new ConfigService();
  const indexerService = new IndexerService(dbService, configService);
  new RewardMonitorService(dbService, configService);

  let startingBlock = Number(
    await chains[sourceChain].publicClient.getBlockNumber()
  );

  const outboxes = Object.values(chains[sourceChain].outboxContracts);

  console.log("Starting polls for outboxes:", outboxes);
  await Promise.allSettled(
    outboxes.map((outbox) =>
      indexerService.startPoll(sourceChain, startingBlock, outbox)
    )
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
