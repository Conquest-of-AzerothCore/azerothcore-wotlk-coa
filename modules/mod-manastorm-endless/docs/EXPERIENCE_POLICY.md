# Manastorm experience policy

Ordinary stage creatures keep the core kill reward path enabled. Loot mode zero suppresses their normal
item and money loot; reputation remains disabled. Kill XP follows the core's level, group, range and
no-XP rules, then the existing Manastorm depth/native experience modifiers. Helpers retain their exclusions.

Floor XP is a configurable reconstruction, not a recovered original Ascension amount. A successful
objective completion awards each eligible run member the repeatable RDF reward for their own level.
Replaying a floor in another run earns it again; entering or using a portal does not award XP.

## Installation and configuration

Rebuild the updated source. Before starting it, apply:

- `data/sql/db-world/base/83_manastorm_floor_experience.sql` to `acore_world`.
- `data/sql/db-characters/base/05_manastorm_pending_experience.sql` to `acore_characters`.

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
