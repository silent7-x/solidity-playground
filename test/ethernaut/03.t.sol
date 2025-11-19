// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {CoinFlip, CoinFlipAttack} from "../../src/ethernaut/03.sol";

contract CoinFlipTest is Test {
    CoinFlip public coinFlipContract;
    CoinFlipAttack public coinFlipAttackContract;

    function setUp() public {
        coinFlipContract = new CoinFlip();
        coinFlipAttackContract = new CoinFlipAttack(address(coinFlipContract));
        console.log(
            "CoinFlip contract deployed at: ",
            address(coinFlipContract)
        );
        console.log(
            "CoinFlipAttack contract deployed at: ",
            address(coinFlipAttackContract)
        );
    }

    function testHackFlip() public {
        // We need 10 consecutive wins
        for (uint256 i = 0; i < 10; i++) {
            // Advance to next block (each flip must be in a different block)
            vm.roll(block.number + 1);

            uint256 winsBefore = coinFlipContract.consecutiveWins();
            console.log("Wins before flip", i + 1, ":", winsBefore);

            // Attack contract calculates the correct guess and calls flip
            coinFlipAttackContract.attack();

            uint256 winsAfter = coinFlipContract.consecutiveWins();
            console.log("Wins after flip", i + 1, ":", winsAfter);

            // Verify we won
            assertEq(winsAfter, winsBefore + 1, "Should win each flip");
        }

        // Verify we have 10 consecutive wins
        assertEq(
            coinFlipContract.consecutiveWins(),
            10,
            "Should have 10 consecutive wins"
        );
    }
}
