# 0007. Demonic Will reduces Physical damage only

- Status: accepted (owner ruling Felsworn O-12 (2026-11-23, Felsworn ADR 0007))
- Date: 2026-11-23

## Context

Demonic Will 800209 (server Spell.dbc, Description[enUS]): "Generates 1 Felfury. Strengthen your will, reducing
Physical damage taken by $s3% for $d."

Server DBC set, Effect[2]: aura 87 `SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN`, BasePoints -31 with DieSides 1 (`$s3` = 30),
MiscValue 127 (every school). The engine applies the aura to a hit when its MiscValue shares a bit with the hit's
school mask (`Unit::SpellDamageBonusTaken` and `Unit::MeleeDamageBonusTaken`), so the DBC aura reduces every school by
30%. The conformance batch 1 pair measured a 28.8 to 30.3% reduction for every school tried, Physical and magic.

The tooltip names Physical damage only. The owner ruled Physical only (Felsworn O-12 (2026-11-23), decision page); a player
asked the same question also answered "Only Physical". No reference snapshot or combat log gives a value for a
magic hit under the aura.

## Options

- Restrict Effect[2] to the Physical school in the Felsworn class contract, keyed to 800209.
- Change the server DBC record. Rejected: the DBC files stay as shipped, and a class contract already rewrites
  Felsworn effects at load.

## Decision

`AscensionFelsworn::ApplyContracts` sets Effect[2] MiscValue of 800209 to `SPELL_SCHOOL_MASK_NORMAL`. No shared file
changes; no client text change, since the tooltip already says Physical.

## Consequences

- A Physical hit taken under Demonic Will is reduced by 30%; a magic hit is not reduced.
- The other readers of 800209 read only its presence or id, not Effect[2]: Felfury generation
  (`AscensionCustomResourceData.h`), the 805245 condition (`AscensionFelswornEvents.cpp`) and the 520240 cooldown cut
  (`AscensionFelswornAbilities.cpp`). Namesake 500497 has no effects and is not touched. No other class lists 800209.
- Regressions: the `taken_hit` entries `800209 physical_taken` (ratio 0.70, Void Zone 92559, Physical) and
  `800209 holy_taken` (ratio 1.00, Light of the Naaru 41394, Holy), each with a control arm where Demonic Will is
  unlearned and absent.
