from pathlib import Path
import os
import re
import shutil
import sqlite3
import subprocess
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MODULE = ROOT / 'modules/mod-manastorm-endless/src'


def method(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def main():
    rewards = (MODULE / 'ManastormRewards.cpp').read_text()
    sources = [(MODULE / 'ManastormClientBridge.cpp', ['char const* ValidateEnter(']),
               (MODULE / 'ManastormRewards.cpp', ['bool ManastormRewards::LoadWeeklyCacheAllowance(',
                'bool ManastormRewards::PrepareNormalCacheReward(',
                'std::vector<ManastormRewardVisibilityRecord>\nManastormRewards::BuildVisibilityRecords('])]
    methods = '\n'.join(method(path.read_text(), signature) for path, signatures in sources for signature in signatures)
    header = (MODULE / 'ManastormRewards.h').read_text()
    allowance = method(header, 'struct ManastormWeeklyCacheAllowance') + ';'
    allowance += method(header, 'struct ManastormRewardVisibilityRecord') + ';'
    compiler = shutil.which(os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable the C++20 compiler environment.'
    with tempfile.TemporaryDirectory(prefix='manastorm-release-') as directory:
        out = Path(directory)
        cpp = out / 'actual.cpp'
        exe = out / ('checks.exe' if os.name == 'nt' else 'checks')
        cpp.write_text((HERE / 'harness.cpp').read_text().replace('// ACTUAL_METHODS', methods).replace('struct ManastormWeeklyCacheAllowance;', allowance))
        flags = (['/nologo', '/std:c++20', '/EHsc', str(cpp), '/Fe' + str(exe)] if Path(compiler).stem.lower() == 'cl'
                 else ['-std=c++20', str(cpp), '-o', str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    migrations = [ROOT / 'data/sql/updates/pending_db_characters' / name for name in
                  ['rev_1792493075163811100.sql', 'rev_1792515600000000000.sql']]
    migration = '\n'.join(path.read_text() for path in migrations)
    migration = re.sub(r'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', '', migration)
    production = (ROOT / 'src/server/database/Database/Implementation/CharacterDatabase.cpp').read_text()
    def sql(name):
        match = re.search(r'PrepareStatement\(' + name + r',\s*"([^"\n]+)"', production)
        assert match, name
        return match.group(1)
    reserve_mysql = sql('CHAR_INS_MANASTORM_WEEKLY_CACHE')
    reserve = reserve_mysql.replace('ON DUPLICATE KEY UPDATE reset_at = IF(reset_at = ? AND caches_received = ?, VALUES(reset_at), 0), caches_received = VALUES(caches_received)',
        'ON CONFLICT(guid) DO UPDATE SET reset_at = CASE WHEN reset_at = ? AND caches_received = ? THEN excluded.reset_at ELSE 0 END, caches_received = excluded.caches_received')
    assert reserve != reserve_mysql
    receipt = sql('CHAR_INS_MANASTORM_STAGE_RECEIPT')
    count = sql('CHAR_SEL_MANASTORM_WEEKLY_CACHE')
    with tempfile.TemporaryDirectory(prefix='manastorm-ledger-') as directory:
        ledger = Path(directory) / 'characters.db'
        db = sqlite3.connect(ledger)
        db.executescript(migration)
        db.executescript(migration)
        db.execute('CREATE TABLE delivered (item_id INTEGER)')
        db.execute('CREATE TABLE character_manastorm_completed_depth (guid INTEGER, mode INTEGER, track INTEGER, depth INTEGER)')
        db.execute('INSERT INTO character_manastorm_completed_depth VALUES (1,1,1,100)')
        db.commit()
        clear = sql('CHAR_SEL_MANASTORM_FIRST_CLEAR')
        assert db.execute(clear, (1,1,1,100)).fetchone()[0] == 1
        assert db.execute(clear, (1,2,1,100)).fetchone()[0] == 0
        assert db.execute(clear, (1,1,2,100)).fetchone()[0] == 0
        for number in range(1, 6):
            with db:
                db.execute(receipt, (1, 100, 1, number))
                db.execute(reserve, (1, 2000, number, 2000 if number > 1 else 0, number - 1))
                db.execute('INSERT INTO delivered VALUES (1278050)')
        assert db.execute(count, (1,)).fetchone() == (2000, 5)
        assert db.execute(count, (2,)).fetchone() == (0, 0)
        assert db.execute('SELECT COUNT(*) FROM manastorm_weekly_cache_lockout').fetchone()[0] == 1
        try:
            with db:
                db.execute('INSERT INTO delivered VALUES (1278050)')
                db.execute(receipt, (1, 100, 1, 5))
            raise AssertionError('Duplicate stage was accepted')
        except sqlite3.IntegrityError:
            pass
        try:
            with db:
                db.execute(receipt, (1, 100, 1, 6))
                db.execute(reserve, (1, 2000, 5, 2000, 4))
            raise AssertionError('Stale concurrent counter was accepted')
        except sqlite3.IntegrityError:
            pass
        assert db.execute('SELECT COUNT(*) FROM delivered').fetchone()[0] == 5
        assert db.execute('SELECT COUNT(*) FROM character_manastorm_stage_receipt').fetchone()[0] == 5
        with db:
            db.execute(receipt, (1, 100, 1, 6))
            db.execute('INSERT INTO delivered VALUES (1478052)')
        assert db.execute(count, (1,)).fetchone() == (2000, 5)
        with db:
            db.execute(reserve, (1, 3000, 1, 2000, 5))
        assert db.execute(count, (1,)).fetchone() == (3000, 1)
        try:
            with db:
                db.execute(reserve, (1, 3000, 1, 2000, 5))
            raise AssertionError('Concurrent reset doubled the new allowance')
        except sqlite3.IntegrityError:
            pass
        db.close()
        reopened = sqlite3.connect(ledger)
        reopened.executescript(migration)
        assert reopened.execute(count, (1,)).fetchone() == (3000, 1)
        assert reopened.execute('SELECT COUNT(*) FROM delivered').fetchone()[0] == 6
        reopened.close()
    print('PASS: production counter SQL replay, character isolation, expiry, duplicate-stage/concurrent counter rollback, bonus exemption and reopen persistence.')
    mysql_config = os.environ.get('MANASTORM_TEST_MYSQL_CONFIG')
    if mysql_config:
        mysql = os.environ['MANASTORM_TEST_MYSQL']
        def bind(query, values):
            for value in values:
                query = query.replace('?', str(int(value)), 1)
            assert '?' not in query
            return query + ';'
        temporary_schema = '\n'.join(path.read_text() for path in migrations).replace(
            'CREATE TABLE IF NOT EXISTS', 'CREATE TEMPORARY TABLE')
        statements = [temporary_schema,
            'CREATE TEMPORARY TABLE manastorm_test_delivery (item_id INT);',
            "SET SESSION sql_mode = '';",
            bind(reserve_mysql, (1,2000,1,0,0)),
            'START TRANSACTION;',
            bind(receipt, (1,100,1,1)),
            'INSERT INTO manastorm_test_delivery VALUES (1278050);',
            bind(reserve_mysql, (1,2000,2,2000,0)),
            'ROLLBACK;',
            "SELECT CONCAT('ROLLBACK:', COUNT(*)) FROM manastorm_test_delivery;",
            "SELECT CONCAT('RECEIPTS:', COUNT(*)) FROM character_manastorm_stage_receipt;",
            bind(reserve_mysql, (1,2000,2,2000,1)),
            bind(reserve_mysql, (1,3000,1,2000,2)),
            'START TRANSACTION;',
            bind(reserve_mysql, (1,3000,1,2000,2)),
            'ROLLBACK;',
            "SELECT CONCAT('COUNTER:',reset_at,':',caches_received) FROM manastorm_weekly_cache_lockout WHERE guid=1;",
            bind(reserve_mysql, (2,3000,255,0,0)),
            "SELECT CONCAT('MAX:',caches_received) FROM manastorm_weekly_cache_lockout WHERE guid=2;"]
        fixture_sql = '\n'.join(statements)
        suffix = uuid.uuid4().hex
        for table in ['manastorm_weekly_cache_lockout', 'character_manastorm_stage_receipt',
                      'character_manastorm_weekly_cache', 'manastorm_test_delivery']:
            fixture_sql = fixture_sql.replace(table, 'tmp_ms_' + suffix + '_' + str(len(table)))
        result = subprocess.run([mysql, '--defaults-file=' + mysql_config,
            '--database=' + os.environ['MANASTORM_TEST_MYSQL_DATABASE'], '--batch', '--force'],
            input=fixture_sql, text=True, capture_output=True, timeout=30)
        errors = [line for line in result.stderr.splitlines() if 'ERROR' in line]
        assert len(errors) == 2 and all('3819' in line for line in errors), result.stderr
        for expected in ['ROLLBACK:0','RECEIPTS:0','COUNTER:3000:1','MAX:255']:
            assert expected in result.stdout, result.stdout
        print('PASS: MySQL temporary-table counter updates, CHECK rejection without strict mode, transaction rollback, expiry and TINYINT maximum. No persistent tables changed.')



if __name__ == '__main__':
    main()
