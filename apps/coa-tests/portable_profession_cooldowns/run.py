import os
from pathlib import Path
import runpy
import shutil
import sqlite3
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SQL = 'data/sql/updates/pending_db_world/rev_1790878435980747000.sql'
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    source_ref = os.environ.get('COA_SAWMILL_COOLDOWN_SOURCE_REF')

    def source(path, optional=False):
        if source_ref:
            result = subprocess.run(['git', 'show', f'{source_ref}:{path}'], cwd=ROOT,
                                    capture_output=True, text=True)
            if optional and result.returncode:
                return ''
            result.check_returncode()
            return result.stdout
        return (ROOT / path).read_text(encoding='utf-8')

    sql = source(SQL, optional=True)
    db = sqlite3.connect(':memory:')
    db.executescript('''
        CREATE TABLE spell_cooldown_overrides (
            Id INTEGER PRIMARY KEY, RecoveryTime INTEGER, CategoryRecoveryTime INTEGER,
            StartRecoveryTime INTEGER, StartRecoveryCategory INTEGER, Comment TEXT);
        CREATE TABLE item_template (
            entry INTEGER PRIMARY KEY, spellid_1 INTEGER, spellcooldown_1 INTEGER,
            spellcategory_1 INTEGER, spellcategorycooldown_1 INTEGER, duration INTEGER);
        INSERT INTO spell_cooldown_overrides VALUES (42, 7777, 123, 456, 789, 'unrelated');
        INSERT INTO item_template VALUES (1777064, 9931368, 3600000, 0, -1, 99);
        INSERT INTO item_template VALUES (43, 804707, 1200000, 7, 30000, 88);
    ''')
    db.executescript(sql)
    once = list(db.iterdump())
    db.executescript(sql)
    assert list(db.iterdump()) == once, 'Cooldown migration must be idempotent'
    assert db.execute('SELECT * FROM spell_cooldown_overrides WHERE Id=42').fetchone() == (
        42, 7777, 123, 456, 789, 'unrelated')
    assert db.execute('SELECT * FROM item_template WHERE entry=43').fetchone() == (
        43, 804707, 1200000, 7, 30000, 88)
    item = db.execute('SELECT * FROM item_template WHERE entry=1777064').fetchone()
    assert item[:2] == (1777064, 9931368) and item[3:] == (0, -1, 99)
    db.execute('UPDATE item_template SET spellid_1=804707, spellcooldown_1=1200000 WHERE entry=1777064')
    db.executescript(sql)
    assert db.execute('SELECT spellcooldown_1 FROM item_template WHERE entry=1777064').fetchone() == (1200000,)
    db.execute('DELETE FROM item_template WHERE entry=1777064')
    db.executescript(sql)
    assert db.execute('SELECT COUNT(*) FROM item_template').fetchone() == (1,), 'Migration cannot invent an item'
    rows = db.execute('SELECT Id, RecoveryTime, CategoryRecoveryTime, StartRecoveryTime, '
                      'StartRecoveryCategory FROM spell_cooldown_overrides ORDER BY Id').fetchall()

    manager = source('src/server/game/Spells/SpellMgr.cpp')
    player = source('src/server/game/Entities/Player/Player.cpp')
    items = source('src/server/game/Handlers/ItemHandler.cpp')
    buffer = source('src/server/shared/Packets/ByteBuffer.cpp')
    world = source('src/server/game/World/World.cpp')
    spell = source('src/server/game/Spells/Spell.cpp')
    assert world.index('sSpellMgr->LoadSpellCooldownOverrides();') < world.index(
        'sSpellMgr->LoadSpellInfoCustomAttributes();')
    assert 'if (HasSpellCooldownOverride(spellInfo->Id))' in method(
        manager, 'void SpellMgr::LoadSpellInfoCustomAttributes()')
    assert ('_player->AddSpellAndCategoryCooldowns(m_spellInfo, '
            'm_CastItem ? m_CastItem->GetEntry() : 0, this);') in method(spell, 'void Spell::SendSpellCooldown()')
    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, value in [
        ('BYTE_BUFFER', '\n'.join(method(buffer, signature) for signature in (
            'void ByteBuffer::append(uint8 const* src, std::size_t cnt)',
            'ByteBufferPositionException::ByteBufferPositionException(',
        ))),
        ('COOLDOWN_RECORD', method(source('src/server/game/Entities/Player/Player.h'), 'struct SpellCooldown') + ';'),
        ('OVERRIDE_RECORD', method(source('src/server/game/Spells/SpellMgr.h'), 'struct SpellCooldownOverride') + ';'),
        ('ATTACK_TYPE', method(source('src/server/game/Entities/Unit/Unit.h'), 'enum WeaponAttackType') + ';'),
        ('LOAD_OVERRIDES', method(manager, 'void SpellMgr::LoadSpellCooldownOverrides()')),
        ('HAS_OVERRIDE', method(manager, 'bool SpellMgr::HasSpellCooldownOverride(')),
        ('GET_OVERRIDE', method(manager, 'SpellCooldownOverride SpellMgr::GetSpellCooldownOverride(')),
        ('APPLY_OVERRIDE', method(manager, 'if (HasSpellCooldownOverride(spellInfo->Id))')),
        ('ADD_COOLDOWNS', method(player, 'void Player::AddSpellAndCategoryCooldowns(')),
        ('STORE_COOLDOWN', method(player, 'void Player::_AddSpellCooldown(')),
        ('HAS_COOLDOWN', method(player, 'bool Player::HasSpellCooldown(')),
        ('COOLDOWN_DELAY', method(player, 'uint32 Player::GetSpellCooldownDelay(')),
        ('ITEM_QUERY', method(items, 'void WorldSession::SendItemQuerySingleResponse(')),
        ('SQL_ROWS', 'WorldDatabase.Rows = {' + ','.join('{' + ','.join(map(str, row)) + '}' for row in rows) + '};'),
        ('ITEM_COOLDOWN', str(item[2])),
    ]:
        harness = harness.replace('// ACTUAL_' + marker, value)

    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler.'
    includes = [ROOT / path for path in (
        'src/common', 'src/common/Utilities', 'src/server/shared', 'src/server/shared/DataStores',
        'src/server/shared/Packets', 'src/server/game/Server', 'src/server/game/Server/Protocol',
        'src/server/game/Entities/Item', 'src/server/game/Spells', 'src/server/game/Spells/Auras')]
    with tempfile.TemporaryDirectory(prefix='coa-portable-profession-cooldowns-') as directory:
        out = Path(directory)
        cpp = out / 'harness.cpp'
        cpp.write_text(harness, encoding='utf-8')
        executable = out / ('regressions.exe' if os.name == 'nt' else 'regressions')
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/utf-8', *['/I' + str(path) for path in includes],
                     str(cpp), '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', *['-I' + str(path) for path in includes],
                     str(cpp), '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=60)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=15)


if __name__ == '__main__':
    main()
