#!/usr/bin/env bash

info() {
    # Define colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    echo -e "\n${GREEN}════════════════════════════════════ ENV VARIABLES ════════════════════════════════════${NC}"
    echo -e "${BLUE}PRIVATE_KEY:${NC}         $PRIVATE_KEY"
    echo -e "${BLUE}RPC_URL:${NC}             $RPC_URL"
    echo -e "${BLUE}VERIFIER_URL:${NC}        $VERIFIER_URL"
    echo -e "${BLUE}SCANNER_API_KEY:${NC}     $SCANNER_API_KEY"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════════════════════${NC}\n"
}

# deploy-protocol() {
#     echo "Deploying protocol..."
#     forge script script/DeployProtocol.s.sol \
#         --sig "run(string,string,address,address)" \
#         "${TOKEN_NAME}" "${TOKEN_SYMBOL}" "${GATEWAY_ADDRESS}" "${GAS_SERVICE_ADDRESS}" \
#         --rpc-url "${SEPOLIA_RPC_URL}" \
#         --private-key "${PRIVATE_KEY}" \
#         --broadcast \
#         --verify \
#         --etherscan-api-key "${API_KEY_ETHERSCAN}" \
#         -vvvv
# }

# deploy-token() {
#     echo "Deploying ERC20CrossChain..."
#     forge script script/DeployERC20CrossChain.s.sol \
#         --sig "run(address,address,uint8,string,string)" \
#         "${GATEWAY_ADDRESS}" "${GAS_SERVICE_ADDRESS}" "18" "${TOKEN_NAME}" "${TOKEN_SYMBOL}" \
#         --rpc-url "${SEPOLIA_RPC_URL}" \
#         --private-key "${PRIVATE_KEY}" \
#         --broadcast \
#         --verify \
#         --etherscan-api-key "${API_KEY_ETHERSCAN}" \
#         -vvvv
# }

# deploy-token-bnb() {
#     echo "Deploying ERC20CrossChain..."
#     forge script script/DeployERC20CrossChain.s.sol \
#         --sig "run(address,address,uint8,string,string)" \
#         "${GATEWAY_ADDRESS}" "${GAS_SERVICE_ADDRESS}" "18" "${TOKEN_NAME}" "${TOKEN_SYMBOL}" \
#         --rpc-url "${BNB_RPC_URL}" \
#         --private-key "${PRIVATE_KEY}" \
#         --broadcast \
#         --verify \
#         --verifier-url https://api-testnet.bscscan.com/api \
#         --etherscan-api-key "${API_KEY_BSCSCAN}" \
#         -vvvv
# }

# upgrade-token() {
#     echo "Upgrading ERC20CrossChain..."
#     forge script script/UpgradeERC20CrossChain.s.sol \
#         --sig "run(address,address,address,address,uint8)" \
#         "${PROXY_ADDRESS}" "${PROXY_ADMIN_ADDRESS}" "${GATEWAY_ADDRESS}" "${GAS_SERVICE_ADDRESS}" "18" \
#         --rpc-url "${SEPOLIA_RPC_URL}" \
#         --private-key "${PRIVATE_KEY}" \
#         --broadcast \
#         --verify \
#         --etherscan-api-key "${API_KEY_ETHERSCAN}" \
#         -vvvv
# }

deploy-axelar() {
    local network=$1
    if [ -z "$network" ]; then
        echo "Usage: deploy-axelar <network>"
        echo "Supported networks: sepolia, bnb-testnet"
        exit 1
    fi

    local env_file=".env.${network}"
    if [ -f "$env_file" ]; then
        export $(cat "$env_file" | grep -v '#' | sed 's/\r$//' | xargs)
    else
        echo "${env_file} file not found"
        exit 1
    fi

    info

    # Add balance check
    local balance=$(cast balance ${WALLET_ADDRESS:-$(cast wallet address ${PRIVATE_KEY})} --rpc-url ${RPC_URL})
    local balance_eth=$(cast --from-wei ${balance})
    echo "Current wallet balance: ${balance_eth} ETH"

    # Add gas estimation with buffer
    local gas_estimate=$(forge script script/DeployAxelar.s.sol --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} -vvvv | grep "Estimated amount required" | awk '{print $4}')
    echo "Estimated gas required: ${gas_estimate} ETH"

    if (($(echo "${balance_eth} < ${gas_estimate} * 1.2" | bc -l))); then
        echo "Error: Insufficient funds. Please ensure you have at least ${gas_estimate} ETH (plus buffer for safety)"
        exit 1
    fi

    # Add nonce checking and management
    local wallet_address=${WALLET_ADDRESS:-$(cast wallet address ${PRIVATE_KEY})}
    local current_nonce=$(cast nonce ${wallet_address} --rpc-url ${RPC_URL})
    echo "Current nonce: ${current_nonce}"

    # Optional: Allow manual nonce override
    if [ ! -z "${NONCE}" ]; then
        echo "Using manual nonce override: ${NONCE}"
        NONCE_FLAG="--nonce ${NONCE}"
    else
        NONCE_FLAG=""
    fi

    while true; do
        read -p "Are you sure you want to deploy Axelar contracts? (y/n): " answer
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
        if [ "$answer" = "y" ] || [ "$answer" = "yes" ]; then
            break
        elif [ "$answer" = "n" ] || [ "$answer" = "no" ]; then
            echo "Deployment cancelled"
            exit 0
        fi
        echo "Please answer 'y' or 'n'"
    done

    local deploy_message="Deploying Axelar contracts..."
    if [ "$network" = "bnb-testnet" ]; then
        deploy_message="Deploying Gateway to BNB Smart Chain Testnet..."
    fi

    echo "$deploy_message"
    forge script script/DeployAxelar.s.sol \
        -vvvv \
        --private-key ${PRIVATE_KEY} \
        --broadcast \
        --rpc-url ${RPC_URL} \
        --verify \
        --verifier-url ${VERIFIER_URL} \
        --etherscan-api-key ${SCANNER_API_KEY} \
        --legacy \
        ${NONCE_FLAG}

    if [ $? -ne 0 ]; then
        echo "Error: Transaction failed. Possible nonce issues:"
        echo "Current nonce is: ${current_nonce}"
        echo "Try the following:"
        echo "1. Reset nonce: NONCE=${current_nonce} ./script/deploy.sh ${network}"
        echo "2. Clear pending transactions in your wallet"
        echo "3. Wait for pending transactions to complete"
        exit 1
    fi
}

"$@"
