// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UnsafeVault, SafeVault} from "../../src/security/SafeERC20Demo.sol";

// Mock USDT that behaves exactly like real USDT (returns nothing)
contract USDTMock {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    // Exactly like real USDT: returns nothing
    function transfer(address to, uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        // No return statement
    }
}

contract USDTTest is Test {
    USDTMock usdt;
    UnsafeVault unsafeVault;
    SafeVault safeVault;
    address user = address(1);

    function setUp() public {
        usdt = new USDTMock();
        unsafeVault = new UnsafeVault(address(usdt));
        safeVault = new SafeVault(address(usdt));

        // Give USDT to vaults
        usdt.mint(address(unsafeVault), 1000 * 1e6);
        usdt.mint(address(safeVault), 1000 * 1e6);
    }

    function test_UnsafeVault_WorksButCannotVerify_WithUSDT() public {
        // With USDT, the transfer works, but we can't verify success
        // because USDT doesn't return a bool. The low-level call returns success=true
        // even if the transfer fails (in some edge cases)
        unsafeVault.withdraw(500 * 1e6, user);

        // We must manually verify that the transfer succeeded
        assertEq(usdt.balanceOf(user), 500 * 1e6, "Transfer worked, but we can't verify success from return value");
    }

    function test_SafeVault_Works_WithUSDT() public {
        // Arrange: Setup initial balances
        uint256 vaultBalanceBefore = usdt.balanceOf(address(safeVault));
        uint256 userBalanceBefore = usdt.balanceOf(user);
        uint256 amount = 500 * 1e6;

        assertEq(vaultBalanceBefore, 1000 * 1e6, "Vault should have 1000 USDT");
        assertEq(userBalanceBefore, 0, "User should start with 0 USDT");

        // Act: SafeERC20 transfer (revert if fails, no return value)
        safeVault.withdraw(amount, user);

        // Assert: Verify the transfer succeeded
        uint256 vaultBalanceAfter = usdt.balanceOf(address(safeVault));
        uint256 userBalanceAfter = usdt.balanceOf(user);

        // ✅ SafeERC20 succeeded: vault balance decreased
        assertEq(
            vaultBalanceAfter,
            vaultBalanceBefore - amount,
            "Vault balance should decrease by transfer amount (SafeERC20 succeeded)"
        );

        // ✅ SafeERC20 succeeded: user balance increased
        assertEq(
            userBalanceAfter,
            userBalanceBefore + amount,
            "User balance should increase by transfer amount (SafeERC20 succeeded)"
        );

        // ✅ SafeERC20 succeeded: no revert means transfer was successful
        // SafeERC20.safeTransfer() reverts on failure, so reaching here confirms success
        assertEq(
            vaultBalanceAfter + userBalanceAfter,
            vaultBalanceBefore + userBalanceBefore,
            "Total balance should be conserved (SafeERC20 verified successful transfer)"
        );
    }

    function test_SafeVault_Works_WithNormalToken() public {
        // Create a standard token mock (returns bool)
        StandardTokenMock standardToken = new StandardTokenMock();
        SafeVault tokenVault = new SafeVault(address(standardToken));

        standardToken.mint(address(tokenVault), 1000 ether);

        tokenVault.withdraw(500 ether, user);
        assertEq(standardToken.balanceOf(user), 500 ether);
    }

    // ============================================
    // THE REAL PROBLEM: Token that returns false
    // ============================================

    /// @notice Demonstrates the REAL problem: token that returns false
    /// @dev This is THE case where SafeERC20 shows its superiority
    function test_UnsafeVault_SilentFailure_WithReturnFalseToken() public {
        // Badly implemented token that always returns false (like some old tokens)
        ReturnFalseToken badToken = new ReturnFalseToken();
        UnsafeVault badVault = new UnsafeVault(address(badToken));

        uint256 userBalanceBefore = badToken.balanceOf(user);

        // ❌ PROBLEM: unsafeWithdraw passes silently!
        //
        // BUG EXPLANATION:
        // 1. UnsafeVault makes a low-level call: address(token).call(...)
        // 2. ReturnFalseToken.transfer() returns false but DOES NOT REVERT
        // 3. The low-level call returns success = true (because no revert)
        // 4. require(success, "transfer failed") passes because success = true
        // 5. BUT the transfer failed because the function returned false!
        //
        // The problem: success of low-level call only indicates "no revert",
        // NOT "function returned true". This is why it passes silently.
        badVault.withdraw(500 ether, user);

        // Verification: nothing was transferred (silent failure)
        assertEq(badToken.balanceOf(user), userBalanceBefore, "No tokens transferred - silent failure!");
        // ⚠️ Test passes even though transfer failed! Funds are locked.
    }

    /// @notice Explicitly demonstrates why the low-level call passes
    /// @dev Shows that success = true even if the function returns false
    function test_WhyLowLevelCallPasses_WithReturnFalse() public {
        ReturnFalseToken badToken = new ReturnFalseToken();

        // Simulate what UnsafeVault does
        (bool success, bytes memory returnData) =
            address(badToken).call(abi.encodeWithSignature("transfer(address,uint256)", user, 500 ether));

        // ✅ The low-level call returns success = true (no revert)
        // IMPORTANT: success = true means "call executed without revert"
        // NOT "function returned true"
        assertTrue(success, "Low-level call succeeded (no revert occurred)");

        // ❌ BUT the function returned false!
        // Must decode returnData to get the actual return value
        bool transferResult = abi.decode(returnData, (bool));
        assertFalse(transferResult, "But transfer() actually returned false!");

        // This is the problem: success indicates "no revert", not "function returns true"
        // UnsafeVault only checks success, not the function's return value
    }

    /// @notice Comparison: function that reverts vs function that returns false
    /// @dev Clearly shows the difference between success and return value
    function test_Comparison_RevertVsReturnFalse() public {
        ReturnFalseToken badToken = new ReturnFalseToken();

        // Case 1: Function that returns false (does not revert)
        (bool success1, bytes memory returnData1) =
            address(badToken).call(abi.encodeWithSignature("transfer(address,uint256)", user, 500 ether));

        assertTrue(success1, "Success = true (no revert)");
        bool result1 = abi.decode(returnData1, (bool));
        assertFalse(result1, "But function returned false");

        // Case 2: Function that reverts (for comparison)
        RevertToken revertToken = new RevertToken();
        (bool success2,) =
            address(revertToken).call(abi.encodeWithSignature("transfer(address,uint256)", user, 500 ether));

        assertFalse(success2, "Success = false (revert occurred)");
        // No returnData because revert

        // CONCLUSION:
        // - success = true + return false → SILENT FAILURE (the bug!)
        // - success = false → FAILURE DETECTED (revert)
    }

    /// @notice Demonstrates the SOLUTION: SafeERC20 detects false and reverts
    /// @dev This is where we see the true superiority of SafeERC20
    function test_SafeVault_DetectsFailure_WithReturnFalseToken() public {
        ReturnFalseToken badToken = new ReturnFalseToken();
        SafeVault safeVaultWithBadToken = new SafeVault(address(badToken));

        // ✅ SOLUTION: SafeERC20 detects false and reverts properly
        vm.expectRevert(); // SafeERC20FailedOperation
        safeVaultWithBadToken.withdraw(500 ether, user);
        // SafeERC20 explicitly checks the return value and reverts if not true
        // You are immediately alerted that the transfer failed
    }

    /// @notice Direct comparison: unsafe vs safe with a token that returns false
    /// @dev Clearly shows why SafeERC20 is superior
    function test_Comparison_UnsafeVsSafe_WithReturnFalseToken() public {
        ReturnFalseToken badToken = new ReturnFalseToken();
        UnsafeVault unsafeVaultBad = new UnsafeVault(address(badToken));
        SafeVault safeVaultBad = new SafeVault(address(badToken));

        uint256 userBalanceBefore = badToken.balanceOf(user);

        // UNSAFE: passes silently (false positive)
        unsafeVaultBad.withdraw(500 ether, user);
        assertEq(badToken.balanceOf(user), userBalanceBefore, "Unsafe passed but no tokens transferred");
        // ⚠️ Test passes even though transfer failed!

        // SAFE: reverts properly (correct detection)
        vm.expectRevert(); // SafeERC20FailedOperation
        safeVaultBad.withdraw(500 ether, user);
        // ✅ SafeERC20 detects false and reverts - you are immediately alerted
    }

    // ============================================
    // FINANCIAL IMPACT: Real fund loss
    // ============================================

    /// @notice Demonstrates real fund loss with silent failure
    /// @dev Realistic scenario: user tries to withdraw funds but they remain locked
    function test_FinancialLoss_UnsafeVault_SilentFailure() public {
        ReturnFalseToken badToken = new ReturnFalseToken();
        UnsafeVault unsafeVaultLoss = new UnsafeVault(address(badToken));

        // Scenario: user deposits 1000 tokens into the vault
        badToken.mint(address(unsafeVaultLoss), 1000 ether);
        uint256 vaultBalanceBefore = badToken.balanceOf(address(unsafeVaultLoss));
        assertEq(vaultBalanceBefore, 1000 ether, "Vault has 1000 tokens");

        // User tries to withdraw 500 tokens
        // ❌ PROBLEM: Transaction passes (no revert), but...
        unsafeVaultLoss.withdraw(500 ether, user);

        // ...tokens are still in the vault (not transferred)
        uint256 vaultBalanceAfter = badToken.balanceOf(address(unsafeVaultLoss));
        uint256 userBalanceAfter = badToken.balanceOf(user);

        assertEq(vaultBalanceAfter, 1000 ether, "Vault still has all tokens - they were NOT transferred");
        assertEq(userBalanceAfter, 0, "User received NO tokens");

        // 💰 LOSS: 500 tokens are LOCKED in the vault
        // User thinks they withdrew funds, but they're still there
        // They can't recover them because the vault thinks they were transferred
        // This is a permanent loss of 500 tokens
    }

    /// @notice Demonstrates that SafeERC20 prevents fund loss
    /// @dev Same scenario, but with SafeERC20 detecting the problem
    function test_FinancialLoss_Prevented_WithSafeERC20() public {
        ReturnFalseToken badToken = new ReturnFalseToken();
        SafeVault safeVaultLoss = new SafeVault(address(badToken));

        // Scenario: user deposits 1000 tokens into the vault
        badToken.mint(address(safeVaultLoss), 1000 ether);
        uint256 vaultBalanceBefore = badToken.balanceOf(address(safeVaultLoss));
        assertEq(vaultBalanceBefore, 1000 ether, "Vault has 1000 tokens");

        // User tries to withdraw 500 tokens
        // ✅ SOLUTION: SafeERC20 detects false and reverts
        vm.expectRevert(); // SafeERC20FailedOperation
        safeVaultLoss.withdraw(500 ether, user);

        // Tokens are still in the vault (no loss)
        uint256 vaultBalanceAfter = badToken.balanceOf(address(safeVaultLoss));
        assertEq(vaultBalanceAfter, 1000 ether, "Vault still has all tokens - no loss occurred");

        // 💰 PROTECTION: Tokens are still in the vault
        // User is alerted that the transfer failed
        // They can retry or use another token
        // No fund loss!
    }

    /// @notice Realistic scenario: cumulative loss across multiple transactions
    /// @dev Shows how losses accumulate with unsafeWithdraw
    function test_CumulativeLoss_MultipleFailedWithdrawals() public {
        ReturnFalseToken badToken = new ReturnFalseToken();
        UnsafeVault unsafeVaultCumulative = new UnsafeVault(address(badToken));

        // Initial deposit
        badToken.mint(address(unsafeVaultCumulative), 1000 ether);

        // Withdrawal attempts (all pass silently)
        unsafeVaultCumulative.withdraw(200 ether, user); // Fails silently
        unsafeVaultCumulative.withdraw(300 ether, user); // Fails silently
        unsafeVaultCumulative.withdraw(400 ether, user); // Fails silently

        // Verification: all tokens are still in the vault
        assertEq(badToken.balanceOf(address(unsafeVaultCumulative)), 1000 ether, "All tokens still stuck in vault");
        assertEq(badToken.balanceOf(user), 0, "User received nothing");

        // 💰 TOTAL LOSS: 900 tokens are "lost" (locked)
        // User thinks they withdrew 900 tokens, but they're still in the vault
        // They can't recover them because the vault thinks they were transferred
    }
}

// Badly implemented token that always returns false (like some old tokens)
contract ReturnFalseToken is IERC20 {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address, uint256) external pure override returns (bool) {
        // ⚠️ Always returns false, even if transfer could succeed
        // This is behavior found in some old badly implemented tokens
        return false;
    }

    function transferFrom(address, address, uint256) external pure override returns (bool) {
        return false;
    }

    function approve(address, uint256) external pure override returns (bool) {
        return false;
    }

    function totalSupply() external pure override returns (uint256) {
        return 0;
    }
}

    // Standard token mock that returns bool (like most ERC20 tokens)
    contract StandardTokenMock is IERC20 {
        mapping(address => uint256) public override balanceOf;
        mapping(address => mapping(address => uint256)) public override allowance;

        function mint(address to, uint256 amount) external {
            balanceOf[to] += amount;
        }

        function transfer(address to, uint256 amount) external override returns (bool) {
            require(balanceOf[msg.sender] >= amount, "insufficient balance");
            balanceOf[msg.sender] -= amount;
            balanceOf[to] += amount;
            return true; // Returns bool like standard tokens
        }

        function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
            require(balanceOf[from] >= amount, "insufficient balance");
            require(allowance[from][msg.sender] >= amount, "insufficient allowance");
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
            allowance[from][msg.sender] -= amount;
            return true;
        }

        function approve(address spender, uint256 amount) external override returns (bool) {
            allowance[msg.sender][spender] = amount;
            return true;
        }

        function totalSupply() external pure override returns (uint256) {
            return 0;
        }
    }

        // Token that reverts instead of returning false (for comparison)
        contract RevertToken is IERC20 {
            mapping(address => uint256) public override balanceOf;
            mapping(address => mapping(address => uint256)) public override allowance;

            function transfer(address, uint256) external pure override returns (bool) {
                revert("Transfer failed"); // Revert instead of returning false
            }

            function transferFrom(address, address, uint256) external pure override returns (bool) {
                revert("Transfer failed");
            }

            function approve(address, uint256) external pure override returns (bool) {
                revert("Approve failed");
            }

            function totalSupply() external pure override returns (uint256) {
                return 0;
            }
        }
