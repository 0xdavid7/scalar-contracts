// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ScalarToken.sol";

contract sBTC is ScalarToken {
    constructor() ScalarToken("sBTC", "sBTC") { }
} 