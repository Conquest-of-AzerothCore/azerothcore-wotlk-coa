# 0520. The Decaying Colossus takes a quarter of its caster's damage

- Status: accepted
- Date: 2026-11-13

## Context

Raise: Decaying Colossus 500989: "25% of all damage taken by the caster is taken by the Decaying Colossus." Decaying
Colossus Passive 520376 (Spell.dbc: Effect[0] 143 SPELL_EFFECT_APPLY_AREA_AURA_OWNER, aura 81
SPELL_AURA_SPLIT_DAMAGE_PCT, BasePoints 24 + 1 = 25, DurationIndex 21) carries the split, but no code applied it: the
Colossus 50115 runs `npc_ascension_necromancer`, whose `IsSummonedBy` casts only the occupancy aura and
`ChampionAura(entry)`, which knew the three champions only. The taken_hit entry read a ratio of 1.0 against the
stated 0.75. The owner ruled (Q-a1-3, option (a), rulings 3.2) to apply the split; the mentor approved fix note FN-own-1.

## Decision

- `ChampionAura` returns 520376 for the Colossus 50115. The existing paths cast it on summon and remove it in
  `JustDied`, as for the Gravebound Champion's 805050 (same 143/81 layout, its split proven at 0.5).

## Consequences

- Regression (class file): `Raise: Decaying Colossus (damage split)` (taken_hit, damage_ratio 0.75; control without a
  Colossus). The Champion split (0.5) is the identity check.
- With a Champion and a Colossus up, two SPLIT_DAMAGE_PCT auras apply in the stock order; the Colossus can die from
  its share. `ChampionAura` now also names a non-champion.
- The live logs show no 520376 event; the ruling decides, not the logs.
