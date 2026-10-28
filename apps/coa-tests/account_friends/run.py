from pathlib import Path
import re
import subprocess
import tempfile

H = Path(__file__).resolve().parent
S = H.parents[2]

def extract(text, signature):
    start = text.index(signature)
    end = text.index('{', start) + 1
    depth = 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]

source = (S / 'src/server/game/Entities/Player/SocialMgr.cpp').read_text()
native = (S / 'src/server/game/Entities/Player/AccountFriends.cpp').read_text()
header = (S / 'src/server/game/Entities/Player/AccountFriends.h').read_text()
code = (H / 'adapter.hpp').read_text() + '\n'
code += '\n'.join(line for line in header.splitlines() if not line.startswith('#')) + '\n'
code += '\n'.join(line for line in native.splitlines() if not line.startswith('#include')) + '\n'
for signature in ('void PlayerSocial::SendSocialList(', 'bool PlayerSocial::HasFriend(', 'void SocialMgr::GetFriendInfo(', 'void SocialMgr::SendFriendStatus('):
    code += extract(source, signature) + '\n'
session = (S / 'src/server/game/Server/WorldSession.cpp').read_text()
for signature in ('bool MapSessionFilter::Process(', 'bool WorldSessionFilter::Process('):
    code += extract(session, signature) + '\n'
opcodes = (S / 'src/server/game/Server/Protocol/Opcodes.cpp').read_text()
route = next(line for line in opcodes.splitlines() if 'DEFINE_HANDLER(CMSG_CONTACT_LIST,' in line)
assert 'PROCESS_THREADUNSAFE' in route
code += (H / 'cases.cpp').read_text()
database = (S / 'src/server/database/Database/Implementation/CharacterDatabase.cpp').read_text()
for statement in ('CHAR_INS_ACCOUNT_FRIEND', 'CHAR_INS_ACCOUNT_FRIEND_MIGRATION'):
    registration = re.search(r'PrepareStatement\(' + statement + r',.*?;', database, re.S)
    assert registration and 'CONNECTION_SYNCH' in registration.group(), statement
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory)
    (path / 'check.cpp').write_text(code)
    subprocess.run(['g++', '-std=c++20', '-pthread', '-Wall', '-Wextra', '-Werror', '-fsanitize=undefined',
                    str(path / 'check.cpp'), '-o', str(path / 'check')], check=True)
    subprocess.run([str(path / 'check')], check=True)
