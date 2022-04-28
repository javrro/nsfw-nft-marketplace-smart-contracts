//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract NFT {
    using Counters for Counters.Counter;
    Counters.Counter private _nftIds; //this is the NFT ID

    address marketplaceContractAddress; //we need the marketplace contract address to grant it permission to deal the NFT

    constructor(address marketplaceAddress) {
        marketplaceContractAddress = marketplaceAddress;
    }

    function mintToken() public returns(uint){
        _nftIds.increment();
        uint256 newNftId = _nftIds.current();
        // _mint(msg.sender, newNftId);
        // _setTokenURI(newNftId, nftURI);
        // setApprovalForAll(marketplaceContractAddress, true);

        return newNftId;
    }
}