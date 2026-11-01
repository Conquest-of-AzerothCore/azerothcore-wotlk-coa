"""Plan guarded imports into a realm's shared build records; never modifies personal builds."""
import hashlib
import json
import portable_dependency
from library import canonical, require, validate_record
from native_wire import encode_wire, decode_wire


def local_id(public_id):
    value = hashlib.sha256(('A52LIB:' + public_id).encode()).digest()
    return (int.from_bytes(value[:8], 'big') & ((1 << 63) - 1)) | 1


def plan(records, snapshot, catalog, spell_ids, enchant_ids, now, validate=None):
    require(type(now) is int and now > 0, 'Invalid import time')
    latest = {}
    for value in records:
        record = validate_record(value)
        previous = latest.get(record['id'])
        if previous and previous['revision'] == record['revision']:
            require(canonical(previous) == canonical(record), 'Conflicting remote revision')
        if previous is None or record['revision'] > previous['revision']:
            latest[record['id']] = record
    changes, skipped = [], []
    for public_id, record in sorted(latest.items()):
        if record['compatibility']['catalog'] != catalog:
            skipped.append({'id':public_id,'reason':'catalog mismatch'})
            continue
        build = record['build']
        if validate:
            reason=validate(build)
            if reason:
                skipped.append({'id':public_id,'reason':reason})
                continue
        if any(row['Spell'] not in spell_ids for row in build['Spells']) or any(row['Enchant'] not in enchant_ids for row in build['RandomEnchants']):
            skipped.append({'id':public_id,'reason':'unavailable spell or enchant'})
            continue
        identity = local_id(public_id)
        before = snapshot.get(str(identity))
        record_hash = hashlib.sha256(canonical(record)).hexdigest()
        if before:
            require(before['owner_account'] == 0 and before['public_id'] == public_id,
                    'Import ID collides with a personal or unrelated build')
            require(not before['archived'] and not before['featured'] and not before['archetype'], 'Shared build has local changes')
            require(before['native_revision'] == before['latest_revision'], 'Shared build revision changed locally')
            require(hashlib.sha256(bytes.fromhex(before['wire'])).hexdigest() == before['wire_sha256'], 'Shared build content changed locally')
            if record['revision'] <= before['public_revision']:
                if record['revision'] == before['public_revision']:
                    require(record_hash == before['record_sha256'], 'Public revision changed in place')
                continue
            native_revision = before['native_revision'] + 1
            created = before['created']
            updated = max(now, decode_wire(bytes.fromhex(before['wire']))['Updated'] + 1)
        else:
            native_revision, created, updated = 1, now, now
        raw = encode_wire(build, identity, record['author'], created, updated)
        changes.append({'id':identity,'public_id':public_id,'public_revision':record['revision'],
                        'record_sha256':record_hash,'native_revision':native_revision,
                        'wire_sha256':hashlib.sha256(raw).hexdigest(),'wire':raw.hex(),
                        'name':build['Name'],'category':decode_wire(raw)['Category'],
                        'created':created,'before':before})
    return {'changes':changes,'skipped':skipped}


def sql_text(value):
    return "CONVERT(X'" + value.encode('utf-8').hex() + "' USING utf8mb4)"


def transaction(prepared):
    lines = ['CREATE TEMPORARY TABLE a52_library_guard (ok TINYINT NOT NULL CHECK (ok=1));',
             'START TRANSACTION;']
    for row in prepared['changes']:
        identity, revision = row['id'], row['native_revision']
        before = row['before']
        if before:
            condition = (f"b.id={identity} AND b.owner_account=0 AND b.archived=0 "
                f"AND l.public_id={sql_text(row['public_id'])} AND l.public_revision={before['public_revision']} "
                f"AND l.native_revision={before['native_revision']} "
                f"AND l.record_sha256={sql_text(before['record_sha256'])} "
                f"AND l.wire_sha256={sql_text(before['wire_sha256'])} "
                f"AND r.revision=l.native_revision AND HEX(JSON_UNQUOTE(JSON_EXTRACT(r.document,'$.wire')))={sql_text(before['wire'].encode().hex().upper())} "
                "AND NOT EXISTS(SELECT 1 FROM area52_build_revision x WHERE x.build_id=b.id AND x.revision>r.revision) "
                "AND NOT EXISTS(SELECT 1 FROM area52_build_featured f WHERE f.build_id=b.id) "
                "AND NOT EXISTS(SELECT 1 FROM area52_build_archetype a WHERE a.build_id=b.id)")
            lines.append('INSERT INTO a52_library_guard SELECT IF(COUNT(*)=1,1,0) FROM area52_build b '
                         'JOIN area52_library_import l ON l.build_id=b.id JOIN area52_build_revision r ON r.build_id=b.id WHERE ' + condition + ' FOR UPDATE;')
        else:
            lines.append(f'INSERT INTO a52_library_guard SELECT IF(COUNT(*)=0,1,0) FROM area52_build WHERE id={identity} FOR UPDATE;')
            lines.append(f'INSERT INTO area52_build(id,owner_account,archived) VALUES ({identity},0,0);')
        document = json.dumps({'wire':row['wire'],'library_id':row['public_id'],'library_revision':row['public_revision']},separators=(',',':'))
        lines.append(f"INSERT INTO area52_build_revision(build_id,revision,category,name,document) VALUES ({identity},{revision},{row['category']},{sql_text(row['name'])},{sql_text(document)});")
        values = f"{sql_text(row['public_id'])},{identity},{row['public_revision']},{revision},{sql_text(row['record_sha256'])},{sql_text(row['wire_sha256'])},{row['created']}"
        if before:
            lines.append(f"UPDATE area52_library_import SET public_revision={row['public_revision']},native_revision={revision},record_sha256={sql_text(row['record_sha256'])},wire_sha256={sql_text(row['wire_sha256'])} WHERE build_id={identity};")
        else:
            lines.append('INSERT INTO area52_library_import(public_id,build_id,public_revision,native_revision,record_sha256,wire_sha256,created_epoch) VALUES (' + values + ');')
    lines += ['COMMIT;', 'DROP TEMPORARY TABLE a52_library_guard;']
    return '\n'.join(lines) + '\n'


def snapshot_query(records):
    identities = sorted({local_id(validate_record(row)['id']) for row in records})
    if not identities:
        return None
    ids = ','.join(map(str,identities))
    return f"""SELECT JSON_OBJECT(
        'id',CAST(b.id AS CHAR),'owner_account',b.owner_account,'archived',b.archived,
        'public_id',l.public_id,'public_revision',l.public_revision,'native_revision',l.native_revision,
        'record_sha256',l.record_sha256,'wire_sha256',l.wire_sha256,'created',l.created_epoch,
        'latest_revision',r.revision,'wire',JSON_UNQUOTE(JSON_EXTRACT(r.document,'$.wire')),
        'featured',EXISTS(SELECT 1 FROM area52_build_featured f WHERE f.build_id=b.id),
        'archetype',EXISTS(SELECT 1 FROM area52_build_archetype a WHERE a.build_id=b.id))
        FROM area52_build b LEFT JOIN area52_library_import l ON l.build_id=b.id
        LEFT JOIN area52_build_revision r ON r.build_id=b.id AND r.revision=(
            SELECT MAX(x.revision) FROM area52_build_revision x WHERE x.build_id=b.id)
        WHERE b.id IN ({ids});"""


def prepare(records, query, catalog, spell_ids, enchant_ids, now, validate=None):
    statement = snapshot_query(records)
    rows = [json.loads(line) for line in query(statement).splitlines()] if statement else []
    return plan(records, {row['id']:row for row in rows}, catalog, spell_ids, enchant_ids, now, validate)


def apply(prepared, query):
    if not prepared['changes']:
        return
    query(transaction(prepared))
    ids = ','.join(str(row['id']) for row in prepared['changes'])
    result = query(f"SELECT JSON_OBJECT('id',CAST(build_id AS CHAR),'public_revision',public_revision,'native_revision',native_revision,'record_sha256',record_sha256,'wire_sha256',wire_sha256) FROM area52_library_import WHERE build_id IN ({ids});")
    actual = {row['id']:row for row in map(json.loads,result.splitlines())}
    for row in prepared['changes']:
        value = actual.get(str(row['id']))
        require(value is not None and all(value[key] == row[key] for key in ('public_revision','native_revision','record_sha256','wire_sha256')), 'Import committed but readback unresolved; reconcile before retry')
