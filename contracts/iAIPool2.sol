// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './IPool.sol';

contract iAIPool2 is IPool {
  constructor(address iAITokenAddress, address nftTokenAddress) IPool(iAITokenAddress, nftTokenAddress) {
    poolType = 'Pool 2';
    arp = 400;
    withdrawPenalty = 25;
    nftThresholdPool = 2;
    tokenThresholdPool = 30000;
    minPoolPeriod = 182 days;
  }

  function pool2(uint256 _amount) public {
    require(_amount >= 1, "Amount can't be zero");
    require(iAI.balanceOf(msg.sender) >= _amount, 'Insufficient $iAI balance');

    iAI.transferFrom(msg.sender, address(this), _amount);
    poolBalance[msg.sender] += _amount;
    poolData[msg.sender].push(Pool(_amount, arp, block.timestamp, poolType));
    emit Pooled(msg.sender, _amount);
  }

  function unpool2(uint256 _index) public nonReentrant {
    require(poolData[msg.sender].length > 0, 'No stakes found for the address');
    require(poolData[msg.sender].length >= _index + 1, 'Stake does not exist');
    // uint256 totalStaked = poolingBalance[msg.sender];
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = poolData[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    require(timeStaked >= minPoolPeriod, 'Minimum pooling period not reached');
    uint256 latestStake = lastStake.amount;
    uint256 reward = (latestStake * arp) / 10000;
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

  function withdrawPool2(uint256 _index) public nonReentrant {
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

  function claimRewardPool2() public nonReentrant {
    require(poolData[msg.sender].length > 0, 'No stakes found for the address');
    uint256 totalStaked = poolBalance[msg.sender];
    uint256 lastClaim = lastClaimTime[msg.sender];
    uint256 timeElapsed = block.timestamp - lastClaim;
    require(timeElapsed > 0, 'No rewards to claim');
    uint256 reward = (totalStaked * (arp / 365) * (timeElapsed / 1 days)) / 100;
    require(reward > 0, 'Not Eligible for reward');
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, reward);
    emit RewardClaimed(msg.sender, reward);
  }
}