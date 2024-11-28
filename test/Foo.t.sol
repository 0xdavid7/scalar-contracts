// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";
import { Foo } from "../src/Foo.sol";

contract FooTest is Test {
    Foo internal foo;

    function setUp() public virtual {
        foo = new Foo();
    }

    function test_bar() public view {
        console2.log("bar");
        foo.bar();
    }
}
