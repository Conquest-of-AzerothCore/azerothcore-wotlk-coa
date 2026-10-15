import os
from pathlib import Path
import re
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SOURCE = ROOT / 'src/server/coa'


def main():
    header = (SOURCE / 'AscensionRenewalContributions.h').read_text()
    script = (SOURCE / 'AscensionChronomancerRenewal.cpp').read_text()
    code = header + (HERE / 'harness.cpp').read_text()
    code += re.sub(r'^#include.*\n', '', script, flags=re.M)
    code += (HERE / 'cases.cpp').read_text()
    compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
    with tempfile.TemporaryDirectory(prefix='coa-renewal-') as directory:
        out = Path(directory)
        cpp, exe = out / 'renewal.cpp', out / 'renewal.exe'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print('PASS: staggered Renewal ticks, independent expiry, aggregate tooltip, delayed updates and saturation')


if __name__ == '__main__':
    main()
