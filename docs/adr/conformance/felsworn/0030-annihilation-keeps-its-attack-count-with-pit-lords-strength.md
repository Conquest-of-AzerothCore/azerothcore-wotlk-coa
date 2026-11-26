# 0030. Annihilation keeps its attack count with Pit Lord's Strength

- Status: accepted (tooltip; no owner ruling)
- Date: 2026-11-24

## Context

Annihilation 803904 (server Spell.dbc, Description[enUS]): "Lasts for $n attacks or $d." ($n = ProcCharges 5,
$d = 12000 ms). Pit Lord's Strength 802076 / 802110 (Description[enUS]): "Your Annihilation now affects $s1
additional attack" (Effect[0] SPELL_AURA_ADD_FLAT_MODIFIER, SPELLMOD_CHARGES, $s1 = 1 / 2). Expected: 5, 6 and 7
attacks.

The Felsworn contract clears 803904's ProcCharges and its spell_proc row has no Charges, so the attacks are counted in
the aura's script value (`AscensionFelswornAuras.cpp`, 5 plus SPELLMOD_CHARGES). `Aura::CalcMaxCharges` still applies
the talents' SPELLMOD_CHARGES to the native charges, so the aura held 1 / 2 native charges that
`Aura::PrepareProcToTrigger` and `Aura::ConsumeProcCharges` spent on the first landed attacks and then removed the
aura. A diagnostic scenario (dual wield, read every 700 ms) measured native charges 0 / 1 / 2 at the cast; without the
talent the count went 5, 3, 1 over 4 landed attacks; with 802076 or 802110 the count read 6 / 7 at the cast and the
aura was gone after the first landed pair. The conformance entries reported by fw-bsw read 6 / 7 at the cast and 0
after 3 landed attacks.

## Options

- (a) Clear the aura's native charges when the Felsworn script sets its count, so only the script count ends the aura.
- (b) Drop the script count and let native charges end the aura: the direct-hit path
  (`OnSpellCalculatedTarget`) and the proc handler both use the script count; this would rewrite both.

## Decision

(a). The 803904 branch of the Felsworn aura apply hook calls `SetCharges(0)` after it stores the count. The hook runs
on apply and on reapply; a refresh resets the native charges (`Aura::ModStackAmount`) before its reapply, so the hook
clears them again (code reading; the 60 s cooldown makes a refresh rare and it was not measured). Without a talent
the native charges were already 0, so that case does not change. No SQL, DBC, client text or other file changes.

## Consequences

- With either rank the count drops by one per landed attack, and the aura goes after the 6th / 7th attack or at 12 s.
- The client shows no charge count on the aura with or without a talent, as before without one.
- Regression: `felsworn-annihilation-pit-lords-strength-attacks` (one 1300 ms main-hand dagger per arm) reads the
  native charges 0 and the count after each landed attack until the aura is removed, for 802076, 802110 and the
  no-talent control.
- Readers: 803904 and its script count are used only by Felsworn code (`AscensionFelswornAuras.cpp`,
  `AscensionFelswornEvents.cpp`, `AscensionFelswornAbilities.cpp`, `AscensionFelswornContracts.cpp`) and the Felsworn
  spell_proc rows; 802076 and 802110 are Felsworn talents. No other class lists them.
