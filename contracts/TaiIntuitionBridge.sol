// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/**
 * @title TaiIntuitionBridge
 * @notice Assign and track SoulSkills for users with DAO governance
 * @dev Fully ERC2771Context ready for meta-transactions
 */
contract TaiIntuitionBridge is ERC2771Context {
    struct SoulSkill {
        address user;
        string category;
        bytes32 skillHash;
        uint256 timestamp;
        uint256 impact; // Impact used for reputation or rewards
    }

    mapping(address => SoulSkill[]) public userSkills;
    mapping(bytes32 => bool) public validSkillCategories;
    address public dao;

    event SoulSkillAssigned(address indexed user, string category, bytes32 skillHash, uint256 impact);
    event SkillCategoryUpdated(bytes32 skillHash, bool isActive);
    event DAOUpdated(address newDAO);

    modifier onlyDAO() {
        require(_msgSender() == dao, "Not authorized DAO");
        _;
    }

    constructor(address _dao, address _forwarder) ERC2771Context(_forwarder) {
        require(_dao != address(0), "Invalid DAO address");
        dao = _dao;
    }

    /*───────────────────────────── DAO FUNCTIONS ─────────────────────────────*/
    function updateDAO(address _newDAO) external onlyDAO {
        require(_newDAO != address(0), "Invalid DAO address");
        dao = _newDAO;
        emit DAOUpdated(_newDAO);
    }

    function setSkillCategory(bytes32 skillHash, bool isActive) external onlyDAO {
        validSkillCategories[skillHash] = isActive;
        emit SkillCategoryUpdated(skillHash, isActive);
    }

    function assignSoulSkill(address user, string memory category, bytes32 skillHash, uint256 impact) external onlyDAO {
        SoulSkill memory skill = SoulSkill(user, category, skillHash, block.timestamp, impact);
        userSkills[user].push(skill);
        emit SoulSkillAssigned(user, category, skillHash, impact);
    }

    /*───────────────────────────── VIEW FUNCTIONS ─────────────────────────────*/
    function getSkills(address user) external view returns (SoulSkill[] memory) {
        return userSkills[user];
    }

    function getUserSkillImpact(address user) external view returns (uint256 totalImpact) {
        SoulSkill[] memory skills = userSkills[user];
        for (uint256 i = 0; i < skills.length; i++) {
            totalImpact += skills[i].impact;
        }
    }

    /*───────────────────────────── ERC2771Context OVERRIDES ─────────────────────────────*/
    // Override _msgSender and _msgData from ERC2771Context only
    function _msgSender() internal view override returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view override returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }
}

