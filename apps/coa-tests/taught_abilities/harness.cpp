#include <algorithm>
#include <array>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <map>
#include <mutex>
#include <set>
#include <unordered_map>
#include <vector>

using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
constexpr uint8 SPEC_MASK_ALL = 3, MAX_SPELL_EFFECTS = 3;
constexpr uint32 SPELL_ATTR0_PASSIVE = 64, SPELL_ATTR0_DO_NOT_DISPLAY = 128, SPELL_EFFECT_LEARN_SPELL = 36;
using SpellAttr0 = uint32;
#define LOG_INFO(...) ((void)0)
#define LOG_DEBUG(...) ((void)0)

// ACTUAL_CLASSES
// ACTUAL_STATE
// ACTUAL_SPELL_RECORD
// ACTUAL_DATA

struct SpellEffect
{
    uint32 Effect = 0, TriggerSpell = 0;
    bool IsEffect() const { return Effect != 0; }
};

struct SpellInfo
{
    uint32 Id = 0;
    bool IsDeprecatedForPlayers = false;
    std::array<SpellEffect, 3> Effects{};
    bool HasAttribute(uint32) const { return false; }
    bool HasAnyAura() const { return false; }
    bool HasEffect(uint32 id) const
    {
        return std::any_of(Effects.begin(), Effects.end(), [id](auto const& effect) { return effect.Effect == id; });
    }
};

using SpellsRequiringSpellMap = std::map<uint32, uint32>;
using SpellsRequiringSpellMapBounds = std::pair<SpellsRequiringSpellMap::const_iterator,
    SpellsRequiringSpellMap::const_iterator>;
struct SpellMgr
{
    std::map<uint32, SpellInfo> records;
    std::map<uint32, uint32> roots;
    std::map<uint32, uint32> nextRanks;
    std::map<uint32, uint32> rankNumbers;
    std::set<uint32> missing;
    SpellsRequiringSpellMap dependencies;
    SpellInfo const* GetSpellInfo(uint32 id) const
    {
        auto itr = records.find(id);
        return missing.contains(id) || itr == records.end() ? nullptr : &itr->second;
    }
    static bool CheckSpellValid(SpellInfo const* info, uint32, bool) { return info != nullptr; }
    uint32 GetNextSpellInChain(uint32 id) const { return nextRanks.contains(id) ? nextRanks.at(id) : 0; }
    uint32 GetFirstSpellInChain(uint32 id) const { return roots.contains(id) ? roots.at(id) : id; }
    uint32 GetSpellRank(uint32 id) const { return rankNumbers.contains(id) ? rankNumbers.at(id) : 0; }
    bool IsAdditionalTalentSpell(uint32) const { return false; }
    auto GetSpellsRequiringSpellBounds(uint32) const
    {
        return std::make_pair(dependencies.begin(), dependencies.end());
    }
} manager;
auto sSpellMgr = &manager;
uint32 GetTalentSpellCost(uint32) { return 0; }
void const* GetTalentSpellPos(uint32) { return nullptr; }
bool IsAscensionClass(uint32 cls) { return cls >= 12 && cls <= 32; }

struct Guid
{
    uint32 GetCounter() const { return 1; }
    uint32 GetRawValue() const { return 1; }
    uint32 ToString() const { return 1; }
};
using PlayerSpellMap = std::map<uint32, PlayerSpell*>;
constexpr uint32 CHAR_DEL_CHAR_SPELL_BY_SPELL = 1, CHAR_INS_CHAR_SPELL = 2;
struct CharacterDatabasePreparedStatement
{
    uint32 kind = 0;
    std::array<uint32, 3> data{};
    void SetData(uint32 index, uint32 value) { data[index] = value; }
};
struct Database
{
    CharacterDatabasePreparedStatement statement{};
    auto GetPreparedStatement(uint32 kind)
    {
        statement = {kind, {}};
        return &statement;
    }
} CharacterDatabase;
struct Transaction
{
    std::vector<CharacterDatabasePreparedStatement> statements;
    void Append(CharacterDatabasePreparedStatement* statement) { statements.push_back(*statement); }
};
using CharacterDatabaseTransaction = Transaction*;

constexpr uint32 SMSG_SUPERCEDED_SPELL = 1;
struct WorldPacket
{
    std::vector<uint32> values;
    WorldPacket(uint32, uint32) { }
    WorldPacket& operator<<(uint32 value)
    {
        values.push_back(value);
        return *this;
    }
};
struct Session
{
    std::vector<std::vector<uint32>> replacements;
    void SendPacket(WorldPacket* packet) { replacements.push_back(packet->values); }
};

struct Aura
{
    bool Removed = false;
    bool IsRemoved() const { return Removed; }
};

struct Player
{
    uint32 cls = 16, level = 80, learnPackets = 0;
    bool dualWield = false;
    uint32 offhandChecks = 0;
    uint8 m_activeSpec = 0;
    PlayerSpellMap m_spells;
    std::map<uint32, uint32> m_temporarySpellReplacements;
    std::map<uint32, uint32> m_temporarySpellReplacementOrigins;
    std::map<uint32, Aura> auras;
    Session session;
    Player() = default;
    Player(Player const&) = delete;
    ~Player()
    {
        for (auto const& entry : m_spells)
            delete entry.second;
    }
    uint32 getClass() const { return cls; }
    uint32 GetLevel() const { return level; }
    bool CanDualWield() const { return dualWield; }
    void SetCanDualWield(bool value) { dualWield = value; }
    void AutoUnequipOffhandIfNeed() { ++offhandChecks; }
    Guid GetGUID() const { return {}; }
    Aura const* GetAura(uint32 id, Guid) const
    {
        auto const itr = auras.find(id);
        return itr == auras.end() ? nullptr : &itr->second;
    }
    auto const& GetSpellMap() const { return m_spells; }
    Session* GetSession() { return &session; }
    bool IsInWorld() const { return true; }
    bool isBeingLoaded() const { return false; }
    uint8 GetActiveSpec() const { return m_activeSpec; }
    uint8 GetLearnSpellSpecMask(uint32) const { return SPEC_MASK_ALL; }
    bool HasSpell(uint32) const;
    bool HasActiveSpell(uint32) const;
    bool _addSpell(uint32, uint8, bool, bool = false);
    void learnSpell(uint32, bool = false, bool = false);
    void learnSpellWithoutAnnouncement(uint32, bool = true);
    void _learnSpell(uint32, bool, bool, bool);
    void removeSpell(uint32, uint8, bool);
    bool addSpell(uint32 id, uint8 mask, bool, bool temporary, bool skill)
    {
        return _addSpell(id, mask, temporary, skill);
    }
    void SendLearnPacket(uint32, bool, bool = false) { ++learnPackets; }
    void _SaveSpells(CharacterDatabaseTransaction);
    void SetTemporarySpellReplacement(uint32, uint32);
    uint32 GetTemporarySpellReplacement(uint32) const;
    void Put(uint32 id, PlayerSpellState state = PLAYERSPELL_UNCHANGED, uint8 mask = 3)
    {
        assert(!m_spells.contains(id));
        m_spells[id] = new PlayerSpell{state, true, mask};
    }
};
bool IsAscensionCustomClass(Player const* player) { return IsAscensionClass(player->getClass()); }
void SynchronizeAscensionRunemasterEchoes(Player*, uint32) { }
void RemoveAscensionPrimalistWeapons(Player*) { }
namespace AscensionWildcard
{
constexpr std::array<uint32, 1> SPECIALIZATION_SWAP_SPELLS = { 979993 };
bool IsWildcardHero(Player const*) { return false; }
}

struct AscensionClassService
{
    mutable std::mutex _stateLock;
    std::unordered_map<uint32, uint32> _activeSpecializations;
    static AscensionClassService& Instance()
    {
        static AscensionClassService service;
        return service;
    }
    bool AffectsProficiencies(uint32) const { return false; }
    void SynchronizeProficiencies(Player*) { }
    void SendActiveSlot(Player*) { }
    static void ReconcileRunemasterFists(Player*, uint32) { }
    // ACTUAL_SERVICE
};
namespace AscensionCompatConfig
{
constexpr uint32 ENABLED = 0;
}
struct Config
{
    bool enabled = true;
    template<typename T> T GetConfigValue(uint32) const { return enabled; }
} ascensionCompatConfig;
struct ScriptMgr
{
    void OnPlayerTemporarySpellLearnNotice(Player*, uint32, bool) { }
    void OnPlayerTemporarySpellRemoveNotice(Player*, uint32, bool) { }
    void OnPlayerTemporarySpellReplacementNotice(Player*, uint32, uint32, bool) { }
    // ACTUAL_HOOKS
} scripts;
auto sScriptMgr = &scripts;

// ACTUAL_PLAYER

void CheckReplacements()
{
    auto& service = AscensionClassService::Instance();
    for (auto const& entry : AscensionCompatData::TalentReplacements)
    {
        manager.records[entry.ParentSpellId].Id = entry.ParentSpellId;
        manager.records[entry.OriginalSpellId].Id = entry.OriginalSpellId;
        for (auto const& rank : entry.Ranks)
            if (rank.SpellId)
                manager.records[rank.SpellId].Id = rank.SpellId;
    }
    for (auto const& entry : AscensionCompatData::TalentReplacements)
    {
        if (entry.RequiresAura)
            continue;
        uint32 const original = entry.OriginalSpellId, parent = entry.ParentSpellId;
        uint32 const base = entry.Ranks.front().SpellId;
        Player player;
        player.cls = entry.ClassId;
        player.level = 10;
        service._activeSpecializations[1] = entry.SpecId;
        player.learnSpell(parent);
        assert(!player.HasSpell(base));
        player.learnSpell(original);
        if (!player.HasSpell(base) || player.GetTemporarySpellReplacement(original) != base)
        {
            std::cerr << "Missing replacement " << base << " for " << original << " from " << parent << '\n';
            std::exit(88);
        }
        auto packets = player.session.replacements.size();
        service.SynchronizeTalentReplacements(&player);
        assert(player.session.replacements.size() == packets);
        uint32 previous = base;
        for (auto const& rank : entry.Ranks)
        {
            if (!rank.SpellId || !rank.RequiredLevel)
                continue;
            assert(!service.AffectsTalentReplacements(rank.SpellId));
            player.level = rank.RequiredLevel - 1;
            service.SynchronizeTalentReplacements(&player);
            assert(player.GetTemporarySpellReplacement(original) == previous);
            player.level = rank.RequiredLevel;
            service.SynchronizeTalentReplacements(&player);
            assert(player.GetTemporarySpellReplacement(original) == rank.SpellId);
            assert(!player.HasSpell(previous));
            previous = rank.SpellId;
        }
        uint32 const highest = previous;
        Transaction save;
        player._SaveSpells(&save);
        for (auto const& statement : save.statements)
            assert(statement.data[1] != highest);
        player.level = 10;
        service.SynchronizeTalentReplacements(&player);
        assert(player.GetTemporarySpellReplacement(original) == base);
        player.removeSpell(parent, SPEC_MASK_ALL, false);
        assert(player.GetTemporarySpellReplacement(original) == original && !player.HasSpell(base));
        player.learnSpell(parent);
        assert(player.GetTemporarySpellReplacement(original) == base);
        player.removeSpell(original, SPEC_MASK_ALL, false);
        assert(!player.m_temporarySpellReplacements.contains(original) && !player.HasSpell(base));
        player.learnSpell(original);
        assert(player.GetTemporarySpellReplacement(original) == base);
        service._activeSpecializations[1] = 0;
        service.SynchronizeTalentReplacements(&player);
        assert(!player.HasSpell(base));
        service._activeSpecializations[1] = entry.SpecId;
        service.SynchronizeTalentReplacements(&player);
        assert(player.HasSpell(base));
        player.m_spells.at(parent)->specMask = 1;
        player.m_activeSpec = 1;
        scripts.OnPlayerAfterSpecSlotChanged(&player, 1);
        assert(player.GetTemporarySpellReplacement(original) == original && !player.HasSpell(base));
        player.m_activeSpec = 0;
        scripts.OnPlayerAfterSpecSlotChanged(&player, 0);
        assert(player.HasSpell(base));

        player.removeSpell(base, SPEC_MASK_ALL, true);
        player.Put(base, PLAYERSPELL_REMOVED, 0);
        service.SynchronizeTalentReplacements(&player);
        assert(!player.HasSpell(base));
        assert(player.GetTemporarySpellReplacement(original) == original);
        Transaction deletion;
        player._SaveSpells(&deletion);
        manager.missing.insert(base);
        service.SynchronizeTalentReplacements(&player);
        assert(!player.HasSpell(base));
        manager.missing.clear();
        service.SynchronizeTalentReplacements(&player);
        assert(player.HasSpell(base));
        player.removeSpell(base, SPEC_MASK_ALL, true);
        player.Put(base);
        player.removeSpell(parent, SPEC_MASK_ALL, false);
        assert(player.HasSpell(base));

        Player otherSpec;
        otherSpec.cls = entry.ClassId;
        otherSpec.level = 10;
        otherSpec.Put(base, PLAYERSPELL_UNCHANGED, 2);
        otherSpec.Put(original);
        otherSpec.learnSpell(parent);
        assert(otherSpec.GetTemporarySpellReplacement(original) == original);
        assert(otherSpec.m_spells.at(base)->specMask == 2);

        Player relog;
        relog.cls = entry.ClassId;
        relog.level = 10;
        relog.Put(parent);
        relog.Put(original);
        service._activeSpecializations.clear();
        service.SynchronizeTalentReplacements(&relog);
        assert(!relog.HasSpell(base));
        service._activeSpecializations[1] = entry.SpecId;
        service.SynchronizeTalentReplacements(&relog);
        assert(relog.GetTemporarySpellReplacement(original) == base);

        uint32 const originalRank = original + 10000000;
        manager.records[originalRank].Id = originalRank;
        manager.roots[originalRank] = original;
        relog.learnSpell(originalRank);
        assert(relog.GetTemporarySpellReplacement(originalRank) == base);
        relog.removeSpell(originalRank, SPEC_MASK_ALL, false);
        assert(!relog.m_temporarySpellReplacements.contains(originalRank));
        assert(relog.GetTemporarySpellReplacement(original) == base);
    }
    for (auto const& entry : AscensionCompatData::TalentReplacements)
    {
        if (!entry.RequiresAura)
            continue;
        Player player;
        player.cls = entry.ClassId;
        uint32 const original = entry.OriginalSpellId, parent = entry.ParentSpellId;
        uint32 const child = entry.Ranks.front().SpellId;
        player.learnSpell(parent);
        player.learnSpell(original);
        assert(!player.HasSpell(child));
        assert(player.GetTemporarySpellReplacement(original) == original);
        player.auras[parent] = {};
        service.SynchronizeTalentReplacements(&player);
        assert(player.HasSpell(child));
        assert(player.GetTemporarySpellReplacement(original) == child);
        player.auras[parent].Removed = true;
        service.SynchronizeTalentReplacements(&player);
        assert(!player.HasSpell(child));
        assert(player.GetTemporarySpellReplacement(original) == original);
        player.auras[parent].Removed = false;
        service.SynchronizeTalentReplacements(&player);
        player.removeSpell(original, SPEC_MASK_ALL, false);
        assert(!player.HasSpell(child));
        player.learnSpell(original);
        assert(player.HasSpell(child));
        player.auras.erase(parent);
        service.SynchronizeTalentReplacements(&player);
        assert(!player.HasSpell(child));
        player.Put(child);
        player.auras[parent] = {};
        service.SynchronizeTalentReplacements(&player);
        player.auras.erase(parent);
        service.SynchronizeTalentReplacements(&player);
        assert(player.HasSpell(child));
        assert(player.GetTemporarySpellReplacement(original) == original);
    }
    Player blood;
    blood.cls = 20;
    blood.Put(562720);
    for (uint32 id : {505188u, 504728u, 504710u})
        blood.Put(id);
    for (auto const& entry : AscensionCompatData::TalentReplacements)
        if (entry.ClassId == 20)
        {
            service._activeSpecializations[1] = entry.SpecId;
            service.SynchronizeTalentReplacements(&blood);
            assert(blood.GetTemporarySpellReplacement(562720) == entry.Ranks.front().SpellId);
            for (uint32 id : {680692u, 801076u, 562572u})
                assert(blood.HasSpell(id) == (id == entry.Ranks.front().SpellId));
        }
    std::cout << "PASS: " << AscensionCompatData::TalentReplacements.size()
        << " transformation routes, rank gates, callbacks, native routing and ownership cleanup\n";
}

int main()
{
    auto& service = AscensionClassService::Instance();
    std::array<AscensionCompatData::TaughtAbility, 13> expected = {{
        {12, 3, 0, 804729, 804834}, {13, 6, 0, 561069, 801662}, {16, 13, 10, 92097, 804019},
        {15, 11, 0, 801343, 578118}, {15, 11, 0, 801343, 680263},
        {20, 99, 10, 92114, 800157}, {20, 99, 10, 92114, 674}, {22, 31, 10, 92119, 806291},
        {25, 40, 10, 92131, 520326}, {25, 96, 10, 680750, 567524},
        {31, 59, 10, 92148, 574302}, {31, 59, 10, 92148, 574303}, {31, 59, 10, 92148, 500860}
    }};
    for (auto const& entry : AscensionCompatData::TaughtAbilities)
    {
        manager.records[entry.ParentSpellId].Id = entry.ParentSpellId;
        manager.records[entry.SpellId].Id = entry.SpellId;
    }
    for (auto const& entry : expected)
    {
        manager.records[entry.ParentSpellId].Id = entry.ParentSpellId;
        manager.records[entry.SpellId].Id = entry.SpellId;
        Player player;
        player.cls = entry.ClassId;
        service._activeSpecializations[1] = entry.SpecId;
        player.learnSpell(entry.ParentSpellId);
        if (!player.HasSpell(entry.SpellId))
        {
            std::cerr << "Missing promised ability " << entry.SpellId << " from " << entry.ParentSpellId << '\n';
            return 88;
        }
    }

    Player eternal;
    eternal.cls = CLASS_SON_OF_ARUGAL;
    service._activeSpecializations[1] = 99;
    eternal.learnSpell(92114);
    assert(eternal.HasSpell(674) && eternal.CanDualWield());
    service.SynchronizeTaughtAbilities(&eternal);
    assert(eternal.offhandChecks == 0);
    eternal.removeSpell(92114, SPEC_MASK_ALL, false);
    assert(!eternal.HasSpell(674) && !eternal.CanDualWield() && eternal.offhandChecks == 1);
    eternal.learnSpell(92114);
    eternal.m_spells.at(92114)->specMask = 1;
    eternal.m_activeSpec = 1;
    scripts.OnPlayerAfterSpecSlotChanged(&eternal, 1);
    assert(!eternal.CanDualWield() && eternal.offhandChecks == 2);
    eternal.Put(674, PLAYERSPELL_UNCHANGED, 2);
    service.SynchronizeTaughtAbilities(&eternal);
    assert(eternal.CanDualWield());
    service._activeSpecializations[1] = 0;
    service.SynchronizeTaughtAbilities(&eternal);
    assert(eternal.CanDualWield() && eternal.offhandChecks == 2);

    for (auto const& entry : AscensionCompatData::TaughtAbilities)
    {
        Player player;
        player.cls = entry.ClassId;
        service._activeSpecializations.clear();
        player.learnSpell(entry.ParentSpellId);
        assert(!player.HasSpell(entry.SpellId));
        service._activeSpecializations[1] = entry.SpecId;
        service.SynchronizeTaughtAbilities(&player);
        assert(player.HasSpell(entry.SpellId));
        assert(player.m_spells.at(entry.SpellId)->State == PLAYERSPELL_TEMPORARY);
        uint32 packets = player.learnPackets;
        assert(service.SynchronizeTaughtAbilities(&player) == 0 && player.learnPackets == packets);
        Transaction save;
        player._SaveSpells(&save);
        for (auto const& statement : save.statements)
            assert(statement.data[1] != entry.SpellId);
        player.removeSpell(entry.ParentSpellId, SPEC_MASK_ALL, false);
        assert(!player.HasSpell(entry.SpellId));
        player.learnSpell(entry.ParentSpellId);
        assert(player.HasSpell(entry.SpellId));
        if (entry.RequiredLevel)
        {
            player.level = entry.RequiredLevel - 1;
            service.SynchronizeTaughtAbilities(&player);
            assert(!player.HasSpell(entry.SpellId));
            player.level = entry.RequiredLevel;
            service.SynchronizeTaughtAbilities(&player);
            assert(player.HasSpell(entry.SpellId));
        }
        service._activeSpecializations[1] = 999;
        service.SynchronizeTaughtAbilities(&player);
        assert(!player.HasSpell(entry.SpellId));
        service._activeSpecializations[1] = entry.SpecId;
        service.SynchronizeTaughtAbilities(&player);
        player.m_spells.at(entry.ParentSpellId)->specMask = 1;
        player.m_activeSpec = 1;
        service.SynchronizeTaughtAbilities(&player);
        assert(!player.HasSpell(entry.SpellId));
        player.m_activeSpec = 0;
        manager.missing.insert(entry.SpellId);
        service.SynchronizeTaughtAbilities(&player);
        assert(!player.HasSpell(entry.SpellId));
        manager.missing.clear();
        service.SynchronizeTaughtAbilities(&player);
        assert(player.HasSpell(entry.SpellId));
        player.removeSpell(entry.SpellId, SPEC_MASK_ALL, true);
        player.Put(entry.SpellId, PLAYERSPELL_REMOVED, 0);
        service.SynchronizeTaughtAbilities(&player);
        assert(player.m_spells.at(entry.SpellId)->State == PLAYERSPELL_REMOVED);
        Transaction deletion;
        player._SaveSpells(&deletion);
        service.SynchronizeTaughtAbilities(&player);
        assert(player.HasSpell(entry.SpellId));
        player.removeSpell(entry.SpellId, SPEC_MASK_ALL, true);
        player.Put(entry.SpellId);
        player.removeSpell(entry.ParentSpellId, SPEC_MASK_ALL, false);
        assert(player.HasSpell(entry.SpellId) && player.m_spells.at(entry.SpellId)->State != PLAYERSPELL_TEMPORARY);

        Player otherSpec;
        otherSpec.cls = entry.ClassId;
        otherSpec.Put(entry.SpellId, PLAYERSPELL_UNCHANGED, 2);
        otherSpec.learnSpell(entry.ParentSpellId);
        assert(!otherSpec.HasSpell(entry.SpellId));
        assert(otherSpec.m_spells.at(entry.SpellId)->specMask == 2);

        for (uint32 cls : {1u, 33u, entry.ClassId == 12 ? 13u : 12u})
        {
            Player otherClass;
            otherClass.cls = cls;
            otherClass.learnSpell(entry.ParentSpellId);
            assert(!otherClass.HasSpell(entry.SpellId));
        }
    }

    for (uint32 parent : {537218u, 300728u, 504088u, 806302u, 520925u})
        assert(!service.AffectsTaughtAbilities(parent));
    CheckReplacements();
    std::cout << "PASS: explicit active grants, Shadowhound utilities, Eternal dual wield, and all "
        << AscensionCompatData::TaughtAbilities.size()
              << " parent/level/spec/native ownership/save lifecycles\n";
}
