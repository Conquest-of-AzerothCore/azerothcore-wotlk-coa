# 0031. Raising the Kirin Tor refunds a fixed 10 Runic Power

- Status: accepted
- Date: 2026-11-13

## Context

Raising the Kirin Tor 805649 (Spell.dbc): "Your Command spells now have a $h% chance to refund a portion of their
Runic Power cost." (ProcChance 40). Its refund spell 359505 "Energize Runic Power +30" reads "Gain 10 Runic Power"
while its Effect[0] SPELL_EFFECT_ENERGIZE BasePoints are 299 + 1 = 300 (30 Runic Power). The server refunded the
whole cost the Command paid (`spell->GetScriptValue(359505)`, set from `GetPowerCost()` at cast), so a full Command:
Undead 504868 (ManaCost 300, PowerType 6) gave back all 30 Runic Power, not a portion. The owner ruled (Q-c4-1) a
fixed 10 Runic Power, the refund spell's text.

Options: (a) whole paid cost (unchanged); (b) the 359505 BasePoints, 30 Runic Power; (c) the 359505 text, 10 Runic
Power.

## Decision

- Option (c): `necromancer_casts::OnSpellCast` energizes 359505 for 100 internal units (10 Runic Power) when the
  805649 roll succeeds. The paid-cost script value stays: the Blight path (500217) still reads it.

## Consequences

- Regression (class file): the Raising the Kirin Tor proc entry carries `energize_amounts` power 6, expected 100:
  every 359505 energize after Command: Undead 504868 (a 30 Runic Power Command) restores 100; the proc entry's
  baseline arm without the talent is the control (no 359505 energize).
- The refund no longer depends on the paid cost: a Command made cheaper by a cost modifier also refunds 10 Runic
  Power (code reading; not measured).
