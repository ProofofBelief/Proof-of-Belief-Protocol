// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ILock.sol";

contract PoBNFT is ERC721Enumerable {
    ILock public _lockContract;
    address public parentCollection;

    mapping(uint256 => string) private _tokenURIs;

    uint256 public maxSupply = 42000;
    uint256 private _nextTokenId = 1;

    constructor(
        string memory name_,
        string memory symbol_,
        ILock lockContract_,
        address parentCollection_
    ) ERC721(name_, symbol_) {
        _lockContract = lockContract_;
        parentCollection = parentCollection_;
    }

    function mint(
        uint256[] calldata parentTokenIds,
        string calldata content
    ) external {
        require(
            parentTokenIds.length > 0,
            "parentTokenIds must be greater than 0"
        );

        require(_nextTokenId <= maxSupply, "No more NFTs to mint");
        uint256 tokenId = _nextTokenId;
        _nextTokenId += 1;

        uint256 requiredLockDuration = getRequiredLockDuration(
            tokenId,
            parentTokenIds.length
        );
        _lockContract.releaseNFT(
            parentCollection,
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
