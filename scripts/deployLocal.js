const hre = require("hardhat");
const fs = require('fs');

async function main(){
  const Market = await hre.ethers.getContractFactory('Marketplace');
  const market = await Market.deploy();
  await market.deployed();
  const marketAddress = market.address;

  const NFT = await hre.ethers.getContractFactory('NFT');
  const nft = await NFT.deploy(marketAddress);
  await nft.deployed();
  const nftAddress = nft.address;

  const addresses = {
    NFT_CONTRACT_ADDRESS: nftAddress,
    MARKET_CONTRACT_ADDRESS: marketAddress
  };

  const jsonAddresses = JSON.stringify(addresses);
  fs.writeFileSync('addressesLocal.json', jsonAddresses);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
