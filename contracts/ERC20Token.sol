// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;  

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    constructor(address to, uint initialAmount) ERC20("ERC20TestToken","E2TT"){
        _mint(to, initialAmount);
    }
}