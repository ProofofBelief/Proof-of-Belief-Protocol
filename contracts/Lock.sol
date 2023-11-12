// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Lock is IERC721Receiver {
    struct LockedNFT {
        address owner;
        address targetCollection;
        address collection;
        uint256 tokenId;
        uint256 lockTimestamp;
    }

    mapping(address => mapping(uint256 => LockedNFT)) private _lockedNFTs;

    event NFTLocked(
        address indexed owner,
        uint256[] tokenIds,
        uint256 lockTimestamp
    );
    event NFTUnlocked(address indexed owner, uint256[] tokenIds);

    constructor() {}

    function lockNFT(
        address targetCollection,
        address collection,
        uint256[] calldata tokenIds
    ) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(collection).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
            _lockedNFTs[collection][tokenIds[i]] = LockedNFT({
                owner: msg.sender,
                targetCollection: targetCollection,
                collection: collection,
                tokenId: tokenIds[i],
                lockTimestamp: block.timestamp
            });
        }
        emit NFTLocked(msg.sender, tokenIds, block.timestamp);
    }

    function unlockNFT(
        address collection,
        uint256[] calldata tokenIds
    ) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                _lockedNFTs[collection][tokenIds[i]].owner == msg.sender,
                "Only owner can unlock"
            );
            IERC721(collection).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
            delete _lockedNFTs[collection][tokenIds[i]];
        }
        emit NFTUnlocked(msg.sender, tokenIds);
    }

    function releaseNFT(
        address collection,
        uint256[] memory tokenIds,
        uint256 requiredLockDuration
    ) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            LockedNFT memory lockedNFT = _lockedNFTs[collection][tokenIds[i]];
            require(
                lockedNFT.targetCollection == msg.sender,
                "Only target collection can release"
            );
            require(
                lockedNFT.lockTimestamp + requiredLockDuration <=
                    block.timestamp,
                "Lock duration not met"
            );
            IERC721(collection).safeTransferFrom(
                address(this),
                lockedNFT.owner,
                tokenIds[i]
            );
            _lockedNFTs[collection][tokenIds[i]]
                .lockTimestamp += requiredLockDuration;
        }
    }

    function getLockedNFT(
        address collection,
        uint256 tokenId
    ) external view returns (LockedNFT memory) {
        return _lockedNFTs[collection][tokenId];
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
