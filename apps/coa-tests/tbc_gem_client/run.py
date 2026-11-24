import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import sqlite3
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def method(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


parser = argparse.ArgumentParser()
parser.add_argument('--dbc-dir', type=Path, required=True)
args = parser.parse_args()
enchanting_migration = ROOT / 'data/sql/updates/pending_db_world/rev_20261124_01_coa_tbc_enchanting_level60.sql'
with sqlite3.connect(':memory:') as database:
    database.execute('CREATE TABLE item_template (entry INTEGER PRIMARY KEY, RequiredLevel INTEGER)')
    database.executemany('INSERT INTO item_template VALUES (?, ?)', [(22459, 70), (22460, 70), (40111, 80)])
    for _ in range(2):
        database.executescript(enchanting_migration.read_text())
        assert database.execute('SELECT RequiredLevel FROM item_template ORDER BY entry').fetchall() == [
            (60,), (60,), (80,)]
    database.execute('UPDATE item_template SET RequiredLevel = 55 WHERE entry = 22460')
    database.executescript(enchanting_migration.read_text())
    assert database.execute('SELECT RequiredLevel FROM item_template WHERE entry = 22460').fetchone() == (55,)

spec = importlib.util.spec_from_file_location('gem_build', ROOT / 'apps/coa-world-content/tbc_gems/build.py')
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)
with tempfile.TemporaryDirectory(prefix='coa-gem-requirements-') as directory:
    output = Path(directory)
    source = (ROOT / 'src/server/coa/CoATbcGemRequirements.cpp').read_text()
    harness = (HERE / 'harness.cpp').read_text()
    harness = harness.replace('// ACTUAL_LOAD', method(source, 'void LoadRequirements('))
    baseline = json.loads(generator.BASELINE.read_text())
    props = {int(row['ID']): row for row in baseline['gem_properties']}
    enchants = {int(row['ID']): row for row in baseline['enchantments']}
    fixture = []
    for item in generator.scoped_items(baseline):
        prop = props[int(item['GemProperties'])]
        enchant = enchants[int(prop['Enchant_Id'])]
        fixture.append('    { ' + ', '.join(str(value) for value in
            (item['entry'], item['GemProperties'], prop['Enchant_Id'], enchant['MinLevel'])) + ' }')
    harness = harness.replace('// ACTUAL_FIXTURE', ',\n'.join(fixture))
    cpp = output / 'harness.cpp'
    cpp.write_text(harness)
    exe = output / 'harness'
    compiler = shutil.which(os.environ.get('CXX', 'c++'))
    assert compiler
    subprocess.run([compiler, '-std=c++20', '-Wall', '-Wextra', '-Werror',
                    '-I' + str(ROOT / 'src/server/coa'), '-I' + str(ROOT / 'src/common/Utilities'), str(cpp), '-o', str(exe)], check=True, timeout=60)
    subprocess.run([str(exe)], check=True, timeout=15)
print('PASS: actual requirement loader caps only validated TBC gem requirements, preserves effects and '
      'lower gates, rejects incomplete mappings, and is repeatable without a client patch')
