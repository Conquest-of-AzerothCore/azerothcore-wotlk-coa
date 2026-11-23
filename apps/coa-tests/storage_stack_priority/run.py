import os
from pathlib import Path
import re
import runpy
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    storage = (ROOT / 'src/server/game/Entities/Player/PlayerStorage.cpp').read_text()
    header = (ROOT / 'src/server/game/Entities/Player/Player.h').read_text()
    header += (ROOT / 'src/server/game/Entities/Item/Item.h').read_text()
    code = (HERE / 'harness.cpp').read_text()
    names = re.findall(r'\b(?:INVENTORY_SLOT_\w+|KEYRING_SLOT_\w+|CURRENCYTOKEN_SLOT_\w+|BUYBACK_SLOT_\w+|PLAYER_SLOT_END|NULL_BAG|NULL_SLOT)\b', code + storage[storage.index('InventoryResult Player::CanStoreItem_InSpecificSlot'):storage.index('InventoryResult Player::CanStoreItems(')])
    for name in sorted(set(names)):
        value = re.search(r'\b' + name + r'\s*(?:=\s*)?(\d+)', header)
        assert value, name
        code = f'constexpr unsigned {name} = {value[1]};\n' + code
    methods = '\n'.join(method(storage, signature) for signature in (
        'InventoryResult Player::CanStoreItem_InSpecificSlot(',
        'InventoryResult Player::CanStoreItem_InBag(',
        'InventoryResult Player::CanStoreItem_InInventorySlots(',
        'InventoryResult Player::CanStoreItem(uint8'))
    code = code.replace('ACTUAL_METHODS', methods)
    with tempfile.TemporaryDirectory(prefix='storage-stack-priority-') as directory:
        out = Path(directory)
        source = out / 'test.cpp'
        source.write_text(code)
        executable = out / ('test.exe' if os.name == 'nt' else 'test')
        compiler = os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++')
        args = ['/nologo', '/std:c++20', '/EHsc', str(source), '/Fe' + str(executable)] if Path(compiler).stem == 'cl' else ['-std=c++20', str(source), '-o', str(executable)]
        subprocess.run([compiler, *args], cwd=out, check=True)
        subprocess.run([str(executable)], cwd=out, check=True)
    print('PASS: cross-bag merge priority, empty fallback, explicit slots, count limits and bag restrictions')


if __name__ == '__main__':
    main()
