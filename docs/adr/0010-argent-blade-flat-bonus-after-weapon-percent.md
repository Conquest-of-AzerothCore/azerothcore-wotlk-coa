# 0010. Argent Blade adds its flat bonus after the weapon percent

- Status: accepted
- Date: 2026-11-05

## Context

Argent Blade (804929 and ranks 807263-807268) reads "dealing 215% Weapon Damage plus AP*0.4725+SP*1.35+m1".
Its DBC lists the flat effect (121 `NORMALIZED_WEAPON_DMG`, value 421 at the top rank plus the coefficients the
Templar tables add) before the 215% effect (31 `WEAPON_PERCENT_DAMAGE`). `Spell::EffectWeaponDmg` applies weapon
effects in DBC order, so the 215% multiplied the flat bonus and both coefficients: 2.9 spell power and about
1.0 attack power per point instead of 1.35 and 0.4725.

Measured on this fork (level 60 Templar, Walking Stick, 313 attack power, no spell power, level 60 target, 25
non-critical hits): Argent Blade averages 1019 and the holy Scourgebane hit 263. The measured ratio matches the
multiplied model (about 1000 predicted for Argent Blade once the 0.71 mitigation seen on Scourgebane is applied)
and not the additive one (about 535).

The product owner's reading of the live discussion is that Argent Blade is heavily overtuned. The archived
Ascension logs do not settle the engine's semantics: rank 807268 non-critical hits sit at 1000-1450 for typical
players and 2500 for the best geared, with no attack power or spell power recorded, and Scarlet Hammer, which has the
opposite effect order, is about as strong as Argent Blade there but about 40% of it here.

## Considered options

1. Keep the engine order. Argent Blade stays at the measured level.
2. Reorder the effects of the six ranks. Rejected: talents address effect indexes (Scourge-Defense Training adds
   49 to effect 2, Martial Training and others use EFFECT1-3 spell mods), so a swap would move their bonus onto
   the wrong value.
3. A per-spell flag that applies the weapon percent first and adds the flat value afterwards, set for the Argent
   Blade chain. Chosen.
4. A numeric nerf of the coefficients. Rejected for now: it would not follow the tooltip and would hide the cause.

## Decision

`SpellInfo::AscensionFlatAfterWeaponPercent` makes `EffectWeaponDmg` apply the weapon percent to weapon damage
alone and add the flat bonus afterwards. `AscensionTemplar::ApplyContracts` sets it for the Argent Blade chain.
Other spells keep the DBC effect order. Regression: `templar-argent-blade-flat-bonus-additive`.

## Consequences

- A non-critical Argent Blade falls by about 48% for the same stats in the measured setup (1019 to about 535), and
  more with spell power.
- Divine Strikes, Paladin Training, Scourge-Defense Training and the other multipliers still apply on top.
- 2,168 spells with a flat effect before a percent effect (outside this change) may carry the same multiplication.
  Each class needs its own Ascension evidence before the flag is used elsewhere.
- If later Ascension evidence shows the multiplied hit was live behaviour, clear the flag in `ApplyContracts`; no
  data migration is involved.
