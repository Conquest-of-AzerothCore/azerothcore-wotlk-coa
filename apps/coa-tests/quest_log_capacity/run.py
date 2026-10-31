import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]


def main():
    extract = runpy.run_path(str(ROOT / 'apps/coa-tests/client_compat/run.py'))['method']
    player = (ROOT / 'src/server/game/Entities/Player/Player.h').read_text()
    quests = (ROOT / 'src/server/game/Entities/Player/PlayerQuest.cpp').read_text()
    definitions = (ROOT / 'src/server/game/Quests/QuestDef.h').read_text()
    capacity = re.search(r'#define MAX_QUEST_LOG_SIZE\s+\d+', definitions)[0]
    stride = re.search(r'#define MAX_QUEST_OFFSET\s+\d+', player)[0]
    fields = (ROOT / 'src/server/game/Entities/Object/Updates/UpdateFields.h').as_posix()
    methods = ''.join(extract(player, signature) for signature in (
        'uint32 GetQuestSlotQuestId(', 'uint32 GetQuestSlotState(', 'uint16 GetQuestSlotCounter(',
        'uint32 GetQuestSlotTime(', 'void SetQuestSlot(', 'void SetQuestSlotCounter(',
        'void SetQuestSlotState(', 'void RemoveQuestSlotState(', 'void SetQuestSlotTimer(', 'void SwapQuestSlot('))
    methods += extract(quests, 'uint16 Player::FindQuestSlot(').replace('Player::', '')
    methods += extract(quests, 'bool Player::SatisfyQuestLog(').replace('Player::', '')
    code = r'''
#include <array>
#include <cassert>
#include <cstdint>
#include "''' + fields + r'''"
using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
#define LOG_DEBUG(...) ((void)0)
namespace WorldPackets::Quest
{
struct QuestLogFull { void* Write() { return nullptr; } };
}
''' + capacity + '\n' + stride + '\n' + extract(player, 'enum QuestSlotOffsets') + r''';
struct Player
{
    std::array<uint32, PLAYER_END> fields{};
    unsigned fullNotices = 0;
    uint32 GetUInt32Value(unsigned index) const { return fields.at(index); }
    uint64 GetUInt64Value(unsigned index) const
    {
        return uint64(GetUInt32Value(index)) | (uint64(GetUInt32Value(index + 1)) << 32);
    }
    void SetUInt32Value(unsigned index, uint32 value) { fields.at(index) = value; }
    void SetUInt64Value(unsigned index, uint64 value)
    {
        SetUInt32Value(index, uint32(value)); SetUInt32Value(index + 1, uint32(value >> 32));
    }
    void SetFlag(unsigned index, uint32 value) { fields.at(index) |= value; }
    void RemoveFlag(unsigned index, uint32 value) { fields.at(index) &= ~value; }
    void SendDirectMessage(void*) { ++fullNotices; }
''' + methods + r'''
};
int main()
{
    static_assert(MAX_QUEST_LOG_SIZE == 64);
    static_assert(PLAYER_QUEST_LOG_1_1 + 64 * MAX_QUEST_OFFSET == PLAYER_VISIBLE_ITEM_1_ENTRYID);
    Player player;
    player.SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID, 123456);
    for (uint16 slot = 0; slot < 64; ++slot)
    {
        assert(player.SatisfyQuestLog(false));
        assert(player.FindQuestSlot(0) == slot);
        player.SetQuestSlot(slot, 1000 + slot, 100 + slot);
        player.SetQuestSlotState(slot, 2);
        player.SetQuestSlotCounter(slot, 3, 17 + slot);
    }
    assert(!player.SatisfyQuestLog(true) && player.fullNotices == 1);
    assert(player.FindQuestSlot(0) == 64);
    for (uint16 slot = 0; slot < 64; ++slot)
    {
        assert(player.FindQuestSlot(1000 + slot) == slot);
        assert(player.GetQuestSlotState(slot) == 2);
        assert(player.GetQuestSlotCounter(slot, 3) == 17 + slot);
        assert(player.GetQuestSlotTime(slot) == 100 + slot);
    }
    player.SwapQuestSlot(0, 63);
    assert(player.FindQuestSlot(1000) == 63 && player.FindQuestSlot(1063) == 0);
    assert(player.GetQuestSlotCounter(63, 3) == 17 && player.GetQuestSlotTime(63) == 100);
    player.SetQuestSlot(63, 0);
    assert(player.SatisfyQuestLog(false) && player.FindQuestSlot(0) == 63);
    player.SetQuestSlot(63, 9999);
    assert(!player.SatisfyQuestLog(false) && player.FindQuestSlot(9999) == 63);
    assert(player.GetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID) == 123456);
}
'''
    compiler = shutil.which(os.environ.get('CXX', 'c++'))
    assert compiler, 'A C++20 compiler is required'
    with tempfile.TemporaryDirectory(prefix='quest-log-capacity-') as directory:
        cpp = Path(directory) / 'test.cpp'
        exe = Path(directory) / 'test'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '-std=c++20', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(exe)],
                       check=True, timeout=60)
        subprocess.run([str(exe)], check=True, timeout=15)
    print('PASS: 64 slots, full-log rejection, counters/state/timers, first-last swap, removal/reuse, equipment boundary')


if __name__ == '__main__':
    main()
