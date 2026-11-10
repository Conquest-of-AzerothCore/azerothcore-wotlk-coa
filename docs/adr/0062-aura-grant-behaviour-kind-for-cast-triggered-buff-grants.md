# 0062. An `aura_grant` behaviour kind for cast-triggered buff grants

- Status: accepted
- Date: 2026-11-09

## Context

`round10/workstreams/oath-stacks-exclusivity.md` lists four Templar abilities whose tooltip ends "...and granting
an Oath[.]": Righteous Lunge (570233), Holy Cleave (573049), Vindication (573324) and Condemn (804906). Each
clause is coverage `missing` in `claims-merged.json`: nothing in the batch checks that the Oath buff is actually
granted on the cast, only (separately, for three of the four) the magnitude token of the Oath buff itself. Reading
`AscensionTemplarAbilities.cpp:155-161` confirms the real mechanism: `OnSpellCast`, gated on
`Family(info, 2, 1) || info->Id == 500689`, unconditionally calls `GrantOath(player, oath)`, where `oath` is
selected by a `Named()` ternary (804904 for Righteous Lunge's 801443 chain, 804903 for Holy Cleave's 801445 chain,
804922 for Condemn's own 804906 id, else 805332 for Vindication). `GrantOath` only declines when the Oath Chain
(704576) already holds 10 stacks, which a fresh caster never does. No existing behaviour kind models "cast X, read
whether aura Y newly appears": `exclusivity` and `amount_delta` both read a single target aura across a
without/with-passive pair, not a plain presence delta around one unconditional cast.

## Considered options

1. Reuse `metric_delta`, gating the "with" phase on learning the granting spell itself. Rejected: the grant is not
   conditional on a learned passive, it is the ability's own base effect; gating the comparison on learning the
   ability itself would make the "without" phase scenario-invalid (the ability cannot be cast before it is known).
2. A new minimal `aura_grant` kind: learn the ability, read the target Oath aura's presence, cast the ability once
   at a dummy, wait, read the Oath aura's presence again. One expectation per entry, reusing the existing boolean
   `aura` metric already used by `exclusivity`. Chosen.

## Decision

Added `BEHAVIOUR_AURA_GRANT` / kind `'aura_grant'` to `behaviours.py`, with `AuraGrantSpec` (`spell`, `name`,
`quote`, `oath`, `wait_ms`) and `aura_grant_scenario`/`aura_grant_spec` following the existing spec-and-
scenario-builder pattern. The scenario arms the caster for the spell (`armed_for`), reads the `oath` aura's
presence before any cast, casts `spell` once at a dummy target (resetting its cooldown and applying any required
caster aura/mana-cost fixture first), waits `wait_ms` (default 300) for the `OnSpellCast` hook to run, then reads
the `oath` aura's presence again. `compare.py` gained `behaviour_aura_grant_verdict`: `ok` only when the before
read is 0 and the after read is 1; any other combination is always an `alert`.

`classes/templar.json` carries four `aura_grant` entries, one per granting ability, each citing the exact
`Named()`/ternary line that selects its Oath id: Righteous Lunge (570233) grants 804904, Holy Cleave (573049)
grants 804903, Vindication (573324) grants 805332, Condemn (804906) grants 804922.

## Consequences

Any future "cast X, see buff Y appear" clause (for any class) can reuse the same kind with its own `spell`/`oath`
pair, with no tool code change. The kind only proves that the grant happens at least once from a clean state; it
does not prove the grant is idempotent under repeated casts, that it respects the Oath Chain's own 10-stack cap,
or the granted Oath's own magnitude/duration — those remain separate clauses with their own entries (the
magnitude tokens for 804904/804903/804922 are already proven elsewhere in this file; the 10-stack cap and the
Oath Chain's own start/consume mechanics are separate, still-open clauses in this workstream).
