// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./lock.sol";

contract PoBNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address private _lockContractAddress;
    mapping(uint256 => string) private _tokenURIs;

    constructor(address lockContractAddress) ERC721("PoBNFT", "PB") {
        _lockContractAddress = lockContractAddress;
    }

    function mintNFT(uint256 lockedNFTId, string memory content) external {
        // Ensure that the caller has locked the NFT for at least 10 minutes
        require(_isNFTLockedLongEnough(lockedNFTId), "NFT not locked long enough");

        // Mint the new NFT
        uint256 tokenId = _tokenIdCounter.current();
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, content);
        _tokenIdCounter.increment();

        // Unlock the previously locked NFT
        LockContract lockContract = LockContract(_lockContractAddress);
        lockContract.unlockNFT(lockedNFTId);
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        _tokenURIs[tokenId] = uri;
    }

    function _isNFTLockedLongEnough(uint256 lockedNFTId) internal view returns (bool) {
        LockContract lockContract = LockContract(_lockContractAddress);
        (, uint256 lockTimestamp) = lockContract.getLockedNFT(lockedNFTId);

        // Check if the current time is at least 10 minutes after the lockTimestamp
        return (block.timestamp >= lockTimestamp + 600);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }
}
