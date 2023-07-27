const { ethers } = require('hardhat');

import EthToken from '../artifacts/contracts/iAITest.sol/IAITest.json'

async function main() {
    const address = '0xAf6C5fF92c0a3F187b063500D47dd1DBf034dC45';
    const tokenAddress = '0xB83cA21FED7054bAE76613cEd0215FaA06706361'
    const poolAddress = '0xD1CC357aF989564B251104b671eB6A58bF00dC06';
    const tokenAbi = EthToken.abi;

    const provider = ethers.provider;
    const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, provider);

    const balance = await tokenContract.balanceOf(address);
    console.log(`Token balance for ${address}: ${balance}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
