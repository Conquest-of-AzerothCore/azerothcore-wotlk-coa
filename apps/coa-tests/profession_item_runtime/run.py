import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']
source = (ROOT / 'src/server/coa/CoAProfessionRescale.cpp').read_text()
harness = (HERE / 'harness.cpp').read_text()
for marker, signature in [('LOAD', 'void ProfessionRescale::Load('),
                          ('OWNS', 'bool ProfessionRescale::OwnsItem('),
                          ('POWER', 'std::optional<std::uint32_t> ProfessionRescale::ItemPower('),
                          ('NORMALIZE', 'void ProfessionRescale::NormalizeProperty(')]:
    harness = harness.replace('// ACTUAL_' + marker, method(source, signature))
native = (ROOT / 'src/server/coa/AscensionNativeItemScaling.cpp').read_text()
harness = harness.replace('// ACTUAL_AUCTIONS', method(source, 'void NormalizeAuctions('))
harness = harness.replace('// ACTUAL_MAIL', method(native, 'void MailListed('))
harness = harness.replace('// ACTUAL_REFRESH', method(source, 'void RefreshTemplates('))
harness = harness.replace('// ACTUAL_ARMOR', method(native, 'uint32 WornArmor('))
compiler = shutil.which(os.environ.get('CXX', 'c++'))
assert compiler
with tempfile.TemporaryDirectory(prefix='coa-profession-runtime-') as directory:
    output = Path(directory)
    cpp = output / 'harness.cpp'
    cpp.write_text(harness)
    exe = output / 'regression'
    subprocess.run([compiler, '-std=c++20', '-Wall', '-Wextra', '-Werror',
                    '-I' + str(ROOT / 'src/server/coa'), '-I' + str(ROOT / 'src/common/Utilities'),
                    str(cpp), '-o', str(exe)], check=True, timeout=60)
    subprocess.run([str(exe)], check=True, timeout=15)
print('PASS: actual profession budget activation, Power overrides, all canonical affix mappings, '
      'deferred existing-copy persistence, outside items and idempotence')
