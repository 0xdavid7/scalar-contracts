// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AxelarGateway } from "@axelar-network/axelar-cgp-solidity/contracts/AxelarGateway.sol";
import { ECDSA } from "@axelar-network/axelar-cgp-solidity/contracts/ECDSA.sol";
import { IAxelarAuth } from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarAuth.sol";

contract ScalarGateway is AxelarGateway {
  enum Phase {
    Preparing,
    Executing,
    Switching
  }

  struct Session {
    uint64 sequence;
    Phase phase;
  }

  event SwitchPhase(uint64 indexed sequence, Phase phase);

  // mapping of symbol to session
  mapping(bytes32 => Session) public sessions;

  constructor(address authModule, address tokenDeployer) AxelarGateway(authModule, tokenDeployer) {}

  // TODO: Add set_session function
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
      bytes32 commandId = commandIds[i];

      // Ignore if duplicate commandId received
      if (isCommandExecuted(commandId)) continue;

      bytes4 commandSelector;
      bytes32 commandHash = keccak256(abi.encodePacked(commands[i]));

      if (commandHash == SELECTOR_DEPLOY_TOKEN) {
        commandSelector = AxelarGateway.deployToken.selector;
      } else if (commandHash == SELECTOR_MINT_TOKEN) {
        commandSelector = AxelarGateway.mintToken.selector;
      } else if (commandHash == SELECTOR_APPROVE_CONTRACT_CALL) {
        commandSelector = AxelarGateway.approveContractCall.selector;
      } else if (commandHash == SELECTOR_APPROVE_CONTRACT_CALL_WITH_MINT) {
        commandSelector = AxelarGateway.approveContractCallWithMint.selector;
      } else if (commandHash == SELECTOR_BURN_TOKEN) {
        commandSelector = AxelarGateway.burnToken.selector;
      } else if (commandHash == SELECTOR_TRANSFER_OPERATORSHIP) {
        if (!allowOperatorshipTransfer) continue;

        allowOperatorshipTransfer = false;
        commandSelector = AxelarGateway.transferOperatorship.selector;
      } else {
        // Ignore unknown commands
        continue;
      }

      // Prevent a re-entrancy from executing this command before it can be marked as successful.
      _setCommandExecuted(commandId, true);

      // slither-disable-next-line calls-loop,reentrancy-no-eth
      (bool success, ) = address(this).call(abi.encodeWithSelector(commandSelector, params[i], commandId));

      // slither-disable-next-line reentrancy-events
      if (success) emit Executed(commandId);
      else _setCommandExecuted(commandId, false);
    }
  }

  function getSession(string calldata symbol) external view returns (Session memory) {
    return sessions[keccak256(bytes(symbol))];
  }

  // TODO: add _setSession function
  //   function _setSession(string calldata symbol, Session memory session) internal {
  //     sessions[keccak256(bytes(symbol))] = session;
  //   }
}
