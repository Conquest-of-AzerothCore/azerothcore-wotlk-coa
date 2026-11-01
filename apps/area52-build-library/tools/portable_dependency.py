from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1] / 'portable' / 'tools'
if not all((ROOT / name).is_file() for name in ('library.py', 'catalog.py')):
    raise RuntimeError('Initialize apps/area52-build-library/portable at the pinned submodule commit')
sys.path.insert(0, str(ROOT))
