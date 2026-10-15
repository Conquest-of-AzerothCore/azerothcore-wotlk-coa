/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionNecromancer.h"
#include "Creature.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>

namespace
{
using namespace AscensionNecromancer;
bool Derived(SpellInfo const* info)
{
    if (!info)
        return false;
    switch (info->Id)
    {
    case 573242:
    case 801241:
    case 707575:
    case 561318:
    case 561095:
    case 570050:
    case 681463:
    case 707002:
    case 707284:
    case 505225:
        return true;
    default:
        return false;
    }
}
void LeechArmy(Player* player, uint32 damage, int32 percent)
{
    auto minions = Minions(player);
    uint32 amount = uint32(uint64(damage) * std::max(0, percent) / (100 * (minions.size() + 1)));
    Copy(player, player, 681463, amount);
    for (Creature* unit : minions)
        Copy(player, unit, 681463, amount);
}

class aura_ascension_necromancer_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_necromancer_event);
    bool Check(ProcEventInfo& event)
    {
        Player* player = Owner(GetTarget());
        if (!player || State(player).event || !event.GetActionTarget() || Derived(event.GetSpellInfo()))
            return false;
        if (GetTarget() != player && !IsMinion(player, GetTarget()))
            return false;
        return event.GetDamageInfo() && event.GetDamageInfo()->GetDamage();
    }
    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        Player* player = Owner(GetTarget());
        if (!player)
            return;
        State(player).event = true;
        Unit* actor = event.GetActor();
        Unit* target = event.GetActionTarget();
        SpellInfo const* info = event.GetSpellInfo();
        uint32 damage = event.GetDamageInfo()->GetDamage();
        bool critical = (event.GetHitMask() & PROC_HIT_CRITICAL) != 0;
        bool periodic = (event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC)) != 0 ||
                        (info && (info->Id == 800343 || info->Id == 500237 || info->Id == 803779));
        bool melee =
            (event.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK)) != 0;
        bool outgoing = actor == GetTarget();
        bool minion = outgoing && actor != player && IsMinion(player, actor);
        bool own = outgoing && actor == player;
        if (!outgoing && target == GetTarget() && target->HasAura(681529, player->GetGUID()) && actor &&
            (event.GetTypeMask() & (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_RANGED_AUTO_ATTACK |
                                    PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS | PROC_FLAG_TAKEN_SPELL_RANGED_DMG_CLASS)))
        {
            Cast(player, actor, 707669);
        }
        if ((minion || own) && target != player && player->IsValidAttackTarget(target))
        {
            if (AuraEffect const* ward = actor->GetAuraEffect(680388, EFFECT_0, player->GetGUID()))
                LeechArmy(player, damage, ward->GetAmount());
            if (minion && player->HealthBelowPct(50) && actor->HasAura(560607, player->GetGUID()))
                Copy(player, player, 561095, uint64(damage) * std::max(0, Amount(560607, 1)) / 100);
            if (actor->HasAura(800027, player->GetGUID()))
                Copy(actor, target, 570050, uint64(damage) * std::max(0, Amount(800027)) / 100);
            if (minion && melee && actor->HasAura(805290, player->GetGUID()))
                Cast(actor, player, 707000);
        }
        if (own)
        {
            if (info && (info->Id == 800343 || Lichfrost(info)) && player->HasAura(92121))
                Plague(player, target, Lichfrost(info) ? 2 : 1);
            if (info && info->Id == 800343)
            {
                if (player->HasAura(92123))
                    Cast(player, target, 803530);
                if (player->HasAura(500165))
                    Cast(player, player, 806588);
                if (player->HasAura(704723))
                    if (Aura* stacks = player->GetAura(706504))
                        stacks->ModStackAmount(-1);
            }
            if (periodic)
            {
                if (Chance(player, 300235))
                    BuffArmy(player, 301334, true);
                if (player->HasAura(573223))
                    Copy(player, target, 573242, uint64(damage) * 20 / 100);
                if (Chance(player, 561319) || Chance(player, 560730))
                    Cast(player, target, 560729);
                if (Chance(player, 806086))
                    Summon(player, 806087, target, target->GetPosition());
                if (Chance(player, 807700))
                    Summon(player, 302586, target, target->GetPosition());
                if (info && info->Id == 500237 && Chance(player, 561353))
                    Reduce(player, 533236, INT32_MAX);
                if (info && Named(info, 500968) && (Chance(player, 705747) || Chance(player, 707880)))
                    Summon(player, 525379, target, target->GetPosition());
                if (critical && player->HasAura(705752))
                    Cast(player, player, 706424);
            }
            else if (critical && player->HasAura(705752))
                Cast(player, player, 705753);
            if (critical && Chance(player, 806321))
                Plague(player, target);
            if (info && (info->SchoolMask & SPELL_SCHOOL_MASK_FROST))
            {
                if (Chance(player, 531135))
                    Cast(player, target, 706732);
                Spell const* cast = event.GetProcSpell();
                Aura const* dot = info ? target->GetAura(info->Id, player->GetGUID()) : nullptr;
                bool frozen = target->HasAuraState(AURA_STATE_FROZEN) || player->HasAura(801747) ||
                              (cast && cast->GetScriptValue(801747)) || (dot && dot->GetScriptValue(801747));
                if (frozen && Chance(player, 572023))
                    Cast(player, target, 801724);
                if (critical)
                {
                    if (player->HasAura(707562))
                        Cast(player, player, 712434);
                    if (player->HasAura(707588))
                        Cast(player, player, 707886);
                }
            }
            if (info && (info->SchoolMask & SPELL_SCHOOL_MASK_SHADOW) && player->HasAura(706948))
                Cast(player, target, 706949);
            if (info && (info->SchoolMask & SPELL_SCHOOL_MASK_MAGIC) && Chance(player, 705750))
                Cast(player, player, 705751);
            if (info && info->Id == 707592 && player->HasAura(705745))
                for (Unit* nearby : Nearby(target, 10.0f))
                    if (nearby != target && player->IsValidAttackTarget(nearby))
                        Copy(player, nearby, 707575, uint64(damage) * std::max(0, Amount(705745)) / 100);
        }
        if (minion)
        {
            uint8 cost = 1;
            for (auto const& row : State(player).minions)
                if (row.guid == actor->GetGUID())
                    cost = std::max<uint8>(1, row.cost);
            if (Chance(player, 531128, cost))
                Cast(player, player, 531129);
            if (actor->HasAura(560798, player->GetGUID()))
                Reduce(player, 801938, std::abs(Amount(806322)));
            if (actor->GetEntry() == 50073 && Chance(player, 503740))
                Cast(player, actor, 707014);
            if (melee && actor->GetEntry() == 50078 && roll_chance_i(sSpellMgr->GetSpellInfo(805023)->ProcChance))
                Cast(actor, target, 805024);
            if (melee && actor->GetEntry() == 503200 && actor->HasAura(531133))
                Cast(actor, target, 531132);
            if (critical && Chance(player, 537208, 1, 1000))
                Reduce(player, 805029, std::abs(Amount(680553)));
            if (critical && melee && Chance(player, 638403))
                Copy(actor, target, 801241, uint64(damage) * std::max(0, Amount(638403, 1)) / 100);
            if (critical && (actor->GetEntry() == 50068 || actor->GetEntry() == 50115) && player->HasAura(707283))
                Cast(actor, target, 707284);
            if (Chance(player, player->HasAura(707882) ? 707882 : 707001))
            {
                uint32 count = 0;
                uint32 cap = std::max(1, Amount(player->HasAura(707882) ? 707882 : 707001));
                for (Unit* nearby : Nearby(target, 8.0f))
                    if (player->IsValidAttackTarget(nearby))
                    {
                        Cast(actor, nearby, 707002);
                        if (++count >= cap)
                            break;
                    }
            }
            if (Chance(player, 802986))
            {
                Cast(player, actor, 807653);
                Cast(actor, actor, 504022);
            }
            if (target->HasAura(560729, player->GetGUID()) && player->HasAura(561319))
                Copy(actor, target, 561318, uint64(damage) * std::max(0, Amount(561319)) / 100);
            if (player->HasAura(704721) &&
                (!info || (info->SchoolMask & (SPELL_SCHOOL_MASK_NORMAL | SPELL_SCHOOL_MASK_FROST))) &&
                !State(player).cooldowns.HasTimeUntilEvent(704721))
            {
                State(player).cooldowns.ScheduleEvent(704721, 1s);
                Reduce(player, 805029, std::abs(Amount(302597)) + 1000 * Count(player, {50068, 50115}));
            }
            if (Aura* diabolical = target->GetAura(707133, player->GetGUID()))
            {
                Copy(actor, target, 570050, uint64(damage) * std::max(0, Amount(707133)) / 100);
                diabolical->ModStackAmount(-1);
            }
        }
        State(player).event = false;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_necromancer_event::Check);
        OnProc += AuraProcFn(aura_ascension_necromancer_event::Proc);
    }
};

class aura_ascension_necromancer_ghoul_mastery : public AuraScript
{
    PrepareAuraScript(aura_ascension_necromancer_ghoul_mastery);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({707014});
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* ghoul = GetTarget();
        Player* player = Owner(ghoul);
        Unit* target = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return player && GetCaster() == player && ghoul->IsCreature() && ghoul->GetEntry() == 50073 &&
            IsMinion(player, ghoul) && event.GetActor() == ghoul && target &&
            player->IsValidAttackTarget(target) && damage && damage->GetDamage();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_necromancer_ghoul_mastery::Check);
    }
};

class necromancer_defense : public UnitScript
{
  public:
    necromancer_defense() : UnitScript("necromancer_defense", true, {UNITHOOK_ON_DAMAGE, UNITHOOK_CAN_UNIT_ATTACK}) {}
    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        Player* player = Owner(victim);
        if (!player || victim != player)
            return;
        if (player->HasAura(300580))
            damage -= CalculatePct(damage, std::min(10u, Count(player)));
        if (player->HasAura(560595) && player->HasAura(500983))
            damage -= CalculatePct(damage, 10);
        if (player->HasAura(500730))
        {
            damage = 0;
            return;
        }
        auto& state = State(player);
        if (attacker != player && state.phylactery && !state.shade &&
            int64(player->GetHealth()) - damage < player->CountPctFromMaxHealth(10))
            if (Creature* phylactery = ObjectAccessor::GetCreature(*player, state.phylactery))
                if (phylactery->IsAlive() && player->IsInMap(phylactery) && player->InSamePhase(phylactery))
                {
                    state.shade = true;
                    damage = std::min(damage, player->GetHealth() - 1);
                    Cast(player, player, 500730);
                    Cast(player, player, 500729);
                }
    }
    bool CanUnitAttack(Unit const* attacker, Unit const*, SpellInfo const*) override
    {
        Player* player = Owner(attacker);
        if (!player)
            return true;
        return attacker == player ? !player->HasAura(500730) : !IsMinion(player, attacker) || !player->HasAura(500983);
    }
};
}
void AddAscensionNecromancerEventScripts()
{
    RegisterSpellScript(aura_ascension_necromancer_event);
    RegisterSpellScript(aura_ascension_necromancer_ghoul_mastery);
    new necromancer_defense();
}
