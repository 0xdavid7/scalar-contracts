#!/usr/bin/env bash

info() {
    echo "PRIVATE_KEY: $PRIVATE_KEY"
    echo "RPC_URL: $RPC_URL"
    echo "VERIFIER_URL: $VERIFIER_URL"
    echo "SCANNER_API_KEY: $SCANNER_API_KEY"
}

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

deploy-token-bnb() {
    echo "Deploying ERC20CrossChain..."
    forge script script/DeployERC20CrossChain.s.sol \
        --sig "run(address,address,uint8,string,string)" \
        "${GATEWAY_ADDRESS}" "${GAS_SERVICE_ADDRESS}" "18" "${TOKEN_NAME}" "${TOKEN_SYMBOL}" \
        --rpc-url "${BNB_RPC_URL}" \
        --private-key "${PRIVATE_KEY}" \
        --broadcast \
        --verify \
        --verifier-url https://api-testnet.bscscan.com/api \
        --etherscan-api-key "${API_KEY_BSCSCAN}" \
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

deploy-axelar() {
    if [ -f .env.sepolia ]; then
        export $(cat .env.sepolia | grep -v '#' | sed 's/\r$//' | xargs)
    else
        echo ".env.sepolia file not found"
        exit 1
    fi

    info

    echo "Deploying Axelar contracts..."
    forge script script/DeployAxelar.s.sol -vvvv --private-key ${PRIVATE_KEY} --broadcast --rpc-url ${RPC_URL} --verify --verifier-url ${VERIFIER_URL} --etherscan-api-key ${SCANNER_API_KEY}
}

deploy-axelar-bnb() {
    if [ -f .env.bnb-testnet ]; then
        export $(cat .env.bnb-testnet | grep -v '#' | sed 's/\r$//' | xargs)
    else
        echo ".env.bnb-testnet file not found"
        exit 1
    fi

    info

    echo "Deploying Gateway to BNB Smart Chain Testnet..."
    forge script script/DeployAxelar.s.sol \
        -vvvv \
        --private-key ${PRIVATE_KEY} \
        --broadcast \
        --rpc-url ${RPC_URL} \
        --verify \
        --verifier-url ${VERIFIER_URL} \
        --etherscan-api-key ${SCANNER_API_KEY}
}

"$@"
