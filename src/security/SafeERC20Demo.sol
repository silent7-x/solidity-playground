// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UnsafeVault {
    IERC20 public immutable token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    // DANGER – pattern still seen everywhere
    function withdraw(uint256 amount, address to) external {
        // Some do this → silent failure with real USDT
        (bool success,) = address(token).call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        require(success, "transfer failed"); // ← LIE with USDT
    }
}

contract SafeVault {
    using SafeERC20 for IERC20; // ← THE MAGIC LINE
    IERC20 public immutable token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function withdraw(uint256 amount, address to) external {
        token.safeTransfer(to, amount); // ← always safe
    }
}
