/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "DBCStores.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <list>

namespace
{
enum SphereSpells : uint32
{
    SPELL_SPHERES_OF_POWER = 706434,
    SPELL_POWER_SPHERE = 706433,
    SPELL_STORMFLOW = 567555
};

enum SphereEntries : uint32
{
    NPC_POWER_SPHERE = 503201,
    SUMMON_PROPERTIES_SPHERE = 61
};

struct npc_ascension_power_sphere : ScriptedAI
{
    explicit npc_ascension_power_sphere(Creature* creature) : ScriptedAI(creature) { }
    ObjectGuid targetGuid;
    bool spent = false;
    uint32 timer = 0;

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void EnterEvadeMode(EvadeReason) override { }

    void IsSummonedBy(WorldObject*) override
    {
        me->SetReactState(REACT_PASSIVE);
        me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE);
    }

    void SetGUID(ObjectGuid const& guid, int32 = 0) override
    {
        if (spent)
            return;
        targetGuid = guid;
        if (Unit* target = ObjectAccessor::GetUnit(*me, targetGuid))
            me->GetMotionMaster()->MoveChase(target, 0.0f);
    }

    void UpdateAI(uint32 diff) override
    {
        if (spent)
            return;
        if (timer > diff)
        {
            timer -= diff;
            return;
        }
        timer = 100;
        Player* owner = me->GetCharmerOrOwnerPlayerOrPlayerItself();
        Unit* target = ObjectAccessor::GetUnit(*me, targetGuid);
        if (!owner || owner->getClass() != CLASS_STORMBRINGER || !owner->IsAlive() || !owner->IsInWorld() ||
            !owner->HasAura(SPELL_SPHERES_OF_POWER) || owner->GetMap() != me->GetMap() || !owner->InSamePhase(me) ||
            !target || !target->IsAlive() || !target->IsInWorld() || target->GetMap() != me->GetMap() ||
            !me->InSamePhase(target) || !owner->IsValidAttackTarget(target))
        {
            spent = true;
            me->DespawnOrUnsummon();
            return;
        }
        if (!me->IsWithinDistInMap(target, CONTACT_DISTANCE))
            return;

        spent = true;
        SpellInfo const* info = sSpellMgr->GetSpellInfo(SPELL_POWER_SPHERE);
        if (info)
        {
            int32 power = std::max(owner->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_ARCANE),
                owner->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE));
            CustomSpellValues values;
            values.AddSpellMod(SPELLVALUE_BASE_POINT0, info->Effects[EFFECT_0].CalcValue(owner) + int32(power * 0.485f));
            SpellCastTargets targets;
            targets.SetUnitTarget(target);
            targets.SetDst(*target);
            owner->CastSpell(targets, info, &values, TRIGGERED_FULL_MASK);
        }
        me->DespawnOrUnsummon();
    }
};

Creature* FindSphere(Player* player)
{
    std::list<Creature*> summons;
    player->GetAllMinionsByEntry(summons, NPC_POWER_SPHERE);
    for (Creature* summon : summons)
        if (summon->IsAlive() && summon->IsInWorld() && summon->GetMap() == player->GetMap() &&
            summon->InSamePhase(player))
            if (auto* ai = dynamic_cast<npc_ascension_power_sphere*>(summon->AI()); ai && !ai->spent)
                return summon;
    return nullptr;
}

class stormbringer_sphere_hits : public AllSpellScript
{
public:
    stormbringer_sphere_hits() : AllSpellScript("stormbringer_sphere_hits", {ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool) override
    {
        Player* owner = spell->GetCaster()->ToPlayer();
        SpellInfo const* info = spell->GetSpellInfo();
        if (!owner || owner->getClass() != CLASS_STORMBRINGER || info->SpellFamilyName != 22 ||
            !owner->HasAura(SPELL_SPHERES_OF_POWER) || !target || !target->IsAlive() ||
            !owner->IsValidAttackTarget(target) || miss != SPELL_MISS_NONE || info->Id == SPELL_POWER_SPHERE)
            return;

        Creature* sphere = FindSphere(owner);
        if (sSpellMgr->GetFirstSpellInChain(info->Id) == SPELL_STORMFLOW)
        {
            if (sphere)
                sphere->AI()->SetGUID(target->GetGUID());
            return;
        }
        if (sphere || !damage || !roll_chance_i(sSpellMgr->GetSpellInfo(SPELL_SPHERES_OF_POWER)->ProcChance))
            return;

        TempSummon* summon = owner->GetMap()->SummonCreature(NPC_POWER_SPHERE, owner->GetPosition(),
            sSummonPropertiesStore.LookupEntry(SUMMON_PROPERTIES_SPHERE), 0, owner, SPELL_SPHERES_OF_POWER);
        if (summon)
        {
            summon->AI()->SetGUID(target->GetGUID());
        }
    }
};

class stormbringer_sphere_contracts : public GlobalScript
{
public:
    stormbringer_sphere_contracts() : GlobalScript("stormbringer_sphere_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info && info->Id == SPELL_POWER_SPHERE && info->SpellFamilyName == 22)
        {
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        }
    }
};
}

void AddSC_AscensionStormbringerSphere()
{
    RegisterCreatureAI(npc_ascension_power_sphere);
    new stormbringer_sphere_hits();
    new stormbringer_sphere_contracts();
}
