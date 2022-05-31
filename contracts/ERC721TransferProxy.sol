// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721TransferProxy is Ownable {
    function transferERC721(address token, address from, address to, uint256 tokenID) public onlyOwner {
        IERC721(token).safeTransferFrom(from, to, tokenID);
    }
}