// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import { IScalarToken } from "./interfaces/IScalarToken.sol";

/**
 * @title Protocol
 * @notice Sends a message from chain A to chain B and handles GMP messages.
 */
contract Protocol is AxelarExecutable {
    IScalarToken public immutable SCALAR_TOKEN;
    IAxelarGasService public immutable GAS_SERVICE;

    event Executed(string indexed _from, string indexed _to, uint256 _amount);
    event Unstaked(address indexed _from, uint256 _amount);

    error InvalidAmount();

    /**
     * @param _gateway address of Axelar gateway on the deployed chain.
     * @param _gasReceiver address of Axelar gas service on the deployed chain.
     * @param _token address of the ERC20 token.
     */
    constructor(address _gateway, address _gasReceiver, address _token) AxelarExecutable(_gateway) {
        GAS_SERVICE = IAxelarGasService(_gasReceiver);
        SCALAR_TOKEN = IScalarToken(_token);
    }

    /**
     * @notice Send payload from chain A to chain B
     * @dev Payload param is passed as GMP message.
     * @param _destinationChain Name of the destination chain (e.g., "WBitcoin").
     * @param _destinationAddress Address on destination chain to send payload to.
     * @param _amount Amount to burn (unstake).
     * @param _encodedPayload Encoded payload to send to the destination chain.
     */
    function unstake(
        string calldata _destinationChain,
        string calldata _destinationAddress,
        uint256 _amount,
        bytes calldata _encodedPayload
    )
        external
    {
        // TODO: Check the amount is equivalent to the amount in the PSBT?
        SCALAR_TOKEN.transferFrom(msg.sender, address(this), _amount);

        // Burn the tokens from the protocol contract.
        SCALAR_TOKEN.burn(_amount); // The protocol contract is now authorized to burn.

        emit Unstaked(msg.sender, _amount);

        // Prepare the payload and call the destination contract via Axelar gateway.

        gateway.callContract(_destinationChain, _destinationAddress, _encodedPayload);
    }

    /**
     * @notice Handle the incoming message from another chain.
     * @param _sourceChain The chain from which the message originated.
     * @param _sourceAddress The address from which the message was sent.
     * @param _payload Encoded payload sent from the source chain.
     */
    function _execute(
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    )
        internal
        override
    {
        address to;
        uint256 amount;

        // Correctly decode the payload
        (to, amount) = abi.decode(_payload, (address, uint256));

        // Assuming mint is a function in the token contract.
        SCALAR_TOKEN.mint(to, amount);

        emit Executed(_sourceChain, _sourceAddress, amount);
    }
}
