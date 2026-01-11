// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*───────────────────────────── IMPORTS ─────────────────────────────*/
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/*───────────────────────────── INTERFACES ─────────────────────────────*/
interface ITaiCoin is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function exponentialMint(address to, uint256 baseAmount) external returns (uint256);
}

interface IOracle {
    function getPrice() external view returns (uint256);
}

interface IProofOfLight {
    function validateProofOfLight(bytes32 lightHash) external view returns (bool);
}

interface ITaiAI {
    function validateMintingParameters(uint256 baseAmount) external view returns (bool);
}

/*───────────────────────────── CONTRACT ─────────────────────────────*/
contract TaiVault is ERC2771Context, Ownable, Pausable, ReentrancyGuard {

    /*═════════════════════════════════
        CORE STATE
    ═════════════════════════════════*/

    IERC20 public immutable collateralToken;
    ITaiCoin public immutable taiCoin;

    IOracle public oracle;
    IProofOfLight public proofOfLight;
    ITaiAI public taiAI;

    address public dao;
    address public gasRelayer;

    uint256 public totalCollateral;
    uint256 public collateralRatio = 150; // 150%

    /*═════════════════════════════════
        METAPHYSICAL METRICS
    ═════════════════════════════════*/

    uint256 public resonanceHarmonics;
    uint256 public polarityHealingIndex;
    uint256 public fractalCoherence;
    uint256 public serviceImpactMetric;

    /*═════════════════════════════════
        EVENTS
    ═════════════════════════════════*/

    event Deposited(address indexed user, uint256 collateralIn, uint256 taiOut);
    event Withdrawn(address indexed user, uint256 taiBurned, uint256 collateralOut);
    event DAOUpdated(address indexed newDAO);
    event OracleUpdated(address indexed newOracle);
    event ProofOfLightUpdated(address indexed newProof);
    event CollateralRatioUpdated(uint256 newRatio);

    /*═════════════════════════════════
        MODIFIERS
    ═════════════════════════════════*/

    modifier onlyDAOorOwner() {
        require(
            _msgSender() == owner() || _msgSender() == dao,
            "TaiVault: not authorized"
        );
        _;
    }

    /*═════════════════════════════════
        CONSTRUCTOR (BOOTSTRAP SAFE)
    ═════════════════════════════════*/

    constructor(
        address _collateralToken,
        address _taiCoin,
        address _oracle,
        address _taiAI,
        address _forwarder
    ) ERC2771Context(_forwarder) {
        require(_collateralToken != address(0), "Vault: zero collateral");
        require(_taiCoin != address(0), "Vault: zero TaiCoin");
        require(_oracle != address(0), "Vault: zero oracle");
        require(_taiAI != address(0), "Vault: zero AI");

        collateralToken = IERC20(_collateralToken);
        taiCoin = ITaiCoin(_taiCoin);
        oracle = IOracle(_oracle);
        taiAI = ITaiAI(_taiAI);
    }

    /*═════════════════════════════════
        CONFIGURATION (PHASED SAFE)
    ═════════════════════════════════*/

    function setDAO(address _dao) external onlyOwner {
        require(_dao != address(0), "Vault: zero DAO");
        dao = _dao;
        emit DAOUpdated(_dao);
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Vault: zero oracle");
        oracle = IOracle(_oracle);
        emit OracleUpdated(_oracle);
    }

    function setProofOfLight(address _pol) external onlyOwner {
        require(_pol != address(0), "Vault: zero proof");
        proofOfLight = IProofOfLight(_pol);
        emit ProofOfLightUpdated(_pol);
    }

    function setGasRelayer(address _relayer) external onlyOwner {
        gasRelayer = _relayer;
    }

    function setCollateralRatio(uint256 newRatio) external onlyDAOorOwner {
        require(newRatio >= 100, "Vault: ratio too low");
        collateralRatio = newRatio;
        emit CollateralRatioUpdated(newRatio);
    }

    /*═════════════════════════════════
        CORE VAULT LOGIC
    ═════════════════════════════════*/

    function deposit(
        uint256 collateralAmount,
        bytes32 lightHash
    ) external nonReentrant whenNotPaused {
        require(collateralAmount > 0, "Vault: zero deposit");
        require(address(proofOfLight) != address(0), "Vault: proof unset");
        require(proofOfLight.validateProofOfLight(lightHash), "Vault: invalid proof");

        collateralToken.transferFrom(_msgSender(), address(this), collateralAmount);
        totalCollateral += collateralAmount;

        uint256 baseTai = (collateralAmount * 100) / collateralRatio;
        require(
            taiAI.validateMintingParameters(baseTai),
            "Vault: AI rejected mint"
        );

        uint256 minted = taiCoin.exponentialMint(_msgSender(), baseTai);
        emit Deposited(_msgSender(), collateralAmount, minted);
    }

    function withdraw(
        uint256 taiAmount
    ) external nonReentrant whenNotPaused {
        require(taiAmount > 0, "Vault: zero withdraw");

        uint256 collateralOut = (taiAmount * collateralRatio) / 100;
        require(totalCollateral >= collateralOut, "Vault: undercollateralized");

        taiCoin.transferFrom(_msgSender(), address(this), taiAmount);
        taiCoin.burn(taiAmount);

        collateralToken.transfer(_msgSender(), collateralOut);
        totalCollateral -= collateralOut;

        emit Withdrawn(_msgSender(), taiAmount, collateralOut);
    }

    /*═════════════════════════════════
        PAUSING (SAFE FOR GOVERNANCE)
    ═════════════════════════════════*/

    function pause() external onlyDAOorOwner {
        _pause();
    }

    function unpause() external onlyDAOorOwner {
        _unpause();
    }

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

