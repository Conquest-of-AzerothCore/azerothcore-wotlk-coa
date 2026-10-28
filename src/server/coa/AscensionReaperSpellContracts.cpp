/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Creature.h"
#include "CreatureAI.h"
#include "DBCStores.h"
#include "DynamicObject.h"
#include "MotionMaster.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellAuras.h"
#include "SpellScript.h"

namespace
{
constexpr uint32 SPELL_THRESH = 505170;
constexpr uint32 SPELL_THRESH_TRANSFORM = 525058;
constexpr uint32 SPELL_BLOODSHATTER = 505326;
constexpr uint32 SPELL_BLOODSHATTER_TRANSFORM = 525299;
constexpr uint32 SPELL_SOULSTONE_LURE = 561376;
constexpr uint32 SPELL_SOULSTONE_LURE_AURA = 561826;
constexpr uint32 NPC_SOULSTONE_LURE = 557911;
constexpr uint32 SUMMON_PROPERTIES_STATIONARY = 64;
constexpr uint32 SPELL_DEATHBRINGER = 573040;
constexpr uint32 SPELL_APPARITION = 705389;
constexpr uint32 SPELL_SOULS_FOR_SLAUGHTER_DAMAGE = 575847;
constexpr uint32 SPELL_HARVESTING_GROUNDS = 705413;
constexpr uint32 SPELL_HARVESTING_GROUNDS_SLOW = 707591;
constexpr uint32 NPC_HARVESTING_GROUNDS = 300662;

class reaper_spell_contracts : public GlobalScript
{
public:
    reaper_spell_contracts() : GlobalScript("reaper_spell_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || info->SpellFamilyName != 36)
            return;

        if (info->Id == SPELL_HARVESTING_GROUNDS &&
            info->Effects[EFFECT_1].Effect == SPELL_EFFECT_SUMMON &&
            info->Effects[EFFECT_1].MiscValue == NPC_HARVESTING_GROUNDS)
            info->Effects[EFFECT_1].MiscValueB = SUMMON_PROPERTIES_STATIONARY;
        if (info->Id == SPELL_HARVESTING_GROUNDS_SLOW &&
            info->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_MOD_DECREASE_SPEED)
            info->DurationEntry = sSpellDurationStore.LookupEntry(8);

        if (info->Id == SPELL_SOULS_FOR_SLAUGHTER_DAMAGE &&
            info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
        {
            info->AscensionInheritsResolvedAmount = true;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
        }

        if (info->Id == SPELL_APPARITION &&
            info->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
            info->Effects[EFFECT_1].MiscValue == SPELLMOD_EFFECT1 &&
            info->Effects[EFFECT_1].SpellClassMask == flag96(0, 67108864, 0))
            info->Effects[EFFECT_1].MiscValue = SPELLMOD_EFFECT2;

        if (info->Id == SPELL_THRESH)
        {
            info->CasterAuraSpell = SPELL_THRESH_TRANSFORM;
            info->ExcludeCasterAuraSpell = SPELL_BLOODSHATTER_TRANSFORM;
        }
        else if (info->Id == SPELL_BLOODSHATTER)
            info->CasterAuraSpell = SPELL_BLOODSHATTER_TRANSFORM;
        else if (info->Id == SPELL_SOULSTONE_LURE && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SUMMON &&
            info->Effects[EFFECT_0].MiscValue == NPC_SOULSTONE_LURE)
            info->Effects[EFFECT_0].MiscValueB = SUMMON_PROPERTIES_STATIONARY;
        else if (info->Id == SPELL_DEATHBRINGER &&
            info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_DURATION &&
            info->Effects[EFFECT_0].SpellClassMask == flag96(16777216, 0, 0))
            info->Effects[EFFECT_0].SpellClassMask = flag96(16777216, 536875008, 67108864);
    }
};

class aura_ascension_reaper_harvesting_grounds : public AuraScript
{
    PrepareAuraScript(aura_ascension_reaper_harvesting_grounds);

    void Leave(AuraEffect const*, AuraEffectHandleModes)
    {
        Aura* aura = GetAura();
        Unit* target = GetTarget();
        Unit* caster = GetCaster();
        if (aura->GetType() != DYNOBJ_AURA_TYPE || aura->IsRemoved() || aura->GetDuration() <= 0 ||
            !target || !target->IsAlive() || !caster || caster->IsFriendlyTo(target) ||
            target->IsImmuneToForcedMovement())
            return;
        DynamicObject* ground = aura->GetDynobjOwner();
        if (!ground->IsInWorld() || !ground->IsInMap(target) || !ground->InSamePhase(target) ||
            ground->IsWithinDistInMap(target, ground->GetRadius()))
            return;
        target->GetMotionMaster()->MoveJump(ground->GetPositionX(), ground->GetPositionY(),
            ground->GetPositionZ(), 20.0f, 5.0f);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_reaper_harvesting_grounds::Leave,
            EFFECT_0, SPELL_AURA_MOD_MELEE_RANGED_HASTE, AURA_EFFECT_HANDLE_REAL);
    }
};

class npc_ascension_reaper_harvesting_grounds : public CreatureScript
{
public:
    npc_ascension_reaper_harvesting_grounds() : CreatureScript("npc_ascension_reaper_harvesting_grounds") { }

    struct GroundAI : public CreatureAI
    {
        explicit GroundAI(Creature* creature) : CreatureAI(creature) { }

        void IsSummonedBy(WorldObject* summoner) override
        {
            Unit* owner = summoner ? summoner->ToUnit() : nullptr;
            if (!owner)
                return;
            me->SetOwnerGUID(owner->GetGUID());
            me->SetCreatorGUID(owner->GetGUID());
            me->SetFaction(owner->GetFaction());
            me->SetReactState(REACT_PASSIVE);
            me->SetCombatMovement(false);
        }

        void AttackStart(Unit*) override { }
        void UpdateAI(uint32) override { }
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new GroundAI(creature);
    }
};

class npc_ascension_reaper_soulstone_lure : public CreatureScript
{
public:
    npc_ascension_reaper_soulstone_lure() : CreatureScript("npc_ascension_reaper_soulstone_lure") { }

    struct LureAI : public CreatureAI
    {
        explicit LureAI(Creature* creature) : CreatureAI(creature) { }

        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* player = summoner ? summoner->ToPlayer() : nullptr;
            if (!player || player->getClass() != CLASS_REAPER)
                return;

            me->SetOwnerGUID(player->GetGUID());
            me->SetCreatorGUID(player->GetGUID());
            me->SetFaction(player->GetFaction());
            me->SetReactState(REACT_PASSIVE);
            me->SetCombatMovement(false);
            me->CastSpell(me, SPELL_SOULSTONE_LURE_AURA, true);
        }

        void AttackStart(Unit*) override { }
        void UpdateAI(uint32) override { }
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new LureAI(creature);
    }
};

}

void AddSC_AscensionReaperSpellContracts()
{
    new reaper_spell_contracts();
    RegisterSpellScript(aura_ascension_reaper_harvesting_grounds);
    new npc_ascension_reaper_harvesting_grounds();
    new npc_ascension_reaper_soulstone_lure();
}
