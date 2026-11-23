/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionGuardianTravelPolicy.h"
#include "AscensionNecromancer.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DataMap.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "PetDefines.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <string>
#include <vector>

static_assert(GuardianTravel::TypeTimedOrDead == TEMPSUMMON_TIMED_OR_DEAD_DESPAWN);
static_assert(GuardianTravel::TypeTimedOrCorpse == TEMPSUMMON_TIMED_OR_CORPSE_DESPAWN);
static_assert(GuardianTravel::TypeTimed == TEMPSUMMON_TIMED_DESPAWN);
static_assert(GuardianTravel::TypeTimedOutOfCombat == TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT);
static_assert(GuardianTravel::TypeCorpseTimed == TEMPSUMMON_CORPSE_TIMED_DESPAWN);
static_assert(GuardianTravel::TypeDead == TEMPSUMMON_DEAD_DESPAWN);
static_assert(GuardianTravel::TypeDespawned == TEMPSUMMON_DESPAWNED);
static_assert(GuardianTravel::TypeTimedOutOfCombatAlive == TEMPSUMMON_TIMED_DESPAWN_OOC_ALIVE);

namespace
{
std::string const TravelKey = "AscensionGuardianTravel";
std::atomic<bool> FollowTravel{true};

struct TravelingGuardian
{
    ObjectGuid guid;
    uint32 entry = 0;
    uint32 spell = 0;
    float health = 1.0f;
    float mana = 1.0f;
    uint32 type = GuardianTravel::TypeDead;
    uint32 remainingMs = 0;
    uint32 properties = 0;
    uint8 level = 1;
    bool necromancer = false;
    bool shield = false;
    int32 shieldAmount = 0;
};

struct TravelNote final : DataMap::Base
{
    std::vector<TravelingGuardian> guardians;
    uint32 fromMap = 0;
    uint32 fromInstance = 0;
    uint32 map = 0;
    float x = 0;
    float y = 0;
    float z = 0;
    uint64 capturedMs = 0;
    bool keepCombat = false;
};

uint32 ElapsedMs(TravelNote const& note)
{
    uint64 const now = uint64(GameTime::GetGameTimeMS().count());
    return uint32(std::min<uint64>(now > note.capturedMs ? now - note.capturedMs : 0, UINT32_MAX));
}

std::vector<TempSummon*> OwnedGuardians(Player* player)
{
    std::vector<TempSummon*> result;
    for (Unit* controlled : player->m_Controlled)
    {
        Creature* creature = controlled ? controlled->ToCreature() : nullptr;
        TempSummon* summon = creature ? creature->ToTempSummon() : nullptr;
        if (!summon || !summon->IsGuardian() || summon->IsPet() || summon->IsTotem() || summon->IsVehicle() ||
            !summon->m_Properties || summon->GetOwnerGUID() != player->GetGUID() || summon->GetCharmerGUID() ||
            summon->GetGUID() == player->GetCritterGUID())
            continue;
        result.push_back(summon);
    }
    return result;
}

bool WalksWithOwner(TempSummon* summon)
{
    MovementGeneratorType const active = summon->GetMotionMaster()->GetMotionSlotType(MOTION_SLOT_ACTIVE);
    if (active == FOLLOW_MOTION_TYPE)
        return true;
    return active == CHASE_MOTION_TYPE && summon->IsCombatMovementAllowed() && summon->IsInCombat();
}

float Fraction(uint32 value, uint32 maximum)
{
    return maximum ? std::clamp(float(value) / float(maximum), 0.0f, 1.0f) : 1.0f;
}

bool SummonSpellAllowsHere(Player* player, uint32 spell)
{
    Map* map = player->GetMap();
    if (!map || map->IsBattlegroundOrArena())
        return false;
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
    return info && info->CheckLocation(player->GetMapId(), player->GetZoneId(), player->GetAreaId(), player) ==
        SPELL_CAST_OK;
}

bool MakeAgain(Player* player, TravelingGuardian const& row, uint32 lifetime, uint32 slot)
{
    SummonPropertiesEntry const* properties = sSummonPropertiesStore.LookupEntry(row.properties);
    if (!properties)
        return false;
    float const angle = Position::NormalizeOrientation(PET_FOLLOW_ANGLE + float(slot % 6) * float(M_PI) / 3.0f);
    float const distance = PET_FOLLOW_DIST + 2.5f * float(slot / 6);
    Position point = player->GetPosition();
    player->MovePositionToFirstCollision(point, distance, angle);
    uint32 duration = lifetime;
    if (lifetime &&
        (row.type == TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT || row.type == TEMPSUMMON_TIMED_DESPAWN_OOC_ALIVE))
        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(row.spell))
            duration = std::max<uint32>(lifetime, uint32(std::max(0, info->GetDuration())));
    TempSummon* unit = player->GetMap()->SummonCreature(row.entry, point, properties, duration, player, row.spell);
    if (!unit)
        return false;
    if (!unit->IsInWorld() || !unit->IsAlive() || unit->GetOwnerGUID() != player->GetGUID() ||
        GuardianTravel::OnItsWayOut(uint32(unit->GetSummonType())) ||
        (row.necromancer && !AscensionNecromancer::IsMinion(player, unit)))
    {
        unit->DespawnOrUnsummon();
        return false;
    }
    unit->SetTempSummonType(TempSummonType(GuardianTravel::CopyType(row.type, lifetime)));
    if (lifetime)
        unit->SetTimer(lifetime);
    if (row.necromancer)
    {
        Aura* shield = unit->GetAura(AscensionNecromancer::SummonShield);
        AuraEffect* effect = shield && row.shield ? shield->GetEffect(EFFECT_0) : nullptr;
        if (effect)
            effect->SetAmount(std::min(effect->GetAmount(), row.shieldAmount));
        else
            unit->RemoveAurasDueToSpell(AscensionNecromancer::SummonShield);
    }
    if (unit->IsGuardian() && unit->GetLevel() != row.level)
    {
        unit->SetLevel(row.level);
        static_cast<Guardian*>(unit)->InitStatsForLevel(row.level);
    }
    unit->SetHealth(std::max<uint32>(1, uint32(row.health * float(unit->GetMaxHealth()))));
    if (unit->GetMaxPower(POWER_MANA))
        unit->SetPower(POWER_MANA, int32(row.mana * float(unit->GetMaxPower(POWER_MANA))));
    if (unit->IsGuardian())
        static_cast<Minion*>(unit)->SetFollowAngle(angle);
    unit->GetMotionMaster()->Clear();
    unit->GetMotionMaster()->MoveFollow(player, distance, angle);
    return true;
}

void Arrive(Player* player, TravelNote const& note)
{
    if (!FollowTravel || !player->IsAlive())
        return;
    bool const worldChanged = note.fromMap != player->GetMapId() || note.fromInstance != player->GetInstanceId();
    std::vector<bool> make(note.guardians.size(), true);
    if (worldChanged)
    {
        std::vector<GuardianTravel::Kind> carried;
        std::vector<GuardianTravel::Kind> present;
        for (TravelingGuardian const& row : note.guardians)
            carried.push_back({row.entry, row.spell});
        for (TempSummon* unit : OwnedGuardians(player))
            if (unit->IsAlive() && !GuardianTravel::OnItsWayOut(uint32(unit->GetSummonType())))
                present.push_back({unit->GetEntry(), unit->GetUInt32Value(UNIT_CREATED_BY_SPELL)});
        make = GuardianTravel::Shortfall(carried, present);
    }
    uint32 const elapsed = ElapsedMs(note);
    uint32 slot = 0;
    uint32 kept = 0;
    uint32 moved = 0;
    uint32 made = 0;
    uint32 lost = 0;
    for (size_t index = 0; index < note.guardians.size(); ++index)
    {
        TravelingGuardian const& row = note.guardians[index];
        Creature* unit = worldChanged ? nullptr : ObjectAccessor::GetCreature(*player, row.guid);
        TempSummon* summon = unit ? unit->ToTempSummon() : nullptr;
        bool const present = summon && summon->IsInWorld() && summon->IsAlive() &&
            !summon->IsDuringRemoveFromWorld() && !GuardianTravel::OnItsWayOut(uint32(summon->GetSummonType())) &&
            summon->GetOwnerGUID() == player->GetGUID() && !summon->GetCharmerGUID() && !summon->GetTransport() &&
            (!row.necromancer || AscensionNecromancer::IsMinion(player, summon));
        bool const allowed = !worldChanged || SummonSpellAllowsHere(player, row.spell);
        switch (GuardianTravel::Plan(worldChanged, present, present ? player->GetExactDist(summon) : 0.0f, allowed))
        {
            case GuardianTravel::Step::Keep:
                ++kept;
                break;
            case GuardianTravel::Step::Move:
            {
                Position point = player->GetPosition();
                player->MovePositionToFirstCollision(point, PET_FOLLOW_DIST, summon->GetFollowAngle());
                if (!note.keepCombat)
                    summon->CombatStop(true);
                summon->NearTeleportTo(point.GetPositionX(), point.GetPositionY(), point.GetPositionZ(),
                                       player->GetOrientation());
                ++moved;
                break;
            }
            case GuardianTravel::Step::Recreate:
            {
                uint32 lifetime = 0;
                if (!make[index])
                    ++kept;
                else if (GuardianTravel::TimeLeft(row.type, row.remainingMs, elapsed, lifetime) &&
                         MakeAgain(player, row, lifetime, slot++))
                    ++made;
                else
                    ++lost;
                break;
            }
            case GuardianTravel::Step::Skip:
                ++lost;
                break;
        }
    }
    if (player->getClass() == CLASS_NECROMANCER)
        AscensionNecromancer::Sync(player);
    LOG_DEBUG("coa", "Traveling guardians for {}: {} kept, {} moved, {} made again, {} not carried",
              player->GetName(), kept, moved, made, lost);
}

void Settle(Player* player)
{
    TravelNote* note = player->CustomData.Get<TravelNote>(TravelKey);
    if (!note)
        return;
    bool const inWorld = player->IsInWorld() && player->FindMap();
    auto const arrival = GuardianTravel::Check(inWorld, player->IsBeingTeleported(), player->GetMapId() == note->map,
                                               inWorld ? player->GetExactDist(note->x, note->y, note->z) : 0.0f,
                                               ElapsedMs(*note));
    if (arrival == GuardianTravel::Arrival::Wait)
        return;
    TravelNote const pending = std::move(*note);
    player->CustomData.Erase(TravelKey);
    if (arrival == GuardianTravel::Arrival::Restore)
        Arrive(player, pending);
}

void NoteGuardians(Player* player, uint32 map, float x, float y, float z, uint32 options)
{
    if (TravelNote* pending = player->CustomData.Get<TravelNote>(TravelKey);
        pending && (player->IsBeingTeleported() || !player->IsInWorld()))
    {
        pending->map = map;
        pending->x = x;
        pending->y = y;
        pending->z = z;
        return;
    }
    Settle(player);
    player->CustomData.Erase(TravelKey);
    MapEntry const* destination = sMapStore.LookupEntry(map);
    Map* current = player->IsInWorld() ? player->FindMap() : nullptr;
    if (!FollowTravel || !current || current->IsBattlegroundOrArena() || !destination ||
        !GuardianTravel::CarryFor(map != player->GetMapId(), player->GetExactDist2d(x, y),
                                  destination->IsBattlegroundOrArena()))
        return;
    TravelNote note;
    note.fromMap = player->GetMapId();
    note.fromInstance = player->GetInstanceId();
    note.map = map;
    note.x = x;
    note.y = y;
    note.z = z;
    note.capturedMs = uint64(GameTime::GetGameTimeMS().count());
    note.keepCombat = (options & TELE_TO_NOT_LEAVE_COMBAT) != 0;
    std::vector<TempSummon*> units;
    bool const necromancer = player->getClass() == CLASS_NECROMANCER;
    if (necromancer)
        for (Creature* unit : AscensionNecromancer::Minions(player))
            if (TempSummon* summon = unit->ToTempSummon())
                units.push_back(summon);
    for (TempSummon* summon : OwnedGuardians(player))
        if (std::find(units.begin(), units.end(), summon) == units.end())
            units.push_back(summon);
    for (TempSummon* summon : units)
    {
        bool const classMinion = necromancer && AscensionNecromancer::IsMinion(player, summon);
        uint32 const type = uint32(summon->GetSummonType());
        GuardianTravel::Candidate candidate;
        candidate.Entry = summon->GetEntry();
        candidate.Properties = summon->m_Properties ? summon->m_Properties->Id : 0;
        candidate.Alive = summon->IsAlive() && summon->IsInWorld();
        candidate.Owned = summon->GetOwnerGUID() == player->GetGUID() && !summon->GetCharmerGUID();
        candidate.Leaving = summon->IsDuringRemoveFromWorld();
        candidate.Type = type;
        candidate.RemainingMs = GuardianTravel::TimerOf(type) != GuardianTravel::Timer::None ?
            summon->GetTimer() : 0;
        candidate.Necromancer = classMinion;
        candidate.Follows = !classMinion || AscensionNecromancer::FollowsOwner(summon->GetEntry());
        candidate.Walks = WalksWithOwner(summon);
        candidate.Hidden = summon->HasUnitState(UNIT_STATE_ROOT) || !summon->IsVisible() ||
            summon->GetTransport() != nullptr;
        if (!GuardianTravel::Travels(candidate))
            continue;
        TravelingGuardian row;
        row.guid = summon->GetGUID();
        row.entry = summon->GetEntry();
        row.spell = summon->GetUInt32Value(UNIT_CREATED_BY_SPELL);
        row.health = Fraction(summon->GetHealth(), summon->GetMaxHealth());
        row.mana = Fraction(summon->GetPower(POWER_MANA), summon->GetMaxPower(POWER_MANA));
        row.type = type;
        row.remainingMs = candidate.RemainingMs;
        row.properties = candidate.Properties;
        row.level = summon->GetLevel();
        row.necromancer = classMinion;
        Aura* shield = classMinion ? summon->GetAura(AscensionNecromancer::SummonShield) : nullptr;
        AuraEffect* shieldEffect = shield ? shield->GetEffect(EFFECT_0) : nullptr;
        row.shield = shieldEffect != nullptr;
        row.shieldAmount = shieldEffect ? shieldEffect->GetAmount() : 0;
        note.guardians.push_back(row);
    }
    if (!note.guardians.empty())
        *player->CustomData.GetDefault<TravelNote>(TravelKey) = std::move(note);
}

class ascension_guardian_travel_config : public WorldScript
{
public:
    ascension_guardian_travel_config() :
        WorldScript("ascension_guardian_travel_config", {WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool) override
    {
        FollowTravel = sConfigMgr->GetOption<bool>("CoA.Guardians.FollowTravel", true);
    }
};

class ascension_guardian_travel : public PlayerScript
{
public:
    ascension_guardian_travel() :
        PlayerScript("ascension_guardian_travel", {PLAYERHOOK_ON_BEFORE_TELEPORT, PLAYERHOOK_ON_UPDATE}) { }

    bool OnPlayerBeforeTeleport(Player* player, uint32 map, float x, float y, float z, float, uint32 options,
                                Unit*) override
    {
        if (FollowTravel || player->CustomData.Get<TravelNote>(TravelKey))
            NoteGuardians(player, map, x, y, z, options);
        return true;
    }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        Settle(player);
    }
};
}

void AddSC_AscensionGuardianTravel()
{
    new ascension_guardian_travel_config();
    new ascension_guardian_travel();
}
