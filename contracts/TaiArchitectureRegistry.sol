// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    TAI ARCHITECTURE REGISTRY

    SYSTEM ROLE:
    - Canonical, append-only architectural truth layer
    - Non-governing
    - Non-upgradeable
    - Non-authoritative
*/

import "@openzeppelin/contracts/access/Ownable.sol";

contract TaiArchitectureRegistry is Ownable {

    /*═══════════════════════════════════════════════════════════════
                                ENUMS
    ═══════════════════════════════════════════════════════════════*/

    enum ContractRole {
        UNDEFINED,
        PEG_ORACLE,
        SWAP,
        BRIDGE,
        VAULT,
        CLAIM,
        ACTIVATOR,
        REDISTRIBUTOR,
        GOVERNANCE,
        AI_ADJUDICATOR,
        REGISTRY,
        OBSERVER,
        FINALITY_ANCHOR,
        EPOCH_COORDINATOR,
        CONSENT_MANIFOLD,
        FAILURE_ATLAS,
        CUSTOM
    }

    enum AuthorityDomain {
        NONE,
        ECONOMIC,
        GOVERNANCE,
        AI_VALIDATION,
        MERKLE_TRUTH,
        CROSS_CHAIN,
        TEMPORAL_FINALITY,
        OBSERVATIONAL,
        META_PROTOCOL
    }

    /*═══════════════════════════════════════════════════════════════
                                STRUCTS
    ═══════════════════════════════════════════════════════════════*/

    struct ContractRecord {
        address contractAddress;
        ContractRole role;
        AuthorityDomain authority;
        uint256 chainId;
        uint256 epoch;
        uint256 registeredAt;
        bool genesisBound;
        bool active;
        string name;
        string description;
        address predecessor;
    }

    /*═══════════════════════════════════════════════════════════════
                                STORAGE
    ═══════════════════════════════════════════════════════════════*/

    uint256 public totalRecords;
    mapping(uint256 => ContractRecord) private records;
    mapping(address => uint256) private recordIndex;
    mapping(uint256 => uint256[]) private epochIndex;

    /*═══════════════════════════════════════════════════════════════
                                EVENTS
    ═══════════════════════════════════════════════════════════════*/

    event ContractRegistered(
        uint256 indexed recordId,
        address indexed contractAddress,
        ContractRole role,
        AuthorityDomain authority,
        uint256 indexed epoch,
        uint256 chainId,
        bool genesisBound
    );

    event ContractDeprecated(
        uint256 indexed recordId,
        address indexed contractAddress,
        uint256 deprecatedAtEpoch
    );

    /*═══════════════════════════════════════════════════════════════
                            CONSTRUCTOR
    ═══════════════════════════════════════════════════════════════*/

    constructor(address initialOwner) Ownable() {
        // No need to pass initialOwner argument to Ownable
    }

    /*═══════════════════════════════════════════════════════════════
                        REGISTRATION LOGIC
    ═══════════════════════════════════════════════════════════════*/

    function registerContract(
        address contractAddress,
        ContractRole role,
        AuthorityDomain authority,
        uint256 epoch,
        bool genesisBound,
        string calldata name,
        string calldata description,
        address predecessor
    ) external onlyOwner returns (uint256 recordId) {
        require(contractAddress != address(0), "Invalid address");
        require(recordIndex[contractAddress] == 0, "Already registered");

        totalRecords += 1;
        recordId = totalRecords;

        records[recordId] = ContractRecord({
            contractAddress: contractAddress,
            role: role,
            authority: authority,
            chainId: block.chainid,
            epoch: epoch,
            registeredAt: block.timestamp,
            genesisBound: genesisBound,
            active: true,
            name: name,
            description: description,
            predecessor: predecessor
        });

        recordIndex[contractAddress] = recordId;
        epochIndex[epoch].push(recordId);

        emit ContractRegistered(
            recordId,
            contractAddress,
            role,
            authority,
            epoch,
            block.chainid,
            genesisBound
        );
    }

    function deprecateContract(
        address contractAddress,
        uint256 deprecatedAtEpoch
    ) external onlyOwner {
        uint256 recordId = recordIndex[contractAddress];
        require(recordId != 0, "Not registered");
        require(records[recordId].active, "Already deprecated");

        records[recordId].active = false;

        emit ContractDeprecated(
            recordId,
            contractAddress,
            deprecatedAtEpoch
        );
    }

    /*═══════════════════════════════════════════════════════════════
                            VIEW FUNCTIONS
    ═══════════════════════════════════════════════════════════════*/

    function getRecordById(uint256 recordId)
        external
        view
        returns (ContractRecord memory)
    {
        require(recordId > 0 && recordId <= totalRecords, "Invalid record");
        return records[recordId];
    }

    function getRecordByAddress(address contractAddress)
        external
        view
        returns (ContractRecord memory)
    {
        uint256 recordId = recordIndex[contractAddress];
        require(recordId != 0, "Not registered");
        return records[recordId];
    }

    function getRecordsByEpoch(uint256 epoch)
        external
        view
        returns (uint256[] memory)
    {
        return epochIndex[epoch];
    }

    function isRegistered(address contractAddress)
        external
        view
        returns (bool)
    {
        return recordIndex[contractAddress] != 0;
    }

    function isActive(address contractAddress)
        external
        view
        returns (bool)
    {
        uint256 recordId = recordIndex[contractAddress];
        if (recordId == 0) return false;
        return records[recordId].active;
    }
}

