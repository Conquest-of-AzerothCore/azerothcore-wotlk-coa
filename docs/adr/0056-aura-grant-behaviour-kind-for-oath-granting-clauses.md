# 0056. An `aura_grant` behaviour kind proves "and granting an Oath" clauses

- Status: accepted
- Date: 2026-11-10

## Context

Four Templar abilities' tooltips end with an unconditional side effect on their own cast, not on a separate
passive: Righteous Lunge 570233, Holy Cleave 573049 and Vindication 573324 each say "... and granting an
|cffffffffOath|r.", and Condemn 804906 says the same with a trailing period. `claims-merged.json` marked all
four `missing`, with no candidate label. The mechanism is confirmed in `AscensionTemplarAbilities.cpp:155-165`
(`OnSpellCast`, run unconditionally once `!spell->IsTriggered()`): `if (Family(info, 2, 1) ||
info->Id == 500689) { uint32 oath = Named(info, 801443) ? 804904 : Named(info, 801445) ? 804903 :
Named(info, 804906) ? 804922 : 805332; GrantOath(player, oath); }`. All four spells carry `SpellFamilyName`
25 and `SpellFamilyFlags[2]` bit 0 (confirmed with `coa-dbc-viewer record --field 'SpellFamilyFlags*'`),
matching `Family(info, 2, 1)`; the ternary selects the oath aura by the spell's own chain root (570233 chains
to 801443, 573049 to 801445, 804906 is matched directly, 573324 falls to the `else` branch), each name
("Oath: Righteous Lunge" 804904, "Oath: Holy Cleave" 804903, "Oath: Condemn" 804922, "Oath: Vindication"
805332) matching the ability it belongs to. `GrantOath` (`AscensionTemplar.cpp:163-175`) casts the oath aura
on the caster and the shared "Oath Chain" aura 704576 (capped at 10 stacks), unconditional on hit, miss,
dodge or parry — the grant happens in `OnSpellCast`, before any hit-result hook runs.

No existing scenario shape fits a single cast's own unconditional self-buff without a separate passive to
gate on: `triggers.py`'s `trigger_scenario`/`cooldown_trigger_scenario`/`duration_trigger_scenario` all model a
*passive* that changes behaviour when a *different* trigger action happens repeatedly (with a statistical
`TRIGGER_TRIALS` sampling loop sized for a probabilistic proc chance), and every existing `behaviours.py` kind
that reads a metric delta around a cast (`metric_delta`, `amount_delta`, `duration_refresh`) does so by
comparing a "without the gating passive" phase against a "with it learned" phase — there is no separate
passive here, the ability grants the Oath by itself.

## Considered options

1. Force-fit `metric_delta_scenario`, passing the ability itself as both `trigger_spell` and the gating
   `spell`/`gate_spell`. Rejected: the "before" measurement would already be taken after the ability is known
   (the scenario's own first `learn` step), so the delta would not isolate "casting it" from "knowing it";
   the kind's contract text ("measured before and after ... is learned") would be actively false for this
   check.
2. A new `triggers.py` entry reusing the probabilistic `TRIGGER_TRIALS` sampling loop with `per_trigger: 1`
   and `observe_metric: 'aura_apply_count'`. Rejected: `GrantOath`'s `Cast(player, player, oath)` re-applies
   the same spell on an existing aura, which `Unit::AddAura` refreshes in place rather than re-running
   `Aura::_ApplyAura` — `AuraApplyCounter` only increments on the first application, not on a refresh — so
   repeated attempts would not scale 1:1 with the trial count the statistical model requires, and the grant is
   deterministic code, not a sampled proc, making the whole `TRIGGER_TRIALS`/baseline-without-the-passive
   machinery the wrong fit.
3. A new `behaviours.py` kind, `aura_grant`: one cast, read the Oath Chain's `aura_stacks` before and after,
   and the specific oath's `aura` presence after. Chosen — deterministic code needs a deterministic check, not
   a sampled one.

## Decision

- `behaviours.py` gains `BEHAVIOUR_AURA_GRANT`, `AuraGrantSpec` (`spell`, `name`, `quote`, `trigger_spell`,
  `oath_aura`, `chain_aura` default 704576), `aura_grant_scenario` and `aura_grant_spec`, wired into
  `behaviour_scenario`'s dispatch under `kind: "aura_grant"`.
- The scenario learns `trigger_spell`, resets its cooldown, reads `aura_stacks` of `chain_aura` (before),
  casts `trigger_spell` once at a fresh creature fixture, waits 500 ms, then reads `aura_stacks` of
  `chain_aura` (after) and `aura` of `oath_aura`. No `CoAGameplayTest.cpp` change was needed: `aura_stacks`
  and `aura` already exist and need only a `spell` field.
- `compare.behaviour_aura_grant_verdict` takes the integer delta `after - before` and the oath presence flag:
  `ok` only when the delta is exactly the expected `+1` and the oath aura is present, `alert` otherwise (no
  `tolerated` band — an integer stack delta has no "near miss"). The label is
  `f'{spell} behaviour_aura_grant'`.
- `passives.py`'s `BEHAVIOUR_LABELS` P5-link table gains the `aura_grant` entry (the same defect shape step5
  found and fixed for `crit_guarantee`, caught here before it recurred).
- `classes/templar.json` gains four `behaviours` entries (570233, 573049, 573324, 804906), each citing the
  `OnSpellCast` line, the confirmed `SpellFamilyFlags` bit and the oath-aura selection it resolves to.

## Consequences

- All four "and granting an Oath[.]" clauses are proven end to end (two independent gameplay runs, both all
  `ok`: chain stack 0 → 1, the correct oath aura present, for every one of the four spells in both runs);
  `classes/templar_clauses.json`'s labels now point at live verdicts instead of an empty, unproven list.
- The `aura_grant` kind generalises to any class's "casting X grants/applies aura Y" clause that is
  unconditional on the cast itself (not gated by a separate learned passive): a new class-file entry naming
  the trigger spell, the observed aura and (if not 704576) the stack-holding aura, no further tool code.
- The Templar's other Oath-related clauses ("Consumes your Oaths, dealing additional damage/healing for each
  consumed", on Righteous Upheaval 572027, Chastise 503141, Benediction 578276, Blade of Faith 803872,
  Righteous Tempest 805409 and Reckoning 805421) are a different mechanic (consuming the chain to scale a
  *different* spell's output, via `RighteousTempest()`'s per-oath factor in
  `OnSpellCalculatedTarget`/`OnSpellHitResult`) and remain unproven; they are left for the next capability.
