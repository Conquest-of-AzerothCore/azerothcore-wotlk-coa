import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    source_ref = os.environ.get('COA_TAMING_SOURCE_REF')

    def source(name):
        if source_ref:
            return subprocess.check_output(['git', 'show', f'{source_ref}:{name}'], cwd=ROOT).decode('utf-8')
        return (ROOT / name).read_text(encoding='utf-8')

    pet_defines = source('src/server/game/Entities/Pet/PetDefines.h')
    shared = source('src/server/shared/SharedDefines.h')
    statements = source('src/server/database/Database/Implementation/CharacterDatabase.cpp')
    pet = source('src/server/game/Entities/Pet/Pet.cpp')
    data = source('src/server/coa/AscensionTamingData.h')
    taming = source('src/server/coa/AscensionTaming.cpp')

    scale = method(pet, 'float Pet::GetNativeObjectScale(')
    family = re.search(r'(\w+) ctFamily = GetCreatureTemplate\(\)->family;', scale)
    assert family and family[1] in ('uint16', 'uint32'), \
        'GetNativeObjectScale must hold the creature family in a type that fits families above 255'

    delete = re.search(r'PrepareStatement\(CHAR_DEL_CHAR_PET_BY_SLOT, "([^"]+)"', statements)[1]
    filters_type = 'PetType = ?' in delete
    if filters_type:
        save = method(pet, 'void Pet::SavePetToDB(')
        block = save[save.index('CHAR_DEL_CHAR_PET_BY_SLOT'):save.index('trans->Append(stmt);', save.index('CHAR_DEL_CHAR_PET_BY_SLOT'))]
        assert 'stmt->SetData(3, uint8(HUNTER_PET));' in block, 'the hunter pet delete must bind the hunter pet type'

    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, text in [
        ('PET_DEFINES', pet_defines[pet_defines.index('enum PetType : uint8'):pet_defines.index('enum HappinessState')]),
        ('PET_STABLE', method(pet_defines, 'class PetStable') + ';'),
        ('TAME_FAILURE', method(shared, 'enum PetTameFailure') + ';'),
        ('DELETE_FILTER', f'constexpr bool DeleteFiltersPetType = {"true" if filters_type else "false"};'),
        ('TAMING_DATA', data[data.index('namespace AscensionTaming'):data.rindex('#endif')]),
        ('TAMING', taming[taming.index('namespace AscensionTaming'):]),
    ]:
        harness = harness.replace('// ACTUAL_' + marker, text)

    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler.'
    with tempfile.TemporaryDirectory(prefix='coa-taming-family-calls-') as directory:
        out = Path(directory)
        cpp = out / 'harness.cpp'
        cpp.write_text(harness, encoding='utf-8')
        executable = out / ('regressions.exe' if os.name == 'nt' else 'regressions')
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/utf-8', str(cpp), '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=60)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=15)


if __name__ == '__main__':
    main()
