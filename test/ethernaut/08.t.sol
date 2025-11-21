// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../../src/ethernaut/08.sol";

contract VaultTest is Test {
    Vault public vault;

    bytes32 internal constant SECRET =
        keccak256(abi.encodePacked("ethernaut-level-08"));

    function setUp() public {
        vault = new Vault(SECRET);
    }

    function testHackUnlocksVault() public {
        assertTrue(vault.locked());

        // Storage layout:
        // slot 0 -> bool locked
        // slot 1 -> bytes32 password
        bytes32 storedPassword = vm.load(address(vault), bytes32(uint256(1)));
        console.logBytes32(storedPassword);

        vault.unlock(storedPassword);

        assertFalse(vault.locked(), "Vault should be unlocked");
    }
}
