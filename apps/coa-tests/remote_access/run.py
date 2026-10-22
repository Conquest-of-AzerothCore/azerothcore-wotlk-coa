import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent

def main():
    header = (ROOT / 'src/server/apps/worldserver/RemoteAccess/RASession.h').read_text()
    source = (ROOT / 'src/server/apps/worldserver/RemoteAccess/RASession.cpp').read_text()
    source = source[source.index('using boost::asio::ip::tcp;'):]
    begin = source.index('bool RASession::CheckAccessLevel(')
    end = source.rfind('\n', 0, source.index('RASession::ProcessCommand(')) + 1
    source = source[:begin] + source[end:]
    holder = (ROOT / 'src/server/game/World/IWorld.h').read_text()
    holder = holder[holder.index('struct AC_GAME_API CliCommandHolder'):holder.index('// ServerMessages.dbc')]
    harness = (HERE / 'harness.cpp').read_text().replace('// ACTUAL_HOLDER', holder).replace('// ACTUAL_SOURCE', source)
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'A C++20 compiler is required'
    boost = Path(os.environ.get('BOOST_INCLUDE_DIR', 'C:/vcpkg/installed/x64-windows-static-md/include'))
    with tempfile.TemporaryDirectory(prefix='coa-ra-shutdown-') as folder:
        out = Path(folder)
        (out / 'RASession.h').write_text(header)
        (out / 'Socket.h').write_text('''#pragma once
#include <boost/asio.hpp>
#include <memory>
#include <string_view>
using IoContextTcpSocket = boost::asio::basic_stream_socket<boost::asio::ip::tcp, boost::asio::io_context::executor_type>;
''')
        (out / 'harness.cpp').write_text(harness)
        exe = out / ('regression.exe' if os.name == 'nt' else 'regression')
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/D_CRT_SECURE_NO_WARNINGS', '/I' + str(boost),
                     'harness.cpp', '/Fe' + str(exe), '/link', 'ws2_32.lib', 'mswsock.lib']
        else:
            flags = ['-std=c++20', '-pthread', 'harness.cpp', '-o', str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)

if __name__ == '__main__':
    main()
