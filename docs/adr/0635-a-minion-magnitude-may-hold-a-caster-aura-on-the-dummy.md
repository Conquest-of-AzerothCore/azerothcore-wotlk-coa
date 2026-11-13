# 0635. A minion magnitude may hold a caster aura on the dummy

- Status: accepted
- Date: 2026-11-13

## Context

Necromancer claim 396.0, Parasites 560729: "Your Undead minions feast upon the parasites on hit, leeching
$561319s1% of their damage dealt as Plague Damage to the target." The leech 561318 is cast per minion hit only on a
target that holds 560729 from the player (Necromancer ADR 0065). The `magnitude_ratio` trigger with a `minion` action
already measures a minion-cast copy per minion hit (Depravity 638403, Putrid Claws 805044), and its `minion_auras`
hold fixture auras on the minion, but nothing held an aura on the dummy for a minion trigger. The debuff's own roll
(560730, 5% of the caster's damage) is already proven by its proc_rate entries and would make the denominator depend on
a coin.

## Options

- Let the caster's damage apply the debuff: a 5% roll; the ratio would mix debuffed and clean hits.
- A new kind for one claim: duplicates the magnitude scenario, its trial plan and its resist-aware judge.
- An optional `target_auras` list on the minion magnitude entry.

## Decision

`target_auras` (triggers.py): a list of `{"spell", "source"}`, minion action only, needing `minion_aura_refresh_ms`.
Each refresh window first removes and then sets each aura on the dummy with the caster as its caster (`set_aura`
`target: dummy`, `caster: caster`), beside the existing minion auras. The trigger rule names each one with its source.
Entries without the field generate unchanged; Templar `generate --class 19` and `--stack` are byte-identical.

## Consequences

- A minion copy gated on a caster debuff of the target is measured on debuffed hits only.
- Seeded tests in test_minions.py: a malformed dummy aura or one without a refresh interval is refused; each window
  refreshes the aura from the caster; an entry without the field sets none.
