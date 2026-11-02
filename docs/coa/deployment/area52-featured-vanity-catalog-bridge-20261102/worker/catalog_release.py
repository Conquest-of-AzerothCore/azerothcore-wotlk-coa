from pathlib import Path
import copy
import hashlib
import json
import sys

def prepare(archive,baseline_hash,manifest_bytes,pointer_bytes,destination,launcher,repository):
    sys.path[:0]=[str(launcher),str(Path(launcher)/'tools')]
    from launcher import fullclient
    digest=lambda value:hashlib.sha256(value).hexdigest()
    pointer=json.loads(pointer_bytes)
    if pointer['manifest_sha256']!=digest(manifest_bytes):
        raise ValueError('Launcher pointer baseline mismatch')
    manifest=copy.deepcopy(fullclient.validate(json.loads(manifest_bytes),repository))
    path='Data/area-52/patch-E.MPQ'
    rows=[row for row in manifest['baseline'] if row['path'].lower()==path.lower()]
    components=[value for value in manifest['components'] if len(value['files'])==1 and value['files'][0]['path'].lower()==path.lower()]
    if len(rows)!=1 or len(components)!=1 or rows[0]['sha256']!=baseline_hash:
        raise ValueError('Launcher archive baseline requires reconciliation')
    data=Path(archive).read_bytes()
    output=Path(destination)
    if output.exists():
        raise ValueError('Refuse to overwrite release preparation')
    output.mkdir(parents=True)
    row={'path':rows[0]['path'],'bytes':len(data),'sha256':digest(data)}
    identity='featured-catalog-'+digest(data)[:32]
    prefix=pointer['manifest_url'].rsplit('/',1)[0]+'/'
    chunks=[]
    for index,start in enumerate(range(0,len(data),fullclient.CHUNK_LIMIT)):
        block=data[start:start+fullclient.CHUNK_LIMIT]
        asset=identity+'-'+str(index).zfill(3)+'.bin'
        (output/asset).write_bytes(block)
        chunks.append({'asset':asset,'url':prefix+asset,'bytes':len(block),'sha256':digest(block)})
    manifest['components'].remove(components[0])
    manifest['components'].append({'id':identity,'bytes':len(data),'files':[row],'chunks':chunks})
    manifest['baseline']=[row if value['path'].lower()==path.lower() else value for value in manifest['baseline']]
    fullclient.validate(manifest,repository)
    encoded=(json.dumps(manifest,indent=2)+'\n').encode()
    pointer['manifest_sha256']=digest(encoded)
    pointer['message']='Featured Build catalog updated.'
    (output/'manifest.json').write_bytes(encoded)
    (output/'area52.json').write_text(json.dumps(pointer,indent=2)+'\n')
    (output/'catalog-release.json').write_text(json.dumps({'publication':'pending','baseline_manifest_sha256':digest(manifest_bytes),'candidate_manifest_sha256':digest(encoded),'changed_paths':[path],'archive_sha256':digest(data)},indent=2))
    return manifest
