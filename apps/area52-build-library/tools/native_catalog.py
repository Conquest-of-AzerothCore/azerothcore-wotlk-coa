"""Run the receiving server's pinned native catalog validator before importing or publishing."""
import hashlib
import json
from pathlib import Path
import subprocess
import portable_dependency
from library import require
from native_wire import encode_wire


class CatalogDrift(ValueError):
    pass


class NativeCatalog:
    def __init__(self, manifest, executable, directory):
        self.data=json.loads(Path(manifest).read_text(encoding='utf-8'))
        self.executable=Path(executable)
        self.directory=Path(directory)
        self.stamps={}
        require(self.data['schema']==1 and self.data['files'],'Unsupported native catalog manifest')
        self.check()

    def check_file(self,path,digest):
        info=path.stat()
        stamp=(info.st_size,info.st_mtime_ns,info.st_ctime_ns,info.st_dev,info.st_ino)
        if self.stamps.get(str(path))!=stamp:
            with path.open('rb') as stream:
                if hashlib.file_digest(stream,'sha256').hexdigest()!=digest:
                    raise CatalogDrift('Native catalog baseline changed: '+path.name)
            after=path.stat()
            require((after.st_size,after.st_mtime_ns,after.st_ctime_ns,after.st_dev,after.st_ino)==stamp,
                    'Native catalog changed during validation')
            self.stamps[str(path)]=stamp

    def check(self):
        self.check_file(self.executable,self.data['validator_sha256'])
        for name,digest in self.data['files'].items():
            require(Path(name).name==name and name.endswith('.dbc'),'Invalid catalog filename')
            self.check_file(self.directory/name,digest)
            effective=self.data.get('effective_sources',{}).get(name)
            if effective:self.check_file(Path(effective),digest)
        if 'effective_source_root' in self.data:
            for name,digest in self.data['source'].items():
                require(name.startswith('src/server/coa/') and '..' not in Path(name).parts,'Invalid native source path')
                path=Path(self.data['effective_source_root'])/name
                if not path.is_file():path=Path(self.data['fallback_source_root'])/name
                self.check_file(path,digest)

    def validate(self,build):
        self.check()
        try:
            raw=encode_wire(build,1,'Library validation',1,1)
        except ValueError:
            return 'Build exceeds native layout limits'
        result=subprocess.run([str(self.executable),str(self.directory)],input=raw.hex()+'\n',
                              text=True,capture_output=True,timeout=30)
        require(result.returncode==0,'Native catalog validator unavailable')
        message=result.stdout.strip()
        require(message=='OK' or message.startswith('REJECT '),'Invalid native validator response')
        return None if message=='OK' else message[7:]
