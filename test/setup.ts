import { createPublicClient, createWalletClient, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";

import { sepolia } from "viem/chains";
import { ProjectENV } from "./env";

export function getTestSuite() {
  const account = privateKeyToAccount(`0x${ProjectENV.PRIVATE_KEY}`);

  const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(process.env.ETHEREUM_RPC_URL),
  });

  const walletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http(process.env.ETHEREUM_RPC_URL),
  });

  const testSuite = {
    publicClient,
    walletClient,
    protocolContractAddress: ProjectENV.PROTOCOL_ADDRESS,
    gatewayContractAddress: ProjectENV.GATEWAY_ADDRESS,
    account,
  };

  return testSuite;
}
