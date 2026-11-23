import argparse
import json
import random
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import fixture_format
from fixture_format import encode_field, value_text
from tables import TABLES

ROUND_LIMIT = 60
TARGET_HITS = 8
TARGET_BRANCH_HITS = 4
TEAM_HANDLERS = ('FX03', 'FX15', 'FX20', 'FX22', 'FX39', 'FX145')
TIP_POWER = 260
MAX_TARGET_BATTLES = 40
EXTRA_POOL = 40
LIBRARY_ABILITIES = (277, 522, 325, 1344, 1073, 795, 1104, 385)
HARD_CODED_AURAS = (1124, 831)


def prop_is(*props):
    return lambda fx, turn, entry: fx['prop'] in props


HANDLER_MATCH = {
    'FX00': prop_is(24, 222, 96, 62, 384, 385), 'FX01': prop_is(27), 'FX02': prop_is(59), 'FX03': prop_is(141),
    'FX04': prop_is(32), 'FX05': prop_is(131), 'FX06': prop_is(226), 'FX07': prop_is(66), 'FX08': prop_is(68),
    'FX09': prop_is(149), 'FX10': prop_is(80), 'FX12': prop_is(77, 75), 'FX14': prop_is(53), 'FX15': prop_is(100),
    'FX17': prop_is(44), 'FX18': prop_is(197), 'FX19': prop_is(138),
    'FX20': lambda fx, turn, entry: fx['prop'] == 29 and fx['p3'] > 0, 'FX21': prop_is(29), 'FX22': prop_is(23),
    'FX23': prop_is(104),
    'FX24': lambda fx, turn, entry: fx['prop'] == 52 and any(other['prop'] == 194 for other in turn),
    'FX25': prop_is(26, 63, 50, 52, 178, 54, 172), 'FX26': prop_is(144), 'FX27': prop_is(61), 'FX28': prop_is(22),
    'FX30': prop_is(78), 'FX31': prop_is(76),
    'FX32': lambda fx, turn, entry: fx['prop'] == 79 and not entry['priority'], 'FX33': prop_is(159),
    'FX34': prop_is(170), 'FX36': lambda fx, turn, entry: fx['prop'] == 85 and fx['p1'] == 69, 'FX37': prop_is(49),
    'FX38': lambda fx, turn, entry: fx['prop'] == 31 and fx['p1'] == 141 and fx['p2'] == 1,
    'FX39': prop_is(107, 139), 'FX145': prop_is(145),
}


def plain(lua_type, value, depth=0):
    if depth > 8:
        raise ValueError('nested value too deep')
    if lua_type(value) != 'table':
        return value
    return {(int(key) if isinstance(key, float) and key.is_integer() else key): plain(lua_type, item, depth + 1)
            for key, item in value.items()}


def seq(table):
    return [table[index] for index in range(1, len(table) + 1)] if table else []


class Tracer:
    def __init__(self, upstream, seed):
        from lupa.lua51 import LuaRuntime, lua_type
        self.lua_type = lua_type
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        scripts = str((Path(upstream) / 'scripts').resolve())
        chunk = self.lua.eval('function(source, scripts) return assert(loadstring(source, "@trace.lua"))(scripts) end')
        self.M = chunk((HERE / 'trace.lua').read_text(encoding='utf-8'), scripts)
        self.C = self.M.C
        self.commands = random.Random(seed)
        self.rolls_source = random.Random(seed + 1)
        self.rolls = []
        self.kinds = {}

    def roll(self, lo, hi):
        lo, hi = int(lo), int(hi)
        value = self.rolls_source.randint(lo, hi)
        self.rolls.append((lo, hi, value))
        return value

    def species(self):
        return sorted(int(key) for key in self.M.D.species.keys())

    def kit_slots(self, entry):
        slots = []
        for row in seq(plain(self.lua_type, self.M.kitSlots(entry))):
            turns = [{'event': turn['event'], 'fx': seq(turn['fx'])} for turn in seq(row['turns'])]
            slots.append({**row, 'turns': turns})
        return slots

    def new_pet(self, entry, level, hp=None, picks=None):
        quality = int(self.C.RollQuality(self.roll))
        options = self.lua.table_from({'quality': quality, 'hp': hp} if hp is not None else {'quality': quality})
        lua_picks = self.lua.table_from(picks) if picks else None
        pet = self.C.NewPet(entry, level, lua_picks, self.roll, options)
        return pet, quality

    def choose(self, battle, status, target=None):
        info = plain(self.lua_type, self.M.choices(battle))
        bench, ready, locked = (sorted(int(value) for value in seq(info.get(key, {})))
                                for key in ('bench', 'ready', 'locked'))
        if status == 'force':
            if target and target[0] in bench:
                return f'S{target[0]}'
            return f'S{self.commands.choice(bench)}'
        if target and int(info['active']) == target[0] and target[1] in ready and self.commands.random() < 0.8:
            return f'A{target[1]}'
        draw = self.commands.random()
        if draw < 0.15 and info['canTrap']:
            return 'T'
        if 0.15 <= draw < 0.20:
            if not info['canTrap']:
                return 'T'
            if locked:
                return f'A{self.commands.choice(locked)}'
        if 0.20 <= draw < 0.30 and bench and not info['channel']:
            return f'S{self.commands.choice(bench)}'
        return f'A{self.commands.choice(ready)}' if ready else 'A1'

    def battle(self, battle_id, team, target=None, tipped=frozenset()):
        self.rolls = []
        lines, pets, new_tips = [], {'P': [], 'E': []}, set()
        for side in ('P', 'E'):
            for index, member in enumerate(team[side], 1):
                pet, quality = self.new_pet(member['entry'], member['level'], member.get('hp'), member.get('picks'))
                pets[side].append(pet)
                picks, hp = member.get('picks'), member.get('hp')
                lines.append(['PET', side, index, member['entry'], member['level'], quality,
                              ','.join(str(pick) for pick in picks) if picks else 'nil',
                              'nil' if hp is None else hp])
                lines.append(['BUILT', side, index] + list(seq(self.M.built(pet))))
                for tip in seq(self.M.tips(pet)):
                    tip = plain(self.lua_type, tip)
                    lines.append(['TIPX' if tip['fallback'] else 'TIP', side, index, int(tip['slot']), tip['text']])
                if member['entry'] not in tipped and member['entry'] not in new_tips:
                    new_tips.add(member['entry'])
                    for tip in seq(plain(self.lua_type, self.M.kitTips(member['entry'], pet.power))):
                        lines.append(['KITTIPX' if tip['fallback'] else 'KITTIP', side, index, int(tip['slot']),
                                      int(tip['opt']), tip['text']])
        battle = self.C.NewBattle(self.lua.table_from(pets['P']), self.lua.table_from(pets['E']), self.roll)
        status = 'turn'
        for _ in range(ROUND_LIMIT):
            command = self.choose(battle, status, target)
            enemy = self.C.AI(battle)
            lines.append(['CMD', command, enemy])
            events, status = self.C.Round(battle, command, enemy)
            for event in seq(plain(self.lua_type, events)):
                self.kinds[event['k']] = self.kinds.get(event['k'], 0) + 1
                lines.append(['EV', fixture_format.canonical_event(event)])
            lines.append(['STATUS', status])
            for row in seq(plain(self.lua_type, self.M.snapshot(battle))):
                lines.append(['STATE'] + seq(row))
            if status in ('win', 'loss'):
                break
        rolls = [['ROLL', lo, hi, value] for lo, hi, value in self.rolls]
        header = [['BATTLE', battle_id]]
        body = header + rolls + lines + [['END']]
        species = [member['entry'] for side in ('P', 'E') for member in team[side]]
        return '\n'.join('\t'.join(cell if isinstance(cell, str) and cell.startswith('k=') else value_text(cell)
                                   for cell in row) for row in body) + '\n', species, new_tips

    def report(self):
        counts = {str(key): int(value) for key, value in plain(self.lua_type, self.M.counts).items()}
        branches = {str(key): int(value) for key, value in plain(self.lua_type, self.M.branches).items()}
        return {'handlers': counts, 'kinds': dict(self.kinds), 'unknown': int(self.M.unknownTotal()),
                'branches': branches}

    def branch_candidates(self):
        found = plain(self.lua_type, self.M.branchCandidates())
        return {name: sorted({(int(row['entry']), int(row['slot']), int(row['opt'])) for row in seq(rows)})
                for name, rows in found.items()}


def handler_candidates(tracer, species):
    candidates = {name: [] for name in HANDLER_MATCH}
    for entry in species:
        for slot in tracer.kit_slots(entry):
            for turn in slot['turns']:
                if turn['event'] not in (255, 2):
                    continue
                for fx in turn['fx']:
                    for name, match in HANDLER_MATCH.items():
                        if match(fx, turn['fx'], slot):
                            candidates[name].append((entry, int(slot['slot']), int(slot['opt'])))
    return {name: list(dict.fromkeys(found)) for name, found in candidates.items()}


NEEDS_FALLEN_ALLY = ('FX27',)


def targeted_plans(tracer, species, rng):
    candidates = handler_candidates(tracer, species)
    plans = []
    for name in sorted(fixture_format.REQUIRED_HANDLERS, key=lambda handler: len(candidates.get(handler, []))):
        found = candidates.get(name, [])
        rng.shuffle(found)
        for entry, slot, opt in (found * 4)[:MAX_TARGET_BATTLES]:
            picks = [1, 1, 1]
            picks[slot - 1] = opt
            holder = {'entry': entry, 'level': 25, 'picks': picks}
            enemy = [{'entry': rng.choice(species), 'level': 25}]
            if name in NEEDS_FALLEN_ALLY:
                fallen = [{'entry': rng.choice(species), 'level': 25, 'hp': 1} for _ in range(2)]
                plans.append((name, {'P': fallen + [holder], 'E': enemy}, (3, slot)))
            elif name in TEAM_HANDLERS:
                plans.append((name, team_of(holder, species, rng), (1, slot)))
            else:
                plans.append((name, {'P': [holder], 'E': enemy}, (1, slot)))
    return plans


def team_of(holder, species, rng):
    return {'P': [holder] + [{'entry': rng.choice(species), 'level': 25} for _ in range(2)],
            'E': [{'entry': rng.choice(species), 'level': 25} for _ in range(3)]}


def branch_plans(tracer, species, rng):
    candidates = tracer.branch_candidates()
    plans = []
    for name in sorted(candidates, key=lambda branch: len(candidates[branch])):
        found = list(candidates[name])
        rng.shuffle(found)
        for entry, slot, opt in (found * 4)[:MAX_TARGET_BATTLES]:
            picks = [1, 1, 1]
            picks[slot - 1] = opt
            plans.append((name, team_of({'entry': entry, 'level': 25, 'picks': picks}, species, rng), (1, slot)))
    return sorted(candidates), plans


def random_plans(pool, rng, battles):
    plans = []
    for _ in range(battles):
        size = 1 if rng.random() < 0.6 else 3
        level = rng.randint(1, 25)
        enemy_level = max(1, min(25, level + rng.randint(-2, 2)))
        mine = [{'entry': rng.choice(pool), 'level': level} for _ in range(size)]
        for member in mine:
            if rng.random() < 0.1:
                member['hp'] = rng.randint(1, 50)
        plans.append({'P': mine, 'E': [{'entry': rng.choice(pool), 'level': enemy_level} for _ in range(size)]})
    return plans


def data_rows(export_path, species_used):
    export = json.loads(Path(export_path).read_text(encoding='utf-8'))
    tables = export['tables']
    species = [row for row in tables['coa_pet_species'] if row[0] in species_used]
    kits = {row[2] for row in species}
    kit_abilities = [row for row in tables['coa_pet_kit_ability'] if row[0] in kits]
    effects_by_ability = {}
    for row in tables['coa_pet_ability_effect']:
        effects_by_ability.setdefault(row[0], []).append(row)
    bases = {row[0]: row[5] for row in tables['coa_pet_ability']}
    reach, pending = set(), [row[3] for row in kit_abilities] + list(LIBRARY_ABILITIES) + list(HARD_CODED_AURAS)
    while pending:
        ability = pending.pop()
        if ability in reach:
            continue
        reach.add(ability)
        pending += [row[4] for row in effects_by_ability.get(ability, []) if row[4] and row[4] in bases]
        if bases.get(ability):
            pending.append(bases[ability])
    auras = reach | {row[4] for ability in reach for row in effects_by_ability.get(ability, []) if row[4]}
    rows = {
        'coa_pet_species': species,
        'coa_pet_kit': [row for row in tables['coa_pet_kit'] if row[0] in kits],
        'coa_pet_kit_ability': kit_abilities,
        'coa_pet_ability': [row for row in tables['coa_pet_ability'] if row[0] in reach],
        'coa_pet_ability_turn': [row for row in tables['coa_pet_ability_turn'] if row[0] in reach],
        'coa_pet_ability_effect': [row for row in tables['coa_pet_ability_effect'] if row[0] in reach],
        'coa_pet_effect_property': tables['coa_pet_effect_property'],
        'coa_pet_state': tables['coa_pet_state'],
        'coa_pet_aura_state': [row for row in tables['coa_pet_aura_state'] if row[0] in auras],
        'coa_pet_xp': tables['coa_pet_xp'],
        'coa_pet_presentation': [row for row in tables['coa_pet_presentation'] if row[0] in species_used],
    }
    lines = []
    for name in TABLES:
        for row in rows.get(name, []):
            lines.append('\t'.join([name] + [value_text(value) for value in row]))
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--upstream', required=True)
    parser.add_argument('--export', required=True)
    parser.add_argument('--out-dir', required=True)
    parser.add_argument('--seed', type=int, required=True)
    parser.add_argument('--battles', type=int, required=True)
    parser.add_argument('--max-bytes', type=int, required=True)
    args = parser.parse_args()
    tracer = Tracer(args.upstream, args.seed)
    rng = random.Random(args.seed + 2)
    species = tracer.species()
    traces, used, size, tipped = [], set(), 0, set()
    report = {'handlers': {}, 'kinds': {}, 'unknown': 0, 'branches': {}}

    def run(team, target=None, wanted=None):
        nonlocal size
        before = tracer.report()
        text, battle_species, new_tips = tracer.battle(len(traces) + 1, team, target, frozenset(tipped))
        after = tracer.report()
        gained = {key: after['handlers'].get(key, 0) - before['handlers'].get(key, 0) for key in after['handlers']}
        gained_branches = {key: after['branches'].get(key, 0) - before['branches'].get(key, 0)
                           for key in after['branches']}
        if wanted and gained.get(wanted, 0) == 0 and gained_branches.get(wanted, 0) == 0:
            return False
        if not wanted and size + len(text.encode('utf-8')) > args.max_bytes * 0.55:
            return None
        traces.append(text)
        size += len(text.encode('utf-8'))
        used.update(battle_species)
        tipped.update(new_tips)
        for key, value in gained_branches.items():
            report['branches'][key] = report['branches'].get(key, 0) + value
        for key, value in gained.items():
            report['handlers'][key] = report['handlers'].get(key, 0) + value
        for key, value in after['kinds'].items():
            report['kinds'][key] = report['kinds'].get(key, 0) + value - before['kinds'].get(key, 0)
        report['unknown'] += after['unknown'] - before['unknown']
        return True

    for name, team, target in targeted_plans(tracer, species, rng):
        if report['handlers'].get(name, 0) < TARGET_HITS:
            run(team, target, name)
    reachable, plans = branch_plans(tracer, species, rng)
    report['reachable_branches'] = reachable
    for name, team, target in plans:
        if report['branches'].get(name, 0) < TARGET_BRANCH_HITS:
            run(team, target, name)
    pool = sorted(used) + rng.sample(species, EXTRA_POOL)
    for team in random_plans(pool, rng, args.battles):
        if run(team) is None:
            break
    data = data_rows(args.export, used)
    out = Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    (out / 'traces.txt').write_text(''.join(traces), encoding='utf-8')
    (out / 'pet_data.txt').write_text(data, encoding='utf-8')
    total = size + len(data.encode('utf-8'))
    failures = fixture_format.coverage_failures(report)
    if total > args.max_bytes:
        failures.append(f'fixtures are {total} bytes, limit {args.max_bytes}')
    census = plain(tracer.lua_type, tracer.M.fallbackCensus(TIP_POWER))
    print(json.dumps({'battles': len(traces), 'bytes': total, 'report': report, 'tooltip_census': census,
                      'failures': failures}, indent=1))
    sys.exit(1 if failures else 0)


if __name__ == '__main__':
    main()
