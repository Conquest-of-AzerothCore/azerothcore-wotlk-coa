import os
from pathlib import Path
import re
import runpy
import shutil
import struct
import subprocess
import sys
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(ROOT / 'apps/coa-dbc'))
from client_data import dbc_dir
from inspect_dbc import DataSet

method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    source_ref = os.environ.get('COA_WOODWORKING_APPEARANCES_SOURCE_REF')

    def source(path):
        if source_ref:
            return subprocess.check_output(['git', 'show', f'{source_ref}:{path}'], cwd=ROOT).decode('utf-8')
        return (ROOT / path).read_text(encoding='utf-8')

    compat = source('src/server/coa/AscensionCompat.cpp')
    service = method(compat, 'class AscensionCollectionService')
    script = method(compat, 'class AscensionCompatPlayerScript')
    player_header = source('src/server/game/Scripting/ScriptDefines/PlayerScript.h')
    dispatch = source('src/server/game/Scripting/ScriptDefines/PlayerScript.cpp')
    item_header = source('src/server/game/Entities/Item/ItemTemplate.h')
    shared = source('src/server/shared/SharedDefines.h')
    client = source('src/server/shared/DataStores/ClientDBC.cpp')
    crafting = method(source('src/server/game/Spells/SpellEffects.cpp'), 'void Spell::DoCreateItem(')
    assert crafting.index('StoreNewItem(') < crafting.index('sScriptMgr->OnPlayerCreateItem(player, pItem, addNumber);')
    constants = ['APPEARANCE_CATEGORY_COUNT', 'SMSG_APPEARANCE_ADDED', 'SMSG_VANITY_COLLECTION_ADDED']
    if 'APPEARANCE_CATEGORY_SHADOWHOUND' in compat:
        constants.append('APPEARANCE_CATEGORY_SHADOWHOUND')
    replacements = {
        'APPEARANCE_ALIASES': re.sub(r'^#include.*\n', '',
            (ROOT / 'src/server/coa/AscensionItemAppearanceAliases.cpp').read_text(), flags=re.M),
        'CONSTANTS': '\n'.join(re.search(r'^constexpr [\w:]+ ' + name + r' = [^;]+;$', compat, re.M)[0]
                              for name in constants),
        'PATCH_CONSTANTS': '\n'.join(
            re.search(r'^constexpr uint16 ' + name + r' = [^;]+;$', compat, re.M)[0]
            if name in compat else f'constexpr uint16 {name} = {value};'
            for name, value in [('SMSG_PATCH_APPEARANCES', '0x0692'),
                                ('SMSG_PATCH_ITEM_APPEARANCES', '0x0693')]),
        'ENUMS': '\n'.join(method(text, signature) + ';' for text, signature in (
            (item_header, 'enum InventoryType'), (item_header, 'enum ItemClass'),
            (shared, 'enum SpellEffects'), (player_header, 'enum PlayerHook'),
            (player_header, 'enum class CoAProgressEvent'))),
        'RECORDS': '\n'.join(method(compat, signature) + ';' for signature in (
            'struct AppearanceInfo', 'struct VanityInfo', 'struct PlayerCollectionState')),
        'CLIENT_DBC': '\n'.join(method(client, signature) for signature in (
            'uint32 ReadHeaderField(', 'std::string_view ClientDBC::Record::GetStringAt(',
            'bool ClientDBC::Load(', 'ClientDBC::Record ClientDBC::GetRecord(')),
        'DISPATCH_CREATE': method(dispatch, 'void ScriptMgr::OnPlayerCreateItem('),
        'SCRIPT_CONSTRUCTOR': re.search(r'AscensionCompatPlayerScript\(\)[\s\S]*?\}\)\s*\{\s*\}', script)[0],
        'SCRIPT_CREATE': method(script, 'void OnPlayerCreateItem('),
        'SCRIPT_PATCH': method(script, 'static void SendObtainedItemPatchRow('),
    }
    for marker, signature in (
        ('INSTANCE', 'static AscensionCollectionService &Instance()'),
        ('LOAD', 'bool LoadClientData()'), ('GET_STATE', 'std::shared_ptr<PlayerCollectionState> GetState('),
        ('OBTAINED', 'void OnItemObtained('), ('IS_EQUIPMENT', 'static bool IsEquipmentAppearance('),
        ('COLLECT_APPEARANCE', 'void CollectItemAppearance('), ('COLLECT_ITEM', 'void CollectItem('),
        ('SEND_ADDED', 'void SendAppearanceAdded('),
    ):
        replacements[marker] = method(service, signature)
    for marker, signature, fallback in (
        ('LOAD_WOODWORKING', 'void LoadWoodworkingAppearances(', 'void LoadWoodworkingAppearances(uint32) {}'),
        ('SEND_CATALOG', 'void SendWoodworkingAppearanceCatalog(', 'void SendWoodworkingAppearanceCatalog(Player*) {}'),
    ):
        replacements[marker] = method(service, signature) if signature in service else fallback
    if 'void SendWoodworkingAppearanceCatalog(' in service:
        login = method(service, 'void OnPlayerLogin(')
        assert login.index('IsBot()') < login.index('SendWoodworkingAppearanceCatalog(player);')
        assert login.index('SendWoodworkingAppearanceCatalog(player);') < login.index('ScanPlayerInventory(')
        assert login.index('SendWoodworkingAppearanceCatalog(player);') < login.index('BeginAppearanceCollectionSync(')

    dataset = DataSet(dbc_dir())
    skills, skill_schema, _, _ = dataset.load('SkillLineAbility')
    spells, spell_schema, spell_index, _ = dataset.load('Spell')
    skill_fields = {field.name: field for field in skill_schema.columns}
    spell_fields = {field.name: field for field in spell_schema.columns}
    value = lambda table, row, field: dataset.value(table, row, field)[0]
    recipes = {}
    for row in range(skills.rows):
        if value(skills, row, skill_fields['SkillLine']) != 757:
            continue
        spell_id = value(skills, row, skill_fields['Spell'])
        if spell_id not in spell_index:
            continue
        index = spell_index[spell_id]
        recipes[spell_id] = [value(spells, index, spell_fields[f'{name}[{effect}]'])
                            for effect in range(3) for name in ('Effect', 'EffectItemType')]
    assert recipes, 'Selected DBCs must contain Woodworking recipes'
    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, replacement in replacements.items():
        harness = harness.replace('// ACTUAL_' + marker + '\n', replacement + '\n')
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler.'
    with tempfile.TemporaryDirectory(prefix='coa-woodworking-appearances-') as directory:
        out = Path(directory)
        for name in ('Appearances', 'ItemAppearances', 'Item'):
            (out / f'{name}.dbc').write_bytes(dataset.load(name)[0].data)
        for name, width in [('ItemSet', 35), ('VanityCollection', 77)]:
            (out / f'{name}.dbc').write_bytes(struct.pack('<4s4I', b'WDBC', 0, width, width * 4, 1) + b'\0')
        (out / 'recipes.txt').write_text('\n'.join(' '.join(map(str, (spell_id, *effects)))
                                                for spell_id, effects in sorted(recipes.items())), encoding='utf-8')
        (out / 'Errors.h').write_text('#pragma once\n#include <cassert>\n'
                                    '#define ASSERT(condition, ...) assert(condition)\n', encoding='utf-8')
        (out / 'harness.cpp').write_text(harness, encoding='utf-8')
        executable = out / ('regressions.exe' if os.name == 'nt' else 'regressions')
        includes = [out, ROOT / 'src/common', ROOT / 'src/server/shared/DataStores']
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/utf-8', *['/I' + str(path) for path in includes],
                     str(out / 'harness.cpp'), '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', *['-I' + str(path) for path in includes],
                     str(out / 'harness.cpp'), '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=60)
        subprocess.run([str(executable), str(out)], cwd=out, check=True, timeout=30)


if __name__ == '__main__':
    main()
