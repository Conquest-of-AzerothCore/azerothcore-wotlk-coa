from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'modules/mod-manastorm-endless/src'
PENDING = ROOT / 'data/sql/updates/pending_db_world'



def function(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def dungeon_budget_rows(path):
    rows = {}
    for match in re.finditer(
        r"^\((\d+), ([012]), (\d+), 63, (\d+),",
        path.read_text(encoding='utf-8'),
        re.MULTILINE,
    ):
        map_id, difficulty, entry, health = map(int, match.groups())
        rows.setdefault((map_id, entry), {})[difficulty] = health
    return rows


def health_update_rows(path):
    rows = {}
    pattern = (
        r"UPDATE `coa_dungeon_rescale_budget`\s+SET `health` = CASE `entry`"
        r"(.*?)END\s+WHERE `map_id` = (\d+) AND `difficulty` = (\d)"
        r" AND `entry` IN \(([^)]*)\);"
    )
    for body, map_id, difficulty, entries in re.findall(pattern, path.read_text(encoding='utf-8'), re.DOTALL):
        values = {int(entry): int(health) for entry, health in re.findall(r"WHEN (\d+) THEN (\d+)", body)}
        if set(values) != set(map(int, entries.split(','))):
            raise AssertionError(f"Map {map_id} difficulty {difficulty}: CASE entries mismatch WHERE entries")
        for entry, health in values.items():
            rows.setdefault((int(map_id), entry), {})[int(difficulty)] = health
    return rows

def header_constants():
    header = (MODULE / 'ManastormOutlandHealth.h').read_text(encoding='utf-8')
    return {name: float(value) for name, value in re.findall(r'constexpr double (\w+) = ([0-9.]+);', header)}


class OutlandHealthTests(unittest.TestCase):
    def test_tbc_mythic_boss_budget_updates_use_confirmed_source_rows(self):
        source = {}
        for name in ('rev_20261121_20_coa_hellfire_dungeons_combat.sql',
                     'rev_20261123_40_coa_coilfang_combat.sql',
                     'rev_20261123_56_coa_tbc_remaining_combat.sql'):
            for key, modes in dungeon_budget_rows(PENDING / name).items():
                source.setdefault(key, {}).update(modes)
        updates = health_update_rows(PENDING / 'rev_1795706983084427444.sql')
        target_maps = {269, 540, 542, 543, 545, 546, 547, 552, 553, 554, 555, 556, 557, 558, 560, 585}
        source_bosses = {key for key, modes in source.items() if key[0] in target_maps and set(modes) == {0, 1, 2}}
        updated_bosses = {key for key, modes in updates.items() if key[0] in target_maps and set(modes) == {0, 1, 2}}

        self.assertEqual(updated_bosses, source_bosses)
        for key in sorted(source_bosses):
            mythic = round(source[key][2] * 0.5)
            expected = {0: round(mythic / 1.88), 1: round(mythic * 1.44 / 1.88), 2: mythic}
            self.assertEqual(updates[key], expected, key)

        self.assertEqual({map_id for map_id, _ in updates}, target_maps)
        self.assertEqual(len(updated_bosses), 58)

    def test_manastorm_uses_half_health_only_for_the_selected_tbc_dungeon_boss(self):
        self.assertEqual(header_constants()['TBC_DUNGEON_BOSS_HEALTH_MULTIPLIER'], 0.5)
        header = (MODULE / 'ManastormOutlandHealth.h').read_text(encoding='utf-8')
        ratio = function(header, 'constexpr double Ratio(')
        self.assertIn('tbcDungeonObjective ? TBC_DUNGEON_BOSS_HEALTH_MULTIPLIER : 1.0', ratio)
        source = (MODULE / 'ManastormMgr.cpp').read_text(encoding='utf-8')
        selection = function(source, 'double GetOutlandCreatureHealthRatio(')
        self.assertIn('IsTbcDungeon(creature->FindMap())', selection)
        self.assertIn('IsObjectiveBoss(creature, run)', selection)
        self.assertIn('creature->GetEntry() == run.GetSegment().ObjectiveCreatureEntry', selection)
        scaling = function(source, 'void ManastormMgr::ApplyCreatureHealthScaling(')
        applied = scaling.index('GetOutlandCreatureHealthRatio(')
        self.assertLess(scaling.index('map->IsRaid()'), applied)
        self.assertLess(applied, scaling.index('run.GetScaling().HealthMultiplier'))
        self.assertLess(applied, scaling.index('SetChaoticLinkBaseMaxHealth('))


if __name__ == '__main__':
    unittest.main()
