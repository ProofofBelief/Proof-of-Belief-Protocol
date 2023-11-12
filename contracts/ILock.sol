// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILock {
    struct LockedNFT {
        address owner;
        address targetCollection;
        address collection;
        uint256 tokenId;
        uint256 lockTimestamp;
    }

    event NFTLocked(
        address indexed owner,
        uint256[] tokenIds,
        uint256 lockTimestamp
    );
    event NFTUnlocked(address indexed owner, uint256[] tokenIds);

    function lockNFT(
        address targetCollection,
        address collection,
        uint256[] calldata tokenIds
    ) external;

    function unlockNFT(
        address collection,
        uint256[] calldata tokenIds
    ) external;

    function releaseNFT(
        address collection,
        uint256[] memory tokenIds,
        uint256 requiredLockDuration
    ) external;

    function getLockedNFT(
        address collection,
        uint256 tokenId
    ) external view returns (LockedNFT memory);
}
