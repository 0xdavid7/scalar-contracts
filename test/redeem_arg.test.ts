import { describe, expect, test } from "bun:test";
import { decodeAbiParameters, decodeFunctionData } from "viem";
import { abi } from "./abi";

describe('test-args', () => {
    test('test-args', async () => {
        // read args from redeem_arg.txt
        const rawData = await Bun.file('./test/redeem_arg.txt').text()
        // decode args
        const { functionName, args } = decodeFunctionData({
            abi: abi,
            data: rawData as `0x${string}`
        })

        console.log(functionName)
        const [data, proof] = decodeAbiParameters(
            [
                { name: 'data', type: 'bytes' },
                { name: 'proof', type: 'bytes' },
            ],
            args[0] as `0x${string}`,
        )

        const [operators, weights, threshold, signatures] = decodeAbiParameters(
            [
                { name: 'operators', type: 'address[]' },
                { name: 'weights', type: 'uint256[]' },
                { name: 'threshold', type: 'uint256' },
                { name: 'signatures', type: 'bytes[]' },
            ],
            proof
        )

        console.log({ operators, weights, threshold, signatures })



        const [chainId, commandIds, commands, params] = decodeAbiParameters(
            [
                { name: 'chainId', type: 'uint256' },
                { name: 'commandIds', type: 'bytes32[]' },
                { name: 'commands', type: 'string[]' },
                { name: 'params', type: 'bytes[]' },
            ],
            data
        )

        console.log({ chainId, commandIds, commands, params })


        // (
        //     string memory destinationChain,
        //     string memory destinationContractAddress,
        //     bytes memory payload,
        //     string memory symbol,
        //     uint256 amount
        // ) = abi.decode(params, (string, string, bytes, string, uint256)); 

        const [destinationChain, destinationContractAddress, payload, symbol, amount] = decodeAbiParameters(
            [
                { name: 'destinationChain', type: 'string' },
                { name: 'destinationContractAddress', type: 'string' },
                { name: 'payload', type: 'bytes' },
                { name: 'symbol', type: 'string' },
                { name:'amount', type:'uint256' },
            ],
            params[0] as `0x${string}`
        )

        console.log({ destinationChain, destinationContractAddress, payload, symbol, amount })
    })
})