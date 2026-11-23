# 0154. Read the resisted amount and keep generated fixtures at the class level

- Status: accepted
- Date: 2026-11-11

## Context

`templar-high-general-chastise-damage` compared two arms of eight Chastise 803157 crits on level 80 dummies, inside
1.9-2.1. CoA.MonsterResistance gives a level 80 creature 80 Holy resistance, a 16% average resist drawn in tenths for
every hit, so a correct server left the band about 31% of the time (1.811 then 2.064 on one build). The server's
x2.0 for High General 524617 was never in doubt; the test could not resolve it at that sample size. The mentor's
brief asked for a proof by construction: remove the resist with beeg spellpen 823764 and assert that no hit is
partially resisted. The harness parsed `SMSG_SPELLNONMELEEDAMAGELOG` but skipped its resisted field.

Light's Chosen 301310 grants spell penetration through 301369 (aura 123 `SPELL_AURA_MOD_TARGET_RESISTANCE`). Its
fix needs a deterministic readback of the target's effective resistance; no metric gave it.

Blessed Padding 301311 and 301360 equipped chest 1065932, whose `RequiredLevel` is 80, and their class file entries
raised the generated player to level 80 to fit it. The target level policy of 2026-11-11 keeps players at the realm
cap, 60. `item_template` is SQL data, outside the DBC set the generator reads.

## Considered options

1. Run the High General scenario 13 times or more, which brings a lucky pass under 1%. Rejected while the resisted
   amount can be read: a per-hit zero is a direct proof, and one or two runs suffice.
2. Keep the class file's `level` override for items above the class level. Rejected: it puts players above 60.
3. Read the resisted amount, read back the resist chance, and refuse an item entry above the class level. Chosen.

## Decision

- The harness keeps the resisted amount of every direct spell damage log: `spell_resist_total`, with the `caster`,
  `target` and `critical` filters of `spell_absorb_total`.
- `spell_resist_chance` reads back `Unit::GetEffectiveResistChance` for the player's spells of a magic `school`
  (1..6) on `target`, in percentage points, after the player's target resistance and penetration modifiers. It
  applies no hit, so it is a readback under the trial ruling of 2026-11-11 (point 4).
- An `item_armor_subclass_effects` entry states `required_level`, the `RequiredLevel` of its item's `item_template`
  row, and cites where it was read. `passive_scenario` refuses an entry without it, one above the class file level,
  or one that sets its own `level`; the player always stays at the class file level.

## Consequences

- `templar-high-general-chastise-damage` runs at level 60 against level 60 dummies, with 823764 on both players,
  and asserts a resisted amount of 0 on every Chastise log of both arms.
- Blessed Padding equips Void Slayer's Tunic 30298 (mail chest, `RequiredLevel` 60, template armor 704 in the test
  database) at level 60. A Templar wears the ItemAddon.dbc reborn armor instead (`LocalLevelScaling::WornArmorFor`),
  574 for 30298; with 27 from the starter mail, the mail armor the passive scales reads 601.
- `templar-chastise-partial-resist-read` is the positive control: without 823764, twelve Chastise hits on a level 60
  dummy must show a positive resisted total.
- Tests: `test_runner.test_spell_log_metrics_need_a_spell_and_take_the_caster_filters`,
  `test_runner.test_spell_resist_chance_needs_a_magic_school_and_a_target`,
  `test_passives.PassiveScenarioTest.test_item_armor_subclass_item_must_be_wearable_at_the_class_level` and
  `test_blessed_padding_equips_its_mail_chest_at_the_class_level`.
