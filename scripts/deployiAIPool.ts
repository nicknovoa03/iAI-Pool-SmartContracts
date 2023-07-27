import { ethers } from "hardhat";

async function main() {


  const tokenAddress = '0x6dDe4fFD6dB302Bc9a46850f61399e082f6c2122';
  const nftAddress = '0x853806fCa5Ee8a6Ac99Dc84a8e3596A4F6541796';

  const testTokenAddress = '0x8987B3f0Fd6F36a66119A4586Dd334281d4dcB64';
  const testNftAddress = '0x98F889e00f2AA49c5c30938f555B0488d4f59B8b';

  const iAIPool = await ethers.getContractFactory("iAIPool3");
  const contract = await iAIPool.deploy(tokenAddress, nftAddress);

  await contract.deployed();

  console.log(`Contract deployed to ${contract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});



