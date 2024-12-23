import { describe, expect, it } from "bun:test";
import { parseUnits } from "viem";
import { getTestSuite } from "./setup";

const protocolABI = [
  {
    type: "function",
    name: "unstake",
    inputs: [
      { name: "_destinationChain", type: "string" },
      { name: "_destinationAddress", type: "string" },
      { name: "_amount", type: "uint256" },
      { name: "_encodedPayload", type: "bytes" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
] as const;

describe("Unstake", () => {
  const { publicClient, walletClient, account, protocolContractAddress } = getTestSuite();
  it("should successfully unstake", async () => {
    // Prepare test data
    const destinationChain = "bitcoin|4";
    const destinationAddress = "tb1q2rwweg2c48y8966qt4fzj0f4zyg9wty7tykzwg";
    const amount = parseUnits("1", 5);
    const encodedPayload = "0x01020304";

    // Simulate transaction to estimate gas
    const { request } = await publicClient.simulateContract({
      address: protocolContractAddress as `0x${string}`,
      abi: protocolABI,
      functionName: "unstake",
      args: [destinationChain, destinationAddress, amount, encodedPayload],
      account: account.address,
    });

    // Send transaction
    const hash = await walletClient.writeContract(request);

    // Wait for transaction
    const receipt = await publicClient.waitForTransactionReceipt({ hash });

    // Assertions
    expect(receipt.status).toBe("success");
    expect(receipt.to).toBe(protocolContractAddress as `0x${string}`);
  });
});
