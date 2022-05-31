// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20TransferProxy {
    function transferERC20(address token, address from, address to, uint256 amount) public {
        require(IERC20(token).transferFrom(from, to, amount));
    }
}