import { describe, test } from "bun:test";
import { getConfig } from "./config";

describe('broadcast_tx', () => {
    const { publicClient } = getConfig()
    test('broadcast_tx', async () => {
        try {
            const rawData = await Bun.file('./test/broadcast_tx.txt').text()
            const hash = await publicClient.sendRawTransaction({
                serializedTransaction: rawData as `0x${string}`
            })
        } catch (e) {
            console.log("Error: ", e)
        }
    })
})