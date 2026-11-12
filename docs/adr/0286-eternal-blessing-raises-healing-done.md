# 0286. Eternal Blessing raises healing done, not healing received

- Status: accepted
- Date: 2026-11-12

## Context

Eternal Blessing 705300 reads "Increases your Holy damage and healing done by $s1% for $d." ($s1 = 15). In the
server Spell.dbc its effect 2 (EffectBasePoints 14, MiscValue 2) is aura 118 `SPELL_AURA_MOD_HEALING_PCT`. The engine
reads that aura on the healed unit (`Unit::SpellHealingBonusTaken`, `Unit.cpp:10883-10896`), so the Templar's own
heals on others gained nothing and every heal the Templar received gained 15%. Healing done is aura 136
`SPELL_AURA_MOD_HEALING_DONE_PERCENT`, which `Unit::SpellHealingBonusDone` applies without a school filter
(`Unit.cpp:10679`).

The owner ruled on 2026-11-12 (question Q3, claim 218): the tooltip governs, healing done +15%, and no longer healing
received. Reference search: the coabuildhub `skills_templar.json` tooltip and the sidekick snapshot carry the same
"healing done" text; nothing in the references describes the received-healing behaviour.

## Options

- Change effect 2 to aura 136 in the Templar SpellInfo contracts. One spell, one field; the amount, target and
  duration stay those of the DBC.
- Leave aura 118 and add an aura script that scales the Templar's outgoing heals. Rejected: it would keep the
  received-healing bonus the ruling removes.

## Decision

`AscensionTemplar::ApplyContracts` (`AscensionTemplarContracts.cpp`) sets 705300's effect 2 to
`SPELL_AURA_MOD_HEALING_DONE_PERCENT`. Templar code only; the engine is unchanged. The Sun Cleric contracts use the
same aura for a healing-done effect (`AscensionSunClericContracts.cpp`, 704909).

## Consequences

- Benediction 578276 from the Templar to an ally at level 60 reads 800 of a 1000 base without the aura and 920 with
  it (x1.15); Benediction from the ally to the Templar reads 1000 in both cases (catalog scenario
  `templar-eternal-blessing-healing-done`).
- Conformance: `705300 behaviour_hit_ratio healing_done` (x1.15) and its new control
  `705300 behaviour_hit_ratio healing_received` (x1.00, the ally heals the caster) are ok on the counted pair
  20261112-075403 / 20261112-075458 (worldserver fe5cc405…): +15.08% / +14.98% and -0.01% / -0.05%.
  `holy_damage` (+14.88% / +15.07%) is the unchanged-part control.
- After review (rule 4 amendment point 6), both healing arms and the catalog scenario cast 705300 for real instead
  of setting its aura. On the counted pair 20261112-084520 / 20261112-084607 (worldserver 4d20e7ca…, commit
  21e6485e36), `healing_done` reads +14.89% / +14.85% and `healing_received` +0.01% / 0.00%, both ok.
- A Templar who relied on Eternal Blessing to raise healing received from others loses that bonus.
