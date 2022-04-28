//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
// security against transactions for multiple requests
import "hardhat/console.sol";

contract Marketplace is ReentrancyGuard, ERC721URIStorage, EIP712 {
    using Counters for Counters.Counter;

    string private constant SIGNING_DOMAIN = "Marketplace";
    string private constant SIGNATURE_VERSION = "1";
    Counters.Counter private _marketItemIds; //this is the market item ids
    Counters.Counter private _marketItemIds2; //this is the market item ids
    Counters.Counter private _itemsSold;

    address payable marketplaceOwner; //this is the owner of the store (us)

    uint256 listingPrice = 0.045 ether;

    constructor()
        ERC721("Marketplace", "MKP")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){
            marketplaceOwner = payable(msg.sender);
    }

    // struct MarketItem {
    //     uint256 marketItemId;
    //     address nftContract;
    //     uint256 nftId;
    //     address payable seller;
    //     address payable owner;
    //     uint256 price;
    //     bool sold;
    // }

    struct NFTVoucher {
        uint256 tokenId;
        uint256 minPrice;
        string uri;
        bytes signature;
    }

    struct MarketItem{
        uint256 marketItemId;
        uint256 tokenId;
        NFTVoucher voucher;
        address payable seller;
        address payable owner;
        uint256 price; //temporary
        bool sold;
    }

    mapping(uint256 => MarketItem) private itemIdToMarketItem;

    // mapping(uint256 => MarketItem) private itemIdToMarketItem;

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

    function createMarketItem2(uint nftId, uint price, NFTVoucher calldata voucher) public payable nonReentrant returns(MarketItem memory){
        _marketItemIds.increment();
        uint itemId = _marketItemIds.current();

        itemIdToMarketItem[itemId] = MarketItem(
            itemId,
            nftId,
            voucher,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
        return itemIdToMarketItem[itemId];
    }

    function redeemVoucher(NFTVoucher calldata voucher, uint itemId) public payable returns (uint256) {
        //check if voucher/market itemid is still for sale
        require(itemIdToMarketItem[itemId].sold == false, "Voucher was already redeemed");

        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);

        // transfer the token to the redeemer
        _transfer(signer, msg.sender, voucher.tokenId);

        //pay the seller
        itemIdToMarketItem[itemId].seller.transfer(msg.value);

        itemIdToMarketItem[itemId].owner = payable(msg.sender);
        
        //set the item as redeemed so that none else can mint it
        itemIdToMarketItem[itemId].sold = true;
        _itemsSold.increment();

        return voucher.tokenId;
    }

    /*
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
    }*/

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

    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"),
        voucher.tokenId,
        voucher.minPrice,
        keccak256(bytes(voucher.uri))
        )));
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    // function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC721) returns (bool) {
    //     return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    // }
}
