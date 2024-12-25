import { describe, expect, it } from "bun:test";
import { getTestSuite } from "./setup";

describe("ERC20CrossChain", () => {
  const { publicClient, erc20CrossChainContractAddress } = getTestSuite();

  it("should return correct token information", async () => {
    // Get token info
    const name = await publicClient.readContract({
      address: erc20CrossChainContractAddress as `0x${string}`,
      abi: [
        {
          type: "function",
          name: "name",
          inputs: [],
          outputs: [{ type: "string" }],
          stateMutability: "view",
        },
      ],
      functionName: "name",
    });

    const symbol = await publicClient.readContract({
      address: erc20CrossChainContractAddress as `0x${string}`,
      abi: [
        {
          type: "function",
          name: "symbol",
          inputs: [],
          outputs: [{ type: "string" }],
          stateMutability: "view",
        },
      ],
      functionName: "symbol",
    });

    const owner = await publicClient.readContract({
      address: erc20CrossChainContractAddress as `0x${string}`,
      abi: [
        {
          type: "function",
          name: "owner",
          inputs: [],
          outputs: [{ type: "address" }],
          stateMutability: "view",
        },
      ],
      functionName: "owner",
    });

    const decimals = await publicClient.readContract({
      address: erc20CrossChainContractAddress as `0x${string}`,
      abi: [
        {
          type: "function",
          name: "decimals",
          inputs: [],
          outputs: [{ type: "uint8" }],
          stateMutability: "view",
        },
      ],
      functionName: "decimals",
    });

    console.log({
      name,
      symbol,
      owner,
      decimals,
    });

    // Add your assertions
    expect(name).toBe("Pool");
    expect(symbol).toBe("pBTC");
    expect(decimals).toBe(18);
  });
});
