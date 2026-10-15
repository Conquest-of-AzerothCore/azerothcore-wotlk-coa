import re
import sqlite3
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SQL = ROOT / 'data/sql/updates/pending_db_world/rev_20261007_98_coa_class_trainers_event.sql'
GUARDIAN_SQL = ROOT / 'data/sql/updates/pending_db_world/rev_20261005_04_coa_guardian_of_time_stores.sql'
SCROLL_SQL = ROOT / 'data/sql/updates/pending_db_world/rev_20261007_99_coa_unimbued_mystic_scroll_altars_store.sql'
UNIMBUED_MYSTIC_SCROLL = 992720
GENERAL_GOODS = 9781000
ALTARS = 9781012
MECHANICAL_MYSTIC_ALTAR = 2903513


def run_trainer_event_sql(db, sql):
    event = int(re.search(r'SET @EVENT := (\d+);', sql)[1])
    db.executescript(sql.replace('SET @EVENT := %d;' % event, '').replace('@EVENT', str(event)))
    return event


def check_trainer_event():
    sql = SQL.read_text(encoding='utf-8')
    db = sqlite3.connect(':memory:')
    db.executescript('''
        CREATE TABLE `game_event` (`eventEntry`, `description`, `world_event`, `announce`);
        CREATE TABLE `game_event_creature` (`eventEntry`, `guid`, PRIMARY KEY (`guid`, `eventEntry`));
        CREATE TABLE `creature` (`guid`, `id`);
        CREATE TABLE `creature_default_trainer` (`CreatureId`, `TrainerId`);
        CREATE TABLE `trainer` (`Id`, `Type`, `Requirement`);
        INSERT INTO `trainer` VALUES (1, 0, 1), (900015, 0, 15), (900032, 0, 32), (90, 2, 0);
        INSERT INTO `creature_default_trainer` VALUES (100, 1), (50280, 900015), (50290, 900032), (4217, 900032), (200, 90);
        INSERT INTO `creature` VALUES (1, 100), (2, 50280), (3, 50280), (4, 50290), (5, 4217), (6, 200), (7, 300);
        INSERT INTO `game_event_creature` VALUES (195, 99);
    ''')
    event = run_trainer_event_sql(db, sql)
    run_trainer_event_sql(db, sql)
    assert event == 195
    assert db.execute('SELECT COUNT(*) FROM `game_event` WHERE `eventEntry` = 195').fetchone()[0] == 1
    linked = {row[0] for row in db.execute('SELECT `guid` FROM `game_event_creature` WHERE `eventEntry` = 195')}
    assert linked == {2, 3, 4}, linked


def check_source():
    freepick = (ROOT / 'src/server/coa/AscensionFreepick.cpp').read_text(encoding='utf-8')
    assert 'constexpr std::uint16_t COA_CLASS_TRAINERS_EVENT = 195;' in freepick
    startup = freepick[freepick.index('class AscensionFreepickWorld'):]
    assert re.search(r'if \(CurrentRealm\.ConquestOfAzeroth\)\s*sGameEventMgr->StartInternalEvent\(COA_CLASS_TRAINERS_EVENT\);',
                     startup), 'the trainer event starts only on a Conquest of Azeroth realm'
    assert re.search(r'MysticAltars = \(Classless \|\| Reborn\) &&\s*!AscensionWildcard::PlaysWildcard\(', startup), \
        'altars are offered on free-pick and Warcraft Reborn realms, not on CoA or Wildcard'

    guardian = (ROOT / 'modules/mod-worldforged-upgrades/src/WorldforgedGuardian.cpp').read_text(encoding='utf-8')
    sells = guardian[guardian.index('bool SellsAltars()'):]
    assert 'return AscensionFreepick::RealmOffersMysticAltars();' in sells[:sells.index('}')]

    compat = (ROOT / 'src/server/coa/AscensionCompat.cpp').read_text(encoding='utf-8')
    send = compat[compat.index('void SendVanityCollection('):]
    send = send[:send.index('SendPacket(&packet)')]
    assert 'IsWithheldVanityItem' in send, 'withheld altars are not reported as owned'
    deliver = compat[compat.index('is not present in this client build.'):]
    assert deliver.index('IsWithheldVanityItem(itemId)') < deliver.index('bool const entitled'), \
        'withheld altars cannot be delivered'

    altars = {int(v) for v in re.search(r'MysticAltarVanityItems = \{([^}]*)\}', compat)[1].replace(' ', '').split(',') if v.strip()}
    store = GUARDIAN_SQL.read_text(encoding='utf-8')
    sold = set()
    for row in re.finditer(r'\(\s*9781012\s*,\s*\d+\s*,\s*(\d+)', store):
        sold.add(int(row[1]))
    assert sold, 'the Altars store rows were found'
    assert altars - {MECHANICAL_MYSTIC_ALTAR} <= sold, altars - sold


def check_scrolls():
    enchant = (ROOT / 'src/server/coa/AscensionMysticEnchant.cpp').read_text(encoding='utf-8')
    scroll = enchant[enchant.index('bool IsMysticScroll(uint32 item)'):]
    assert 'return item == UNTARNISHED_MYSTIC_SCROLL || (Ready && Loaded.FindItem(item));' in scroll[:scroll.index('}')]
    roll = enchant[enchant.index('bool OnItemRoll('):]
    roll = roll[:roll.index('return true;')]
    pattern = (r'if \(!item->reference && !AscensionFreepick::RealmOffersMysticAltars\(\) && '
               r'IsMysticScroll\(item->itemid\)\)\s*chance = 0\.0f;')
    assert re.search(pattern, roll), 'a scroll never drops where Mystic Enchants are not played'
    assert 'GLOBALHOOK_ON_ITEM_ROLL' in enchant and 'new AscensionMysticEnchant::AscensionMysticEnchantLoot();' in enchant

    db = sqlite3.connect(':memory:')
    db.executescript('''
        CREATE TABLE `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`);
        INSERT INTO `npc_vendor` VALUES (9781000, 14, 1, 0, 0, 0), (9781000, 15, 992720, 0, 0, 0), (9781012, 16, 2, 0, 0, 0);
    ''')
    sql = SCROLL_SQL.read_text(encoding='utf-8')
    db.executescript(sql)
    db.executescript(sql)
    sold = set(db.execute('SELECT `entry`, `item` FROM `npc_vendor` WHERE `item` = 992720'))
    assert sold == {(ALTARS, UNIMBUED_MYSTIC_SCROLL)}, sold
    assert db.execute('SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 9781000').fetchone()[0] == 1


def main():
    check_trainer_event()
    check_source()
    check_scrolls()
    print('PASS: CoA class trainers only on CoA realms; Mystic Enchanting altars and scrolls only on free-pick and Warcraft Reborn realms')


if __name__ == '__main__':
    main()
