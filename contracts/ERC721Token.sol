// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;  

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Token is ERC721 {
    constructor(address to, uint256 tokenID) ERC721("ERC721TestToken","E7TT"){
        _safeMint(to, tokenID);
    }
}