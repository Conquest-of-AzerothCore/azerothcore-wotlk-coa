CLI_DESCRIPTION = """Schedule raid and heroic lockout resets for client MapDifficulty rows without a RaidDuration.

Runs the actual InstanceSaveMgr reset loading, warning and reset methods against stale instance_reset rows.
Pass --dbc-dir (or set COA_DBC_DIR) to also schedule every row of the installed client MapDifficulty.dbc.
"""

import argparse
from datetime import datetime, timedelta, timezone
import os
from pathlib import Path
import runpy
import shutil
import struct
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']

sys.path.insert(0, str(HERE.parent))
from client_data import SERVER_DBC_DIR  # noqa: E402

DAY = 86400
UTC = timezone.utc
RESET_HOUR = 4
NOW = datetime(2026, 9, 23, 10, tzinfo=UTC)
SIMULATION_END = datetime(2026, 9, 27, tzinfo=UTC)
MAP_TYPES = ['MAP_COMMON', 'MAP_INSTANCE', 'MAP_RAID', 'MAP_BATTLEGROUND', 'MAP_ARENA']
MAP_COMMON, MAP_INSTANCE, MAP_RAID, MAP_BATTLEGROUND, MAP_ARENA = range(5)

VMANGOS_MAP_TEMPLATE_RESET_DAYS = {309: 3, 409: 7, 469: 7, 509: 3, 531: 7}
WOTLK_LEVEL_80_RAID_RESET_DAYS = {249: 7, 533: 7, 603: 7, 615: 7, 616: 7, 624: 7, 631: 7, 649: 7, 724: 7}
WOTLK_TBC_RAID_RESET_DAYS = {532: 7, 534: 7, 544: 7, 548: 7, 550: 7, 564: 7, 565: 7, 568: 3, 580: 7}
COA_CUSTOM_RAID_RESET_DAYS = {880: 7, 881: 7, 890: 7, 951: 7, 968: 7}
RAID_RESET_DAYS = {**VMANGOS_MAP_TEMPLATE_RESET_DAYS, **WOTLK_LEVEL_80_RAID_RESET_DAYS,
                   **WOTLK_TBC_RAID_RESET_DAYS, **COA_CUSTOM_RAID_RESET_DAYS}
UNLISTED_RAID_RESET_DAYS = 7
HEROIC_DUNGEON_RESET_DAYS = 1


def epoch(moment):
    return int(moment.timestamp())


def at_reset_hour(day):
    return datetime(day.year, day.month, day.day, RESET_HOUR, tzinfo=UTC)


def next_reset_on_cycle(anchor, days, now):
    reset = at_reset_hour(anchor.date())
    while reset <= now:
        reset += timedelta(days=days)
    return reset


def first_reset(days):
    return at_reset_hour(NOW.date() + timedelta(days=days))


def reset_days(map_id, map_type, difficulty, raid_duration):
    if raid_duration:
        return raid_duration / DAY
    if map_type == MAP_RAID:
        return RAID_RESET_DAYS.get(map_id, UNLISTED_RAID_RESET_DAYS)
    if map_type == MAP_INSTANCE and difficulty:
        return HEROIC_DUNGEON_RESET_DAYS
    return None


def fallback_cases():
    cases = []
    for map_id, days in RAID_RESET_DAYS.items():
        cases += [(0, map_id, MAP_RAID, difficulty, days * DAY) for difficulty in range(4)]
    for map_id in (33, 189, 574, 1912):
        cases += [(0, map_id, MAP_INSTANCE, 0, 0), (0, map_id, MAP_INSTANCE, 1, DAY), (0, map_id, MAP_INSTANCE, 2, DAY)]
    for map_id, map_type in ((0, MAP_COMMON), (30, MAP_BATTLEGROUND), (562, MAP_ARENA)):
        cases += [(0, map_id, map_type, difficulty, 0) for difficulty in range(4)]
    cases += [(604800, 891, MAP_RAID, difficulty, 604800) for difficulty in range(4)]
    cases += [(604800, 1731, MAP_INSTANCE, 0, 604800), (86400, 574, MAP_INSTANCE, 1, 86400),
              (432000, 249, MAP_RAID, 0, 432000), (259200, 409, MAP_RAID, 1, 259200)]
    return cases


def stale_scenario():
    maps = {409: MAP_RAID, 309: MAP_RAID, 509: MAP_RAID, 568: MAP_RAID, 249: MAP_RAID, 533: MAP_RAID,
            891: MAP_RAID, 1731: MAP_INSTANCE, 574: MAP_INSTANCE, 33: MAP_INSTANCE, 30: MAP_BATTLEGROUND,
            0: MAP_COMMON}
    difficulties = {(409, 0): 0, (409, 1): 0, (409, 2): 0, (409, 3): 0, (309, 0): 0, (509, 0): 0, (568, 0): 0,
                    (249, 0): 0, (533, 1): 0, (891, 0): 604800, (1731, 0): 604800, (574, 0): 0, (574, 1): 0,
                    (33, 0): 0, (33, 1): 0, (33, 2): 0, (30, 0): 0, (0, 0): 0}
    weekly = datetime(2026, 6, 6, 4, tzinfo=UTC)
    short = datetime(2026, 6, 3, 12, tzinfo=UTC)
    heroic = datetime(2026, 6, 2, 4, tzinfo=UTC)
    configured = datetime(2026, 9, 27, 4, tzinfo=UTC)
    stored = {(409, 0): weekly, (309, 0): short, (509, 0): short, (568, 0): short, (249, 0): weekly,
              (533, 1): weekly, (891, 0): configured, (1731, 0): configured, (574, 1): heroic, (13, 0): weekly}
    expected = {}
    for key, raid_duration in difficulties.items():
        days = reset_days(key[0], maps[key[0]], key[1], raid_duration)
        if days is None:
            continue
        expected[key] = next_reset_on_cycle(stored[key], days, NOW) if key in stored else first_reset(days)
    assert expected[(409, 0)] == datetime(2026, 9, 26, 4, tzinfo=UTC)
    assert expected[(309, 0)] == expected[(568, 0)] == datetime(2026, 9, 25, 4, tzinfo=UTC)
    assert expected[(574, 1)] == expected[(33, 2)] == datetime(2026, 9, 24, 4, tzinfo=UTC)
    assert expected[(891, 0)] == configured and (33, 0) not in expected and (30, 0) not in expected
    return maps, difficulties, stored, expected


def after_simulation(maps, difficulties, expected):
    result, resets = {}, {}
    for key, reset in expected.items():
        days = reset_days(key[0], maps[key[0]], key[1], difficulties[key])
        resets[key] = []
        while reset < SIMULATION_END:
            resets[key].append(reset)
            reset += timedelta(days=days)
        result[key] = reset
    return result, resets


def client_scenario(dbc_dir):
    def rows(name):
        blob = (dbc_dir / name).read_bytes()
        count, fields, size = struct.unpack_from('<3I', blob, 4)
        return [struct.unpack_from('<' + str(fields) + 'I', blob, 20 + i * size) for i in range(count)]

    maps = {row[0]: row[2] for row in rows('Map.dbc')}
    difficulties = {}
    for row in sorted(rows('MapDifficulty.dbc')):
        difficulties[(row[1], row[2])] = row[20]
    expected, missing = {}, 0
    for (map_id, difficulty), raid_duration in difficulties.items():
        days = reset_days(map_id, maps.get(map_id), difficulty, raid_duration)
        if days is not None:
            expected[(map_id, difficulty)] = first_reset(days)
            missing += not raid_duration
    lockouts = [key for key in difficulties if maps.get(key[0]) == MAP_RAID
                or (maps.get(key[0]) == MAP_INSTANCE and key[1])]
    assert missing and all(key in expected for key in lockouts)
    return maps, difficulties, {}, expected, len(lockouts), missing


def cpp_rows(rows):
    return '{ ' + ', '.join(f'{{ {{ {m}u, {d}u }}, time_t({epoch(t)}) }}' for (m, d), t in sorted(rows.items())) + ' }'


def cpp_scenario(maps, difficulties, stored, expected):
    map_rows = ', '.join(f'{{ {m}u, {t}u }}' for m, t in sorted(maps.items()))
    difficulty_rows = ', '.join(f'{{ {m}u, {d}u, {r}u }}' for (m, d), r in sorted(difficulties.items()))
    return (f'Scenario{{ {RESET_HOUR}u, time_t({epoch(NOW)}), {{ {map_rows} }}, {{ {difficulty_rows} }}, '
            f'{cpp_rows(stored)}, {cpp_rows(expected)} }}')


def expected_header(client):
    cases = ',\n    '.join(f'{{ {r}u, {m}u, {MAP_TYPES[t]}, Difficulty({d}), {e}u }}'
                           for r, m, t, d, e in fallback_cases())
    maps, difficulties, stored, expected = stale_scenario()
    after, resets = after_simulation(maps, difficulties, expected)
    molten_core, zul_gurub, heroic, configured = (409, 0), (309, 0), (574, 1), (891, 0)
    assert resets[molten_core] == [datetime(2026, 9, 26, 4, tzinfo=UTC)] and resets[configured] == []
    assert resets[zul_gurub] == [datetime(2026, 9, 25, 4, tzinfo=UTC)] and len(resets[heroic]) == 3
    extended = after[molten_core] + timedelta(days=RAID_RESET_DAYS[409])
    lines = [
        f'std::vector<FallbackCase> const FallbackCases{{\n    {cases}\n}};',
        f'Scenario const StaleRows = {cpp_scenario(maps, difficulties, stored, expected)};',
        f'ResetKey const MoltenCore{{ {molten_core[0]}u, {molten_core[1]}u }};',
        f'ResetKey const ZulGurub{{ {zul_gurub[0]}u, {zul_gurub[1]}u }};',
        f'ResetKey const HeroicDungeon{{ {heroic[0]}u, {heroic[1]}u }};',
        f'ResetKey const ConfiguredRaid{{ {configured[0]}u, {configured[1]}u }};',
        f'time_t const SimulationEnd = {epoch(SIMULATION_END)};',
        f'time_t const MoltenCoreReset = {epoch(resets[molten_core][0])};',
        f'time_t const ZulGurubReset = {epoch(resets[zul_gurub][0])};',
        f'time_t const MoltenCoreExtendedReset = {epoch(extended)};',
        'std::vector<time_t> const HeroicDungeonResets{ ' + ', '.join(str(epoch(t)) for t in resets[heroic]) + ' };',
        f'ResetRows const AfterSimulation = {cpp_rows(after)};',
        'std::vector<Scenario> const ClientDbc{ ' + (cpp_scenario(*client[:4]) if client else '') + ' };',
    ]
    return '\n'.join(lines) + '\n'


def harness():
    instances = ROOT / 'src/server/game/Instances'
    header = (instances / 'InstanceSaveMgr.h').read_text(encoding='utf-8')
    source = (instances / 'InstanceSaveMgr.cpp').read_text(encoding='utf-8')
    structure = (ROOT / 'src/server/shared/DataStores/DBCStructure.h').read_text(encoding='utf-8')
    stores = (ROOT / 'src/server/game/DataStores/DBCStores.cpp').read_text(encoding='utf-8')
    assert 'MapDifficulty(entry->resetTime, entry->maxPlayers' in stores
    event = header[header.index('    struct InstResetEvent'):header.index('ResetTimeQueue;') + len('ResetTimeQueue;')]
    accessors = header[header.index('    [[nodiscard]] time_t GetResetTimeFor('):
                       header.index('    [[nodiscard]] ResetTimeByMapDifficultyMap const& GetResetTimeMap()')]
    reset_map = next(line for line in header.splitlines() if line.endswith('> ResetTimeByMapDifficultyMap;'))
    delays = next(line for line in source.splitlines() if line.startswith('uint16 InstanceSaveMgr::ResetTimeDelay[]'))
    methods = '\n\n'.join([delays] + [method(source, signature) for signature in (
        'uint32 InstanceSaveMgr::GetResetDelayFor(', 'void InstanceSaveMgr::LoadResetTimes()',
        'void InstanceSaveMgr::ScheduleReset(', 'void InstanceSaveMgr::Update()',
        'void InstanceSaveMgr::_ResetOrWarnAll(')])
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, text in [
        ('MAP_DIFFICULTY', method(structure, 'struct MapDifficulty\n{') + ';'),
        ('DIFFICULTY_LOOKUP', method(stores, 'MapDifficulty const* GetMapDifficultyData(uint32 mapId, Difficulty')),
        ('RESET_TIME_MAP', reset_map),
        ('EVENT', event),
        ('ACCESSORS', accessors),
        ('METHODS', methods),
    ]:
        code = code.replace('// ACTUAL_' + marker, text)
    return code


def compile_and_run(code, expected):
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler (VS Developer PowerShell on Windows).'
    with tempfile.TemporaryDirectory(prefix='coa-raid-reset-') as directory:
        out = Path(directory)
        cpp, exe = out / 'raid_reset.cpp', out / ('raid_reset.exe' if os.name == 'nt' else 'raid_reset')
        cpp.write_text(code, encoding='utf-8')
        (out / 'expected.h').write_text(expected, encoding='utf-8')
        includes = [out, ROOT / 'src/server/game/Instances', ROOT / 'src/server/game/Maps', ROOT / 'src/common',
                    ROOT / 'src/server/shared/DataStores']
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8', *['/I' + str(p) for p in includes],
                     str(cpp), '/Fe' + str(exe)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', *['-I' + str(p) for p in includes], str(cpp),
                     '-o', str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--dbc-dir', type=Path, default=Path(os.environ.get('COA_DBC_DIR') or SERVER_DBC_DIR))
    args = parser.parse_args()
    client = None
    if (args.dbc_dir / 'MapDifficulty.dbc').is_file() and (args.dbc_dir / 'Map.dbc').is_file():
        client = client_scenario(args.dbc_dir)
    compile_and_run(harness(), expected_header(client))
    coverage = (f'; client DBC: {client[4]} raid/heroic difficulties scheduled, {client[5]} without RaidDuration'
                if client else '; client DBC not found, row coverage skipped')
    print('PASS: fallback reset periods, stale instance_reset rows rescheduled, warnings and one reset per period'
          + coverage)


if __name__ == '__main__':
    main()
