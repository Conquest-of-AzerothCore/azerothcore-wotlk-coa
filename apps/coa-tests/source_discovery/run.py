import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source


ROOT = Path(__file__).resolve().parents[3]
MACRO = 'src/cmake/macros/AutoCollect.cmake'


def write(path, content=''):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-ref')
    args = parser.parse_args()
    cmake = shutil.which('cmake')
    if cmake is None:
        raise RuntimeError('cmake is required for source discovery coverage')
    macro = (git_source(['git', 'show', f'{args.source_ref}:{MACRO}'], cwd=ROOT).decode('utf-8')
             if args.source_ref else (ROOT / MACRO).read_text(encoding='utf-8'))
    with tempfile.TemporaryDirectory(prefix='coa-source-discovery-') as directory:
        root = Path(directory)
        project, build = root / 'project', root / 'build'
        sources = project / 'sources'
        excluded = sources / 'excluded'
        write(project / 'AutoCollect.cmake', macro)
        write(sources / 'initial.cpp')
        write(excluded / 'ignored.cpp')
        write(project / 'CMakeLists.txt', '''cmake_minimum_required(VERSION 3.16)
project(SourceDiscovery NONE)
include(AutoCollect.cmake)
CollectSourceFiles("${CMAKE_CURRENT_SOURCE_DIR}/sources" SOURCES
  "${CMAKE_CURRENT_SOURCE_DIR}/sources/excluded")
file(WRITE "${CMAKE_BINARY_DIR}/sources.txt" "${SOURCES}")
add_custom_target(source_roster ALL COMMAND "${CMAKE_COMMAND}" -E true)
''')
        subprocess.run([cmake, '-S', str(project), '-B', str(build)], check=True, timeout=30)

        def roster(expected):
            subprocess.run([cmake, '--build', str(build)], check=True, timeout=30)
            entries = (build / 'sources.txt').read_text(encoding='utf-8').split(';')
            actual = {Path(entry).relative_to(sources).as_posix() for entry in entries if entry}
            if actual != expected:
                raise AssertionError(f'Expected source roster {sorted(expected)}, observed {sorted(actual)}')

        roster({'initial.cpp'})
        write(sources / 'added.cpp')
        roster({'initial.cpp', 'added.cpp'})
        write(sources / 'new-directory' / 'nested.cpp')
        roster({'initial.cpp', 'added.cpp', 'new-directory/nested.cpp'})
        write(excluded / 'later.cpp')
        roster({'initial.cpp', 'added.cpp', 'new-directory/nested.cpp'})
        (sources / 'initial.cpp').unlink()
        roster({'added.cpp', 'new-directory/nested.cpp'})
        (sources / 'new-directory' / 'nested.cpp').unlink()
        (sources / 'new-directory').rmdir()
        roster({'added.cpp'})
    print('PASS: incremental source additions, removals, new directories and directory exclusions')


if __name__ == '__main__':
    main()
