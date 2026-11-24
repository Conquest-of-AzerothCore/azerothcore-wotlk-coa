# 0019. Hateforged Barrier reduces Physical damage while it holds

- Status: accepted (Felsworn mentor decision D-81, 2026-11-24)
- Date: 2026-11-24

## Context

Hateforged Barrier 707527 (server Spell.dbc, Description[enUS]): "Manifest a barrier of pure hatred, absorbing
${$m1+0+$STA*1} damage, scaling with your Stamina, for $d. While the barrier holds, you take $s2% reduced Physical
Damage." `$s2` is 10 (Effect[1] BasePoints -11 with DieSides 1).

Server DBC set, Effect[1] of every rank: aura 87 `SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN`, BasePoints -11. Rank 1
705129 carries MiscValue 1 (Physical); ranks 707523, 707524, 707525, 707526 and 707527 carry MiscValue 0. The engine
applies an aura 87 effect to a hit only when its MiscValue shares a bit with the hit's school mask
(`Unit::SpellDamageBonusTaken` and `Unit::MeleeDamageBonusTaken`), so ranks 2 to 6 never reduce any damage. The
conformance pairs read -2.26% to -2.36% per Void Zone strike under 707527 against the -12.08% their entry stated;
the strike that broke the barrier also removed the reduction, so those runs could not tell 10% from none (fw-vb4b).

## Options

- Set Effect[1] MiscValue of 707523 to 707527 to the Physical mask in the Felsworn class contract, as rank 1 and the
  Demonic Will precedent ([Felsworn ADR 0007](0007-demonic-will-reduces-physical-damage-only.md)) do.
- Change the server DBC records. Rejected: the DBC files stay as shipped, and the class contract already rewrites
  Felsworn effects at load.

## Decision

`AscensionFelsworn::ApplyContracts` sets Effect[1] MiscValue of 707523 to 707527 to `SPELL_SCHOOL_MASK_NORMAL`.
Rank 1 705129 already carries it and is not touched. No shared file changes; no client text change, since the
tooltip already says Physical.

## Consequences

- A Physical hit taken under any rank is reduced by 10%; a magic hit is not. The reduction is part of the barrier's
  aura, so it ends when the absorb is used up (`Unit::CalcAbsorbResist` removes the aura at 0) or when `$d` ends.
- The other readers of the Hateforged Barrier ranks read only their presence, name or Effect[0]: the 300468 trigger
  and the 520240 cooldown cut (`AscensionFelswornAbilities.cpp`), the 560822 removal cast
  (`AscensionFelswornAuras.cpp`), the 803478 maximum-health absorb term (`AscensionFelswornContracts.cpp`) and the
  805245 condition (`AscensionFelswornEvents.cpp`). No other class lists these spells.
