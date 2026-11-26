# 0021. Felforged is used up by three Fel Fireballs

- Status: accepted (Felsworn mentor decision D-84, 2026-11-24)
- Date: 2026-11-24

## Context

Felforged 806104 (server Spell.dbc, Description[enUS]): "Your next 3 Fel Fireballs have a $s1% reduced cast time for
$d." Effect[0] is aura 108 `SPELL_AURA_ADD_PCT_MODIFIER` on `SPELLMOD_CASTING_TIME`, BasePoints -31 with DieSides 1,
DurationIndex 31 (8000 ms). ProcCharges is 0, so the engine counts no charge, and nothing in the Felsworn code used
the aura up: the 4th Fel Fireball after the grant was still reduced (conformance entry 300490 `fourth_cast` read 5
where 4 means a full-length 4th cast).

The recorded logs (coa-history, 659 Felforged windows in 10 logs) show, in the 342 windows without a refresh: 170
removals at a Fel Fireball cast completion, peaking at three casts; 80 expiries at 8 s with fewer than three casts;
73 windows longer than 8.5 s that the logs do not explain. A Fel Fireball already casting when Felforged is granted
uses a charge when it completes, and a refresh restores three charges.

## Options

- Give 806104 ProcCharges 3 in the class contract and let the engine drop a charge for each spell its modifiers
  touch. Rejected: no Felsworn charge buff uses engine charges; they count in their aura's script value (Twin Slice
  buff 807163, 803904, 707902), and the engine would count every spell its three effect masks reach.
- Count Fel Fireball casts in the class's own cast hooks, as the one-shot Fel Fireball buffs 300486 and 807424 are
  already used up there.

## Decision

806104 joins the Felsworn `selected` auras (`AscensionFelswornAbilities.cpp`), selected by Fel Fireball 801312 and
its ranks. The aura present when a Fel Fireball completes is stamped at `OnSpellBeforeEffects`; at `OnSpellCast` it
counts one used charge in its script value and is removed at the third. 806104 has no aura script binding, so it
takes its selection sequence at that first stamp instead of at apply. The 300490 grant resets the count after its
cast (`AscensionFelswornEvents.cpp`), since an engine refresh keeps the aura and its script values. No shared file,
DBC, SQL or client text changes.

## Consequences

- Fel Fireballs 1 to 3 after a grant are reduced; the 4th casts at 1500 ms. Another Felsworn cast between them uses
  no charge. The 8000 ms duration still ends Felforged with charges left.
- Fel Fireball damage is computed at launch, before `OnSpellCast`, so the 3rd Fel Fireball keeps the Withering
  707416 bonus that rides on Felforged Effect[1].
- Readers of 806104: the 300490 grant and the conformance entries of 300490 and 707416; the 707416 entries set the
  aura before every trial. No other class lists 806104, 300490 or 801312.
