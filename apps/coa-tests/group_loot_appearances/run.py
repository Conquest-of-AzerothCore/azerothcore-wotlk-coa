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


def method_or(source, signature, fallback):
    return method(source, signature) if signature in source else fallback


def constant(source, name):
    return re.search(r'^constexpr [\w:]+ ' + name + r' = [^;]+;$', source, re.M)[0]


def main():
    source_ref = os.environ.get('COA_GROUP_LOOT_SOURCE_REF')

    def source(path):
        if source_ref:
            return subprocess.check_output(['git', 'show', f'{source_ref}:{path}'], cwd=ROOT).decode('utf-8')
        return (ROOT / path).read_text(encoding='utf-8')

    compat = source('src/server/coa/AscensionCompat.cpp')
    group = source('src/server/game/Groups/Group.cpp')
    group_header = source('src/server/game/Groups/Group.h')
    script_header = source('src/server/game/Scripting/ScriptDefines/GroupScript.h')
    script_source = source('src/server/game/Scripting/ScriptDefines/GroupScript.cpp')
    player_header = source('src/server/game/Scripting/ScriptDefines/PlayerScript.h')
    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    service = method(compat, 'class AscensionCollectionService')
    group_script = method_or(compat, 'class AscensionCompatGroupScript', '')
    hooks = method(script_header, 'enum GroupHook')
    if 'GROUPHOOK_ON_LOOT_ROLL_START' not in hooks:
        hooks = hooks.replace('GROUPHOOK_END', 'GROUPHOOK_ON_LOOT_ROLL_START,\n    GROUPHOOK_END')
    constructor = (re.search(r'AscensionCompatGroupScript\(\)[\s\S]*?\}\)\s*\{\s*\}', group_script)[0]
                   if group_script else 'AscensionCompatGroupScript() : GroupScript("baseline", {}) {}')
    for marker, value in [
        ('CONSTANTS', '\n'.join(constant(compat, name) for name in (
            'APPEARANCE_CATEGORY_COUNT', 'SMSG_APPEARANCE_ADDED'))),
        ('GROUP_HOOKS', hooks + ';'),
        ('ROLL_VOTES', method(group_header, 'enum RollVote') + ';'),
        ('PROGRESS_EVENTS', method(player_header, 'enum class CoAProgressEvent') + ';'),
        ('APPEARANCE_INFO', method(compat, 'struct AppearanceInfo') + ';'),
        ('COLLECTION_STATE', method(compat, 'struct PlayerCollectionState') + ';'),
        ('ROLL_DISPATCH', method_or(script_source, 'void ScriptMgr::OnGroupLootRollStart(',
                                  'void ScriptMgr::OnGroupLootRollStart(Group*, Roll const&, Loot const&,'
                                  ' LootItem const&) {}')),
        ('INSTANCE', method(service, 'static AscensionCollectionService &Instance()')),
        ('GET_STATE', method(service, 'std::shared_ptr<PlayerCollectionState> GetState(')),
        ('ROLL_STARTED', method_or(service, 'void OnLootRollStart(',
                                   'void OnLootRollStart(Roll const&, Loot const&, LootItem const&) {}')),
        ('EQUIPMENT_APPEARANCE', method(service, 'static bool IsEquipmentAppearance(')),
        ('COLLECT_APPEARANCE', method_or(service, 'void CollectItemAppearance(', '')),
        ('SEND_ADDED', method(service, 'void SendAppearanceAdded(')),
        ('SCRIPT_CONSTRUCTOR', constructor),
        ('SCRIPT_ROLL', method_or(group_script, 'void OnLootRollStart(',
                                 'void OnLootRollStart(Group*, Roll const&, Loot const&,'
                                 ' LootItem const&) override {}')),
        ('CAN_ROLL', method(group, 'bool CanRollOnItem(')),
        ('GROUP_LOOT', method(group, 'void Group::GroupLoot(')),
        ('NEED_BEFORE_GREED', method(group, 'void Group::NeedBeforeGreed(')),
        ('SEND_START', method(group, 'void Group::SendLootStartRoll(')),
        ('SEND_PLAYER_START', method(group, 'void Group::SendLootStartRollToPlayer(')),
        ('SEND_PASS', method(group, 'void Group::SendLootRoll(')),
        ('SEND_PENDING', method(group, 'void Group::SendPendingRollsToPlayer(')),
    ]:
        harness = harness.replace('// ACTUAL_' + marker, value)

    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler.'
    with tempfile.TemporaryDirectory(prefix='coa-group-loot-appearances-') as directory:
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
