import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'src/server/coa'


def main():
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    if not compiler:
        raise RuntimeError('A C++20 compiler is required')
    with tempfile.TemporaryDirectory(prefix='coa-core-integration-') as directory:
        output = Path(directory)
        harness = output / 'provider.cpp'
        harness.write_text('''#include "CoASpellbook.h"
#include <cassert>
class Player {};
Player owner;
int main()
{
    using namespace CoASpellbook;
    assert(!Available());
    assert(RowCount(&owner) == -1);
    assert(OffersSpell(&owner, 123) == -1);
    assert(CoversSpell(&owner, 123) == -1);
    SetProvider({
        [](Player* player) -> std::uint32_t { assert(player == &owner); return 7; },
        [](Player* player, std::uint32_t spell) { assert(player == &owner); return spell == 123; },
        [](Player* player, std::uint32_t spell) { assert(player == &owner); return spell == 456; }
    });
    assert(Available());
    assert(RowCount(&owner) == 7);
    assert(OffersSpell(&owner, 123) == 1);
    assert(OffersSpell(&owner, 456) == 0);
    assert(CoversSpell(&owner, 456) == 1);
    assert(CoversSpell(&owner, 123) == 0);
    SetProvider({});
    assert(!Available());
    assert(RowCount(&owner) == -1);
    assert(OffersSpell(&owner, 123) == -1);
    assert(CoversSpell(&owner, 456) == -1);
}
''', encoding='utf-8')
        executable = output / ('provider.exe' if os.name == 'nt' else 'provider')
        sources = [str(harness), str(SOURCE / 'CoASpellbook.cpp')]
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/I' + str(SOURCE), *sources, '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', '-I' + str(SOURCE), *sources,
                     '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=output, check=True)
        subprocess.run([str(executable)], check=True)
    print('PASS: optional spellbook provider registration, query forwarding, absence and unload')


if __name__ == '__main__':
    main()
