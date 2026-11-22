# 0016. Overflowing Juju scales the folded spell power coefficient

- Status: accepted; amended by 0031 (Malefic Arrow is scaled)
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Overflowing Juju 707405: "Increases the spell power scaling of Malefic Wrath, Shadowflare, and Bad Juju by $s1%."
($s1 = 20). Effect 0 is aura 108 SPELLMOD_BONUS_MULTIPLIER, which the engine applies to the native spell power
coefficient. Every Witch Doctor coefficient row has its native BonusMultiplier zeroed and folded into the effect base
value (`ModifySpellEffectBaseValue`), so the talent scaled nothing: +0.000% at 60000 spell power in all three cycle 9
sweep entries.

Mentor ruling M-59 (2026-11-21): the folded spell power term of the spells its mask names is scaled, except Malefic
Arrow. The Arrow ranks share the Malefic Wrath bit and the tooltip does not name them; Hexfire Wrath 807480 "scales
with modifiers to Malefic Wrath". Owner question Q-TA-1 stays open: whether Malefic Arrow, when 707854 transforms
Malefic Wrath into it, counts as Malefic Wrath.

## Decision

- In `witch_doctor_scaling`, the spell power coefficient is multiplied by 1 + the talent's amount / 100 when the
  aura's mask covers the spell and the spell is not an Arrow (`IsArrow`).

## Consequences

- Regression: catalog `witch-doctor-overflowing-juju-scales-spell-power`: each spell is cast once before the talent
  (control arm) and once after; the second hit over the first must read 1.18 to 1.22 at 60000 spell power. It passed
  in 20261121-062124.
- The proc rate is right on the server; the judge counts trials from Shadow Puppets 500015, which deals no damage, so
  it reads unmeasured. That is an owner tool item.
