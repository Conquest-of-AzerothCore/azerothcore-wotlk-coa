# 0024. Valiance's first auto attack on a target is the DBC extra attack, gated by its debuff

- Status: accepted
- Date: 2026-11-22

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
- The marker lasts 600000 ms or until the target dies, not until the caster leaves combat. Any Sun Cleric's marker on a
  target blocks every Valiance on it (`HasAura` without a caster check): a rule of the DBC data, not measured here.
- Regression entries (`sun_cleric.json`, 680643): the extra-attack cast and the marker on the first auto, one cast over
  3 swing intervals, the cast in the first interval, no 506824 cast, each against a control without the talent.
- Not measured, a tool gap in the ledger: a second target gets its own extra attack (autos are driven at the dummy
  only) and the landing of the extra white swing (the swing counts change at the interval boundary). The damage of the
  first exchange before and after the change is not measured either.
