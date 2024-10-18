import config from "./src/config";
import HandlerService from "./src/handler/handler.service";
import SignerService from "./src/signer/signer.service";
import DBService from "./src/database/db.service";
import { parseEther, zeroAddress, type Address } from "viem";
import chains from "./src/chain/chains";
import { SupportedChains } from "./src/types/chain";

async function main() {
  const sourceChainId = config.sourceChain;

  // This info will come from contract event
  const requestHash =
    "0xd758704a57f68d8454a2e178564de8917b3f5403c103f296ec973c5c0844850c";
  const request = {
    requester: "0x" as Address,
    calls: [],
    destinationChainId: 421614n, // arbitrum sepolia chain ID
    proverContract: "0x" as Address,
    inboxContract: "0x49e2cdc9e81825b6c718ae8244fe0d5b062f4874" as Address, // RIP7755Inbox on Arbitrum Sepolia
    l2Oracle: "0xd80810638dbdf9081b72c1b33c65375e807281c8" as Address, // Arbitrum Rollup on Sepolia
    l2OracleStorageKey:
      "0x0000000000000000000000000000000000000000000000000000000000000076" as Address, // Arbitrum Rollup _nodes storage slot
    rewardAsset: "0x" as Address,
    rewardAmount: parseEther("1"),
    finalityDelaySeconds: 10n,
    nonce: 1n,
    expiry: 1828828574n,
    precheckContract: zeroAddress,
    precheckData: "0x" as Address,
  };

  const activeChains = {
    src: chains[sourceChainId],
    l1: chains[SupportedChains.Sepolia],
    dst: chains[Number(request.destinationChainId)],
  };

  if (!activeChains.src) {
    throw new Error(`Invalid Source Chain: ${sourceChainId}`);
  }
  if (!activeChains.l1) {
    throw new Error(`Invalid L1 Chain: ${SupportedChains.Sepolia}`);
  }
  if (!activeChains.dst) {
    throw new Error(
      `Invalid Destination Chain: ${Number(request.destinationChainId)}`
    );
  }

  const signerService = new SignerService();
  const dbService = new DBService();
  const handlerService = new HandlerService(
    activeChains,
    signerService,
    dbService
  );

  await handlerService.handleRequest(requestHash, request);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
