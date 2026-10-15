#include <algorithm>
#include <array>
#include <cassert>
#include <chrono>
#include <cstdint>
#include <functional>
#include <initializer_list>
#include <map>
#include <memory>
#include <mutex>
#include <utility>
#include <vector>
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;
using SpellEffIndex = uint8;
using Milliseconds = std::chrono::milliseconds;
// NATIVE_ENUMS
constexpr uint32 EFFECT_0 = 0, EFFECT_1 = 1, EFFECT_2 = 2, SPEC_MASK_ALL = 3;
constexpr uint32 UNIT_CREATED_BY_SPELL = 1, SPELLMOD_DURATION = 1;
constexpr uint32 REACT_PASSIVE = 0, SMSG_SUPERCEDED_SPELL = 1;
constexpr int UNITHOOK_ON_AURA_REMOVE = 1, PLAYERHOOK_ON_LOGIN = 1, PLAYERHOOK_ON_LOGOUT = 2,
    PLAYERHOOK_ON_MAP_CHANGED = 3, PLAYERHOOK_ON_FORGOT_SPELL = 4, PLAYERHOOK_ON_UPDATE = 5;
struct ObjectGuid
{
    uint32 value = 0;
    auto operator<=>(ObjectGuid const&) const = default;
    explicit operator bool() const { return value != 0; }
    static ObjectGuid Empty;
};
ObjectGuid ObjectGuid::Empty;
struct Position
{
    float x = 0, y = 0, z = 0, o = 0;
    float GetPositionX() const { return x; }
    float GetPositionY() const { return y; }
    float GetPositionZ() const { return z; }
    auto operator<=>(Position const&) const = default;
};
struct SpellImplicitTargetInfo
{
    uint32 target = 0;
    explicit SpellImplicitTargetInfo(uint32 value = 0) : target(value) { }
};
struct SpellEffectInfo { uint32 Effect = 0; SpellImplicitTargetInfo TargetA, TargetB; };
struct SpellInfo
{
    uint32 Id = 0, SpellFamilyName = 38;
    int32 duration = 20000;
    SpellEffectInfo Effects[3];
    bool maskInitialized = false;
    int32 GetDuration() const { return duration; }
    void _InitializeExplicitTargetMask() { maskInitialized = true; }
};
struct Spell { bool triggered = false; bool IsTriggered() const { return triggered; } };
struct Player;
struct Creature;
struct TempSummon;
struct Map
{
    std::map<ObjectGuid, Creature*> creatures;
    Creature* GetCreature(ObjectGuid guid)
    {
        auto itr = creatures.find(guid);
        return itr == creatures.end() ? nullptr : itr->second;
    }
};
struct Aura
{
    uint32 id = 0;
    ObjectGuid caster;
    uint32 GetId() const { return id; }
    ObjectGuid GetCasterGUID() const { return caster; }
};
struct AuraApplication { Aura aura; Aura* GetBase() { return &aura; } };
struct Unit
{
    virtual ~Unit() = default;
    ObjectGuid guid, ownerGuid;
    Player* owner = nullptr;
    Map* map = nullptr;
    Position position;
    bool alive = true, inWorld = true, samePhase = true, los = true;
    std::map<uint32, Aura> auras;
    std::vector<uint32> casts;
    virtual Player* ToPlayer() { return nullptr; }
    ObjectGuid GetGUID() const { return guid; }
    ObjectGuid GetOwnerGUID() const { return ownerGuid; }
    bool IsAlive() const { return alive; }
    bool IsInWorld() const { return inWorld; }
    Map* GetMap() const { return map; }
    bool InSamePhase(Unit* other) const { return samePhase && other->samePhase; }
    bool IsWithinLOSInMap(Unit* other) const { return los && other->los; }
    Position GetPosition() const { return position; }
    bool HasAura(uint32 id, ObjectGuid caster) const
    {
        auto it = auras.find(id);
        return it != auras.end() && it->second.caster == caster;
    }
    void RemoveAurasDueToSpell(uint32 id, ObjectGuid caster);
    void CastSpell(Unit* target, uint32 id, bool triggered)
    {
        assert(target == this && triggered);
        casts.push_back(id);
        if (id == 500289 || id == 500588)
            auras[id] = {id, guid};
    }
};
using WorldObject = Unit;
using EvadeReason = int;
struct MotionMaster
{
    bool idle = false, path = true;
    Position destination;
    ForcedMovement forced = FORCED_MOVEMENT_NONE;
    void Clear() { }
    void MoveIdle() { idle = true; }
    void MovePoint(uint32 id, Position const& pos, ForcedMovement mode, float speed, bool generatePath)
    {
        assert(id == 1 && speed == 0.0f);
        destination = pos;
        forced = mode;
        path = generatePath;
        idle = false;
    }
};
struct ScriptedAI
{
    Creature* me;
    explicit ScriptedAI(Creature* creature) : me(creature) { }
    virtual ~ScriptedAI() = default;
    virtual void AttackStart(Unit*) { }
    virtual void MoveInLineOfSight(Unit*) { }
    virtual void EnterEvadeMode(EvadeReason) { }
    virtual void IsSummonedBy(WorldObject*) { }
    virtual void UpdateAI(uint32) { }
};
struct EventMap
{
    uint32 event = 0;
    int64_t remaining = 0;
    void ScheduleEvent(uint32 id, Milliseconds delay) { event = id; remaining = delay.count(); }
    void Update(uint32 diff) { remaining -= diff; }
    uint32 ExecuteEvent() { return remaining <= 0 ? std::exchange(event, 0) : 0; }
};
struct Creature : Unit
{
    uint32 entry = 0, createdBy = 0, duration = 0, faction = 35, level = 1, react = 1;
    MotionMaster motion;
    std::unique_ptr<ScriptedAI> ai;
    bool removed = false;
    uint32 GetEntry() const { return entry; }
    Player* GetCharmerOrOwnerPlayerOrPlayerItself() { return owner; }
    void SetOwnerGUID(ObjectGuid value) { ownerGuid = value; }
    void SetFaction(uint32 value) { faction = value; }
    void SetLevel(uint32 value) { level = value; }
    void SetReactState(uint32 value) { react = value; }
    void SetUInt32Value(uint32 field, uint32 value) { assert(field == UNIT_CREATED_BY_SPELL); createdBy = value; }
    void DespawnOrUnsummon() { removed = true; inWorld = false; }
    MotionMaster* GetMotionMaster() { return &motion; }
};
struct TempSummon : Creature { };
struct WorldPacket
{
    std::vector<uint32> values;
    WorldPacket(uint32, uint32) { }
    WorldPacket& operator<<(uint32 value) { values.push_back(value); return *this; }
};
struct Session
{
    std::vector<std::vector<uint32>> packets;
    void SendPacket(WorldPacket* packet) { packets.push_back(packet->values); }
};
struct Player : Unit
{
    uint32 cls = CLASS_SPIRIT_MAGE;
    bool teleporting = false, flight = false, transport = false, vehicle = false, failSummon = false;
    uint32 summons = 0, teleports = 0, removals = 0;
    Position teleportDestination, damageDestination, collisionDestination{30, 0, 0, 0};
    std::map<uint32, int> spells;
    std::map<uint32, uint32> m_temporarySpellReplacements;
    std::map<uint32, uint32> m_temporarySpellReplacementOrigins;
    std::vector<std::unique_ptr<TempSummon>> creatures;
    Session session;
    Player* ToPlayer() override { return this; }
    uint32 getClass() const { return cls; }
    uint32 GetFaction() const { return 123; }
    uint32 GetLevel() const { return 40; }
    bool IsBeingTeleported() const { return teleporting; }
    bool IsInFlight() const { return flight; }
    bool GetTransport() const { return transport; }
    bool GetVehicle() const { return vehicle; }
    bool HasActiveSpell(uint32 id) const { auto it = spells.find(id); return it != spells.end() && it->second >= 0; }
    auto const& GetSpellMap() const { return spells; }
    void learnSpell(uint32 id, bool temporary) { assert(temporary && !spells.contains(id)); spells[id] = 1; }
    void removeSpell(uint32 id, uint32 mask, bool temporary)
    {
        assert(mask == SPEC_MASK_ALL && temporary);
        ++removals;
        auto it = spells.find(id);
        if (it != spells.end() && it->second == 1)
            spells.erase(it);
    }
    void SetTemporarySpellReplacement(uint32 original, uint32 replacement);
    uint32 GetTemporarySpellReplacement(uint32 original) const;
    Session* GetSession() { return &session; }
    void SendLearnPacket(uint32, bool, bool = false) { }
    void ApplySpellMod(uint32, uint32 op, int32&) { assert(op == SPELLMOD_DURATION); }
    TempSummon* SummonCreature(uint32 entry, Position const& pos, TempSummonType type, uint32 duration = 0);
    Position GetFirstCollisionPosition(float distance, float angle)
    {
        assert(distance == 30.0f && angle == 0.0f);
        return collisionDestination;
    }
    void NearTeleportTo(Position& destination, bool casting)
    {
        assert(casting);
        ++teleports;
        teleportDestination = destination;
        teleporting = true;
    }
    using Unit::CastSpell;
    void CastSpell(float x, float y, float z, uint32 id, bool triggered)
    {
        assert(id == 500495 && triggered);
        casts.push_back(id);
        damageDestination = {x, y, z, 0};
    }
};
struct ScriptMgr
{
    void OnPlayerTemporarySpellRemoveNotice(Player*, uint32, bool) { }
    void OnPlayerTemporarySpellReplacementNotice(Player*, uint32, uint32, bool) { }
} scripts;
auto sScriptMgr = &scripts;
// NATIVE_REPLACEMENTS
struct SpellMgr
{
    std::map<uint32, SpellInfo> spells;
    SpellInfo const* GetSpellInfo(uint32 id)
    {
        auto it = spells.find(id);
        return it == spells.end() ? nullptr : &it->second;
    }
} manager;
auto sSpellMgr = &manager;
struct Hook { template<class T> void operator+=(T) { } };
struct SpellScript
{
    Unit* caster = nullptr;
    SpellInfo info;
    Spell fixtureSpell;
    bool prevented = false;
    Hook OnCheckCast, OnEffectHit, OnEffectHitTarget, OnEffectLaunchTarget;
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual void Register() { }
    Unit* GetCaster() { return caster; }
    SpellInfo const* GetSpellInfo() { return &info; }
    Spell* GetSpell() { return &fixtureSpell; }
    bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }
    void PreventHitDefaultEffect(SpellEffIndex) { prevented = true; }
};
struct UnitScript
{
    UnitScript(char const*, bool, std::initializer_list<int>) { }
    virtual void OnAuraRemove(Unit*, AuraApplication*, AuraRemoveMode) { }
};
struct PlayerScript
{
    PlayerScript(char const*, std::initializer_list<int>) { }
    virtual void OnPlayerLogin(Player*) { }
    virtual void OnPlayerLogout(Player*) { }
    virtual void OnPlayerMapChanged(Player*) { }
    virtual void OnPlayerForgotSpell(Player*, uint32) { }
    virtual void OnPlayerUpdate(Player*, uint32) { }
};
#define PrepareSpellScript(name)
#define SpellCheckCastFn(...) 0
#define SpellEffectFn(...) 0
#define RegisterSpellScript(name)
#define RegisterCreatureAI(name)
// ACTUAL_SOURCE
void Unit::RemoveAurasDueToSpell(uint32 id, ObjectGuid caster)
{
    auto it = auras.find(id);
    if (it == auras.end() || it->second.caster != caster)
        return;
    AuraApplication application{it->second};
    auras.erase(it);
    runemaster_travel_auras hooks;
    hooks.OnAuraRemove(this, &application, AURA_REMOVE_BY_DEFAULT);
}
TempSummon* Player::SummonCreature(uint32 entry, Position const& pos, TempSummonType type, uint32 duration)
{
    assert(type == TEMPSUMMON_MANUAL_DESPAWN);
    if (failSummon)
        return nullptr;
    auto marker = std::make_unique<TempSummon>();
    marker->entry = entry;
    marker->duration = duration;
    marker->position = pos;
    marker->guid = {1000 + ++summons};
    marker->owner = this;
    marker->map = map;
    marker->ai = std::make_unique<npc_ascension_runemaster_marker>(marker.get());
    map->creatures[marker->guid] = marker.get();
    marker->ai->IsSummonedBy(this);
    auto result = marker.get();
    creatures.push_back(std::move(marker));
    return result;
}
int main()
{
    Map map, otherMap;
    Player player;
    player.guid = {1};
    player.map = &map;
    player.position = {4, 5, 6, 1};
    player.spells[500270] = 0;
    player.spells[500287] = 0;
    manager.spells[500270].Id = 500270;
    manager.spells[500606].Id = 500606;
    runemaster_travel_lifecycle lifecycle;
    runemaster_travel_auras auras;
    lifecycle.OnPlayerUpdate(&player, 1);
    assert(player.removals == 0);
    spell_ascension_runemaster_travel cast;
    cast.caster = &player;
    cast.info.Id = 500270;
    assert(cast.CheckTravel() == SPELL_CAST_OK);
    cast.SummonEcho(0);
    cast.SummonDagger(0);
    auto rune = FindMarker(&player, 500270);
    assert(rune && player.summons == 1 && rune->motion.idle && rune->createdBy == 500270);
    assert(rune->duration == 0 && rune->faction == 123 && rune->level == 40 && rune->react == REACT_PASSIVE);
    assert(player.GetTemporarySpellReplacement(500270) == 500272 && player.spells.at(500272) == 1);
    player.auras[500270] = {500270, player.guid};
    rune->ai->UpdateAI(25000);
    assert(!rune->removed);
    player.position = {40, 50, 60, 2};
    spell_ascension_runemaster_return recall;
    recall.caster = &player;
    recall.info.Id = 500272;
    assert(recall.CheckReturn() == SPELL_CAST_OK);
    recall.Echo(0);
    assert(!recall.prevented && player.teleports == 1 && rune->removed);
    assert(player.teleportDestination == Position(4, 5, 6, 1));
    assert(!player.spells.contains(500272) && !player.auras.contains(500270));
    assert(player.GetTemporarySpellReplacement(500270) == 500270);
    recall.Echo(0);
    assert(recall.prevented && player.teleports == 1);
    player.teleporting = false;
    player.spells[500272] = 0;
    assert(StartTravel(&player, 500270));
    player.auras[500270] = {500270, player.guid};
    AuraApplication expiration{{500270, player.guid}};
    player.auras.erase(500270);
    auras.OnAuraRemove(&player, &expiration, AURA_REMOVE_BY_EXPIRE);
    assert(player.teleports == 2 && player.casts.back() == 500272 && player.spells.at(500272) == 0);
    recall.fixtureSpell.triggered = true;
    assert(recall.CheckReturn() == SPELL_CAST_OK);
    recall.prevented = false;
    recall.Echo(0);
    assert(!recall.prevented && player.teleports == 2);
    recall.fixtureSpell.triggered = false;
    player.teleporting = false;
    player.spells.erase(500272);
    for (auto mode : {AURA_REMOVE_BY_DEFAULT, AURA_REMOVE_BY_CANCEL, AURA_REMOVE_BY_DEATH})
    {
        assert(StartTravel(&player, 500270));
        auras.OnAuraRemove(&player, &expiration, mode);
        assert(player.teleports == 2 && !FindMarker(&player, 500270));
    }
    player.spells[500272] = -1;
    assert(!StartTravel(&player, 500270) && player.spells.at(500272) == -1);
    player.spells.erase(500272);
    cast.info.Id = 500287;
    cast.SummonEcho(0);
    auto before = player.summons;
    cast.SummonDagger(0);
    assert(player.summons == before + 1);
    auto dagger = FindMarker(&player, 500287);
    assert(dagger && dagger->entry == 51335 && dagger->casts.back() == 500588);
    assert(dagger->motion.destination == player.collisionDestination && !dagger->motion.path);
    assert(dagger->motion.forced == FORCED_MOVEMENT_RUN && player.auras.contains(500289));
    dagger->position = {17, 0, 0, 1};
    recall.info.Id = 500587;
    player.los = false;
    assert(recall.CheckReturn() == SPELL_CAST_OK);
    lifecycle.OnPlayerUpdate(&player, 1);
    assert(FindMarker(&player, 500287) == dagger);
    assert(recall.CheckReturn() == SPELL_CAST_OK);
    recall.Warp(0);
    assert(player.teleportDestination == Position(17, 0, 0, 1));
    assert(player.damageDestination == Position(17, 0, 0, 0));
    assert(player.position != player.damageDestination && player.casts.back() == 500495 && dagger->removed);
    assert(!player.auras.contains(500289) && !player.spells.contains(500587));
    before = uint32(player.casts.size());
    recall.Warp(0);
    assert(player.casts.size() == before);
    player.teleporting = false;
    assert(StartTravel(&player, 500287));
    dagger = FindMarker(&player, 500287);
    player.failSummon = true;
    assert(!StartTravel(&player, 500287) && FindMarker(&player, 500287) == dagger && !dagger->removed);
    player.failSummon = false;
    assert(StartTravel(&player, 500287));
    auto next = FindMarker(&player, 500287);
    dagger->ai.reset();
    assert(FindMarker(&player, 500287) == next);
    next->ownerGuid = {99};
    lifecycle.OnPlayerUpdate(&player, 1);
    assert(!next->removed && !player.spells.contains(500587));
    for (bool Player::* blocked : {&Player::teleporting, &Player::flight, &Player::transport, &Player::vehicle})
    {
        player.*blocked = true;
        assert(!StartTravel(&player, 500270));
        player.*blocked = false;
    }
    for (bool Unit::* required : {&Unit::alive, &Unit::inWorld, &Unit::samePhase})
    {
        assert(StartTravel(&player, 500287));
        player.*required = false;
        lifecycle.OnPlayerUpdate(&player, 1);
        assert(!player.spells.contains(500587));
        player.*required = true;
    }
    assert(StartTravel(&player, 500287));
    dagger = FindMarker(&player, 500287);
    player.map = &otherMap;
    lifecycle.OnPlayerMapChanged(&player);
    assert(!player.spells.contains(500587));
    dagger->ai->UpdateAI(500);
    assert(dagger->removed);
    player.map = &map;
    assert(StartTravel(&player, 500270));
    lifecycle.OnPlayerForgotSpell(&player, 500270);
    assert(!FindMarker(&player, 500270));
    assert(StartTravel(&player, 500287));
    lifecycle.OnPlayerLogout(&player);
    assert(!FindMarker(&player, 500287));
    player.auras[500270] = {500270, player.guid};
    lifecycle.OnPlayerLogin(&player);
    assert(!player.auras.contains(500270));
    player.cls = CLASS_RANGER;
    assert(!StartTravel(&player, 500270));
    SpellInfo info;
    info.Id = 500495;
    ApplyAscensionRunemasterTravelContracts(&info);
    assert(info.Effects[0].TargetA.target == TARGET_DEST_DEST);
    assert(info.Effects[0].TargetB.target == TARGET_UNIT_DEST_AREA_ENEMY && info.maskInitialized);
    info.Id = 500272;
    info.Effects[0].Effect = SPELL_EFFECT_HEAL;
    info.Effects[1].Effect = SPELL_EFFECT_TRIGGER_SPELL;
    ApplyAscensionRunemasterTravelContracts(&info);
    assert(info.Effects[0].Effect == SPELL_EFFECT_HEAL && !info.Effects[1].Effect);
    info.Id = 500587;
    info.Effects[0].Effect = SPELL_EFFECT_SCRIPT_EFFECT;
    info.Effects[1].Effect = SPELL_EFFECT_REMOVE_AURA;
    info.Effects[2].Effect = SPELL_EFFECT_DUMMY;
    ApplyAscensionRunemasterTravelContracts(&info);
    assert(info.Effects[0].Effect == SPELL_EFFECT_DUMMY && !info.Effects[1].Effect && !info.Effects[2].Effect);
    info.SpellFamilyName = 27;
    info.Effects[1].Effect = 123;
    ApplyAscensionRunemasterTravelContracts(&info);
    assert(info.Effects[1].Effect == 123);
}
