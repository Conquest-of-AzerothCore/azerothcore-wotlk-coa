# One-button rotation assistance

Create a macro with the following text, put it on an action bar and bind it to a comfortable key:

```text
/s .rotation
```

Select a living enemy to attack or a friendly target to heal, then press the button once for each ability. Each
press submits at most one ordinary spell cast. There is no timer or automatic rotation between presses. Presses
during a cast, a queued melee attack or an existing spell queue do nothing. A press during the global cooldown
usually has no available attack; press again when ready.

The command is available to ordinary players of every class. Characters with a CoA specialization use the imported
attack and healing priorities for that specialization, restricted to spells they currently know. The basic fallback
also works for stock classes, classless characters and characters without a specialization. It tries learned,
single-target damage or healing spells with a base cooldown of at most 15 seconds, ordered by spell level and spell
ID. It does not promise an optimal rotation for every talent build, encounter or level.

Normal costs, cooldowns, equipment, stance, line of sight, range and facing checks still apply. The highest active
learned rank of a named spell is used, and native temporary spell replacements remain in effect. For spells that
directly apply a damage-over-time or healing-over-time effect, the button waits for this player's effect to expire
before reapplying it. Fully healed friendly targets do not receive another heal.

The player still chooses movement, target, forms, buffs, defensive abilities, taunts, pets, ground-targeted
spells and untargeted area attacks. Party and tank healing rules address only the selected friendly target; the
command never chooses another ally. Bot rules for enemy counting and automatic movement are not imported. The
authored priorities can include
attacks that also hit nearby enemies; this is not a crowd-control-safe mode. Start ordinary auto-attacks yourself
when using attacks that wait for the next weapon swing. Channels and normal triggered spell effects behave as they
do when that ability is pressed directly.

Realm operators can disable the command with `CoA.RotationAssist.Enable = 0` in `coa.conf`, including on config
reload. The feature needs no playerbots module, bot database, SQL migration, addon or client patch.

## Rotation data and attribution

`src/server/coa/CoARotationData.h` adapts the attack and healing rules from
[Zyth45/mod-playerbots](https://github.com/Zyth45/mod-playerbots/tree/10d0058cefe2a981373d65bc192464181ec9a49c),
revision `10d0058cefe2a981373d65bc192464181ec9a49c` (CoA Bots 2.4). The upstream module is distributed under GPL
version 2 or any later version; its copyright notices and
[contributors](https://github.com/Zyth45/mod-playerbots/blob/10d0058cefe2a981373d65bc192464181ec9a49c/AUTHORS.md)
remain credited. CoA specialization guide data is credited to ascensionsidekick.com and steviecraycray. The
repository's `LICENSE` contains GPL version 2.

The snapshot starts with `data/sql/playerbots/custom/zz_coa_rotation_corrections_1_9.sql`, then applies every later
`zz_coa_rotation_corrections_*.sql` in filename order through `2_4`. This includes the fixes for Time Out!, Assume
Peak Posture and the Reaper spender priorities. Specialization IDs come from `playerbots_coa_rotations.sql`. No
upstream SQL is executed against the world or character databases.

The adaptation retains 1,571 rules across 70 specialization profiles. It keeps `cast`, `cast melee`, `cast debuff`,
`cast heal`, `cast heal party` and `cast heal tank` actions with readiness, missing debuff, aura
presence/absence/stacks, self/target health, mana or resource conditions. Rules are sorted by descending upstream
priority with original row order breaking ties; identical rules are deduplicated. Mana thresholds are 15%/40%;
health thresholds are 25%/45%/65%, matching the upstream defaults. Resource thresholds use the percentage of
maximum power. Target-aura conditions accept effects from any caster, as upstream does. Runtime spell data
requires a matching damage or healing effect (including periodic and triggered effects) and excludes automatic
repeat attacks, movement,
taunting, summoning and other manual actions. Damage implemented entirely by a script without a damage effect in
its effective spell data stays manual. An unavailable or unknown rule falls through. This is a source snapshot, not
a live dependency or a claim that all 70 rotations have been measured in game.

## Verification

The `rotation_assist` harness checks the imported priorities, condition boundaries, missing/unavailable spells and
selection of at most one action. The `rotation-assist` gameplay scenario exercises the ordinary player command,
selected-target requirement, native spell effects, resource costs, cooldowns and idle behavior. The
`rotation-assist-profile` scenario checks Incineration against a competing fallback spell.
`rotation-assist-target-aura` checks a matching target debuff from another caster. Run them through
`tools/verify_all.py` as described in [verification](verification.md).
