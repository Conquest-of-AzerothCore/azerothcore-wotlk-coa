/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "DBCStores.h"
#include "EventMap.h"
#include "MotionMaster.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include <algorithm>

namespace
{
enum RiftCloneSpells : uint32
{
    SPELL_PHASE_OUT = 500671,
    SPELL_RIFT_CLONES = 707463,
    SPELL_RIFT_CLONE_SUMMON = 707464,
    SPELL_RIFT_CLONE_AURA = 707465,
    SPELL_RIFT_EXPLOSION = 707466,
    SPELL_CLONE_ME = 45204
};
enum RiftCloneEntries : uint32 { NPC_RIFT_CLONE = 840004 };
enum RiftCloneEvents : uint32 { EVENT_CHECK_OWNER = 1, POINT_RUN_AWAY = 1 };

class runemaster_rift_clone_cast : public AllSpellScript
{
public:
    runemaster_rift_clone_cast() : AllSpellScript("runemaster_rift_clone_cast", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || !player->IsAlive() || !player->IsInWorld() ||
            spell->IsTriggered() || info->Id != SPELL_PHASE_OUT ||
            !player->HasAura(SPELL_RIFT_CLONES, player->GetGUID()))
            return;
        SpellInfo const* summon = sSpellMgr->GetSpellInfo(SPELL_RIFT_CLONE_SUMMON);
        if (!summon || summon->GetDuration() <= 0)
            return;
        int32 count = std::clamp(summon->Effects[EFFECT_0].CalcValue(player), 0, 10);
        for (int32 i = 0; i < count; ++i)
            player->SummonCreature(NPC_RIFT_CLONE, player->GetPosition(),
                TEMPSUMMON_TIMED_DESPAWN, uint32(summon->GetDuration()));
    }
};

struct npc_ascension_rift_clone : ScriptedAI
{
    explicit npc_ascension_rift_clone(Creature* creature) : ScriptedAI(creature) { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* owner = summoner ? summoner->ToPlayer() : nullptr;
        SpellInfo const* summon = sSpellMgr->GetSpellInfo(SPELL_RIFT_CLONE_SUMMON);
        if (!owner || owner->getClass() != CLASS_SPIRIT_MAGE || !summon)
        {
            me->DespawnOrUnsummon();
            return;
        }
        me->SetOwnerGUID(owner->GetGUID());
        me->SetLevel(owner->GetLevel());
        me->SetFaction(owner->GetFaction());
        me->SetReactState(REACT_PASSIVE);
        owner->CastSpell(me, SPELL_CLONE_ME, true);
        owner->AddAura(SPELL_RIFT_CLONE_AURA, me);
        float distance = me->GetSpeed(MOVE_RUN) * float(summon->GetDuration()) / 1000.0f;
        Position destination = me->GetFirstCollisionPosition(distance, frand(0.0f, float(2.0 * M_PI)));
        me->GetMotionMaster()->MovePoint(POINT_RUN_AWAY, destination, FORCED_MOVEMENT_RUN);
        _events.ScheduleEvent(EVENT_CHECK_OWNER, Milliseconds(250));
    }

    void UpdateAI(uint32 diff) override
    {
        _events.Update(diff);
        if (_events.ExecuteEvent() != EVENT_CHECK_OWNER)
            return;
        Unit* owner = me->GetOwner();
        if (!owner || !owner->IsAlive() || !owner->IsInWorld() || !me->IsInMap(owner) ||
            !me->InSamePhase(owner) || !owner->HasAura(SPELL_RIFT_CLONES, owner->GetGUID()))
        {
            me->DespawnOrUnsummon();
            return;
        }
        _events.ScheduleEvent(EVENT_CHECK_OWNER, Milliseconds(250));
    }

    EventMap _events;
};

class runemaster_rift_clone_scaling : public UnitScript
{
public:
    runemaster_rift_clone_scaling() : UnitScript("runemaster_rift_clone_scaling", true,
        {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        if (!caster || info->Id != SPELL_RIFT_EXPLOSION || info->SpellFamilyName != 38 || index != EFFECT_0)
            return;
        Unit const* owner = caster;
        if (Creature const* clone = caster->ToCreature())
        {
            if (clone->GetEntry() != NPC_RIFT_CLONE)
                return;
            owner = clone->GetOwner();
        }
        if (owner && owner->IsPlayer() && owner->getClass() == CLASS_SPIRIT_MAGE)
            value += std::max(0.0f, owner->GetTotalAttackPowerValue(BASE_ATTACK)) * 0.195f;
    }
};

class runemaster_rift_clone_metadata : public GlobalScript
{
public:
    runemaster_rift_clone_metadata() : GlobalScript("runemaster_rift_clone_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == SPELL_RIFT_EXPLOSION && info->SpellFamilyName == 38)
        {
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
            info->Effects[EFFECT_0].RadiusEntry = sSpellRadiusStore.LookupEntry(8);
        }
    }
};
}

void AddSC_AscensionRunemasterRiftClones()
{
    new runemaster_rift_clone_cast();
    new runemaster_rift_clone_scaling();
    new runemaster_rift_clone_metadata();
    RegisterCreatureAI(npc_ascension_rift_clone);
}
