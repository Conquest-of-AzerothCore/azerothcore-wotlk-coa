import argparse
import os
from pathlib import Path
import re
import runpy
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
extract = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--before', help='Optional original git ref for the equip checks (expected regression failure).')
    args = parser.parse_args()

    def read(path, original=True):
        if args.before and original:
            return git_source(['git', 'show', args.before + ':' + path], cwd=ROOT).decode()
        return (ROOT / path).read_text()

    core = read('src/server/game/Entities/Player/Player.cpp')
    header = read('src/server/game/Entities/Player/Player.h')
    storage = read('src/server/game/Entities/Player/PlayerStorage.cpp')
    updates = read('src/server/game/Entities/Player/PlayerUpdates.cpp')
    code = (HERE / 'harness.cpp').read_text()
    if args.before:
        code += 'bool Player::HasBurningCommander()const{return false;}\n'
        body = extract(header, 'bool CanTitanGrip() const').split('{', 1)[1]
        code += 'bool Player::CanTitanGrip(ItemTemplate const*)const{' + body + '\n'
    else:
        code += extract(core, 'enum CustomEquipmentSpells') + ';\n'
        code += extract(core, 'bool Player::HasBurningCommander() const') + '\n'
        code += extract(core, 'bool Player::CanTitanGrip(') + '\n'
        removed = extract(core, 'void Player::removeSpell(')
        assert 'if (spell_id == SPELL_BURNING_COMMANDER)\n        AutoUnequipOffhandIfNeed();' in removed
    code += extract(core, 'bool Player::CanUseTwoHandWithShield(') + '\n'
    code += extract(header, 'bool IsTwoHandUsed() const').replace('bool IsTwoHandUsed', 'bool Player::IsTwoHandUsed') + '\n'
    code += extract(updates, 'void Player::UpdateTitansGrip()') + '\n'
    find = extract(storage, 'uint8 Player::FindEquipSlot(')
    case = find[find.index('case INVTYPE_2HWEAPON:'):find.index('case INVTYPE_TABARD:')]
    code += 'bool Player::FindTwoHandSlot(ItemTemplate const* proto)const{uint8 slots[2]={255,255};'
    code += 'switch(proto->InventoryType){' + case + '}return slots[1]==EQUIPMENT_SLOT_OFFHAND;}\n'
    equip = extract(storage, 'InventoryResult Player::CanEquipItem(')
    checks = equip[equip.index('uint32 type = pProto->InventoryType;'):equip.index('dest = ((INVENTORY_SLOT_BAG_0')]
    code += 'InventoryResult Player::CheckEquip(ItemTemplate const* pProto,uint8 eslot,bool swap,bool not_loading){'
    code += checks + 'return EQUIP_ERR_OK;}\n'
    retain = extract(core, 'void Player::AutoUnequipOffhandIfNeed(')
    retain = retain[:retain.index('ItemPosCountVec off_dest;')]
    code += retain + 'removed=true;}\n'
    code += (HERE / 'cases.cpp').read_text()
    contracts = read('src/server/coa/AscensionFelswornContracts.cpp', False)
    commander = extract(contracts, 'if (id == BurningCommander)')
    assert 'periodic(1, 3000);' in commander and 'info->Effects[EFFECT_2].Effect = 0;' in commander
    compiler = str(Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe')
    with tempfile.TemporaryDirectory(prefix='coa-tyrant-equipment-') as directory:
        out = Path(directory)
        cpp, exe = out / 'equipment.cpp', out / 'equipment.exe'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print('PASS: native slot/equip/retention checks; owned passive; unlearn/reset; warrior and Guardian boundaries')


if __name__ == '__main__':
    main()
