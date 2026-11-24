import argparse
import json
import random
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import fixture_format

FIXTURES = HERE.parents[1] / 'tests' / 'fixtures'
ROUND_GUARD = 400
ATTEMPTS = 60
GM, PLAYER = 3, 0
REQUIRED = (
    'refuse_combat', 'refuse_dead', 'refuse_no_pets', 'auto_team', 'forfeit', 'watchdog', 'moved', 'died', 'map',
    'logout', 'restart', 'account', 'bot', 'capture_added', 'capture_replaced', 'capture_released', 'journal',
)
REQUIRED_OUT = ('pbt|begin', 'pbt|st', 'pbt|own', 'pbt|abil', 'pbt|in', 'pbt|tag', 'pbt|info', 'pbt|eabil',
                'pbt|turn|go', 'pbt|turn|force', 'pbt|turn|lock', 'pbt|turn|stun', 'pbt|act', 'pbt|hp', 'pbt|fnt', 'pbt|msg', 'pbt|weather', 'pbt|stip',
                'pbt|end|win', 'pbt|end|loss', 'pbt|end|interrupted', 'pbt|xp', 'pbt|done', 'pbt|got', 'pbj|pet',
                'pbj|team', 'pbj|active', 'pbj|follow', 'pbj|done', 'pbj|abl')


class Recorder:
    def __init__(self, upstream, world, seed):
        from lupa.lua51 import LuaRuntime
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.rng = random.Random(seed)
        self.rolls = []
        lua_world = self.lua.table_from({
            'displays': self.lua.table_from({species: self.lua.table_from(rows)
                                             for species, rows in world['displays'].items()}),
            'modelInfo': self.lua.table_from({species: self.lua.table_from(info)
                                              for species, info in world['model_info'].items()}),
        })
        chunk = self.lua.eval('function(source, scripts, roll, world) '
                              'return assert(loadstring(source, "@trace_battles.lua"))(scripts, roll, world) end')
        self.M = chunk((HERE / 'trace_battles.lua').read_text(encoding='utf-8'), str(Path(upstream) / 'scripts'),
                       self.roll, lua_world)
        self.players = {}
        self.seen = 0

    def roll(self, lo, hi):
        lo, hi = int(lo), int(hi)
        value = self.rng.randint(lo, hi)
        self.rolls.append((lo, hi, value))
        return value

    def player(self, low, account=1, rank=GM, bot=False):
        player = self.M.NewPlayer(low, account)
        player.state.rank = rank
        player.state.bot = bot
        self.players[low] = player
        return player

    def grant(self, player, species, level, quality=1, picks=(1, 1, 1), health=None):
        self.M.Store.AddPet(player, species, level, self.lua.table_from(list(picks)), quality, 0)
        if health is not None:
            self.M.Store.SetHp(player.GetGUIDLow(), species, health)

    def records(self):
        return list(self.M.out.values())

    def journal(self, player):
        return [dict(row.items()) for row in self.M.Journal(player).values()]

    def pump(self, until_ms):
        self.M.RunUntil(until_ms)

    def step(self):
        due = self.M.NextDue()
        if due is None:
            return False
        self.M.RunUntil(due)
        return True

    def settle(self):
        for _ in range(100000):
            if self.M.PendingOneShots() == 0:
                return
            self.step()
        raise RuntimeError('timers never settled')


def opponent_moves(text):
    payload = text.split('|', 2)[2]
    kind, cooldowns, trap = payload.split(';')[:3]
    return kind, [int(value) for value in cooldowns.split(',')], trap == '1'


def play(recorder, player, policy, stop=None):
    low = player.GetGUIDLow()
    turns = 0
    for _ in range(ROUND_GUARD * 20):
        records = recorder.records()
        while recorder.seen < len(records):
            record = records[recorder.seen]
            recorder.seen += 1
            if record.kind != 'OUT' or not record.text.startswith(f'p{low} pbt|turn|'):
                continue
            kind, cooldowns, trap = opponent_moves(record.text.split(' ', 1)[1])
            turns += 1
            if stop and stop(turns):
                return turns
            for command in policy(kind, cooldowns, trap, turns):
                recorder.M.Message(player, command)
        if not recorder.M.InBattle(player) and recorder.M.PendingOneShots() == 0:
            return turns
        if not recorder.step():
            return turns
    raise RuntimeError('battle never ended')


def random_policy(rng, trap_bias=0.5, illegal=0.15):
    def choose(kind, cooldowns, trap, turn):
        if kind == 'force':
            return [f'pbt|cmd|S{i}' for i in (1, 2, 3)]
        if kind != 'go':
            return []
        if trap and rng.random() < trap_bias:
            return ['pbt|cmd|T']
        ready = [f'pbt|cmd|A{i + 1}' for i, cd in enumerate(cooldowns) if cd == 0]
        commands = []
        if rng.random() < illegal:
            commands.append(rng.choice(['pbt|cmd|A2', 'pbt|cmd|A3', 'pbt|cmd|S1', 'pbt|cmd|T', 'pbt|cmd|X9',
                                        'pbt|cmd|', 'pbt|cmd|S9']))
        if rng.random() < 0.12:
            commands.append(rng.choice(['pbt|cmd|S2', 'pbt|cmd|S3']))
        commands.append(rng.choice(ready) if ready else 'pbt|cmd|A1')
        if rng.random() < 0.1:
            commands.append('pbt|cmd|A1')
        return commands
    return choose


def idle_policy(kind, cooldowns, trap, turn):
    return []


def species_pool():
    data = (FIXTURES / 'pet_data.txt').read_text(encoding='utf-8').splitlines()
    return sorted(int(line.split('\t')[1]) for line in data if line.startswith('coa_pet_species\t'))


def team_of(recorder, player, rng, pool, size=3, level=None):
    chosen = rng.sample(pool, size)
    for species in chosen:
        recorder.grant(player, species, level or rng.randint(3, 25), rng.randint(1, 4),
                       tuple(rng.randint(1, 2) for _ in range(3)))
    return chosen


def enemies_text(rng, pool, count, level):
    return ' '.join(f'{rng.choice(pool)}@{level}' for _ in range(count))


def session(name, upstream, world, seed, script):
    recorder = Recorder(upstream, world, seed)
    rng = random.Random(seed + 7)
    setup = script(recorder, rng)
    return name, recorder, setup


def build_sessions(upstream, world, seed, battles):
    pool = species_pool()
    out = []

    def add(name, script, offset, wanted=None):
        for attempt in range(ATTEMPTS):
            recorded = session(name, upstream, world, seed * 1000 + offset + attempt * 100000, script)
            texts = [record.text for record in recorded[1].records()]
            if not wanted or any(wanted in text for text in texts):
                out.append(recorded)
                return
        raise RuntimeError(f'session {name} never showed {wanted!r}')

    def refuse(state, note):
        def script(recorder, rng):
            player = recorder.player(7)
            team_of(recorder, player, rng, pool)
            setup = Setup(recorder, [player])
            recorder.M.SetState(player, state[0], state[1], note)
            recorder.M.Message(player, f'pbt|start|{enemies_text(rng, pool, 1, 10)}')
            recorder.settle()
            return setup
        return script

    add('refuse_combat', refuse(('combat', True), 'combat 1'), 1)
    add('refuse_dead', refuse(('alive', False), 'dead'), 2)

    def no_pets(recorder, rng):
        player = recorder.player(7)
        setup = Setup(recorder, [player])
        recorder.M.Message(player, f'pbt|start|{enemies_text(rng, pool, 1, 10)}')
        recorder.settle()
        return setup
    add('refuse_no_pets', no_pets, 3)

    def battle(enemy_count, policy_args=None, before=None, during=None, team_level=None):
        def script(recorder, rng):
            player = recorder.player(7)
            team_of(recorder, player, rng, pool, level=team_level)
            if before:
                before(recorder, rng, player)
            setup = Setup(recorder, [player])
            level = rng.randint(1, 25)
            recorder.M.Message(player, f'pbt|start|{enemies_text(rng, pool, enemy_count, level)}')
            policy = random_policy(random.Random(rng.random()), **(policy_args or {}))
            if during:
                during(recorder, rng, player, policy)
            else:
                play(recorder, player, policy)
            recorder.settle()
            return setup
        return script

    add('auto_team', battle(1), 4)

    def forfeit(recorder, rng, player, policy):
        play(recorder, player, policy, stop=lambda turns: turns >= 2)
        recorder.M.Message(player, 'pbt|quit')
        recorder.M.Message(player, 'pbt|quit')
    add('forfeit', battle(3, during=forfeit), 5)

    def watchdog(recorder, rng, player, policy):
        play(recorder, player, idle_policy, stop=lambda turns: turns >= 1)
        recorder.pump(recorder.M.clock + 310_000)
    add('watchdog', battle(1, during=watchdog), 6)

    def interrupt(state, value, note):
        def during(recorder, rng, player, policy):
            play(recorder, player, policy, stop=lambda turns: turns >= 2)
            recorder.M.SetState(player, state, value, note)
            recorder.pump(recorder.M.clock + 6_000)
        return during
    add('moved', battle(1, during=interrupt('distance', 41, 'move 41')), 7)
    add('died', battle(1, during=interrupt('alive', False, 'dead')), 8)
    add('map', battle(1, during=interrupt('map', 1, 'map 1')), 9)

    def logout(recorder, rng, player, policy):
        play(recorder, player, policy, stop=lambda turns: turns >= 2)
        recorder.M.LogoutForfeit(player)
    add('logout', battle(2, during=logout), 10)

    def restart(recorder, rng, player, policy):
        play(recorder, player, policy, stop=lambda turns: turns >= 2)
        recorder.M.Message(player, f'pbt|start|{enemies_text(rng, pool, 1, 12)}')
        play(recorder, player, policy)
    add('restart', battle(1, during=restart), 11)

    def account(recorder, rng):
        first = recorder.player(7)
        second = recorder.player(8)
        team_of(recorder, first, rng, pool)
        setup = Setup(recorder, [first, second])
        recorder.M.Message(first, f'pbt|start|{enemies_text(rng, pool, 1, 10)}')
        play(recorder, first, random_policy(random.Random(rng.random())), stop=lambda turns: turns >= 1)
        recorder.M.Message(second, f'pbt|start|{enemies_text(rng, pool, 1, 10)}')
        recorder.M.Message(first, 'pbt|quit')
        recorder.settle()
        return setup
    add('account', account, 12)

    def bot(recorder, rng):
        player = recorder.player(9, account=3, bot=True)
        team_of(recorder, player, rng, pool)
        setup = Setup(recorder, [player])
        recorder.M.Message(player, f'pbt|start|{enemies_text(rng, pool, 1, 10)}')
        recorder.M.Message(player, 'pbj|list')
        recorder.settle()
        return setup
    add('bot', bot, 13)

    def capture(owned):
        def script(recorder, rng):
            player = recorder.player(7)
            enemy = rng.choice(pool)
            team = [species for species in rng.sample(pool, 4) if species != enemy][:3]
            for species in team:
                recorder.grant(player, species, 8, 1)
            if owned == 'better':
                recorder.grant(player, enemy, 25, 4)
            elif owned == 'worse':
                recorder.grant(player, enemy, 1, 1)
            setup = Setup(recorder, [player])
            recorder.M.Message(player, f'pbj|setteam|1,{team[0]},{team[1]},{team[2]}')
            recorder.M.Message(player, f'pbt|start|{enemy}@8')
            play(recorder, player, random_policy(random.Random(rng.random()), trap_bias=1.0, illegal=0.0))
            recorder.settle()
            return setup
        return script
    add('capture_added', capture(None), 14, 'pbt|got|')
    add('capture_replaced', capture('worse'), 15, 'It replaces the one you had.')
    add('capture_released', capture('better'), 16, 'so it was released')

    def journal(recorder, rng):
        player = recorder.player(7)
        owned = team_of(recorder, player, rng, pool)
        setup = Setup(recorder, [player])
        unowned = next(species for species in pool if species not in owned)
        for text in ('pbj|list', f'pbj|abil|{owned[0]}', f'pbj|abil|{unowned}', 'pbj|abil|0', 'pbj|abil|x',
                     f'pbj|setabil|{owned[1]},2,2', f'pbj|setabil|{owned[1]},4,1', f'pbj|setabil|{unowned},1,2',
                     f'pbj|setteam|2,{owned[0]},{owned[1]},0', f'pbj|setteam|2,{owned[0]},{owned[0]},0',
                     f'pbj|setteam|3,{unowned},0,0', 'pbj|setteam|4,0,0,0', 'pbj|setteam|x', 'pbj|active|2',
                     'pbj|active|5', 'pbj|active|', 'pbj|list'):
            recorder.M.Message(player, text)
        recorder.settle()
        return setup
    add('journal', journal, 17)

    for index in range(battles):
        size = 1 if index % 3 == 0 else 3
        add(f'battle_{index + 1}', battle(size, team_level=None), 100 + index)
    return out


class Setup:
    def __init__(self, recorder, players):
        self.players = [(player.GetGUIDLow(), int(player.state.account), int(player.state.rank),
                         1 if player.state.bot else 0, recorder.journal(player)) for player in players]
        self.teams = {}
        recorder.M.Reset()
        recorder.rolls.clear()
        recorder.seen = 0


def journal_line(tag, low, row):
    return '\t'.join([tag, f'p{low}'] + [str(int(row[key])) for key in
                                          ('species', 'level', 'xp', 'a1', 'a2', 'a3', 'quality', 'display', 'hp',
                                           'hpAt')])


def write_session(number, name, recorder, setup):
    lines = [f'SESSION\t{number}\t{name}']
    for low, account, rank, bot, journal in setup.players:
        lines.append(f'PLAYER\tp{low}\t{account}\t{rank}\t{bot}')
        lines += [journal_line('JOURNAL', low, row) for row in journal]
    lines += [f'ROLL\t{lo}\t{hi}\t{value}' for lo, hi, value in recorder.rolls]
    for record in recorder.records():
        lines.append(f'{record.kind}\t{int(record.t)}\t{fixture_format.encode_field(record.text)}')
    for low, *_ in setup.players:
        lines += [journal_line('JOURNAL_AFTER', low, row) for row in recorder.journal(recorder.players[low])]
    lines.append('END')
    return '\n'.join(lines) + '\n'


def world_from_database(defaults, species):
    def query(sql):
        output = subprocess.run(['mysql', f'--defaults-extra-file={defaults}', '-N', '-B', '-e', sql], check=True,
                                capture_output=True, text=True).stdout
        return [line.split('\t') for line in output.splitlines() if line]
    entries = ','.join(map(str, species))
    displays = {}
    for creature, display in query('SELECT `CreatureID`, `CreatureDisplayID` FROM `acore_world`.`creature_template_model` '
                                   f'WHERE `CreatureID` IN ({entries}) ORDER BY `CreatureID`, `Idx`'):
        displays.setdefault(int(creature), []).append(int(display))
    model_info = {}
    for creature, radius, reach in query(
            'SELECT m.`CreatureID`, i.`BoundingRadius`, i.`CombatReach` FROM `acore_world`.`creature_template_model` m '
            'JOIN `acore_world`.`creature_model_info` i ON i.`DisplayID` = m.`CreatureDisplayID` '
            f'WHERE m.`CreatureID` IN ({entries}) AND m.`Idx` = 0'):
        model_info[int(creature)] = [float(radius), float(reach)]
    return {'displays': displays, 'model_info': model_info}


def read_world(path):
    world = {'displays': {}, 'model_info': {}}
    for line in path.read_text(encoding='utf-8').splitlines():
        fields = line.split('\t')
        if fields[0] == 'DISPLAYS':
            world['displays'][int(fields[1])] = [int(value) for value in fields[2:]]
        elif fields[0] == 'MODELINFO':
            world['model_info'][int(fields[1])] = [float(fields[2]), float(fields[3])]
    return world


def sizes_from_sql(world):
    import sql_reader
    root = HERE.parents[3] / 'data/sql/updates/pending_db_world'
    tables = sql_reader.read(sorted(root.glob('rev_2026112[34]_*_coa_pet_battles_*.sql')))
    species = set(world['displays']) | set(world['model_info'])
    displays = {display for rows in world['displays'].values() for display in rows}
    models = [row for row in tables['coa_pet_model_size'] if row[0] in species]
    shown = [row for row in tables['coa_pet_display_size'] if row[0] in displays]
    return sorted(models), sorted(shown)


def write_world(path, world):
    lines = [f'DISPLAYS\t{species}\t' + '\t'.join(map(str, rows)) for species, rows in sorted(world['displays'].items())]
    lines += [f'MODELINFO\t{species}\t{fixture_format.value_text(info[0])}\t{fixture_format.value_text(info[1])}'
              for species, info in sorted(world['model_info'].items())]
    models, shown = sizes_from_sql(world)
    lines += ['MODELSIZE\t' + '\t'.join(fixture_format.value_text(value) for value in row) for row in models]
    lines += ['DISPLAYSIZE\t' + '\t'.join(fixture_format.value_text(value) for value in row) for row in shown]
    path.write_text('\n'.join(lines) + '\n', encoding='utf-8')


def coverage_failures(text):
    names = {line.split('\t')[2] for line in text.splitlines() if line.startswith('SESSION\t')}
    failures = [f'session {name} missing' for name in REQUIRED if name not in names]
    outs = [line.split('\t', 2)[2].split(' ', 1)[1] for line in text.splitlines() if line.startswith('OUT\t')]
    failures += [f'no {kind} message' for kind in REQUIRED_OUT if not any(out.startswith(kind) for out in outs)]
    failures += [f'TOOLONG record: {line[:80]}' for line in text.splitlines() if line.startswith('TOOLONG\t')]
    return failures


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--upstream', required=True)
    parser.add_argument('--seed', type=int, required=True)
    parser.add_argument('--battles', type=int, required=True)
    parser.add_argument('--mysql-defaults')
    parser.add_argument('--out-dir', default=str(FIXTURES))
    args = parser.parse_args()
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    world_path = out_dir / 'battle_world.txt'
    if args.mysql_defaults:
        write_world(world_path, world_from_database(args.mysql_defaults, species_pool()))
    world = read_world(world_path)
    write_world(world_path, world)
    sessions = build_sessions(args.upstream, world, args.seed, args.battles)
    text = ''.join(write_session(number, name, recorder, setup)
                   for number, (name, recorder, setup) in enumerate(sessions, 1))
    (out_dir / 'sessions.txt').write_text(text, encoding='utf-8')
    failures = coverage_failures(text)
    print(json.dumps({'sessions': len(sessions), 'bytes': len(text.encode('utf-8')), 'failures': failures}, indent=1))
    sys.exit(1 if failures else 0)


if __name__ == '__main__':
    main()
