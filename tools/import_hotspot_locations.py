import argparse
import csv
import gzip
import hashlib
import io
import json
from pathlib import Path
import struct
import tarfile


def dbc(path, minimum_fields):
    data = Path(path).read_bytes()
    if len(data) < 20 or data[:4] != b'WDBC':
        raise ValueError('Expected a WDBC file')
    count, fields, size, strings_size = struct.unpack_from('<4I', data, 4)
    if fields < minimum_fields or size != fields * 4 or len(data) != 20 + count * size + strings_size:
        raise ValueError('Unsupported or truncated DBC layout')
    strings = data[20 + count * size:]
    rows = [struct.unpack_from('<' + str(fields) + 'I', data, 20 + i * size) for i in range(count)]
    return rows, strings


def map_rows(path):
    if Path(path).suffix.lower() != '.dbc':
        return json.loads(Path(path).read_text())
    records, strings = dbc(path, 8)
    result = []
    for r in records:
        result.append(dict(ID=r[0], MapID=r[1], AreaID=r[2],
                           AreaName=strings[r[3]:].split(b'\0')[0].decode(),
                           **{key: struct.unpack('<f', struct.pack('<I', r[i]))[0]
                              for i, key in enumerate(['LocLeft', 'LocRight', 'LocTop', 'LocBottom'], 4)}))
    return result


def catalog(archive, client_maps, area_dbc=None):
    with tarfile.open(archive) as data:
        def table(name):
            content = gzip.decompress(data.extractfile('tables/' + name + '.csv.gz').read()).decode()
            return list(csv.DictReader(io.StringIO(content)))
        areas = {int(r['id']): r for r in table('area')}
        objectives = table('quest_objective_hotspot')
        archived_maps = {int(r['area_id']): r for r in table('world_map_area') if int(r['area_id'] or 0)}
    archived_roots = {i: r for i, r in areas.items() if not r['parent_area_id']}
    if area_dbc:
        current, strings = dbc(area_dbc, 33)
        for r in current:
            areas[r[0]] = dict(id=str(r[0]), map_id=str(r[1]), parent_area_id=str(r[2]) if r[2] else '',
                               name=strings[r[11]:].split(b'\0')[0].decode())
    maps = {int(r['AreaID']): r for r in map_rows(client_maps) if r['AreaID']}
    def zone(a):
        seen = set()
        while a in areas and areas[a]['parent_area_id'] and a not in seen:
            seen.add(a)
            a = int(areas[a]['parent_area_id'])
        return a
    def continent(m, z):
        if m == 571:
            return 2
        if m == 530 and z not in {3430,3433,3487,3524,3525,3557}:
            return 1
        return 0 if m in {0,1,530} else 3
    def base(i, z, name, kind, source):
        a = areas.get(z, {})
        m = int(a.get('map_id') or 0)
        v = maps.get(z)
        return dict(id=i, revision=1, name=name[:100], map=m, zone=z, kind=kind, source=source,
                    continent=continent(m,z), enabled=bool(v and m in {0,1,530,571}), valid=bool(v),
                    xp=150, duration=3600, weight=1, cooldown=3600, queued=0, starts=0, ends=0,
                    lastEnd=0, icon=True, highlight=True, x=0.0, y=0.0, radius=0.0, points=[],
                    mapArea=int(v['ID']) if v else 0,
                    bounds=[v[k] for k in ['LocTop','LocBottom','LocLeft','LocRight']] if v else [])
    result=[]
    roots = dict(archived_roots)
    roots.update({i: r for i, r in areas.items() if not r['parent_area_id']})
    for z,a in sorted(roots.items()):
        v=maps.get(z)
        name=a['name'] or (v['AreaName'] if v else 'Zone '+str(z))
        row=base(z,z,name,'zone','area:'+str(z))
        if v:
            row['x']=(v['LocTop']+v['LocBottom'])/2
            row['y']=(v['LocLeft']+v['LocRight'])/2
        result.append(row)
    for i,r in enumerate(objectives,100000):
        a=int(r['area_id']);z=zone(a);original=archived_maps.get(a) or archived_maps.get(z)
        v = {k:float(original[s]) for k,s in [('LocTop','loc_top'),('LocBottom','loc_bottom'),
             ('LocLeft','loc_left'),('LocRight','loc_right')]} if original else None
        row=base(i,z,r['target_name'] or 'Quest '+r['quest_id'],'circle',
                 'quest:'+':'.join(r[k] for k in ['quest_id','objective_idx','target_kind','target_id','area_id']))
        row['original']=r
        row['map']=int(r['map_id'])
        row['continent']=continent(row['map'],z)
        if v and all(r[k] for k in ['cx_pct','cy_pct','radius_pct']):
            cx,cy,radius=(float(r[k])/100 for k in ['cx_pct','cy_pct','radius_pct'])
            row['x']=v['LocTop']+cy*(v['LocBottom']-v['LocTop'])
            row['y']=v['LocLeft']+cx*(v['LocRight']-v['LocLeft'])
            row['radius']=radius*abs(v['LocRight']-v['LocLeft']) if radius > 0 else 150
            row['radiusSource']='recovered-width-percentage' if radius > 0 else 'default-150yd-single-point'
            row['valid']=0<=cx<=1 and 0<=cy<=1 and 0<row['radius']<=5000
        else:
            row['valid']=False
        row['enabled']=row['enabled'] and row['valid']
        result.append(row)
    return result, len(objectives)


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--archive',type=Path,required=True)
    p.add_argument('--client-maps',type=Path,required=True)
    p.add_argument('--areas',type=Path)
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args()
    expected='0f69f4bd01b9f787b4a4bb267fba6711b905300aeaf4f42873bbd9f5446d8549'
    if hashlib.sha256(args.archive.read_bytes()).hexdigest()!=expected:
        raise ValueError('Unexpected source archive')
    rows,count=catalog(args.archive,args.client_maps,args.areas)
    if count!=2715:
        raise ValueError('Expected all 2715 objective records')
    args.output.mkdir(parents=True,exist_ok=True)
    (args.output/'locations.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
    (args.output/'provenance.json').write_text(json.dumps(dict(
        archive_sha256=expected, map_sha256=hashlib.sha256(args.client_maps.read_bytes()).hexdigest(),
        area_sha256=hashlib.sha256(args.areas.read_bytes()).hexdigest() if args.areas else None,
        archive_url='https://github.com/hertigservices/ascension-data/releases/download/'
        'exiles-db-export-2026-09-13/coa-public-2026-09-13-tables.tar'), indent=2)+'\n',encoding='utf-8')
    sql=['CREATE TABLE IF NOT EXISTS `xp_hotspot_location` (`id` INT UNSIGNED NOT NULL, '
         '`payload` MEDIUMTEXT NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;',
         'CREATE TABLE IF NOT EXISTS `xp_hotspot_setting` (`id` INT UNSIGNED NOT NULL, '
         '`value` INT UNSIGNED NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB;',
         'START TRANSACTION;',
         'INSERT IGNORE INTO `xp_hotspot_setting` (`id`, `value`) VALUES (1, 1);']
    for row in rows:
        encoded=json.dumps(row,ensure_ascii=False,separators=(',',':')).encode().hex()
        sql.append("INSERT IGNORE INTO `xp_hotspot_location` (`id`, `payload`) "
                   f"VALUES ({row['id']}, CONVERT(0x{encoded} USING utf8mb4));")
    sql.append('COMMIT;')
    (args.output/'rev_20261011_00_hotspots.sql').write_text('\n'.join(sql)+'\n',encoding='utf-8')
    print(json.dumps(dict(objectives=count,zones=len(rows)-count,eligible=sum(r['enabled'] for r in rows),
                         unresolved=sum(not r['valid'] for r in rows))))


if __name__=='__main__':
    main()
