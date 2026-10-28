#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

using uint8 = std::uint8_t;
using int8 = std::int8_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;

template <typename T>
using Optional = std::optional<T>;

enum ReactStates : uint8
{
    REACT_PASSIVE = 0
};

// ACTUAL_PET_DEFINES

// ACTUAL_PET_STABLE

// ACTUAL_TAME_FAILURE

// ACTUAL_DELETE_FILTER

enum SpellCastResult
{
    SPELL_FAILED_DONT_REPORT = 1,
    SPELL_CAST_OK = 255
};

enum CharacterDatabaseStatements
{
    CHAR_UPD_CHAR_PET_SLOT_BY_ID
};

enum UnitFields
{
    UNIT_FIELD_LEVEL
};

enum PlayerHook
{
    PLAYERHOOK_ON_FORGOT_SPELL
};

template <typename... Args>
void LogSink(Args const&...) { }

#define LOG_ERROR(...) LogSink(__VA_ARGS__)
#define LOG_INFO(...) LogSink(__VA_ARGS__)

[[noreturn]] void Fail(char const* message)
{
    std::fprintf(stderr, "FAIL: %s\n", message);
    std::exit(1);
}

void Require(bool condition, char const* message)
{
    if (!condition)
        Fail(message);
}

struct Row
{
    uint32 Slot;
    PetType Type;
};

std::map<uint32, Row> Db;
std::vector<std::pair<uint32, int>> Saves;
std::vector<std::pair<uint32, uint32>> Updates;

void SaveRow(uint32 number, PetType type, PetSaveMode mode)
{
    Saves.emplace_back(number, int(mode));
    Db.erase(number);
    if (mode < PET_SAVE_AS_CURRENT)
        return;
    if (type == HUNTER_PET && (mode == PET_SAVE_AS_CURRENT || mode > PET_SAVE_LAST_STABLE_SLOT))
    {
        for (auto row = Db.begin(); row != Db.end();)
        {
            if ((row->second.Slot == 0 || row->second.Slot > uint32(PET_SAVE_LAST_STABLE_SLOT)) &&
                (!DeleteFiltersPetType || row->second.Type == HUNTER_PET))
                row = Db.erase(row);
            else
                ++row;
        }
    }
    Db[number] = { uint32(uint8(mode)), type };
}

struct CharacterDatabasePreparedStatement
{
    std::array<uint64, 4> Values{};

    template <typename T>
    void SetData(int index, T value) { Values[index] = uint64(value); }
};

struct CharacterDatabaseWorker
{
    std::vector<std::unique_ptr<CharacterDatabasePreparedStatement>> Statements;

    CharacterDatabasePreparedStatement* GetPreparedStatement(CharacterDatabaseStatements)
    {
        Statements.push_back(std::make_unique<CharacterDatabasePreparedStatement>());
        return Statements.back().get();
    }

    void Execute(CharacterDatabasePreparedStatement* stmt)
    {
        uint32 const number = uint32(stmt->Values[2]);
        Updates.emplace_back(number, uint32(stmt->Values[0]));
        if (auto row = Db.find(number); row != Db.end())
            row->second.Slot = uint32(stmt->Values[0]);
    }
} CharacterDatabase;

struct CreatureTemplate
{
    uint32 type = 0;
    bool Tameable = true;

    bool IsTameable(bool) const { return Tameable; }
};

struct ObjectMgr
{
    std::map<uint32, CreatureTemplate> Templates;

    CreatureTemplate const* GetCreatureTemplate(uint32 entry) const
    {
        auto found = Templates.find(entry);
        return found == Templates.end() ? nullptr : &found->second;
    }
} ObjectStore;

ObjectMgr* const sObjectMgr = &ObjectStore;

struct ObjectGuid
{
    uint32 Counter = 0;

    uint32 GetCounter() const { return Counter; }
    explicit operator bool() const { return Counter != 0; }
};

struct SpellInfo
{
    uint32 Id;
};

class Player;
class Pet;

class Creature
{
};

struct Map
{
    void AddToMap(Creature*, bool) { }
};

class Unit : public Creature
{
public:
    virtual ~Unit() = default;
    virtual Player* ToPlayer() { return nullptr; }
};

class Pet : public Unit
{
public:
    uint32 Entry = 0;
    PetType Type = HUNTER_PET;
    bool Alive = true;
    uint32 Number = 0;
    Map PetMap;

    uint32 GetEntry() const { return Entry; }
    PetType getPetType() const { return Type; }
    bool IsAlive() const { return Alive; }
    void SetUInt32Value(UnitFields, uint32) { }
    Map* GetMap() { return &PetMap; }
    Creature* ToCreature() { return this; }
    void InitTalentForLevel() { }
    void SavePetToDB(PetSaveMode mode) { SaveRow(Number, Type, mode); }
};

uint32 NextPetNumber = 1000;
std::vector<std::unique_ptr<Pet>> AllPets;

class Player : public Unit
{
public:
    std::optional<PetStable> Stable;
    Pet* Out = nullptr;
    bool Charmed = false;
    std::optional<uint8> TameFailure;
    uint32 StarterCalls = 0;
    bool UnsafeStarter = false;

    Player* ToPlayer() override { return this; }
    ObjectGuid GetGUID() const { return { 42 }; }
    PetStable& GetOrInitPetStable()
    {
        if (!Stable)
            Stable.emplace();
        return *Stable;
    }
    PetStable* GetPetStable() { return Stable ? &*Stable : nullptr; }
    Pet* GetPet() const { return Out; }
    ObjectGuid GetPetGUID() const { return { Out ? 7u : 0u }; }
    ObjectGuid GetCharmGUID() const { return { Charmed ? 9u : 0u }; }
    std::string GetName() const { return "Hero"; }
    uint8 GetLevel() const { return 20; }
    bool CanTameExoticPets() const { return false; }
    void SendTameFailure(uint8 reason) { TameFailure = reason; }
    void SetMinion(Pet* pet, bool) { Out = pet; }
    void PetSpellInitialize() { }

    void RemovePet(Pet* pet, PetSaveMode mode)
    {
        pet->SavePetToDB(mode);
        PetStable& stable = GetOrInitPetStable();
        if (stable.CurrentPet && stable.CurrentPet->PetNumber == pet->Number)
        {
            if (mode == PET_SAVE_NOT_IN_SLOT)
            {
                stable.UnslottedPets.push_back(std::move(*stable.CurrentPet));
                stable.CurrentPet.reset();
            }
            else if (mode == PET_SAVE_AS_DELETED)
                stable.CurrentPet.reset();
        }
        Out = nullptr;
    }

    Pet* CreateTamedPetFrom(uint32 entry, uint32)
    {
        ++StarterCalls;
        if (!sObjectMgr->GetCreatureTemplate(entry))
            return nullptr;
        PetStable& stable = GetOrInitPetStable();
        for (PetStable::PetInfo const& pet : stable.UnslottedPets)
            if (pet.Type == HUNTER_PET)
                UnsafeStarter = true;
        if (stable.CurrentPet || stable.GetUnslottedHunterPet())
            return nullptr;
        AllPets.push_back(std::make_unique<Pet>());
        Pet* pet = AllPets.back().get();
        pet->Entry = entry;
        pet->Number = NextPetNumber++;
        PetStable::PetInfo& info = stable.CurrentPet.emplace();
        info.PetNumber = pet->Number;
        info.CreatureId = entry;
        info.Health = 100;
        info.Type = HUNTER_PET;
        return pet;
    }
};

Player* Caster = nullptr;

class SpellScript
{
public:
    struct CheckCastHook
    {
        template <typename T>
        CheckCastHook& operator+=(T) { return *this; }
    } OnCheckCast;

    SpellInfo Info{ 0 };

    virtual ~SpellScript() = default;
    Unit* GetCaster() const { return Caster; }
    SpellInfo const* GetSpellInfo() const { return &Info; }
    virtual void Register() { }
};

class PlayerScript
{
public:
    PlayerScript(char const*, std::initializer_list<PlayerHook>) { }
    virtual ~PlayerScript() = default;
    virtual void OnPlayerForgotSpell(Player*, uint32) { }
};

#define PrepareSpellScript(CLASS) public: using ScriptSelf = CLASS
#define SpellCheckCastFn(F) &F
#define RegisterSpellScriptWithArgs(...) LogSink(#__VA_ARGS__)

namespace AscensionWildcard
{
bool IsClasslessHero(Player*) { return true; }
}

// ACTUAL_TAMING_DATA

// ACTUAL_TAMING

constexpr uint32 CALL_BEAST = 883;
constexpr uint32 CALL_DEMON = 884;
constexpr uint32 CALL_UNDEAD = 885;
constexpr uint32 BEAST = 100;
constexpr uint32 BEAST_2 = 101;
constexpr uint32 BEAST_3 = 102;
constexpr uint32 HUNTER_DEMON = 200;
constexpr uint32 IMP = 416;
constexpr uint32 UNDEAD = 300;

PetStable::PetInfo Info(uint32 number, uint32 creature, PetType type, uint32 health = 100)
{
    PetStable::PetInfo info;
    info.PetNumber = number;
    info.CreatureId = creature;
    info.Type = type;
    info.Health = health;
    return info;
}

Player& Reset(uint32 maxStabled)
{
    static Player player;
    Db.clear();
    Saves.clear();
    Updates.clear();
    AllPets.clear();
    player = Player();
    player.GetOrInitPetStable().MaxStabledPets = maxStabled;
    ObjectStore.Templates = {
        { BEAST, { 1 } }, { BEAST_2, { 1 } }, { BEAST_3, { 1 } }, { 2031, { 1 } },
        { HUNTER_DEMON, { 3 } }, { IMP, { 3 } }, { 1547, { 3 } },
        { UNDEAD, { 6 } }, { 2178, { 6 } },
    };
    Caster = &player;
    return player;
}

void Current(Player& player, PetStable::PetInfo info, bool out)
{
    Db[info.PetNumber] = { 0, info.Type };
    if (out)
    {
        AllPets.push_back(std::make_unique<Pet>());
        Pet* pet = AllPets.back().get();
        pet->Entry = info.CreatureId;
        pet->Type = info.Type;
        pet->Number = info.PetNumber;
        pet->Alive = info.Health != 0;
        player.Out = pet;
    }
    player.Stable->CurrentPet = std::move(info);
}

void Stabled(Player& player, std::size_t slot, PetStable::PetInfo info)
{
    Db[info.PetNumber] = { uint32(slot + 1), info.Type };
    player.Stable->StabledPets[slot] = std::move(info);
}

void Unslotted(Player& player, PetStable::PetInfo info)
{
    Db[info.PetNumber] = { uint32(PET_SAVE_NOT_IN_SLOT), info.Type };
    player.Stable->UnslottedPets.push_back(std::move(info));
}

SpellCastResult Cast(uint32 spellId)
{
    AscensionTaming::spell_ascension_family_call script;
    script.Info.Id = spellId;
    return script.CheckCast();
}

void RequireConsistent(Player& player, char const* message)
{
    std::map<uint32, Row> expected;
    PetStable const& stable = *player.Stable;
    if (stable.CurrentPet)
        expected[stable.CurrentPet->PetNumber] = { 0, stable.CurrentPet->Type };
    for (std::size_t slot = 0; slot < stable.StabledPets.size(); ++slot)
        if (stable.StabledPets[slot])
            expected[stable.StabledPets[slot]->PetNumber] = { uint32(slot + 1), stable.StabledPets[slot]->Type };
    for (PetStable::PetInfo const& pet : stable.UnslottedPets)
        expected[pet.PetNumber] = { uint32(PET_SAVE_NOT_IN_SLOT), pet.Type };
    Require(expected.size() == Db.size(), message);
    for (auto const& [number, row] : expected)
    {
        auto found = Db.find(number);
        Require(found != Db.end() && found->second.Slot == row.Slot && found->second.Type == row.Type, message);
    }
}

bool IsUnslotted(Player& player, uint32 number)
{
    for (PetStable::PetInfo const& pet : player.Stable->UnslottedPets)
        if (pet.PetNumber == number)
            return true;
    return false;
}

void WarlockDemonStaysUnslotted()
{
    Player& player = Reset(2);
    Current(player, Info(1, BEAST, HUNTER_PET), true);
    Unslotted(player, Info(2, IMP, SUMMON_PET));
    Stabled(player, 0, Info(3, UNDEAD, HUNTER_PET));
    Require(Cast(CALL_UNDEAD) == SPELL_CAST_OK, "a stored undead answers Call Undead");
    Require(player.Stable->CurrentPet && player.Stable->CurrentPet->PetNumber == 3, "the stored undead becomes current");
    Require(player.Stable->StabledPets[0] && player.Stable->StabledPets[0]->PetNumber == 1,
        "the beast takes the undead's stable slot");
    Require(IsUnslotted(player, 2) && !player.Stable->StabledPets[1],
        "a warlock demon is never moved into a hunter stable slot");
    RequireConsistent(player, "stable and database agree after a family swap");
}

void CallDemonIgnoresWarlockDemons()
{
    Player& player = Reset(2);
    Unslotted(player, Info(2, IMP, SUMMON_PET));
    Require(Cast(CALL_DEMON) == SPELL_FAILED_DONT_REPORT, "Call Demon with no hunter demon grants the starter");
    Require(player.Stable->CurrentPet && player.Stable->CurrentPet->CreatureId == 1547 &&
        player.Stable->CurrentPet->Type == HUNTER_PET, "Call Demon must not take a warlock demon as its pet");
    Require(IsUnslotted(player, 2), "the warlock demon stays where warlock summons look for it");
    RequireConsistent(player, "saving the starter must not delete the warlock demon's row");
}

void LockedStableSlotsStayLocked()
{
    Player& player = Reset(0);
    Current(player, Info(1, BEAST, HUNTER_PET), true);
    Require(Cast(CALL_UNDEAD) == SPELL_FAILED_DONT_REPORT, "no purchased slot fails Call Undead");
    Require(player.TameFailure == PET_TAME_TOO_MANY, "the player is told the stable is full");
    Require(player.Out && player.Stable->CurrentPet && player.Stable->CurrentPet->PetNumber == 1,
        "the beast stays out when there is nowhere to stable it");
    Require(Saves.empty() && Updates.empty() && player.StarterCalls == 0, "a refused call writes nothing");
    RequireConsistent(player, "a refused call leaves the stable as it was");
}

void DeadStoredPetIsRefusedFirst()
{
    Player& player = Reset(2);
    Current(player, Info(1, BEAST, HUNTER_PET), true);
    Stabled(player, 0, Info(3, HUNTER_DEMON, HUNTER_PET, 0));
    Require(Cast(CALL_DEMON) == SPELL_FAILED_DONT_REPORT, "a dead stored demon fails Call Demon");
    Require(player.TameFailure == PET_TAME_DEAD, "the player is told the pet is dead");
    Require(player.Out && player.Out->Number == 1, "the beast is not dismissed for a cast that fails");
    Require(Saves.empty() && Updates.empty(), "a failed call writes nothing");
    RequireConsistent(player, "a failed call leaves the stable as it was");
}

void FullStableNeverStrandsPets()
{
    Player& player = Reset(2);
    Stabled(player, 0, Info(4, BEAST_2, HUNTER_PET));
    Stabled(player, 1, Info(5, BEAST_3, HUNTER_PET));
    Unslotted(player, Info(2, IMP, SUMMON_PET));
    Current(player, Info(1, BEAST, HUNTER_PET), true);
    Require(Cast(CALL_UNDEAD) == SPELL_FAILED_DONT_REPORT, "a full stable fails the starter grant");
    Require(player.TameFailure == PET_TAME_TOO_MANY, "the player is told the stable is full");
    Require(player.StarterCalls == 0 && !player.UnsafeStarter, "no starter is created over an unslotted hunter pet");
    Require(player.Out && player.Out->Number == 1, "the beast stays out");
    RequireConsistent(player, "no pet row is lost when the stable is full");
}

void OutPetIsStabledInOneWrite()
{
    Player& player = Reset(2);
    Current(player, Info(1, BEAST, HUNTER_PET), true);
    Stabled(player, 1, Info(3, UNDEAD, HUNTER_PET));
    Require(Cast(CALL_UNDEAD) == SPELL_CAST_OK, "a stored undead answers Call Undead");
    uint32 beastWrites = 0;
    for (auto const& [number, mode] : Saves)
        if (number == 1)
        {
            ++beastWrites;
            Require(mode == PET_SAVE_FIRST_STABLE_SLOT + 1, "the beast is saved straight into its stable slot");
        }
    for (auto const& [number, slot] : Updates)
        if (number == 1)
            ++beastWrites;
    Require(beastWrites == 1, "the dismissed beast is written once, so no two writes can reorder");
    RequireConsistent(player, "stable and database agree after parking the out pet");
}

void NothingToSummonFails()
{
    Player& player = Reset(2);
    ObjectStore.Templates.erase(2031);
    Require(Cast(CALL_BEAST) == SPELL_FAILED_DONT_REPORT, "a call with nothing to summon fails");
    Require(player.TameFailure == PET_TAME_NOPET_AVAILABLE, "the player is told there is no pet");
    RequireConsistent(player, "a failed call leaves the stable as it was");
}

void StarterGrantedWithStabledBeast()
{
    Player& player = Reset(2);
    Current(player, Info(1, BEAST, HUNTER_PET), true);
    Require(Cast(CALL_UNDEAD) == SPELL_FAILED_DONT_REPORT, "Call Undead grants the starter itself");
    Require(player.StarterCalls == 1 && !player.UnsafeStarter, "the starter is created with no hunter pet unslotted");
    Require(player.Stable->CurrentPet && player.Stable->CurrentPet->CreatureId == 2178, "the undead starter is current");
    Require(player.Stable->StabledPets[0] && player.Stable->StabledPets[0]->PetNumber == 1, "the beast is stabled");
    RequireConsistent(player, "stable and database agree after the starter grant");
}

int main()
{
    WarlockDemonStaysUnslotted();
    CallDemonIgnoresWarlockDemons();
    LockedStableSlotsStayLocked();
    DeadStoredPetIsRefusedFirst();
    FullStableNeverStrandsPets();
    OutPetIsStabledInOneWrite();
    NothingToSummonFails();
    StarterGrantedWithStabledBeast();
    std::puts("PASS: warlock demons untouched; locked slots respected; dead and full-stable calls refused before any "
              "change; one write per parked pet; starter grant keeps every row");
    return 0;
}
