// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Force, ForceAttacker} from "../../src/ethernaut/07.sol";

contract ForceTest is Test {
    Force public forceContract;

    function setUp() public {
        forceContract = new Force();
    }

    function testHack() public {
        ForceAttacker attacker = new ForceAttacker{value: 1 wei}(address(forceContract));
        console.log("Force contract balance before attack: ", address(forceContract).balance);

        attacker.attack();

        console.log("Force contract balance after attack: ", address(forceContract).balance);
        assertEq(address(forceContract).balance, 1 wei);
    }
}
