// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Talvio ($TALV) — the Talvio Pixel Relic ecosystem token (BEP-20).
/// @notice BNB Smart Chain (chain ID 56). Fixed supply, minted once at deploy:
/// - TOTAL_SUPPLY = 7,770,000,000,000 TALV (7.77 trillion), 18 decimals.
/// - The ENTIRE supply is minted to the deployer (the project owner) in the
///   constructor. There is NO mint function after deployment and no burn
///   function — the supply can never change.
/// - Intended allocation (from the project's published tokenomics — the split
///   itself is executed by the owner from their wallet, it is not enforced
///   on-chain): 82% liquidity (PancakeSwap V2 LP, paired with 82% of the
///   genesis funds, LP burned), 10% top-100 inviters, 8% treasury.
/// - No taxes, no fees, no blacklist, no proxy — a plain OpenZeppelin ERC-20.
/// - This token is separate from the Talvio Pixel Relic NFT (TalvioBNB.sol);
///   the NFTs determine how much $TALV each holder receives when the pool
///   opens, per the rarity table on the site.
contract TalvioToken is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 7_770_000_000_000 * 10 ** 18;

    constructor() ERC20("Talvio", "TALV") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}
