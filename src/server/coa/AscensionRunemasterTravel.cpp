/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionRunemasterTalents.h"
#include "Creature.h"
#include "EventMap.h"
#include "Map.h"
#include "MotionMaster.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <map>
#include <mutex>

namespace
{
enum RunemasterTravelSpells : uint32
{
    SPELL_ECHO_RUNE = 500270,
    SPELL_ECHO_RETURN = 500272,
    SPELL_WARPDAGGER = 500287,
    SPELL_RUNESHROUD = 500288,
    SPELL_SHROUDWALKER = 705563,
    SPELL_WARP_READY = 500289,
    SPELL_WARP_DAMAGE = 500495,
    SPELL_WARP = 500587,
    SPELL_WARP_VISUAL = 500588,
    SPELL_WARP_SUMMON = 500606
};

enum RunemasterTravelCreatures : uint32
{
    NPC_ECHO_RUNE = 50063,
    NPC_WARPDAGGER = 51335
};

enum RunemasterTravelEvents : uint32
{
    EVENT_TRAVEL_OWNER_CHECK = 1,
    POINT_WARP_DESTINATION = 1
};

std::mutex travelMutex;
std::map<std::pair<ObjectGuid, uint32>, ObjectGuid> travelMarkers;

uint32 ReturnSpell(uint32 spell) { return spell == SPELL_ECHO_RUNE ? SPELL_ECHO_RETURN : SPELL_WARP; }
uint32 TravelAura(uint32 spell) { return spell == SPELL_ECHO_RUNE ? SPELL_ECHO_RUNE : SPELL_WARP_READY; }
uint32 TravelEntry(uint32 spell) { return spell == SPELL_ECHO_RUNE ? NPC_ECHO_RUNE : NPC_WARPDAGGER; }

ObjectGuid MarkerGuid(ObjectGuid owner, uint32 spell)
{
    std::lock_guard<std::mutex> lock(travelMutex);
    auto itr = travelMarkers.find({owner, spell});
    return itr == travelMarkers.end() ? ObjectGuid::Empty : itr->second;
}

void ForgetMarker(ObjectGuid owner, uint32 spell, ObjectGuid marker)
{
    std::lock_guard<std::mutex> lock(travelMutex);
    auto itr = travelMarkers.find({owner, spell});
    if (itr != travelMarkers.end() && itr->second == marker)
        travelMarkers.erase(itr);
}

bool CanTravel(Player* player)
{
    return player && player->getClass() == CLASS_SPIRIT_MAGE && player->IsAlive() && player->IsInWorld() &&
        !player->IsBeingTeleported() && !player->IsInFlight() && !player->GetTransport() && !player->GetVehicle();
}

Creature* FindMarker(Player* player, uint32 spell)
{
    ObjectGuid guid = MarkerGuid(player->GetGUID(), spell);
    Creature* marker = guid && player->IsInWorld() ? player->GetMap()->GetCreature(guid) : nullptr;
    return marker && marker->GetOwnerGUID() == player->GetGUID() && marker->GetEntry() == TravelEntry(spell)
        ? marker : nullptr;
}

void ClearTravel(Player* player, uint32 spell)
{
    ObjectGuid guid = MarkerGuid(player->GetGUID(), spell);
    Creature* marker = FindMarker(player, spell);
    ForgetMarker(player->GetGUID(), spell, guid);
    player->SetTemporarySpellReplacement(spell, 0);
    player->removeSpell(ReturnSpell(spell), SPEC_MASK_ALL, true);
    player->RemoveAurasDueToSpell(TravelAura(spell), player->GetGUID());
    if (marker)
        marker->DespawnOrUnsummon();
}

bool HasTravelMarker(Player* player, uint32 spell)
{
    if (!CanTravel(player) || !player->HasActiveSpell(spell))
        return false;
    Creature* marker = FindMarker(player, spell);
    return marker && marker->IsAlive() && marker->IsInWorld() && player->InSamePhase(marker);
}

bool CanReturn(Player* player, uint32 spell)
{
    return HasTravelMarker(player, spell);
}

bool ReturnToMarker(Player* player, uint32 spell, Position* arrival = nullptr)
{
    if (!CanReturn(player, spell))
        return false;
    Position destination = FindMarker(player, spell)->GetPosition();
    if (arrival)
        *arrival = destination;
    ClearTravel(player, spell);
    player->NearTeleportTo(destination, true);
    return true;
}

bool StartTravel(Player* player, uint32 spell)
{
    if (!CanTravel(player) || !player->HasActiveSpell(spell))
        return false;
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell == SPELL_ECHO_RUNE ? spell : SPELL_WARP_SUMMON);
    if (!info)
        return false;
    int32 duration = info->GetDuration();
    player->ApplySpellMod(info->Id, SPELLMOD_DURATION, duration);
    if (duration <= 0)
        return false;
    TempSummon* marker = player->SummonCreature(TravelEntry(spell), player->GetPosition(),
        TEMPSUMMON_MANUAL_DESPAWN);
    if (!marker)
        return false;
    ClearTravel(player, spell);
    marker->SetUInt32Value(UNIT_CREATED_BY_SPELL, spell);
    {
        std::lock_guard<std::mutex> lock(travelMutex);
        travelMarkers[{player->GetGUID(), spell}] = marker->GetGUID();
    }
    uint32 child = ReturnSpell(spell);
    if (player->GetSpellMap().find(child) == player->GetSpellMap().end())
        player->learnSpell(child, true);
    player->SetTemporarySpellReplacement(spell, child);
    if (player->GetTemporarySpellReplacement(spell) != child)
    {
        ClearTravel(player, spell);
        return false;
    }
    if (spell == SPELL_WARPDAGGER)
    {
        player->CastSpell(player, SPELL_WARP_READY, true);
        marker->CastSpell(marker, SPELL_WARP_VISUAL, true);
        Position destination = player->GetFirstCollisionPosition(30.0f, 0.0f);
        marker->GetMotionMaster()->MovePoint(POINT_WARP_DESTINATION, destination,
            FORCED_MOVEMENT_RUN, 0.0f, false);
    }
    return true;
}

struct npc_ascension_runemaster_marker : ScriptedAI
{
    explicit npc_ascension_runemaster_marker(Creature* creature) : ScriptedAI(creature) { }
    ObjectGuid ownerGuid;
    uint32 spell = 0;
    EventMap events;

    ~npc_ascension_runemaster_marker() override { ForgetMarker(ownerGuid, spell, me->GetGUID()); }
    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void EnterEvadeMode(EvadeReason) override { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* owner = summoner ? summoner->ToPlayer() : nullptr;
        if (!CanTravel(owner))
        {
            me->DespawnOrUnsummon();
            return;
        }
        ownerGuid = owner->GetGUID();
        spell = me->GetEntry() == NPC_ECHO_RUNE ? SPELL_ECHO_RUNE : SPELL_WARPDAGGER;
        me->SetOwnerGUID(ownerGuid);
        me->SetFaction(owner->GetFaction());
        me->SetLevel(owner->GetLevel());
        me->SetReactState(REACT_PASSIVE);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveIdle();
        events.ScheduleEvent(EVENT_TRAVEL_OWNER_CHECK, Milliseconds(500));
    }

    void UpdateAI(uint32 diff) override
    {
        events.Update(diff);
        if (events.ExecuteEvent() != EVENT_TRAVEL_OWNER_CHECK)
            return;
        Player* owner = me->GetCharmerOrOwnerPlayerOrPlayerItself();
        if (!CanTravel(owner) || !me->IsAlive() || owner->GetMap() != me->GetMap() || !owner->InSamePhase(me) ||
            !owner->HasAura(TravelAura(spell), ownerGuid) ||
            !owner->HasActiveSpell(spell) || MarkerGuid(ownerGuid, spell) != me->GetGUID())
        {
            ForgetMarker(ownerGuid, spell, me->GetGUID());
            me->DespawnOrUnsummon();
            return;
        }
        events.ScheduleEvent(EVENT_TRAVEL_OWNER_CHECK, Milliseconds(500));
    }
};

class spell_ascension_runemaster_travel : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_travel);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_ECHO_RETURN, SPELL_WARP, SPELL_WARP_READY, SPELL_WARP_VISUAL,
            SPELL_WARP_SUMMON, SPELL_WARP_DAMAGE, SPELL_RUNESHROUD, SPELL_SHROUDWALKER});
    }

    SpellCastResult CheckTravel()
    {
        Player* player = GetCaster()->ToPlayer();
        return CanTravel(player) && player->HasActiveSpell(GetSpellInfo()->Id)
            ? SPELL_CAST_OK : SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
    }

    void SummonEcho(SpellEffIndex index)
    {
        if (GetSpellInfo()->Id != SPELL_ECHO_RUNE)
            return;
        PreventHitDefaultEffect(index);
        StartTravel(GetCaster()->ToPlayer(), SPELL_ECHO_RUNE);
    }

    void SummonDagger(SpellEffIndex index)
    {
        if (GetSpellInfo()->Id != SPELL_WARPDAGGER)
            return;
        PreventHitDefaultEffect(index);
        StartTravel(GetCaster()->ToPlayer(), SPELL_WARPDAGGER);
    }

    void ApplyShroudwalker()
    {
        Player* player = GetCaster()->ToPlayer();
        if (GetSpellInfo()->Id == SPELL_WARPDAGGER && player && player->HasAura(SPELL_SHROUDWALKER) &&
            player->HasAura(SPELL_RUNESHROUD, player->GetGUID()))
            player->RemoveSpellCooldown(SPELL_WARPDAGGER, true);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_runemaster_travel::CheckTravel);
        OnEffectHit += SpellEffectFn(spell_ascension_runemaster_travel::SummonEcho, EFFECT_0, SPELL_EFFECT_ANY);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_runemaster_travel::SummonDagger, EFFECT_0, SPELL_EFFECT_ANY);
        AfterCast += SpellCastFn(spell_ascension_runemaster_travel::ApplyShroudwalker);
    }
};

class spell_ascension_runemaster_return : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_return);

    SpellCastResult CheckReturn()
    {
        Player* player = GetCaster()->ToPlayer();
        uint32 spell = GetSpellInfo()->Id == SPELL_ECHO_RETURN ? SPELL_ECHO_RUNE : SPELL_WARPDAGGER;
        if (spell == SPELL_ECHO_RUNE && GetSpell()->IsTriggered() && player &&
            player->getClass() == CLASS_SPIRIT_MAGE && player->IsAlive() && player->IsInWorld())
            return SPELL_CAST_OK;
        return CanReturn(player, spell) ? SPELL_CAST_OK : SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
    }

    void Echo(SpellEffIndex index)
    {
        if (GetSpellInfo()->Id != SPELL_ECHO_RETURN)
            return;
        if (!GetSpell()->IsTriggered() && !ReturnToMarker(GetCaster()->ToPlayer(), SPELL_ECHO_RUNE))
            PreventHitDefaultEffect(index);
    }

    void Warp(SpellEffIndex index)
    {
        if (GetSpellInfo()->Id != SPELL_WARP)
            return;
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        Position destination;
        if (ReturnToMarker(player, SPELL_WARPDAGGER, &destination))
            player->CastSpell(destination.GetPositionX(), destination.GetPositionY(), destination.GetPositionZ(),
                SPELL_WARP_DAMAGE, true);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_runemaster_return::CheckReturn);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_runemaster_return::Echo, EFFECT_0, SPELL_EFFECT_ANY);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_runemaster_return::Warp, EFFECT_0, SPELL_EFFECT_ANY);
    }
};

class runemaster_travel_auras : public UnitScript
{
public:
    runemaster_travel_auras() : UnitScript("runemaster_travel_auras", true, {UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode mode) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || !application)
            return;
        Aura* aura = application->GetBase();
        if (aura->GetCasterGUID() != player->GetGUID())
            return;
        uint32 id = aura->GetId();
        if (id == SPELL_ECHO_RUNE)
        {
            if (mode == AURA_REMOVE_BY_EXPIRE && ReturnToMarker(player, SPELL_ECHO_RUNE))
                player->CastSpell(player, SPELL_ECHO_RETURN, true);
            else
                ClearTravel(player, SPELL_ECHO_RUNE);
        }
        else if (id == SPELL_WARP_READY)
            ClearTravel(player, SPELL_WARPDAGGER);
    }
};

class runemaster_travel_lifecycle : public PlayerScript
{
public:
    runemaster_travel_lifecycle() : PlayerScript("runemaster_travel_lifecycle",
        {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_MAP_CHANGED,
            PLAYERHOOK_ON_FORGOT_SPELL, PLAYERHOOK_ON_UPDATE}) { }

    void Clear(Player* player)
    {
        if (player->getClass() == CLASS_SPIRIT_MAGE)
            for (uint32 spell : {SPELL_ECHO_RUNE, SPELL_WARPDAGGER})
                ClearTravel(player, spell);
    }

    void OnPlayerLogin(Player* player) override { Clear(player); }
    void OnPlayerLogout(Player* player) override { Clear(player); }
    void OnPlayerMapChanged(Player* player) override { Clear(player); }

    void OnPlayerForgotSpell(Player* player, uint32 spell) override
    {
        if (player->getClass() == CLASS_SPIRIT_MAGE && (spell == SPELL_ECHO_RUNE || spell == SPELL_WARPDAGGER))
            ClearTravel(player, spell);
    }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        if (player->getClass() != CLASS_SPIRIT_MAGE)
            return;
        for (uint32 spell : {SPELL_ECHO_RUNE, SPELL_WARPDAGGER})
            if ((MarkerGuid(player->GetGUID(), spell) || player->GetTemporarySpellReplacement(spell) != spell) &&
                !HasTravelMarker(player, spell))
                ClearTravel(player, spell);
    }
};
}

void ApplyAscensionRunemasterTravelContracts(SpellInfo* info)
{
    if (info->SpellFamilyName != 38)
        return;
    if (info->Id == SPELL_ECHO_RETURN)
        info->Effects[EFFECT_1].Effect = 0;
    if (info->Id == SPELL_WARP)
    {
        info->Effects[EFFECT_0].Effect = SPELL_EFFECT_DUMMY;
        info->Effects[EFFECT_1].Effect = 0;
        info->Effects[EFFECT_2].Effect = 0;
    }
    if (info->Id == SPELL_WARP_DAMAGE)
    {
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_DEST_DEST);
        info->Effects[EFFECT_0].TargetB = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ENEMY);
        info->_InitializeExplicitTargetMask();
    }
}

void AddSC_AscensionRunemasterTravel()
{
    RegisterCreatureAI(npc_ascension_runemaster_marker);
    RegisterSpellScript(spell_ascension_runemaster_travel);
    RegisterSpellScript(spell_ascension_runemaster_return);
    new runemaster_travel_auras();
    new runemaster_travel_lifecycle();
}
