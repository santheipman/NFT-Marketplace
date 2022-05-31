// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721TransferProxy {
    function transferERC721(address token, address from, address to, uint256 tokenID) public {
        IERC721(token).safeTransferFrom(from, to, tokenID);
    }
}