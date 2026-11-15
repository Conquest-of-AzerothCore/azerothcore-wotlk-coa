from pathlib import Path
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


manager = (S / 'src/server/game/Battlegrounds/ArenaTeamMgr.cpp').read_text()
handler = (S / 'src/server/game/Handlers/CharacterHandler.cpp').read_text()
solo_queue = (S / 'src/server/coa/AscensionArenaQueue.cpp').read_text()

assert 'team->Create(player->GetGUID(), bracket.TeamType' in solo_queue
assert 'sArenaTeamMgr->IsCaptainOfTeamWithOtherMembers(factionChangeInfo->Guid)' in handler
assert 'GetArenaTeamByCaptain(factionChangeInfo->Guid)' not in handler
disband = handler.index('sArenaTeamMgr->DisbandSoloTeamsOfCaptain(factionChangeInfo->Guid);')
leave = handler.index('Player::LeaveAllArenaTeams(factionChangeInfo->Guid);')
assert 0 < leave - disband < 120

code = r'''
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <unordered_map>
#include <vector>
using uint32 = std::uint32_t;
struct ObjectGuid
{
    uint32 value = 0;
    bool operator==(ObjectGuid const&) const = default;
};
class ArenaTeamMgr;
ArenaTeamMgr* ArenaTeamMgrInstance();
class ArenaTeam
{
public:
    ArenaTeam(uint32 id, ObjectGuid captain, std::size_t members) : _id(id), _captain(captain), _members(members) { }
    ~ArenaTeam() { ++Deleted; }
    ObjectGuid GetCaptain() const { return _captain; }
    std::size_t GetMembersSize() const { return _members; }
    void Disband();
    uint32 GetId() const { return _id; }
    inline static int Deleted = 0;
    bool Disbanded = false;
private:
    uint32 _id;
    ObjectGuid _captain;
    std::size_t _members;
};
class ArenaTeamMgr
{
public:
    using ArenaTeamContainer = std::unordered_map<uint32, ArenaTeam*>;
    bool IsCaptainOfTeamWithOtherMembers(ObjectGuid guid) const;
    void DisbandSoloTeamsOfCaptain(ObjectGuid guid);
    void RemoveArenaTeam(uint32 id) { ArenaTeamStore.erase(id); }
    ArenaTeamContainer ArenaTeamStore;
};
ArenaTeamMgr Manager;
ArenaTeamMgr* ArenaTeamMgrInstance() { return &Manager; }
#define sArenaTeamMgr ArenaTeamMgrInstance()
void ArenaTeam::Disband()
{
    _members = 0;
    Disbanded = true;
    sArenaTeamMgr->RemoveArenaTeam(_id);
}
''' + extract(manager, 'bool ArenaTeamMgr::IsCaptainOfTeamWithOtherMembers(') + '\n' + extract(
    manager, 'void ArenaTeamMgr::DisbandSoloTeamsOfCaptain(') + r'''
ArenaTeam* Add(uint32 id, uint32 captain, std::size_t members)
{
    auto* team = new ArenaTeam(id, ObjectGuid{captain}, members);
    Manager.ArenaTeamStore[id] = team;
    return team;
}
void Reset()
{
    for (auto& [id, team] : Manager.ArenaTeamStore)
        delete team;
    Manager.ArenaTeamStore.clear();
    ArenaTeam::Deleted = 0;
}
int main()
{
    ObjectGuid const player{7};
    ObjectGuid const other{8};

    Add(1, 7, 1);
    assert(!Manager.IsCaptainOfTeamWithOtherMembers(player));
    Reset();

    Add(1, 7, 2);
    assert(Manager.IsCaptainOfTeamWithOtherMembers(player));
    assert(!Manager.IsCaptainOfTeamWithOtherMembers(other));
    Reset();

    Add(1, 7, 1);
    Add(2, 7, 3);
    Add(3, 7, 1);
    assert(Manager.IsCaptainOfTeamWithOtherMembers(player));
    Reset();

    Add(1, 8, 4);
    assert(!Manager.IsCaptainOfTeamWithOtherMembers(player));
    Reset();

    ArenaTeam* solo2 = Add(1, 7, 1);
    ArenaTeam* solo3 = Add(2, 7, 1);
    ArenaTeam* empty = Add(3, 7, 0);
    ArenaTeam* shared = Add(4, 7, 2);
    ArenaTeam* foreign = Add(5, 8, 1);
    ArenaTeam* foreign_shared = Add(6, 8, 3);
    (void)solo2; (void)solo3; (void)empty;
    Manager.DisbandSoloTeamsOfCaptain(player);
    assert(Manager.ArenaTeamStore.size() == 3);
    assert(Manager.ArenaTeamStore.count(1) == 0 && Manager.ArenaTeamStore.count(2) == 0 &&
        Manager.ArenaTeamStore.count(3) == 0);
    assert(ArenaTeam::Deleted == 3);
    assert(Manager.ArenaTeamStore.at(4) == shared && !shared->Disbanded && shared->GetMembersSize() == 2);
    assert(Manager.ArenaTeamStore.at(5) == foreign && !foreign->Disbanded);
    assert(Manager.ArenaTeamStore.at(6) == foreign_shared && !foreign_shared->Disbanded);
    assert(Manager.IsCaptainOfTeamWithOtherMembers(player));
    Reset();

    Add(1, 7, 1);
    Manager.DisbandSoloTeamsOfCaptain(player);
    assert(Manager.ArenaTeamStore.empty());
    assert(!Manager.IsCaptainOfTeamWithOtherMembers(player));
    Manager.DisbandSoloTeamsOfCaptain(player);
    Reset();
    return 0;
}
'''

with tempfile.TemporaryDirectory() as directory:
    path = Path(directory)
    (path / 'check.cpp').write_text(code)
    subprocess.run(['g++', '-std=c++20', '-Wall', '-Wextra', '-Werror', '-fsanitize=address,undefined',
                    str(path / 'check.cpp'), '-o', str(path / 'check')], check=True)
    subprocess.run([str(path / 'check')], check=True)
