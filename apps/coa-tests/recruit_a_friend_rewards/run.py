from pathlib import Path
import re
import sqlite3

ROOT = Path(__file__).resolve().parents[3]


def statements(database):
    text = (ROOT / ('src/server/database/Database/Implementation/' + database + 'Database.cpp')).read_text()
    result = {}
    for name, parts in re.findall(r'PrepareStatement\((\w+),\s*((?:"[^"\n]*"\s*)+),\s*CONNECTION_\w+\)', text):
        result[name] = ''.join(re.findall(r'"([^"\n]*)"', parts))
    return result


def connections(database):
    text = (ROOT / ('src/server/database/Database/Implementation/' + database + 'Database.cpp')).read_text()
    return dict(re.findall(r'PrepareStatement\((\w+),\s*(?:"[^"\n]*"\s*)+,\s*(CONNECTION_\w+)\)', text))


def method(path, signature):
    text = (ROOT / path).read_text()
    start = text.index(signature)
    end = text.index('{', start) + 1
    depth = 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]


def main():
    sql = statements('Login')
    char_sql = statements('Character')
    db = sqlite3.connect(':memory:')
    db.create_function('UNIX_TIMESTAMP', 0, lambda: 1000000)
    db.create_function('IF', 3, lambda condition, yes, no: yes if condition else no)
    db.create_function('GREATEST', -1, lambda *values: None if None in values else max(values))
    db.create_function('LEAST', -1, lambda *values: None if None in values else min(values))
    db.executescript("""
        CREATE TABLE account(id INTEGER PRIMARY KEY, username TEXT, recruiter INTEGER DEFAULT 0);
        CREATE TABLE raf_accounts(account_id INTEGER PRIMARY KEY, started_at INTEGER, validated_at INTEGER);
        CREATE TABLE raf_progress(account_id INTEGER, realm_id INTEGER, guid INTEGER,
            baseline_time INTEGER, played_time INTEGER, session_token INTEGER, qualified_seconds INTEGER DEFAULT 0, PRIMARY KEY(account_id, realm_id, guid));
        CREATE TABLE raf_claims(claim_id INTEGER PRIMARY KEY AUTOINCREMENT, account_id INTEGER,
            reward_id INTEGER, realm_id INTEGER, guid INTEGER, item_id INTEGER, quantity INTEGER,
            created_at INTEGER, delivered_at INTEGER, UNIQUE(account_id,reward_id));
        CREATE TABLE raf_reward_delivery(claim_id INTEGER PRIMARY KEY, account_id INTEGER,
            guid INTEGER, mail_id INTEGER);
        CREATE TABLE test_mail(id INTEGER PRIMARY KEY, item INTEGER, quantity INTEGER);
        INSERT INTO account VALUES(1,'A',0),(2,'B',1),(3,'C',2),(4,'D',2),(5,'E',1),(6,'F',0);
    """)
    checks = 0

    def check(condition, message):
        nonlocal checks
        assert condition, message
        checks += 1

    def run(name, values=()):
        query = sql.get(name, char_sql.get(name)).replace('INSERT IGNORE', 'INSERT OR IGNORE')
        query = query.replace('UPDATE raf_accounts a SET', 'UPDATE raf_accounts AS a SET')
        return db.execute(query, values)

    def progress(account, realm, guid, played, token=1):
        run('LOGIN_INS_RAF_ACCOUNT', (account,))
        run('LOGIN_INS_RAF_PROGRESS', (account, realm, guid, played, played, token))
        run('LOGIN_UPD_RAF_PROGRESS', (token, played, token, played, played, token, account, realm, guid))
        run('LOGIN_UPD_RAF_VALIDATION', (account,))

    def valid(account):
        return db.execute('SELECT validated_at FROM raf_accounts WHERE account_id=?', (account,)).fetchone()[0] is not None

    progress(2, 1, 10, 100000)
    check(not valid(2), 'Historical playtime must not validate a legacy link')
    progress(2, 1, 10, 104000)
    progress(2, 1, 11, 200000)
    progress(2, 1, 11, 204000)
    check(not valid(2), 'Two 4000-second characters must not combine')
    progress(2, 2, 10, 900000)
    check(not valid(2), 'Same GUID on another realm needs an independent baseline')
    progress(2, 1, 10, 103000, token=2)
    progress(2, 1, 10, 103100, token=2)
    earned = db.execute('SELECT qualified_seconds FROM raf_progress WHERE account_id=2 AND realm_id=1 AND guid=10').fetchone()[0]
    check(earned == 4100, 'A crash rollback of character playtime must preserve previous auth progress')
    progress(2, 1, 10, 103100, token=2)
    check(db.execute('SELECT qualified_seconds FROM raf_progress WHERE account_id=2 AND realm_id=1 AND guid=10').fetchone()[0] == 4100,
          'Repeated progress checkpoints cannot count the same seconds twice')
    progress(2, 2, 10, 907199)
    check(not valid(2), '7199 seconds must not qualify')
    progress(2, 2, 10, 907200)
    check(valid(2), 'A single character reaching 7200 seconds must qualify')
    progress(2, 2, 10, 907200)
    check(run('LOGIN_SEL_RAF_VALID_COUNT', (1,)).fetchone()[0] == 1, 'Repeated progress counts one recruit')
    progress(3, 4, 10, 0)
    progress(3, 4, 10, 7200)
    check(run('LOGIN_SEL_RAF_VALID_COUNT', (1,)).fetchone()[0] == 1, 'Grandchildren are not direct recruits')
    check(run('LOGIN_SEL_RAF_VALID_COUNT', (2,)).fetchone()[0] == 1, 'A recruited account can earn recruitment rewards')
    progress(2, 2, 10, 1)
    check(valid(2), 'Validation remains permanent after an older playtime observation')
    check(len(run('LOGIN_SEL_RAF_RECRUITS', (2,)).fetchall()) == 2, 'Status includes validated and pending direct recruits')
    check(not valid(4) if db.execute('SELECT 1 FROM raf_accounts WHERE account_id=4').fetchone() else True,
          'Unobserved legacy links cannot automatically qualify')
    run('LOGIN_INS_RAF_CLAIM', (1, 100, 1, 10, 6948, 1, 1, 2))
    check(not run('LOGIN_SEL_RAF_CLAIMS', (1,)).fetchall(), 'Insufficient recruits cannot reserve a claim')
    run('LOGIN_INS_RAF_CLAIM', (1, 100, 1, 10, 6948, 1, 1, 1))
    first = run('LOGIN_SEL_RAF_CLAIMS', (1,)).fetchone()
    check(first is not None and first[6] is None, 'Eligible claim starts pending')
    run('LOGIN_INS_RAF_CLAIM', (1, 100, 2, 99, 25, 900, 1, 1))
    rows = run('LOGIN_SEL_RAF_CLAIMS', (1,)).fetchall()
    check(len(rows) == 1 and rows[0][2:6] == first[2:6], 'Cross-realm duplicate preserves original delivery payload')
    db.commit()
    try:
        db.execute('BEGIN')
        db.execute('INSERT INTO test_mail VALUES(1,6948,1)')
        run('CHAR_INS_RAF_DELIVERY', (first[0], 1, 10, 1))
        raise RuntimeError('simulated crash before character transaction commit')
    except RuntimeError:
        db.rollback()
    check(not run('CHAR_SEL_RAF_DELIVERY', (first[0],)).fetchone(), 'Uncommitted delivery has no receipt')
    check(not db.execute('SELECT * FROM test_mail').fetchall(), 'Uncommitted mail is rolled back with receipt')
    db.execute('BEGIN')
    db.execute('INSERT INTO test_mail VALUES(2,6948,1)')
    run('CHAR_INS_RAF_DELIVERY', (first[0], 1, 10, 2))
    db.commit()
    check(run('CHAR_SEL_RAF_DELIVERY', (first[0],)).fetchone()[0] == 2,
          'Committed receipt survives a crash before auth finalization')
    try:
        db.execute('BEGIN')
        db.execute('INSERT INTO test_mail VALUES(3,6948,1)')
        run('CHAR_INS_RAF_DELIVERY', (first[0], 1, 10, 3))
        raise AssertionError('Duplicate receipt unexpectedly succeeded')
    except sqlite3.IntegrityError:
        db.rollback()
    check(len(db.execute('SELECT * FROM test_mail').fetchall()) == 1, 'Competing delivery rolls back its duplicate mail')
    run('LOGIN_UPD_RAF_CLAIM_DELIVERED', (first[0],))
    check(run('LOGIN_SEL_RAF_CLAIMS', (1,)).fetchone()[6] is not None, 'Recovery finalizes the existing delivery')
    cycle_sql = sql['LOGIN_UPD_RAF_RECRUITER'].split('UPDATE account recruit')[0]
    cycle_sql += 'SELECT COUNT(*) FROM ancestors WHERE id = ?'
    cycle_sql = cycle_sql.replace('UNION DISTINCT', 'UNION')
    check(db.execute(cycle_sql, (3, 1)).fetchone()[0] == 1, 'Ancestor A cannot become recruited by descendant C')
    check(db.execute(cycle_sql, (2, 2)).fetchone()[0] == 1, 'Self recruitment is blocked')
    check(db.execute(cycle_sql, (3, 6)).fetchone()[0] == 0, 'Unrelated root may join an existing chain')
    db.execute('UPDATE account SET recruiter=3 WHERE id=1')
    check(db.execute(cycle_sql, (3, 1)).fetchone()[0] == 1, 'Preexisting cycles terminate safely via UNION DISTINCT')
    recovery = method('src/server/game/Handlers/ReferAFriendHandler.cpp', 'void WorldSession::RecoverRecruitAFriendRewards(')
    mail_rows = method('src/server/game/Mails/Mail.cpp', 'StagedMail MailDraft::AppendMailRows(')
    new_item = method('src/server/game/Entities/Item/Item.cpp', 'void Item::SaveToDB(')
    check('CharacterDatabase.DirectCommitTransaction(trans)' in recovery and 'StageMailTo(trans' in recovery,
          'Reward delivery commits its staged mail directly')
    check('uState == ITEM_NEW ? CHAR_REP_ITEM_INSTANCE' in new_item, 'A created reward item saves with its insert')
    flags = {**connections('Login'), **connections('Character')}
    delivery = set(re.findall(r'\b(?:CHAR|LOGIN)_[A-Z_]+\b', recovery + mail_rows)) | {'CHAR_REP_ITEM_INSTANCE'}
    async_only = sorted(name for name in delivery if flags[name] == 'CONNECTION_ASYNC')
    check(not async_only, 'Direct delivery runs on a synchronous connection, so it needs ' + ', '.join(async_only))
    print(str(checks) + ' focused production-SQL checks passed (in-memory SQLite; no live DB writes).')


if __name__ == '__main__':
    main()
