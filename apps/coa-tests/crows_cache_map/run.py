import argparse
from pathlib import Path
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def main():
    parser = argparse.ArgumentParser(description="Check Crow's Cache map marker updates, projection and hover text.")
    parser.parse_args()
    lua = shutil.which('lua5.1') or shutil.which('lua')
    if not lua:
        raise SystemExit('Lua 5.1 is required for the client map regression.')
    subprocess.run([lua, str(HERE / 'harness.lua'),
                    str(ROOT / 'client-addons/CoACrowsCache/CoACrowsCache.lua')], check=True, timeout=30)


if __name__ == '__main__':
    main()
