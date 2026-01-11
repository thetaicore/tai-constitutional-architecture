// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import "./IAI.sol";  
import "./ITaiCoinSwap.sol"; 
import "./ITaiVaultMerkleClaim.sol"; 
import "./IGasRelayer.sol";  
import "./IProofOfLight.sol"; 
import "./IMintByResonance.sol";  

/*───────────────────────────── CONTRACT ─────────────────────────────*/
/// @title TaiRedistributor — Reputation-based redistribution & TAI-AI enhanced governance
/// @notice Fully meta-tx compatible, handles contributors, redistribution, and AI signals
contract TaiRedistributor is ERC2771Context, Ownable, ReentrancyGuard {
    IERC20 public immutable taiCoin;
    ITaiCoinSwap public immutable coinSwap;
    ITaiAI public immutable tai;
    ITaiVaultMerkleClaim public immutable merkleClaim;
    IGasRelayer public gasRelayer;
    IProofOfLight public proofOfLight;
    IMintByResonance public mintByResonance;

    address public taiController;
    address public dao;

    struct Contributor { 
        uint256 reputation; 
        bool isSoulbound; 
    }

    mapping(address => Contributor) private _contributors;
    address[] private _participantList;
    mapping(address => bool) private _isParticipant;
    uint256 private _totalReputation;

    // ===== Events =====
    event ContributorRegistered(address indexed user, uint256 reputation, bool soulbound);
    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation);
    event ContributorUnbound(address indexed user);
    event Redistribution(uint256 totalAmount, uint256 totalReputation);
    event TokensRecovered(address token, address to, uint256 amount);
    event IntentSignal(address indexed user, uint256 score, string signalType);
    event TaiControllerSet(address indexed newController);
    event GasRelayed(address indexed from, address indexed to, uint256 amount);
    event MintByResonanceMinted(address indexed user, uint256 amount);

    // ===== Modifiers =====
    modifier onlyTai() { require(_msgSender() == taiController, "Not authorized TAI"); _; }
    modifier onlyDAO() { require(_msgSender() == dao, "Not authorized DAO"); _; }

    // ===== Constructor =====
    constructor(
        address _taiCoin,
        address _dao,
        address _taiController,
        address _merkleClaim,
        address _coinSwap,
        address _gasRelayer,
        address _proofOfLight,
        address _mintByResonance,
        address _taiAI,
        address _forwarder
    ) ERC2771Context(_forwarder) {
        require(_taiCoin != address(0) && _dao != address(0) && _taiController != address(0), "Invalid core addresses");
        require(_merkleClaim != address(0) && _coinSwap != address(0), "Invalid service addresses");
        require(_gasRelayer != address(0) && _proofOfLight != address(0) && _mintByResonance != address(0) && _taiAI != address(0), "Invalid auxiliary addresses");

        taiCoin = IERC20(_taiCoin);
        dao = _dao;
        taiController = _taiController;
        merkleClaim = ITaiVaultMerkleClaim(_merkleClaim);
        coinSwap = ITaiCoinSwap(_coinSwap);
        gasRelayer = IGasRelayer(_gasRelayer);
        proofOfLight = IProofOfLight(_proofOfLight);
        mintByResonance = IMintByResonance(_mintByResonance);
        tai = ITaiAI(_taiAI);
    }

    // ===== ERC2771 Overrides =====
    function _msgSender() internal view override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }
    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
    function _contextSuffixLength() internal view override(ERC2771Context, Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }

    // ===== Admin =====
    function setTaiController(address _controller) external onlyOwner {
        require(_controller != address(0), "Invalid controller");
        taiController = _controller;
        emit TaiControllerSet(_controller);
    }

    function setGasRelayer(address _gasRelayer) external onlyOwner {
        require(_gasRelayer != address(0), "Invalid gas relayer");
        gasRelayer = IGasRelayer(_gasRelayer);
    }

    function recoverTokens(address token, address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Invalid recipient");
        IERC20(token).transfer(to, amount);
        emit TokensRecovered(token, to, amount);
    }

    // ===== Contributors =====
    function reputationOf(address user) external view returns (uint256) {
        return _contributors[user].reputation;
    }

    function isSoulbound(address user) external view returns (bool) {
        return _contributors[user].isSoulbound;
    }

    function totalReputation() external view returns (uint256) {
        return _totalReputation;
    }

    function getParticipants() external view returns (address[] memory) {
        return _participantList;
    }

    function registerContributor(address user, uint256 newReputation, bool soulbound) public onlyOwner {
        _updateContributor(user, newReputation, soulbound);
    }

    function updateReputation(address user, uint256 newReputation) public onlyOwner {
        _updateContributor(user, newReputation, _contributors[user].isSoulbound);
    }

    function batchUpdateReputation(address[] calldata users, uint256[] calldata scores) external onlyOwner {
        require(users.length == scores.length, "Array length mismatch");
        for (uint256 i = 0; i < users.length; i++) {
            _updateContributor(users[i], scores[i], _contributors[users[i]].isSoulbound);
        }
    }

    function unbindContributor(address user) external onlyOwner {
        require(_isParticipant[user], "User not registered");
        _contributors[user].isSoulbound = false;
        emit ContributorUnbound(user);
    }

    // ===== TAI-AI Signals =====
    function emitIntentSignal(address user, uint256 score, string calldata signalType) external onlyTai {
        uint256 boostedScore = _applySignalBoost(signalType, score);
        _updateContributor(user, boostedScore, true);
        tai.processIntentSignal(user, boostedScore, signalType);
        emit IntentSignal(user, boostedScore, signalType);
    }

    // ===== Redistribution =====
    function redistribute(uint256 totalAmount) external onlyOwner nonReentrant {
        require(totalAmount > 0 && _totalReputation > 0, "Nothing to distribute");
        require(taiCoin.balanceOf(address(this)) >= totalAmount, "Insufficient balance");

        for (uint256 i = 0; i < _participantList.length; i++) {
            address user = _participantList[i];
            uint256 userScore = _contributors[user].reputation;
            if (userScore > 0) {
                uint256 payout = (totalAmount * userScore) / _totalReputation;
                if (payout > 0) taiCoin.transfer(user, payout);
            }
        }

        emit Redistribution(totalAmount, _totalReputation);
    }

    // ===== Internal Helpers =====
    function _updateContributor(address user, uint256 newReputation, bool soulbound) internal {
        require(user != address(0), "Invalid address");
        uint256 oldReputation = _contributors[user].reputation;
        _contributors[user] = Contributor(newReputation, soulbound);

        if (!_isParticipant[user] && newReputation > 0) {
            _participantList.push(user);
            _isParticipant[user] = true;
        } else if (newReputation == 0 && _isParticipant[user]) {
            _removeParticipant(user);
        }

        if (newReputation > oldReputation) _totalReputation += (newReputation - oldReputation);
        else if (oldReputation > newReputation) _totalReputation -= (oldReputation - newReputation);

        emit ContributorRegistered(user, newReputation, soulbound);
        emit ReputationUpdated(user, oldReputation, newReputation);
    }

    function _removeParticipant(address user) internal {
        uint256 len = _participantList.length;
        for (uint256 i = 0; i < len; i++) {
            if (_participantList[i] == user) {
                if (i != len - 1) _participantList[i] = _participantList[len - 1];
                _participantList.pop();
                _isParticipant[user] = false;
                break;
            }
        }
    }

    function _applySignalBoost(string memory signalType, uint256 score) internal pure returns (uint256) {
        bytes32 sigHash = keccak256(abi.encodePacked(signalType));
        if (sigHash == keccak256("truth")) return score * 2;
        if (sigHash == keccak256("frequency_match")) return (score * 3) / 2;
        if (sigHash == keccak256("resonance")) return (score * 125) / 100;
        return score;
    }
}

