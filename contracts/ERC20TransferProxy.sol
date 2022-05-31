// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20TransferProxy is Ownable {
    function transferERC20(address token, address from, address to, uint256 amount) public onlyOwner {
        require(IERC20(token).transferFrom(from, to, amount));
    }
}