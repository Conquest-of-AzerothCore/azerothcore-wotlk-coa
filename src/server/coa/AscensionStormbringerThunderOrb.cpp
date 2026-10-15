/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "EventMap.h"
#include "MotionMaster.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "TemporarySummon.h"

namespace
{
enum ThunderOrbSpells : uint32
{
    SPELL_SUMMON_THUNDER_ORB = 801802,
    SPELL_ORB_SHOCK_PERIODIC = 801863
};

enum ThunderOrbEntries : uint32
{
    NPC_THUNDER_ORB = 50074,
    EVENT_THUNDER_ORB_OWNER_CHECK = 1
};

bool HasThunderOrbOwner(Creature* orb)
{
    if (!orb || orb->GetEntry() != NPC_THUNDER_ORB || !orb->IsAlive() || !orb->IsInWorld())
        return false;
    Player* owner = orb->GetCharmerOrOwnerPlayerOrPlayerItself();
    return owner && owner->GetGUID() == orb->GetOwnerGUID() && owner->getClass() == CLASS_STORMBRINGER &&
        owner->IsAlive() && owner->IsInWorld() && owner->GetMap() == orb->GetMap() && owner->InSamePhase(orb);
}

struct npc_ascension_thunder_orb : ScriptedAI
{
    explicit npc_ascension_thunder_orb(Creature* creature) : ScriptedAI(creature) { }
    EventMap events;

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void EnterEvadeMode(EvadeReason) override { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* owner = summoner ? summoner->ToPlayer() : nullptr;
        if (!owner || owner->getClass() != CLASS_STORMBRINGER)
        {
            me->DespawnOrUnsummon();
            return;
        }
        me->SetOwnerGUID(owner->GetGUID());
        me->SetFaction(owner->GetFaction());
        me->SetLevel(owner->GetLevel());
        me->SetReactState(REACT_PASSIVE);
        me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveIdle();
        events.ScheduleEvent(EVENT_THUNDER_ORB_OWNER_CHECK, Milliseconds(500));
    }

    void UpdateAI(uint32 diff) override
    {
        events.Update(diff);
        if (events.ExecuteEvent() != EVENT_THUNDER_ORB_OWNER_CHECK)
            return;
        if (!HasThunderOrbOwner(me))
        {
            me->DespawnOrUnsummon();
            return;
        }
        events.ScheduleEvent(EVENT_THUNDER_ORB_OWNER_CHECK, Milliseconds(500));
    }
};

class spell_ascension_summon_thunder_orb : public SpellScript
{
    PrepareSpellScript(spell_ascension_summon_thunder_orb);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_ORB_SHOCK_PERIODIC}); }

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == CLASS_STORMBRINGER;
    }

    void Summon(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        Unit* target = GetExplTargetUnit();
        WorldLocation const* location = GetHitDest();
        if ((!target || target == player) && !location)
            return;
        Position destination = target && target != player ? target->GetPosition() : location->GetPosition();
        int32 duration = GetSpellInfo()->GetDuration();
        player->ApplySpellMod(SPELL_SUMMON_THUNDER_ORB, SPELLMOD_DURATION, duration);
        if (duration <= 0)
            return;
        TempSummon* orb = player->SummonCreature(NPC_THUNDER_ORB, destination,
            TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, uint32(duration));
        if (!orb)
            return;
        orb->SetUInt32Value(UNIT_CREATED_BY_SPELL, SPELL_SUMMON_THUNDER_ORB);
        player->CastSpell(orb, SPELL_ORB_SHOCK_PERIODIC, true);
        if (Aura* aura = orb->GetAura(SPELL_ORB_SHOCK_PERIODIC, player->GetGUID()))
        {
            aura->SetMaxDuration(duration);
            aura->SetDuration(duration);
        }
        else
            orb->DespawnOrUnsummon();
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_summon_thunder_orb::Summon, EFFECT_0, SPELL_EFFECT_SUMMON);
    }
};
}

void AddSC_AscensionStormbringerThunderOrb()
{
    RegisterCreatureAI(npc_ascension_thunder_orb);
    RegisterSpellScript(spell_ascension_summon_thunder_orb);
}
