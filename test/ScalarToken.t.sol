// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { ScalarToken } from "../src/ScalarToken.sol";

contract ScalarTokenTest is Test {
    ScalarToken public token;
    address public owner;
    address public user;
    address public spender;

    function setUp() public {
        token = new ScalarToken("ScalarToken", "SCALAR");
        owner = token.owner();
        user = address(1);
        spender = address(2);
    }

    function testMint() public {
        token.mint(owner, 100);
        assertEq(token.balanceOf(owner), 100);
    }

    function testBurn() public {
        token.mint(owner, 100);
        token.burn(50);
        assertEq(token.balanceOf(owner), 50);
    }

    function testBurnNotEnough() public {
        vm.prank(user);
        vm.expectRevert("Insufficient balance");
        token.burn(100);
    }

    function testOnlyOwnerMint() public {
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner or protocol contract");
        token.mint(user, 100);
    }
}
