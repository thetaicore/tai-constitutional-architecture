// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TaiStakingEngine
 * @notice Stake TaiCoin to earn rewards based on user roles with early withdrawal penalties.
 */
contract TaiStakingEngine is Ownable {
    struct StakeInfo {
        uint256 amount;
        uint256 startEpoch;
        uint256 lockEpochs;
        string role;
        uint256 penaltyRate; // Early withdrawal penalty %
    }

    IERC20 public immutable taiToken;
    uint256 public currentEpoch;
    uint256 public rewardPerEpoch;

    mapping(address => StakeInfo) private _stakes;
    mapping(string => uint256) public roleMultiplier;

    event Staked(address indexed user, uint256 amount, uint256 lockEpochs, string role);
    event Claimed(address indexed user, uint256 reward);
    event EpochAdvanced(uint256 newEpoch);
    event StakePenalty(address indexed user, uint256 penaltyAmount);

    constructor(address _taiToken) {
        require(_taiToken != address(0), "Invalid TaiCoin address");
        taiToken = IERC20(_taiToken);

        // Default multipliers
        roleMultiplier["Seeker"] = 100;
        roleMultiplier["Scribe"] = 120;
        roleMultiplier["Guardian"] = 150;
    }

    // ===== User Functions =====
    function stake(uint256 amount, uint256 lockEpochs, string calldata role) external {
        require(roleMultiplier[role] > 0, "Invalid role");
        require(_stakes[msg.sender].amount == 0, "Already staking");

        taiToken.transferFrom(msg.sender, address(this), amount);
        uint256 penaltyRate = _calculatePenaltyRate(lockEpochs);

        _stakes[msg.sender] = StakeInfo(amount, currentEpoch, lockEpochs, role, penaltyRate);
        emit Staked(msg.sender, amount, lockEpochs, role);
    }

    function claim() external {
        StakeInfo memory info = _stakes[msg.sender];
        require(info.amount > 0, "Not staking");
        require(currentEpoch >= info.startEpoch + info.lockEpochs, "Still locked");

        uint256 rewardEpochs = info.lockEpochs;
        uint256 rawReward = (rewardEpochs * rewardPerEpoch * info.amount * roleMultiplier[info.role]) / 10000;
        uint256 penaltyAmount = (rawReward * info.penaltyRate) / 100;
        uint256 finalReward = rawReward - penaltyAmount;

        delete _stakes[msg.sender];
        taiToken.transfer(msg.sender, finalReward);

        if (penaltyAmount > 0) emit StakePenalty(msg.sender, penaltyAmount);
        emit Claimed(msg.sender, finalReward);
    }

    // ===== Owner Functions =====
    function advanceEpoch() external onlyOwner {
        unchecked { currentEpoch += 1; }
        emit EpochAdvanced(currentEpoch);
    }

    function setRewardPerEpoch(uint256 reward) external onlyOwner {
        rewardPerEpoch = reward;
    }

    function setRoleMultiplier(string calldata role, uint256 multiplier) external onlyOwner {
        require(multiplier > 0, "Multiplier must be > 0");
        roleMultiplier[role] = multiplier;
    }

    // ===== View Functions =====
    function stakeInfo(address user) external view returns (StakeInfo memory) {
        return _stakes[user];
    }

    // ===== Internal Helpers =====
    function _calculatePenaltyRate(uint256 lockEpochs) internal pure returns (uint256) {
        if (lockEpochs <= 3) return 10;
        if (lockEpochs <= 6) return 5;
        return 0;
    }
}

