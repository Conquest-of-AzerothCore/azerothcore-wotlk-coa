/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
enum ElectrifiedWatersSpells : uint32
{
    SPELL_STATIC_ELECTRICITY = 524954,
    SPELL_ELECTRIFIED_WATERS = 573436,
    SPELL_ELECTRIFIED_REFUND = 573442
};

enum ElectrifiedWatersEntries : uint32
{
    NPC_ELECTRIFIED_WATER_ELEMENTAL = 310603
};

constexpr uint32 DrownRanks[] = {806407, 572760, 572761, 572762, 572763, 572764};

bool DrowningByCaster(Unit* victim, ObjectGuid caster)
{
    for (uint32 rank : DrownRanks)
        if (victim->GetAura(rank, caster))
            return true;
    return false;
}

bool SummonsElectrifiedWater(Player* owner)
{
    return owner->getClass() == CLASS_STORMBRINGER &&
        (owner->HasAura(SPELL_ELECTRIFIED_WATERS) || owner->HasAura(SPELL_STATIC_ELECTRICITY));
}

class aura_ascension_electrified_waters : public AuraScript
{
    PrepareAuraScript(aura_ascension_electrified_waters);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_ELECTRIFIED_REFUND});
    }

    bool CheckProc(ProcEventInfo& event)
    {
        DamageInfo* damage = event.GetDamageInfo();
        Unit* victim = event.GetActionTarget();
        return (event.GetHitMask() & PROC_HIT_CRITICAL) && damage && damage->GetDamage() &&
            damage->GetDamageType() != DOT && victim && victim != GetTarget() &&
            DrowningByCaster(victim, GetTarget()->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_electrified_waters::CheckProc);
    }
};

struct npc_ascension_electrified_water_elemental : ScriptedAI
{
    explicit npc_ascension_electrified_water_elemental(Creature* creature) : ScriptedAI(creature) { }

    bool dissipated = false;

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void EnterEvadeMode(EvadeReason) override { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* owner = summoner ? summoner->ToPlayer() : nullptr;
        if (!owner || !SummonsElectrifiedWater(owner))
        {
            me->DespawnOrUnsummon();
            return;
        }

        me->SetOwnerGUID(owner->GetGUID());
        me->SetFaction(owner->GetFaction());
        me->SetLevel(owner->GetLevel());
        me->SetReactState(REACT_PASSIVE);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveIdle();
    }

    void OnDespawn() override
    {
        if (dissipated || me->GetEntry() != NPC_ELECTRIFIED_WATER_ELEMENTAL)
            return;

        dissipated = true;
        Player* owner = ObjectAccessor::GetPlayer(*me, me->GetOwnerGUID());
        if (owner && owner->IsInWorld() && owner->IsAlive() && SummonsElectrifiedWater(owner))
            owner->CastSpell(owner, SPELL_ELECTRIFIED_REFUND, true);
    }
};
}

void AddSC_AscensionStormbringerDrown()
{
    RegisterSpellScript(aura_ascension_electrified_waters);
    RegisterCreatureAI(npc_ascension_electrified_water_elemental);
}
