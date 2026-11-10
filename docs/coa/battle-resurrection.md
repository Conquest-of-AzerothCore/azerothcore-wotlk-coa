# Battle resurrection limit

Live Conquest of Azeroth limits in-combat resurrections in raid boss fights and Mythic+ runs. The rule comes from the
Zul'Gurub tester feedback of 2026-11-04: "Combat resurrection restriction supposed to be there per fight, total of 2 up
to 15 man raid, 3 for 25 man raid, yellow text on top of screen", with in-combat resurrections defined as "like the Pyro
and Necro's in-combat resurrections". The Mythic+ budget of one per run is a user decision.

## Behavior

A battle resurrection is a spell a player casts, not triggered, with a `SPELL_EFFECT_RESURRECT` (18) or
`SPELL_EFFECT_RESURRECT_NEW` (113) effect, while the caster is in combat. That covers Call of The Scourge (801792),
Reborn from Ash (804231), Tidal Rebirth (801793), Spawn (805568), their ranks and Druid Rebirth (20484). Soulstone and
Reincarnation, which only resurrect their owner (`SPELL_EFFECT_SELF_RESURRECT`), are not counted. Resurrections outside
combat are not counted either.

- **Raids, every difficulty:** a boss fight starts with 2 charges when 15 or fewer players (game masters excluded) are in
  the instance at the pull, 3 when 16 or more. The charges are reset whenever an encounter enters `IN_PROGRESS` while no
  other encounter is in progress, so a wipe and the next pull start full, but a second boss pulled into a running fight
  shares its charges. They apply only while an encounter is in progress.
- **Mythic+:** starting a keystone gives the run one charge for the whole run, in and out of boss fights.

A charge is used when the spell is cast, even if the target declines the resurrection. Every player in the instance then
sees a yellow notification: "<caster> used a battle resurrection: N of M left." With no charge left the cast fails
(`SPELL_FAILED_DONT_REPORT`) and the caster sees "No battle resurrections left."

The code is `src/server/coa/AscensionBattleResurrection.cpp`; the Mythic+ module starts the run budget in
`modules/mod-coa-mythic-plus/src/MythicPlus.cpp`. The regression scenario is
`battle-resurrection-raid-fight-limit`, and `BattleResurrectionTest.cpp` covers the charge counts.
