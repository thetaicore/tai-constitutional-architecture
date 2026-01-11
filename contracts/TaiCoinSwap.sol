// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/*───────────────────────────── INTERFACES ─────────────────────────────*/
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

interface ITaiCoin {
    function mint(address to, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
    function decimals() external view returns (uint8);
    function hasRole(bytes32 role, address account) external view returns (bool);
}

interface ITaiPegOracle {
    function isOfficialOneToOneUSD() external view returns (bool);
}

interface ITaiVaultMerkleClaim {
    function isGenesisActive() external view returns (bool);
}

interface ITaiAI {
    function evaluateSwapDecision(uint256 usdAmount, uint256 taiAmount) external view returns (bool);
}

/*───────────────────────────── CONTRACT ─────────────────────────────*/
contract TaiCoinSwapV1 is ERC2771Context, Ownable, ReentrancyGuard {

    /*═════════════════════════════════
        CONSTANTS
    ═════════════════════════════════*/

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /*═════════════════════════════════
        CORE REFERENCES
    ═════════════════════════════════*/

    IERC20 public immutable usdToken;
    ITaiCoin public immutable taiCoin;

    ITaiPegOracle public oracle;
    ITaiVaultMerkleClaim public vaultClaim;
    ITaiAI public taiAI;

    address public governor;
    bool public swapsPaused;
    bool public genesisTriggered;
    bool public mintAuthorityConfirmed;

    /*═════════════════════════════════
        EVENTS
    ═════════════════════════════════*/

    event SwapExecuted(address indexed user, uint256 usdAmount, uint256 taiAmount);
    event ReverseSwapExecuted(address indexed user, uint256 taiAmount, uint256 usdAmount);
    event GenesisActivated(address indexed firstUser);
    event MintAuthorityVerified(address indexed taiCoin, address indexed minter);
    event OracleUpdated(address indexed newOracle);
    event GovernorUpdated(address indexed newGovernor);
    event SwapsPaused(bool paused);

    /*═════════════════════════════════
        MODIFIERS
    ═════════════════════════════════*/

    modifier onlyGov() {
        require(_msgSender() == governor, "Not governor");
        _;
    }

    modifier whenActive() {
        require(!swapsPaused, "Swaps paused");
        _;
    }

    modifier whenMintReady() {
        require(mintAuthorityConfirmed, "Mint authority not confirmed");
        _;
    }

    /*═════════════════════════════════
        CONSTRUCTOR (OPTION B SAFE)
    ═════════════════════════════════*/
    constructor(
        address trustedForwarder,
        address usd,
        address tai,
        address oracle_,
        address vault_,
        address gov_,
        address taiAI_
    )
        ERC2771Context(trustedForwarder)
        Ownable()
    {
        transferOwnership(gov_);

        usdToken = IERC20(usd);
        taiCoin = ITaiCoin(tai);
        oracle = ITaiPegOracle(oracle_);
        vaultClaim = ITaiVaultMerkleClaim(vault_);
        governor = gov_;
        taiAI = ITaiAI(taiAI_);
    }

    /*═════════════════════════════════
        POST-DEPLOY WIRING
    ═════════════════════════════════*/

    function verifyMintAuthority() external onlyGov {
        require(
            taiCoin.hasRole(MINTER_ROLE, address(this)),
            "MINTER_ROLE not granted"
        );
        mintAuthorityConfirmed = true;
        emit MintAuthorityVerified(address(taiCoin), address(this));
    }

    /*═════════════════════════════════
        ERC2771 OVERRIDES
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

    /*═════════════════════════════════
        USD → TAI
    ═════════════════════════════════*/

    function swapUSDforTai(uint256 usdAmount)
        external
        whenActive
        whenMintReady
        nonReentrant
    {
        require(oracle.isOfficialOneToOneUSD(), "Oracle not 1:1");
        require(taiAI.evaluateSwapDecision(usdAmount, 0), "TAI rejected swap");

        usdToken.transferFrom(_msgSender(), address(this), usdAmount);

        uint256 taiAmount = _normalize(
            usdAmount,
            usdToken.decimals(),
            taiCoin.decimals()
        );

        taiCoin.mint(_msgSender(), taiAmount);

        if (!genesisTriggered) {
            genesisTriggered = true;
            emit GenesisActivated(_msgSender());
        }

        emit SwapExecuted(_msgSender(), usdAmount, taiAmount);
    }

    /*═════════════════════════════════
        TAI → USD
    ═════════════════════════════════*/

    function swapTaiForUSD(uint256 taiAmount)
        external
        whenActive
        whenMintReady
        nonReentrant
    {
        require(oracle.isOfficialOneToOneUSD(), "Oracle not 1:1");
        require(taiAI.evaluateSwapDecision(0, taiAmount), "TAI rejected reverse swap");

        uint256 usdAmount = _normalize(
            taiAmount,
            taiCoin.decimals(),
            usdToken.decimals()
        );

        taiCoin.burnFrom(_msgSender(), taiAmount);
        usdToken.transfer(_msgSender(), usdAmount);

        emit ReverseSwapExecuted(_msgSender(), taiAmount, usdAmount);
    }

    /*═════════════════════════════════
        GOVERNANCE
    ═════════════════════════════════*/

    function pauseSwaps(bool pause) external onlyGov {
        swapsPaused = pause;
        emit SwapsPaused(pause);
    }

    function setOracle(address newOracle) external onlyGov {
        oracle = ITaiPegOracle(newOracle);
        emit OracleUpdated(newOracle);
    }

    function setGovernor(address newGov) external onlyGov {
        governor = newGov;
        emit GovernorUpdated(newGov);
    }

    function withdrawUSD(address to, uint256 amount) external onlyGov {
        usdToken.transfer(to, amount);
    }

    /*═════════════════════════════════
        INTERNAL
    ═════════════════════════════════*/

    function _normalize(
        uint256 amt,
        uint8 fromD,
        uint8 toD
    ) internal pure returns (uint256) {
        return fromD < toD
            ? amt * 10 ** (toD - fromD)
            : amt / 10 ** (fromD - toD);
    }
}

