from pathlib import Path
import re
import unittest

from test_molten_core_smart_scripts_base_entry import molten_core_files, value_tuples


DISCIPLE_SHADOW_BOLTS = {
    2105957: 'Proxima the Opressor',
    2105959: 'Ebon the Cruel',
    2105961: 'Cull the Destroyer',
}
HARBINGER_PRIESTS_FAMILY = (2105950, 2105951, 2105952, 2105953)
HIT_SCRIPT = 'spell_coa_damage_info_hit'

DELETE_RE = re.compile(r'DELETE\s+FROM\s+`(\w+)`\s+WHERE\s+`spell_id`\s*(=|IN)\s*(\d+|\([^)]*\))', re.S)
INSERT_RE = re.compile(
    r'INSERT\s+INTO\s+`(coa_spell_damage_info|spell_script_names)`\s*\(([^)]+)\)\s*VALUES\s*(.+?);', re.S)


def replay(files):
    info, scripts = {}, set()
    for path in files:
        text = path.read_text(encoding='utf-8')
        for match in DELETE_RE.finditer(text):
            table, ids = match.group(1), {int(v) for v in re.findall(r'\d+', match.group(3))}
            if table == 'coa_spell_damage_info':
                for spell_id in ids:
                    info.pop(spell_id, None)
            elif table == 'spell_script_names':
                scripts -= {entry for entry in scripts if entry[0] in ids}
        for match in INSERT_RE.finditer(text):
            table = match.group(1)
            for row in value_tuples(match.group(3)):
                cells = [cell.strip().strip("'") for cell in row.split(',')]
                if table == 'coa_spell_damage_info':
                    info[int(cells[0])] = tuple(int(cell) for cell in cells[1:5])
                else:
                    scripts.add((int(cells[0]), cells[1]))
    return info, scripts


class MoltenCoreDamageInfoTests(unittest.TestCase):
    def test_disciple_shadow_bolts_read_the_harbinger_priests_family(self):
        info, scripts = replay(molten_core_files())
        for spell_id, caster in DISCIPLE_SHADOW_BOLTS.items():
            with self.subTest(caster=caster):
                self.assertEqual(info.get(spell_id), HARBINGER_PRIESTS_FAMILY)
                self.assertIn((spell_id, HIT_SCRIPT), scripts)


if __name__ == '__main__':
    unittest.main()
