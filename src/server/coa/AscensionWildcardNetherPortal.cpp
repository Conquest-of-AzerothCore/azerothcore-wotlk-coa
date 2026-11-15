/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Containers.h"
#include "CreatureAI.h"
#include "DBCStores.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "PetDefines.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <array>
#include <list>
#include <string_view>
#include <vector>

namespace
{
enum NetherPortalSpells : uint32
{
    SPELL_NETHER_PORTAL = 290441,
    SPELL_NETHER_PORTAL_SUMMON = 290444
};

constexpr uint32 NETHER_PORTAL_CREATURE = 840095;
constexpr uint32 NETHER_PORTAL_GUARDIAN_PROPERTIES = 61;
constexpr uint32 NETHER_PORTAL_GRACE_MS = 500;
constexpr float NETHER_PORTAL_SEARCH_RANGE = 100.0f;
constexpr uint32 DEMON_OWNER_CHECK_MS = 1000;
constexpr std::array<uint32, 4> LESSER_DEMONS = { 840099, 840096, 840097, 840098 };
constexpr std::array<uint32, 2> GREATER_DEMONS = { 840101, 840102 };
constexpr uint32 LESSER_DEMON_TIER = 290447;
constexpr uint32 GREATER_DEMON_TIER = 290448;
constexpr std::size_t DEMON_LIMIT = 4;
constexpr std::array<std::string_view, 3> PORTAL_SPELLS = { "Shadow Bolt", "Incinerate", "Soul Fire" };

bool OpensThePortal(SpellInfo const* info)
{
    if (!info || info->SpellFamilyName != SPELLFAMILY_WARLOCK || !info->SpellName[LOCALE_enUS])
        return false;
    std::string_view const name = info->SpellName[LOCALE_enUS];
    return std::find(PORTAL_SPELLS.begin(), PORTAL_SPELLS.end(), name) != PORTAL_SPELLS.end();
}

struct npc_wildcard_nether_portal_demon : public ScriptedAI
{
    explicit npc_wildcard_nether_portal_demon(Creature* creature) : ScriptedAI(creature) { }

    ObjectGuid _owner;
    uint32 _check = 0;

    void IsSummonedBy(WorldObject* summoner) override
    {
        Unit* owner = summoner ? summoner->ToUnit() : nullptr;
        if (!owner)
        {
            me->DespawnOrUnsummon();
            return;
        }
        _owner = owner->GetGUID();
        if (owner->HasUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED))
            me->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);
        me->SetFaction(owner->GetFaction());
        me->SetReactState(REACT_DEFENSIVE);
        me->GetMotionMaster()->MoveFollow(owner, PET_FOLLOW_DIST, PET_FOLLOW_ANGLE);
    }

    void MoveInLineOfSight(Unit*) override { }

    void Assist(Unit* owner)
    {
        if (me->GetVictim())
            return;
        Unit* victim = owner->GetVictim();
        if (!victim)
            if (Player* player = owner->ToPlayer())
                victim = player->GetSelectedUnit();
        if (victim && me->IsValidAttackTarget(victim))
            AttackStart(victim);
        else if (!me->isMoving() && !me->IsWithinDistInMap(owner, PET_FOLLOW_DIST * 2))
            me->GetMotionMaster()->MoveFollow(owner, PET_FOLLOW_DIST, PET_FOLLOW_ANGLE);
    }

    void UpdateAI(uint32 diff) override
    {
        if (_check <= diff)
        {
            _check = DEMON_OWNER_CHECK_MS;
            Unit* owner = ObjectAccessor::GetUnit(*me, _owner);
            if (!owner || !owner->IsInWorld() || owner->GetMap() != me->GetMap())
            {
                me->DespawnOrUnsummon();
                return;
            }
            Assist(owner);
        }
        else
            _check -= diff;

        if (UpdateVictim())
            DoMeleeAttackIfReady();
    }
};

class aura_wildcard_nether_portal : public AuraScript
{
    PrepareAuraScript(aura_wildcard_nether_portal);

    std::vector<ObjectGuid> _demons;
    std::size_t _summoned = 0;

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ LESSER_DEMON_TIER, GREATER_DEMON_TIER }) &&
            sSummonPropertiesStore.LookupEntry(NETHER_PORTAL_GUARDIAN_PROPERTIES);
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Spell const* spell = event.GetProcSpell();
        return owner->IsPlayer() && event.GetActor() == owner && spell && !spell->IsTriggered() &&
            _summoned < DEMON_LIMIT && OpensThePortal(event.GetSpellInfo());
    }

    void Banish()
    {
        for (ObjectGuid const& guid : _demons)
            if (Creature* demon = ObjectAccessor::GetCreature(*GetTarget(), guid))
                demon->DespawnOrUnsummon();
        _demons.clear();
    }

    static void ScaleToOwner(Creature* demon, Unit* owner)
    {
        CreatureTemplate const* info = demon->GetCreatureTemplate();
        uint8 const level = owner->GetLevel();
        CreatureBaseStats const* stats = sObjectMgr->GetCreatureBaseStats(level, info->unit_class);
        demon->SetLevel(level);
        uint32 const health = std::max<uint32>(1, stats->GenerateHealth(info));
        demon->SetCreateHealth(health);
        demon->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
        float const damage = stats->GenerateBaseDamage(info);
        for (WeaponAttackType attack : { BASE_ATTACK, OFF_ATTACK, RANGED_ATTACK })
        {
            demon->SetBaseWeaponDamage(attack, MINDAMAGE, damage);
            demon->SetBaseWeaponDamage(attack, MAXDAMAGE, damage * 1.5f);
        }
        demon->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER, BASE_VALUE, float(stats->AttackPower));
        demon->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER_RANGED, BASE_VALUE, float(stats->RangedAttackPower));
        demon->UpdateAllStats();
        demon->SetFullHealth();
    }

    void Summon(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        bool const greater = ++_summoned == DEMON_LIMIT;
        if (greater)
            Banish();
        uint32 const tier = greater ? GREATER_DEMON_TIER : LESSER_DEMON_TIER;
        uint32 const entry = greater ? Acore::Containers::SelectRandomContainerElement(GREATER_DEMONS) :
            Acore::Containers::SelectRandomContainerElement(LESSER_DEMONS);
        int32 const remaining = GetDuration();
        SummonPropertiesEntry const* properties =
            sSummonPropertiesStore.LookupEntry(NETHER_PORTAL_GUARDIAN_PROPERTIES);
        if (remaining <= 0 || !properties)
            return;
        Position spot = owner->GetNearPosition(PET_FOLLOW_DIST, PET_FOLLOW_ANGLE);
        TempSummon* demon = owner->GetMap()->SummonCreature(entry, spot, properties,
            uint32(remaining) + NETHER_PORTAL_GRACE_MS, owner, SPELL_NETHER_PORTAL_SUMMON);
        if (!demon)
            return;
        demon->SetTempSummonType(TEMPSUMMON_TIMED_DESPAWN);
        ScaleToOwner(demon, owner);
        demon->CastSpell(demon, tier, true);
        _demons.push_back(demon->GetGUID());
        Spell const* spell = event.GetProcSpell();
        Unit* target = spell ? spell->m_targets.GetUnitTarget() : nullptr;
        if (target && demon->IsAIEnabled && demon->IsValidAttackTarget(target))
            demon->AI()->AttackStart(target);
    }

    void Close(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* owner = GetTarget();
        for (ObjectGuid const& guid : _demons)
            if (Creature* demon = ObjectAccessor::GetCreature(*owner, guid))
                demon->DespawnOrUnsummon(Milliseconds(NETHER_PORTAL_GRACE_MS));
        _demons.clear();
        std::list<Creature*> portals;
        owner->GetCreatureListWithEntryInGrid(portals, NETHER_PORTAL_CREATURE, NETHER_PORTAL_SEARCH_RANGE);
        for (Creature* portal : portals)
        {
            TempSummon* summon = portal->ToTempSummon();
            if (summon && summon->GetSummonerGUID() == owner->GetGUID() &&
                portal->GetUInt32Value(UNIT_CREATED_BY_SPELL) == SPELL_NETHER_PORTAL)
                portal->DespawnOrUnsummon(Milliseconds(NETHER_PORTAL_GRACE_MS));
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_nether_portal::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_nether_portal::Summon, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_wildcard_nether_portal::Close, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionWildcardNetherPortal()
{
    RegisterCreatureAI(npc_wildcard_nether_portal_demon);
    RegisterSpellScript(aura_wildcard_nether_portal);
}
