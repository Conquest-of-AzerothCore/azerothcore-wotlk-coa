# 0026. Owner ruling Felsworn O-28: Doomstride doubles the resist chance

- Status: accepted (owner ruling Felsworn O-28 (2026-11-24); implementation mentor decision D-93, 2026-11-24)
- Date: 2026-11-24

## Context

Doomstride 804613, installed tooltip: "While at full health, your chance to resist the next Curse or Magic effect on
you is increased by 100%. Can only occur once every 10 sec." The Felsworn code turned every qualifying effect that
the stock hit roll let through into `SPELL_MISS_RESIST` (`ResistDebuff`, called from `OnSpellBeforeEffects`), then
cast the 10 s lockout 706818: Curse of Weakness 702 from a level 60 creature was resisted in 3.7% of 4000 trials
without the passive and 100% with it (pair 20261123-203629 / -203704).

The owner ruled (Felsworn O-28 (2026-11-24)): "increased by 100%" doubles the base chance ("Increased 'by', not 'to'"); the guaranteed
resist is a defect. The base chance p is the stock miss and resist chance of `Unit::MagicSpellHitResult`; no engine
function returns it.

## Options

- A: copy the stock chance into Felsworn code (level difference, world miss rates, spell modifiers, auras, ratings,
  mechanic and binary resists) and add a resist with p / (1 - p) when the stock roll hit: exact 2p, but about 40
  engine lines duplicated in class code, which drift with every engine change. Refused by the mentor.
- B: roll the stock hit result a second time (`Unit::SpellHitResult(victim, spell, false)`) and resist when it
  misses or resists: 1 - (1 - p)^2 = 2p - p^2, the engine reused. Chosen.
- C: an engine helper that returns p (`Unit.cpp`). Refused: a shared engine edit for one class.

## Decision

`ResistDebuff` keeps its gates (owner of 804613, alive, at full health, no 706818, a negative all-aura Curse or Magic
effect) and now resists only when a second stock roll gives `SPELL_MISS_MISS` or `SPELL_MISS_RESIST`. 706818 is still
cast only when that roll resists: the mentor's reading of "Can only occur once every 10 sec" (D-93), not an owner
ruling. No shared file, DBC, SQL or client text changes.

## Consequences

- The full-health chance is 2p - p^2, a known approximation of 2p: 7.84% against 8% at p = 4% (same level), 27.75%
  against 30% at p = 15%. The shortfall is p^2 and grows with p.
- The conformance proof uses the new kind `debuff_resist_rate` (shared ADR 1268, provisional): a same-level striker
  (p = 0.04) with Curse of Weakness 702 and Slow 31589, the talent learned for real between a control arm and the
  full-health and 90% health arms; and a level 56 striker (p = 0.20: an open-world creature is shown to a level 60
  character at least at level 56) for the 10 s lockout. The `taken_hit` entries `resist_next` and `resist_icd` are
  replaced: `resist_next` set 804613 by `set_aura` and read only the Curse leg, and `resist_icd` relied on the
  guaranteed resist (with p = 0 the passive can never resist).
- Readers of 804613, 807962 and 706818: `ResistDebuff`, the Felsworn refresh (807962 toggle), the contract of 706818
  and 807962, the conformance entries above and `felsworn-idle-doomstride-item-procs.json` (807962 recasts only).
  No other class lists them.
