import json
from pathlib import Path
import tempfile
import unittest

from coverage import clause_coverage, load_clauses
from ledger import (ACQUISITION_REASON, EMPTY_CLAUSE, EMPTY_REASON, LEVEL_REASON, clause_words, differs_text, ledger,
                    no_claim_reason, parse_text_bases, pulled_clauses, raw_clauses, write_ledger)
from profile import DBC_DIR, FIXTURE_CLASSES_DIR, load_fixture_class_file
from streamed import streamed_texts
from tooltip import Records
from values import dataset

TEMPLAR = 19
NECROMANCER = 23
DEPRAVITY = 638403
GHOUL_FRENZY = 503740
FRENZIED_GHOUL = 707014
TUNDRA_WARRIORS_TALENT = 92122
TEMPLAR_LEDGER = FIXTURE_CLASSES_DIR / 'templar_clauses.json'
NECROMANCER_LEDGER = FIXTURE_CLASSES_DIR / 'necromancer_clauses.json'
OWNER_RULING_NO_CLAIM = 805410
LEVEL_LINE = '|cFF66DDFFLevel 10 Passive|r\r\n'


def clauses(text: str) -> list[str]:
    return [clause_words(raw) for raw in raw_clauses(text)]


def templar_bases(hand: list[dict]) -> dict[int, str]:
    by_file = {entry['text_source']['file']: entry['text_source']['basis'] for entry in hand if 'text_source' in entry}
    return {spell: by_file[row.file] for spell, row in streamed_texts().items() if row.file in by_file}


class ClauseSplitTests(unittest.TestCase):
    def test_a_sentence_is_cut_where_each_part_states_a_value(self):
        self.assertEqual(
            clauses('Meditate for $d, restoring $s1% of your maximum health every $T1 sec and reducing damage taken '
                    'by $s2%.'),
            ['Meditate for $d,', 'restoring $s1% of your maximum health every $T1 sec',
             'and reducing damage taken by $s2%.'])

    def test_a_part_without_a_value_stays_with_its_neighbour(self):
        self.assertEqual(clauses('Increases the damage and reduces the Energy cost of Lunge and Blade by $s1%.'),
                         ['Increases the damage and reduces the Energy cost of Lunge and Blade by $s1%.'])

    def test_a_cut_after_a_function_word_is_refused(self):
        self.assertEqual(
            clauses("Periodic damage dealt now has a $h% chance to increase your and your Undead minion's haste by "
                    "$301334s1% for $301334d."),
            ["Periodic damage dealt now has a $h% chance to increase your and your Undead minion's haste by "
             "$301334s1% for $301334d."])

    def test_lines_and_sentences_are_separate_clauses_without_colour_codes(self):
        self.assertEqual(
            clauses(LEVEL_LINE + 'Increases the damage of |cffffffffBlade|r by $s1%. Does not stack with similar '
                                 'effects.\r\n\r\nIn addition, lasts $d.'),
            ['Level 10 Passive', 'Increases the damage of Blade by $s1%.', 'Does not stack with similar effects.',
             'In addition, lasts $d.'])

    def test_spell_markup_joins_the_clause_before_it_and_is_not_shown(self):
        raws = raw_clauses('Your attacks now trigger |cFFFFFFFFZealotry|r.@s:801450:0@')
        self.assertEqual(raws, ['Your attacks now trigger |cFFFFFFFFZealotry|r.@s:801450:0@'])
        self.assertEqual(clause_words(raws[0]), 'Your attacks now trigger Zealotry.')

    def test_a_conditional_and_an_extension_note_are_never_cut_inside(self):
        self.assertEqual(
            clauses('Call down boulders, dealing ${$m1+0+$spfr*1.405} Frost damage.$?s560852[\r\n\r\nThis spell is '
                    'guaranteed to critically strike.][]\r\n\r\n@ext:Damage scales, and grows. :ext@'),
            ['Call down boulders, dealing ${$m1+0+$spfr*1.405} Frost damage.',
             '$?s560852[\r\n\r\nThis spell is guaranteed to critically strike.][]',
             '@ext:Damage scales, and grows. :ext@'])

    def test_the_pieces_cover_the_whole_tooltip(self):
        text = LEVEL_LINE + 'Brand an enemy for $d, preventing them from mounting.@s:102208:0@\r\n\r\nLasts $d.'
        self.assertEqual(''.join(raw_clauses(text)), text)


class NoClaimTests(unittest.TestCase):
    def test_level_label_lines(self):
        self.assertEqual(no_claim_reason('Level 10 Passive'), LEVEL_REASON)
        self.assertIsNone(no_claim_reason('Level 10 enemies take $s1% more damage.'))

    def test_acquisition_note(self):
        self.assertEqual(no_claim_reason('@ext:Eastern Kingdoms: Northshire Abbey.|n|nKalimdor: Moonglade.:ext@'),
                         ACQUISITION_REASON)
        self.assertIsNone(no_claim_reason('@ext:Periodic damage dealt by this can critically strike.:ext@'))

    def test_empty_tooltip(self):
        self.assertEqual(no_claim_reason(''), EMPTY_REASON)

    def test_text_bases(self):
        self.assertEqual(parse_text_bases(['638403=text_correction']), {638403: 'text_correction'})
        for items in (['638403'], ['spell=owner_ruling'], ['1=owner_ruling', '1=live_source']):
            with self.subTest(items=items), self.assertRaises(ValueError):
                parse_text_bases(items)

    def test_differing_fields(self):
        self.assertEqual(differs_text([]), 'no field differs from Spell.dbc')
        self.assertEqual(differs_text(['Description']), 'Description differs from Spell.dbc')
        self.assertEqual(differs_text(['Description', 'ToolTip']), 'Description and ToolTip differ from Spell.dbc')


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ClassLedgerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.hand = json.loads(TEMPLAR_LEDGER.read_text(encoding='utf-8'))
        cls.templar = ledger(load_fixture_class_file(TEMPLAR), DBC_DIR, templar_bases(cls.hand)).entries
        necromancer_hand = json.loads(NECROMANCER_LEDGER.read_text(encoding='utf-8'))
        cls.necromancer = ledger(load_fixture_class_file(NECROMANCER), DBC_DIR, templar_bases(necromancer_hand))

    def test_templar_no_claim_rows_of_the_generation_rules_are_reproduced(self):
        reasons = {LEVEL_REASON: 'level', EMPTY_REASON: 'empty', ACQUISITION_REASON: 'acquisition'}
        generated = {(entry['spell'], reasons[entry['reason']]) for entry in self.templar
                     if entry['kind'] == 'no_claim'}
        hand = {(entry['spell'], 'empty' if entry['clause'] == EMPTY_CLAUSE
                 else 'acquisition' if entry['clause'].startswith('@ext:') else 'level')
                for entry in self.hand if entry['kind'] == 'no_claim' and entry['spell'] != OWNER_RULING_NO_CLAIM}
        self.assertEqual(len(hand), 16)
        self.assertLessEqual(hand, generated)

    def test_templar_level_labels_keep_the_exact_words(self):
        hand = {(entry['spell'], entry['clause']) for entry in self.hand
                if entry['kind'] == 'no_claim' and entry['clause'].startswith('Level ')}
        generated = {(entry['spell'], entry['clause']) for entry in self.templar if entry['kind'] == 'no_claim'}
        self.assertLessEqual(hand, generated)

    def test_streamed_spells_carry_their_text_source(self):
        streamed = set(streamed_texts())
        for entry in self.templar + self.necromancer.entries:
            with self.subTest(spell=entry['spell'], clause=entry['clause']):
                self.assertEqual('text_source' in entry, entry['spell'] in streamed)
        depravity = [entry for entry in self.necromancer.entries if entry['spell'] == DEPRAVITY]
        self.assertTrue(depravity)
        self.assertEqual({entry['text_source']['basis'] for entry in depravity}, {'text_correction'})
        self.assertTrue(any('dbc_clause' in entry for entry in depravity))

    def test_a_streamed_spell_without_a_basis_is_refused(self):
        with self.assertRaises(ValueError):
            ledger(load_fixture_class_file(NECROMANCER), DBC_DIR, {})

    def test_the_written_ledger_loads_and_runs_through_coverage(self):
        for entries in (self.templar, self.necromancer.entries):
            with tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / 'clauses.json'
                write_ledger(entries, path)
                loaded = load_clauses(path)
                self.assertEqual(loaded, entries)
                result = clause_coverage(loaded, [])
                self.assertEqual(result.total, sum(entry['kind'] == 'claim' for entry in entries))

    def rows(self, spell: int) -> dict[str, list[str]]:
        return {entry['clause']: entry['labels'] for entry in self.necromancer.entries if entry['spell'] == spell}

    def test_a_pulled_sentence_joins_the_parent_tooltip_with_its_tokens(self):
        self.assertEqual(self.rows(GHOUL_FRENZY), {
            'Damage dealt by your Ghouls now has a $h% chance to transform them into a Frenzied Ghoul.':
                ['503740 effect_value #0'],
            'Transformed into a Frenzied Ghoul, increasing haste by $s2% for $d.':
                ['503740 effect_value 707014e1 #1', '503740 spell_duration 707014 #2'],
            'Immune to movement slowing effects.': []})

    def test_a_pulled_text_is_cut_by_the_clause_rules(self):
        rows = self.rows(TUNDRA_WARRIORS_TALENT)
        self.assertEqual(rows['Casting any spell now has a $h% chance to grant you Tundra Warriors.'],
                         ['92122 effect_value #0'])
        self.assertEqual(rows['For $d,'], ['92122 spell_duration 707421 #1'])
        self.assertEqual(rows['the critical strike chance of your Undead minions is increased by $s1%,'],
                         ['92122 effect_value 707421e0 #2'])
        self.assertEqual(rows['stacking $u times.'], ['92122 max_stacks 707421 #3'])

    def test_a_pulled_spell_evaluated_on_its_own_adds_no_clause(self):
        records = Records(dataset(DBC_DIR))
        raws = raw_clauses(records.field('Spell', GHOUL_FRENZY, 'Description[enUS]'))
        clauses, pieces = pulled_clauses(records, GHOUL_FRENZY, raws, frozenset({FRENZIED_GHOUL}))
        self.assertEqual([clause.raw for clause in clauses], raws)
        self.assertEqual([piece.text for piece in pieces], raws)
        clauses, pieces = pulled_clauses(records, GHOUL_FRENZY, raws, frozenset())
        self.assertEqual({clause.spell for clause in clauses[1:]}, {FRENZIED_GHOUL})
        self.assertEqual(''.join(piece.text for piece in pieces if piece.spell == FRENZIED_GHOUL),
                         records.field('Spell', FRENZIED_GHOUL, 'Description[enUS]'))

    def test_the_generation_is_deterministic(self):
        necromancer_hand = json.loads(NECROMANCER_LEDGER.read_text(encoding='utf-8'))
        again = ledger(load_fixture_class_file(NECROMANCER), DBC_DIR, templar_bases(necromancer_hand))
        self.assertEqual(again, self.necromancer)


if __name__ == '__main__':
    unittest.main()
