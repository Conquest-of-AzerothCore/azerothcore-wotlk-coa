import json
from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def persistence():
    source = (ROOT / 'src/server/database/Database/Implementation/CharacterDatabase.cpp').read_text(encoding='utf-8')
    queries = {}
    for name, body in re.findall(r'PrepareStatement\((CHAR_[A-Z_]*LOTTERY[A-Z_]*),\s*(.*?)\s*,\s*CONNECTION_[A-Z]+\);',
                                 source, re.S):
        queries[name] = ''.join(json.loads(literal) for literal in re.findall(r'"(?:\\.|[^"\\])*"', body))
    db = sqlite3.connect(':memory:')
    db.executescript('''
        CREATE TABLE characters(guid INTEGER PRIMARY KEY, money INTEGER, name TEXT, account INTEGER, deleteDate INTEGER);
        CREATE TABLE mail(id INTEGER PRIMARY KEY, receiver INTEGER, money INTEGER);
        CREATE TABLE item_instance(guid INTEGER PRIMARY KEY, itemEntry INTEGER, owner_guid INTEGER);
        CREATE TABLE mail_items(mail_id INTEGER, item_guid INTEGER UNIQUE, receiver INTEGER);
        INSERT INTO characters VALUES(10,1000000,'FirstWinner',42,NULL),(20,1000000,'Other',43,NULL);
    ''')
    migration = ROOT / 'data/sql/updates/pending_db_characters/rev_20261009_01_coa_lottery.sql'
    character_sql = migration.read_text(encoding='utf-8')
    character_sql = re.sub(r'TINYINT UNSIGNED|BIGINT UNSIGNED|INT UNSIGNED', 'INTEGER', character_sql)
    character_sql = re.sub(r',\s*KEY `[^`]+` \([^)]*\)', '', character_sql)
    character_sql = character_sql.replace('UNIQUE KEY `one_active_round`', 'UNIQUE')
    character_sql = character_sql.replace(' ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', '')
    character_sql = character_sql.replace('INSERT IGNORE', 'INSERT OR IGNORE')
    db.executescript(character_sql)
    db.execute(queries['CHAR_INS_LOTTERY_ROUND'], (1, 604800, 0, 0, 100, 604800, 97393, 0))
    db.commit()
    upsert = queries['CHAR_UPSERT_LOTTERY_ENTRY'].replace(
        'ON DUPLICATE KEY UPDATE', 'ON CONFLICT(round_id,guid) DO UPDATE SET')
    upsert = re.sub(r'VALUES\((tickets|spent_copper|pot_copper)\)', r'excluded.\1', upsert)

    def buy(fail):
        try:
            with db:
                db.execute('UPDATE characters SET money=900000 WHERE guid=10')
                db.execute(upsert, (1, 10, 1, 100000, 100000))
                if fail:
                    raise RuntimeError('simulated disconnect before pot save')
                db.execute(queries['CHAR_UPD_LOTTERY_POT'], (100000, 1))
        except RuntimeError:
            pass

    buy(True)
    assert db.execute('SELECT money FROM characters WHERE guid=10').fetchone() == (1000000,)
    assert not db.execute('SELECT * FROM coa_lottery_entry').fetchall()
    assert db.execute(queries['CHAR_SEL_LOTTERY_ROUND']).fetchone()[2] == 0
    buy(False)
    assert db.execute('SELECT money FROM characters WHERE guid=10').fetchone() == (900000,)
    assert db.execute(queries['CHAR_SEL_LOTTERY_ENTRIES'], (1,)).fetchall() == [(10, 1)]

    def draw(fail):
        try:
            with db:
                db.execute('INSERT INTO mail VALUES(1,10,100000)')
                db.execute('INSERT INTO item_instance VALUES(1,97393,10)')
                db.execute('INSERT INTO mail_items VALUES(1,1,10)')
                name, account = db.execute(queries['CHAR_SEL_LOTTERY_WINNER_IDENTITY'], (10,)).fetchone()
                db.execute(queries['CHAR_INS_LOTTERY_WINNER'],
                    (1, 604900, 10, account, name, 100000, 97393, 'Sigil of Goldilocks', 1, 1, 1, 0, 0, 0, 0))
                db.execute(queries['CHAR_COMPLETE_LOTTERY_ROUND'], (10, 1, 1))
                if fail:
                    raise RuntimeError('simulated disconnect before next round')
                db.execute(queries['CHAR_INS_LOTTERY_ROUND'], (2, 1209600, 0, 0, 100, 604800, 98073, 0))
        except RuntimeError:
            pass

    draw(True)
    assert not db.execute('SELECT * FROM coa_lottery_winner').fetchall()
    assert not db.execute('SELECT * FROM mail').fetchall()
    assert not db.execute('SELECT * FROM item_instance').fetchall()
    assert not db.execute('SELECT * FROM mail_items').fetchall()
    loaded = db.execute(queries['CHAR_SEL_LOTTERY_ROUND']).fetchone()
    assert loaded[0] == 1 and loaded[6] == 97393
    draw(False)
    loaded = db.execute(queries['CHAR_SEL_LOTTERY_ROUND']).fetchone()
    assert loaded[0] == 2 and loaded[6] == 98073
    assert db.execute('SELECT bonus_item FROM coa_lottery_round WHERE id=1').fetchone() == (97393,)
    assert db.execute('SELECT * FROM item_instance').fetchall() == [(1, 97393, 10)]
    assert db.execute('SELECT * FROM mail_items').fetchall() == [(1, 1, 10)]
    assert db.execute('SELECT winner_guid,payout_mail_id FROM coa_lottery_round WHERE id=1').fetchone() == (10, 1)
    assert db.execute('SELECT * FROM mail').fetchall() == [(1, 10, 100000)]
    db.execute(upsert, (2, 20, 1, 100000, 100000))
    db.execute("UPDATE characters SET deleteDate=1,name='',account=0 WHERE guid=20")
    assert db.execute(queries['CHAR_SEL_LOTTERY_WINNER_IDENTITY'], (20,)).fetchone() is None
    assert db.execute(queries['CHAR_SEL_LOTTERY_ENTRIES'], (2,)).fetchall() == [(None, None)]
    db.execute('DELETE FROM characters WHERE guid=20')
    assert db.execute(queries['CHAR_SEL_LOTTERY_ENTRIES'], (2,)).fetchall() == [(None, None)]
    assert db.execute(queries['CHAR_SEL_LOTTERY_WINNER_IDENTITY'], (20,)).fetchone() is None
    assert db.execute('SELECT COUNT(*) FROM coa_lottery_round WHERE active=1').fetchone() == (1,)
    expected_winner = (1, 604900, 10, 42, 'FirstWinner', 100000, 97393, 'Sigil of Goldilocks', 1, 1, 1, 0, 0, 0, 0)
    assert db.execute('SELECT * FROM coa_lottery_winner').fetchall() == [expected_winner]
    db.execute("UPDATE characters SET name='Renamed' WHERE guid=10")
    db.execute('DELETE FROM characters WHERE guid=10')
    assert db.execute(queries['CHAR_SEL_LOTTERY_WINNER_IDENTITY'], (10,)).fetchone() is None
    assert db.execute(queries['CHAR_SEL_LOTTERY_ENTRIES'], (1,)).fetchall() == [(None, None)]
    db.execute('DELETE FROM mail WHERE id=1')
    db.commit()
    assert db.execute('SELECT * FROM coa_lottery_winner').fetchall() == [expected_winner]
    try:
        with db:
            db.execute(queries['CHAR_INS_LOTTERY_WINNER'], expected_winner)
    except sqlite3.IntegrityError:
        pass
    else:
        raise AssertionError('duplicate winner record accepted')
    assert db.execute('SELECT COUNT(*) FROM coa_lottery_winner').fetchone() == (1,)
    print('PASS: winner snapshots survive renames/deletion/mail cleanup, atomic rollback, one winner per round')
    db.execute('UPDATE coa_lottery_round SET pot=10100000,fake_tickets=100 WHERE id=2')
    db.commit()
    assert db.execute(queries['CHAR_SEL_LOTTERY_ROUND']).fetchone()[7] == 100
    house_record = (2, 1209700, 0, 0, 'Trade Prince Gallywix', 10100000, 0, '', 100, 100, 0, 1, 10100000, 0, 0)
    item_count = db.execute('SELECT COUNT(*) FROM item_instance').fetchone()
    attachment_count = db.execute('SELECT COUNT(*) FROM mail_items').fetchone()

    def house_draw(fail):
        try:
            with db:
                db.execute(queries['CHAR_INS_LOTTERY_WINNER'], house_record)
                db.execute(queries['CHAR_COMPLETE_LOTTERY_ROUND'], (0, 0, 2))
                if fail:
                    raise RuntimeError('simulated failure before house next round')
                db.execute(queries['CHAR_INS_LOTTERY_ROUND'], (3, 1814500, 10000000, 0, 100, 604800, 97393, 100))
        except RuntimeError:
            pass

    house_draw(True)
    assert db.execute(queries['CHAR_SEL_LOTTERY_ROUND']).fetchone()[0] == 2
    assert db.execute('SELECT COUNT(*) FROM coa_lottery_winner WHERE house_win=1').fetchone() == (0,)
    house_draw(False)
    assert db.execute('SELECT * FROM coa_lottery_winner WHERE house_win=1').fetchone() == house_record
    assert db.execute('SELECT winner_guid,payout_mail_id,active FROM coa_lottery_round WHERE id=2').fetchone() == (0, 0, None)
    next_round = db.execute(queries['CHAR_SEL_LOTTERY_ROUND']).fetchone()
    assert next_round[0] == 3 and next_round[2] == 10000000 and next_round[7] == 100
    assert not db.execute('SELECT * FROM mail').fetchall()
    assert db.execute('SELECT COUNT(*) FROM item_instance').fetchone() == item_count
    assert db.execute('SELECT COUNT(*) FROM mail_items').fetchone() == attachment_count
    assert db.execute('SELECT COUNT(*) FROM coa_lottery_round WHERE active=1').fetchone() == (1,)
    print('PASS: persistent house tickets, Gallywix identity, destroyed pot, no mail/item payout, rollback and reseed')

    ledger = db.execute(queries['CHAR_SEL_LOTTERY_RECENT_WINNERS']).fetchall()
    assert ledger == [('Trade Prince Gallywix', 10100000, 100, 1, 0), ('FirstWinner', 100000, 1, 0, 0)]
    for identifier in range(10, 16):
        record = (identifier, 2000000, 0, 0, 'Trade Prince Gallywix', 10000000, 0, '', 100, 100, 0, 1, 10000000, 0, 0)
        db.execute(queries['CHAR_INS_LOTTERY_WINNER'], record)
    ledger = db.execute(queries['CHAR_SEL_LOTTERY_RECENT_WINNERS']).fetchall()
    assert len(ledger) == 5 and all(row[0] == 'Trade Prince Gallywix' for row in ledger)
    print('PASS: recent winner query, preserved names after deletion, house tickets, bounded newest-first ledger')
    prepared = re.search(r'PrepareStatement\(CHAR_INS_ACCOUNT_VANITY_COLLECTION,\s*"([^"]+)"', source).group(1)
    db.execute('CREATE TABLE account_vanity_collection(account_id INTEGER, item_id INTEGER, PRIMARY KEY(account_id,item_id))')
    prepared = prepared.replace('INSERT IGNORE', 'INSERT OR IGNORE')
    db.execute(prepared, (42, 97393))
    db.execute(prepared, (42, 97393))
    db.commit()
    assert db.execute('SELECT item_id FROM account_vanity_collection WHERE account_id=42').fetchall() == [(97393,)]
    assert not db.execute('SELECT item_id FROM account_vanity_collection WHERE account_id=43').fetchall()
    db.execute("INSERT INTO characters VALUES(60,1000000,'Refundee',60,NULL),(70,1000000,'OtherRefundee',70,NULL)")
    db.execute(queries['CHAR_COMPLETE_LOTTERY_ROUND'], (0,0,3))
    db.execute(queries['CHAR_INS_LOTTERY_ROUND'], (400,9000000,10100000,0,25,604800,97393,100))
    db.execute(upsert, (400,60,2,200000,50000))
    db.execute(upsert, (400,70,1,100000,25000))
    db.execute(upsert, (400,80,1,100000,25000))
    db.execute(upsert, (399,60,99,9900000,2475000))
    db.commit()
    admin_entries = db.execute(queries['CHAR_SEL_LOTTERY_ADMIN_ENTRIES'], (400,)).fetchall()
    assert admin_entries == [(60,2,200000,50000,'Refundee',60,None),
                             (70,1,100000,25000,'OtherRefundee',70,None),(80,1,100000,25000,None,None,None)]
    try:
        with db:
            db.execute('INSERT INTO mail VALUES(100,60,200000)')
            db.execute(queries['CHAR_DEL_LOTTERY_ENTRY'], (400,60))
            db.execute(queries['CHAR_UPD_LOTTERY_POT'], (10050000,400))
            raise RuntimeError('refund commit failure')
    except RuntimeError:
        pass
    assert not db.execute('SELECT * FROM mail').fetchall()
    assert db.execute(queries['CHAR_SEL_LOTTERY_ADMIN_ENTRIES'], (400,)).fetchall() == admin_entries
    with db:
        db.execute('INSERT INTO mail VALUES(100,60,200000)')
        db.execute(queries['CHAR_DEL_LOTTERY_ENTRY'], (400,60))
        db.execute(queries['CHAR_UPD_LOTTERY_POT'], (10050000,400))
    assert db.execute('SELECT tickets FROM coa_lottery_entry WHERE round_id=399').fetchone() == (99,)
    assert db.execute('SELECT money FROM mail WHERE id=100').fetchone() == (200000,)
    assert db.execute(queries['CHAR_SEL_LOTTERY_ROUND']).fetchone()[2] == 10050000
    with db:
        db.execute(queries['CHAR_UPD_LOTTERY_PAUSE'], (1,12345,9000000,400))
        db.execute(queries['CHAR_UPD_LOTTERY_CONTROL'], (0,1))
    assert db.execute(queries['CHAR_SEL_LOTTERY_CONTROL']).fetchone() == (0,1)
    assert db.execute(queries['CHAR_SEL_LOTTERY_ROUND']).fetchone()[8:] == (1,12345)
    with db:
        db.execute(queries['CHAR_CANCEL_LOTTERY_ROUND'], (400,))
        db.execute(queries['CHAR_UPD_LOTTERY_CONTROL'], (0,0))
    assert db.execute(queries['CHAR_SEL_LOTTERY_ROUND']).fetchone() is None
    assert db.execute(queries['CHAR_SEL_LOTTERY_CONTROL']).fetchone() == (0,0)
    assert db.execute(queries['CHAR_SEL_LOTTERY_NEXT_ID']).fetchone() == (401,)
    assert not db.execute('SELECT * FROM coa_lottery_winner WHERE round_id=400').fetchall()
    world_db = sqlite3.connect(':memory:')
    world_db.execute('CREATE TABLE command(name TEXT PRIMARY KEY, security INTEGER, help TEXT)')
    world_sql = (ROOT / 'data/sql/updates/pending_db_world/rev_20261009_01_coa_lottery.sql').read_text(encoding='utf-8')
    world_db.executescript('''
        CREATE TABLE creature_template(entry INTEGER PRIMARY KEY, name TEXT, subname TEXT, minlevel INTEGER,
            maxlevel INTEGER, faction INTEGER, npcflag INTEGER, unit_class INTEGER, type INTEGER,
            HealthModifier REAL, ManaModifier REAL, ScriptName TEXT DEFAULT '', AIName TEXT);
        CREATE TABLE creature_template_model(CreatureID INTEGER, Idx INTEGER, CreatureDisplayID INTEGER,
            DisplayScale REAL, Probability REAL, VerifiedBuild INTEGER, PRIMARY KEY(CreatureID,Idx));
        CREATE TABLE item_template(entry INTEGER PRIMARY KEY, class INTEGER, subclass INTEGER, name TEXT,
            displayid INTEGER, Quality INTEGER, Flags INTEGER, ItemLevel INTEGER, bonding INTEGER,
            spellid_1 INTEGER, spelltrigger_1 INTEGER, spellcharges_1 INTEGER, spellid_2 INTEGER,
            spelltrigger_2 INTEGER, description TEXT, BagFamily INTEGER);
        CREATE TABLE creature_template_movement(CreatureId INTEGER PRIMARY KEY, Ground INTEGER, Flight INTEGER);
    ''')
    translated_world = world_sql.replace('INSERT IGNORE', 'INSERT OR IGNORE')
    translated_world = translated_world.replace('ON DUPLICATE KEY UPDATE', 'ON CONFLICT(entry) DO UPDATE SET')
    translated_world = re.sub(r'VALUES\((`[^`]+`)\)', r'excluded.\1', translated_world)
    world_db.executescript(translated_world)
    world_db.executescript(translated_world)
    assert world_db.execute('SELECT CreatureDisplayID,DisplayScale FROM creature_template_model WHERE CreatureID=80541').fetchone() == (89251,0.33)
    assert world_db.execute('SELECT Ground,Flight FROM creature_template_movement WHERE CreatureId=80541').fetchone() == (1,0)
    assert world_db.execute('SELECT spellid_1,spelltrigger_1,spellcharges_1,spellid_2,spelltrigger_2 FROM item_template WHERE entry=97393').fetchone() == (55884,0,-1,92453,6)
    before = db.execute('SELECT * FROM coa_lottery_entry ORDER BY round_id,guid').fetchall()
    control = db.execute(queries['CHAR_SEL_LOTTERY_CONTROL']).fetchone()
    winners = db.execute('SELECT * FROM coa_lottery_winner ORDER BY round_id').fetchall()
    db.executescript(character_sql)
    assert db.execute('SELECT * FROM coa_lottery_entry ORDER BY round_id,guid').fetchall() == before
    assert db.execute(queries['CHAR_SEL_LOTTERY_CONTROL']).fetchone() == control
    assert db.execute('SELECT * FROM coa_lottery_winner ORDER BY round_id').fetchall() == winners
    assert "(80541, 0, 89251, 0.33, 1, 12340)" in world_sql
    assert "VALUES (80541, 1, 0)" in world_sql
    assert world_db.execute('SELECT COUNT(*) FROM command WHERE security=2').fetchone() == (11,)
    assert all(help_text.startswith('Syntax: .lottery') for (help_text,) in world_db.execute('SELECT help FROM command'))
    print('PASS: consolidated schema, preserved entries/history/control on reapply, final pet scale/ground movement, commands and rollback')
    print('PASS: account prize persistence and duplicate claims')
    print('PASS: purchase and payout rollback, committed round recovery, deleted-character eligibility')


def main():
    persistence()
    companion = (ROOT / 'src/server/coa/AscensionCompat.cpp').read_text(encoding='utf-8')
    method = companion[companion.index('    std::vector<uint32> GetMissingOwnedCompanionSpells('):
                       companion.index('    void QueueOwnedCompanionSpells(')]
    lottery_source = (ROOT / 'modules/mod-coa-lottery/src/CoALottery.cpp').read_text(encoding='utf-8')
    commands_code = (HERE / 'commands-harness.cpp').read_text(encoding='utf-8')
    world_update = lottery_source[lottery_source.index('        void OnUpdate(uint32 diff) override'):
                                 lottery_source.index('    struct LotteryAdminEntry')]
    world_update = world_update[:world_update.rindex('    };')].replace(' override', '')
    commands_code = commands_code.replace('WORLD_UPDATE_METHOD', world_update)
    structs = lottery_source[lottery_source.index('    struct LotterySettings'):
                             lottery_source.index('    constexpr uint32 GallywixMenuId')]
    round_methods = lottery_source[lottery_source.index('    LotteryRound NewRound('):
                                   lottery_source.index('    void PublishMail(')]
    draw_method = lottery_source[lottery_source.index('    bool DrawIfDue('):
                                lottery_source.index('    void Show(Player*')]
    commands = lottery_source[lottery_source.index('    struct LotteryAdminEntry'):
                              lottery_source.index('    class LotteryNPC')]
    statements = (ROOT / 'src/server/database/Database/Implementation/CharacterDatabase.cpp').read_text(encoding='utf-8')
    enums = re.findall(r'PrepareStatement\((CHAR_[A-Z_]*LOTTERY[A-Z_]*)', statements)
    for marker, value in [('LOTTERY_STRUCTS', structs), ('ROUND_METHODS', round_methods),
                          ('DRAW_METHOD', draw_method), ('COMMAND_METHODS', commands),
                          ('STATEMENT_ENUMS', ',\n    '.join(enums) + ','),
                          ('RULES_HEADER', (ROOT / 'modules/mod-coa-lottery/src/CoALotteryRules.h').as_posix())]:
        commands_code = commands_code.replace(marker, value)
    deletion_code = (HERE / 'deletion-harness.cpp').read_text(encoding='utf-8')
    draw_prefix = lottery_source[lottery_source.index('    bool DrawIfDue('):
                                 lottery_source.index('        std::unique_ptr<Item> bonus;')]
    draw_prefix += '        (void)winnerAccount; ++attempts; if (houseWin) ++houseDraws; return true;\n    }\n'
    deletion_code = deletion_code.replace('DRAW_PREFIX', draw_prefix)
    deletion_code = deletion_code.replace('RULES_HEADER',
        (ROOT / 'modules/mod-coa-lottery/src/CoALotteryRules.h').as_posix())
    advertising_code = (HERE / 'advertising-harness.cpp').read_text(encoding='utf-8')
    advertiser = lottery_source[lottery_source.index('    class LotteryAdvertiser'):
                                lottery_source.index('    void ShowGallywix(')]
    advertising_code = advertising_code.replace('ADVERTISER_CLASS', advertiser)
    advertising_code = advertising_code.replace('ADVERTISING_HEADER',
        (ROOT / 'modules/mod-coa-lottery/src/CoALotteryAdvertising.h').as_posix())
    advertising_code = advertising_code.replace('RULES_HEADER',
        (ROOT / 'modules/mod-coa-lottery/src/CoALotteryRules.h').as_posix())
    gossip_code = (HERE / 'gossip-harness.cpp').read_text(encoding='utf-8')
    gallywix_method = lottery_source[lottery_source.index('    void ShowGallywix('):lottery_source.index('    class LotteryWorld')]
    gallywix_method = gallywix_method.replace('    LotteryCities advertiser;\n\n', '')
    hello_method = lottery_source[lottery_source.index('        bool OnGossipHello('):lottery_source.index('        bool OnGossipSelect(')]
    select_method = lottery_source[lottery_source.index('        bool OnGossipSelect('):
                              lottery_source.index('            uint32 tickets = Options[action - 1].tickets;')]
    select_method += '            ++purchases; return true;\n        }\n'
    gossip_code = gossip_code.replace('GALLYWIX_METHOD', gallywix_method)
    gossip_code = gossip_code.replace('HELLO_METHOD', hello_method.replace(' override', ''))
    gossip_code = gossip_code.replace('SELECT_METHOD', select_method.replace(' override', ''))
    gossip_code = gossip_code.replace('RULES_HEADER', (ROOT / 'modules/mod-coa-lottery/src/CoALotteryRules.h').as_posix())
    companion_code = (HERE / 'companion-harness.cpp').read_text(encoding='utf-8')
    companion_code = companion_code.replace('COMPANION_METHOD', method)
    companion_code = companion_code.replace('COLLECTIBLES_HEADER',
        (ROOT / 'src/server/coa/AscensionCollectibleSpellData.h').as_posix())
    gossip = (ROOT / 'src/server/game/Entities/Creature/GossipDef.cpp').read_text(encoding='utf-8')
    methods = gossip[gossip.index('void PlayerMenu::ClearDynamicGossipText()'):
                     gossip.index('void PlayerMenu::SendGossipMenu(uint32')]
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8').replace('DYNAMIC_METHODS', methods)
    code = code.replace('RULES_HEADER', (ROOT / 'modules/mod-coa-lottery/src/CoALotteryRules.h').as_posix())
    with tempfile.TemporaryDirectory(prefix='coa-lottery-') as directory:
        out = Path(directory)
        (out / 'harness.cpp').write_text(code, encoding='utf-8')
        (out / 'companion.cpp').write_text(companion_code, encoding='utf-8')
        (out / 'gossip.cpp').write_text(gossip_code, encoding='utf-8')
        (out / 'advertising.cpp').write_text(advertising_code, encoding='utf-8')
        (out / 'deletion.cpp').write_text(deletion_code, encoding='utf-8')
        (out / 'commands.cpp').write_text(commands_code, encoding='utf-8')
        for filename in ('TaskScheduler.h', 'TaskScheduler.cpp'):
            (out / filename).write_text((ROOT / 'src/common/Utilities' / filename).read_text(encoding='utf-8'), encoding='utf-8')
        (out / 'Util.h').write_text("#pragma once\n#include <algorithm>\n#include <cstdint>\n#include <chrono>\nusing uint32=uint32_t;\nusing Milliseconds=std::chrono::milliseconds;\ninline uint32 urand(uint32 low, uint32 high) {static uint32 seed=17; seed=seed*1664525+1013904223; return low+seed%(high-low+1);}\n", encoding='utf-8')
        (out / 'Errors.h').write_text('#pragma once\n#include <cassert>\n#define ASSERT(value) assert(value)\n', encoding='utf-8')
        (out / 'CMakeLists.txt').write_text('''cmake_minimum_required(VERSION 3.20)
project(CoALotteryHarness LANGUAGES CXX)
add_executable(lottery harness.cpp)
target_compile_features(lottery PRIVATE cxx_std_20)
add_executable(companion companion.cpp)
target_compile_features(companion PRIVATE cxx_std_20)
add_executable(gossip gossip.cpp)
target_compile_features(gossip PRIVATE cxx_std_20)
add_executable(advertising advertising.cpp TaskScheduler.cpp)
target_compile_features(advertising PRIVATE cxx_std_20)
add_executable(commands commands.cpp)
target_compile_features(commands PRIVATE cxx_std_20)
add_executable(deletion deletion.cpp)
target_compile_features(deletion PRIVATE cxx_std_20)
if(MSVC)
  target_compile_options(lottery PRIVATE /W4 /WX /EHsc /utf-8)
  target_compile_options(companion PRIVATE /W4 /WX /EHsc /utf-8)
  target_compile_options(gossip PRIVATE /W4 /WX /EHsc /utf-8)
  target_compile_options(advertising PRIVATE /W4 /WX /EHsc /utf-8)
  target_compile_options(commands PRIVATE /W4 /WX /EHsc /utf-8)
  target_compile_options(deletion PRIVATE /W4 /WX /EHsc /utf-8)
else()
  target_compile_options(lottery PRIVATE -Wall -Wextra -Werror)
  target_compile_options(companion PRIVATE -Wall -Wextra -Werror)
  target_compile_options(gossip PRIVATE -Wall -Wextra -Werror)
  target_compile_options(advertising PRIVATE -Wall -Wextra -Werror)
  target_compile_options(commands PRIVATE -Wall -Wextra -Werror)
  target_compile_options(deletion PRIVATE -Wall -Wextra -Werror)
endif()
''', encoding='utf-8')
        subprocess.run(['cmake', '-S', str(out), '-B', str(out / 'build')], check=True, timeout=60)
        subprocess.run(['cmake', '--build', str(out / 'build'), '--config', 'Release'], check=True, timeout=90)
        executable = next((out / 'build').rglob('lottery.exe'), None)
        if executable is None:
            executable = out / 'build/lottery'
        subprocess.run([str(executable)], check=True, timeout=15)
        companion_executable = next((out / 'build').rglob('companion.exe'), out / 'build/companion')
        subprocess.run([str(companion_executable)], check=True, timeout=15)
        gossip_executable = next((out / 'build').rglob('gossip.exe'), out / 'build/gossip')
        subprocess.run([str(gossip_executable)], check=True, timeout=15)
        advertising_executable = next((out / 'build').rglob('advertising.exe'), out / 'build/advertising')
        subprocess.run([str(advertising_executable)], check=True, timeout=15)
        deletion_executable = next((out / 'build').rglob('deletion.exe'), out / 'build/deletion')
        subprocess.run([str(deletion_executable)], check=True, timeout=15)
        commands_executable = next((out / 'build').rglob('commands.exe'), out / 'build/commands')
        subprocess.run([str(commands_executable)], check=True, timeout=15)
        print('PASS: compiled GM commands, actual draw/refund/start/stop/restart/pause persistence, forced prizes and rollback')
        print('PASS: selected recipient missing/pending deletion skips payout; all entrants deleted extends or draws house safely')
        print('PASS: Goldilocks spawn, 0.5..1.5 timer scaling, reset, restored progress and independent lifecycle')
        print('PASS: actual TaskScheduler advertising cadence, managed spawn/recovery/removal, 15-line rotation, live values, player filters, zone yell routing')
        print('PASS: compiled Gallywix rules/ledger, purchase rejection, disabled-state dialogue, Goldilocks sales routing')
        print('PASS: earned sigil account synchronization, unrelated accounts, unlock-all exclusion, known/missing spells')
    print('PASS: compiled dynamic text packet ordering, session isolation, query guards, caps, weighted selection')


if __name__ == '__main__':
    main()
