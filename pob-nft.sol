// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./pob-lock.sol";

contract PoBNFT is ERC721 {
    address private _lockContractAddress;

    constructor(address lockContractAddress) ERC721("PoBNFT", "PB") {
        _lockContractAddress = lockContractAddress;
    }

    function mintNFT(uint256 lockedNFTId, string memory content) external {
        // Ensure that the caller has locked the NFT for at least 10 minutes
        require(_isNFTLockedLongEnough(lockedNFTId), "NFT not locked long enough");

        // Mint the new NFT
        uint256 tokenId = totalSupply() + 1;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, content);

        // Unlock the previously locked NFT
        LockContract lockContract = LockContract(_lockContractAddress);
        lockContract.unlockNFT(lockedNFTId);
    }

    function _isNFTLockedLongEnough(uint256 lockedNFTId) internal view returns (bool) {
        LockContract lockContract = LockContract(_lockContractAddress);
        (, uint256 lockTimestamp) = lockContract.getLockedNFT(lockedNFTId);

        // Check if the current time is at least 10 minutes after the lockTimestamp
        return (block.timestamp >= lockTimestamp + 600);
    }
}
