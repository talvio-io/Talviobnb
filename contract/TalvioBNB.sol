// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
/// The 7,777 pixel images + metadata are hosted in the GitHub repo
/// (talvio-io/Talviobnb: nft/images + nft/meta); baseURI points at the
/// raw.githubusercontent meta URL.
/// @notice Rules (Talvio's BNB design, revised 2026-11-10 so paid mint runs in
/// parallel with the free phase and $TALV is paid out inside the mint itself):
/// - MAX_SUPPLY 7,777.
/// - TWO MINT PATHS, both live from the moment mint opens:
///   * mintFree(): the first FREE_LIMIT (777) free mints are for wallets
///     holding a Binance Agent ID (registry below, balanceOf > 0), 1 free
///     mint per wallet (MAX_FREE_PER_WALLET = 1). The free quota is counted
///     by totalFreeMinted, so paid mints NEVER eat into it, and the free
///     phase ends only when 777 free mints have actually been claimed.
///   * mintPaid(qty): open to ANY personal wallet from the start — nobody
///     waits for the free phase to finish. PAID_FEE = 0.0015 BNB per token.
/// - MAX_PER_WALLET 5: no wallet may mint more than 5 tokens in total
///   (free + paid combined). This is the site's "max 5/wallet".
/// - RANDOM DRAW: token IDs are NOT minted in order. Each mint draws its
///   token IDs at random from the pool of not-yet-minted IDs (1..7777), so
///   nobody can predict or snipe a specific Relic (e.g. a Legendary whose
///   metadata is publicly known). The pool is a virtual array with
///   swap-remove draws: every ID is drawn exactly once and no 7,777-entry
///   array is ever stored. Randomness is on-chain pseudo-randomness
///   (blockhash + timestamp + sender + a rolling nonce), the same style as
///   other agent-mint pools — it is not Chainlink VRF.
/// - $TALV REWARD, PAID INSIDE THE MINT TRANSACTION: every minted Relic
///   earns $TALV — FREE_TALV_REWARD (48,888,800 TALV) for a free mint,
///   PAID_TALV_REWARD (488,888,000 TALV) for a paid one. The reward is
///   transferred to the minter in the same transaction, out of the $TALV
///   balance this contract holds. The owner funds that balance with plain
///   ERC-20 transfers to this contract (after setTalvToken) and can top it
///   up at any time. If the balance ever runs short mid-mint, the mint
///   still succeeds: the unpaid remainder is recorded in talvOwed[minter]
///   and can be pulled later with claimOwed() once the contract is topped
///   up. Max possible reward liability if all 7,777 sell out:
///   777 * 48,888,800 + 7,000 * 488,888,000 = 3,460,202,597,600 TALV of the
///   7.77 trillion total supply.
/// - $TALV itself is a separate token contract (TalvioToken.sol, deployed
///   from the deploy console): fixed 7.77 trillion supply, all minted to
///   its deployer; this contract only holds and forwards it as rewards.
/// - BNB fees are HELD in the contract (not forwarded). The owner collects
///   accumulated fees with withdraw(). Network gas is separate and
///   variable, paid to validators.
/// - Personal wallets only for minting (msg.sender == tx.origin, contract
///   callers rejected).
/// - tokenURI = baseURI + tokenId + ".json" (meta files are N.json).
/// - mintOpen defaults FALSE: the owner opens mint only after baseURI is
///   set, the $TALV token is linked, and the reward balance is funded.
/// - withdraw() (onlyOwner): sends the whole BNB balance to the owner.
///   rescueTalv() (onlyOwner): pulls $TALV back out of this contract
///   (e.g. excess funding). No receive/fallback: plain BNB sends revert,
///   so the BNB balance only grows from mint fees.
contract Talvio is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant FREE_LIMIT = 777;
    uint256 public constant MAX_PER_WALLET = 5;
    uint256 public constant MAX_FREE_PER_WALLET = 1;
    uint256 public constant PAID_FEE = 0.0015 ether; // BNB on BNB Smart Chain

    /// @notice $TALV paid out per Relic, by mint path (18 decimals).
    uint256 public constant FREE_TALV_REWARD = 48888800 ether;
    uint256 public constant PAID_TALV_REWARD = 488888000 ether;

    /// @notice Binance Agent ID registry on BNB Chain. On-chain read only;
    /// the registry itself is not owned or controlled by this contract.
    address public constant AGENT_ID_REGISTRY = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    string public baseURI;
    bool public mintOpen;
    uint256 public totalMinted;
    /// @notice Free mints claimed so far; the free phase ends at FREE_LIMIT.
    uint256 public totalFreeMinted;
    mapping(address => uint256) public mintedByWallet;
    mapping(address => uint256) public freeMintedByWallet;

    /// @notice The $TALV token this contract pays rewards in (owner-set).
    IERC20 public talvToken;
    /// @notice $TALV a wallet is still owed because the reward balance ran
    /// short during its mint; pull it with claimOwed() after a top-up.
    mapping(address => uint256) public talvOwed;

    /// @notice Token IDs still in the draw pool (MAX_SUPPLY - totalMinted).
    uint256 public remaining;
    /// @notice Virtual draw pool: _pool[i] is the token ID at pool position i,
    /// where 0 means "identity" (position i holds token ID i + 1). Draws are
    /// swap-remove, so the mapping stays sparse and draws cost O(1).
    mapping(uint256 => uint256) private _pool;
    uint256 private _randNonce;

    event BaseURISet(string baseURI);
    event Minted(address indexed wallet, uint256 indexed tokenId);
    event TalvTokenSet(address indexed token);
    event TalvReward(address indexed wallet, uint256 paidOut, uint256 owedAdded);

    constructor(string memory _baseURI) ERC721("Talvio Pixel Relic", "TALV") {
        baseURI = _baseURI;
        remaining = MAX_SUPPLY;
    }

    /// @notice True when `wallet` holds at least one Binance Agent ID.
    function hasAgentId(address wallet) public view returns (bool) {
        return IAgentId(AGENT_ID_REGISTRY).balanceOf(wallet) > 0;
    }

    /// @notice True while `wallet` can still take its free Agent ID mint:
    /// free quota left, wallet has not used its 1 free mint, holds an
    /// Agent ID.
    function freeAvailable(address wallet) public view returns (bool) {
        return
            totalFreeMinted < FREE_LIMIT &&
            freeMintedByWallet[wallet] < MAX_FREE_PER_WALLET &&
            hasAgentId(wallet);
    }

    /// @notice Fee for the next single token `wallet` would mint: 0 while a
    /// free Agent ID mint is still available to them, otherwise PAID_FEE.
    function feeForNext(address wallet) public view returns (uint256) {
        if (freeAvailable(wallet)) {
            return 0;
        }
        return PAID_FEE;
    }

    /// @notice Fee for the next single token, ignoring the free allowance
    /// (the paid price). Kept for the site's live price display.
    function currentFee() public pure returns (uint256) {
        return PAID_FEE;
    }

    /// @notice Total BNB fee for minting `qty` Relics via mintPaid().
    /// (Free claims go through mintFree() and always cost 0; the `wallet`
    /// parameter is kept so existing callers keep working.)
    function quoteFor(address wallet, uint256 qty) public pure returns (uint256) {
        wallet; // unused: the paid price is the same for everyone
        return qty * PAID_FEE;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    function setMintOpen(bool _open) external onlyOwner {
        mintOpen = _open;
    }

    /// @notice Link the $TALV token contract that rewards are paid in.
    function setTalvToken(address _token) external onlyOwner {
        talvToken = IERC20(_token);
        emit TalvTokenSet(_token);
    }

    function withdraw() external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "empty");
        (bool ok, ) = owner().call{value: bal}("");
        require(ok, "withdraw failed");
    }

    /// @notice Pull $TALV back out of this contract (onlyOwner), e.g. to
    /// recover excess reward funding.
    function rescueTalv(uint256 amount) external onlyOwner {
        require(address(talvToken) != address(0), "no token");
        require(talvToken.transfer(owner(), amount), "transfer failed");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    /// @notice Token ID stored at pool position `idx` (identity when unset).
    function _poolIdAt(uint256 idx) internal view returns (uint256) {
        uint256 v = _pool[idx];
        return v == 0 ? idx + 1 : v;
    }

    /// @notice Draw one token ID at random from the remaining pool and remove
    /// it (swap-remove: the last pool entry moves into the drawn slot).
    function _draw() internal returns (uint256 tokenId) {
        uint256 last = remaining - 1;
        uint256 r = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.timestamp,
                    msg.sender,
                    _randNonce,
                    totalMinted
                )
            )
        ) % remaining;
        _randNonce += 1;
        tokenId = _poolIdAt(r);
        _pool[r] = _poolIdAt(last);
        remaining = last;
    }

    /// @notice Mint one Relic to `to` with a random draw.
    function _mintOne(address to) internal {
        uint256 tokenId = _draw();
        totalMinted += 1;
        mintedByWallet[to] += 1;
        _safeMint(to, tokenId);
        emit Minted(to, tokenId);
    }

    /// @notice Pay `amount` of $TALV to `user` out of this contract's reward
    /// balance. Any shortfall is recorded in talvOwed instead of reverting,
    /// so a mint can never fail just because the reward balance ran dry.
    function _settleReward(address user, uint256 amount) internal {
        uint256 pay = 0;
        if (address(talvToken) != address(0)) {
            uint256 bal = talvToken.balanceOf(address(this));
            pay = amount <= bal ? amount : bal;
            if (pay > 0 && !talvToken.transfer(user, pay)) {
                pay = 0;
            }
        }
        uint256 short = amount - pay;
        if (short > 0) {
            talvOwed[user] += short;
        }
        emit TalvReward(user, pay, short);
    }

    /// @notice Claim the free Agent ID mint: exactly 1 Relic, fee 0.
    /// Requires a Binance Agent ID and an unused free allowance; the free
    /// phase ends once FREE_LIMIT free mints have been claimed, independent
    /// of how many paid mints happen in the meantime. The Relic's $TALV
    /// reward (FREE_TALV_REWARD) is paid in this same transaction.
    function mintFree() external {
        require(mintOpen, "mint closed");
        require(msg.sender == tx.origin, "no contracts");
        require(totalFreeMinted < FREE_LIMIT, "free supply done");
        require(hasAgentId(msg.sender), "free mint needs Agent ID");
        require(
            freeMintedByWallet[msg.sender] < MAX_FREE_PER_WALLET,
            "max 1 free per Agent ID"
        );
        require(mintedByWallet[msg.sender] < MAX_PER_WALLET, "max 5 per wallet");
        require(totalMinted < MAX_SUPPLY, "supply");
        totalFreeMinted += 1;
        freeMintedByWallet[msg.sender] += 1;
        _mintOne(msg.sender);
        _settleReward(msg.sender, FREE_TALV_REWARD);
    }

    /// @notice Mint `qty` Relics at PAID_FEE each. Open to any personal
    /// wallet from the moment mint opens — it does NOT wait for the free
    /// phase to finish, and paid mints never consume the free quota. Each
    /// Relic's $TALV reward (PAID_TALV_REWARD) is paid in this same
    /// transaction.
    function mintPaid(uint256 qty) external payable {
        require(mintOpen, "mint closed");
        require(msg.sender == tx.origin, "no contracts");
        require(qty > 0, "qty zero");
        require(mintedByWallet[msg.sender] + qty <= MAX_PER_WALLET, "max 5 per wallet");
        require(totalMinted + qty <= MAX_SUPPLY, "supply");
        require(msg.value == qty * PAID_FEE, "wrong fee");
        for (uint256 i = 0; i < qty; i++) {
            _mintOne(msg.sender);
        }
        _settleReward(msg.sender, qty * PAID_TALV_REWARD);
        // Fees stay in the contract; the owner collects them with withdraw().
    }

    /// @notice Pull any $TALV still owed to you from a mint whose reward
    /// could not be fully paid at the time. Pays as much as the contract's
    /// current reward balance covers; the rest stays recorded as owed.
    function claimOwed() external {
        uint256 amount = talvOwed[msg.sender];
        require(amount > 0, "nothing owed");
        require(address(talvToken) != address(0), "no token");
        uint256 bal = talvToken.balanceOf(address(this));
        uint256 pay = amount <= bal ? amount : bal;
        require(pay > 0, "reward balance empty");
        talvOwed[msg.sender] = amount - pay;
        require(talvToken.transfer(msg.sender, pay), "transfer failed");
        emit TalvReward(msg.sender, pay, 0);
    }
}
