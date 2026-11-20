# 0860. A metric delta target-pet total can prove its recipient absent before

- Status: accepted
- Date: 2026-11-16

## Context

Houndmaster's Whistle 801343 `hound_heal_share` (claim 312.0) judges the heal 574335 that the owner's script casts on
the Shadowhound. A read without a recipient filter also counts any 574335 landing on the owner. The heal reads filter
on the caster's current pet with `target` + `target_pet`, but the control phase withholds the Whistle
(`setup_only_after`), and the harness refuses that read without a current pet ("Healing target needs a current pet").

## Options

- Let the harness read 0 without a pet: a harness change, and a missing pet would read like a measured control.
- Add a recipient-entry filter to the heal reads: a harness change for one claim.
- Drop the before read and prove the recipient absent instead, from an existing metric.

## Decision

The `metric_delta` option `before_absent_recipient: true` (mentor D-290) applies only to a `spell_heal_total` or
`spell_energize_total` read with `target` and `target_pet` true and `setup_only_after`. The recipient entry is the
single `SPELL_EFFECT_SUMMON_PET` (56) `EffectMiscValue` among the entry's setup casts (DBC). The before read is
replaced by `owned_creature_count` of that entry, and an assert of exactly one owned recipient precedes the after
read. The before value is 0 only when that count reads 0; a count above 0 is `alert`, a missing count `unmeasured`.

## Consequences

- Test: `BeforeAbsentRecipientTests` (metric_delta_options/test_before_absent_recipient.py), with a count-1 mutant
  that alerts.
- Only entries that set the option change; the Templar and Necromancer digests are unchanged.
