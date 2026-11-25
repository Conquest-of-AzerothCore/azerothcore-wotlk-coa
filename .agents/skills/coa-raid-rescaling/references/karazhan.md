# Karazhan worked example

These are historical conversion decisions and measurements, not a statement of current deployment status.
Recheck effective source, data, and verification before applying them to another raid.

| Input | Owner's decision |
|---|---|
| Release order | Generate a distinct Karazhan raid phase immediately after Naxxramas, expose it through the realm configuration and `.raidphase`, and use it for Karazhan entry, Callboard, and Manastorm release gates. Keep the existing Classic order. |
| Access | Archmage Alturus offers **The Key to Karazhan** (200837) at level 60. Accept it, earn Kel’Thuzad kill credit in Naxxramas on any difficulty, and return to Alturus for **The Master’s Key** (24490), which opens the physical gate. The rewarded quest grants permanent character access. Characters that completed both requirements under the earlier deployment retain access. Playerbots are exempt from personal attunement. |
| Combat | Fixed level-60 content. Reuse 10–25 flex and the current bot health weight. Support Normal, Heroic, Mythic, and Ascended. Verify and reuse existing modes and corresponding item tiers, and generate any that are missing. |
| Gear | Rebalance existing item IDs in place where appropriate, including gear already owned. Require at most level 60 to equip. Use Naxxramas as the entry benchmark. Make late Karazhan comparable drops clear upgrades. Normal Tier 4 sits slightly above Normal Tier 3. Preserve the realm's difficulty gear scaling and rebudget the entire item, including scripted effects. |
| Reputation | Earn Violet Eye reputation in Karazhan. Scale its rewards to the new tier. |
| Tokens and resets | Add Karazhan Tier 4 glove and helm redemption to the existing token vendor and preserve pagination. Keep glove tokens on Curator and helm tokens on Prince Malchezaar. Leave chest tokens on Magtheridon, shoulder tokens on High King Maulgar, and leg tokens on Gruul. Include Karazhan in Raid Registrar resets. Attunement is a permanent character unlock. |
| Callboard | Gate Karazhan rewards by realm phase. With `PreviousStageOnly` enabled, neither generic nor progress-bar caches can pay Karazhan gear at the Karazhan release phase. The Karazhan pool becomes eligible when a higher raid phase is active, subject to the usual cache rules. |
| Manastorm | Add Karazhan rewards at a higher tier appropriate to their item levels. Preserve existing depth-to-item-level breakpoints. |
| Playtest | Tune Normal for 10 players in mostly Normal Naxxramas gear. Start relatively easy and build toward a very challenging Prince Malchezaar, the final boss and difficulty benchmark. Keep optional bosses easier than Prince and estimate their tuning from the original encounters. Lean harder when tuning is uncertain, then adjust from playtest evidence. |
| Class effects | Prefer class-neutral mechanics and role-based replacements for set bonuses. Use the closest supported CoA ability when a set effect needs a specific ability or for standalone gear effects where appropriate. Make these decisions without prompting and list every mapping in the final before-and-after report. |

Compare overlap with Naxxramas by slot and difficulty. Inspect Opera, Aran, Netherspite, Chess, and Prince for assumptions about raid size
and coordination. Bring concrete decisions from those findings to the owner. If Manastorm
eligibility requires a separate ruling beyond its depth, item level, and release-stage policy,
confirm it before introducing a personal unlock requirement.

## Results from the live iteration

- The old attunement sent characters through Outland dungeons for three fragments and through the Caverns of
  Time to finish the key. The owner replaced that chain with a single quest and tested its flow through live
  Karazhan entry. The realm phase and physical door remain separate checks.
- The initial Normal flex budget gave Midnight and each Attumen form 422,837 HP per effective player. Lucifron
  already had 588,759 per effective player. Attumen’s 4.13-second swing timer also reduced sustained tank
  pressure relative to the damage per swing. Compare effective encounter health and observed damage before
  setting the scale for subsequent raids.
- The approved health-only follow-up used 1,400,000 Normal HP per effective player for Attumen and Midnight,
  a factor of about 3.311 across the existing boss difficulty budgets and hostile fixed-health enemies in
  Karazhan. The mounted phase inherits the higher remaining health of Midnight and unmounted Attumen.
  At Normal, one player and 24 bots inside, with 0.7 bot weight and GM mode off, round to 18 effective
  players. That gives each opener form 25.2M maximum HP and Prince about 119.1M. Spectral Charger is
  expected to have about 376k HP regardless of roster size. The incremental build, live startup and boss
  migration rows were verified. The Charger’s displayed HP and the full raid pacing still needed live confirmation.
