# 0340. A raised minion drives trigger and proc entries

- Status: accepted
- Date: 2026-11-12

## Context

Most Necromancer passives fire on a summoned minion's hits ("Critical strikes dealt by your Abominations now Chomp
your target", "Damage dealt by your Undead minions now has a 5% chance to restore..."). Every trigger action
(`cast`, `attack`, `periodic`, `taken_hit`) and every proc trigger counted the player's own events, so none of these
claims had a route. The aura behind many of them is a SPELL_EFFECT_ASCENSION_APPLY_AURA_TO_SUMMONS (190) aura that
sits on the minions and never on the caster, so the trigger and proc judges, which drop parts whose caster has no
aura, also excluded every run.

## Considered options

1. A dedicated behaviour kind per spell. Rejected: a new kind costs code, judge, evidence row and docs each time, and
   the trigger and proc judges already decide the claims.
2. Harness-scripted minion attacks (C++). Rejected: the class code already makes a raised minion attack its owner's
   victim (`AscensionNecromancerSummons.cpp:780-796`); a harness change beyond reading needs a prior note (G-39).
3. A `minion` trigger action that the existing trigger, magnitude, gate-absence and proc builders share. Chosen.

## Decision

- `trigger: {"action": "minion", "spell": <summon>, "entry": <creature>, "swing_ms", "swing_source", "learn"}`: the
  scenario learns `learn` (Life Force capacity) and the summon spell, casts it with its power and cooldown fixtures,
  asserts one owned creature of `entry` (8000 ms), and the caster attacks the dummy so the minion engages it. An
  attempt is one `swing_ms` of minion swings; `swing_source` cites `creature_template.BaseAttackTime`.
- Trials: `pet_melee_crits`, `pet_melee_swings` or `owned_creature_damage_count` of `entry`; events may be read on
  the minion (`observe_actor: "minion"`, `spell_damage_count` by entry).
- `minion_auras` (precondition fixtures, G-21 point 6) are removed and set again every `minion_aura_refresh_ms`,
  since `set_aura` does not refresh an existing aura; `caster_health_pct` holds the caster's health between windows.
- `aura_on_minion` reads a summons-only aura on the minion (`owned_creature_count` with `spell` and `caster`).
- `aura_cast` casts an active aura after its learn (Fetid Ward); `caster_power` sets a power before each cast, for
  base-mana percentage costs the cast fixture leaves unset.
- Proc entries: the same action; `baseline: true` swings the minion before the learn for
  `max(20, ceil(log 0.01 / log(1 - p)))` attempts, so a live roll of chance `p` shows an event with 99% probability;
  `judge_proc` alerts on any baseline event and leaves those trials out of the rate. Minion procs are keyed by
  their summon spell.

## Consequences

- Templar `generate --class 19` and `--stack` stay byte-identical; every new field defaults to the old output.
- Counted Necromancer pairs: Chomp 271/271 crits, Vampiric Aura (trigger, gate absence at full health, 0.0967
  magnitude), Overwhelming Force and both Putricide's Formula ranks (proc rates with sized baselines). The same rig
  showed Depravity's Bone Club and Plague Horde never roll (fix note F-b1-1).
- The minion's level is the owner's by class code (`AscensionNecromancerSummons.cpp:289`); no harness read of an
  owned creature's level exists yet.
