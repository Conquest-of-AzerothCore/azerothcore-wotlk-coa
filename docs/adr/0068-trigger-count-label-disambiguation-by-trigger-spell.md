# 0068. `trigger_count` entries sharing an aura are disambiguated by trigger spell

- Status: accepted
- Date: 2026-11-10

## Context

Several tooltips name 2-3 spells as independent trigger sources for the same effect ("Casting Righteous
Upheaval or Blade of Faith now grants you Oath: Retribution"; the three-spell list on Condemnation). Proving
each named spell independently (not just one representative) means adding a second (or third) entry to the
same aura's `trigger_count` set, differing only in `trigger.spell`.

`procs.py` already supports this for `proc_rate`: `proc_label(aura, proc_spell, trigger)`, gated by
`shares_aura`/`shares_proc_spell`/`trigger_key`, so two entries sharing an aura get distinct `Expectation`
labels and distinct scenario keys automatically (confirmed by reading it; proven already by the existing
Lightkeeper and Might of Aggramar entries). `triggers.py`'s plain (default-kind) `trigger_count` path had no
equivalent: `trigger_label(aura)` took only the aura, so a second entry for the same aura would silently
collide under one `Expectation.label`. `compare.py`'s `trigger_parts.setdefault(expectation.label, [])`
aggregates parts by label across the whole run, so two different trigger spells' events would have been
summed into a single verdict — a false "this clause is proven" that would, in fact, only ever have exercised
whichever of the two trigger spells scheduled first. `conformance.py`'s `add_trigger` had a similar, but
separate, gap: it disambiguated scenario *keys* only via a manual `effect` field (correct for `cooldown_delta`
entries that really are separate `SpellEffectIndex`es of the same aura), which doesn't fit a second named
trigger *spell* for the same single effect.

## Decision

Extend `trigger_label(aura, trigger_spell=None)` to take an optional second component, mirroring
`cooldown_label(aura, observe_spell=None)`. Add `shares_trigger_aura(class_file, entry)`: true when more than
one default-kind (`kind` absent), non-`status` entry shares `aura`. `trigger_scenario` uses the disambiguated
label only when `shares_trigger_aura` is true, so every existing single-entry aura keeps its plain label
unchanged (`cooldown_label`'s own compatibility rule). The key component is `trigger.get('spell',
trigger['action'])`, since a `periodic` trigger has no `spell` field at all; this also future-proofs the
disambiguation for a non-`cast` trigger pair, though none exists yet.

Add `checked_trigger_set(entries)`, a *cross*-entry validator (the others in `triggers.py` validate one entry
at a time) that raises when two default-kind entries share both `aura` and trigger spell/action — the exact
collision the missing disambiguation used to hide silently. `trigger_entries()` runs the full class's trigger
list through it before any aura filtering, so a future mistaken duplicate fails loudly at generate time instead
of quietly producing a mixed, meaningless verdict.

`conformance.py`'s `add_trigger` scenario-key logic gains the same rule, applied only when there is no
explicit `effect` field (which still wins, preserving the `cooldown_delta`/`duration_delta` convention).

## Considered options

1. Give every multi-spell clause its own `effect` index, reusing the existing manual mechanism. Rejected: an
   `effect` number is supposed to name a real `SpellEffectIndex` of the aura (as `cooldown_delta`'s two
   `One With The Light` entries do, one per real effect); two entries that both measure the *same* single
   effect, triggered by two different named spells, have no second effect index to assign, and inventing one
   would misrepresent the DBC data the entry cites.
2. Key the label by the entry's position/order in the list instead of its trigger spell. Rejected: an
   arbitrary ordinal is meaningless to a reader of `verdicts.json`/`alerts.tsv`, where `706325 proc_rate 801450
   804906` (the existing `proc_rate` convention) already reads as "aura 706325, proc spell 801450, triggered by
   804906" at a glance.

## Consequences

`trigger_count` and `proc_rate` now share the same disambiguation shape (trigger spell/action appended when an
aura has more than one qualifying entry), so a future per-trigger-spell breakdown for either kind follows one
pattern. The new cross-entry check is a genuine "can fail" guard: a unit test seeds two entries with the same
aura and trigger spell and asserts `checked_trigger_set` raises, where it previously accepted the collision
silently.
