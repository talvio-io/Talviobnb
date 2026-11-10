// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @notice Minimal read interface of the Talvio Pixel Relic NFT contract.
interface ITalvioRelic {
    function mintedByWallet(address wallet) external view returns (uint256);
    function freeMintedByWallet(address wallet) external view returns (uint256);
}

/// @title TalvioInvite — on-chain invite registry for Talvio Pixel Relic.
/// @notice The NFT contract (0x11257ad917089719618288f9b8cf331496d522d4) is
/// immutable and its mint functions take no inviter argument, so invites
/// are recorded by this companion registry instead:
/// - After a wallet's first PAID mint (paid count = mintedByWallet -
///   freeMintedByWallet on the NFT contract, so free-only wallets cannot
///   game it), the wallet may register its inviter exactly once with
///   registerInvite(inviter). Registration is permanent — the first
///   inviter named is the one that counts.
/// - inviteCount[inviter] is the inviter's point total. The site's
///   leaderboard and the "Valid invites" card read straight from here.
/// - The 10% inviter pool (BNB) is NOT held by this contract: mint fees
///   accumulate in the NFT contract, the owner withdraws them and pays
///   the top inviters proportional to inviteCount (owner-executed, using
///   this registry as the tamper-proof count).
/// - Personal wallets only (msg.sender == tx.origin), same as the mint.
contract TalvioInvite {
    ITalvioRelic public immutable nft;

    /// @notice The inviter a wallet registered (zero if none).
    mapping(address => address) public inviterOf;
    /// @notice True once a wallet has registered its inviter.
    mapping(address => bool) public registered;
    /// @notice Invite points per inviter.
    mapping(address => uint256) public inviteCount;
    /// @notice Total wallets that registered an inviter.
    uint256 public totalRegistered;

    /// @notice Unique inviters, in first-seen order (for the leaderboard).
    address[] public inviters;
    mapping(address => bool) private _isInviter;

    event Registered(address indexed invitee, address indexed inviter);

    constructor(address _nft) {
        nft = ITalvioRelic(_nft);
    }

    /// @notice Paid mints of `wallet` (total mints minus free claims).
    function paidMinted(address wallet) public view returns (uint256) {
        return nft.mintedByWallet(wallet) - nft.freeMintedByWallet(wallet);
    }

    /// @notice Register `inviter` as your inviter. Requires at least one
    /// paid mint from your wallet; can only ever be called once per wallet.
    function registerInvite(address inviter) external {
        require(msg.sender == tx.origin, "no contracts");
        require(!registered[msg.sender], "already registered");
        require(inviter != address(0), "zero inviter");
        require(inviter != msg.sender, "self invite");
        require(paidMinted(msg.sender) > 0, "paid mint required");
        registered[msg.sender] = true;
        inviterOf[msg.sender] = inviter;
        if (!_isInviter[inviter]) {
            _isInviter[inviter] = true;
            inviters.push(inviter);
        }
        inviteCount[inviter] += 1;
        totalRegistered += 1;
        emit Registered(msg.sender, inviter);
    }

    /// @notice Number of unique inviters (leaderboard length).
    function invitersLength() external view returns (uint256) {
        return inviters.length;
    }
}
