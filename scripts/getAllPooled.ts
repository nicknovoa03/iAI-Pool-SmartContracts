const { ethers } = require('hardhat');

import Pool1 from '../artifacts/contracts/iAIPool1.sol/iAIPool1.json'

async function main() {
    const address = '0xAf6C5fF92c0a3F187b063500D47dd1DBf034dC45';
    const poolAddress = '0xD1CC357aF989564B251104b671eB6A58bF00dC06';
    const abi = Pool1.abi;

    const provider = ethers.provider;
    const tokenContract = new ethers.Contract(poolAddress, abi, provider);

    const allPooled = await tokenContract.allPooled(address);
    console.log(`all pooled for address ${address}: ${allPooled}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
