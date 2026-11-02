from pathlib import Path
import hashlib
import json
import sys

def sha(value):
    return hashlib.sha256(value).hexdigest()

def stage(request_directory,baseline,expected,output,mpq_tools):
    sys.path.insert(0,str(mpq_tools))
    from lib.mpq import MPQArchive,write_archive
    directory=Path(request_directory)
    request=json.loads((directory/'release-request.json').read_text())
    required={'DBFilesClient/CharacterCreationArchetypeDetails.dbc','Interface/GlueXML/CharacterCreate.lua'}
    reward_files={'DBFilesClient/ItemSet.dbc','DBFilesClient/VanityCollection.dbc'}
    if request['schema']!=1 or request['dll_changed'] or set(request['files']) not in (required,required|reward_files):
        raise ValueError('Unsupported catalog release scope')
    baseline=Path(baseline)
    if sha(baseline.read_bytes())!=expected:
        raise ValueError('Client archive baseline drift')
    with MPQArchive(baseline) as archive:
        names=archive.read_file('(listfile)').decode().splitlines()
        files={name:archive.read_file(name) for name in names if name not in ('(listfile)','(attributes)','(signature)')}
    changes={}
    original={name:sha(value) for name,value in files.items()}
    for relative,digest in request['files'].items():
        value=(directory/relative).read_bytes()
        if sha(value)!=digest:
            raise ValueError('Export hash mismatch')
        key=relative.replace('/','\\')
        matches=[name for name in files if name.lower().replace('/','\\')==key.lower()]
        if len(matches)>1:
            raise ValueError('Duplicate archive member')
        key=matches[0] if matches else key
        files[key]=value;changes[key]=digest
    output=Path(output)
    if output.exists():
        raise ValueError('Refuse to overwrite a staged archive')
    output.parent.mkdir(parents=True,exist_ok=True)
    write_archive(output,files)
    with MPQArchive(output) as archive:
        for name,value in files.items():
            if archive.read_file(name)!=value:
                raise ValueError('Archive readback mismatch')
    result={'schema':1,'baseline_sha256':expected,'candidate_sha256':sha(output.read_bytes()),'changed':changes,
        'preserved':{name:digest for name,digest in original.items() if name not in changes},'publication':'pending'}
    output.with_suffix('.catalog.json').write_text(json.dumps(result,indent=2))
    return result
