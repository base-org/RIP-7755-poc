import ChainService from "../src/chain/chain.service";
import Prover from "../src/prover/prover.service";
import config from "../src/config";

// Generate and store proof in json file to be used for testing
async function main() {
  const chainService = new ChainService();
  const prover = new Prover(config.sourceChain, chainService);
  const proof = await prover.generateProof();

  await Bun.write("./Proof.json", JSON.stringify(proof));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
