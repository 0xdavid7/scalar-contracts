ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Default deployment values (can be overridden via command line)
TOKEN_NAME ?= "Scalar BTC"
TOKEN_SYMBOL ?= "sBTC"
REDEPLOY_AXELAR ?= true

# Chain ID constants
ANVIL_CHAIN_ID := 1337
SEPOLIA_CHAIN_ID := 11155111

.PHONY: info clean remapping

info:
	$(info 🌟🌟🌟 ENV VARIABLES 🌟🌟🌟)
	$(info PRIVATE_KEY: $(PRIVATE_KEY))
	$(info ANVIL_RPC_URL: $(ANVIL_RPC_URL))
	$(info SEPOLIA_RPC_URL: $(SEPOLIA_RPC_URL))
	$(info API_KEY_ETHERSCAN: $(API_KEY_ETHERSCAN))
	$(info TOKEN_NAME: $(TOKEN_NAME))
	$(info TOKEN_SYMBOL: $(TOKEN_SYMBOL))
	$(info REDEPLOY_AXELAR: $(REDEPLOY_AXELAR))
	$(info ANVIL_CHAIN_ID: $(ANVIL_CHAIN_ID))
	$(info SEPOLIA_CHAIN_ID: $(SEPOLIA_CHAIN_ID))
	$(info ==============================================)
	@echo "\n"

# Clean the build artifacts
clean:
	forge clean

remapping:
	rm -rf remappings.txt
	echo "forge remappings > remappings.txt"



########################################################################
# 																	   #	
# 																	   #	
# 							TEST COMMANDS							   #	
# 																	   #	
# 																	   #	
########################################################################

.PHONY: test test-all test-verbose test-files clean deploy-anvil deploy-sepolia deploy deploy-axelar

test:
	@if [ -n "$(filter-out test,$(MAKECMDGOALS))" ]; then \
		file=$(filter-out test,$(MAKECMDGOALS)); \
		echo "Testing $$file.t.sol:"; \
		forge test --match-path test/$$file.t.sol -vvvv; \
	else \
		forge test; \
	fi

%:
	@:

test-all:
	forge test --match-path "test/*.t.sol"

test-verbose:
	forge test --match-path "test/*.t.sol" -vvvv

test-files:
	@if [ -z "$(files)" ]; then \
		echo "Usage: make test-files files='Foo Bar Baz'"; \
		echo "Example: make test-files files='Foo Bar'"; \
		exit 1; \
	fi
	@for file in $(files); do \
		echo "\nTesting $$file.t.sol:"; \
		forge test --match-path test/$$file.t.sol -vvvv; \
	done


#############################################################################
# 																		    #	
# 																		    #	
# 							DEPLOYMENT COMMANDS								#	
# 																		    #	
# 																		    #	
#############################################################################



# Deployment commands
.PHONY: deploy-anvil deploy-sepolia deploy deploy-axelar 

# Define network detection variable
IS_LOCAL_NETWORK := $(shell curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' http://localhost:8545 >/dev/null 2>&1 && echo "true" || echo "false")


deploy-axelar: 
	@echo "IS_LOCAL_NETWORK: $(IS_LOCAL_NETWORK)"
	@if [ "$(REDEPLOY_AXELAR)" = "true" ]; then \
		echo "Deploying Axelar contracts..."; \
		if [ "$(IS_LOCAL_NETWORK)" = "true" ]; then \
			forge script script/DeployAxelar.s.sol -vvvv --private-key ${PRIVATE_KEY} --broadcast --fork-url ${ANVIL_RPC_URL}; \
		else \
			forge script script/DeployAxelar.s.sol -vvvv --private-key ${PRIVATE_KEY} --broadcast --rpc-url ${SEPOLIA_RPC_URL} --verify --etherscan-api-key ${API_KEY_ETHERSCAN}; \
		fi \
	else \
		echo "Skipping Axelar deployment..."; \
	fi



get-contract-address:
	@$(eval CONTRACT_ADDR := $(shell cat broadcast/DeployAxelar.s.sol/$(CHAIN_ID)/run-latest.json | jq -r '.transactions[] | select(.contractName=="$(CONTRACT_NAME)") | .contractAddress'))
	@echo $(CONTRACT_ADDR)

get-addresses:
	@$(eval CHAIN_ID := $(if $(filter true,$(IS_LOCAL_NETWORK)),$(ANVIL_CHAIN_ID),$(SEPOLIA_CHAIN_ID)))
	@echo "\nCHAIN_ID: $(CHAIN_ID) 🧪"
	@$(eval GAS_SERVICE_ADDRESS := $(shell make -s get-contract-address CHAIN_ID=$(CHAIN_ID) CONTRACT_NAME=AxelarGasService))
	@$(eval GATEWAY_ADDRESS := $(shell make -s get-contract-address CHAIN_ID=$(CHAIN_ID) CONTRACT_NAME=AxelarGateway))
	@echo "GAS_SERVICE_ADDRESS: $(GAS_SERVICE_ADDRESS)"
	@echo "GATEWAY_ADDRESS: $(GATEWAY_ADDRESS)"
	

deploy-anvil: deploy-axelar get-addresses
	@echo "Deploying Protocol to local Anvil network..."
	@echo "TOKEN_NAME: $(TOKEN_NAME)"
	@echo "TOKEN_SYMBOL: $(TOKEN_SYMBOL)"
	@echo "GAS_SERVICE_ADDRESS: $(GAS_SERVICE_ADDRESS)"
	@echo "GATEWAY_ADDRESS: $(GATEWAY_ADDRESS)"
	@forge script script/DeployProtocol.s.sol \
		--sig "run(string,string,address,address)" \
		$(TOKEN_NAME) $(TOKEN_SYMBOL) $(GATEWAY_ADDRESS) $(GAS_SERVICE_ADDRESS) \
		--fork-url ${ANVIL_RPC_URL} \
		--private-key ${PRIVATE_KEY} \
		--broadcast \
		-vvvv

# Deploy to Sepolia testnet
deploy-sepolia: deploy-axelar
	@echo "Deploying Protocol to Sepolia testnet..."
	@forge script script/DeployProtocol.s.sol \
		--sig "run(string,string,address,address)" \
		$(TOKEN_NAME) $(TOKEN_SYMBOL) $(GATEWAY_ADDRESS) $(GAS_SERVICE_ADDRESS) \
		--rpc-url ${SEPOLIA_RPC_URL} \
		--private-key ${PRIVATE_KEY} \
		--broadcast \
		--verify \
		--etherscan-api-key ${API_KEY_ETHERSCAN} \
		-vvvv

# Smart deploy - checks if local or testnet
deploy: info
	@if [ "$(IS_LOCAL_NETWORK)" = "true" ]; then \
		echo "--- 🛜 Local network detected 🎲 🎲 🎲 ---"; \
		REDEPLOY_AXELAR=$(REDEPLOY_AXELAR) make deploy-anvil; \
	else \
		echo "--- ✅ Using Sepolia network 🚀 🚀 🚀 ---"; \
		REDEPLOY_AXELAR=$(REDEPLOY_AXELAR) make deploy-sepolia; \
	fi

anvil:
	anvil --host 0.0.0.0 --chain-id 1337
