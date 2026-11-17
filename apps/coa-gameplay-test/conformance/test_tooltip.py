from dataclasses import replace
from pathlib import Path
import struct
import tempfile
import unittest

from tooltip import (MAX_EXPANSION_DEPTH, PER_TICK, CasterStats, DataSet, Displayed, ForcedPoints, Records, Tooltip,
                     client_spell_level, period_reading, read_tooltip, weapon_skill_spells)
import schemas
from streamed import streamed_field, streamed_texts

DBC_DIR = Path('/srv/coa/server-data/dbc')

SCHOOLS = range(7)
HOLY, FIRE, NATURE, FROST, SHADOW, ARCANE = 1, 2, 3, 4, 5, 6
LEVEL_60_TEMPLAR = CasterStats(level=60, ap=313.0, rap=0.0, sp_by_school={school: 0.0 for school in SCHOOLS},
                               stats={stat: 0.0 for stat in range(5)})

ARGENT_BLADE = 807268
ARGENT_BLADE_BASE_POINTS = (420, 214)
SCOURGEBANE_PASSIVE = 92111
SCOURGEBANE_PROC_AURA_CHANCE = 20
SCOURGEBANE_DAMAGE_BASE_POINTS = (261, 49)
SCALINGBP_TERMS = (0.0267291844060354, 0.0048541098014737, 0.0001859597762293)
HOLY_COMBATANT = 500011
HOLY_COMBATANT_EXTENSION_BASE_POINTS = 999
RETRIBUTION = 707391
RETRIBUTION_PROC_CHANCE = 20
RETRIBUTION_BASE_POINTS = 29
HEXBREAK = 806240
STUDIOUS = 705657
STUDIOUS_BASE_POINTS = -16
OUTMANEUVER = 557325
OUTMANEUVER_DURATION_MS = 8000
OUTMANEUVER_STACK_AMOUNT = 20
OUTMANEUVER_BASE_POINTS_3 = 29
DECOY_STRIKE_BASE_POINTS = 850
VEILED_IN_DARKNESS = 524854
HOLY_CONSTITUTION = 706323
HOLY_CONSTITUTION_BASE_POINTS_2 = 29
VEILED_IN_DARKNESS_RADIUS_YARDS = 100.0
SCOURGEBANE_STRIKE = 801832
INTERDICT_EXTENSION = 500014
HOLY_LIGHT = 706449
HOLY_LIGHT_CAST_TIME_POINTS = 1500
ZEALOTRY_PASSIVE = 92108
ZEALOTRY = 801450
ZEALOTRY_WEAPON_BASE_POINTS = 79
GLORY = 801481
DOWNFALL = 801482
REDEMPTION = 801483
DOWNFALL_DURATION_MS = 5000
HUMAN, TEMPLAR = 1, 19
STAFF_SUBCLASS = 10
STAVES = 227
STAVES_LINE = 136
TEMPLAR_LINES = (70, 71, 72)
LEVEL_60_SKILL = 300
SKILLED_TEMPLAR = replace(LEVEL_60_TEMPLAR, skills=dict.fromkeys(TEMPLAR_LINES + (STAVES_LINE,), LEVEL_60_SKILL),
                          race=HUMAN, class_id=TEMPLAR)
DIVINE_FORCE = 807805
DIVINE_FORCE_BASE_POINTS_3, DIVINE_FORCE_PER_LEVEL_3, DIVINE_FORCE_BASE_LEVEL = 376, 1.125, 58
RECKONING = 572741
RECKONING_BASE_POINTS, RECKONING_PER_LEVEL, RECKONING_BASE_LEVEL = 165, 3.376800060272217, 56
STAFFGUARD = 705295
STAFFGUARD_HEALTH = 706583
STAFFGUARD_HEALTH_BASE_POINTS = 124
UNTAINTED = 705298
UNTAINTED_EFFECT = 705299
UNTAINTED_EFFECT_BASE_POINTS = -11
CHAKRA_OF_LIGHT = 803844
CHAKRA_OF_LIGHT_BASE_POINTS = 49
ARMOR_OF_FAITH = 804930
ARMOR_OF_FAITH_FORMULA = 801546
ARMOR_OF_FAITH_BASE_POINTS, ARMOR_OF_FAITH_PER_LEVEL, ARMOR_OF_FAITH_BASE_LEVEL = 165, 1.4, 31
RIGHTEOUS_TEMPEST = 807274
RIGHTEOUS_TEMPEST_PERIOD_MS = 1000
BLADE_OF_FAITH = 803880
BLADE_OF_FAITH_PERIOD_MS = 3000
BLADE_OF_FAITH_DURATION_S = 30
BLADE_OF_FAITH_TOTAL = '${($d*1000/$T1)*($m1+0+$SP*.2+$AP*0.1)}'
BLADE_OF_FAITH_BASE_POINTS, BLADE_OF_FAITH_PER_LEVEL, BLADE_OF_FAITH_BASE_LEVEL = 205, 1.125, 58


def displayed(readout, text):
    matches = [value for value in readout.values if value.text == text]
    if len(matches) != 1:
        raise AssertionError(f'{text!r} read {len(matches)} times in {readout}')
    return matches[0]


def scalingbp(level):
    constant, linear, quadratic = SCALINGBP_TERMS
    return constant + linear * level + quadratic * level * level


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ClientDbcTooltipTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dbc = DataSet(DBC_DIR)

    def read(self, spell_id, caster=LEVEL_60_TEMPLAR):
        return read_tooltip(self.dbc, spell_id, caster)

    def test_argent_blade_weapon_percent_and_flat_bonus(self):
        readout = self.read(ARGENT_BLADE)
        weapon_points, flat_points = ARGENT_BLADE_BASE_POINTS
        self.assertEqual(displayed(readout, '$s2'), Displayed('$s2', flat_points + 1, 1, 'percent',
                                                                 ARGENT_BLADE))
        bonus = displayed(readout, '${$AP*0.4725+$sph*1.35+$m1+0}')
        self.assertAlmostEqual(bonus.value, 313 * 0.4725 + 0 * 1.35 + weapon_points + 1, places=9)
        self.assertAlmostEqual(bonus.value, 568.9, delta=0.01)
        self.assertEqual((bonus.effect_index, bonus.kind), (0, 'flat'))

    def test_argent_blade_resolves_scalingbp_against_the_spell_that_defines_it(self):
        readout = self.read(ARGENT_BLADE)
        damage = displayed(readout, '${$801832m1*$<scalingbp>+$sph*0.25+$AP*0.25}')
        damage_points, _ = SCOURGEBANE_DAMAGE_BASE_POINTS
        self.assertAlmostEqual(damage.value, (damage_points + 1) * scalingbp(60) + 313 * 0.25, places=6)
        self.assertEqual(readout.unreadable, [])

    def test_scourgebane_proc_chance_and_scaled_damage(self):
        readout = self.read(SCOURGEBANE_PASSIVE)
        self.assertEqual(displayed(readout, '$520007h'),
                         Displayed('$520007h', SCOURGEBANE_PROC_AURA_CHANCE, None, 'chance_pct'))
        damage_points, weapon_points = SCOURGEBANE_DAMAGE_BASE_POINTS
        self.assertEqual(displayed(readout, '$801832s2'), Displayed('$801832s2', weapon_points + 1, None, 'percent',
                                                                           SCOURGEBANE_STRIKE))
        damage = displayed(readout, '${$801832m1*$<scalingbp>+$SP*.25+$AP*.25}')
        self.assertAlmostEqual(scalingbp(60), 0.9874, delta=0.00005)
        self.assertAlmostEqual(damage.value, (damage_points + 1) * scalingbp(60) + 313 * 0.25, places=6)
        self.assertAlmostEqual(damage.value, 262 * 0.9874 + 78.25, delta=0.02)
        self.assertEqual((damage.effect_index, damage.kind), (None, 'flat'))
        self.assertEqual(readout.unreadable, [])

    def test_scalingbp_follows_the_caster_level(self):
        caster = CasterStats(level=40, ap=0.0, rap=0.0, sp_by_school={school: 0.0 for school in SCHOOLS}, stats={})
        damage = displayed(self.read(SCOURGEBANE_PASSIVE, caster), '${$801832m1*$<scalingbp>+$SP*.25+$AP*.25}')
        self.assertAlmostEqual(damage.value, (SCOURGEBANE_DAMAGE_BASE_POINTS[0] + 1) * scalingbp(40), places=6)

    def test_sp_is_the_lowest_school_spell_power(self):
        powers = {0: 0.0, HOLY: 120.0, FIRE: 80.0, NATURE: 95.0, FROST: 110.0, SHADOW: 100.0, ARCANE: 90.0}
        caster = CasterStats(level=60, ap=313.0, rap=0.0, sp_by_school=powers, stats={})
        damage = displayed(self.read(SCOURGEBANE_PASSIVE, caster), '${$801832m1*$<scalingbp>+$SP*.25+$AP*.25}')
        expected = (SCOURGEBANE_DAMAGE_BASE_POINTS[0] + 1) * scalingbp(60) + powers[FIRE] * 0.25 + 313 * 0.25
        self.assertAlmostEqual(damage.value, expected, places=6)

    def test_missing_school_spell_power_is_unreadable(self):
        caster = CasterStats(level=60, ap=313.0, rap=0.0, sp_by_school={HOLY: 0.0}, stats={})
        readout = self.read(SCOURGEBANE_PASSIVE, caster)
        self.assertIn('${$801832m1*$<scalingbp>+$SP*.25+$AP*.25}', readout.unreadable)
        self.assertNotIn('${$801832m1*$<scalingbp>+$SP*.25+$AP*.25}', [value.text for value in readout.values])

    def test_holy_combatant_division_reads_seconds(self):
        readout = self.read(HOLY_COMBATANT)
        self.assertEqual(readout.values, [Displayed('$/1000;500014s1', HOLY_COMBATANT_EXTENSION_BASE_POINTS + 1, None,
                                                    'duration_ms', INTERDICT_EXTENSION)])
        self.assertEqual(readout.unreadable, [])

    def test_retribution_proc_chance_and_percent(self):
        readout = self.read(RETRIBUTION)
        self.assertEqual(readout.values, [Displayed('$h', RETRIBUTION_PROC_CHANCE, None, 'chance_pct'),
                                          Displayed('$s1', RETRIBUTION_BASE_POINTS + 1, 0, 'percent', RETRIBUTION)])
        self.assertEqual(readout.unreadable, [])

    def test_known_spell_conditional_chooses_the_false_branch_when_the_gate_is_unknown(self):
        readout = self.read(HEXBREAK)
        self.assertEqual(readout.values, [Displayed('$s1', 1, 0, 'flat', HEXBREAK)])
        self.assertEqual(readout.unreadable, [])

    def test_known_spell_conditional_chooses_the_true_branch_when_the_gate_is_known(self):
        caster = replace(LEVEL_60_TEMPLAR, known_spells=frozenset({572870}))
        readout = self.read(HEXBREAK, caster)
        self.assertEqual(readout.values, [Displayed('$s1', 1, 0, 'flat', HEXBREAK)])
        self.assertEqual(readout.unreadable, [])

    def test_conditional_keeps_its_color_codes_verbatim_and_negative_points_display_unsigned(self):
        readout = self.read(STUDIOUS)
        self.assertEqual(readout.unreadable, [])
        self.assertEqual(readout.values, [Displayed('$s1', abs(STUDIOUS_BASE_POINTS + 1), 0, 'percent', STUDIOUS)])

    def test_conditional_with_an_unhandled_operator_stays_one_unreadable_entry(self):
        readout = Tooltip(Records(self.dbc), HEXBREAK, LEVEL_60_TEMPLAR).read('$?!s572870[s][]')
        self.assertEqual(readout.values, [])
        self.assertEqual(len(readout.unreadable), 1)
        self.assertIn('unhandled $? operator', readout.unreadable[0])

    def test_chained_conditional_stays_one_unreadable_entry(self):
        readout = Tooltip(Records(self.dbc), HEXBREAK, LEVEL_60_TEMPLAR).read('$?s572870[a]?s1[b][c]')
        self.assertEqual(readout.values, [])
        self.assertEqual(len(readout.unreadable), 1)
        self.assertIn('chains a nested $? conditional', readout.unreadable[0])

    def test_durations_stacks_and_level_scaled_points_of_a_spell_without_an_ability_row(self):
        readout = self.read(OUTMANEUVER)
        self.assertEqual(displayed(readout, '$d'), Displayed('$d', OUTMANEUVER_DURATION_MS, None, 'duration_ms'))
        self.assertEqual(displayed(readout, '$u'), Displayed('$u', OUTMANEUVER_STACK_AMOUNT, None, 'count'))
        self.assertEqual(displayed(readout, '$557326d'),
                         Displayed('$557326d', OUTMANEUVER_DURATION_MS, None, 'duration_ms'))
        self.assertEqual(displayed(readout, '$s3'), Displayed('$s3', OUTMANEUVER_BASE_POINTS_3 + 1, 2, 'percent',
                                                               OUTMANEUVER))
        self.assertEqual(displayed(readout, '${$557328m1+$AP*.55}').value,
                         DECOY_STRIKE_BASE_POINTS + 1 + 0.55 * LEVEL_60_TEMPLAR.ap)
        self.assertEqual(readout.unreadable, [])

    def test_level_scaled_points_without_the_character_name_the_field_and_the_cause(self):
        readout = self.read(HOLY_CONSTITUTION)
        self.assertEqual(readout.values, [Displayed('$s2', HOLY_CONSTITUTION_BASE_POINTS_2 + 1, 1, 'percent',
                                                    HOLY_CONSTITUTION)])
        self.assertEqual(readout.unreadable, ['${$m1+0} [EffectRealPointsPerLevel[0] of spell 706323: the race and '
                                              'class of the character are unknown]'])

    def test_weapon_skill_table(self):
        records = Records(self.dbc)
        self.assertEqual(weapon_skill_spells(records)[STAFF_SUBCLASS], STAVES)
        self.assertEqual([ability.line for ability in records.abilities(STAVES)], [STAVES_LINE])

    def test_own_level_scaled_token(self):
        readout = self.read(DIVINE_FORCE, SKILLED_TEMPLAR)
        value = displayed(readout, '${$m3+0+$SP*1+$AP*.55}')
        self.assertEqual(value.value, DIVINE_FORCE_BASE_POINTS_3 + 1
                         + DIVINE_FORCE_PER_LEVEL_3 * (LEVEL_60_SKILL // 5 - DIVINE_FORCE_BASE_LEVEL) + 0.55 * 313)
        self.assertEqual((value.effect_index, value.spell_id), (2, DIVINE_FORCE))

    def test_unmeasured_skill_keeps_the_token_unreadable(self):
        readout = self.read(DIVINE_FORCE, replace(SKILLED_TEMPLAR, skills={}))
        self.assertEqual(readout.unreadable, ['${$m3+0+$SP*1+$AP*.55} [EffectRealPointsPerLevel[2] of spell 807805: '
                                              'skill 72 is not measured]'])

    def test_unknown_race_and_class_keep_the_token_unreadable(self):
        readout = self.read(DIVINE_FORCE, replace(SKILLED_TEMPLAR, race=None, class_id=None))
        self.assertEqual(readout.unreadable, ['${$m3+0+$SP*1+$AP*.55} [EffectRealPointsPerLevel[2] of spell 807805: '
                                              'the race and class of the character are unknown]'])

    def test_weapon_skill_path(self):
        token = '${$m1+0+$AP*0.175+$STA*0.5}'
        stamina = SKILLED_TEMPLAR.stats[2]
        with_staff = self.read(RECKONING, replace(SKILLED_TEMPLAR, weapon_subclass=STAFF_SUBCLASS))
        self.assertEqual(displayed(with_staff, token).value, RECKONING_BASE_POINTS + 1 + 0.175 * 313 + 0.5 * stamina)
        self.assertEqual(client_spell_level(Records(self.dbc), RECKONING,
                                            replace(SKILLED_TEMPLAR, weapon_subclass=STAFF_SUBCLASS)), 0)
        unarmed = self.read(RECKONING, SKILLED_TEMPLAR)
        self.assertEqual(displayed(unarmed, token).value,
                         RECKONING_BASE_POINTS + 1 + RECKONING_PER_LEVEL * (60 - RECKONING_BASE_LEVEL)
                         + 0.175 * 313 + 0.5 * stamina)

    def test_forced_roll_of_a_level_scaled_effect_adds_the_level_part(self):
        forced = ForcedPoints(self.dbc, RECKONING, 0, RECKONING_BASE_POINTS + 49)
        description = forced.field('Spell', RECKONING, 'Description[enUS]')
        readout = Tooltip(forced, RECKONING, SKILLED_TEMPLAR).read(description)
        self.assertEqual(displayed(readout, '${$m1+0+$AP*0.175+$STA*0.5}').value,
                         RECKONING_BASE_POINTS + 49 + RECKONING_PER_LEVEL * (60 - RECKONING_BASE_LEVEL) + 0.175 * 313)

    def test_foreign_level_scaled_spell_reads_its_own_rank(self):
        stamina = SKILLED_TEMPLAR.stats[2]
        staffguard = displayed(self.read(STAFFGUARD, SKILLED_TEMPLAR), f'${{${STAFFGUARD_HEALTH}m1+$STA*.3}}')
        self.assertEqual(staffguard.value, STAFFGUARD_HEALTH_BASE_POINTS + 1 + 0.3 * stamina)
        self.assertEqual(staffguard.spell_id, STAFFGUARD_HEALTH)
        untainted = displayed(self.read(UNTAINTED, SKILLED_TEMPLAR), f'${{-${UNTAINTED_EFFECT}m1+$STA*0.1}}')
        self.assertEqual(untainted.value, -(UNTAINTED_EFFECT_BASE_POINTS + 1) + 0.1 * stamina)

    def test_no_ability_row_means_rank_zero(self):
        readout = self.read(CHAKRA_OF_LIGHT, SKILLED_TEMPLAR)
        self.assertEqual(displayed(readout, '${$m1+$SP*0.35}').value, CHAKRA_OF_LIGHT_BASE_POINTS + 1)

    def test_ppl_resolves_to_the_per_level_points(self):
        readout = self.read(ARMOR_OF_FAITH, SKILLED_TEMPLAR)
        reading = displayed(readout, '${$801546m1+$801546ppl1+$AP*0.2+$sph*0.5}')
        flat = ARMOR_OF_FAITH_BASE_POINTS + 1
        scaled = flat + ARMOR_OF_FAITH_PER_LEVEL * (60 - ARMOR_OF_FAITH_BASE_LEVEL) + 0.2 * SKILLED_TEMPLAR.ap
        self.assertNotEqual(scaled, flat + 0.2 * SKILLED_TEMPLAR.ap)
        self.assertAlmostEqual(reading.value, scaled, places=4)
        self.assertEqual(readout.unreadable, [])

    def test_amplitude_tokens(self):
        tempest = self.read(RIGHTEOUS_TEMPEST, SKILLED_TEMPLAR)
        self.assertEqual(displayed(tempest, '$t1'),
                         Displayed('$t1', RIGHTEOUS_TEMPEST_PERIOD_MS, 0, 'amplitude_ms', RIGHTEOUS_TEMPEST))
        self.assertNotIn('$t1', tempest.unreadable)
        blade = Tooltip(Records(self.dbc), BLADE_OF_FAITH, SKILLED_TEMPLAR)
        self.assertEqual(blade.evaluate('$T1'), (BLADE_OF_FAITH_PERIOD_MS, None, None))
        points = (BLADE_OF_FAITH_BASE_POINTS + 1
                  + BLADE_OF_FAITH_PER_LEVEL * (LEVEL_60_SKILL // 5 - BLADE_OF_FAITH_BASE_LEVEL))
        ticks = BLADE_OF_FAITH_DURATION_S * 1000 / BLADE_OF_FAITH_PERIOD_MS
        total = displayed(self.read(BLADE_OF_FAITH, SKILLED_TEMPLAR), BLADE_OF_FAITH_TOTAL)
        self.assertEqual((total.effect_index, total.kind, total.spell_id), (0, 'flat', BLADE_OF_FAITH))
        self.assertAlmostEqual(total.value, ticks * (points + 0.1 * SKILLED_TEMPLAR.ap), places=9)

    def test_radius(self):
        readout = self.read(VEILED_IN_DARKNESS)
        self.assertEqual(displayed(readout, '$a1'),
                         Displayed('$a1', VEILED_IN_DARKNESS_RADIUS_YARDS, 0, 'radius_yards', VEILED_IN_DARKNESS))
        self.assertEqual(readout.unreadable, [])

    def test_foreign_value_token_names_its_spell(self):
        token = displayed(self.read(SCOURGEBANE_PASSIVE), '$801832s2')
        self.assertEqual((token.spell_id, token.effect_index), (SCOURGEBANE_STRIKE, None))
        expression = displayed(self.read(SCOURGEBANE_PASSIVE), '${$801832m1*$<scalingbp>+$SP*.25+$AP*.25}')
        self.assertEqual((expression.spell_id, expression.effect_index), (SCOURGEBANE_STRIKE, None))

    def test_tokens_without_an_effect_name_no_spell(self):
        readout = self.read(SCOURGEBANE_PASSIVE)
        self.assertIsNone(displayed(readout, '$520007h').spell_id)

    def test_uppercase_s(self):
        tooltip = Tooltip(Records(self.dbc), HOLY_LIGHT, LEVEL_60_TEMPLAR)
        upper, lower = tooltip.read('$/1000;S1 sec and $/1000;s1 sec').values
        self.assertEqual((upper.text, lower.text), ('$/1000;S1', '$/1000;s1'))
        self.assertEqual((upper.value, upper.effect_index, upper.kind, upper.spell_id),
                         (lower.value, lower.effect_index, lower.kind, lower.spell_id))
        self.assertEqual(upper.value, HOLY_LIGHT_CAST_TIME_POINTS)
        self.assertEqual(self.read(HOLY_LIGHT).unreadable, [])

    def test_spell_markup_expands(self):
        readout = self.read(ZEALOTRY_PASSIVE)
        self.assertEqual(readout.values, [Displayed('$s2', ZEALOTRY_WEAPON_BASE_POINTS + 1, None, 'percent',
                                                    ZEALOTRY)])
        self.assertEqual(readout.unreadable, [])

    def test_expanded_tokens_name_the_referenced_spell_after_the_own_tokens(self):
        readout = self.read(GLORY)
        self.assertEqual([(value.text, value.effect_index, value.spell_id) for value in readout.values], [
            ('$s1', 0, GLORY), ('$d', None, None),
            ('$s1', None, DOWNFALL), ('$d', None, DOWNFALL),
            ('$s1', None, REDEMPTION), ('$s3', None, REDEMPTION), ('$d', None, REDEMPTION)])
        self.assertEqual(readout.values[3].value, DOWNFALL_DURATION_MS)
        self.assertEqual(readout.unreadable, [])

    def test_until_cancelled_duration_is_unreadable(self):
        records = Records(self.dbc)
        description = records.dbc_field('Spell', SCOURGEBANE_STRIKE, 'Description[enUS]')
        self.assertIn('over $d', description)
        readout = Tooltip(records, SCOURGEBANE_STRIKE, LEVEL_60_TEMPLAR).read(description)
        self.assertEqual(readout.unreadable, ['$d'])
        self.assertEqual(displayed(readout, '$i'), Displayed('$i', 0, None, 'count'))


SPELL_RECORD_BYTES = 936
SMALL_RECORD_BYTES = 16


def wdbc(rows, fields, size, strings):
    return struct.pack('<4s4I', b'WDBC', len(rows), fields, size, len(strings)) + b''.join(rows) + strings


class StringBlock:
    def __init__(self):
        self.data = b'\0'

    def add(self, text):
        offset = len(self.data)
        self.data += text.encode() + b'\0'
        return offset


def write_fixture(directory: Path, spells: dict[int, dict], variables: dict[int, str]):
    offsets = {column.name: column.offset for column in schemas.registry()['Spell'].columns}
    strings = StringBlock()
    rows = []
    for spell_id, fields in spells.items():
        row = bytearray(SPELL_RECORD_BYTES)
        struct.pack_into('<I', row, offsets['Id'], spell_id)
        for name, value in fields.items():
            if name == 'Description[enUS]':
                struct.pack_into('<I', row, offsets[name], strings.add(value))
            elif name.startswith('EffectRealPointsPerLevel'):
                struct.pack_into('<f', row, offsets[name], value)
            else:
                struct.pack_into('<i', row, offsets[name], value)
        rows.append(bytes(row))
    (directory / 'Spell.dbc').write_bytes(wdbc(rows, 234, SPELL_RECORD_BYTES, strings.data))
    durations = [struct.pack('<4i', 1, 6000, 0, 6000), struct.pack('<4i', 2, 1000, 100, 9000)]
    (directory / 'SpellDuration.dbc').write_bytes(wdbc(durations, 4, SMALL_RECORD_BYTES, b'\0'))
    radii = [struct.pack('<I3f', 7, 8.0, 0.0, 8.0)]
    (directory / 'SpellRadius.dbc').write_bytes(wdbc(radii, 4, SMALL_RECORD_BYTES, b'\0'))
    variable_strings = StringBlock()
    variable_rows = [struct.pack('<2I', identity, variable_strings.add(text)) for identity, text in variables.items()]
    (directory / 'SpellDescriptionVariables.dbc').write_bytes(wdbc(variable_rows, 2, 8, variable_strings.data))
    (directory / 'SkillLineAbility.dbc').write_bytes(wdbc([], 14, 56, b'\0'))


FIXTURE_SPELLS = {
    10: {'Description[enUS]': 'Strikes for ${$m1+$SP*0.5+$STA*2}, then $s2% of it over $d to $i targets within $a1 '
                              'yds, up to $u stacks, $h% chance; |cff00ff00$<bonus>|r and $M1 more.',
         'EffectBasePoints[0]': 99, 'EffectDieSides[0]': 1, 'EffectBasePoints[1]': 24, 'EffectDieSides[1]': 1,
         'EffectRadiusIndex[0]': 7, 'DurationIndex': 1, 'MaxAffectedTargets': 3, 'StackAmount': 5,
         'ProcChance': 35, 'SpellDescriptionVariableID': 1},
    11: {'Description[enUS]': 'Grows by $s1 per level for $d.', 'EffectBasePoints[0]': 9, 'EffectDieSides[0]': 1,
         'EffectRealPointsPerLevel[0]': 1.5, 'DurationIndex': 2},
    12: {'Description[enUS]': 'Hits for $s1 and ${$s1*2}, ${$AP^2}, ${$ap*2}, ${$BH*1}, $t1 sec, $lpoint:points; '
                              '|TInterface\\Icons\\X:0|t @ext:Scales with Spirit:ext@ and $<odd> with $<missing>.',
         'EffectBasePoints[0]': 4, 'EffectDieSides[0]': 3, 'SpellDescriptionVariableID': 2},
    13: {'Description[enUS]': 'Echo of $10s2%, $10m1 and $99d.'},
    14: {'Description[enUS]': 'Shown with shift only.@s:801450:-4@'},
    15: {'Description[enUS]': 'Names a missing spell.@s:404:0@'},
    20: {'Description[enUS]': 'Opens with $s1.@s:21:0@', 'EffectBasePoints[0]': 1, 'EffectDieSides[0]': 1},
    21: {'Description[enUS]': 'Echoes $s1 and $d.@s:20:0@', 'EffectBasePoints[0]': 2, 'EffectDieSides[0]': 1,
         'DurationIndex': 1},
    30: {'Description[enUS]': '@s:31:0@'},
    31: {'Description[enUS]': '@s:32:0@'},
    32: {'Description[enUS]': '@s:33:0@'},
    33: {'Description[enUS]': 'Deep $s1.@s:34:0@', 'EffectBasePoints[0]': 32, 'EffectDieSides[0]': 1},
    34: {'Description[enUS]': 'Too deep $s1.', 'EffectBasePoints[0]': 33, 'EffectDieSides[0]': 1},
    801450: {'Description[enUS]': 'Deals $s2%.', 'EffectBasePoints[1]': 79, 'EffectDieSides[1]': 1},
    40: {'Description[enUS]': 'Every $t2 sec for ${$d*1000/$T2} ticks.', 'EffectAmplitude[1]': 2000,
         'DurationIndex': 1},
    41: {'Description[enUS]': 'Every $t1 sec, ${$T1}.', 'EffectAmplitude[0]': 2000, 'ProcFlags': 1},
    42: {'Description[enUS]': 'Every $t1 sec, ${$T1}.', 'EffectAmplitude[0]': 2000, 'AttributesEx5': 0x2000},
    43: {'Description[enUS]': 'Acts over a $/1000;s1 sec shorter period.', 'Effect[0]': 6,
         'EffectApplyAuraName[0]': 107, 'EffectAmplitude[0]': 1500, 'EffectBasePoints[0]': -1001,
         'EffectDieSides[0]': 1},
    44: {'Description[enUS]': 'Burns for $/1000;s1 sec, every $t1 sec.', 'Effect[0]': 6, 'EffectApplyAuraName[0]': 3,
         'EffectAmplitude[0]': 1000, 'EffectBasePoints[0]': 1999, 'EffectDieSides[0]': 1, 'DurationIndex': 1},
    45: {'Description[enUS]': 'Every $t1 sec.', 'EffectAmplitude[0]': 2000, 'AttributesEx5': 0x2000,
         'AttributesEx3': 0x20000000},
    50: {'Description[enUS]': 'Scales by ${$50m1+$50ppl1}.', 'EffectBasePoints[0]': 10, 'EffectDieSides[0]': 1,
         'EffectRealPointsPerLevel[0]': 2.0, 'BaseLevel': 10},
    60: {'Description[enUS]': 'Cross-spell ${$61m1*$<scalingbp>}.'},
    61: {'Description[enUS]': 'Unused directly.', 'EffectBasePoints[0]': 5, 'EffectDieSides[0]': 1,
         'SpellDescriptionVariableID': 3},
    70: {'Description[enUS]': 'Base $s1$?s71[ plus $71s1 bonus][].', 'EffectBasePoints[0]': 4, 'EffectDieSides[0]': 1},
    71: {'Description[enUS]': 'Bonus source.', 'EffectBasePoints[0]': 6, 'EffectDieSides[0]': 1},
    72: {'Description[enUS]': 'Broken $?s71[no closing.'},
    73: {'Description[enUS]': 'Chance $h1, lasts $d1, stacks $u1, hits $i1 targets.', 'ProcChance': 40,
         'DurationIndex': 1, 'StackAmount': 6, 'MaxAffectedTargets': 2},
    74: {'Description[enUS]': 'Restores $o1 over $d.', 'EffectBasePoints[0]': 9, 'EffectDieSides[0]': 1,
         'EffectAmplitude[0]': 1000, 'DurationIndex': 1},
    75: {'Description[enUS]': 'Restores $O1 over $d.', 'EffectBasePoints[0]': 9, 'EffectDieSides[0]': 1,
         'EffectAmplitude[0]': 1000, 'DurationIndex': 1, 'AttributesEx5': 0x200},
    76: {'Description[enUS]': 'Restores $o1 over $d.', 'EffectBasePoints[0]': 9, 'EffectDieSides[0]': 1,
         'DurationIndex': 1},
}
FIXTURE_VARIABLES = {
    1: '$bonus=${$m1*2+$PL}\r\n',
    2: '$odd=$?s100[${1}][${2}]\r\n',
    3: '$scalingbp=${1+$PL*0}\r\n',
}
FIXTURE_CASTER = CasterStats(level=60, ap=200.0, rap=0.0,
                             sp_by_school={0: 0.0, HOLY: 40.0, FIRE: 30.0, NATURE: 50.0, FROST: 60.0, SHADOW: 70.0,
                                           ARCANE: 80.0},
                             stats={0: 10.0, 1: 20.0, 2: 15.0, 3: 30.0, 4: 40.0})


class FixtureTooltipTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        directory = Path(self.temp.name)
        write_fixture(directory, FIXTURE_SPELLS, FIXTURE_VARIABLES)
        self.dbc = DataSet(directory)

    def tearDown(self):
        self.temp.cleanup()

    def test_every_listed_token_is_read_from_the_records(self):
        readout = read_tooltip(self.dbc, 10, FIXTURE_CASTER)
        self.assertEqual(readout.values, [
            Displayed('${$m1+$SP*0.5+$STA*2}', 100 + 30 * 0.5 + 15 * 2, 0, 'flat', 10),
            Displayed('$s2', 25, 1, 'percent', 10),
            Displayed('$d', 6000, None, 'duration_ms'),
            Displayed('$i', 3, None, 'count'),
            Displayed('$a1', 8.0, 0, 'radius_yards', 10),
            Displayed('$u', 5, None, 'count'),
            Displayed('$h', 35, None, 'chance_pct'),
            Displayed('$<bonus>', 100 * 2 + 60, 0, 'flat', 10),
            Displayed('$M1', 100, 0, 'flat', 10),
        ])
        self.assertEqual(readout.unreadable, [])

    def test_level_scaled_points_without_an_ability_row_read_rank_zero_and_scaled_durations_stay_unreadable(self):
        readout = read_tooltip(self.dbc, 11, FIXTURE_CASTER)
        self.assertEqual(readout.values, [Displayed('$s1', 10, 0, 'flat', 11)])
        self.assertEqual(readout.unreadable, ['$d [DurationPerLevel of spell 11]'])

    def test_unsupported_patterns_are_reported_verbatim(self):
        readout = read_tooltip(self.dbc, 12, FIXTURE_CASTER)
        self.assertEqual(readout.values, [])
        self.assertEqual(readout.unreadable, [
            '$s1', '${$s1*2}', '${$AP^2}', '${$ap*2}', '${$BH*1}', '$t1 [EffectAmplitude[0] 0 of spell 12]',
            '$lpoint:points;',
            '|TInterface\\Icons\\X:0|t', '@ext:Scales with Spirit:ext@', '$<odd>', '$<missing>'])

    def test_amplitude_of_the_named_effect_in_text_and_in_expressions(self):
        readout = read_tooltip(self.dbc, 40, FIXTURE_CASTER)
        self.assertEqual(readout.values, [Displayed('$t2', 2000, 1, 'amplitude_ms', 40),
                                          Displayed('${$d*1000/$T2}', 3, None, 'flat')])

    def test_the_first_proc_flag_reads_a_five_second_period(self):
        readout = read_tooltip(self.dbc, 41, FIXTURE_CASTER)
        self.assertEqual([value.value for value in readout.values], [5000, 5000])

    def test_only_the_shown_period_the_client_hastes_is_unreadable(self):
        readout = read_tooltip(self.dbc, 42, FIXTURE_CASTER)
        self.assertEqual(readout.values, [Displayed('${$T1}', 2000, None, 'flat')])
        self.assertEqual(readout.unreadable, ['$t1 [AttributesEx5 0x2000 of spell 42: the client hastes the shown '
                                              'period by the cast speed, which is not measured]'])

    def test_the_haste_exemption_keeps_the_shown_period_readable(self):
        readout = read_tooltip(self.dbc, 45, FIXTURE_CASTER)
        self.assertEqual(readout.values, [Displayed('$t1', 2000, 0, 'amplitude_ms', 45)])

    def test_a_token_read_with_its_following_text_is_one_tick(self):
        readout = read_tooltip(self.dbc, 44, FIXTURE_CASTER)
        seconds = readout.values[0]
        self.assertEqual(seconds, Displayed('$/1000;s1', 2000, 0, 'duration_ms', 44))
        self.assertEqual(period_reading(Records(self.dbc), 44, FIXTURE_CASTER, seconds, 0), PER_TICK)

    def test_references_to_other_spells_have_no_effect_index(self):
        readout = read_tooltip(self.dbc, 13, FIXTURE_CASTER)
        self.assertEqual(readout.values, [Displayed('$10s2', 25, None, 'percent', 10),
                                          Displayed('$10m1', 100, None, 'flat', 10)])
        self.assertEqual(readout.unreadable, ['$99d'])

    def test_negative_flags_stay_unreadable(self):
        readout = read_tooltip(self.dbc, 14, FIXTURE_CASTER)
        self.assertEqual(readout.values, [])
        self.assertEqual(readout.unreadable, ['@s:801450:-4@ [negative flags select a shift or partial rendering]'])

    def test_markup_naming_a_missing_spell_is_unreadable(self):
        readout = read_tooltip(self.dbc, 15, FIXTURE_CASTER)
        self.assertEqual(readout.unreadable, ['@s:404:0@ [spell 404 is not in Spell.dbc]'])

    def test_expansion_cycle(self):
        readout = read_tooltip(self.dbc, 20, FIXTURE_CASTER)
        self.assertEqual(readout.values, [Displayed('$s1', 2, 0, 'flat', 20), Displayed('$s1', 3, None, 'flat', 21),
                                          Displayed('$d', 6000, None, 'duration_ms', 21)])
        self.assertEqual(readout.unreadable, ['@s:20:0@ [expansion cycle 20 -> 21 -> 20]'])

    def test_expansion_deeper_than_the_limit_is_unreadable(self):
        self.assertEqual(MAX_EXPANSION_DEPTH, 3)
        readout = read_tooltip(self.dbc, 30, FIXTURE_CASTER)
        self.assertEqual(readout.values, [Displayed('$s1', 33, None, 'flat', 33)])
        self.assertEqual(readout.unreadable, ['@s:34:0@ [nesting deeper than 3 expansions]'])

    def test_conditional_false_branch_is_empty_and_contributes_nothing(self):
        readout = read_tooltip(self.dbc, 70, FIXTURE_CASTER)
        self.assertEqual(readout.values, [Displayed('$s1', 5, 0, 'flat', 70)])
        self.assertEqual(readout.unreadable, [])

    def test_conditional_true_branch_is_read_as_a_normal_token(self):
        caster = replace(FIXTURE_CASTER, known_spells=frozenset({71}))
        readout = read_tooltip(self.dbc, 70, caster)
        self.assertEqual(readout.values, [Displayed('$s1', 5, 0, 'flat', 70),
                                          Displayed('$71s1', 7, None, 'flat', 71)])
        self.assertEqual(readout.unreadable, [])

    def test_malformed_conditional_is_unreadable(self):
        readout = read_tooltip(self.dbc, 72, FIXTURE_CASTER)
        self.assertEqual(readout.values, [])
        self.assertEqual(readout.unreadable, ['$?s71[no closing. [malformed $? conditional]'])

    def test_trailing_digit_on_h_d_u_i_is_accepted_and_ignored(self):
        readout = read_tooltip(self.dbc, 73, FIXTURE_CASTER)
        self.assertEqual(readout.values, [
            Displayed('$h1', 40, None, 'chance_pct'),
            Displayed('$d1', 6000, None, 'duration_ms'),
            Displayed('$u1', 6, None, 'count'),
            Displayed('$i1', 2, None, 'count'),
        ])
        self.assertEqual(readout.unreadable, [])

    def test_periodic_total_token_scales_points_by_the_duration_over_the_period(self):
        readout = read_tooltip(self.dbc, 74, FIXTURE_CASTER)
        self.assertEqual(readout.values[0], Displayed('$o1', 60.0, 0, 'flat', 74))

    def test_periodic_total_token_adds_one_period_when_the_aura_starts_ticking_at_apply(self):
        readout = read_tooltip(self.dbc, 75, FIXTURE_CASTER)
        self.assertEqual(readout.values[0], Displayed('$O1', 70.0, 0, 'flat', 75))

    def test_periodic_total_token_defaults_the_period_to_five_seconds(self):
        readout = read_tooltip(self.dbc, 76, FIXTURE_CASTER)
        self.assertEqual(readout.values[0], Displayed('$o1', 12.0, 0, 'flat', 76))

    def test_unknown_spell_is_rejected(self):
        with self.assertRaises(ValueError):
            read_tooltip(self.dbc, 404, FIXTURE_CASTER)

    def test_ppl_token_adds_the_per_level_term_an_absent_one_would_miss(self):
        readout = read_tooltip(self.dbc, 50, FIXTURE_CASTER)
        flat = 10 + 1
        scaled = flat + 2.0 * (FIXTURE_CASTER.level - 10)
        self.assertNotEqual(scaled, flat)
        self.assertEqual(readout.values, [Displayed('${$50m1+$50ppl1}', scaled, 0, 'flat', 50)])
        self.assertEqual(readout.unreadable, [])

    def test_named_variable_resolves_against_the_spell_that_defines_it(self):
        readout = read_tooltip(self.dbc, 60, FIXTURE_CASTER)
        self.assertEqual(readout.values, [Displayed('${$61m1*$<scalingbp>}', 6.0, None, 'flat', 61)])
        self.assertEqual(readout.unreadable, [])


class StreamedTextTests(unittest.TestCase):
    def updates(self, files: dict[str, str]) -> Path:
        root = Path(tempfile.mkdtemp())
        for name, text in files.items():
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding='utf-8')
        return root

    def test_rows_replay_their_deletes_and_inserts_in_file_order(self):
        root = self.updates({
            'db_world/a.sql': "INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES "
                              "(1, 'old', 'tip'), (2, CONCAT('Deals ', 'it''s\\r\\nfine'), NULL);",
            'pending_db_world/b.sql': "-- note\nDELETE FROM `coa_client_spell_description` WHERE `ID` IN (1, 3);\n"
                                      "INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES "
                                      "(3,'new; kept');",
            'pending_db_world/c.sql': "DELETE FROM `coa_client_spell_description` WHERE `ID` = 9;"})
        texts = streamed_texts(root)
        self.assertEqual(sorted(texts), [2, 3])
        self.assertEqual((texts[2].description, texts[2].tooltip, texts[2].file), ("Deals it's\r\nfine", None, 'a.sql'))
        self.assertEqual((texts[3].description, texts[3].tooltip), ('new; kept', None))

    def test_an_empty_description_blanks_the_text_and_an_empty_tooltip_keeps_the_client_one(self):
        root = self.updates({'pending_db_world/a.sql': "INSERT INTO `coa_client_spell_description` "
                                                       "(`ID`, `Description`, `ToolTip`) VALUES (5, '', '');"})
        self.assertEqual(streamed_field(5, 'Description[enUS]', root), '')
        self.assertIsNone(streamed_field(5, 'ToolTip[enUS]', root))
        self.assertIsNone(streamed_field(6, 'Description[enUS]', root))
        self.assertIsNone(streamed_field(5, 'SpellName[enUS]', root))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
    def test_the_reader_prefers_the_streamed_text_and_keeps_the_client_one(self):
        records = Records(DataSet(DBC_DIR))
        self.assertIn('${-$705299m1+$STA*0.1}', records.field('Spell', UNTAINTED, 'Description[enUS]'))
        self.assertIn('${$705299m1+$STA*0.1}', records.dbc_field('Spell', UNTAINTED, 'Description[enUS]'))
        self.assertEqual(records.field('Spell', UNTAINTED_EFFECT, 'ToolTip[enUS]'),
                         'Physical damage taken reduced by ${-$m1+$STA*0.1}.')
        self.assertEqual(records.field('Spell', UNTAINTED, 'ToolTip[enUS]'),
                         records.dbc_field('Spell', UNTAINTED, 'ToolTip[enUS]'))


if __name__ == '__main__':
    unittest.main()
