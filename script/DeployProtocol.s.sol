// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { BaseScript } from "./Base.s.sol";
import { ScalarToken } from "../src/ScalarToken.sol";
import { Protocol } from "../src/Protocol.sol";

contract DeployProtocol is BaseScript {
    function run(
        string memory tokenName,
        string memory tokenSymbol,
        address gatewayAddress,
        address gasServiceAddress
    )
        public
        broadcast
        returns (ScalarToken, Protocol)
    {
        ScalarToken token = new ScalarToken(tokenName, tokenSymbol);

        Protocol protocol = new Protocol(gatewayAddress, gasServiceAddress, address(token));

        token.setProtocolContract(address(protocol));

        return (token, protocol);
    }
}
