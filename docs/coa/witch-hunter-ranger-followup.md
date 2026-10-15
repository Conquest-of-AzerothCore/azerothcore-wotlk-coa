# Witch Hunter / Ranger follow-up — 2026-09-08

This follow-up corrects Witch Hunter behavior and makes Ranger Advantage apply
on misses under the selected local rule. Validation covered source behavior;
Witch Hunter had not yet received manual gameplay acceptance. See the
[release history](local-release-state.md) for later integration.

## Ranger Advantage

The completed-cast hook grants the base resource for all 45 Wild Strike, Flank,
Quick Shot, Toxic Dart and Hunting Shot records already handled by this module.
Miss, dodge, parry, resistance, immunity and other failed impact results do not
remove that cast gain. Rejected/interrupted casts that never launch and triggered
helpers receive no base gain. Archery Master's additional point still requires a
landed critical Quick Shot and is deduplicated per cast. Ravager retains its extra
Wild Strike point. Existing spender refund and quiver hit rules are preserved.

Hunting Shot keeps its per-enemy cardinality: each selected ricochet enemy earns
one point, including a missed shot under the user's local rule. The native target
list is unique and the caster's separate target entry is excluded. Other generators
earn their base amount once per cast. Spell event bits 30/31 hold the base/critical
deduplication markers; other event bits are unchanged.

Four additional cast-rule rows repair missing described gains: Horn of Perseverance
800088, Horn of Endurance 806359 and Dust Toss 807820 grant one; Deadshot ranks
573243–573246 grant two. Existing resource rules for other classes are identical.
The audit reviewed recovered Ranger records and rank sets; helper descriptions
copied from parents do not authorize duplicate resource gains.

## Witch Hunter

- Arbalest Mastery advances after each launched Witchbane channel shot, including
  misses/absorption. That shot uses the preceding count; the next shot gains the
  next 15% step, retaining the native ten-stack cap. Losing the talent clears the
  stored progress. The exact parent family and helper 704342 identify the channel.
- Sixfold Shot's helper 807527 grants its existing 521228 resource payload once per
  launched shot, including misses, through its 807364 parent context. The installed
  helper gives 3 Rage and 2% maximum mana. Landed-hit callbacks no longer grant it
  again. Unrelated triggers and ordinary casts of the helper do not earn it.
- Shadowblast's Shadow Rage talent grants the pet aura only to the player's live,
  owned permanent Shadowhound. An absent/dead/foreign pet no longer falls back to
  buffing the player. Sharpshooter's separate owner mana return remains available.
- Strafing Shot copies Tormentor's remaining duration, damage and next-tick timer.
  A nearly expired DoT can therefore deliver its pending tick. Any already owned
  Tormentor rank excludes a recipient, and a rejected aura application allows the
  search to continue to another eligible enemy. Other casters' ownership is separate.

These rules use the previously extracted family-21 records and their helper chains.
The parent descriptions for 706240, 807364, 705455 and 705515 supply the contracts;
521228's recovered native effects supply the unchanged resource amounts. No new
coefficient, balance multiplier, summon template or SQL definition is introduced.

## Validation and installation boundary

Eight focused tests execute production cast/hit/proc code, including reproduced
before/after failures for Ranger misses, Witch Hunter channel progression, pet
targeting and Tormentor spreading. Seventy-one existing regression tests pass.
Five real production translation units pass MSVC syntax checks with actual project
headers; final hashes are reconciled. C++ lint and diff whitespace pass.

The old Forest Dweller test fixture lacked the already installed Cycle branch's
unit context and used a float where native UpdateSpeed uses int32. Its fixture now
supplies that context and adds Cycle controls; existing Ranger assertions and
Elude talent tests are unchanged. The old Guardian/Ranger hit-policy tests
explicitly change their obsolete miss expectations to the new cast-gain contract.

One historical Witch Hunter pre-install model check is outside this source-only
run because its DBC candidate is already installed. The 62 existing pending world
SQL files are byte-identical. Historical SQL lint still has pre-existing safety,
semicolon and backtick findings; its CLI also attempts an unavailable origin/master
fetch, so the same checks were run offline. This is not a clean global SQL-lint claim.

Source validation did not include CMake configuration, a linked server build,
SQL application, a client patch or a process restart. Manual combat, channel and
pet acceptance remained separate from the recorded tests.
