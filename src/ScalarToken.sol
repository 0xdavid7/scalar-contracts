// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IScalarToken } from "./interfaces/IScalarToken.sol";

/**
 * @title Scalar Token
 * @notice A custom ERC20 token with minting and burning functionalities restricted to the owner.
 */
contract ScalarToken is ERC20, IScalarToken {
    address public owner;
    address public protocolContract;

    error OnlyOwner();

    /**
     * @notice Sets the initial owner and token details.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
    }

    /**
     * @notice Modifier to restrict access to only the contract owner.
     */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    /**
     * @notice Modifier to restrict access to only the owner or the protocol contract.
     */
    modifier onlyOwnerOrProtocol() {
        if (msg.sender != owner && msg.sender != protocolContract) {
            revert OnlyOwner();
        }
        _;
    }

    /**
     * @notice Mint tokens to the specified address. Only callable by the owner.
     * @param to The address to mint tokens to.
     * @param amount The number of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwnerOrProtocol {
        _mint(to, amount);
    }

    /**
     * @notice Burn a specific amount of tokens from the owner's account. Only callable by the owner.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function setProtocolContract(address _protocolContract) external onlyOwner {
        protocolContract = _protocolContract;
    }
}
