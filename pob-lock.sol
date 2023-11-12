// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LockContract is IERC721Receiver {
    using Counters for Counters.Counter;

    struct LockedNFT {
        address owner;
        uint256 tokenId;
        uint256 lockTimestamp;
    }

    Counters.Counter private _tokenIds;

    // Mapping from token ID to LockedNFT
    mapping(uint256 => LockedNFT) private _lockedNFTs;

    // ERC721 contract address
    address private _erc721Contract;

    event NFTLocked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 lockTimestamp
    );
    event NFTUnlocked(address indexed owner, uint256 indexed tokenId);

    constructor(address erc721Contract) {
        _erc721Contract = erc721Contract;
    }

    function lockNFT(uint256 tokenId) external {
        IERC721(_erc721Contract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        _tokenIds.increment();
        uint256 lockTimestamp = block.timestamp;
        _lockedNFTs[_tokenIds.current()] = LockedNFT({
            owner: msg.sender,
            tokenId: tokenId,
            lockTimestamp: lockTimestamp
        });
        emit NFTLocked(msg.sender, tokenId, lockTimestamp);
    }

    function unlockNFT(uint256 tokenId) external {
        require(_lockedNFTs[tokenId].owner != address(0), "NFT not locked");
        IERC721(_erc721Contract).safeTransferFrom(address(this), _lockedNFTs[tokenId].owner, tokenId);
        emit NFTUnlocked(_lockedNFTs[tokenId].owner, tokenId);
        delete _lockedNFTs[tokenId];
    }

    function getLockedNFT(uint256 tokenId)
        external
        view
        returns (
            address owner,
            uint256 lockTimestamp
        )
    {
        require(_lockedNFTs[tokenId].owner != address(0), "NFT not locked");
        return (
            _lockedNFTs[tokenId].owner,
            _lockedNFTs[tokenId].lockTimestamp
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
