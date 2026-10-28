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
    source_ref = os.environ.get('COA_QUEST_REWARD_SOURCE_REF')
    compat_path = 'src/server/coa/AscensionCompat.cpp'
    compat = (subprocess.check_output(['git', 'show', f'{source_ref}:{compat_path}'], cwd=ROOT).decode('utf-8')
              if source_ref else (ROOT / compat_path).read_text(encoding='utf-8'))
    script_header = (ROOT / 'src/server/game/Scripting/ScriptDefines/PlayerScript.h').read_text(encoding='utf-8')
    script_source = (ROOT / 'src/server/game/Scripting/ScriptDefines/PlayerScript.cpp').read_text(encoding='utf-8')
    quest_source = (ROOT / 'src/server/game/Entities/Player/PlayerQuest.cpp').read_text(encoding='utf-8')
    reward = method(quest_source, 'void Player::RewardQuest(')
    assert 'sScriptMgr->OnPlayerCompleteQuest(this, quest);' in reward
    assert reward.index('StoreNewItem(') < reward.index('sScriptMgr->OnPlayerCompleteQuest(this, quest);')
    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    service = method(compat, 'class AscensionCollectionService')
    player_script = method(compat, 'class AscensionCompatPlayerScript')
    for marker, source in [
        ('CONSTANTS', '\n'.join(constant(compat, name) for name in (
            'APPEARANCE_CATEGORY_COUNT', 'SMSG_APPEARANCE_ADDED', 'SMSG_VANITY_COLLECTION_ADDED'))),
        ('PLAYER_HOOKS', method(script_header, 'enum PlayerHook') + ';'),
        ('PROGRESS_EVENTS', method(script_header, 'enum class CoAProgressEvent') + ';'),
        ('APPEARANCE_INFO', method(compat, 'struct AppearanceInfo') + ';'),
        ('COLLECTION_STATE', method(compat, 'struct PlayerCollectionState') + ';'),
        ('COMPLETE_DISPATCH', method(script_source, 'void ScriptMgr::OnPlayerCompleteQuest(')),
        ('INSTANCE', method(service, 'static AscensionCollectionService &Instance()')),
        ('GET_STATE', method(service, 'std::shared_ptr<PlayerCollectionState> GetState(')),
        ('ITEM_OBTAINED', method(service, 'void OnItemObtained(')),
        ('QUEST_REWARDED', method_or(service, 'void OnQuestRewarded(',
                                    'void OnQuestRewarded(Player*, Quest const*) {}')),
        ('EQUIPMENT_APPEARANCE', method(service, 'static bool IsEquipmentAppearance(')),
        ('COLLECT_APPEARANCE', method_or(service, 'void CollectItemAppearance(', '')),
        ('COLLECT_ITEM', method(service, 'void CollectItem(')),
        ('SEND_ADDED', method(service, 'void SendAppearanceAdded(')),
        ('SCRIPT_CONSTRUCTOR', re.search(r'AscensionCompatPlayerScript\(\)[\s\S]*?\}\)\s*\{\s*\}',
                                         player_script)[0]),
        ('SCRIPT_COMPLETE', method_or(player_script, 'void OnPlayerCompleteQuest(',
                                     'void OnPlayerCompleteQuest(Player*, Quest const*) override {}')),
    ]:
        harness = harness.replace('// ACTUAL_' + marker, source)

    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler.'
    with tempfile.TemporaryDirectory(prefix='coa-quest-reward-appearances-') as directory:
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
