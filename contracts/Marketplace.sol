//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// security against transactions for multiple requests
import "hardhat/console.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _marketItemIds; //this is the market item ids
    Counters.Counter private _itemsSold;

    address payable marketplaceOwner; //this is the owner of the store (us)

    uint256 listingPrice = 0.045 ether;

    constructor() {
        marketplaceOwner = payable(msg.sender);
    }

    struct MarketItem {
        uint256 marketItemId;
        address nftContract;
        uint256 nftId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private itemIdToMarketItem;

    event MarketItemCreated(
        uint256 marketItemId,
        address nftContract,
        uint256 nftId,
        address payable seller,
        address payable owner,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createMarketItem(address nftContract, uint nftId, uint price) public payable nonReentrant{
        require(price > 0, 'Price must be at least one wei');
        require(msg.value == listingPrice, 'Price must be equal to listing price');

        _marketItemIds.increment();
        uint itemId = _marketItemIds.current();

        itemIdToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            nftId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), nftId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            nftId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
    }

    function createMarketSale(address nftContract, uint itemId) public payable nonReentrant{
        require(msg.value == itemIdToMarketItem[itemId].price, 'Please submit the asking price to continue');

        itemIdToMarketItem[itemId].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, itemIdToMarketItem[itemId].nftId);
        itemIdToMarketItem[itemId].owner = payable(msg.sender);
        itemIdToMarketItem[itemId].sold = true;
        _itemsSold.increment();

        payable(marketplaceOwner).transfer(listingPrice);
    }

    function fetchMarketItemsUnsold() public view returns(MarketItem[] memory){
        uint itemCount = _marketItemIds.current();
        uint unsoldItemCount = _marketItemIds.current() - _itemsSold.current();
        uint unsoldCurrentIndex = 0;
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        for(uint i = 0; i< itemCount; i++){
            if(itemIdToMarketItem[i + 1].owner == address(0)){
                MarketItem storage currentItem = itemIdToMarketItem[i + 1];
                items[unsoldCurrentIndex] = currentItem;
                unsoldCurrentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyMarketItems() public view returns(MarketItem[] memory){
        uint itemCount = _marketItemIds.current();
        uint myItemsCount = 0;
        uint myItemCurrentIndex = 0;

        for(uint i = 0; i< itemCount; i++){
            if(itemIdToMarketItem[i + 1].owner == msg.sender){
                myItemsCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](myItemsCount);
         for(uint i = 0; i< itemCount; i++){
             if(itemIdToMarketItem[i + 1].owner == msg.sender){
                MarketItem storage currentItem = itemIdToMarketItem[i + 1];
                items[myItemCurrentIndex] = currentItem;
                myItemCurrentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyCreatedItems() public view returns(MarketItem[] memory){
        uint itemCount = _marketItemIds.current();
        uint myItemsCount = 0;
        uint myItemCurrentIndex = 0;

        for(uint i = 0; i< itemCount; i++){
            if(itemIdToMarketItem[i + 1].seller == msg.sender){
                myItemsCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](myItemsCount);
         for(uint i = 0; i< itemCount; i++){
             if(itemIdToMarketItem[i + 1].seller == msg.sender){
                MarketItem storage currentItem = itemIdToMarketItem[i + 1];
                items[myItemCurrentIndex] = currentItem;
                myItemCurrentIndex += 1;
            }
        }
        return items;
    }
}
