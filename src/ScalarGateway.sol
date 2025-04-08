// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { AxelarGateway } from "@axelar-network/axelar-cgp-solidity/contracts/AxelarGateway.sol";
import { ECDSA } from "@axelar-network/axelar-cgp-solidity/contracts/ECDSA.sol";
import { IAxelarAuth } from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarAuth.sol";
import { ITokenDeployer } from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/ITokenDeployer.sol";

contract ScalarGateway is AxelarGateway {
    enum Phase {
        Preparing,
        Executing
    }

    struct Session {
        uint64 sequence;
        Phase phase;
    }

    error NotInitializedSession();
    error InvalidPhase();
    error PhaseNotChanged();
    error PhaseAlreadyExists();

    event SwitchPhase(bytes32 indexed custodianGroupId, uint64 indexed sequence, Phase from, Phase to);
    event RegisterCustodianGroup(bytes32 indexed custodianGroupId, uint64 sequence, Phase phase);

    bytes32 internal constant SELECTOR_SWITCH_PHASE = keccak256("switchPhase");
    bytes32 internal constant SELECTOR_REGISTER_CUSTODIAN_GROUP = keccak256("registerCustodianGroup");
    bytes32 internal constant SELECTOR_DEPLOY_TOKEN2 = keccak256("deployToken2");
    bytes32 internal constant SELECTOR_REDEEM_TOKEN = keccak256("redeemToken");

    // mapping of custodian group id to session
    mapping(bytes32 => Session) public sessions;
    // mapping of token symbol to custodian group id
    mapping(string => bytes32) public tokenCustodianGroupIds;

    constructor(address authModule, address tokenDeployer) AxelarGateway(authModule, tokenDeployer) { }

    function execute2(bytes calldata input) external {
        (bytes memory data, bytes memory proof) = abi.decode(input, (bytes, bytes));

        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(data));
        // returns true for current operators
        // slither-disable-next-line reentrancy-no-eth
        bool allowOperatorshipTransfer = IAxelarAuth(authModule).validateProof(messageHash, proof);

        uint256 chainId;
        bytes32[] memory commandIds;
        string[] memory commands;
        bytes[] memory params;

        (chainId, commandIds, commands, params) = abi.decode(data, (uint256, bytes32[], string[], bytes[]));

        if (chainId != block.chainid) revert InvalidChainId();
        uint256 commandsLength = commandIds.length;
        if (commandsLength != commands.length || commandsLength != params.length) revert InvalidCommands();

        for (uint256 i; i < commandsLength; ++i) {
            _executeCommand(commandIds[i], commands[i], params[i], allowOperatorshipTransfer);
            allowOperatorshipTransfer = false;
        }
    }

    function _executeCommand(
        bytes32 commandId,
        string memory command,
        bytes memory params,
        bool allowOperatorshipTransfer
    )
        internal
    {
        if (isCommandExecuted(commandId)) return;

        bytes4 commandSelector = _getCommandSelector(keccak256(abi.encodePacked(command)), allowOperatorshipTransfer);

        if (commandSelector == bytes4(0)) return;

        _setCommandExecuted(commandId, true);

        bool success;

        // check if the command is redeemToken
        if (commandSelector == ScalarGateway.redeemToken.selector) {
            (success,) = address(this).call(abi.encodeWithSelector(commandSelector, params, msg.sender));
        } else {
            (success,) = address(this).call(abi.encodeWithSelector(commandSelector, params, commandId));
        }

        if (success) emit Executed(commandId);
        else _setCommandExecuted(commandId, false);
    }

    function _getCommandSelector(bytes32 commandHash, bool allowOperatorshipTransfer) internal pure returns (bytes4) {
        if (commandHash == SELECTOR_DEPLOY_TOKEN) return AxelarGateway.deployToken.selector;
        if (commandHash == SELECTOR_MINT_TOKEN) return AxelarGateway.mintToken.selector;
        if (commandHash == SELECTOR_APPROVE_CONTRACT_CALL) return AxelarGateway.approveContractCall.selector;
        if (commandHash == SELECTOR_APPROVE_CONTRACT_CALL_WITH_MINT) {
            return AxelarGateway.approveContractCallWithMint.selector;
        }
        if (commandHash == SELECTOR_BURN_TOKEN) return AxelarGateway.burnToken.selector;
        if (commandHash == SELECTOR_TRANSFER_OPERATORSHIP) {
            if (!allowOperatorshipTransfer) return bytes4(0);
            return AxelarGateway.transferOperatorship.selector;
        }
        if (commandHash == SELECTOR_SWITCH_PHASE) return ScalarGateway.switchPhase.selector;
        if (commandHash == SELECTOR_REGISTER_CUSTODIAN_GROUP) return ScalarGateway.registerCustodianGroup.selector;
        if (commandHash == SELECTOR_DEPLOY_TOKEN2) return ScalarGateway.deployToken2.selector;
        if (commandHash == SELECTOR_REDEEM_TOKEN) return ScalarGateway.redeemToken.selector;

        return bytes4(0);
    }

    function redeemToken(bytes calldata params, address account) external onlySelf {
        (
            string memory destinationChain,
            string memory destinationContractAddress,
            bytes memory payload,
            string memory symbol,
            uint256 amount
        ) = abi.decode(params, (string, string, bytes, string, uint256));

        // TODO: validate the burned amount with the total of resevered utxos

        _burnTokenFrom(account, symbol, amount);

        emit ContractCallWithToken(
            account, destinationChain, destinationContractAddress, keccak256(payload), payload, symbol, amount
        );
    }

    function deployToken2(bytes calldata params, bytes32) external onlySelf {
        (
            string memory tokenName,
            string memory symbol,
            uint8 decimals,
            uint256 cap,
            address tokenAddress,
            uint256 mintLimit,
            bytes32 custodianGroupId
        ) = abi.decode(params, (string, string, uint8, uint256, address, uint256, bytes32));

        _safeGetSession(custodianGroupId);

        if (tokenCustodianGroupIds[symbol] != bytes32(0)) revert TokenAlreadyExists(symbol);

        // Ensure that this symbol has not been taken.
        if (tokenAddresses(symbol) != address(0)) revert TokenAlreadyExists(symbol);

        _setTokenMintLimit(symbol, mintLimit);

        if (tokenAddress == address(0)) {
            // If token address is not specified, it indicates a request to deploy one.
            bytes32 salt = keccak256(abi.encodePacked(symbol));

            _setTokenType(symbol, TokenType.InternalBurnableFrom);

            // slither-disable-next-line reentrancy-no-eth,controlled-delegatecall
            (bool success, bytes memory data) = tokenDeployer.delegatecall(
                abi.encodeWithSelector(ITokenDeployer.deployToken.selector, tokenName, symbol, decimals, cap, salt)
            );

            if (!success) revert TokenDeployFailed(symbol);

            tokenAddress = abi.decode(data, (address));
        } else {
            // If token address is specified, ensure that there is a contact at the specified address.
            if (tokenAddress.code.length == uint256(0)) revert TokenContractDoesNotExist(tokenAddress);

            // Mark that this symbol is an external token, which is needed to differentiate between operations on mint
            // and burn.
            _setTokenType(symbol, TokenType.External);
        }

        tokenCustodianGroupIds[symbol] = custodianGroupId;

        // slither-disable-next-line reentrancy-events
        emit TokenDeployed(symbol, tokenAddress);

        _setTokenAddress(symbol, tokenAddress);
    }

    function getSession(bytes32 _custodianGroupId) external view returns (Session memory) {
        return _safeGetSession(_custodianGroupId);
    }

    function registerCustodianGroup(bytes calldata params, bytes32) external onlySelf {
        bytes32 custodianGroupId = abi.decode(params, (bytes32));

        Session memory session = _getSession(custodianGroupId);
        if (session.sequence != 0) {
            revert PhaseAlreadyExists();
        }

        session.sequence = 1;
        session.phase = Phase.Preparing;
        _setSession(custodianGroupId, session);
        // we set the phase from Executing to Preparing because of intialized session
        emit SwitchPhase(custodianGroupId, session.sequence, Phase.Executing, Phase.Preparing);
        emit RegisterCustodianGroup(custodianGroupId, session.sequence, session.phase);
    }

    function switchPhase(bytes calldata params, bytes32) external {
        (uint8 newPhase, bytes32 custodianGroupId) = abi.decode(params, (uint8, bytes32));

        if (newPhase > uint8(type(Phase).max)) {
            revert InvalidPhase();
        }

        Session memory session = _safeGetSession(custodianGroupId);
        Phase oldPhase = session.phase;
        Phase targetPhase = Phase(newPhase);

        if (oldPhase == targetPhase) {
            revert PhaseNotChanged();
        }

        session.phase = targetPhase;
        if (targetPhase == Phase.Preparing) {
            session.sequence += 1;
        }
        _setSession(custodianGroupId, session);
        emit SwitchPhase(custodianGroupId, session.sequence, oldPhase, targetPhase);
    }

    function _safeGetSession(bytes32 _custodianGroupId) internal view returns (Session memory) {
        Session memory session = _getSession(_custodianGroupId);
        if (session.sequence == 0) {
            revert NotInitializedSession();
        }
        return session;
    }

    function _getSession(bytes32 _custodianGroupId) internal view returns (Session memory) {
        return sessions[_custodianGroupId];
    }

    function _setSession(bytes32 _custodianGroupId, Session memory _session) internal {
        sessions[_custodianGroupId] = _session;
    }
}
