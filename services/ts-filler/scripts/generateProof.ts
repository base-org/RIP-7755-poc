import ChainService from "../src/chain/chain.service";
import Prover from "../src/prover/prover.service";
import config from "../src/config";
import chains from "../src/chain/chains";
import ConfigService from "../src/config/config.service";
import { replaceBigInts } from "../src/common/utils/bigIntReplacer";

// Generate and store proof in json file to be used for testing
async function main() {
  const activeChains = {
    src: chains[config.sourceChain],
    l1: chains[config.l1],
    dst: chains[config.dstChain],
  };

  if (!activeChains.src) {
    throw new Error(`Invalid Source Chain: ${config.sourceChain}`);
  }
  if (!activeChains.l1) {
    throw new Error(`Invalid L1 Chain: ${config.l1}`);
  }
  if (!activeChains.dst) {
    throw new Error(`Invalid Destination Chain: ${config.dstChain}`);
  }

  const configService = new ConfigService();
  const chainService = new ChainService(activeChains, configService);
  const prover = new Prover(activeChains, chainService, config.devnet);
  const proof = await prover.generateProof(config.requestHash);

  await Bun.write("./Proof.json", JSON.stringify(proof, replaceBigInts));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
