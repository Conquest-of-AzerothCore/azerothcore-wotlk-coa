# 0030. Twilight does not blind raid encounter or world-boss-rank creatures

- Status: accepted (mentor decision D-154, 2026-11-22)
- Date: 2026-11-22

## Context

Twilight 704579: "Applying Vow of the Eclipse now blinds enemies struck, increasing their chance to miss their next
attack by $505342s1% for $505342d, stacking $505342u times. Does not work on bosses."

`AscensionSunCleric::Eclipse` cast Blinded 505342 unless the target was a creature with `IsDungeonBoss()`. That flag
is `CREATURE_FLAG_EXTRA_DUNGEON_BOSS`, which `ObjectMgr::LoadInstanceEncounters` sets on the kill-credit creature of
each `instance_encounters` row. Since 00b1aaf7b2 (#8881) a raid row's credit creature goes to a separate set,
`ObjectMgr::IsRaidEncounterKillCredit` (`ObjectMgr.cpp:6856-6857`), because the dungeon-boss flag also drives 5-man
rewards and mechanics. Raid bosses lost the flag, and Twilight began to blind them. World bosses outside any
encounter never had it.

Mentor decision D-154: "bosses" in the tooltip includes raid encounter creatures and creatures of world-boss rank.

Server data at 97567f7ccb (DungeonEncounter.dbc map, Map.dbc instance type, `creature_template`): the raid set holds
142 creatures. 139 are rank 3 (`CREATURE_ELITE_WORLDBOSS`). The other three, The Illidari Council 23426, Barnes 16812
and Chess Piece: Status Bar 22520, carry unit flags that keep a player from attacking them.

## Options

1. Gate on the rank alone. It covers every attackable raid creature in today's data, but a raid encounter creature
   with a lower rank would be blinded again.
2. Gate on dungeon boss, raid encounter credit or world-boss rank. The raid set is read through the public const
   accessor, with no shared edit.
3. Set the dungeon-boss flag on raid creatures again. It is a shared change, and #8881 removed it on purpose.

## Decision

Option 2. `IsBoss` in `AscensionSunCleric.cpp` returns true for a creature without a player owner that is a dungeon
boss, a raid encounter kill credit or of world-boss rank. `Eclipse` casts 505342 only when `IsBoss` is false. The
player-owner exception matches `Creature::IsDungeonBoss` and the kill rewarder's use of the raid set
(`KillRewarder.cpp:339`). Vow of the Eclipse 505340 still lands on every target.

## Consequences

- Blinded no longer lands on raid bosses (Lucifron 12118) or world-boss-rank creatures (Baron Rivendare 29109).
  Dungeon bosses (Sneed 643) were already exempt, and normal creatures (Harvest Golem 36) are still blinded.
- The change is in the Sun Cleric's code only. It reads the raid set and the creature rank and changes neither.
- No attackable creature tests the raid branch on its own: every attackable raid credit creature is also rank 3.
  The raid arm proves the outcome, not which condition produced it.
- Regression: the class file's Twilight arms on the four targets, each with a 505340 landing control on the same
  target.
