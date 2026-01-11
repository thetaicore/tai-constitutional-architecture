// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TaiBridgeVaultLZ
 * @notice Cross-chain settlement & transport layer for TaiBridgeVault intents
 * @dev LayerZero v2 + ERC2771 compatible, governor-controlled
 */
contract TaiBridgeVaultLZ is
    OApp,
    ERC2771Context,
    ReentrancyGuard,
    Pausable
{
    /*───────────────────────────── STATE ─────────────────────────────*/
    address public governor;
    bool public initialized;

    // user => bridged amount (accounting / observability)
    mapping(address => uint256) public bridgedBalance;

    // LayerZero trusted remotes
    mapping(uint32 => bytes32) public trustedPeers;

    /*───────────────────────────── EVENTS ─────────────────────────────*/
    event GovernorUpdated(address indexed newGovernor);
    event TrustedPeerSet(uint32 indexed eid, bytes32 peer);
    event CrossChainSent(uint32 indexed dstEid, address indexed user, uint256 amount);
    event CrossChainReceived(uint32 indexed srcEid, address indexed user, uint256 amount);

    /*───────────────────────────── CONSTRUCTOR ─────────────────────────────*/
    constructor(
        address _endpoint,
        address _forwarder
    )
        ERC2771Context(_forwarder)
        OApp(_endpoint, msg.sender) // MUST be deployer
    {
        require(_endpoint != address(0), "Invalid endpoint");
        require(_forwarder != address(0), "Invalid forwarder");

        // Temporary governor = deployer
        governor = msg.sender;
        initialized = false;
    }

    /*───────────────────────────── POST-DEPLOY INITIALIZER ─────────────────────────────*/
    /**
     * @notice Finalizes deployment and transfers governance
     * @dev MUST be called once after deployment
     */
    function initialize(address finalGovernor) external {
        require(!initialized, "Already initialized");
        require(msg.sender == governor, "Only temp governor");
        require(finalGovernor != address(0), "Invalid governor");

        initialized = true;
        governor = finalGovernor;

        emit GovernorUpdated(finalGovernor);
    }

    /*───────────────────────────── ERC2771 OVERRIDES ─────────────────────────────*/
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

    /*───────────────────────────── GOVERNANCE ─────────────────────────────*/
    modifier onlyGovernor() {
        require(_msgSender() == governor, "Not governor");
        _;
    }

    modifier onlyInitialized() {
        require(initialized, "Not initialized");
        _;
    }

    function setGovernor(address newGovernor)
        external
        onlyGovernor
        onlyInitialized
    {
        require(newGovernor != address(0), "Governor cannot be zero");
        governor = newGovernor;
        emit GovernorUpdated(newGovernor);
    }

    function setTrustedPeer(uint32 eid, bytes32 peer)
        external
        onlyGovernor
        onlyInitialized
    {
        trustedPeers[eid] = peer;
        emit TrustedPeerSet(eid, peer);
    }

    /*───────────────────────────── CROSS-CHAIN SEND ─────────────────────────────*/
    function sendCrossChain(
        uint32 dstEid,
        address user,
        uint256 amount
    )
        external
        payable
        onlyGovernor
        onlyInitialized
        nonReentrant
        whenNotPaused
    {
        require(user != address(0), "Invalid user");
        require(amount > 0, "Amount must be > 0");

        bytes memory payload = abi.encode(user, amount);

        MessagingFee memory fee = MessagingFee({
            nativeFee: msg.value,
            lzTokenFee: 0
        });

        _lzSend(
            dstEid,
            payload,
            bytes(""),
            fee,
            payable(_msgSender())
        );

        emit CrossChainSent(dstEid, user, amount);
    }

    /*───────────────────────────── CROSS-CHAIN RECEIVE ─────────────────────────────*/
    function _lzReceive(
        Origin calldata origin,
        bytes32,
        bytes calldata payload,
        address,
        bytes calldata
    )
        internal
        override
        whenNotPaused
    {
        require(trustedPeers[origin.srcEid] == origin.sender, "Untrusted peer");

        (address user, uint256 amount) = abi.decode(payload, (address, uint256));

        bridgedBalance[user] += amount;

        emit CrossChainReceived(origin.srcEid, user, amount);
    }

    /*───────────────────────────── EMERGENCY ─────────────────────────────*/
    function pause() external onlyGovernor {
        _pause();
    }

    function unpause() external onlyGovernor {
        _unpause();
    }

    function emergencyWithdrawERC20(
        IERC20 token,
        address to,
        uint256 amount
    )
        external
        onlyGovernor
        onlyInitialized
        nonReentrant
    {
        require(to != address(0), "Invalid address");
        require(token.transfer(to, amount), "Transfer failed");
    }
}

