#! /bin/bash

source .env

deploy-protocol() {
    echo "Deploying protocol..."
    forge script script/DeployProtocol.s.sol \
        --sig "run(string,string,address,address)" \
        "${TOKEN_NAME}" "${TOKEN_SYMBOL}" "${GATEWAY_ADDRESS}" "${GAS_SERVICE_ADDRESS}" \
        --rpc-url "${SEPOLIA_RPC_URL}" \
        --private-key "${PRIVATE_KEY}" \
        --broadcast \
        --verify \
        --etherscan-api-key "${API_KEY_ETHERSCAN}" \
        -vvvv
}

deploy-protocol
