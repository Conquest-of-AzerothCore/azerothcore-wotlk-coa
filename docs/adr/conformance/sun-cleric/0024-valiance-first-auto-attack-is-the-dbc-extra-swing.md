# 0024. Valiance's first auto attack on a target is the DBC extra attack, gated by its debuff

- Status: accepted
- Date: 2026-11-22
- Amended: owner ruling O-21 (2026-11-22): the per-target marker is per caster, which overturns mentor decision
  D-131. See Amendment.

## Context

Valiance 680643: "Increases your melee attack speed by $s1% and your first auto attack on a target hits twice."
Its Effect[1] is aura 42 `PROC_TRIGGER_SPELL` of 681472 (Effect[0] 19 `ADD_EXTRA_ATTACKS` on the caster, Effect[1] 183
delayed trigger of 681531, `ExcludeTargetAuraSpell` 681531). 681531 is an enemy debuff (Effect[0] aura 4 `DUMMY`,
duration index 6 = 600000 ms).

The class code replaced that proc. `AscensionSunClericContracts.cpp` turned the proc effect of every event spell into a
dummy with no trigger, `AscensionSunClericEvents.cpp` gated 680643 on a per-GUID set (`firstAttacks`, cleared out of
combat), suppressed the default action and cast 506824 Vow of the Valkyr (Mainhand), a normalized-weapon strike
(commit e36bc50aad, no rationale recorded). The reference log (coa-history log 161, 2026-08-22, one Sun Cleric player)
shows the other mechanism: 36 `SPELL_EXTRA_ATTACKS` 681472, each followed in the same millisecond by a second
`SWING_DAMAGE` on the same target, and `SPELL_AURA_APPLIED` 681531 on the target about 300 ms later (35 events, 35
distinct target GUIDs, none twice). That player has no 506824 event in the 186 logs.

## Options

- Keep the 506824 strike and the per-GUID set: a yellow normalized strike, no white swing, no debuff.
- Let the DBC proc run and keep the per-GUID set as the gate: two gates for one rule.
- Let the DBC proc run and use 681531 as the only per-target gate.

## Decision

The DBC proc runs. 680643 leaves the `SunClericEvents` list, so its proc effect keeps 681472; its script keeps only the
proc condition (an own damaging automatic attack) and leaves the default action alone; the 506824 cast and the
`firstAttacks` set are removed.

681531 is the per-target marker that makes "first on a target" true: the delayed trigger applies it, and a cast of
681472 at a target that holds it is refused by `ExcludeTargetAuraSpell` (`SpellInfo::CheckTarget`). The per-GUID gate
therefore does not remain. The proc chain guard of `AuraEffect::CheckEffectProc` keeps the extra swing itself from
procing again.

## Consequences

- The extra attack is a white swing: it can glance, takes the swing table and procs auto-attack effects, as in the log.
- The marker lasts 600000 ms or until the target dies, not until the caster leaves combat. Old behaviour, before the
  amendment: a target marked by one Sun Cleric refused another Sun Cleric's Valiance for 10 min, through the stock DBC
  `ExcludeTargetAuraSpell` with no caster check (`SpellInfo.cpp:2158`, via `Spell.cpp:6046`). Mentor decision D-131
  kept that stock rule; owner ruling O-21 overturned it (Amendment).
- Regression entries (`sun_cleric.json`, 680643): the extra-attack cast and the marker on the first auto, one cast over
  3 swing intervals, the cast in the first interval, no 506824 cast, each against a control without the talent.
- Not measured, a tool gap in the ledger: a second target gets its own extra attack (autos are driven at the dummy
  only) and the landing of the extra white swing (the swing counts change at the interval boundary). The damage of the
  first exchange before and after the change is not measured either.

## Amendment: one marker per caster (owner ruling O-21, 2026-11-22)

O-21: each Sun Cleric gets its own double strike on a target. The stock gate cannot give that: `SpellInfo::CheckTarget`
refuses 681472 at any target holding 681531 whatever its caster (`SpellInfo.cpp:2158`), from `Spell::CheckCast`
(`Spell.cpp:6046`) and again when the target is added (`Spell::AddUnitTarget`, `Spell.cpp:2402`), and no triggered cast
flag skips it. A second caster's 681531 would not sit beside the first either: a non-periodic aura of the same spell
from another caster falls through to the same-rank rule of `Aura::CanStackWith` and replaces it
(`SpellAuras.cpp:2158`, removed by `Unit::_RemoveNoStackAurasDueToAura`, `Unit.cpp:5745`; code reading).

Options:

- A per-caster set of target GUIDs in the class state, with the DBC marker kept: two gates for one rule again, and the
  stock exclusion still refuses the second caster.
- Keep 681531 as the only gate, made per caster in the class contracts.

Decision: the second. `AscensionSunClericContracts.cpp` clears 681472's `ExcludeTargetAuraSpell` and gives 681531
`SPELL_ATTR3_DOT_STACKING_RULE`, so the markers of different casters stack (`SpellAuras.cpp:2093`) while the same
caster's marker refreshes. The 680643 proc condition refuses a target that holds the caster's own 681531
(`HasAura(681531, caster)`); 681531 is cast by the Sun Cleric (`Spell::EffectAscensionTriggerSpellDelayed`). For one
caster the extra attack 681472 and the refusal on an already marked target stay (now by the proc condition instead of
`CheckTarget`), but the marker timing changes (code reading): for a spell with a non-zero family,
`Spell::PrepareTriggersExecutedOnHit` sets the pre-cast spell to a negative `ExcludeTargetAuraSpell`
(`Spell.cpp:9119-9121`), and `Spell::DoTriggersOnSpellHit` adds it to each hit unit with `AddAura`
(`Spell.cpp:3330-3345`). 681531 is negative (Effect[0] target 6, `SpellInfo.cpp:3621`, `:3651`,
`SpellMgr.cpp:3942-3943`), so before the amendment the marker was added at the 681472 hit (0 ms) on the target and
on the Sun Cleric itself, then recast at +200 ms by Effect[1] 183. With the exclusion cleared it comes only from the
delayed trigger (`SpellEffects.cpp:1061-1100`), at +200 ms and on the target only; the live log has 681531 on the
target about 300 ms after the extra attack and never on the player.

The single-caster gate therefore rests on the marker's +200 ms window being closed before the next proc. For dual
wield, the off-hand swing is held to at least `ATTACK_DISPLAY_DELAY` (200 ms, `PlayerUpdates.cpp:207-213`, `Unit.h:641`)
and the marker delay is 199 + 1 = 200 ms (`SpellEffects.cpp:1093`). Both expire in the same update, and
`Unit::Update` runs the event queue before the melee block (`PlayerUpdates.cpp:81`, `:181-235`), so the marker is cast
before that off-hand swing and refuses its proc. The extra attack cannot proc again while it is the last extra attack
spell (`SpellAuraEffects.cpp:1425-1435`). The tie of the two 200 ms values and the update order are code reading; no
scenario forces them.

Consequences:

- A second Sun Cleric gets its own extra attack and marker on a target another one marked; neither marker removes the
  other.
- The change is keyed to the class's own spells 681472 and 681531 (spell family 33); no other spell references them
  in the DBC (680643 → 681472 → 681531 only), and `SPELL_ATTR3_DOT_STACKING_RULE` is read only by `Aura::CanStackWith`.
- Regression: `sun-cleric-valiance-per-caster-marker`, three level 60 Sun Clerics with the Valkyr weapon set at one
  dummy: the second gets one 681472 cast on the dummy the first marked, both markers stay, the first attacking again
  gets no second cast, and a control without Valiance gets none.
