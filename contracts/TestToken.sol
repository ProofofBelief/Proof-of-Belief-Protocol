// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ILock.sol";

contract TestToken is ERC721 {
    constructor() ERC721("TestToken", "TT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    // function mint2(
    //     ILock lockContract,
    //     address parentCollection,
    //     uint256[] calldata tokenIds,
    //     uint256 requiredLockDuration,
    //     uint256 mintTokenId
    // ) external {
    //     lockContract.releaseNFT(
    //         parentCollection,
    //         tokenIds,
    //         requiredLockDuration
    //     );
    //     _mint(msg.sender, mintTokenId);
    // }
}
