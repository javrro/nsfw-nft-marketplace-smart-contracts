const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Marketplace", function(){
    it("Should mint and trade NFTs", async function(){
        //tst to receive contract address
        const Market = await ethers.getContractFactory('Marketplace');
        const market = await Market.deploy();
        await market.deployed();
        const marketAddress = market.address;

        const NFT = await ethers.getContractFactory('NFT');
        const nft = await NFT.deploy(marketAddress);
        await nft.deployed();
        const nftAddress = nft.address;

        //test to recieve listing price
        let listingPrice = await market.getListingPrice();
        listingPrice = listingPrice.toString();
        const auctionPrice = ethers.utils.parseUnits('100', 'ether');

        //test for minting
        await nft.mintToken('https-1')
        await nft.mintToken('https-2')

        await market.createMarketItem(nftAddress, 1, auctionPrice, {value: listingPrice});
        await market.createMarketItem(nftAddress, 2, auctionPrice, {value: listingPrice});

        //get address
        const [_, buyerAddress] = await ethers.getSigners();

        //create a market sale
        await market.connect(buyerAddress).createMarketSale(nftAddress, 1, {
            value: auctionPrice
        });

        let items = await market.fetchMyCreatedItems();

        items = await Promise.all(items.map(async i =>{
            const nftUri = await nft.tokenURI(i.nftId);
            let item = {
                price: i.price.toString(),
                nftId: i.nftId.toString(),
                seller: i.seller,
                owner: i.owner,
                nftUri 
            }
            return item
        }));

        //log all items
        console.log('items', items);
    });
});