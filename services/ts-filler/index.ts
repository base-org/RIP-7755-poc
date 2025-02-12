import { SupportedChains } from "./src/common/types/chain";
import IndexerService from "./src/indexer/indexer.service";
import DBService from "./src/database/db.service";
import RewardMonitorService from "./src/rewards/monitor.service";
import ConfigService from "./src/config/config.service";
import chains from "./src/chain/chains";
import MagicSpendService from "./src/paymaster/magicSpend.service";
import GasSponsorService from "./src/paymaster/gasSponsor.service";

async function main() {
  const sourceChain = SupportedChains.BaseSepolia;
  const dbService = new DBService();
  const configService = new ConfigService();
  const indexerService = new IndexerService(dbService, configService);
  new RewardMonitorService(dbService, configService);
  new MagicSpendService();
  new GasSponsorService();

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
