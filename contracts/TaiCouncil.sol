// 🔒 TAI CORE — TAI COUNCIL CONTRACT (MAINNET ARCHITECTURE READY)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/**
 * @title TaiCouncil — Governance council for Tai ecosystem
 * @notice Handles proposal creation and weighted voting with DAO-controlled voting power.
 * @dev Fully synchronized with mainnet keys, ERC2771-enabled for optional meta-transactions
 */
contract TaiCouncil is Ownable, ERC2771Context {

    /*───────────────────────────── CORE STATE ─────────────────────────────*/
    struct Proposal {
        address proposer;
        string description;
        uint256 voteYes;
        uint256 voteNo;
        uint256 deadline;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;
    uint256 public proposalCount;
    address public dao;

    /*───────────────────────────── EVENTS ─────────────────────────────*/
    event Proposed(uint256 indexed id, address indexed proposer, uint256 deadline);
    event Voted(uint256 indexed id, address indexed voter, bool vote, uint256 weight);
    event VotingPowerUpdated(address indexed voter, uint256 newPower);
    event DAOUpdated(address indexed newDAO);

    /*───────────────────────────── MODIFIERS ─────────────────────────────*/
    modifier onlyDAO() {
        require(_msgSender() == dao, "TaiCouncil: caller not DAO");
        _;
    }

    modifier proposalExists(uint256 id) {
        require(id < proposalCount, "TaiCouncil: proposal does not exist");
        _;
    }

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor(address _dao, address _trustedForwarder)
        ERC2771Context(_trustedForwarder)
    {
        require(_dao != address(0), "TaiCouncil: invalid DAO address");
        dao = _dao;
    }

    /*───────────────────────────── DAO ADMIN FUNCTIONS ─────────────────────────────*/
    function setDAO(address _dao) external onlyOwner {
        require(_dao != address(0), "TaiCouncil: invalid DAO address");
        dao = _dao;
        emit DAOUpdated(_dao);
    }

    function setVotingPower(address voter, uint256 power) external onlyDAO {
        votingPower[voter] = power;
        emit VotingPowerUpdated(voter, power);
    }

    /*───────────────────────────── PROPOSAL FUNCTIONS ─────────────────────────────*/
    function propose(string calldata description) external {
        uint256 deadline = block.timestamp + 3 days;

        proposals[proposalCount] = Proposal({
            proposer: _msgSender(),
            description: description,
            voteYes: 0,
            voteNo: 0,
            deadline: deadline,
            executed: false
        });

        emit Proposed(proposalCount, _msgSender(), deadline);
        proposalCount++;
    }

    function vote(uint256 id, bool yes) external proposalExists(id) {
        Proposal storage p = proposals[id];
        require(block.timestamp < p.deadline, "TaiCouncil: voting closed");

        uint256 power = votingPower[_msgSender()];
        require(power > 0, "TaiCouncil: no voting power");

        if (yes) {
            p.voteYes += power;
        } else {
            p.voteNo += power;
        }

        emit Voted(id, _msgSender(), yes, power);
    }

    /*───────────────────────────── READ FUNCTIONS ─────────────────────────────*/
    function getVotingPower(address voter) external view returns (uint256) {
        return votingPower[voter];
    }

    function proposalStatus(uint256 id) external view proposalExists(id) returns (uint256 yes, uint256 no, bool active) {
        Proposal storage p = proposals[id];
        yes = p.voteYes;
        no = p.voteNo;
        active = block.timestamp < p.deadline && !p.executed;
    }

    /*───────────────────────────── EXECUTION LOGIC ─────────────────────────────*/
    function executeProposal(uint256 id) external proposalExists(id) {
        Proposal storage p = proposals[id];
        require(block.timestamp >= p.deadline, "TaiCouncil: voting not ended");
        require(!p.executed, "TaiCouncil: already executed");

        // Execution logic preserved; extend in child contracts if needed
        p.executed = true;
    }

    /*───────────────────────────── ERC2771 OVERRIDES ─────────────────────────────*/
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

