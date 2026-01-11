// 🔒 TAI CORE — ABSOLUTE CONTRACT SYNCHRONIZATION, ATTESTATION & DEPLOYMENT DIRECTIVE
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAIContract.sol";  // AI proposal validator interface

/// @title TaiDAO — Decentralized Governance for TaiCoin Ecosystem
/// @notice Fully synchronized with TaiCore system: ERC2771 + Hardhat v3 + ethers v6 compatible
contract TaiDAO is Ownable, ERC2771Context {

    IERC20 public taiToken;
    ITaiAI public aiContract;       // ✅ Fixed type to interface
    address public dao;

    uint256 public proposalCount;
    uint256 public votingPeriod = 3 days;
    uint256 public quorum = 1000 ether;

    uint256 public mintingRate; 
    uint256 public collateralRatio;
    address public crossChainEndpoint;
    address public gasRelayer;

    struct Proposal {
        address proposer;
        string description;
        uint256 startTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bytes callData;
        address target;
        uint256 action;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // -----------------------------
    // Events
    // -----------------------------
    event ProposalCreated(uint256 indexed id, address proposer, string description);
    event Voted(uint256 indexed id, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed id);
    event MintingRateUpdated(uint256 newRate);
    event CollateralRatioUpdated(uint256 newRatio);
    event CrossChainUpdated(address newEndpoint);
    event GasRelayerUpdated(address newRelayer);
    event DAOUpdated(address indexed newDAO);

    // -----------------------------
    // Modifiers
    // -----------------------------
    modifier onlyTAI() {
        require(_msgSender() == owner() || _msgSender() == dao, "TaiDAO: caller is not TAI");
        _;
    }

    // -----------------------------
    // Constructor
    // -----------------------------
    constructor(
        address _taiToken,
        uint256 _mintingRate,
        uint256 _collateralRatio,
        address _crossChainEndpoint,
        address _gasRelayer,
        address _aiContract,
        address _dao,
        address _forwarder
    ) ERC2771Context(_forwarder) {
        require(_taiToken != address(0), "TAI token cannot be zero");
        require(_crossChainEndpoint != address(0), "Cross-chain endpoint cannot be zero");
        require(_gasRelayer != address(0), "Gas relayer cannot be zero");
        require(_aiContract != address(0), "AI contract cannot be zero");
        require(_dao != address(0), "DAO cannot be zero");

        taiToken = IERC20(_taiToken);
        mintingRate = _mintingRate;
        collateralRatio = _collateralRatio;
        crossChainEndpoint = _crossChainEndpoint;
        gasRelayer = _gasRelayer;
        aiContract = ITaiAI(_aiContract);    // ✅ Interface cast
        dao = _dao;
    }

    // -----------------------------
    // DAO Admin Functions
    // -----------------------------
    function setDAO(address _dao) external onlyOwner {
        require(_dao != address(0), "DAO cannot be zero");
        dao = _dao;
        emit DAOUpdated(_dao);
    }

    function setVotingPeriod(uint256 newPeriod) external onlyTAI {
        votingPeriod = newPeriod;
    }

    function setQuorum(uint256 newQuorum) external onlyTAI {
        quorum = newQuorum;
    }

    // -----------------------------
    // Proposal Management
    // -----------------------------
    function createProposal(
        string calldata description,
        address target,
        bytes calldata callData,
        uint256 action
    ) external {
        require(taiToken.balanceOf(_msgSender()) >= 100 ether, "Need 100 TAI to propose");

        bool isValid = aiContract.validateProposal(description, target, callData, action);
        require(isValid, "Proposal does not align with system resonance");

        Proposal storage p = proposals[proposalCount];
        p.proposer = _msgSender();
        p.description = description;
        p.startTime = block.timestamp;
        p.callData = callData;
        p.target = target;
        p.action = action;

        emit ProposalCreated(proposalCount, _msgSender(), description);
        proposalCount++;
    }

    function vote(uint256 id, bool support) external {
        Proposal storage p = proposals[id];
        require(block.timestamp < p.startTime + votingPeriod, "Voting closed");
        require(!hasVoted[id][_msgSender()], "Already voted");

        uint256 weight = taiToken.balanceOf(_msgSender());
        require(weight > 0, "No voting power");

        if (support) {
            p.forVotes += weight;
        } else {
            p.againstVotes += weight;
        }

        hasVoted[id][_msgSender()] = true;
        emit Voted(id, _msgSender(), support, weight);
    }

    function executeProposal(uint256 id) external {
        Proposal storage p = proposals[id];
        require(!p.executed, "Already executed");
        require(block.timestamp >= p.startTime + votingPeriod, "Voting not ended");
        require(p.forVotes >= quorum, "Quorum not reached");
        require(p.forVotes > p.againstVotes, "Proposal rejected");

        (bool success, ) = p.target.call(p.callData);
        require(success, "Call failed");

        if (p.action == 1) {
            mintingRate = abi.decode(p.callData, (uint256));
            emit MintingRateUpdated(mintingRate);
        } else if (p.action == 2) {
            collateralRatio = abi.decode(p.callData, (uint256));
            emit CollateralRatioUpdated(collateralRatio);
        } else if (p.action == 3) {
            crossChainEndpoint = abi.decode(p.callData, (address));
            emit CrossChainUpdated(crossChainEndpoint);
        } else if (p.action == 4) {
            gasRelayer = abi.decode(p.callData, (address));
            emit GasRelayerUpdated(gasRelayer);
        }

        p.executed = true;
        emit ProposalExecuted(id);
    }

    // -----------------------------
    // ERC2771Context Overrides
    // -----------------------------
    function _msgSender() internal view override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view override(Context, ERC2771Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }
}

