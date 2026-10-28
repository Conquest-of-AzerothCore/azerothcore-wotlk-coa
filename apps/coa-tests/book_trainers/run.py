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
    trainer = (ROOT / 'src/server/game/Entities/Creature/Trainer.cpp').read_text(encoding='utf-8')
    actual = '\n\n'.join([
        method(trainer, 'bool IsRankTrainerHero(Player const* player)'),
        method(trainer, 'Trainer* OwnClassTrainer(Player const* player)'),
        method(trainer, 'Trainer* GetTrainerFor(Creature const* npc, Player const* player)'),
    ])
    wildcard = (ROOT / 'src/server/coa/AscensionWildcard.cpp').read_text(encoding='utf-8')
    assert 'Trainer::SetRankTrainerHero(&AscensionWildcard::IsClasslessHero);' in wildcard
    hero = method(wildcard, 'bool IsRealmHero(Player const* player)' + chr(10) + '{')
    assert 'RealmPlaysWildcard||AscensionFreepick::RealmIsClassless()||IsWildcardHero(player)' in ''.join(hero.split())

    book = (ROOT / 'modules/mod-spellbook/src/spellbook.cpp').read_text(encoding='utf-8')
    hello = method(book, 'bool OnGossipHello(Player *player, Creature *book) override')
    assert hello.index('player->GetSession()->SendTrainerList(book);') < hello.index('OpenTrainer(player, book)')

    code = (HERE / 'harness.cpp').read_text(encoding='utf-8').replace('// ACTUAL_TRAINER', actual)
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler
    with tempfile.TemporaryDirectory(prefix='coa-book-trainers-') as directory:
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
