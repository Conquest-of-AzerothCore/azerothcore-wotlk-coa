from pathlib import Path
import re
import sqlite3

ROOT = Path(__file__).resolve().parents[3]


def main():
    source = (ROOT / 'modules/mod-worldforged-pickups/src/WorldforgedPickups.cpp').read_text(encoding='utf-8')
    pattern = r'trans->Append\("(INSERT IGNORE INTO [^"]+)"'
    claim = re.search(pattern, source).group(1).format('character_worldforged_loot', 1, 15, 30)
    claim = claim.replace('INSERT IGNORE', 'INSERT OR IGNORE')
    with sqlite3.connect(':memory:') as db:
        db.executescript("""
            CREATE TABLE character_worldforged_loot(guid, spawn_id, entry, PRIMARY KEY(guid, spawn_id));
            CREATE TABLE character_inventory(guid, item INTEGER CHECK(item > 0));
        """)
        for item in (0, 0, 99):
            try:
                with db:
                    db.execute(claim)
                    db.execute('INSERT INTO character_inventory VALUES (1, ?)', (item,))
            except sqlite3.IntegrityError:
                assert item == 0
                assert db.execute('SELECT COUNT(*) FROM character_worldforged_loot').fetchone() == (0,)
                assert db.execute('SELECT COUNT(*) FROM character_inventory').fetchone() == (0,)
        with db:
            db.execute(claim)
        assert db.execute('SELECT * FROM character_worldforged_loot').fetchall() == [(1, 15, 30)]
        assert db.execute('SELECT * FROM character_inventory').fetchall() == [(1, 99)]

    failure = source.split('if (CharacterDatabase.AsyncCommitTransaction(trans).m_future.get())', 1)[1]
    assert failure.index('item->SetState(') < failure.index('BySpawn.try_emplace')
    recovery = source.split('void OnPlayerSaveInventory(', 1)[1].split('void OnPlayerCoAPrestige(', 1)[0]
    assert 'GetItemByGuid(claim.ItemGuid)' in recovery
    assert 'item->SetState(' in recovery and 'AppendWorldforgedClaim(trans,' in recovery
    storage = (ROOT / 'src/server/game/Entities/Player/PlayerStorage.cpp').read_text(encoding='utf-8')
    save = storage.split('void Player::_SaveInventory(', 1)[1].split('void Player::_SaveMail(', 1)[0]
    assert save.index('OnPlayerSaveInventory(this, trans)') < save.index('if (m_itemUpdateQueue.empty())')
    assert 'item->SaveToDB(trans)' in save
    print('PASS: pickup claim replay, repeated inventory failure rollback, and inventory retry wiring')


if __name__ == '__main__':
    main()
