// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IAgentId {
    function balanceOf(address account) external view returns (uint256);
}

/// @title Talvio Pixel Relic (TALV) — NFT for the Talvio Pixel Relics collection.
/// @notice BNB VERSION: ERC-721 on BNB Smart Chain (chain ID 56). Fees are in BNB.
/// This replaces the deleted Elysium build (TalvioElysium.sol, moved to the
/// recoverable trash 2026-11-09 at owner request "Kontrak juga hapus pakai bnb
/// aaja"). The Elysium contract was never deployed, so nothing is lost on-chain.
/// The 7,777 pixel images + metadata already exist locally at
/// ~/workspace/talvio/full/ (NOT hosted yet) — baseURI must point at the
/// hosted metadata URL once hosting is decided; do NOT invent one.
/// @notice Rules (Talvio's original BNB design, immutable in this contract except where noted):
/// - MAX_SUPPLY 7,777.
/// - FREE_LIMIT 777: the first 777 tokens minted are FREE (fee 0) — but ONLY
///   for wallets holding a Binance Agent ID (registry below, balanceOf > 0),
///   1 free mint per Agent ID (MAX_FREE_PER_WALLET = 1). A mint that straddles
///   the free boundary pays only for the tokens past it, and the free tokens
///   in it still count against the wallet's 1-free allowance. While the free
///   supply lasts, a wallet without an Agent ID cannot mint at all (its mint
///   would include free tokens it is not entitled to); after the first 777,
///   paid mint is open to ANY personal wallet.
/// - MAX_PER_WALLET 5: no wallet may mint more than 5 tokens in total
///   (free + paid combined). This is the site's "max 5/wallet".
/// - Paid fee: PAID_FEE = 0.0015 BNB per token after the free 777.
/// - Fees are HELD in the contract (not forwarded). The owner collects
///   accumulated fees with withdraw(). Network gas is separate and variable,
///   paid to validators.
/// - Personal wallets only (msg.sender == tx.origin, contract callers rejected).
/// - $TALV (7.77 trillion supply, 82% to LP) is a separate token plan and
///   is NOT this contract: this contract mints only the NFT, no $TALV. The
///   $TALV token contract will be made by the owner themselves.
/// - tokenURI = baseURI + tokenId + ".json" (meta files are N.json).
/// - mintOpen defaults FALSE: the owner opens mint only after baseURI is set.
/// - withdraw() (onlyOwner): sends the whole contract balance to the owner.
///   No receive/fallback: plain BNB sends revert, so the balance only grows
///   from mint fees.
contract Talvio is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant FREE_LIMIT = 777;
    uint256 public constant MAX_PER_WALLET = 5;
    uint256 public constant MAX_FREE_PER_WALLET = 1;
    uint256 public constant PAID_FEE = 0.0015 ether; // BNB on BNB Smart Chain

    /// @notice Binance Agent ID registry on BNB Chain. On-chain read only;
    /// the registry itself is not owned or controlled by this contract.
    address public constant AGENT_ID_REGISTRY = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    string public baseURI;
    bool public mintOpen;
    uint256 public totalMinted;
    mapping(address => uint256) public mintedByWallet;
    mapping(address => uint256) public freeMintedByWallet;

    event BaseURISet(string baseURI);

    constructor(string memory _baseURI) ERC721("Talvio Pixel Relic", "TALV") {
        baseURI = _baseURI;
    }

    /// @notice True when `wallet` holds at least one Binance Agent ID.
    function hasAgentId(address wallet) public view returns (bool) {
        return IAgentId(AGENT_ID_REGISTRY).balanceOf(wallet) > 0;
    }

    /// @notice Fee for the next single token `wallet` would mint: 0 while a
    /// free Agent ID mint is still available to them, otherwise PAID_FEE.
    function feeForNext(address wallet) public view returns (uint256) {
        if (
            totalMinted < FREE_LIMIT &&
            freeMintedByWallet[wallet] < MAX_FREE_PER_WALLET &&
            hasAgentId(wallet)
        ) {
            return 0;
        }
        return PAID_FEE;
    }

    /// @notice Fee for the next single token, ignoring the free boundary
    /// (the paid price). Kept for the site's live price display.
    function currentFee() public pure returns (uint256) {
        return PAID_FEE;
    }

    /// @notice Total fee for `qty` tokens minted now by `wallet`, counting
    /// the free boundary token by token and the wallet's 1-free allowance.
    /// (The Agent ID gate itself is enforced in mint(), not here.)
    function quoteFor(address wallet, uint256 qty) public view returns (uint256) {
        uint256 paid = 0;
        uint256 freeLeft = freeMintedByWallet[wallet] >= MAX_FREE_PER_WALLET
            ? 0
            : MAX_FREE_PER_WALLET - freeMintedByWallet[wallet];
        bool agent = hasAgentId(wallet);
        for (uint256 i = 0; i < qty; i++) {
            if (totalMinted + i < FREE_LIMIT && agent && freeLeft > 0) {
                freeLeft -= 1;
            } else {
                paid += 1;
            }
        }
        return paid * PAID_FEE;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    function setMintOpen(bool _open) external onlyOwner {
        mintOpen = _open;
    }

    function withdraw() external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "empty");
        (bool ok, ) = owner().call{value: bal}("");
        require(ok, "withdraw failed");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function mint(uint256 qty) external payable {
        require(mintOpen, "mint closed");
        require(msg.sender == tx.origin, "no contracts");
        require(qty > 0, "qty zero");
        require(mintedByWallet[msg.sender] + qty <= MAX_PER_WALLET, "max 5 per wallet");
        require(totalMinted + qty <= MAX_SUPPLY, "supply");
        uint256 freeCount = 0;
        for (uint256 i = 0; i < qty; i++) {
            if (totalMinted + i < FREE_LIMIT) freeCount += 1;
        }
        if (freeCount > 0) {
            require(hasAgentId(msg.sender), "free mint needs Agent ID");
            require(
                freeMintedByWallet[msg.sender] + freeCount <= MAX_FREE_PER_WALLET,
                "max 1 free per Agent ID"
            );
        }
        uint256 fee = (qty - freeCount) * PAID_FEE;
        require(msg.value == fee, "wrong fee");
        for (uint256 i = 0; i < qty; i++) {
            totalMinted += 1;
            mintedByWallet[msg.sender] += 1;
            _safeMint(msg.sender, totalMinted);
        }
        freeMintedByWallet[msg.sender] += freeCount;
        // Fees stay in the contract; the owner collects them with withdraw().
    }
}
