// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ScalarToken.sol";

contract pBTC is ScalarToken {
    constructor() ScalarToken("pBTC", "pBTC") { }
}
