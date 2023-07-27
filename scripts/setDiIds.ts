const { ethers } = require('hardhat');

import PoolDI from '../artifacts/contracts/iAIPoolDI.sol/iAIPoolDI.json'

async function main() {
    const [signer] = await ethers.getSigners();
    console.log("signer address:", signer.address)

    const keys = [1, 2, 3];
    const values = [true, true, true];

    const poolAddress = '0x423a84c2bfcB2158afAB95071EdEb1B8883F46Ce';
    const abi = PoolDI.abi;

    const EthBridgeContract = new ethers.Contract(poolAddress, abi, signer);

    await EthBridgeContract.setDiIds(keys, values);
    console.log(`Complete`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
