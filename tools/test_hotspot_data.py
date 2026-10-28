import csv
import gzip
import io
import json
import math
from pathlib import Path
import re
import tarfile
import tempfile
import unittest
from import_hotspot_locations import catalog, map_rows
from package_hotspot_client import extend_toc


ROOT = Path(__file__).resolve().parents[1]


class HotspotDataTests(unittest.TestCase):
    def test_loader_preserves_existing_entries_and_is_idempotent(self):
        original = b'\xef\xbb\xbfWorldMapFrame.xml\r\nExistingFeature.lua\r\n'
        updated = extend_toc(original)
        self.assertTrue(updated.startswith(original))
        self.assertEqual(updated.count(b'XPHotspots.lua'), 1)
        self.assertEqual(extend_toc(updated), updated)
        with self.assertRaises(ValueError):
            extend_toc(b'XPHotspots.lua\nxphotspots.lua\n')

    def test_catalog_contains_every_objective_and_valid_geometry(self):
        sql = (ROOT / 'data/sql/updates/pending_db_world/rev_20261011_00_hotspots.sql').read_text()
        rows = [json.loads(bytes.fromhex(value)) for value in re.findall(r'CONVERT\(0x([0-9a-f]+) USING', sql)]
        objectives = [r for r in rows if r['kind'] == 'circle']
        zones = [r for r in rows if r['kind'] == 'zone']
        self.assertEqual(len(objectives), 2715)
        self.assertEqual(len(zones), 414)
        self.assertEqual(len({r['id'] for r in rows}), len(rows))
        for r in rows:
            self.assertEqual((r['xp'], r['duration']), (150, 3600))
            self.assertTrue(math.isfinite(r['x']) and math.isfinite(r['y']))
            self.assertLessEqual(abs(r['x']), 20000)
            self.assertLessEqual(abs(r['y']), 20000)
            self.assertNotIn('|', r['name'])
            if r['enabled']:
                self.assertTrue(r['valid'])
                self.assertIn(r['map'], (0, 1, 530, 571))
            if r['kind'] == 'circle':
                self.assertEqual(r['map'], int(r['original']['map_id']))
                self.assertTrue(0 < r['radius'] <= 5000)
            if r['map'] == 571:
                self.assertEqual(r['continent'], 2)

    def test_archived_coordinates_and_single_spawn_default(self):
        tables = dict(
            area=[dict(id=44, map_id=0, parent_area_id='', name='Redridge'),
                  dict(id=45, map_id=0, parent_area_id=44, name='Subzone')],
            world_map_area=[dict(area_id=44, loc_top=1000, loc_bottom=0, loc_left=2000, loc_right=0)],
            quest_objective_hotspot=[dict(quest_id=10, objective_idx=0, target_kind='creature', target_id=1,
                target_name='Target', area_id=45, map_id=0, cx_pct=25, cy_pct=75, spawn_count=1, radius_pct=0)])
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            archive = root / 'tables.tar'
            with tarfile.open(archive, 'w') as tar:
                for name, values in tables.items():
                    stream = io.StringIO()
                    writer = csv.DictWriter(stream, fieldnames=list(values[0]))
                    writer.writeheader()
                    writer.writerows(values)
                    data = gzip.compress(stream.getvalue().encode())
                    member = tarfile.TarInfo('tables/' + name + '.csv.gz')
                    member.size = len(data)
                    tar.addfile(member, io.BytesIO(data))
            maps = root / 'maps.json'
            maps.write_text(json.dumps([dict(ID=36, AreaID=44, AreaName='Redridge',
                LocTop=9999, LocBottom=9998, LocLeft=9999, LocRight=9998)]))
            rows, count = catalog(archive, maps)
            r = rows[-1]
            self.assertEqual(count, 1)
            self.assertEqual((r['x'], r['y'], r['radius'], r['zone']), (250, 1500, 150, 44))
            self.assertEqual(r['radiusSource'], 'default-150yd-single-point')

    def test_truncated_dbc_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'WorldMapArea.dbc'
            path.write_bytes(b'WDBC')
            with self.assertRaises(ValueError):
                map_rows(path)


if __name__ == '__main__':
    unittest.main()
