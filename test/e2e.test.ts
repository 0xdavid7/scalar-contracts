import { describe, expect, it } from "bun:test";
import { parseUnits } from "viem";
import { getTestSuite } from "./setup";
import { ERC20CrossChainABI } from "./abi";

describe("TransferRemote", () => {
  const { publicClient, walletClient, account, erc20CrossChainContractAddress } = getTestSuite();
  it("should successfully transfer remote", async () => {
    // Prepare test data
    const destinationChain = "bitcoin|4";
    const destinationContractAddress = "0x0000000000000000000000000000000000000000";
    const amount = parseUnits("7", 5);
    const encodedMetadata =
      "0x0000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000231234567890123456789012345678901234567890123456789012345678901234567890000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010400000000000000000000000000000000000000000000000000000000000000";

    // Simulate transaction to estimate gas
    const { request } = await publicClient.simulateContract({
      address: erc20CrossChainContractAddress as `0x${string}`,
      abi: ERC20CrossChainABI,
      functionName: "transferRemote",
      args: [destinationChain, destinationContractAddress, amount, encodedMetadata],
      account: account.address,
    });

    // Send transaction
    const hash = await walletClient.writeContract(request);

    // Wait for transaction
    const receipt = await publicClient.waitForTransactionReceipt({ hash });

    // Assertions
    expect(receipt.status).toBe("success");
    expect(receipt.to).toBe(erc20CrossChainContractAddress as `0x${string}`);
  });
});
