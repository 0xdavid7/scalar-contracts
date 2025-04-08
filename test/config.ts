import {
    createPublicClient,
    createWalletClient,
    http
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { sepolia } from "viem/chains";
import { ProjectEnv } from "./env";

export function getConfig() {
    const rpc = `https://eth-sepolia.g.alchemy.com/v2/${ProjectEnv.ALCHEMY_API_KEY}`
    const account = privateKeyToAccount(ProjectEnv.PRIVATE_KEY as `0x${string}`);
    const caller = createWalletClient({
        account: account,
        chain: sepolia,
        transport: http(rpc),
    });
    const publicClient = createPublicClient({
        chain: sepolia,
        transport: http(rpc),
    });

    return {
        account,
        caller,
        publicClient,
    };
}