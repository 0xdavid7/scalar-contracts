#!/usr/bin/env bash
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | sed 's/\r$//' | xargs)
else
    echo ".env file not found"
    exit 1
fi

echo "TOKEN_NAME: $TOKEN_NAME"
echo "TOKEN_SYMBOL: $TOKEN_SYMBOL"
echo "GATEWAY_ADDRESS: $GATEWAY_ADDRESS"
echo "GAS_SERVICE_ADDRESS: $GAS_SERVICE_ADDRESS"
echo "PRIVATE_KEY: $PRIVATE_KEY"
echo "SEPOLIA_RPC_URL: $SEPOLIA_RPC_URL"
echo "API_KEY_ETHERSCAN: $API_KEY_ETHERSCAN"

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

deploy-token() {
    echo "Deploying ERC20CrossChain..."
    forge script script/DeployERC20CrossChain.s.sol \
        --sig "run(address,address,uint8,string,string)" \
        "${GATEWAY_ADDRESS}" "${GAS_SERVICE_ADDRESS}" "18" "${TOKEN_NAME}" "${TOKEN_SYMBOL}" \
        --rpc-url "${SEPOLIA_RPC_URL}" \
        --private-key "${PRIVATE_KEY}" \
        --broadcast \
        --verify \
        --etherscan-api-key "${API_KEY_ETHERSCAN}" \
        -vvvv
}

upgrade-token() {
    echo "Upgrading ERC20CrossChain..."
    forge script script/UpgradeERC20CrossChain.s.sol \
        --sig "run(address,address,address,address,uint8)" \
        "${PROXY_ADDRESS}" "${PROXY_ADMIN_ADDRESS}" "${GATEWAY_ADDRESS}" "${GAS_SERVICE_ADDRESS}" "18" \
        --rpc-url "${SEPOLIA_RPC_URL}" \
        --private-key "${PRIVATE_KEY}" \
        --broadcast \
        --verify \
        --etherscan-api-key "${API_KEY_ETHERSCAN}" \
        -vvvv
}

"$@"
