CLI_DESCRIPTION = """Run Ascension extension packet regressions without a server or database.

Compiles the production realm-info sender, socket-thread packet hook, extension packet
queue, world-thread handler, stock item query builder, vanity delivery and the .localtime
command against the real WorldPacket and ItemTemplate. Pass --source-ref to test another
Git ref.
"""

import argparse
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def opcodes(source):
    start = source.index('namespace {\n') + len('namespace {\n')
    return source[start:source.index('constexpr uint32 SPELL_PYROMANCER_HEAT')]


def constant(source, name):
    return re.search(r'^constexpr [\w:]+ ' + name + r' = [^;]+;$', source, re.M)[0]


def method_or(source, signature, fallback):
    return method(source, signature) if signature in source else fallback


def method_in(source, anchor, signature):
    return method(source[source.index(anchor):], signature)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--source-ref', help='Read production code from a local Git ref for regression checks.')
    args = parser.parse_args()

    def source(name):
        if args.source_ref:
            return git_source(['git', 'show', f'{args.source_ref}:{name}'], cwd=ROOT).decode('utf-8')
        return (ROOT / name).read_text(encoding='utf-8')

    compat = source('src/server/coa/AscensionCompat.cpp')
    items = source('src/server/game/Handlers/ItemHandler.cpp')
    objects = source('src/server/game/Globals/ObjectMgr.h')
    buffer = source('src/server/shared/Packets/ByteBuffer.cpp')
    timer = source('src/common/Utilities/Timer.cpp')
    player_script = source('src/server/game/Scripting/ScriptDefines/PlayerScript.h')
    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, text in [
        ('BYTE_BUFFER', '\n'.join(method(buffer, signature) for signature in (
            'void ByteBuffer::append(uint8 const* src, std::size_t cnt)',
            'ByteBufferPositionException::ByteBufferPositionException(',
            'void ByteBuffer::AppendPackedTime(time_t time)',
        ))),
        ('TIME_BREAKDOWN', method(timer, 'std::tm Acore::Time::TimeBreakdown(')),
        ('GET_LOCALE_STRING', method(objects, 'static inline void GetLocaleString(std::vector<std::string> const&')),
        ('ITEM_QUERY', method(items, 'void WorldSession::HandleItemQuerySingleOpcode(') + '\n' + method_or(
            items, 'void WorldSession::SendItemQuerySingleResponse(',
            'void WorldSession::SendItemQuerySingleResponse(uint32) { }')),
        ('OPCODES', opcodes(compat)),
        ('RECEIVES_CLIENT_REQUESTS', method_or(compat, 'bool ReceivesClientRequests(Player const *player)', '')),
        ('PROGRESS_EVENT', method(player_script, 'enum class CoAProgressEvent') + ';'),
        ('QUEUE_LIMIT', constant(compat, 'MAX_QUEUED_EXTENSION_PACKETS')),
        ('CONFIG_KEYS', method(compat, 'enum class AscensionCompatConfig') + ';'),
        ('SEND_REALM_INFO', method(compat, 'void SendRealmInfo(WorldSession *session')),
        ('SEND_GAME_MODE_STATE', method_or(compat, 'void SendGameModeState(Player *player)',
                                           'void SendGameModeState(Player*) { }')),
        ('SEND_SECURE_ADDON_LIST', method_or(compat, 'void SendSecureAddonList(WorldSession* session)', '')),
        ('QUEUE_CLIENT_PACKET', method(compat, 'void QueueClientPacket(uint32 accountId')),
        ('REJECT_CLIENT_PACKET', method_or(compat, 'void RejectClientPacket(uint32 accountId', '')),
        ('TAKE_CLIENT_PACKETS', method_or(compat, 'std::vector<WorldPacket> TakeClientPackets(uint32 accountId', '')),
        ('PENDING_OUTFIT', method_or(compat, 'bool HasPendingOutfitCommit(ObjectGuid guid)',
                                   'bool HasPendingOutfitCommit(ObjectGuid) { return false; }')),
        ('ON_PLAYER_UPDATE', method_in(compat, 'class AscensionCollectionService',
                                       'void OnPlayerUpdate(Player *player, uint32 diff) {')),
        ('HANDLE_CLIENT_PACKET', method(compat, 'void HandleClientPacket(Player *player')),
        ('CAN_PACKET_RECEIVE_EARLY', method(compat, 'bool CanPacketReceiveEarly(WorldSession *session')),
        ('CAN_PACKET_SEND', method(compat, 'bool CanPacketSend(WorldSession* session')),
        ('POINT_SPEND', method_or(compat, 'void HandlePointSpendRequest(Player* player', '')),
        ('DELIVER_VANITY', method(compat, 'void DeliverVanityItem(Player *player, uint32 itemId)')),
        ('WITHHELD_VANITY', '\n'.join([
            (re.search(r'static constexpr std::array<uint32, \d+> MysticAltarVanityItems = [^;]+;', compat) or [''])[0],
            method_or(compat, 'static bool IsWithheldVanityItem(uint32 itemId)',
                      'static bool IsWithheldVanityItem(uint32) { return false; }'),
        ])),
        ('BANK_VANITY', '\n'.join([re.search(r'static constexpr std::array<uint32, \d+> BankVanityItems = [^;]+;',
                                             compat)[0]] + [method(compat, signature) for signature in (
            'static bool IsBankVanityItem(uint32 itemId)',
            'bool OwnsBankVanityItem(Player* player',
            'std::vector<uint32> GetMissingBankSpells(Player* player',
            'void LearnOwnedBankSpells(Player* player',
        )])),
        ('LOCAL_TIME_COMMAND', '\n'.join([
            (re.search(r'static constexpr float REAL_TIME_GAME_SPEED = [^;]+;', compat) or [''])[0],
            method_or(compat, 'static time_t SameDayAt(time_t time', ''),
            method_or(compat, 'static bool HandleLocalTimeCommand(ChatHandler *handler',
                      'static bool HandleLocalTimeCommand(ChatHandler*, Optional<uint8>, Optional<uint8>) '
                      '{ return false; }'),
        ])),
    ]:
        harness = harness.replace('// ACTUAL_' + marker, text)

    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler (VS Developer PowerShell on Windows).'
    includes = [ROOT / 'src/common', ROOT / 'src/common/Utilities', ROOT / 'src/server/shared',
                ROOT / 'src/server/shared/DataStores', ROOT / 'src/server/shared/Packets',
                ROOT / 'src/server/game/Server', ROOT / 'src/server/game/Server/Protocol',
                ROOT / 'src/server/game/Entities/Item', ROOT / 'src/server/coa']
    with tempfile.TemporaryDirectory(prefix='coa-extension-packets-') as directory:
        out = Path(directory)
        cpp = out / 'harness.cpp'
        cpp.write_text(harness, encoding='utf-8')
        executable = out / ('regressions.exe' if os.name == 'nt' else 'regressions')
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/utf-8', *['/I' + str(p) for p in includes],
                     str(cpp), str(ROOT / 'src/common/Utilities/Tokenize.cpp'), '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', '-Wno-unused-const-variable',
                     *['-I' + str(p) for p in includes], str(cpp),
                     str(ROOT / 'src/common/Utilities/Tokenize.cpp'), '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        return subprocess.run([str(executable)], cwd=out).returncode


if __name__ == '__main__':
    sys.exit(main())
