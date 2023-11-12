// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ILock.sol";

contract PoBNFT is ERC721 {
    ILock private _lockContract;

    address _parentCollection;

    mapping(uint256 => string) private _tokenURIs;

    uint256 private _totalSupply = 42000;
    uint256 private _nextTokenId = 1;

    // TODO: modify name and symbol
    constructor(
        ILock lockContract,
        address parentCollection
    ) ERC721("PoBNFT", "PB") {
        _lockContract = lockContract;
        _parentCollection = parentCollection;
    }

    function mint(
        uint256[] calldata parentTokenIds,
        string calldata content
    ) external {
        require(
            parentTokenIds.length > 0,
            "parentTokenIds must be greater than 0"
        );

        // Mint the new NFT
        require(_nextTokenId <= _totalSupply, "No more NFTs to mint");
        uint256 tokenId = _nextTokenId;
        _nextTokenId += 1;

        uint256 requiredLockDuration = getRequiredLockDuration(
            tokenId,
            parentTokenIds.length
        );
        _lockContract.releaseNFT(
            _parentCollection,
            parentTokenIds,
            requiredLockDuration
        );

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, content);
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        _tokenURIs[tokenId] = string(
            abi.encodePacked(
                "data:text/plain;base64,",
                Base64.encode(abi.encodePacked(uri))
            )
        );
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function getNextRequiredLockDuration(
        uint256 lockedNum
    ) public view returns (uint256) {
        return getRequiredLockDuration(_nextTokenId, lockedNum);
    }

    function getRequiredLockDuration(
        uint256 tokenId,
        uint256 lockedNum
    ) public pure returns (uint256) {
        require(lockedNum > 0, "lockedNum must be greater than 0");
        // round up
        return (tokenId * 600 + lockedNum - 1) / lockedNum;
    }
}
