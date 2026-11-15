# mod-coa-challenges

AzerothCore (WotLK) module that reimplements the Conquest of Azeroth
**challenges/trials** system server-side: the client's `C_Challenge` UI is
driven entirely by data already present in the game client patch, while this
module supplies the **authority** (activation gates, auras, lives, rules,
objectives, completions, rewards and the Gamemodes state).

> Status: functional and validated live for activation, death/fail, auras,
> lives, shared fate, hunger/fatigue, rules, activation conditions, criteria
> banners, leaderboard, trial creator and reward delivery. See *Scope* below.

## Requirements

- AzerothCore WotLK, branch `coa-challenge-defs` (or `main`) of the CoA fork.
- **Companion core opcode entries** in `src/server/game/Server/Protocol/Opcodes.h`
  (the "CoA extension range" block) — the module uses custom opcodes.
- The **CoA server component** (opcode pass-through).
- The game client patch that ships the `Challenge*.dbc` files and the challenges
  UI addon (definitions + UI live there, not here).
- For achievements: the client `Achievement.dbc` installed in the server
  `Data/dbc` (custom achievement ids exceed the stock range;
  `Achievement_Criteria.dbc` / `Achievement_Category.dbc` stay stock). Because
  the ids exceed `uint16`, the core `AchievementMgr::LoadFromDB` must read
  `character_achievement.achievement` as `uint32` (the module widens the column;
  see the CoA fork), otherwise completions are dropped on relog.

## Layout

```
mod-coa-challenges.cmake          registers helper headers + unit tests
conf/
  mod-coa-challenges.conf.dist    tunables (see "Configuration")
data/sql/
  db-characters/                  character-side schema (versioned)
  db-world/                       challenge definitions schema (versioned)
src/
  CoA.Challenges.*.cpp / Review.h     implementation, split by area
  CoAChallengeParse.h                 pure parsing/matching (host-testable)
  CoAChallengeInternal.h              GM/test-only declarations
  CoAChallengeTests.cpp               in-game e2e/GM harness
tests/
  CoAChallengeParseTest.cpp           host unit tests (core `unit_tests`)
```

## Installation

1. Place the module at `modules/mod-coa-challenges`.
2. Apply the companion core opcode block (see *Requirements*).
3. Reconfigure and build AzerothCore.
4. Copy/keep `conf/*.conf.dist` as `.conf` and tune as needed.

The character and world tables are created by the versioned SQL under `data/sql/`
(applied automatically by the AzerothCore DB updater). On a dev box without the
updater, set `CoAChallenges.AutoCreateSchema = 1` to create them at runtime.

## Data flow

- **Definitions** (rules, conditions, objectives, auras, lives, rewards) originate
  from an **export of the game client** and are imported into the **world
  database** (`coa_challenge_definition`, `coa_challenge_spell`,
  `coa_challenge_reward`) via the generated SQL
  (`coa-analyze-export.ps1 -EmitSql`). The world DB is the single source of
  truth; the module reads it into a memory cache at startup and on
  `.coa challenges reload`.
- **Rewards** are delivered **by mail** on completion. The client only *displays*
  the reward definition; it never sends a "claim". See the Rewards notes in
  `conf/mod-coa-challenges.conf.dist`.
- The **Challenges Store** tab (Trial Masters / Build Masters) is a separate,
  100% server-side Custom Store system and is **out of scope** for this module.

## Configuration

All options are documented inline in `conf/mod-coa-challenges.conf.dist`,
grouped by area: UI tabs, game modes, lifecycle, rewards, announcements/client
state, grouping, hunger/thirst, fatigue, professions and testing.

Any key omitted from a customized `.conf` falls back to the code default; new
keys are appended automatically on deploy.

## GM / admin commands

```
.coa <trial|challenge> <unlock|check> <id> [player]
.coa e2e <player> <id> [intervalMs]
.coa reward <id> [level] [player]
.coa challenges reload
.coa reset [all] <player>
```

A player with a two-word name is given in quotes, in any letter case: `.coa reset "Firstname Lastname"`.

Support commands for a player's run (administrator, also from the console; the player defaults to the target):

```
.coa trial objectives [player]
.coa trial credit <Challenge ID> <Objective ID> [player]
.coa trial restore <Challenge ID> [player]
```

- `objectives` lists every active challenge with its level, deaths and tracked objectives, numbered and marked
  done or pending, and the challenges the player has failed, newest first, each with its Challenge ID, level,
  when it failed and the character's level at that moment, which is what `restore` needs. It also works for an
  offline character.
- `credit` marks one objective done by the Challenge ID and Objective ID shown in that list, whatever the
  player's level, and runs the normal completion check. The player must be online. `credit` and `restore`
  typed without their IDs print their syntax and point to `objectives`. `.help coa trial objectives`,
  `.help coa trial credit` and `.help coa trial restore` print the syntax and a short explanation in game.
- `restore` removes the failure lock of a failed challenge and makes it active again with the level, objectives
  and run timer it had when it failed, takes the fatal death back when the run was out of lives, and resurrects
  the character. The meters restart as on a new activation, so a run that failed on one does not die again at
  once: hunger and thirst at zero on the Survival trials, the fatigue bar full on the Narcolepsy trials. The
  answer names the meters it restarted. The state comes from `coa_challenge_failure_snapshot`, written at every
  failure; a failure from before that table restores with a restarted timer. A custom trial the challenge
  belonged to, High-Risk drops and shared-fate partners are not restored.

`restore` is refused in two cases, both because of levels gained after the failure. Those levels were earned
outside the challenge's rules: its lives, its bans on the auction house, mail, trade, heirlooms and the dungeon
finder, and its level cap.

- The character has gained more than `CoAChallenges.Restore.MaxLevelsGained` levels (default 3) since the run
  failed. This is the only check for a trial with no objectives, such as Hardcore (54), which completes by
  reaching the maximum level alive.
- The character has levelled past the gate of an objective that is still pending. An objective only counts
  below its gate level, so it could never be earned again.

There is no way to bring such a run back. `.coa trial unlock` only removes the failure lock: a challenge that
must be started at level 1 (the `LEVEL_UP` activation condition, which most trials have) still cannot be started
by that character, so a fresh attempt means a level 1 character.

A character within the allowance and below every pending gate, for example one who kept playing while waiting
for a GM, is restored, and the answer states both levels. A failure from before the snapshot table has no
recorded character level: it is checked against the objective gates only, and refused on a trial that has none.

Examples:

- Hardcore (54): a player dies at level 20 and asks for a restore at level 30. Refused: ten levels gained, three
  allowed. At level 23 or below the restore succeeds.
- Hardcore - Boss Blitz (60), whose first gates are Edwin VanCleef before 21, Mutanus the Devourer before 22 and
  Archmage Arugal before 26: a player dies at level 22 with VanCleef and Mutanus done.
  - Restored at level 22: both objectives are still done and levelling is capped at 25 again.
  - Restored at level 24: allowed, Arugal's gate is 26 so nothing was missed.
  - At level 26 or higher: refused, `past the level 26 gate of pending objective 3 (Kill Archmage Arugal
    before level 26)`.

Worked example for a kill that did not register:

```
.coa trial objectives "Firstname Lastname"
Hardcore - Boss Blitz, Challenge ID 60, level 1, deaths 0 of 1 lives
  2. [pending] Kill Mutanus the Devourer before level 22, Objective ID 2 (levelling capped at 21)
.coa trial credit 60 2 "Firstname Lastname"
```

Crediting the last objective of a trial does not complete it early: a trial completes when every objective is
done and the character reaches the realm's maximum level.

## Scope / limitations

- GroupRewards (`ChallengeGroupRewards.dbc`) — semantics not confirmed.
- Custom Store (Trial Masters tab) — separate system, not implemented here.
- Some rules/objectives/conditions are still being mapped; the module applies
  the subset described in `conf/mod-coa-challenges.conf.dist`.

## Reducing Adventure Mode difficulty

Players can use `.coa adventure <level>` to lower an active Adventure Mode or Prestige Adventure Mode run.
The level must be between 1 and the current level minus one. The run keeps its start time, deaths and objective
progress; its auras, displayed quest XP and completion rewards switch to the selected lower tier. The normal
challenge-start request also accepts a lower tier for an already-active Adventure Mode run.

Changes are refused while the player, a party member or their controlled units are fighting, during an active
instance encounter, or while the player is dead, flying, charmed or teleporting. Start, stop, group-sync and
custom-trial requests enforce the same restriction. Custom trials cannot be downscaled, and an already-completed
tier cannot be selected. Tier changes cannot raise the difficulty again within the same run.

## License

GNU General Public License v2.0 — see [LICENSE](LICENSE).
