import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    wildcard = (ROOT / 'src/server/coa/AscensionWildcard.cpp').read_text(encoding='utf-8')
    actual = '\n\n'.join([
        method(wildcard, 'void RememberTrainedRank(Player* player, uint32 spellId)'),
        method(wildcard, 'void RestoreTrainedRanks(Player* player, uint32 firstSpellId)'),
        method(wildcard, 'std::vector<Trainer::Spell> RankTrainerRows(Player const* player)'),
    ])
    trainer = (ROOT / 'src/server/game/Entities/Creature/Trainer.cpp').read_text(encoding='utf-8')
    assert 'return _trainerId == WILDCARD_RANK_TRAINER_ID;' in method(trainer, 'bool Trainer::RepublishesAfterPurchase() const')
    handler = (ROOT / 'src/server/game/Handlers/NPCHandler.cpp').read_text(encoding='utf-8')
    buy = method(handler, 'void WorldSession::HandleTrainerBuySpellOpcode(')
    assert buy.index('trainer->TeachSpell(npc, _player, packet.SpellID);') < buy.index(
        'if (trainer->RepublishesAfterPurchase())' + chr(10) + '        SendTrainerList(npc);')
    learn = method(wildcard, 'void OnPlayerLearnSpell(Player* player, uint32 spellId) override')
    assert 'Loaded.RankLadders.contains(spellId))\n            RestoreTrainedRanks(player, spellId);' in learn
    forgot = method(wildcard, 'void OnPlayerForgotSpell(Player* player, uint32 spellId) override')
    assert forgot.index('RememberTrainedRank(player, spellId);') < forgot.index('Loaded.RankLadders.find(spellId)')
    assert 'tables.RankRoots[ladder[rank - 1]] = first;' in method(wildcard, 'void LoadRankLadders(')

    code = (HERE / 'harness.cpp').read_text(encoding='utf-8').replace('// ACTUAL_RANKS', actual)
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler
    with tempfile.TemporaryDirectory(prefix='coa-trained-rank-memory-') as directory:
        out = Path(directory)
        cpp = out / 'harness.cpp'
        exe = out / ('harness.exe' if os.name == 'nt' else 'harness')
        cpp.write_text(code, encoding='utf-8')
        flags = (['/nologo', '/std:c++20', '/EHsc', str(cpp), '/Fe' + str(exe)]
                 if Path(compiler).stem.lower() == 'cl' else ['-std=c++20', str(cpp), '-o', str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)


if __name__ == '__main__':
    main()
