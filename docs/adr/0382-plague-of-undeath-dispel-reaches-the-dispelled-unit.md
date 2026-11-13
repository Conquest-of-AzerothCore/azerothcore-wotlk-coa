# 0382. Plague of Undeath's dispel reaches the dispelled unit

- Status: accepted
- Date: 2026-11-13

## Context

Plague of Undeath 801945 (ranks 1-6, 503640 is rank 6): "If Plague of Undeath is dispelled, the enemy takes
${$680928m1+$680928ppl1+$sps*1.25} Plague damage and is stunned for $680928d." The class's AfterDispel hook
(AscensionNecromancerAuras.cpp:266-271, registered for every rank of the chain) cast 680928 at `GetTarget()`.
`AuraScript::GetTarget()` returns nullptr outside the effect and proc hooks (SpellScript.cpp:1186-1214), so nothing was
cast: a real Cure Disease removed the disease from an enemy player and no damage or stun followed (pairs
20261113-003823 / -003900 and 20261113-004714 / -004759; the worldserver log carried the engine's GetTarget error for
spell 503640). The mentor approved the fix (F-b2b-1, G-37: the tooltip states the consequence, the measurement
contradicts it, the cause is in class code, the change stays there).

## Considered options

1. Leave it and ask the owner. Rejected: the four criteria hold.
2. Cast at the dispeller (`DispelInfo::GetDispeller`). Rejected: the tooltip names the enemy that held the disease.
3. Cast at `GetUnitOwner()`, the unit the dispelled aura belonged to. Chosen.

## Decision

The hook casts 680928 at `GetUnitOwner()`.

## Consequences

- Every rank's dispel now deals 680928 and stuns the dispelled unit, not the dispeller.
- Regression: behaviour entries of 503640 for a real dispel of rank 1 and of rank 6 (damage and stun on the dummy that
  cures itself; the stun on a cured player and not on the player who cured it), with the controls of no dispel before,
  an undispelled disease that expires without a blast, and the disease read gone after the cure.
