import argparse
import random
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import sql_reader
from trace_battles import FIXTURES, read_world

SQL = HERE.parents[3] / 'data/sql/updates/pending_db_world'
CRITTER_TEMPLATES = {24270: (31, 0)}
HELLFIRE, ELWYNN = 3483, 12
REQUIRED = (
    'fill_cap', 'spacing', 'cooldown', 'lifetime', 'nobody_near', 'back_within_grace', 'rescan_idle',
    'rescan_moved', 'not_scanning', 'ignored_mobs', 'spawn_spots', 'adopt_release', 'adopt_consume',
    'adopt_refused', 'menu', 'solo_team', 'zone_team', 'fallback_team', 'blips', 'blip_cap', 'vanish',
    'map_change', 'shutdown', 'two_challengers',
)


def pool_species():
    species = {}
    for line in (FIXTURES / 'pet_data.txt').read_text(encoding='utf-8').splitlines():
        f = line.split('\t')
        if f[0] == 'coa_pet_species':
            species[int(f[1])] = {'name': f[2], 'wild': f[4] == '1', 'critter': f[6] == '1'}
    return species


def zone_tables(species):
    tables = sql_reader.read(sorted(SQL.glob('rev_2026112[34]_*_coa_pet_battles_*.sql')))
    zones = {row[0]: row for row in tables['coa_pet_zone']}
    lists = {zone: [] for zone in zones}
    for zone, entry in tables['coa_pet_zone_species']:
        if entry in species and species[entry]['wild'] and entry not in lists[zone]:
            lists[zone].append(entry)
    return zones, lists


class Situation:
    def __init__(self, upstream, base, name, seed, ground=0.0, rects=()):
        from lupa.lua51 import LuaRuntime
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.name = name
        self.rng = random.Random(seed)
        self.rolls = []
        self.setup = [f'GROUND\t0\t{ground}', f'GROUND\t530\t{ground}']
        self.setup += ['GROUND_RECT\t' + '\t'.join(str(v) for v in r) for r in rects]
        self.inputs = []
        t = self.lua.table_from
        zones = t({zone: t({'name': row[1], 'lo': row[2], 'hi': row[3], 'minMob': row[4], 'maxMob': row[5]})
                   for zone, row in base['zones'].items()})
        zone_species = t({base['zones'][zone][1]: t(entries) for zone, entries in base['lists'].items()})
        rect_tables = [t({'map': r[0], 'x1': r[1], 'y1': r[2], 'x2': r[3], 'y2': r[4],
                          'z': None if r[5] == 'none' else r[5]}) for r in rects]
        world = t({
            'displays': t({s: t(rows) for s, rows in base['world']['displays'].items()}),
            'modelInfo': t({s: t(info) for s, info in base['world']['model_info'].items()}),
            'templates': t({e: t(list(v)) for e, v in CRITTER_TEMPLATES.items()}),
            'species': t({s: t(v) for s, v in base['species'].items()}),
            'zones': zones,
            'zoneSpecies': zone_species,
            'ground': t({0: ground, 530: ground}),
            'rects': t(rect_tables),
        })
        chunk = self.lua.eval('function(source, scripts, roll, world) '
                              'return assert(loadstring(source, "@trace_wild.lua"))(scripts, roll, world) end')
        self.M = chunk((HERE / 'trace_wild.lua').read_text(encoding='utf-8'), str(Path(upstream) / 'scripts'),
                       self.roll, world)

    def roll(self, lo=None, hi=None):
        if lo is None:
            value = self.rng.random()
            self.rolls.append(f'ROLL_F\t{value!r}')
            return value
        if hi is None:
            lo, hi = 1, lo
        value = self.rng.randint(int(lo), int(hi))
        self.rolls.append(f'ROLL\t{int(lo)}\t{int(hi)}\t{value}')
        return value

    def player(self, low, zone=HELLFIRE, x=0.0, y=0.0, z=0.0, map_id=0, bot=False):
        self.M.NewPlayer(low, map_id, zone, x, y, z, bot)
        self.setup.append(f'PLAYER\t{low}\t{map_id}\t{zone}\t{x}\t{y}\t{z}\t{"bot" if bot else "human"}')

    def mob(self, guid, entry, x, y, z=0.0, level=60, map_id=0, db=True, alive=True, combat=False):
        self.M.AddMob(self.lua.table_from({'guid': guid, 'entry': entry, 'map': map_id, 'x': x, 'y': y, 'z': z,
                                           'level': level, 'db': db, 'alive': alive, 'combat': combat}))
        self.setup.append(f'MOB\t{guid}\t{entry}\t{map_id}\t{x}\t{y}\t{z}\t{level}\t{"db" if db else "script"}'
                          f'\t{"alive" if alive else "dead"}\t{"combat" if combat else "calm"}')

    def at(self, ms, *event):
        self.M.clock = ms
        self.inputs.append((len(self.M.out), ms, ' '.join(str(e) for e in event)))
        kind, args = event[0], event[1:]
        if kind == 'tick':
            self.M.Tick()
        elif kind == 'blips':
            self.M.Blips()
        elif kind == 'hello':
            self.M.Hello(*args)
        elif kind == 'select':
            self.M.Select(*args)
        elif kind == 'move':
            self.M.Move(*args)
        elif kind in ('combat', 'battle', 'alive'):
            self.M.SetState(args[0], kind, args[1] == 'on')
        elif kind == 'start':
            self.M.startOk = args[0] == 'ok'
        elif kind == 'vanish':
            self.M.Vanish(args[0])
        elif kind == 'wander':
            self.M.WanderTo(*args)
        elif kind == 'shutdown':
            self.M.Shutdown()
        else:
            raise ValueError(kind)

    def outs(self):
        return [self.M.out[i] for i in range(1, len(self.M.out) + 1)]

    def spawned(self):
        return [int(o.text.split()[1]) for o in self.outs() if o.text.startswith('spawn ')]

    def text(self, number):
        if self.M.Live() != 0 or not self.inputs or self.inputs[-1][2] != 'shutdown':
            raise RuntimeError(f'{self.name}: must end with shutdown and no wild pet')
        lines = [f'SITUATION\t{number}\t{self.name}'] + self.setup + self.rolls
        outs = self.outs()
        for index, (first, ms, event) in enumerate(self.inputs):
            last = self.inputs[index + 1][0] if index + 1 < len(self.inputs) else len(outs)
            lines.append(f'IN\t{ms}\t{event}')
            lines += [f'OUT\t{o.t}\t{o.text}' for o in outs[first:last]]
        return '\n'.join(lines) + '\n'


def situations(upstream, base, seed):
    made = []

    def new(name, **kw):
        s = Situation(upstream, base, name, seed + len(made), **kw)
        made.append(s)
        return s

    hellfire = [19189, 16907, 16578, 16842, 22461]

    s = new('fill_cap')
    s.player(1)
    for i, entry in enumerate(hellfire):
        s.mob(100 + i, entry, 10 + 5 * i, 8, level=56 + 2 * i)
    s.mob(110, 19189, -20, 5, level=60)
    s.at(5000, 'tick')
    s.at(6000, 'blips')
    s.at(10000, 'tick')
    s.at(11000, 'shutdown')

    s = new('spacing')
    s.player(1, x=0)
    s.player(2, x=120)
    s.mob(100, 19189, 20, 0)
    s.mob(101, 19189, 100, 0)
    s.mob(102, 16907, 140, 0)
    s.at(5000, 'tick')
    s.at(10000, 'tick')
    s.at(11000, 'shutdown')

    s = new('cooldown')
    s.player(1)
    s.mob(100, 19189, 8, 0)
    s.at(5000, 'tick')
    pet = s.spawned()[0]
    s.at(6000, 'wander', pet, 4.0, 1.0)
    s.at(6500, 'move', 1, 3.0, 1.0, 0.0)
    s.at(7000, 'hello', 1, pet)
    s.at(7100, 'select', 1, pet, 1)
    s.at(7200, 'battle', 1, 'on')
    s.at(9000, 'battle', 1, 'off')
    s.at(10000, 'tick')
    s.at(60000, 'tick')
    s.at(98000, 'tick')
    s.at(110000, 'tick')
    s.at(111000, 'shutdown')

    s = new('lifetime')
    s.player(1)
    s.mob(100, 16907, 8, 0)
    s.at(5000, 'tick')
    s.at(300000, 'tick')
    s.at(606000, 'tick')
    s.at(607000, 'shutdown')

    s = new('nobody_near')
    s.player(1)
    s.mob(100, 16907, 8, 0)
    s.at(5000, 'tick')
    s.at(6000, 'move', 1, 300.0, 0.0, 0.0)
    s.at(10000, 'tick')
    s.at(40000, 'tick')
    s.at(71000, 'tick')
    s.at(72000, 'shutdown')

    s = new('back_within_grace')
    s.player(1)
    s.mob(100, 16907, 8, 0)
    s.at(5000, 'tick')
    s.at(6000, 'move', 1, 300.0, 0.0, 0.0)
    s.at(10000, 'tick')
    s.at(40000, 'move', 1, 0.0, 0.0, 0.0)
    s.at(45000, 'tick')
    s.at(80000, 'tick')
    s.at(81000, 'shutdown')

    s = new('rescan_idle')
    s.player(1)
    s.mob(100, 16907, 75, 0)
    s.at(5000, 'tick')
    s.at(9000, 'move', 1, 20.0, 0.0, 0.0)
    s.at(10000, 'tick')
    s.at(55000, 'tick')
    s.at(56000, 'shutdown')

    s = new('rescan_moved')
    s.player(1)
    s.mob(100, 16907, 90, 0)
    s.at(5000, 'tick')
    s.at(9000, 'move', 1, 40.0, 0.0, 0.0)
    s.at(10000, 'tick')
    s.at(11000, 'shutdown')

    s = new('not_scanning')
    s.player(1)
    s.player(2, x=200)
    s.player(3, x=400, bot=True)
    s.player(4, x=600, zone=9999)
    s.player(5, x=800)
    s.mob(100, 16907, 8, 0)
    s.mob(101, 16907, 208, 0)
    s.mob(102, 16907, 408, 0)
    s.mob(103, 16907, 608, 0)
    s.mob(104, 16907, 808, 0)
    s.at(1000, 'alive', 1, 'off')
    s.at(1001, 'combat', 2, 'on')
    s.at(1002, 'battle', 5, 'on')
    s.at(5000, 'tick')
    s.at(6000, 'alive', 1, 'on')
    s.at(6001, 'combat', 2, 'off')
    s.at(6002, 'battle', 5, 'off')
    s.at(10000, 'tick')
    s.at(11000, 'shutdown')

    s = new('ignored_mobs')
    s.player(1)
    s.mob(100, 19189, 8, 0, combat=True)
    s.mob(101, 16907, 9, 0, alive=False)
    s.mob(102, 16578, 10, 0, db=False)
    s.mob(103, 16842, 11, 0)
    s.at(5000, 'tick')
    s.at(6000, 'shutdown')

    s = new('spawn_spots', rects=((0, -100, -100, 100, 100, 'none'), (530, -100, -100, 100, 100, 9.0)))
    s.player(1)
    s.player(2, map_id=530)
    s.mob(100, 16907, 8, 0)
    s.mob(101, 16907, 8, 0, map_id=530)
    s.mob(102, 19189, 150, 0, map_id=530)
    s.at(5000, 'tick')
    s.at(6000, 'move', 2, 150.0, 0.0, 0.0)
    s.at(10000, 'tick')
    s.at(11000, 'shutdown')

    s = new('adopt_release')
    s.player(1)
    s.mob(100, 24270, 8, 0)
    s.at(5000, 'tick')
    s.at(6000, 'blips')
    s.at(7000, 'move', 1, 300.0, 0.0, 0.0)
    s.at(10000, 'tick')
    s.at(71000, 'tick')
    s.at(72000, 'shutdown')

    s = new('adopt_consume')
    s.player(1)
    s.mob(100, 24270, 6, 0)
    s.at(5000, 'tick')
    s.at(6000, 'hello', 1, 100)
    s.at(6100, 'select', 1, 100, 1)
    s.at(7000, 'shutdown')

    s = new('adopt_refused')
    s.player(1)
    s.mob(100, 24270, 6, 0)
    s.at(5000, 'tick')
    s.at(5500, 'start', 'refused')
    s.at(6000, 'hello', 1, 100)
    s.at(6100, 'select', 1, 100, 1)
    s.at(7000, 'shutdown')

    s = new('menu')
    s.player(1)
    s.mob(100, 16907, 8, 0)
    s.mob(101, 22461, 100, 0)
    s.at(5000, 'tick')
    pet = s.spawned()[0]
    s.at(6000, 'hello', 1, 101)
    s.at(6100, 'wander', pet, 40.0, 0.0)
    s.at(6200, 'hello', 1, pet)
    s.at(6300, 'select', 1, pet, 1)
    s.at(6400, 'wander', pet, 2.0, 0.0)
    s.at(6500, 'select', 1, pet, 2)
    s.at(7000, 'shutdown')

    s = new('solo_team')
    s.player(1, zone=ELWYNN)
    s.mob(100, 80, 6, 0, level=5)
    s.at(5000, 'tick')
    pet = s.spawned()[0]
    s.at(6000, 'wander', pet, 2.0, 0.0)
    s.at(6100, 'select', 1, pet, 1)
    s.at(7000, 'shutdown')

    s = new('zone_team')
    s.player(1)
    s.mob(100, 19189, 6, 0, level=62)
    s.at(5000, 'tick')
    pet = s.spawned()[0]
    s.at(6000, 'wander', pet, 2.0, 0.0)
    s.at(6100, 'select', 1, pet, 1)
    s.at(7000, 'shutdown')

    empty = next(zone for zone, entries in sorted(base['lists'].items())
                 if not entries and base['zones'][zone][2] > 2)
    s = new('fallback_team')
    s.player(1, zone=empty)
    s.mob(100, 19189, 6, 0, level=base['zones'][empty][5])
    s.mob(101, 16907, 12, 0, level=base['zones'][empty][5])
    s.at(5000, 'tick')
    pet = s.spawned()[0]
    s.at(6000, 'wander', pet, 2.0, 0.0)
    s.at(6100, 'select', 1, pet, 1)
    s.at(7000, 'shutdown')

    s = new('blips')
    s.player(1)
    s.mob(100, 16907, 8, 0)
    s.mob(101, 19189, -8, 3)
    s.at(1000, 'blips')
    s.at(5000, 'tick')
    pets = s.spawned()
    s.at(6000, 'blips')
    s.at(6500, 'wander', pets[0], 30.0, -20.0)
    s.at(7000, 'blips')
    for i, pet in enumerate(pets):
        s.at(7100 + i, 'vanish', pet)
    s.at(8000, 'blips')
    s.at(9000, 'blips')
    s.at(10000, 'tick')
    s.at(11000, 'shutdown')

    s = new('blip_cap')
    s.player(1, x=-60)
    s.player(2, x=60)
    s.player(3, x=0)
    for i, entry in enumerate(hellfire):
        s.mob(100 + i, entry, -70 + i, 4)
        s.mob(120 + i, entry, 70 - i, -4)
    s.at(5000, 'tick')
    s.at(6000, 'blips')
    s.at(7000, 'shutdown')

    s = new('vanish')
    s.player(1)
    s.mob(100, 16907, 8, 0)
    s.mob(101, 19189, 9, 0)
    s.at(5000, 'tick')
    s.at(6000, 'vanish', s.spawned()[0])
    s.at(10000, 'tick')
    s.at(15000, 'tick')
    s.at(16000, 'shutdown')

    s = new('map_change')
    s.player(1)
    s.mob(100, 16907, 8, 0)
    s.mob(101, 19189, 8, 0, map_id=530)
    s.at(5000, 'tick')
    s.at(6000, 'move', 1, 0.0, 0.0, 0.0, 530, HELLFIRE)
    s.at(10000, 'tick')
    s.at(11000, 'blips')
    s.at(75000, 'tick')
    s.at(76000, 'shutdown')

    s = new('shutdown')
    s.player(1)
    s.mob(100, 16907, 8, 0)
    s.mob(101, 24270, 9, 0)
    s.at(5000, 'tick')
    s.at(6000, 'shutdown')

    s = new('two_challengers')
    s.player(1)
    s.player(2, x=1.0)
    s.mob(100, 16907, 6, 0)
    s.at(5000, 'tick')
    pet = s.spawned()[0]
    s.at(6000, 'wander', pet, 2.0, 0.0)
    s.at(6100, 'hello', 1, pet)
    s.at(6200, 'hello', 2, pet)
    s.at(6300, 'select', 1, pet, 1)
    s.at(6400, 'select', 2, pet, 1)
    s.at(7000, 'shutdown')
    return made


def header(base):
    lines = [f'ZONE\t{zone}\t{row[1]}\t{row[2]}\t{row[3]}\t{row[4]}\t{row[5]}' for zone, row in sorted(base['zones'].items())]
    lines += [f'ZONESPECIES\t{zone}\t' + '\t'.join(map(str, entries))
              for zone, entries in sorted(base['lists'].items()) if entries]
    lines += [f'TEMPLATE\t{entry}\t{faction}\t{flags}' for entry, (faction, flags) in sorted(CRITTER_TEMPLATES.items())]
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--upstream', required=True)
    parser.add_argument('--seed', type=int, required=True)
    parser.add_argument('--out-dir', default=str(FIXTURES))
    args = parser.parse_args()
    species = pool_species()
    zones, lists = zone_tables(species)
    base = {'world': read_world(FIXTURES / 'battle_world.txt'), 'species': species, 'zones': zones, 'lists': lists}
    text = header(base) + ''.join(s.text(n) for n, s in enumerate(situations(args.upstream, base, args.seed), 1))
    (Path(args.out_dir) / 'wild.txt').write_text(text, encoding='utf-8')


if __name__ == '__main__':
    main()
