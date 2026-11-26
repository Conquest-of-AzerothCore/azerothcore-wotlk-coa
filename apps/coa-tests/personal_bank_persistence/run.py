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
    source = (ROOT / 'src/server/coa/AscensionPersonalBank.cpp').read_text(encoding='utf-8')
    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    extractions = (
        ('STORE_MONEY', 'void StoreMoney('),
        ('STORE_TAB', 'void StoreTab('),
        ('HANDLE_DEPOSIT_MONEY', 'void HandleDepositMoney('),
        ('HANDLE_WITHDRAW_MONEY', 'void HandleWithdrawMoney('),
        ('HANDLE_BUY_TAB', 'void HandleBuyTab('),
        ('HANDLE_UPDATE_TAB', 'void HandleUpdateTab('),
        ('HANDLE_SET_TAB_TEXT', 'void HandleSetTabText('),
        ('ADD_TAB_IN_TRANSACTION', 'bool AddTabInTransaction('),
        ('VOUCHER_SCRIPT', 'class item_ascension_bank_tab_voucher : public ItemScript'),
    )
    for marker, signature in extractions:
        snippet = method(source, signature)
        if signature.startswith('class '):
            snippet += ';'
        harness = harness.replace('// ACTUAL_' + marker, snippet)

    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler.'
    with tempfile.TemporaryDirectory(prefix='coa-personal-bank-persistence-') as directory:
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
    print('PASS: personal and realm bank gold/tab mutations commit atomically with character gold/inventory')


if __name__ == '__main__':
    main()
