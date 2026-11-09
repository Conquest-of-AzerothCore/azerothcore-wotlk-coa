# 0034. A class file's `effect_notes` overrides the generic `unmodelled` reason text

- Status: accepted
- Date: 2026-11-09

## Context

Round4's `scripted-script-aura` item investigated the 21 Templar `P6` ("scripted or crowd-control") passive
effects (`SPELL_AURA_DUMMY`/`SPELL_AURA_OVERRIDE_CLASS_SCRIPTS`). `passives.classify` labels every one of them
`unmodelled: scripted or crowd-control effect`, a single generic string for the whole family, by construction
(`FAMILY_REASONS['P6']`). The investigation found that, of 12 of these effects, 10 need no check at all: either a
sibling effect of the *same* spell already carries the number the tooltip states and is already `ok` (e.g. 300529
effect 1, Deep Secrets, whose single tooltip clause is fully resolved by 301283's own effects), or an existing
`behaviours`/`triggers` entry on a *different* effect of the same spell already proves the server-side behaviour
(804930 effect 0, whose `behaviour_trigger` check on the spell already covers the claim). The remaining 2 (92109
effect 0, 300520 effect 0) are genuine, unverified claims this item's own scope (no new C++ metric, no new
`behaviours` kind) cannot build a check for, and need to say so specifically rather than fall back to the generic
"scripted or crowd-control effect" label that gives no reader any way to tell "nothing to check" apart from
"investigated, nothing can check it yet" apart from "never investigated".

`passives.py` already has two class-file-driven, per-`{spell, effect}` override lists that follow this exact
shape: `effect_overrides` (substitutes a live-corrected `EffectMiscValue`) and `passive_targets` (substitutes a
spell-modifier's resolved target list). Neither touches the `reason` text itself.

## Considered options

1. Hardcode the 12 spell/effect pairs and their explanations directly in `passives.py`. Rejected: violates "tool
   code stays class-agnostic (no class spell ids ... in generic modules)", the same rule `disabled_foreign_
   effects` (ADR 0028) and `effect_overrides` were built to respect.
2. Change `FAMILY_REASONS['P6']` itself, or add a new family, to read differently for these spells. Rejected: the
   generic family reason describes the *mechanism* (scripted/crowd-control, unreachable from a no-combat read),
   which is still true for every `P6` effect; what changes per effect is *why no check is worth building*, a
   per-instance fact, not a property of the family.
3. A generic, class-file-driven `effect_notes` override list, consulted by `classify` only when the computed
   reason already starts with the `unmodelled: ` prefix, replacing the explanation text (never the status) with
   the note's own text. Chosen: same shape as `effect_overrides`/`passive_targets`, one new helper
   (`effect_note`), one call site, no new family or status.

## Decision

- `passives.py` adds `effect_note(class_file, spell_ids, effect) -> str | None`, the same `{spell_id or rank_id,
  effect}` lookup as `effect_override`/`passive_override`, reading a new `effect_notes` list.
- `classify` applies it once, right before returning `PassiveEffect`: `if reason.startswith(UNMODELLED): note =
  effect_note(...); if note is not None: reason = UNMODELLED + note`. A note never fires on a modelled effect
  (empty `reason`) and never changes the verdict status, only the `unmodelled` explanation a reader or
  `verdicts.json` sees.
- `classes/templar.json` gains `effect_notes: [{"spell": <id>, "effect": <n>, "reason": "..."}]`; the spell ids,
  effect indexes and investigation citations live only in class data, `passives.py` stays generic.
- Used for 10 "no check needed, already covered elsewhere" effects and 2 "deferred, this item cannot build a
  check yet" effects (round4 `scripted-script-aura`); the wording distinguishes the two ("no check needed: ..."
  vs "deferred: ..."), both still read as `unmodelled` by `compare.py`.

## Consequences

- A reader of `verdicts.json` can now tell, for any `P6` (or future auto-labelled) effect, whether it carries no
  real claim at all, whether a sibling check already proves it, or whether it is a real, open gap waiting on
  harness capability — instead of one indistinguishable generic string for all three.
- A future class with the same "DUMMY effect, no tooltip clause of its own, already proven by a sibling check"
  shape gets the same fix by adding entries to its own class file, not by touching `passives.py`.
- `effect_notes` only ever replaces text under an existing `unmodelled: ` reason; it cannot be (mis)used to force
  a different effect family, target set or status, keeping its blast radius to documentation accuracy only.
