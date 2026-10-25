# Monster linear magic resistance

Live Conquest of Azeroth monsters resist magic damage, including Holy, by an amount that grows with their level and
that player spell penetration can remove completely. This mode, on by default, reproduces that behavior. The resistance
calculation follows the live evidence below; `PerPercent` is a reconstruction choice that the logs cannot pin down.

## Behavior

When enabled, NPCs not controlled by players receive `PerLevel` additional base resistance per effective combat level
in every magic school, including Holy. Authored resistance and native resistance modifiers still apply. Target debuffs
can reduce the added baseline before resistance is clamped to zero. Player item spell penetration and caster resistance
modifiers then apply through the existing core path, including native pet-owner inheritance.

The effective resistance gives an average resist fraction:

```text
school resistance = ((base resistance + combat level × PerLevel) × base multiplier
                     + flat target resistance modifiers) × total multiplier
effective resistance = max(0, school resistance + caster resistance modifiers - item penetration)
average resist = min(effective resistance / (100 × PerPercent), MaxReductionPct / 100)
```

Each hit and DoT tick then rolls the native WotLK partial-resist distribution around that average: 0%, 10%, 20% … of the
damage is resisted, in 10% steps, with a mean equal to the average resist. There is no separate DoT resistance factor.
With no authored resistance, buffs or debuffs, a level-60 monster has:

| Spell penetration | Effective resistance | Average resist | Partial resist chances (0/10/20/30%) |
| ---: | ---: | ---: | --- |
| 0 | 60 | 12% | 20 / 45 / 30 / 5% |
| 30 | 30 | 6% | 55 / 30 / 15 / 0% |
| 60 | 0 | 0% | 100 / 0 / 0 / 0% |
| 100 | 0 | 0% | 100 / 0 / 0 / 0% |

Existing school resistance is additional. A level-63 boss's baseline is 63, not 60, and contains no separate
unpenetrable level-difference term.

Damaging spells are never fully resisted by an affected monster: spells with school damage, health leech, periodic
damage or periodic leech skip the school-based binary full-resist roll and receive the partial resist instead. Binary
crowd control without damage keeps the native full-resist roll, using the same effective resistance.

## Live evidence

From live WoWCombatLog captures dated 2026-05-31 to 2026-08-30, about 800,000 player magic hits on non-player-controlled
creatures after 2026-07-12:

- Resisted amounts are multiples of 10% of the hit. For cells with an average resist under 10%, the share of
  10% and 20% partial resists matches the WotLK distribution to within half a percentage point
  (2–4% average: 15.0/7.3% observed against 14.8/7.4% expected).
- Logs up to 2026-06-21 contain negative resists (bonus damage) on monsters; from 2026-07-12 they are gone,
  consistent with the zero floor.
- Holy damage is partially resisted by creatures.
- Several players resist only 0.16–0.7% of their damage on level-63 bosses, which a non-penetrable level term would
  not allow.
- DoT ticks are resisted almost as often as direct hits (17.6% against 21.1% of hits), so there is no 0.1 DoT
  factor.
- The CoA feature description states that damaging spells cannot be fully resisted, while creatures can fully resist
  crowd control.

The deterministic reduction and the Classic+ 25/50/75% distribution do not fit these logs. `PerPercent = 5` cannot be
derived from the logs alone, because penetration and player gear are not recorded.

## Scope and compatibility

- Players, player-controlled pets and charmed creatures keep their existing resistance rules as targets. Pet attacks
  against monsters can benefit from their owner's penetration.
- The baseline uses `getLevelForTarget`, so per-viewer creature scaling and existing relative boss-level rules apply.
  It is calculated during combat; creature templates and displayed resistance fields are unchanged.
- Affected monsters always use the native WotLK partial-resist roll, also when `ClassicPlus.CombatRules` is enabled;
  the Classic+ 25/50/75% table and DoT factor remain in use for every other target.
- Spell accuracy, mechanic/debuff resistance and immunity checks are unchanged.
- Pure physical damage keeps the native armor path. Mixed physical/magic spell handling, including the
  weakest-defense rule, remains native.
- Explicit resistance bypasses remain effective, including `AscensionIgnoreAbsorbAndResistance` and the existing
  `SPELL_ATTR4_NO_CAST_LOG` exemption. Spell-specific resistance-ignore effects still run after the roll.
- The feature is not restricted to level-60 content. Switching it off restores the native paths.

## Configuration

The settings live in `modules/coa.conf` (template `src/server/coa/conf/coa.conf.dist`):

```ini
CoA.MonsterResistance.Enable = 1
CoA.MonsterResistance.PerLevel = 1.0
CoA.MonsterResistance.PerPercent = 5.0
CoA.MonsterResistance.MaxReductionPct = 75.0
```

| Setting | Default | Valid values |
| --- | ---: | --- |
| `CoA.MonsterResistance.Enable` | `1` | `0` or `1` |
| `CoA.MonsterResistance.PerLevel` | `1.0` | Finite, at least 0 |
| `CoA.MonsterResistance.PerPercent` | `5.0` | Finite, greater than 0 |
| `CoA.MonsterResistance.MaxReductionPct` | `75.0` | Finite, from 0 to 100 |

Invalid numeric values fall back to their defaults. `CoA.MonsterResistance.Enable = 0` restores the native resistance
paths. `modules/coa.conf` is read after `worldserver.conf`, so a value there wins over a leftover entry in
`worldserver.conf`. The settings follow the normal configuration reload.

## Verification and limitations

The `classic_combat` harness compiles the production effective-resistance and magic-hit methods, plus the resistance
stage of `CalcAbsorbResist`, against bounded engine fixtures. It checks the baseline, authored resistance, target-side
flat and percentage modifiers, penetration and its zero floor, the 10% step distribution and its mean for direct and
periodic damage, Holy, binary damage against binary crowd control, accuracy, mechanic resistance, player/pet
exclusions, scaled and relative boss levels, configurable rates and caps, explicit bypasses and mixed-defense handling.

It does not exercise absorption, full server linking, DBC spell records or live combat. On a development realm, confirm
the 0/30/60/excess penetration cases, a DoT, a binary damage spell and a binary crowd-control spell against a monster.
