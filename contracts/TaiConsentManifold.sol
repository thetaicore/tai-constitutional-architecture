// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    TAI CONSENT MANIFOLD

    SYSTEM ROLE:
    - Canonical declaration of decision authority boundaries
    - Explicit consent topology for human, AI, and protocol domains
    - Non-governing, non-executive, declarative only

    THIS CONTRACT:
    - Does NOT grant permissions
    - Does NOT enforce outcomes
    - Does NOT override governance
    - Does NOT execute protocol logic
*/

import "@openzeppelin/contracts/access/Ownable.sol";

contract TaiConsentManifold is Ownable {

    /*═══════════════════════════════════════════════════════════════
                                ENUMS
    ═══════════════════════════════════════════════════════════════*/

    enum DecisionDomain {
        UNDEFINED,
        ORACLE_ASSERTION,
        AI_EVALUATION,
        CLAIM_ADJUDICATION,
        GOVERNANCE_PROPOSAL,
        GOVERNANCE_EXECUTION,
        EPOCH_TRANSITION,
        CROSS_CHAIN_ASSERTION,
        FINALITY_SEALING,
        EMERGENCY_DECLARATION,
        CUSTOM
    }

    enum ConsentType {
        NONE,
        HUMAN_ONLY,
        AI_ONLY,
        HUMAN_AND_AI,
        GOVERNANCE_ONLY,
        AI_ADVISORY,
        HUMAN_OVERRIDE,
        MULTI_PARTY
    }

    /*═══════════════════════════════════════════════════════════════
                                STRUCTS
    ═══════════════════════════════════════════════════════════════*/

    struct ConsentRule {
        DecisionDomain domain;
        ConsentType consentType;
        uint256 epoch;
        bool immutableRule;
        uint256 declaredAt;
        string description;
    }

    /*═══════════════════════════════════════════════════════════════
                                STORAGE
    ═══════════════════════════════════════════════════════════════*/

    uint256 public totalRules;

    // ruleId => ConsentRule
    mapping(uint256 => ConsentRule) private rules;

    // decision domain => ruleIds
    mapping(DecisionDomain => uint256[]) private domainRules;

    /*═══════════════════════════════════════════════════════════════
                                EVENTS
    ═══════════════════════════════════════════════════════════════*/

    event ConsentRuleDeclared(
        uint256 indexed ruleId,
        DecisionDomain indexed domain,
        ConsentType consentType,
        uint256 epoch,
        bool immutableRule
    );

    /*═══════════════════════════════════════════════════════════════
                            CONSTRUCTOR
    ═══════════════════════════════════════════════════════════════*/

    constructor(address initialOwner) {
        require(initialOwner != address(0), "Invalid owner");
        _transferOwnership(initialOwner);
    }

    /*═══════════════════════════════════════════════════════════════
                        CONSENT DECLARATION LOGIC
    ═══════════════════════════════════════════════════════════════*/

    function declareConsentRule(
        DecisionDomain domain,
        ConsentType consentType,
        uint256 epoch,
        bool immutableRule,
        string calldata description
    ) external onlyOwner returns (uint256 ruleId) {
        require(domain != DecisionDomain.UNDEFINED, "Invalid domain");
        require(consentType != ConsentType.NONE, "Invalid consent");

        totalRules += 1;
        ruleId = totalRules;

        rules[ruleId] = ConsentRule({
            domain: domain,
            consentType: consentType,
            epoch: epoch,
            immutableRule: immutableRule,
            declaredAt: block.timestamp,
            description: description
        });

        domainRules[domain].push(ruleId);

        emit ConsentRuleDeclared(
            ruleId,
            domain,
            consentType,
            epoch,
            immutableRule
        );
    }

    /*═══════════════════════════════════════════════════════════════
                            VIEW FUNCTIONS
    ═══════════════════════════════════════════════════════════════*/

    function getRule(uint256 ruleId)
        external
        view
        returns (ConsentRule memory)
    {
        require(ruleId > 0 && ruleId <= totalRules, "Invalid rule");
        return rules[ruleId];
    }

    function getRulesForDomain(DecisionDomain domain)
        external
        view
        returns (uint256[] memory)
    {
        return domainRules[domain];
    }

    function latestRuleForDomain(DecisionDomain domain)
        external
        view
        returns (ConsentRule memory)
    {
        uint256[] memory ruleIds = domainRules[domain];
        require(ruleIds.length > 0, "No rules for domain");
        return rules[ruleIds[ruleIds.length - 1]];
    }

    function isRuleImmutable(uint256 ruleId)
        external
        view
        returns (bool)
    {
        require(ruleId > 0 && ruleId <= totalRules, "Invalid rule");
        return rules[ruleId].immutableRule;
    }
}
