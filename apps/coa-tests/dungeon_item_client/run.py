import os
from pathlib import Path
import shutil
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def method(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


scaling = (ROOT / 'src/server/coa/AscensionItemScaling.cpp').read_text()
compat = (ROOT / 'src/server/coa/AscensionCompat.cpp').read_text()
code = (HERE / 'harness.cpp').read_text()
for marker, source, signature in [
    ('ROW', scaling, 'ClientItemRow RowOf('),
    ('CLIENT', scaling, 'std::optional<ClientItemRow> ClientRow('),
    ('FIND', compat, 'static std::optional<ItemPatchRow> FindItemRow('),
]:
    code = code.replace('// ACTUAL_' + marker, method(source, signature))
compiler = shutil.which(os.environ.get('CXX', 'c++'))
assert compiler
with tempfile.TemporaryDirectory(prefix='coa-dungeon-client-') as directory:
    output = Path(directory)
    cpp = output / 'harness.cpp'
    exe = output / 'harness'
    cpp.write_text(code)
    subprocess.run([compiler, '-std=c++20', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(exe)],
                   check=True, timeout=60)
    subprocess.run([str(exe)], check=True, timeout=15)
print('PASS: dungeon SQL variants stream their real display rows after late budget loading; '
      'unrelated SQL rows remain gated and dynamic variants retain their existing path')
