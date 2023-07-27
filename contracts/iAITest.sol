// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IAITest is ERC20 {
    constructor() ERC20("iAITest", "aiTEST") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}