// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Enable optimizer with a low runs value
// The optimizer runs a maximum of 200 times (you can adjust the value if needed)
pragma solidity ^0.8.4 ^0.8.4;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface IiAI {
  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}



interface I9022 {
  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}

contract iAIPool is ReentrancyGuard, Ownable {
  IiAI public iAI;
  I9022 public nft;

  struct Pool {
    uint256 amount;
    uint256 apr;
    uint256 timestamp;
    string poolType;
  }

  uint256 public tokenThresholdPool1 = 10000;
  uint256 public tokenThresholdPool2 = 30000;
  uint256 public tokenThresholdPool3 = 100000;
  uint256 public tokenThresholdPrestige = 200000;
  uint256 public tokenThresholdDI = 300000;

  uint256 public nftThresholdPool1 = 1;
  uint256 public nftThresholdPool2 = 2;
  uint256 public nftThresholdPool3 = 3;
  uint256 public nftThresholdPrestige = 1;
  uint256 public nftThresholdDI = 1;

  uint256 public apr1 = 200;
  uint256 public apr2 = 200;
  uint256 public apr3 = 550;
  uint256 public aprPrestige = 1000;
  uint256 public aprDI = 1200;

  uint256 public minPeriodPool1 = 182 days;
  uint256 public minPeriodPool2 = 182 days;
  uint256 public minPeriodPool3 = 182 days;
  uint256 public minPeriodPrestige = 365 days;
  uint256 public minPeriodDI = 365 days;

  uint256 public withdrawPenalty = 25;

  mapping(address => Pool[]) private pool1Data;
  mapping(address => Pool[]) private pool2Data;
  mapping(address => Pool[]) private pool3Data;
  mapping(address => Pool[]) private poolPrestigeData;
  mapping(address => Pool[]) private poolDIData;

  mapping(address => uint256) private pool1Balance;
  mapping(address => uint256) private pool2Balance;
  mapping(address => uint256) private pool3Balance;
  mapping(address => uint256) private poolPrestigeBalance;
  mapping(address => uint256) private poolDIBalance;

  mapping(address => uint256) private lastClaimTime;

  event Staked(address indexed from, uint256 amount, string pool);
  event Unstaked(address indexed to, uint256 amount, uint256 poolingperiod);
  event Penalty(address indexed to, uint256 amount);
  event RewardClaimed(address indexed to, uint256 amount);

  constructor(address iAITokenAddress, address nftTokenAddress) Ownable() {
    iAI = IiAI(iAITokenAddress);
    nft = I9022(nftTokenAddress);
  }

  function setARP1(uint256 _apr) external onlyOwner {
    require(_apr > 0, "Amount cann't be zero");
    apr1 = _apr;
  }

  function setARP2(uint256 _apr) external onlyOwner {
    require(_apr > 0, "Amount cann't be zero");
    apr2 = _apr;
  }

  function setARP3(uint256 _apr) external onlyOwner {
    require(_apr > 0, "Amount cann't be zero");
    apr3 = _apr;
  }

  function setARPPrestige(uint256 _apr) external onlyOwner {
    require(_apr > 0, "Amount cann't be zero");
    aprPrestige = _apr;
  }

  function setARPDI(uint256 _apr) external onlyOwner {
    require(_apr > 0, "Amount cann't be zero");
    aprDI = _apr;
  }

  function setMinPeriodPool1(uint256 _minStakingPeriod) external onlyOwner {
    require(_minStakingPeriod > 0, "Amount cann't be zero");
    minPeriodPool1 = _minStakingPeriod;
  }

  function setMinPeriodPool2(uint256 _minStakingPeriod) external onlyOwner {
    require(_minStakingPeriod > 0, "Amount cann't be zero");
    minPeriodPool2 = _minStakingPeriod;
  }

  function setMinPeriodPool3(uint256 _minStakingPeriod) external onlyOwner {
    require(_minStakingPeriod > 0, "Amount cann't be zero");
    minPeriodPool3 = _minStakingPeriod;
  }

  function setMinPeriodPrestige(uint256 _minStakingPeriod) external onlyOwner {
    require(_minStakingPeriod > 0, "Amount cann't be zero");
    minPeriodPrestige = _minStakingPeriod;
  }

  function setMinPeriodDI(uint256 _minStakingPeriod) external onlyOwner {
    require(_minStakingPeriod > 0, "Amount cann't be zero");
    minPeriodDI = _minStakingPeriod;
  }

  function setWithdrawPenalty(uint256 _withdrawPenalty) external onlyOwner {
    require(_withdrawPenalty > 0, "Amount cann't be zero");
    withdrawPenalty = _withdrawPenalty;
  }

  function poolBalance(address _address) public view returns (uint256) {
    return pool1Balance[_address];
  }

  function pool1Detailed(address _address, uint256 _index) public view returns (Pool memory) {
    return pool1Data[_address][_index];
  }

  function pool2Detailed(address _address, uint256 _index) public view returns (Pool memory) {
    return pool2Data[_address][_index];
  }

  function pool3Detailed(address _address, uint256 _index) public view returns (Pool memory) {
    return pool1Data[_address][_index];
  }

  function poolPrestigeDetailed(address _address, uint256 _index) public view returns (Pool memory) {
    return poolPrestigeData[_address][_index];
  }

  function poolDIDetailed(address _address, uint256 _index) public view returns (Pool memory) {
    return poolDIData[_address][_index];
  }

  function allPooled1(address _address) public view returns (Pool[] memory) {
    return pool1Data[_address];
  }

  function allPooled2(address _address) public view returns (Pool[] memory) {
    return pool2Data[_address];
  }

  function allPooled3(address _address) public view returns (Pool[] memory) {
    return pool3Data[_address];
  }

  function allPooledPrestige(address _address) public view returns (Pool[] memory) {
    return poolPrestigeData[_address];
  }

  function allPooledDI(address _address) public view returns (Pool[] memory) {
    return poolDIData[_address];
  }

  function lastclaimtime(address _address) public view returns (uint256) {
    return lastClaimTime[_address];
  }

  function widthdrawToken(address _address, uint256 _amount) public onlyOwner {
    iAI.transfer(_address, _amount);
  }

  function pool1(uint256 _amount) public {
    require(_amount >= tokenThresholdPool1, "Amount can't be zero");
    require(iAI.balanceOf(msg.sender) >= tokenThresholdPool1, 'Insufficient $iAI balance');
    require(nft.balanceOf(msg.sender) >= nftThresholdPool1, 'Insufficient 9022 balance');

    string memory poolType = 'Pool 1';
    iAI.transferFrom(msg.sender, address(this), _amount);
    pool1Balance[msg.sender] += _amount;
    pool1Data[msg.sender].push(Pool(_amount, apr1, block.timestamp, poolType));
    emit Staked(msg.sender, _amount, poolType);
  }

  function pool2(uint256 _amount) public {
    require(_amount >= tokenThresholdPool2, "Amount can't be zero");
    require(iAI.balanceOf(msg.sender) >= tokenThresholdPool2, 'Insufficient $iAI balance');
    require(nft.balanceOf(msg.sender) >= nftThresholdPool2, 'Insufficient 9022 balance');

    string memory poolType = 'Pool 2';
    iAI.transferFrom(msg.sender, address(this), _amount);
    pool2Balance[msg.sender] += _amount;
    pool2Data[msg.sender].push(Pool(_amount, apr2, block.timestamp, poolType));
    emit Staked(msg.sender, _amount, poolType);
  }

  function pool3(uint256 _amount) public {
    require(_amount >= tokenThresholdPool3, "Amount can't be zero");
    require(iAI.balanceOf(msg.sender) >= tokenThresholdPool3, 'Insufficient $iAI balance');
    require(nft.balanceOf(msg.sender) >= nftThresholdPool3, 'Insufficient 9022 balance');

    uint256 nftCount = nft.balanceOf(msg.sender);
    uint256 dynamicApr = apr3 + (50 * (nftCount - nftThresholdPool3));
    if (dynamicApr > 900) {
      dynamicApr = 900;
    }
    string memory poolType = 'Pool 3';
    iAI.transferFrom(msg.sender, address(this), _amount);
    pool3Balance[msg.sender] += _amount;
    pool3Data[msg.sender].push(Pool(_amount, dynamicApr, block.timestamp, poolType));
    emit Staked(msg.sender, _amount, poolType);
  }

  function poolPrestige(uint256 _amount) public {
    require(_amount >= tokenThresholdPrestige, "Amount can't be zero");
    require(iAI.balanceOf(msg.sender) >= tokenThresholdPrestige, 'Insufficient $iAI balance');
    string memory poolType = 'Pool Prestige';
    iAI.transferFrom(msg.sender, address(this), _amount);
    poolPrestigeBalance[msg.sender] += _amount;
    poolPrestigeData[msg.sender].push(Pool(_amount, aprPrestige, block.timestamp, poolType));
    emit Staked(msg.sender, _amount, poolType);
  }

  function poolDI(uint256 _amount) public {
    require(_amount >= tokenThresholdDI, "Amount can't be zero");
    require(iAI.balanceOf(msg.sender) >= tokenThresholdDI, 'Insufficient $iAI balance');
    string memory poolType = 'Pool Destination Inheritance';
    iAI.transferFrom(msg.sender, address(this), _amount);
    poolDIBalance[msg.sender] += _amount;
    poolDIData[msg.sender].push(Pool(_amount, aprDI, block.timestamp, poolType));
    emit Staked(msg.sender, _amount, poolType);
  }

  function unpool1(uint256 _index) public nonReentrant {
    require(pool1Data[msg.sender].length > 0, 'No stakes found for the address');
    require(pool1Data[msg.sender].length >= _index + 1, 'Stake does not exist');
    // uint256 totalStaked = stakingBalance[msg.sender];
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = pool1Data[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    require(timeStaked >= minPeriodPool1, 'Minimum staking period not reached');
    uint256 latestStake = lastStake.amount;
    uint256 reward = (latestStake * 1) / 10000;
    uint256 payout = latestStake + reward;
    // Remove the stake at the given index
    for (uint256 i = _index; i < pool1Data[msg.sender].length - 1; i++) {
      pool1Data[msg.sender][i] = pool1Data[msg.sender][i + 1];
    }
    pool1Data[msg.sender].pop();
    pool1Balance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, payout);
    emit Unstaked(msg.sender, payout, timeStaked);
  }

  function unpool2(uint256 _index) public nonReentrant {
    require(pool2Data[msg.sender].length > 0, 'No stakes found for the address');
    require(pool2Data[msg.sender].length >= _index + 1, 'Stake does not exist');
    // uint256 totalStaked = stakingBalance[msg.sender];
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = pool2Data[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    require(timeStaked >= minPeriodPool2, 'Minimum staking period not reached');
    uint256 latestStake = lastStake.amount;
    uint256 reward = (latestStake * 1) / 10000;
    uint256 payout = latestStake + reward;
    // Remove the stake at the given index
    for (uint256 i = _index; i < pool2Data[msg.sender].length - 1; i++) {
      pool2Data[msg.sender][i] = pool2Data[msg.sender][i + 1];
    }
    pool2Data[msg.sender].pop();
    pool2Balance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, payout);
    emit Unstaked(msg.sender, payout, timeStaked);
  }

  function unpool3(uint256 _index) public nonReentrant {
    require(pool3Data[msg.sender].length > 0, 'No stakes found for the address');
    require(pool3Data[msg.sender].length >= _index + 1, 'Stake does not exist');
    // uint256 totalStaked = stakingBalance[msg.sender];
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = pool3Data[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    require(timeStaked >= minPeriodPool3, 'Minimum staking period not reached');
    uint256 latestStake = lastStake.amount;
    uint256 reward = (latestStake * 1) / 10000;
    uint256 payout = latestStake + reward;
    // Remove the stake at the given index
    for (uint256 i = _index; i < pool3Data[msg.sender].length - 1; i++) {
      pool3Data[msg.sender][i] = pool3Data[msg.sender][i + 1];
    }
    pool3Data[msg.sender].pop();
    pool3Balance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, payout);
    emit Unstaked(msg.sender, payout, timeStaked);
  }

  function unpoolPrestige(uint256 _index) public nonReentrant {
    require(poolPrestigeData[msg.sender].length > 0, 'No stakes found for the address');
    require(poolPrestigeData[msg.sender].length >= _index + 1, 'Stake does not exist');
    // uint256 totalStaked = stakingBalance[msg.sender];
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = poolPrestigeData[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    require(timeStaked >= minPeriodPrestige, 'Minimum staking period not reached');
    uint256 latestStake = lastStake.amount;
    uint256 reward = (latestStake * 1) / 10000;
    uint256 payout = latestStake + reward;
    // Remove the stake at the given index
    for (uint256 i = _index; i < poolPrestigeData[msg.sender].length - 1; i++) {
      poolPrestigeData[msg.sender][i] = poolPrestigeData[msg.sender][i + 1];
    }
    poolPrestigeData[msg.sender].pop();
    poolPrestigeBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, payout);
    emit Unstaked(msg.sender, payout, timeStaked);
  }

  function unpoolDI(uint256 _index) public nonReentrant {
    require(poolDIData[msg.sender].length > 0, 'No stakes found for the address');
    require(poolDIData[msg.sender].length >= _index + 1, 'Stake does not exist');
    // uint256 totalStaked = stakingBalance[msg.sender];
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = poolDIData[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    require(timeStaked >= minPeriodDI, 'Minimum staking period not reached');
    uint256 latestStake = lastStake.amount;
    uint256 reward = (latestStake * 1) / 10000;
    uint256 payout = latestStake + reward;
    // Remove the stake at the given index
    for (uint256 i = _index; i < poolDIData[msg.sender].length - 1; i++) {
      poolDIData[msg.sender][i] = poolDIData[msg.sender][i + 1];
    }
    poolDIData[msg.sender].pop();
    poolDIBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, payout);
    emit Unstaked(msg.sender, payout, timeStaked);
  }

  function withdrawPool1(uint256 _index) public nonReentrant {
    require(pool1Data[msg.sender].length > 0, 'No stakes found for the address');
    require(pool1Data[msg.sender].length >= _index + 1, 'Stake does not exist');
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = pool1Data[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    uint256 latestStake = lastStake.amount;
    require(timeStaked <= minPeriodPool1, 'Withdraw with penalty time exceed you can now unstake token ');
    uint256 penalty = (latestStake * withdrawPenalty) / 100;
    // Remove the stake at the given index
    for (uint256 i = _index; i < pool1Data[msg.sender].length - 1; i++) {
      pool1Data[msg.sender][i] = pool1Data[msg.sender][i + 1];
    }
    pool1Data[msg.sender].pop();
    pool1Balance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    uint256 payout = latestStake - penalty;
    iAI.transfer(msg.sender, payout);
    emit Penalty(msg.sender, payout);
  }

  function withdrawPool2(uint256 _index) public nonReentrant {
    require(pool2Data[msg.sender].length > 0, 'No stakes found for the address');
    require(pool2Data[msg.sender].length >= _index + 1, 'Stake does not exist');
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = pool2Data[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    uint256 latestStake = lastStake.amount;
    require(timeStaked <= minPeriodPool2, 'Withdraw with penalty time exceed you can now unstake token ');
    uint256 penalty = (latestStake * withdrawPenalty) / 100;
    // Remove the stake at the given index
    for (uint256 i = _index; i < pool2Data[msg.sender].length - 1; i++) {
      pool2Data[msg.sender][i] = pool2Data[msg.sender][i + 1];
    }
    pool2Data[msg.sender].pop();
    pool2Balance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    uint256 payout = latestStake - penalty;
    iAI.transfer(msg.sender, payout);
    emit Penalty(msg.sender, payout);
  }

  function withdrawPool3(uint256 _index) public nonReentrant {
    require(pool3Data[msg.sender].length > 0, 'No stakes found for the address');
    require(pool3Data[msg.sender].length >= _index + 1, 'Stake does not exist');
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = pool3Data[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    uint256 latestStake = lastStake.amount;
    require(timeStaked <= minPeriodPool3, 'Withdraw with penalty time exceed you can now unstake token ');
    uint256 penalty = (latestStake * withdrawPenalty) / 100;
    // Remove the stake at the given index
    for (uint256 i = _index; i < pool3Data[msg.sender].length - 1; i++) {
      pool3Data[msg.sender][i] = pool3Data[msg.sender][i + 1];
    }
    pool3Data[msg.sender].pop();
    pool3Balance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    uint256 payout = latestStake - penalty;
    iAI.transfer(msg.sender, payout);
    emit Penalty(msg.sender, payout);
  }

  function withdrawPrestige(uint256 _index) public nonReentrant {
    require(poolPrestigeData[msg.sender].length > 0, 'No stakes found for the address');
    require(poolPrestigeData[msg.sender].length >= _index + 1, 'Stake does not exist');
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = poolPrestigeData[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    uint256 latestStake = lastStake.amount;
    require(timeStaked <= minPeriodPrestige, 'Withdraw with penalty time exceed you can now unstake token ');
    uint256 penalty = (latestStake * withdrawPenalty) / 100;
    // Remove the stake at the given index
    for (uint256 i = _index; i < poolPrestigeData[msg.sender].length - 1; i++) {
      poolPrestigeData[msg.sender][i] = poolPrestigeData[msg.sender][i + 1];
    }
    poolPrestigeData[msg.sender].pop();
    poolPrestigeBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    uint256 payout = latestStake - penalty;
    iAI.transfer(msg.sender, payout);
    emit Penalty(msg.sender, payout);
  }

  function withdrawDI(uint256 _index) public nonReentrant {
    require(poolDIData[msg.sender].length > 0, 'No stakes found for the address');
    require(poolDIData[msg.sender].length >= _index + 1, 'Stake does not exist');
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = poolDIData[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    uint256 latestStake = lastStake.amount;
    require(timeStaked <= minPeriodDI, 'Withdraw with penalty time exceed you can now unstake token ');
    uint256 penalty = (latestStake * withdrawPenalty) / 100;
    // Remove the stake at the given index
    for (uint256 i = _index; i < poolDIData[msg.sender].length - 1; i++) {
      poolDIData[msg.sender][i] = poolDIData[msg.sender][i + 1];
    }
    poolDIData[msg.sender].pop();
    poolDIBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    uint256 payout = latestStake - penalty;
    iAI.transfer(msg.sender, payout);
    emit Penalty(msg.sender, payout);
  }

  function claimRewardPool1() public nonReentrant {
    require(pool1Data[msg.sender].length > 0, 'No stakes found for the address');
    uint256 totalStaked = pool1Balance[msg.sender];
    uint256 lastClaim = lastClaimTime[msg.sender];
    uint256 timeElapsed = block.timestamp - lastClaim;
    require(timeElapsed > 0, 'No rewards to claim');
    uint256 reward = (totalStaked * (apr1 / 365) * (timeElapsed / 1 days)) / 100;
    require(reward > 0, 'Not Eligible for reward');
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, reward);
    emit RewardClaimed(msg.sender, reward);
  }
}
