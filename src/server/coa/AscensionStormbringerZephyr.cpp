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
enum ZephyrSpells : uint32
{
    SPELL_RAGING_ZEPHYR = 704201,
    SPELL_ZEPHYR_PERIODIC = 725390,
    SPELL_ZEPHYR_PULL = 704210
};

enum ZephyrEntries : uint32
{
    NPC_RAGING_ZEPHYR = 4078281,
    EVENT_ZEPHYR_OWNER_CHECK = 1
};

bool HasZephyrOwner(Creature* zephyr)
{
    if (!zephyr || zephyr->GetEntry() != NPC_RAGING_ZEPHYR || !zephyr->IsAlive() || !zephyr->IsInWorld())
        return false;
    Player* owner = zephyr->GetCharmerOrOwnerPlayerOrPlayerItself();
    return owner && owner->GetGUID() == zephyr->GetOwnerGUID() && owner->getClass() == CLASS_STORMBRINGER &&
        owner->IsAlive() && owner->IsInWorld() && owner->HasActiveSpell(SPELL_RAGING_ZEPHYR) &&
        owner->GetMap() == zephyr->GetMap() && owner->InSamePhase(zephyr);
}

struct npc_ascension_stormbringer_zephyr : ScriptedAI
{
    explicit npc_ascension_stormbringer_zephyr(Creature* creature) : ScriptedAI(creature) { }
    EventMap events;

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void EnterEvadeMode(EvadeReason) override { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* owner = summoner ? summoner->ToPlayer() : nullptr;
        if (!owner || owner->getClass() != CLASS_STORMBRINGER || !owner->HasActiveSpell(SPELL_RAGING_ZEPHYR))
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
        events.ScheduleEvent(EVENT_ZEPHYR_OWNER_CHECK, Milliseconds(500));
    }

    void UpdateAI(uint32 diff) override
    {
        events.Update(diff);
        if (events.ExecuteEvent() != EVENT_ZEPHYR_OWNER_CHECK)
            return;
        if (!HasZephyrOwner(me))
        {
            me->DespawnOrUnsummon();
            return;
        }
        events.ScheduleEvent(EVENT_ZEPHYR_OWNER_CHECK, Milliseconds(500));
    }
};

class spell_ascension_raging_zephyr : public SpellScript
{
    PrepareSpellScript(spell_ascension_raging_zephyr);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_ZEPHYR_PERIODIC, SPELL_ZEPHYR_PULL}); }

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == CLASS_STORMBRINGER;
    }

    void Summon(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        WorldLocation const* destination = GetHitDest();
        int32 duration = GetSpellInfo()->GetDuration();
        player->ApplySpellMod(SPELL_RAGING_ZEPHYR, SPELLMOD_DURATION, duration);
        if (!destination || duration <= 0 || !player->HasActiveSpell(SPELL_RAGING_ZEPHYR))
            return;
        TempSummon* zephyr = player->SummonCreature(NPC_RAGING_ZEPHYR, *destination,
            TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, uint32(duration));
        if (!zephyr)
            return;
        zephyr->SetUInt32Value(UNIT_CREATED_BY_SPELL, SPELL_RAGING_ZEPHYR);
        zephyr->CastSpell(zephyr, SPELL_ZEPHYR_PERIODIC, true);
        if (Aura* aura = zephyr->GetAura(SPELL_ZEPHYR_PERIODIC, zephyr->GetGUID()))
        {
            aura->SetMaxDuration(duration);
            aura->SetDuration(duration);
        }
        else
            zephyr->DespawnOrUnsummon();
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_raging_zephyr::Summon, EFFECT_0, SPELL_EFFECT_SUMMON);
    }
};

class spell_ascension_zephyr_pull : public SpellScript
{
    PrepareSpellScript(spell_ascension_zephyr_pull);

    void CheckTarget(SpellEffIndex index)
    {
        Creature* zephyr = GetCaster()->ToCreature();
        Unit* target = GetHitUnit();
        if (!HasZephyrOwner(zephyr) || !target || !target->IsAlive() || !target->IsInWorld() ||
            target->GetMap() != zephyr->GetMap() || !zephyr->InSamePhase(target) ||
            !zephyr->IsValidAttackTarget(target) || target->IsInFlight() || target->GetVehicle() ||
            target->GetTransport())
        {
            PreventHitDefaultEffect(index);
            return;
        }
        if (Player* player = target->ToPlayer())
            if (player->IsBeingTeleported())
                PreventHitDefaultEffect(index);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_zephyr_pull::CheckTarget,
            EFFECT_0, SPELL_EFFECT_PULL_TOWARDS);
    }
};

class stormbringer_zephyr_metadata : public GlobalScript
{
public:
    stormbringer_zephyr_metadata() : GlobalScript("stormbringer_zephyr_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 22)
            return;
        if (info->Id == SPELL_RAGING_ZEPHYR)
            info->Effects[EFFECT_1].Effect = 0;
        if (info->Id == SPELL_ZEPHYR_PULL)
            info->Effects[EFFECT_1].Effect = 0;
    }
};
}

void AddSC_AscensionStormbringerZephyr()
{
    RegisterCreatureAI(npc_ascension_stormbringer_zephyr);
    RegisterSpellScript(spell_ascension_raging_zephyr);
    RegisterSpellScript(spell_ascension_zephyr_pull);
    new stormbringer_zephyr_metadata();
}
