// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IScalarToken
 * @notice Interface for the Scalar token with minting and burning functionalities.
 */
interface IScalarToken is IERC20 {
    /**
     * @notice Mint tokens to the specified address. Only callable by the owner.
     * @param to The address to mint tokens to.
     * @param amount The number of tokens to mint.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burn a specific amount of tokens from the owner's account. Only callable by the owner.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external;
}
