# 0133. A target aura gate sets the caster's aura on the target instead of casting it

- Status: accepted; supersedes the gate fixture of ADR 0078
- Date: 2026-11-11

## Context

ADR 0078 built the `target_aura_gates` check for Templar's Might 705291 ("Damage dealt by Righteous Lunge, Chastise,
Blade of Faith, and Scourgebane on enemies affected by your Condemn is now increased by $s1% per stack."). Its
fixture cast Condemn 567539 at the dummy before every Chastise trial, and the check judged `alert` in round 10 and
again in lean batch 1: the measured mean matched the unscaled one.

Triage of lean batch 1 chunk 1 found the test at fault. The scenario learns Chastise and Templar's Might, not
Condemn; the harness `cast` action submits `CMSG_CAST_SPELL`, and `WorldSession::HandleCastSpellOpcode` returns
without casting a spell the player does not have active (`SpellHandler.cpp:461-485`). Every gate cast was dropped
(the cast step reported `spell_active` false). A diagnostic scenario on the current build read, after an unlearned
Condemn cast, no Condemn on the dummy and a Condemn cast count of 0; once Condemn was learned the cast landed (one
stack, effect 1 amount 6). With the caster's Condemn set on a second dummy at 3 stacks (effect 1 amount 18), the
Chastise non-critical mean was 418.1 (37 hits) against 356.4 (36 hits) on the plain dummy, a ratio of 1.173 for the
expected 1.18.

Learning Condemn and casting it is not a clean fixture: each Condemn cast grants Oath: Condemn 804922, whose effect 2
is a +30% damage modifier (`SPELL_AURA_ADD_PCT_MODIFIER`, misc 0) on `EffectSpellClassMask` word 2 bit 128, the
Chastise family flag. The gated mean would then carry an Oath bonus that the clause does not promise.

## Considered options

1. Learn the gate spell and keep casting it. Rejected: the cast's side effects on the caster (here the Oath) enter
   the measured mean, and removing them needs class knowledge in the tool.
2. Set the caster's gate aura on the target before every trial, at its `StackAmount`, and assert the stack count.
   Chosen: the aura is the real one, owned by the caster, with its amount computed from the caster's spell
   modifiers (`Aura::SetStackAmount` recalculates each effect through `AuraEffect::CalculateAmount`), and the
   measured hit differs from the unscaled check only by the target's debuff.

## Decision

- `hits.gate_fixture_steps(gate_spell, stacks, label)`: `set_aura` on the target with `caster` at 0 stacks, then at
  `stacks`, then a `SETUP` assertion of `aura_stacks` equal to `stacks`. `stacks` is the gate spell's
  `StackAmount` (at least 1). The fixture no longer resets a cooldown, pays a cost or waits a global cooldown;
  `GATE_FIXTURE_STEP_COUNT` is 3.
- The class file's `percent` stays the bonus at the stack cap (18 for 705291: 3 stacks x 6).
- Tests: the gate scenario sets the aura before every measured cast and asserts the cap; it never learns or casts
  the gate spell.

## Consequences

- A gate fixture that fails to land fails the scenario instead of measuring an ungated mean.
- The proof covers the debuff's effect on the damage, not the gate spell's own cast path; the gate spell's cast is
  proven by its own checks.
- The round 10 and batch 1 alert on `503141 hit_mean condemn_gate` was a test defect, not a server defect.
