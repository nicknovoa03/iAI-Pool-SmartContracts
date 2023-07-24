// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

  uint256 public arp1 = 200;
  uint256 public arp2 = 200;
  uint256 public arp3 = 550;
  uint256 public arpPrestige = 1000;
  uint256 public arpDI = 1200;

  uint256 public minPeriodPool1 = 182 days;
  uint256 public minPeriodPool2 = 182 days;
  uint256 public minPeriodPool3 = 182 days;
  uint256 public minPeriodPrestige = 365 days;
  uint256 public minPeriodDI = 365 days;

  uint256 public withdrawPenalty = 25;

  mapping(address => Pool[]) private pools;
  mapping(address => uint256) private poolingBalance;
  mapping(address => uint256) private lastClaimTime;

  event Staked(address indexed from, uint256 amount, string pool);
  event Unstaked(address indexed to, uint256 amount, uint256 poolingperiod);
  event Penalty(address indexed to, uint256 amount);
  event RewardClaimed(address indexed to, uint256 amount);

  constructor(address iAITokenAddress, address nftTokenAddress) Ownable() {
    iAI = IiAI(iAITokenAddress);
    nft = I9022(nftTokenAddress);
  }

  function setARP1(uint256 _arp) external onlyOwner {
    require(_arp > 0, "Amount cann't be zero");
    arp1 = _arp;
  }

  function setARP2(uint256 _arp) external onlyOwner {
    require(_arp > 0, "Amount cann't be zero");
    arp2 = _arp;
  }

  function setARP3(uint256 _arp) external onlyOwner {
    require(_arp > 0, "Amount cann't be zero");
    arp3 = _arp;
  }

  function setARPPrestige(uint256 _arp) external onlyOwner {
    require(_arp > 0, "Amount cann't be zero");
    arpPrestige = _arp;
  }

  function setARPDI(uint256 _arp) external onlyOwner {
    require(_arp > 0, "Amount cann't be zero");
    arpDI = _arp;
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

  function stakingbalance(address _staker) public view returns (uint256) {
    return poolingBalance[_staker];
  }

  function stakerdetails(address _staker, uint256 _index) public view returns (Pool memory) {
    return pools[_staker][_index];
  }

  function lastclaimtime(address _staker) public view returns (uint256) {
    return lastClaimTime[_staker];
  }

  function allStaked(address _staker) public view returns (Pool[] memory) {
    return pools[_staker];
  }

  function widthdrawToken(address _address, uint256 _amount) public onlyOwner {
    iAI.transfer(_address, _amount);
  }

  function pool1(uint256 _amount) public {
    require(_amount >= 1, "Amount can't be zero");
    require(iAI.balanceOf(msg.sender) >= tokenThresholdPool1, 'Insufficient $TRUTH balance');

    iAI.transferFrom(msg.sender, address(this), _amount);
    poolingBalance[msg.sender] += _amount;
    pools[msg.sender].push(Pool(_amount, block.timestamp, 'Pool1'));
    emit Staked(msg.sender, _amount, 'Pool1');
  }

  function unstake(uint256 _index) public nonReentrant {
    require(pools[msg.sender].length > 0, 'No stakes found for the address');
    require(pools[msg.sender].length >= _index + 1, 'Stake does not exist');
    // uint256 totalStaked = stakingBalance[msg.sender];
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = pools[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    require(timeStaked >= minPeriodPool1, 'Minimum staking period not reached');
    uint256 latestStake = lastStake.amount;
    uint256 reward = (latestStake * 1) / 10000;
    uint256 payout = latestStake + reward;
    // Remove the stake at the given index
    for (uint256 i = _index; i < pools[msg.sender].length - 1; i++) {
      pools[msg.sender][i] = pools[msg.sender][i + 1];
    }
    pools[msg.sender].pop();
    poolingBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, payout);
    emit Unstaked(msg.sender, payout, timeStaked);
  }

  function withdrawpenalty(uint256 _index) public nonReentrant {
    require(pools[msg.sender].length > 0, 'No stakes found for the address');
    require(pools[msg.sender].length >= _index + 1, 'Stake does not exist');
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = pools[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    uint256 latestStake = lastStake.amount;
    require(timeStaked <= minPeriodPool1, 'Withdraw with penalty time exceed you can now unstake token ');
    uint256 penalty = (latestStake * withdrawPenalty) / 100;
    // Remove the stake at the given index
    for (uint256 i = _index; i < pools[msg.sender].length - 1; i++) {
      pools[msg.sender][i] = pools[msg.sender][i + 1];
    }
    pools[msg.sender].pop();
    poolingBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    uint256 payout = latestStake - penalty;
    iAI.transfer(msg.sender, payout);
    emit Penalty(msg.sender, payout);
  }

  function claimReward() public nonReentrant {
    require(pools[msg.sender].length > 0, 'No stakes found for the address');
    uint256 totalStaked = poolingBalance[msg.sender];
    uint256 lastClaim = lastClaimTime[msg.sender];
    uint256 timeElapsed = block.timestamp - lastClaim;
    require(timeElapsed > 0, 'No rewards to claim');
    uint256 reward = (totalStaked * (arp1 / 365) * (timeElapsed / 1 days)) / 100;
    require(reward > 0, 'Not Eligible for reward');
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, reward);
    emit RewardClaimed(msg.sender, reward);
  }
}
