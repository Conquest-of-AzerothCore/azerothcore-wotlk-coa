from pathlib import Path
import unittest

from tooltip import CasterStats, Displayed, Readout
from tooltip_readings import TooltipReading, checked_tooltip_reading, player_tooltip_readings, reading_band, \
    reading_caster, reading_for

WELL_FORMED = {'spell': 801441, 'token': '${$804148m1+$804148ppl1}', 'value': 188, 'ap': 916, 'sp': [],
              'citation': 'player report 2026-11-07'}


class CheckedTooltipReadingTest(unittest.TestCase):
    def test_accepts_well_formed_entry(self):
        self.assertEqual(checked_tooltip_reading(dict(WELL_FORMED)), WELL_FORMED)

    def test_rejects_missing_field(self):
        entry = {key: value for key, value in WELL_FORMED.items() if key != 'ap'}
        with self.assertRaises(ValueError):
            checked_tooltip_reading(entry)

    def test_rejects_citation_without_the_player_report_prefix(self):
        entry = {**WELL_FORMED, 'citation': '2026-11-07 player report'}
        with self.assertRaises(ValueError):
            checked_tooltip_reading(entry)

    def test_rejects_citation_naming_a_person(self):
        entry = {**WELL_FORMED, 'citation': 'Someone report 2026-11-07'}
        with self.assertRaises(ValueError):
            checked_tooltip_reading(entry)


class PlayerTooltipReadingsTest(unittest.TestCase):
    def test_reads_well_formed_entries_from_the_class_file(self):
        class_file = {'player_tooltip_readings': [WELL_FORMED]}
        self.assertEqual(player_tooltip_readings(class_file),
                         [TooltipReading(**{**WELL_FORMED, 'sp': ()})])

    def test_defaults_to_empty_when_the_class_file_has_no_entries(self):
        self.assertEqual(player_tooltip_readings({}), [])

    def test_raises_on_a_malformed_entry_instead_of_silently_dropping_it(self):
        class_file = {'player_tooltip_readings': [{**WELL_FORMED, 'citation': 'not a citation'}]}
        with self.assertRaises(ValueError):
            player_tooltip_readings(class_file)

    def test_a_note_is_optional_and_defaults_to_empty(self):
        reading, = player_tooltip_readings({'player_tooltip_readings': [WELL_FORMED]})
        self.assertEqual(reading.note, '')


class ReadingForTest(unittest.TestCase):
    def test_matches_by_spell_and_token(self):
        reading = TooltipReading(**{**WELL_FORMED, 'sp': ()})
        self.assertIs(reading_for([reading], 801441, WELL_FORMED['token']), reading)

    def test_no_match_returns_none(self):
        reading = TooltipReading(**{**WELL_FORMED, 'sp': ()})
        self.assertIsNone(reading_for([reading], 801441, '${other}'))
        self.assertIsNone(reading_for([reading], 1, WELL_FORMED['token']))


class ReadingCasterTest(unittest.TestCase):
    def test_builds_a_level_60_caster_at_the_readings_ap_and_sp(self):
        reading = TooltipReading(**{**WELL_FORMED, 'ap': 916.0, 'sp': ()})
        caster = reading_caster(reading, 493.0)
        self.assertEqual((caster.level, caster.ap, caster.rap), (60, 916.0, 916.0))
        self.assertTrue(all(value == 493.0 for value in caster.sp_by_school.values()))


class FakeTooltips:
    def __init__(self, values):
        self.values = values

    def read(self, spell_id: int, caster: CasterStats) -> Readout:
        return Readout([value for value in self.values if value.spell_id in (None, spell_id)], [])


class ReadingBandTest(unittest.TestCase):
    def test_single_sp_value_gives_a_single_point_band(self):
        reading = TooltipReading(spell=1, token='$s1', value=10, ap=100, sp=(50,),
                                 citation='player report 2026-11-07')
        tooltips = FakeTooltips([Displayed('$s1', 42.0, 0, 'flat', 1)])
        self.assertEqual(reading_band(tooltips, reading), (42.0, 42.0))

    def test_two_sp_values_give_the_low_high_band(self):
        reading = TooltipReading(spell=1, token='$s1', value=10, ap=100, sp=(50, 100),
                                 citation='player report 2026-11-07')
        read_count = iter([30.0, 60.0])
        tooltips = FakeTooltips([])
        tooltips.read = lambda spell_id, caster: Readout([Displayed('$s1', next(read_count), 0, 'flat', 1)], [])
        self.assertEqual(reading_band(tooltips, reading), (30.0, 60.0))

    def test_no_sp_terms_fall_back_to_a_single_reading(self):
        reading = TooltipReading(spell=1, token='$s1', value=10, ap=100, sp=(), citation='player report 2026-11-07')
        tooltips = FakeTooltips([Displayed('$s1', 11.0, 0, 'flat', 1)])
        self.assertEqual(reading_band(tooltips, reading), (11.0, 11.0))

    def test_a_token_the_reread_does_not_show_raises(self):
        reading = TooltipReading(spell=1, token='$s1', value=10, ap=100, sp=(50,),
                                 citation='player report 2026-11-07')
        tooltips = FakeTooltips([Displayed('$s2', 11.0, 0, 'flat', 1)])
        with self.assertRaises(ValueError):
            reading_band(tooltips, reading)


if __name__ == '__main__':
    unittest.main()
