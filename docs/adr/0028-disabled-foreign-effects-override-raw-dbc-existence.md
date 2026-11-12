# 0028. A class file's `disabled_foreign_effects` overrides raw DBC existence for a foreign check

- Status: accepted
- Date: 2026-11-08

## Context

Round 3's value-metric-gaps item added no-combat checks for the rank's own radius (`$aN`, `spell_effect_radius`)
and own period (`$tN`/`$TN`, `aura_amplitude_ms`), alongside the existing own-stack fix (`$u` now reuses
`spell_max_stacks` instead of being dropped as "not foreign"). `foreign_radius`, parallel to the existing
`foreign_effect`/`foreign_stacks`/`foreign_duration`, decides whether a *foreign* spell's referenced effect is
measurable by reading `Spell.dbc`'s raw `Effect[N]` field: nonzero means measurable, exactly like the existing
foreign checks.

Testament of Hope 1397742's tooltip reads `$704409a1`: 704409's `Effect[0] = 143` (`SPELL_EFFECT_APPLY_AREA_AURA_
OWNER`) in `Spell.dbc`, so the DBC-only check marks it measurable. The generated scenario's `spell_effect_radius`
step failed every run with `Spell effect does not exist`: `AscensionTemplarContracts.cpp:211` sets
`info->Effects[0].Effect = 0` for spell 704409 at `SpellInfo` load time, a Templar class-script correction with
no DBC-visible trace (confirmed: the viewer's own `coa-dbc-viewer` output on this spell already states "Raw DBC
values precede SQL and C++ corrections"; there is no corrections dataset Python can read generically). Effect 1
of 704409 carries the identical `EffectRadiusIndex` and is the one actually applying the aura, so the tooltip's
radius number is still truthful; only effect 0's existence check is wrong.

## Considered options

1. Hardcode spell 704409/effect 0 in `values.py`/`foreign_radius`. Rejected: violates "tool code stays
   class-agnostic (no class spell ids ... in generic modules)".
2. Make the C++ `spell_effect_radius` metric fail softly (return a sentinel instead of `Require()`-failing) so
   the scenario completes and `compare.py` judges a numeric mismatch. Rejected: a sentinel is itself an invented
   number, and the true state is "this effect does not exist", not "a wrong amount was measured" -
   `deterministic()` turning that into a coincidental `ok`/`alert` would misreport the reason either way.
3. A generic, class-file-driven override: a `disabled_foreign_effects` list of `{"spell", "effect", "reason"}`
   entries, consulted by `foreign_radius` through a new `disabled_foreign_effects(class_file)` helper, exactly
   like `known_auras`/`extra_spells` keep other class-specific facts in the class file while the consuming code
   stays generic. Chosen.

## Decision

- `values.py` adds `disabled_foreign_effects(class_file) -> frozenset[(spell_id, effect)]` and a `disabled`
  parameter (default `frozenset()`) on `foreign_radius`; a listed `(spell_id, effect)` pair returns
  `unmeasurable: effect <n> of spell <id> is disabled by a server correction` before the DBC existence check, so
  no scenario step is generated for it.
- `classes/templar.json` gains `disabled_foreign_effects: [{"spell": 704409, "effect": 0, "reason":
  "AscensionTemplarContracts.cpp:211 sets info->Effects[0].Effect = 0 for spell 704409 at load time"}]`; the
  spell id and the C++ citation live only in class data, never in `values.py`.
- Scoped to `foreign_radius` only: `foreign_effect`/`foreign_stacks`/`foreign_duration` keep their existing,
  DBC-only existence check. They carry the same latent risk in principle, but none of this round's spells expose
  it for them, and widening the override to every foreign check is a larger change than this item's own gap-
  closing scope.

## Consequences

- Testament of Hope 1397742's `$704409a1` is now an honest `unmeasurable`, citing the exact server correction,
  instead of a scenario that always fails `Spell effect does not exist`. `test_foreign_radius_of_a_disabled_
  effect_is_unmeasurable` (fixture-level, class-agnostic) and `test_foreign_radius_token_of_a_server_disabled_
  effect_stays_unmeasurable` (Templar, real DBC) pin it; `test_foreign_radius_token` (Norgannon's Wrath 524739,
  a foreign radius with no such correction) keeps the positive path measured.
- A future class whose own script similarly disables a foreign effect a tooltip still names gets the same fix by
  adding one entry to its own class file, not by touching `values.py`.
- `foreign_effect`/`foreign_stacks`/`foreign_duration` remain exposed to the same class of mismatch until a
  reported gap exercises it; widening `disabled_foreign_effects` to cover them is a follow-up, not implied by
  this change.
