// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/*───────────────────────────── INTERFACES ─────────────────────────────*/
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface ITaiPegOracle {
    function merkleRoot() external view returns (bytes32);
    function genesisFinalized() external view returns (bool);
}

interface ITaiAI {
    function evaluateClaim(address user, uint256 amount) external view returns (bool);
}

/*───────────────────────────── CONTRACT ─────────────────────────────*/
contract TaiVaultMerkleClaimV1 is ERC2771Context, Ownable, ReentrancyGuard {

    /*═════════════════════════════════
        EVENTS
    ═════════════════════════════════*/

    event Claimed(address indexed user, address indexed token, uint256 amount);
    event GovernorUpdated(address indexed newGovernor);

    /*═════════════════════════════════
        STATE
    ═════════════════════════════════*/

    address public governor;
    ITaiPegOracle public immutable oracle;
    ITaiAI public taiAI;

    mapping(address => bool) public hasClaimed;

    /*═════════════════════════════════
        MODIFIERS
    ═════════════════════════════════*/

    modifier onlyGov() {
        require(_msgSender() == governor, "Vault: not governor");
        _;
    }

    /*═════════════════════════════════
        CONSTRUCTOR (SYSTEM-CANONICAL)
    ═════════════════════════════════*/
    constructor(
        address trustedForwarder,
        address oracle_,
        address governor_,
        address taiAI_
    )
        ERC2771Context(trustedForwarder)
        Ownable() // ⚡ v5+ pattern: no argument
    {
        require(oracle_ != address(0), "Vault: zero oracle");
        require(governor_ != address(0), "Vault: zero governor");
        require(taiAI_ != address(0), "Vault: zero AI");

        // Manually transfer ownership
        transferOwnership(governor_);

        oracle = ITaiPegOracle(oracle_);
        governor = governor_;
        taiAI = ITaiAI(taiAI_);
    }

    /*═════════════════════════════════
        GOVERNANCE
    ═════════════════════════════════*/

    function setGovernor(address newGov) external onlyGov {
        require(newGov != address(0), "Vault: zero governor");
        governor = newGov;
        emit GovernorUpdated(newGov);
    }

    /*═════════════════════════════════
        EMERGENCY
    ═════════════════════════════════*/

    function emergencyWithdrawERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyGov nonReentrant {
        require(to != address(0), "Vault: zero address");
        require(token.transfer(to, amount), "Vault: transfer failed");
    }

    function emergencyWithdrawETH(
        address payable to,
        uint256 amount
    ) external onlyGov nonReentrant {
        require(to != address(0), "Vault: zero address");
        require(address(this).balance >= amount, "Vault: insufficient balance");
        to.transfer(amount);
    }

    /*═════════════════════════════════
        CLAIMS
    ═════════════════════════════════*/

    function claimETH(
        uint256 amount,
        bytes32[] calldata proof
    ) external nonReentrant {
        address user = _msgSender();
        _preClaimChecks(user, amount);

        bytes32 leaf = keccak256(
            abi.encodePacked(user, amount, "ETH")
        );

        require(
            _verifyProof(leaf, proof),
            "Vault: invalid proof"
        );

        require(
            taiAI.evaluateClaim(user, amount),
            "Vault: AI rejected claim"
        );

        hasClaimed[user] = true;
        payable(user).transfer(amount);

        emit Claimed(user, address(0), amount);
    }

    function claimERC20(
        IERC20 token,
        uint256 amount,
        bytes32[] calldata proof
    ) external nonReentrant {
        address user = _msgSender();
        _preClaimChecks(user, amount);

        bytes32 leaf = keccak256(
            abi.encodePacked(user, amount, address(token))
        );

        require(
            _verifyProof(leaf, proof),
            "Vault: invalid proof"
        );

        require(
            taiAI.evaluateClaim(user, amount),
            "Vault: AI rejected claim"
        );

        hasClaimed[user] = true;
        require(token.transfer(user, amount), "Vault: transfer failed");

        emit Claimed(user, address(token), amount);
    }

    /*═════════════════════════════════
        INTERNAL
    ═════════════════════════════════*/

    function _preClaimChecks(
        address user,
        uint256 amount
    ) internal view {
        require(oracle.genesisFinalized(), "Vault: genesis not finalized");
        require(!hasClaimed[user], "Vault: already claimed");
        require(amount > 0, "Vault: zero amount");
    }

    function _verifyProof(
        bytes32 leaf,
        bytes32[] memory proof
    ) internal view returns (bool) {
        bytes32 computed = leaf;
        bytes32 root = oracle.merkleRoot();

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 sibling = proof[i];
            computed = computed <= sibling
                ? keccak256(abi.encodePacked(computed, sibling))
                : keccak256(abi.encodePacked(sibling, computed));
        }

        return computed == root;
    }

    /*═════════════════════════════════
        RECEIVE
    ═════════════════════════════════*/

    receive() external payable {}

    /*═════════════════════════════════
        ERC2771 OVERRIDES (MANDATORY)
    ═════════════════════════════════*/

    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength()
        internal
        view
        override(Context, ERC2771Context)
        returns (uint256)
    {
        return ERC2771Context._contextSuffixLength();
    }
}

