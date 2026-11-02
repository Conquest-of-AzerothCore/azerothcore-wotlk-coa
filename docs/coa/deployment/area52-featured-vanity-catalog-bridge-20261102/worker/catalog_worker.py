from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import struct
import sys
import tempfile
import time

DEFAULT=4294967295
CATEGORIES=(17,18,23,31)
QUERY="""SELECT a.archetype_id,r.revision,JSON_UNQUOTE(JSON_EXTRACT(r.document,'$.wire'))
FROM area52_build_archetype a JOIN area52_build b ON b.id=a.build_id AND b.archived=0
JOIN area52_build_revision r ON r.build_id=a.build_id AND r.revision=a.revision AND r.category=8
JOIN area52_build_featured f ON f.build_id=a.build_id AND f.revision=a.revision
ORDER BY a.archetype_id;"""

def sha(data):
    return hashlib.sha256(data).hexdigest()

def section(description,name,count):
    marker='###'+name+'\n'
    if marker not in description:
        return None
    if description.count(marker)!=1:
        raise ValueError('Duplicate metadata section')
    start=description.index(marker)
    if start and description[start-1]!='\n':
        raise ValueError('Invalid metadata boundary')
    line=description[start+len(marker):].split('\n',1)[0]
    if not re.fullmatch(r'1:\d+(?:,\d+)*',line):
        raise ValueError('Invalid metadata version or encoding')
    values=[int(value) for value in line[2:].split(',')]
    if len(values)!=count or any(value>DEFAULT for value in values):
        raise ValueError('Invalid metadata values')
    return values

def dbc(data,fields):
    magic,count,width,size,strings=struct.unpack_from('<4s4I',data)
    if (magic,width,size)!=(b'WDBC',fields,fields*4) or len(data)!=20+count*size+strings:
        raise ValueError('DBC layout mismatch')
    return [list(struct.unpack_from('<'+'I'*fields,data,20+i*size)) for i in range(count)]

def records(raw,decode):
    result={}
    if len(raw)>32*1024*1024:
        raise ValueError('Catalog query limit exceeded')
    for line in raw.splitlines():
        archetype,revision,wire=line.split('\t')
        archetype,revision=int(archetype),int(revision)
        if not 1<=archetype<=65535 or revision<1 or archetype in result:
            raise ValueError('Invalid assigned revision')
        build=decode(bytes.fromhex(wire))
        if build['Category']!=8:
            raise ValueError('Non-Featured record')
        description=build['Description']
        ids=re.findall(r'(?:^|\n)###AREA52_ARCHETYPE_ID\n(\d+)(?:\n|$)',description)
        if ids!=[str(archetype)]:
            raise ValueError('Assignment metadata mismatch')
        result[archetype]={'revision':revision,'items':section(description,'AREA52_FEATURED_VANITY',14),
            'effects':section(description,'AREA52_FEATURED_PREVIEW',4),
            'incarnations':section(description,'AREA52_FEATURED_INCARNATIONS',4)}
    return result

def render(base,assigned,incarnations,item_data):
    rows=dbc(base,28)
    items={row[0]:row[6] for row in dbc(item_data,8)}
    appearance={row['appearance_id']:row for row in incarnations}
    category_by_creature={row['creature_id']:row['category'] for row in incarnations}
    available={row[1] for row in rows}
    if set(assigned)-available:
        raise ValueError('Archetype has no client preview rows')
    slots=({1},{3},{5,20},{10},{8},{9},{6},{16},{7},{13,17,21},{13,14,22,23},{15,25,26})
    for record in assigned.values():
        if record['items'] is not None:
            for index,item in enumerate(record['items'][:12]):
                if item and items.get(item) not in slots[index]:
                    raise ValueError('Preview equipment slot mismatch')
            if items.get(record['items'][9])==17 and record['items'][10]:
                raise ValueError('Two-handed equipment conflict')
        for index,value in enumerate(record['incarnations'] or [DEFAULT]*4):
            if value not in (0,DEFAULT) and (value not in appearance or appearance[value]['category']!=CATEGORIES[index]):
                raise ValueError('Incarnation category mismatch')
    output=bytearray(base)
    for index,row in enumerate(rows):
        record=assigned.get(row[1])
        if not record:
            continue
        if record['items'] is not None:
            row[16:28]=record['items'][:12]
        effects=record['effects'] or [DEFAULT]*4
        if effects[0]!=DEFAULT:
            row[13]=effects[0]
        rewards=record['incarnations']
        category=category_by_creature.get(row[14])
        if rewards is not None and category in CATEGORIES:
            reward=rewards[CATEGORIES.index(category)]
            if reward!=DEFAULT:
                row[14]=appearance[reward]['creature_id'] if reward else 0
        elif rewards is not None and any(value not in (0,DEFAULT) for value in rewards):
            raise ValueError('Incarnation scene category requires an explicit mapping')
        struct.pack_into('<28I',output,20+index*112,*row)
    lines=['Area52FeaturedPreviewCatalog = {']
    for archetype,record in sorted(assigned.items()):
        effects=record['effects'] or [DEFAULT]*4
        lines.append('    ['+str(archetype)+']={'+str(effects[2])+','+str(effects[3])+'},')
    lines.append('}')
    return bytes(output),('\n'.join(lines)+'\n').encode()

def pinned(path,digest):
    value=Path(path).read_bytes()
    if sha(value)!=digest:
        raise ValueError('Approved catalog baseline drift')
    return value

def cycle(config,query,decode):
    inputs={name:pinned(config[name]['path'],config[name]['sha256']) for name in ('details','items','incarnations','glue','local_glue')}
    snapshot=query(QUERY)
    assigned=records(snapshot,decode)
    details,catalog=render(inputs['details'],assigned,json.loads(inputs['incarnations'])['records'],inputs['items'])
    glue=inputs['glue']+b'\n'+catalog+b'\n'+inputs['local_glue']
    files={'DBFilesClient/CharacterCreationArchetypeDetails.dbc':details,'Interface/GlueXML/CharacterCreate.lua':glue}
    if 'rewards' in config:
        from catalog_rewards import render as render_rewards
        reward_inputs={name:pinned(entry['path'],entry['sha256']) for name,entry in config['rewards'].items()}
        sets,vanity,rewards=render_rewards(reward_inputs['sets'],reward_inputs['vanity'],reward_inputs['appearances'],assigned,
            json.loads(reward_inputs['mounts'])['kinds'],json.loads(reward_inputs['defaults'])['bundles']['Bundles'])
        files['DBFilesClient/ItemSet.dbc']=sets
        files['DBFilesClient/VanityCollection.dbc']=vanity
        inputs.update({'rewards_'+name:data for name,data in reward_inputs.items()})
    manifest={'schema':1,'baseline':{name:sha(data) for name,data in inputs.items()},
        'files':{name:sha(data) for name,data in files.items()},'revisions':{str(key):value['revision'] for key,value in sorted(assigned.items())},
        'publication':'pending','dll_changed':False}
    if 'archive' in config:
        pinned(config['archive']['path'],config['archive']['sha256'])
        manifest['baseline']['archive']=config['archive']['sha256']
    if 'release' in config:
        for name in ('manifest','pointer'):
            entry=config['release'][name]
            pinned(entry['path'],entry['sha256'])
            manifest['baseline'][name]=entry['sha256']
    if 'publication' in config:
        entry=config['publication']['notes']
        pinned(entry['path'],entry['sha256'])
        manifest['baseline']['notes']=entry['sha256']
        manifest['publication_configuration']=sha(json.dumps(config['publication'],sort_keys=True).encode())
    encoded=json.dumps(manifest,sort_keys=True,separators=(',',':')).encode()
    identity=sha(encoded)
    root=Path(config['outbox']);root.mkdir(parents=True,exist_ok=True)
    target=root/identity
    if target.exists():
        if (target/'release-request.json').read_bytes()!=encoded or any(sha((target/name).read_bytes())!=sha(data) for name,data in files.items()):
            raise ValueError('Immutable export drift')
        if 'archive' in config:
            receipt=json.loads((target/'patch-E.catalog.json').read_text())
            if sha((target/'patch-E.MPQ').read_bytes())!=receipt['candidate_sha256']:
                raise ValueError('Immutable archive drift')
        if 'publication' in config:
            from catalog_publication import verify
            verify(target)
        return identity
    if query(QUERY)!=snapshot:
        raise ValueError('Assignments changed during export; retry next cycle')
    temporary=Path(tempfile.mkdtemp(prefix='.staging-',dir=root))
    for name,data in files.items():
        path=temporary/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
    (temporary/'release-request.json').write_bytes(encoded)
    if 'archive' in config:
        from catalog_archive import stage
        stage(temporary,config['archive']['path'],config['archive']['sha256'],temporary/'patch-E.MPQ',config['mpq_tools'])
    if 'release' in config:
        from catalog_release import prepare
        release=config['release']
        prepare(temporary/'patch-E.MPQ',release.get('archive_sha256',config['archive']['sha256']),
            pinned(release['manifest']['path'],release['manifest']['sha256']),
            pinned(release['pointer']['path'],release['pointer']['sha256']),
            temporary/'release',release['launcher'],release['repository'])
    if 'publication' in config:
        from catalog_publication import prepare
        publication=config['publication']
        prepare(temporary,publication,pinned(publication['notes']['path'],publication['notes']['sha256']))
    temporary.rename(target)
    return identity

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--config',required=True)
    parser.add_argument('--watch',action='store_true')
    args=parser.parse_args()
    config=json.loads(Path(args.config).read_text())
    if config['schema']!=1 or not 10<=config['poll_seconds']<=300 or 'archive' not in config or 'release' not in config or 'rewards' not in config:
        raise ValueError('Worker configuration invalid')
    sys.path.insert(0,config['library_tools'])
    from native_wire import decode_wire
    from refresh import RealmDatabase
    import fcntl
    root=Path(config['outbox']);root.mkdir(parents=True,exist_ok=True)
    with (root/'worker.lock').open('a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        while True:
            try:
                if config.get('delivery',{}).get('enabled') is True:
                    from catalog_delivery import tick
                    print('Catalog '+tick(config,RealmDatabase(config['database_container']),decode_wire,cycle),flush=True)
                else:
                    print('Prepared catalog '+cycle(config,RealmDatabase(config['database_container']),decode_wire),flush=True)
            except Exception:
                if not args.watch:
                    raise RuntimeError('Catalog preparation failed; existing exports retained') from None
                print('Catalog preparation paused; existing exports retained',flush=True)
            if not args.watch:
                break
            time.sleep(config['poll_seconds'])

if __name__=='__main__':
    main()
