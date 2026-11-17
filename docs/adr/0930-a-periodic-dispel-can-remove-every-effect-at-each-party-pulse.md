# 0930. A periodic dispel can remove every effect at each party pulse

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witching Idol 804051 (Witch Hunter parts 349.1 and 350.0, group G12, owner O-33, mentor D-311): "Drop a Witching
Idol for $d that periodically dispels fear, sleep, and charm effects every $806696T1 sec from party members within
$853203a1 yds." The server DBC has no `coa_client_spell_description` row for it in the test world. 806696
(Tribal Totem) pulses every 2500 ms (`EffectAmplitude[0]`, $806696T1) into 853203, three
`SPELL_EFFECT_DISPEL_MECHANIC` effects naming mechanics 1 charm, 5 fear and 10 sleep, SpellRadius 9 = 20 yd. The
tooltip states no count. The server pulse (`AscensionWitchHunterSummons.cpp:374-381`) removes, every 2500 ms within
that radius around the idol, every aura of those mechanics on the owner and its party members
(`Unit::RemoveAurasWithMechanic`, `Unit.cpp:6319-6333`); the first pulse is scheduled 1 ms after the summon
(`:358`).

`periodic_dispel` judges one removal per period on the caster's own debuffs, so it cannot state "all removed at each
pulse" on a party member, nor the radius.

## Options

- An opt-in `party_pulse` mode on `periodic_dispel`, in its own module, with the judge unchanged (`sum_labels`
  compared exactly by `compare.behaviour_cast_gate_verdict`).
- A new kind: more surface for the same reads.
- One removal per period with three debuffs: it would judge a pulse that removes all of them as an alert.

## Decision

`party_pulse: {"radius_spell": id, "pulses": n}` (`periodic_dispel_party.py`). A party member 3 yd from the caster and a
party member at the radius plus 15 yd carry the debuffs; a control phase without the cast reads all present on
both. After the cast at the caster, the near member is read with none left `margin_ms` after the cast, then for each
of `pulses` periods all present `margin_ms` before and none left `margin_ms` after it, the debuffs being set again
after each "none left" reading; the far member is read with all present at the end. One period then lies in
`period - 2 * margin .. period + margin` ms; the generator refuses a margin whose bracket does not exclude 10% of
the period on both sides (D-200), fixtures that miss a mechanic of the radius spell or carry none of them, fixtures
shorter than the window, and fewer than two pulses. The entry must state its own `margin_ms`.

Witch Hunter fixtures, all `SPELL_AURA_MOD_STUN` so the feared member does not run out of the radius: Intimidating
Shout 65931 (Mechanic 5, 8000 ms), Sleep 9159 (Mechanic 10, 10000 ms), Seduction 6358 (Mechanic 1, 15000 ms).
Margin 100 ms brackets the period in 2300..2600 ms.

## Consequences

- Inert by default: only an entry with `party_pulse` takes the mode; the plain `periodic_dispel` path and its
  labels are unchanged. Templar 19 and Necromancer 23 digests unmoved.
- The read times are nominal: each non-wait step of the accelerated clock adds 3 ms of game time, so a read lands a
  few tens of ms after its nominal time; the 10% bounds stay excluded.
- The idol stands at the caster (`TARGET_DEST_DEST` with no destination falls back to the caster,
  `Spell::SelectImplicitDestDestTargets` → `CheckDst`), so the distances are taken from the caster.
- No non-party unit near the idol is read: "party members" is shown through the two party members only.
- `passives.BEHAVIOUR_LABELS` keeps the plain label list for `periodic_dispel`; a P5 link to a `party_pulse` entry
  would name labels it does not produce (not reached by 804051, an active spell).
- Seeded tests (`test_periodic_dispel_party.py`, run from `test_behaviours.py`): a simulated server that removes all
  effects each 2500 ms is ok; mutants alert: one removal per pulse, a pulse that reaches the far member, periods of
  2250 and 2750 ms, no dispel.
