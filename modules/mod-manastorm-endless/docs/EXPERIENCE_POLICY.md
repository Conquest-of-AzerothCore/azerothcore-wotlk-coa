# Manastorm experience policy

Ordinary stage creatures keep the core kill reward path enabled. Loot mode zero suppresses their normal
item and money loot; reputation remains disabled. Kill XP follows the core's level, group, range and
no-XP rules, then applies the Manastorm experience formula (`ManastormExperienceFormula.h`). Helpers
retain their exclusions.

`Manastorm.ExperienceRate` in `manastorm-endless.conf` (default `0.3`, a 70% reduction) multiplies both
kill XP and newly earned floor XP. It is reloadable; floor XP already earned keeps its saved amount.

## Depth scaling and anti-boost rules

- **Solo runs (`N = 1`)** receive the full bounded hyperbolic depth bonus
  `DepthBonusFraction(d) = (d - 1) / ((d - 1) + 100)` (`+0%` at depth 1, `+50%` at depth 101,
  asymptotic cap `+100%`) with no group, raid, level-gap, or contribution penalties.
- **Additive external stacking:** The depth bonus stacks additively with positive external kill XP
  multipliers (`SPELL_AURA_MOD_XP_PCT`, RAF `1.5x`, Prestige `9930831` below `MaxPlayerLevel`, respecting
  `OnPlayerHasNoBonusExperience` and Destiny Weaver Experience Bonus Control) via
  `1 + DepthBonusFraction(effectiveDepth) / externalMultiplier`.
- **Group/raid personal depth cap (`N >= 2`):** Each member's effective depth is capped to
  `min(runDepth, personalBestDepth + 5)`, and each group completion advances a member's recorded
  progression by at most `+1` floor above their personal best (unless checkpoint bypass is active).
- **Group effort, raid size and level gap (`N >= 2`):**
  - Floor XP multiplies by `FloorGroupEffortFactor = clamp(groupHealthMultiplier / N, 0, 1)`.
  - Both kill XP and floor XP multiply by `RaidSizeFactor = (5 / N)^2` for `N > 5` (`1.0` for `1..5`).
  - `LevelGapFactor` is evaluated per member against the stage's highest level (`gap = highest - level`):
    no penalty up to a `20`-level gap, then a progressive `((50 - gap) / 30)^1.5` reduction down to `0.0` at
    a `50`-level gap, and `0.0` for the entire group whenever any member reaches `MaxPlayerLevel` (even for
    a `MaxPlayerLevel - 1` member). Peak member count and highest level persist if a carry leaves mid-stage.
  - On kill XP in mixed-level groups, `KillGroupLevelShareCap = min(1.0, groupAverageLevel / playerLevel)`
    uses the same alive group members as the core reward (the killer and those within reward distance).
    It caps the core `KillRewarder` `playerLevel / aliveSumLevel` share surplus so pairing a high-level character
    with low-level characters cannot yield more kill XP than a same-level group.
- **Dual-pool combat contribution (`N >= 2`):** Members earn full contribution (`1.0`) when either their
  real creature HP damage share or their cross-player effective healing share reaches `40% / N`, ramping
  down to a `10%` floor. Cross-healing excludes self-heals and pets, requires the healed player to have
  damaged stage creatures, and is capped by that player's unhealed damage taken from stage creatures
  (up to one health bar). Kills outside `100` yards, during `Preparing`, during the `previousStage`
  transfer window, or by departing members still on an owned stage award `0` XP.

Floor XP is a configurable reconstruction, not a recovered original Ascension amount. A successful
objective completion awards each eligible run member the repeatable RDF reward for their own level
scaled by `Manastorm.ExperienceRate` and the group/level/contribution factors above.
Replaying a floor in another run earns it again; entering or using a portal does not award XP.

## Installation and configuration

Rebuild the updated source. Before starting it, apply:

- `data/sql/db-world/base/83_manastorm_floor_experience.sql` to `acore_world`.
- `data/sql/db-characters/base/05_manastorm_pending_experience.sql` to `acore_characters`.
- `data/sql/updates/pending_db_world/zzz_20261126_01_manastorm_raid_group_scaling.sql` to `acore_world`
  (extends Normal and Endgame group scaling tables to 6–15 members).

Both files preserve existing data when reapplied. They are module migrations, not full database dumps.

`acore_world.manastorm_floor_experience`, row `id = 1`, controls new earnings:

| Column | Default | Meaning |
| --- | --- | --- |
| `enabled` | `1` | `0` disables new floor XP. Previously earned XP can still settle. |
| `rdf_dungeon_id` | `258` | Random Classic Dungeon; resolves `lfg_dungeon_rewards.otherQuest` by member level. |
| `multiplier` | `1.0` | One repeatable RDF reward; `0.5` halves it and `2.0` doubles it. |

Restart or reload Manastorm after changing the policy. The Classic baseline uses its final level-60
quest above level 60, following the core selector; select another RDF dungeon if that is inappropriate
for your leveling range. First-daily rewards, RDF items, money and quest completion credit are not granted.
Floor XP does not multiply by the kill-only depth/native modifiers.

The completion transaction saves base XP with progression and rewards. Online members claim immediately;
offline members claim on login. Far teleports defer claims until map entry. Character level/XP and the
pending balance debit are saved in one transaction. RDF quest rates, quest XP auras and the normal DF XP
script hook apply at claim time; `GiveXP` retains RAF, level caps and other core eligibility rules.
XP-disabled members do not earn new floor XP; an XP-disabled claimant retains previously earned XP.

If a claim transaction fails after changing the live player, claims for that GUID are blocked for the
remaining process lifetime and an error is logged. Reconcile that player's saved XP and pending balance
before restarting; retrying blindly can duplicate XP if a later ordinary save persisted the live grant.

Source checks cover default RDF brackets, completion/portal ordering, pending claims and SQL formatting.
Compilation, MySQL execution and in-game acceptance remain separate validation steps. Verify level-15
solo kill XP, one completion bonus, portal reuse, a repeated floor, and an offline group member reconnect.
