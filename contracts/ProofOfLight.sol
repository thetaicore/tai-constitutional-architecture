// 🔒 TAI CORE — ABSOLUTE CONTRACT SYNCHRONIZATION, ATTESTATION & DEPLOYMENT DIRECTIVE
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ITaiCoin {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
}

interface ITaiVaultMerkleClaim {
    function claimTokens(uint256 amount, bytes32[] calldata proof) external;
}

interface ITaiCoinSwap {
    function swap(address fromToken, address toToken, uint256 amount) external returns (uint256);
}

interface IAIContract {
    function validateLightHash(bytes32 lightHash) external returns (bool);
}

/**
 * @title ProofOfLight
 * @notice Stake TaiCoin, submit LightHashes, earn rewards, auto-mint TAI for valid LightHashes.
 * @dev Compatible with AI validation, staking rewards, Merkle claims, and cross-chain readiness.
 */
contract ProofOfLight is Ownable {
    using ECDSA for bytes32;

    /*───────────────────────────── CORE CONTRACTS ─────────────────────────────*/
    ITaiCoin public immutable taiCoin;
    ITaiVaultMerkleClaim public merkleClaim;
    ITaiCoinSwap public coinSwap;
    IAIContract public aiContract;

    address public dao;      // DAO governance address
    address public admin;    // Admin for LightHash registration

    /*───────────────────────────── STAKING / REWARD STATE ─────────────────────────────*/
    uint256 public totalStaked;
    uint256 public rewardRatePerSecond;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userStakes;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    /*───────────────────────────── LIGHTHASH TRACKING ─────────────────────────────*/
    mapping(bytes32 => bool) public validLightHashes;

    /*───────────────────────────── EVENTS ─────────────────────────────*/
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event LightHashRegistered(bytes32 indexed hash, address indexed submitter);
    event AdminChanged(address newAdmin);
    event AutoTaiMinted(address indexed user, uint256 amount);

    /*───────────────────────────── MODIFIERS ─────────────────────────────*/
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor(
        address _taiCoin,
        address _dao,
        address _merkleClaim,
        address _coinSwap,
        address _aiContract
    ) {
        require(_taiCoin != address(0), "TaiCoin address required");
        require(_dao != address(0), "DAO address required");
        require(_aiContract != address(0), "AI address required");

        taiCoin = ITaiCoin(_taiCoin);
        dao = _dao;
        admin = msg.sender;
        merkleClaim = ITaiVaultMerkleClaim(_merkleClaim);
        coinSwap = ITaiCoinSwap(_coinSwap);
        aiContract = IAIContract(_aiContract);

        lastUpdateTime = block.timestamp;
        rewardRatePerSecond = 1e12; // default reward rate
    }

    /*───────────────────────────── LIGHTHASH FUNCTIONS ─────────────────────────────*/
    function registerLightHash(bytes32 lightHash) external onlyAdmin {
        require(aiContract.validateLightHash(lightHash), "Invalid Light Hash");
        require(!validLightHashes[lightHash], "Hash already registered");

        validLightHashes[lightHash] = true;
        emit LightHashRegistered(lightHash, msg.sender);
    }

    function submitLightHash(bytes32 lightHash) external updateReward(msg.sender) {
        require(!validLightHashes[lightHash], "Hash already registered");

        if (aiContract.validateLightHash(lightHash)) {
            validLightHashes[lightHash] = true;
            emit LightHashRegistered(lightHash, msg.sender);

            // Auto-mint TaiCoin reward
            uint256 rewardAmount = 1 ether;
            taiCoin.mint(msg.sender, rewardAmount);
            emit AutoTaiMinted(msg.sender, rewardAmount);
        }
    }

    /*───────────────────────────── STAKING FUNCTIONS ─────────────────────────────*/
    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        require(taiCoin.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        userStakes[msg.sender] += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot unstake 0");
        require(userStakes[msg.sender] >= amount, "Insufficient staked");

        userStakes[msg.sender] -= amount;
        totalStaked -= amount;
        require(taiCoin.transfer(msg.sender, amount), "Transfer failed");

        emit Unstaked(msg.sender, amount);
    }

    /*───────────────────────────── REWARD FUNCTIONS ─────────────────────────────*/
    function claimRewards() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards");

        rewards[msg.sender] = 0;
        taiCoin.mint(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        uint256 timeDelta = block.timestamp - lastUpdateTime;
        return rewardPerTokenStored + ((timeDelta * rewardRatePerSecond * 1e18) / totalStaked);
    }

    function earned(address account) public view returns (uint256) {
        uint256 calculated = rewardPerToken() - userRewardPerTokenPaid[account];
        return (userStakes[account] * calculated) / 1e18 + rewards[account];
    }

    function setRewardRate(uint256 newRate) external onlyDAO updateReward(address(0)) {
        rewardRatePerSecond = newRate;
        emit RewardRateUpdated(newRate);
    }

    /*───────────────────────────── ADMIN FUNCTIONS ─────────────────────────────*/
    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin");
        admin = newAdmin;
        emit AdminChanged(newAdmin);
    }

    /*───────────────────────────── VIEW HELPERS ─────────────────────────────*/
    function getStaked(address user) external view returns (uint256) {
        return userStakes[user];
    }

    function getPendingReward(address user) external view returns (uint256) {
        return earned(user);
    }
}

