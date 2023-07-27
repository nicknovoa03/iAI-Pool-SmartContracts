// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './IPool.sol';

contract iAIPool3 is IPool {
  mapping(address => uint256) public dynamicAprs;

  constructor(address iAITokenAddress, address nftTokenAddress) IPool(iAITokenAddress, nftTokenAddress) {
    poolType = 'Pool 3';
    apr = 550;
    nftThreshold = 3;
    tokenThreshold = 100000 ether;
    minPoolPeriod = 182 days;
  }

  function pool(uint256 _amount) external payable {
    require(poolActive, 'Pool is not currently active');
    require(poolData[msg.sender].length == 0, 'Only 1 position allowed for pool 3');
    require(iAI.balanceOf(msg.sender) >= _amount, 'Insufficient $iAI balance');
    require(_amount >= tokenThreshold, '$iAI threshold not met');
    require(nft9022.balanceOf(msg.sender) >= nftThreshold, '9022 threshold not met');

    // Calculate the apr determined by how many 9022 you have
    uint256 nftCount = nft9022.balanceOf(msg.sender);
    uint256 dynamicApr = apr + (50 * (nftCount - nftThreshold));
    if (dynamicApr > 900) {
      dynamicApr = 900;
    }
    dynamicAprs[msg.sender] = dynamicApr;
    iAI.transferFrom(msg.sender, address(this), _amount);
    poolBalance[msg.sender] += _amount;
    poolData[msg.sender].push(Pool(_amount, dynamicApr, block.timestamp, poolType));
    emit Pooled(msg.sender, _amount);
  }

  function unPool(uint256 _index) external nonReentrant {
    require(poolActive, 'Pool is not currently active');
    require(poolData[msg.sender].length > 0, 'No stakes found for the address');
    require(poolData[msg.sender].length >= _index + 1, 'Stake does not exist');
    // uint256 totalStaked = poolingBalance[msg.sender];
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = poolData[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    require(timeStaked >= minPoolPeriod, 'Minimum pooling period not reached');
    uint256 latestStake = lastStake.amount;
    uint256 reward = (latestStake * dynamicAprs[msg.sender]) / 10000;
    uint256 payout = latestStake + reward;
    // Remove the stake at the given index
    for (uint256 i = _index; i < poolData[msg.sender].length - 1; i++) {
      poolData[msg.sender][i] = poolData[msg.sender][i + 1];
    }
    poolData[msg.sender].pop();
    poolBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, payout);
    emit Unpooled(msg.sender, payout, timeStaked);
  }

  function withdrawPosition(uint256 _index) external nonReentrant {
    require(poolActive, 'Pool is not currently active');
    require(poolData[msg.sender].length > 0, 'No stakes found for the address');
    require(poolData[msg.sender].length >= _index + 1, 'Stake does not exist');
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = poolData[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    uint256 latestStake = lastStake.amount;
    require(timeStaked <= minPoolPeriod, 'Withdraw with penalty time exceed you can now unstake token ');
    uint256 penalty = (latestStake * withdrawPenalty) / 100;
    // Remove the stake at the given index
    for (uint256 i = _index; i < poolData[msg.sender].length - 1; i++) {
      poolData[msg.sender][i] = poolData[msg.sender][i + 1];
    }
    poolData[msg.sender].pop();
    poolBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    uint256 payout = latestStake - penalty;
    iAI.transfer(msg.sender, payout);
    emit Penalty(msg.sender, payout);
  }

  function claimReward() external nonReentrant {
    require(poolActive, 'Pool is not currently active');
    require(poolData[msg.sender].length > 0, 'No stakes found for the address');
    uint256 totalStaked = poolBalance[msg.sender];
    uint256 lastClaim = lastClaimTime[msg.sender];
    uint256 timeElapsed = block.timestamp - lastClaim;
    require(timeElapsed > 0, 'No rewards to claim');
    // Calculate the reward
    uint256 reward = (totalStaked * (dynamicAprs[msg.sender] / 365) * (timeElapsed / 1 days)) / 100;
    require(reward > 0, 'Not Eligible for reward');
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, reward);
    emit RewardClaimed(msg.sender, reward);
  }
}
