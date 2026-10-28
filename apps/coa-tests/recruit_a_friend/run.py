from pathlib import Path
import os
import re
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def source(path):
    base = os.environ.get('RAF_TEST_BASE')
    if base:
        return subprocess.check_output(['git', 'show', base + ':' + path], cwd=ROOT, text=True, encoding='utf-8')
    return (ROOT / path).read_text(encoding='utf-8')


def method(text, signature):
    start = text.index(signature)
    end = text.index('{', start) + 1
    depth = 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]


def main():
    handlers = source('src/server/game/Handlers/ReferAFriendHandler.cpp')
    player = source('src/server/game/Entities/Player/Player.cpp')
    header = source('src/server/game/Entities/Player/Player.h')
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    enum_start = header.index('enum ReferAFriendError')
    errors = header[enum_start:header.index('};', enum_start) + 2]
    code = code.replace('// ACTUAL_ERRORS', errors)
    grant_start = handlers.index('namespace') if 'uint8 GrantLevelError(' in handlers else handlers.index('void WorldSession::HandleGrantLevel')
    grant_end = handlers.index('void WorldSession::ClearRecruitAFriendRequests') if 'void WorldSession::ClearRecruitAFriendRequests' in handlers else len(handlers)
    code = code.replace('// ACTUAL_GRANTS', handlers[grant_start:grant_end])
    setter = (method(player, 'void Player::SetGrantableLevels(') if 'void Player::SetGrantableLevels(' in player else
              'void Player::SetGrantableLevels(uint8 val) { m_grantableLevels = val; }')
    code = code.replace('// ACTUAL_SETTER', setter)
    give_level = method(player, 'void Player::GiveLevel(')
    credit = give_level[give_level.index('    // Refer-A-Friend'):give_level.index('    SendQuestGiverStatusMultiple')]
    code = code.replace('// ACTUAL_CREDITS', credit)
    code = code.replace('// ACTUAL_BONUS', method(player, 'bool Player::GetsRecruitAFriendBonus('))
    summon = ''
    if 'SpellCastResult WorldSession::CheckRecruitAFriendSummon(' in handlers:
        summon = method(handlers, 'SpellCastResult WorldSession::CheckRecruitAFriendSummon(')
    else:
        summon = 'SpellCastResult WorldSession::CheckRecruitAFriendSummon(Player const*) const { return SPELL_FAILED_BAD_TARGETS; }'
    code = code.replace('// ACTUAL_SUMMON', summon)
    code = code.replace('// ACTUAL_AVAILABILITY', '#define SUMMON_AVAILABLE ' + str(int('CheckRecruitAFriendSummon' in handlers)))
    code = code.replace('// ACTUAL_REPUTATION', method(player, 'float Player::CalculateReputationGain('))
    confirmation = ''
    if 'bool WorldSession::ValidateRecruitAFriendSummon(' in handlers:
        confirmation = method(handlers, 'bool WorldSession::ValidateRecruitAFriendSummon(')
    code = code.replace('// ACTUAL_CONFIRMATION', confirmation)
    spell = source('src/server/game/Spells/Spell.cpp')
    target_prefix = ''
    if 'CheckRecruitAFriendSummon' in handlers:
        target_prefix = spell[spell.index('void Spell::InitExplicitTargets('):]
        target_prefix = target_prefix[:target_prefix.index('    // this function tries')] + '}\n'
    code = code.replace('// ACTUAL_TARGET_CAPTURE', target_prefix)


    compiler = shutil.which(os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable the C++20 compiler environment.'
    with tempfile.TemporaryDirectory(prefix='raf-regression-') as directory:
        out = Path(directory)
        cpp = out / 'actual.cpp'
        executable = out / ('harness.exe' if os.name == 'nt' else 'harness')
        cpp.write_text(code, encoding='utf-8')
        flags = (['/nologo', '/std:c++20', '/EHsc', '/utf-8', str(cpp), '/Fe' + str(executable)]
                 if Path(compiler).stem.lower() == 'cl' else ['-std=c++20', str(cpp), '-o', str(executable)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=30)


if __name__ == '__main__':
    main()
