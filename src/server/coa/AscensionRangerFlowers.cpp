/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "EventMap.h"
#include "MotionMaster.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <list>

namespace
{
enum RangerFlowerSpells : uint32
{
    SPELL_DREAM_FLOWERS = 92117,
    SPELL_FOREST_HERALD = 800150,
    SPELL_GREEN_FLOWER = 561005,
    SPELL_FLOWER_PERIODIC = 561006,
    SPELL_FLOWER_PICKUP = 561007,
    SPELL_HIGHLANDER = 707534,
    SPELL_HIGHLANDER_STACKS = 707539,
    SPELL_HIGHLANDER_READY = 712427,
    SPELL_HIGHLANDER_REDUCTION = 712428,
    SPELL_ADVANTAGE = 804329,
    SPELL_FALCONS_CALL = 804715
};

enum RangerFlowerEntries : uint32
{
    NPC_GREEN_FLOWER = 454239,
    NPC_RED_FLOWER = 454240,
    EVENT_FLOWER_OWNER_CHECK = 1
};

Player* FlowerOwner(Creature* flower)
{
    if (!flower || flower->GetEntry() != NPC_GREEN_FLOWER || !flower->IsAlive() || !flower->IsInWorld())
        return nullptr;
    Player* owner = flower->GetCharmerOrOwnerPlayerOrPlayerItself();
    return owner && owner->getClass() == CLASS_RANGER && owner->GetGUID() == flower->GetOwnerGUID() &&
        owner->IsAlive() && owner->IsInWorld() && owner->GetMap() == flower->GetMap() &&
        owner->InSamePhase(flower) &&
        (owner->HasAura(SPELL_DREAM_FLOWERS) || owner->HasAura(SPELL_FOREST_HERALD)) ? owner : nullptr;
}

struct npc_ascension_ranger_flower : ScriptedAI
{
    explicit npc_ascension_ranger_flower(Creature* creature) : ScriptedAI(creature) { }
    EventMap events;

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void EnterEvadeMode(EvadeReason) override { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = summoner ? summoner->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_RANGER)
        {
            me->DespawnOrUnsummon();
            return;
        }
        me->SetOwnerGUID(player->GetGUID());
        me->SetFaction(player->GetFaction());
        me->SetLevel(player->GetLevel());
        me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE);
        me->SetReactState(REACT_PASSIVE);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveIdle();
        me->CastSpell(me, SPELL_FLOWER_PERIODIC, true);
        events.ScheduleEvent(EVENT_FLOWER_OWNER_CHECK, Milliseconds(500));
    }

    void UpdateAI(uint32 diff) override
    {
        events.Update(diff);
        if (events.ExecuteEvent() != EVENT_FLOWER_OWNER_CHECK)
            return;
        if (!FlowerOwner(me))
        {
            me->DespawnOrUnsummon();
            return;
        }
        events.ScheduleEvent(EVENT_FLOWER_OWNER_CHECK, Milliseconds(500));
    }
};

class spell_ascension_ranger_green_flower : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_green_flower);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_FLOWER_PERIODIC, SPELL_HIGHLANDER_STACKS, SPELL_HIGHLANDER_READY});
    }

    bool Load() override { return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_RANGER; }

    void Summon(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        WorldLocation const* destination = GetHitDest();
        int32 duration = GetSpellInfo()->GetDuration();
        player->ApplySpellMod(GetSpellInfo()->Id, SPELLMOD_DURATION, duration);
        if (!destination || duration <= 0 ||
            (!player->HasAura(SPELL_DREAM_FLOWERS) && !player->HasAura(SPELL_FOREST_HERALD)))
            return;
        TempSummon* flower = player->SummonCreature(NPC_GREEN_FLOWER, *destination,
            TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, uint32(duration));
        if (!flower)
            return;
        flower->SetUInt32Value(UNIT_CREATED_BY_SPELL, GetSpellInfo()->Id);
        if (player->HasAura(SPELL_HIGHLANDER))
        {
            player->CastSpell(player, SPELL_HIGHLANDER_STACKS, true);
            Aura* stacks = player->GetAura(SPELL_HIGHLANDER_STACKS, player->GetGUID());
            if (stacks && uint32(stacks->GetStackAmount()) >= stacks->GetSpellInfo()->CalcMaxAuraStacks(player))
            {
                player->RemoveAurasDueToSpell(SPELL_HIGHLANDER_STACKS, player->GetGUID());
                player->CastSpell(player, SPELL_HIGHLANDER_READY, true);
            }
        }
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_ranger_green_flower::Summon, EFFECT_0, SPELL_EFFECT_SUMMON);
    }
};

class spell_ascension_ranger_flower_pickup : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_flower_pickup);

    void SelectAlly(std::list<WorldObject*>& targets)
    {
        Creature* flower = GetCaster()->ToCreature();
        Player* owner = FlowerOwner(flower);
        if (!owner)
        {
            targets.clear();
            return;
        }
        targets.remove_if([&](WorldObject* object)
        {
            Unit* unit = object->ToUnit();
            if (Creature* creature = object->ToCreature())
                if (creature->GetEntry() == NPC_GREEN_FLOWER || creature->GetEntry() == NPC_RED_FLOWER)
                    return true;
            return !unit || unit == flower || !unit->IsAlive() || !unit->IsInWorld() ||
                unit->GetMap() != flower->GetMap() || !flower->InSamePhase(unit) ||
                !owner->IsValidAssistTarget(unit) || !owner->IsInRaidWith(unit) || !flower->IsWithinLOSInMap(unit);
        });
        targets.sort([&](WorldObject const* left, WorldObject const* right)
        {
            float leftDistance = flower->GetExactDist(left);
            float rightDistance = flower->GetExactDist(right);
            return leftDistance == rightDistance ? left->GetGUID() < right->GetGUID() : leftDistance < rightDistance;
        });
        if (targets.size() > 1)
            targets.resize(1);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_ranger_flower_pickup::SelectAlly,
            EFFECT_0, TARGET_UNIT_SRC_AREA_ALLY);
    }
};

class aura_ascension_ranger_dream_flowers : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_dream_flowers);

    bool CheckProc(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        return owner->IsPlayer() && owner->getClass() == CLASS_RANGER && owner->IsAlive() && owner->IsInWorld() &&
            event.GetActor() == owner && victim && victim != owner && !owner->IsFriendlyTo(victim) &&
            (event.GetHitMask() & PROC_HIT_CRITICAL) && event.GetDamageInfo() && event.GetDamageInfo()->GetDamage();
    }

    void Spawn(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), SPELL_GREEN_FLOWER, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_ranger_dream_flowers::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_ranger_dream_flowers::Spawn,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_ranger_highlander : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_highlander);
    bool empowered = false;

    bool Load() override { return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_RANGER; }

    void Snapshot()
    {
        empowered = GetCaster()->HasAura(SPELL_HIGHLANDER) &&
            GetCaster()->HasAura(SPELL_HIGHLANDER_READY, GetCaster()->GetGUID());
    }

    void Consume()
    {
        if (empowered)
            GetCaster()->RemoveAurasDueToSpell(SPELL_HIGHLANDER_READY, GetCaster()->GetGUID());
    }

    void Hit()
    {
        Unit* target = GetHitUnit();
        if (empowered && target && target->IsAlive() && GetCaster()->IsValidAttackTarget(target))
        {
            empowered = false;
            GetCaster()->CastSpell(target, SPELL_HIGHLANDER_REDUCTION, true);
        }
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_ranger_highlander::Snapshot);
        AfterCast += SpellCastFn(spell_ascension_ranger_highlander::Consume);
        OnHit += SpellHitFn(spell_ascension_ranger_highlander::Hit);
    }
};

class ranger_flower_casts : public AllSpellScript
{
public:
    ranger_flower_casts() : AllSpellScript("ranger_flower_casts", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_RANGER || info->SpellFamilyName != 27 || spell->IsTriggered() ||
            !player->IsInCombat() || !player->HasAura(SPELL_FOREST_HERALD))
            return;
        if ((info->SpellFamilyFlags[0] & 32768) || info->CasterAuraSpell == SPELL_ADVANTAGE)
            if (SpellInfo const* talent = sSpellMgr->GetSpellInfo(SPELL_FOREST_HERALD))
                if (roll_chance_i(talent->ProcChance))
                    player->CastSpell(player, SPELL_GREEN_FLOWER, true);
    }
};

class ranger_flower_metadata : public GlobalScript
{
public:
    ranger_flower_metadata() : GlobalScript("ranger_flower_metadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 27)
            return;
        if (info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SUMMON &&
            info->Effects[EFFECT_0].MiscValue == NPC_GREEN_FLOWER &&
            info->Effects[EFFECT_2].TriggerSpell == SPELL_HIGHLANDER_STACKS)
            info->Effects[EFFECT_2].Effect = 0;
        if (info->Id == SPELL_HIGHLANDER_REDUCTION)
            info->StackAmount = 1;
    }
};

class ranger_falcon_cooldown_metadata : public GlobalScript
{
public:
    ranger_falcon_cooldown_metadata() : GlobalScript("ranger_falcon_cooldown_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 27)
            return;
        SpellEffectInfo& effect = info->Effects[EFFECT_1];
        if (effect.Effect == SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN && effect.MiscValue == SPELL_FALCONS_CALL &&
            effect.MiscValueB == 0 && effect.BasePoints == -1 && effect.DieSides == 1 &&
            effect.RealPointsPerLevel == 0 && effect.TargetA.GetTarget() == TARGET_UNIT_CASTER)
            effect.Effect = 0;
    }
};

class ranger_highlander_cleanup : public PlayerScript
{
public:
    ranger_highlander_cleanup() : PlayerScript("ranger_highlander_cleanup", {PLAYERHOOK_ON_UPDATE}) { }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        if (player->getClass() == CLASS_RANGER && !player->HasAura(SPELL_HIGHLANDER))
            for (uint32 spell : {SPELL_HIGHLANDER_STACKS, SPELL_HIGHLANDER_READY})
                if (player->HasAura(spell, player->GetGUID()))
                    player->RemoveAurasDueToSpell(spell, player->GetGUID());
    }
};
}

void AddSC_AscensionRangerFlowers()
{
    RegisterCreatureAI(npc_ascension_ranger_flower);
    RegisterSpellScript(spell_ascension_ranger_green_flower);
    RegisterSpellScript(spell_ascension_ranger_flower_pickup);
    RegisterSpellScript(aura_ascension_ranger_dream_flowers);
    RegisterSpellScript(spell_ascension_ranger_highlander);
    new ranger_flower_casts();
    new ranger_flower_metadata();
    new ranger_falcon_cooldown_metadata();
    new ranger_highlander_cleanup();
}
