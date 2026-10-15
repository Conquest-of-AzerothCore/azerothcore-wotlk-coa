#include "AscensionManastormRules.h"
#include "AscensionManastormProtocol.h"
#include "AscensionManastormGadgets.h"
#include <atomic>
#include <cassert>
#include <chrono>
#include <cstring>
#include <deque>
#include <fstream>
#include <functional>
#include <list>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <tuple>
#include <vector>
using uint8 = std::uint8_t;
using int8 = std::int8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using namespace Ascension::Manastorm;
using namespace std::chrono_literals;
constexpr uint32 EventCacheDelivery = 2;
constexpr uint32 SPELL_AURA_MOD_XP_PCT = 200;
struct WorldPacket
{
    uint16 opcode = 0;
    std::vector<uint8> bytes;
    WorldPacket(uint16 op = 0, std::size_t = 0) : opcode(op) {}
    uint16 GetOpcode() const
    {
        return opcode;
    }
    std::size_t size() const
    {
        return bytes.size();
    }
    template <class T> T read(std::size_t at) const
    {
        T v;
        std::memcpy(&v, bytes.data() + at, sizeof(T));
        return v;
    }
    template <class T>
        requires std::is_arithmetic_v<T>
    WorldPacket& operator<<(T value)
    {
        auto* p = reinterpret_cast<uint8*>(&value);
        bytes.insert(bytes.end(), p, p + sizeof(T));
        return *this;
    }
    WorldPacket& operator<<(char const* s)
    {
        bytes.insert(bytes.end(), s, s + std::strlen(s) + 1);
        return *this;
    }
};
struct WorldSession
{
    uint64 token = 42;
    uint32 GetAccountId() const
    {
        return 1;
    }
    uint64 GetScriptPacketToken() const
    {
        return token;
    }
};
struct ObjectGuid
{
    uint32 value = 7;
    uint32 GetCounter() const
    {
        return value;
    }
    auto operator<=>(ObjectGuid const&) const = default;
};
enum Statements
{
    CHAR_INS_MANASTORM_CLEAR,
    CHAR_REP_MANASTORM_BONUS,
    CHAR_INS_MAIL,
    CHAR_INS_MAIL_ITEM,
    CHAR_ADD_MANASTORM_XP,
    CHAR_REP_MANASTORM_LOADOUT,
    CHAR_INS_MANASTORM_CACHE,
    ITEM_SAVE
};
struct Statement
{
    Statements type;
    std::map<unsigned, std::string> values;
    void SetData(unsigned i, std::string const& v)
    {
        values[i] = v;
    }
    template <class T> void SetData(unsigned i, T v)
    {
        values[i] = std::to_string(v);
    }
};
struct Transaction
{
    std::vector<std::shared_ptr<Statement>> statements;
    void Append(Statement* s)
    {
        statements.emplace_back(s);
    }
};
using CharacterDatabaseTransaction = std::shared_ptr<Transaction>;
struct Callback
{
    CharacterDatabaseTransaction transaction;
    std::function<void(bool)> callback;
    void AfterComplete(std::function<void(bool)> c)
    {
        callback = std::move(c);
    }
};
struct Database
{
    std::map<std::string, uint32> clears;
    std::map<uint32, uint32> mails, items, attachments, xp;
    std::map<uint32, uint32> pendingCaches;
    std::map<std::string, std::pair<uint32, uint32>> bonus;
    std::map<std::string, uint32> slots;
    auto BeginTransaction()
    {
        return std::make_shared<Transaction>();
    }
    Statement* GetPreparedStatement(Statements t)
    {
        return new Statement{t, {}};
    }
    Callback AsyncCommitTransaction(CharacterDatabaseTransaction t)
    {
        return {t, {}};
    }
    bool Commit(Callback& cb, bool fail = false)
    {
        Database candidate = *this;
        bool success = !fail;
        for (auto const& s : cb.transaction->statements)
        {
            auto const& v = s->values;
            auto n = [&v](unsigned i) { return uint32(std::stoul(v.at(i))); };
            switch (s->type)
            {
                case CHAR_INS_MANASTORM_CLEAR:
                    success &= candidate.clears.emplace(v.at(0) + ":" + v.at(1) + ":" + v.at(2), n(4)).second;
                    break;
                case CHAR_REP_MANASTORM_BONUS:
                    candidate.bonus[v.at(0) + ":" + v.at(1)] = {n(2), n(3)};
                    break;
                case CHAR_INS_MAIL:
                    assert(v.size() == 14 && n(8) == 1 && n(12) == 0);
                    success &= candidate.mails.emplace(n(0), n(5)).second;
                    break;
                case ITEM_SAVE:
                    success &= candidate.items.emplace(n(0), n(1)).second;
                    break;
                case CHAR_INS_MAIL_ITEM:
                    success &= candidate.attachments.emplace(n(1), n(0)).second;
                    break;
                case CHAR_ADD_MANASTORM_XP:
                    candidate.xp[n(0)] += n(1);
                    break;
                case CHAR_REP_MANASTORM_LOADOUT:
                    candidate.slots[v.at(0) + ":" + v.at(1)] = n(2);
                    break;
                case CHAR_INS_MANASTORM_CACHE:
                    success &= candidate.pendingCaches.emplace(n(0), n(1)).second;
                    break;
            }
        }
        if (success)
            *this = std::move(candidate);
        cb.callback(success);
        return success;
    }
} CharacterDatabase;
struct AuraEffect
{
    uint32 GetId() const
    {
        return 0;
    }
};
struct Player
{
    ObjectGuid guid;
    uint32 level = 10;
    float xpMultiplier = 1.0f;
    std::set<uint32> known;
    std::vector<WorldPacket> sent;
    ObjectGuid GetGUID() const
    {
        return guid;
    }
    uint32 GetLevel() const
    {
        return level;
    }
    bool GetsRecruitAFriendBonus(bool forXP)
    {
        assert(forXP);
        return false;
    }
    float GetTotalAuraMultiplier(uint32 aura, std::function<bool(AuraEffect const*)> const& predicate) const
    {
        assert(aura == SPELL_AURA_MOD_XP_PCT);
        AuraEffect const effect;
        return predicate(&effect) ? xpMultiplier : 1.0f;
    }
    bool HasSpell(uint32 id) const
    {
        return known.contains(id);
    }
    void SendDirectMessage(WorldPacket const* p)
    {
        sent.push_back(*p);
    }
};
struct Item
{
    inline static uint32 next = 900, failEntry = 0;
    ObjectGuid guid;
    uint32 entry, count;
    static Item* CreateItem(uint32 entry, uint32 count, Player*)
    {
        if (entry == failEntry)
            return nullptr;
        return new Item{{next++}, entry, count};
    }
    ObjectGuid GetGUID() const
    {
        return guid;
    }
    void SetBinding(bool) {}
    void SaveToDB(CharacterDatabaseTransaction t)
    {
        auto* s = CharacterDatabase.GetPreparedStatement(ITEM_SAVE);
        s->SetData(0, guid.value);
        s->SetData(1, entry);
        t->Append(s);
    }
};
struct Mail
{
    uint32 messageID = 0, messageType = 0, stationery = 0, sender = 0, receiver = 0, money = 0, checked = 0, state = 0;
    std::int64_t deliver_time = 0, expire_time = 0;
    std::string subject, body;
    std::vector<std::pair<uint32, uint32>> items;
    void AddItem(uint32 id, uint32 entry)
    {
        items.emplace_back(id, entry);
    }
};
struct RewardMail
{
    Mail mail{};
    std::vector<std::unique_ptr<Item>> items;
};
constexpr uint32 GuideEntry = 80919, MAIL_CREATURE = 3, MAIL_STATIONERY_DEFAULT = 41, MAIL_CHECK_MASK_HAS_BODY = 16,
                 MAIL_STATE_UNCHANGED = 1, DAY = 86400;
namespace GameTime
{
std::chrono::seconds GetGameTime()
{
    return std::chrono::seconds(100000);
}
}
struct Objects
{
    uint32 next = 100;
    uint32 GenerateMailID()
    {
        return next++;
    }
    uint32 GetXPForLevel(uint32)
    {
        return 1000;
    }
} objects;
auto* sObjectMgr = &objects;
struct MailManager
{
    uint32 sent = 0;
    void OnMailSent(uint32)
    {
        ++sent;
    }
} mailManager;
auto* sMailMgr = &mailManager;
uint32 nextRoll = 1;
uint32 urand(uint32 low, uint32 high)
{
    assert(nextRoll >= low && nextRoll <= high);
    return nextRoll;
}
struct Encounter
{
    Phase phase = Phase::Running;
    uint32 depth = 1, instanceId = 700, bonusCaches = 0, pendingCommits = 0;
    uint8 mode = 0;
};
struct Run
{
    bool cachesPending = false;
    struct Events
    {
        void RescheduleEvent(uint32, std::chrono::milliseconds) {}
    } uiEvents;
    std::shared_ptr<Encounter> encounter = std::make_shared<Encounter>();
    Progress progress;
    uint64 token = 42;
    uint32 pendingXP = 0;
    std::array<uint32, 8> pity{}, caches{};
    std::array<uint32, 4> slots{};
    bool commitReady = false, commitSucceeded = false, progressDirty = false, databaseReady = true,
         loadoutPending = false, loadoutDirty = false;
    uint32 pendingSlot = 0;
    char const* slotResult = nullptr;
    struct Scene
    {
        uint32 stage = 1;
    };
    Scene GetScene() const
    {
        return {};
    }
};
struct Request
{
    uint64 token;
    uint16 opcode;
    uint32 depth;
    uint32 spell = 0;
};
struct Service
{
    std::atomic<bool> enabled{true};
    std::mutex queueMutex;
    std::map<uint32, std::deque<Request>> requests;
    std::map<ObjectGuid, Run> runs;
    std::map<ObjectGuid, std::vector<std::shared_ptr<RewardMail>>> readyMails;
    std::list<Callback> transactions;
    void ReloadXP(ObjectGuid guid, Run& run)
    {
        run.pendingXP = CharacterDatabase.xp[guid.value];
    }
    // ACTUAL_QUEUE
    // ACTUAL_COMPLETE
    // ACTUAL_GADGET
    // ACTUAL_SET_LOADOUT
};
int main(int argc, char** argv)
{
    assert(argc == 2);
    std::string out = argv[1];
    Progress p;
    p[0] = {1, 2, 3};
    p[4] = {1, 8};
    WorldPacket packet;
    WriteProgress(packet, p);
    std::ofstream(out + "/progress.bin", std::ios::binary)
        .write(reinterpret_cast<char*>(packet.bytes.data()), packet.bytes.size());
    for (uint8 mode = 0; mode < 8; ++mode)
    {
        WorldPacket active;
        WriteActive(active, 51, 12, mode, 0, 37.5f, 1278051);
        std::ofstream(out + "/active-" + std::to_string(mode) + ".bin", std::ios::binary)
            .write(reinterpret_cast<char*>(active.bytes.data()), active.bytes.size());
    }
    for (uint32 mode = 0; mode < 2; ++mode)
    {
        std::ofstream f(out + "/checkpoints-" + std::to_string(mode) + ".bin", std::ios::binary);
        for (uint32 depth = 0; depth <= 16385; ++depth)
        {
            auto allowed = uint8(CanStart(depth, 16384, mode != 0));
            f.put(char(allowed));
            if (depth > 1)
                assert(!CanStart(depth, depth - 2, mode != 0));
        }
    }
    assert(CanAdvance(Phase::Completed, 16383) && !CanAdvance(Phase::Completed, 16384) &&
           !CanAdvance(Phase::Running, 1));
    assert(LinkedHealth(2000, 4) == 4000 && LinkedHealth(2000, 8) == 6000 && LinkedHealth(2000, 99) == 6000);
    assert(LinkedHealth(1800000000, 8) == 1800000000);
    for (uint32 depth : {1u, 25u, 1000u, 16384u})
    {
        assert(CacheChance(9999, depth, true) == 10000);
        assert(CacheChance(0, depth, false) == 10000);
    }
    Service s;
    WorldSession session;
    for (auto [opcode, expected] : {std::pair{Enter, 4u}, std::pair{Leave, 0u}, std::pair{SetSlot, 8u}})
    {
        s.requests.clear();
        for (uint32 size = 0; size <= 128; ++size)
        {
            WorldPacket q(opcode);
            q.bytes.resize(size);
            assert(s.Queue(&session, q));
        }
        assert(s.requests[1].size() == 1);
        assert(s.requests[1][0].opcode == opcode);
        WorldPacket q(opcode);
        q.bytes.resize(expected);
        for (unsigned i = 0; i < 1000; ++i)
            s.Queue(&session, q);
        assert(s.requests[1].size() == MaxQueuedRequests);
    }
    s.requests.clear();
    session.token = 0;
    WorldPacket q(Enter);
    q << uint32(1);
    s.Queue(&session, q);
    assert(s.requests.empty());
    Player player;
    Run& run = s.runs[player.guid];
    s.Complete(&player, run);
    assert(run.encounter->pendingCommits == 1 && CharacterDatabase.mails.empty() && s.readyMails.empty());
    assert(CharacterDatabase.Commit(s.transactions.back()));
    assert(run.encounter->pendingCommits == 0 && run.commitReady && run.commitSucceeded);
    assert(CharacterDatabase.clears.size() == 1 && CharacterDatabase.mails.size() == 1 &&
           CharacterDatabase.items.size() == 3);
    assert(CharacterDatabase.attachments.size() == 2 && CharacterDatabase.xp[7] == 75 && run.pendingXP == 75);
    assert(CharacterDatabase.pendingCaches.size() == 1 && run.cachesPending);
    auto& first = *s.readyMails[player.guid].back();
    assert(first.items.size() == 2 && first.items[0]->entry == 1297308 && first.items[1]->entry == 1297307);
    assert(CharacterDatabase.items.at(CharacterDatabase.pendingCaches.begin()->first) == 97877);
    s.Complete(&player, run);
    assert(CharacterDatabase.Commit(s.transactions.back()));
    assert(CharacterDatabase.clears.size() == 1 && CharacterDatabase.items.size() == 5 &&
           CharacterDatabase.xp[7] == 135);
    auto& repeat = *s.readyMails[player.guid].back();
    assert(repeat.items.size() == 1 && repeat.items[0]->entry == 1297308);
    assert(CharacterDatabase.pendingCaches.size() == 2);
    run.progress[0].clear();
    s.Complete(&player, run);
    assert(!CharacterDatabase.Commit(s.transactions.back()));
    assert(CharacterDatabase.mails.size() == 2 && !run.commitSucceeded && CharacterDatabase.items.size() == 5);
    run.encounter->depth = 2;
    s.Complete(&player, run);
    assert(!CharacterDatabase.Commit(s.transactions.back(), true));
    assert(CharacterDatabase.clears.size() == 1 && CharacterDatabase.mails.size() == 2 &&
           CharacterDatabase.xp[7] == 135);
    run.encounter->mode = 4;
    run.encounter->depth = 100;
    player.level = 80;
    nextRoll = 10000;
    s.Complete(&player, run);
    assert(CharacterDatabase.Commit(s.transactions.back()));
    assert(run.pity[4] == 2000);
    assert(s.readyMails[player.guid].back()->items.size() == 2);
    nextRoll = 4000;
    s.Complete(&player, run);
    assert(CharacterDatabase.Commit(s.transactions.back()));
    assert(run.pity[4] == 0);
    assert(s.readyMails[player.guid].back()->items.size() == 1);
    assert(CharacterDatabase.items.at(CharacterDatabase.pendingCaches.rbegin()->first) == 1278051);
    run.encounter->mode = 1;
    run.encounter->depth = 1;
    run.encounter->bonusCaches = 2;
    nextRoll = 1;
    s.Complete(&player, run);
    assert(CharacterDatabase.Commit(s.transactions.back()));
    assert(s.readyMails[player.guid].back()->items.size() == 2);
    assert(CharacterDatabase.pendingCaches.size() == 6);
    assert(s.readyMails[player.guid].back()->items[0]->count == 23);
    run.encounter->depth = 2;
    s.Complete(&player, run);
    run.encounter = std::make_shared<Encounter>();
    run.commitReady = false;
    assert(CharacterDatabase.Commit(s.transactions.back()));
    assert(!run.commitReady);
    run.encounter->depth = 3;
    s.Complete(&player, run);
    auto old = run.encounter;
    s.runs.erase(player.guid);
    assert(CharacterDatabase.Commit(s.transactions.back()));
    assert(old->pendingCommits == 0 && s.readyMails[player.guid].size() >= 6);
    Run& loadout = s.runs[player.guid];
    loadout.encounter->phase = Phase::Idle;
    player.known = {93430};
    s.SetLoadout(&player, loadout, 0, 93430);
    assert(loadout.loadoutPending && loadout.slots[0] == 0);
    assert(CharacterDatabase.Commit(s.transactions.back()));
    assert(loadout.slots[0] == 93430 && !loadout.loadoutPending);
    auto count = s.transactions.size();
    s.SetLoadout(&player, loadout, 1, 93430);
    assert(s.transactions.size() == count);
    s.SetLoadout(&player, loadout, 4, 93430);
    assert(s.transactions.size() == count);
    s.SetLoadout(&player, loadout, 1, 93429);
    assert(s.transactions.size() == count);
    loadout.encounter->phase = Phase::Running;
    s.SetLoadout(&player, loadout, 0, 0);
    assert(s.transactions.size() == count);
    loadout.encounter->phase = Phase::Idle;
    s.SetLoadout(&player, loadout, 0, 0);
    assert(!CharacterDatabase.Commit(s.transactions.back(), true));
    assert(loadout.slots[0] == 93430);
    s.SetLoadout(&player, loadout, 0, 0);
    assert(CharacterDatabase.Commit(s.transactions.back()));
    assert(loadout.slots[0] == 0);
    uint32 guid = 100;
    for (auto const& [multiplier, firstXP, repeatXP] :
         {std::tuple{1.0f, 75u, 60u}, {1.25f, 93u, 75u}, {1.5f, 112u, 90u}, {1.875f, 140u, 112u}})
    {
        Player boosted;
        boosted.guid.value = guid++;
        boosted.xpMultiplier = multiplier;
        Run& rewardRun = s.runs[boosted.guid];
        s.Complete(&boosted, rewardRun);
        boosted.xpMultiplier = 1.0f;
        assert(CharacterDatabase.Commit(s.transactions.back()));
        assert(CharacterDatabase.xp[boosted.guid.value] == firstXP && rewardRun.pendingXP == firstXP);
        boosted.xpMultiplier = multiplier;
        s.Complete(&boosted, rewardRun);
        assert(CharacterDatabase.Commit(s.transactions.back()));
        assert(CharacterDatabase.xp[boosted.guid.value] == firstXP + repeatXP);
        rewardRun.encounter->mode = 4;
        s.Complete(&boosted, rewardRun);
        assert(CharacterDatabase.Commit(s.transactions.back()));
        assert(CharacterDatabase.xp[boosted.guid.value] == firstXP + repeatXP);
    }
    return 0;
}
