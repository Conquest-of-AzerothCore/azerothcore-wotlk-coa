/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionStarcaller.h"
#include "GameTime.h"
#include "MotionMaster.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
namespace
{
using namespace AscensionStarcaller;
bool First(AuraEffect const* effect)
{
    for (uint8 i = 0; i < effect->GetEffIndex(); ++i)
        if (effect->GetBase()->HasEffect(i))
            return false;
    return true;
}
class aura_ascension_starcaller_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_starcaller_lifecycle);
    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        GetAura()->SetScriptValue(800386, ++State(player).sequence);
        if (id == 805546)
        {
            Cast(player, GetTarget(), 805547);
            if (Aura* aura = GetTarget()->GetAura(805547, player->GetGUID()))
                aura->SetDuration(GetDuration());
        }
        if (id == 680705)
            GetAura()->SetScriptValue(680705, 0);
        if (id == 560634)
            if (Player* ally = GetTarget()->ToPlayer())
                for (Powers power : {POWER_MANA, POWER_RAGE, POWER_ENERGY, POWER_FOCUS, POWER_RUNIC_POWER})
                    ally->UpdateMaxPower(power);
        if (GetTarget() != player)
            return;
        if (id == 500206)
            Cast(player, player, 800393);
        if (id == 800393)
            Cast(player, player, 800391);
        if (id == 704772)
        {
            player->RemoveAurasByType(SPELL_AURA_MOD_DECREASE_SPEED);
            player->Mount(9991);
        }
        if (Named(GetSpellInfo(), 800505))
        {
            player->RemoveAurasByType(SPELL_AURA_MOD_DECREASE_SPEED);
            player->ApplySpellImmune(id, IMMUNITY_MECHANIC, MECHANIC_SNARE, true);
            State(player).chargeX = player->GetPositionX();
            State(player).chargeY = player->GetPositionY();
            State(player).chargeAura = id;
            State(player).chargeReady = false;
            State(player).chargeDistance = 0;
        }
        if (id == 802681)
            Replace(player, 800496, 801125);
        if (id == 572319)
            Replace(player, 801978, 802682);
        if (id == 803573)
            Replace(player, 801978, 801975);
        if (id == 704171)
            GetAura()->SetScriptValue(704171, 5);
        if (id == 805439 && player->HasAura(680772))
            if (AuraEffect* speed = GetEffect(EFFECT_1))
                speed->ChangeAmount(30);
    }
    void Pull(Player* player)
    {
        if (GetAura()->GetScriptValue(680705) || !GetTarget()->IsAlive() || !player->IsAlive() ||
            !player->IsInMap(GetTarget()))
            return;
        GetAura()->SetScriptValue(680705, 1);
        Position destination = player->GetNearPosition(2, 0);
        if (!GetTarget()->IsImmunedToDamage(player, GetSpellInfo()) && !GetTarget()->HasUnitState(UNIT_STATE_ROOT) &&
            !GetTarget()->IsImmuneToForcedMovement())
            GetTarget()->GetMotionMaster()->MoveJump(destination.GetPositionX(), destination.GetPositionY(),
                                                     destination.GetPositionZ(), 15, 8);
        Cast(player, GetTarget(), 680707);
    }
    void Remove(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        if (id == 805546)
            GetTarget()->RemoveAurasDueToSpell(805547, player->GetGUID());
        if (id == 560634)
            if (Player* ally = GetTarget()->ToPlayer())
                for (Powers power : {POWER_MANA, POWER_RAGE, POWER_ENERGY, POWER_FOCUS, POWER_RUNIC_POWER})
                    ally->UpdateMaxPower(power);
        if (id == 680705 && GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE)
            Pull(player);
        if (GetTarget() != player)
            return;
        if (id == 500206)
            player->RemoveAurasDueToSpell(800393), player->RemoveAurasDueToSpell(800394);
        if (id == 800393)
            player->RemoveAurasDueToSpell(800391);
        if (id == 680822)
            player->RemoveAurasDueToSpell(680847);
        if (id == 704772 && player->GetMountID() == 9991)
            player->Dismount();
        if (Named(GetSpellInfo(), 800505))
        {
            player->ApplySpellImmune(id, IMMUNITY_MECHANIC, MECHANIC_SNARE, false);
            if (State(player).chargeAura == id)
                FinishCharge(player);
        }
        if (id == 802681)
            Replace(player, 800496, 0);
        if (id == 572319 || id == 803573)
            Replace(player, 801978, player->HasAura(803573) ? 801975 : player->HasAura(572319) ? 802682 : 0);
        if (id == 300256)
            player->RemoveAurasDueToSpell(301328);
        if (id == 954791)
            PayDelayedDamage(player);
        if (id == 704171)
            player->RemoveAurasDueToSpell(805436);
    }
    void Tick(AuraEffect const* effect)
    {
        Player* player = Owner(GetCaster());
        if (!player || !player->IsAlive())
            return;
        uint32 id = GetId();
        if (id == 524781)
            GainPhase(player);
        if (id == 804716)
            if (!Consume(player, GetTarget()))
                GetAura()->Remove();
        if (id == 500206)
        {
            bool full = player->HasAura(800393);
            player->RemoveAurasDueToSpell(full ? 800393 : 800394);
            Cast(player, player, full ? 800394 : 800393);
        }
        if (id == 680705 && player->GetDistance(GetTarget()) >= 10)
            Pull(player), GetAura()->Remove();
        if (id == 300256)
        {
            uint32 hour = (uint64(GameTime::GetGameTime().count()) / 3600 + 3) % 24;
            bool night = hour < 6 || hour >= 18;
            if (night && !player->HasAura(301328))
                Cast(player, player, 301328);
            if (!night)
                player->RemoveAurasDueToSpell(301328);
        }
        if (id == 954791)
        {
            PayDelayedDamage(player, std::max(1, (GetDuration() + 999) / 1000));
        }
        if (id == 680213)
        {
            Cast(player, GetTarget(), 680214);
            if (++_ticks == 2)
                GetAura()->Remove();
        }
        if (id == 807992)
        {
            uint32 remaining = 5;
            for (Unit* ally : Nearby(GetTarget(), 10))
                if (player->IsValidAssistTarget(ally) && (ally == player || player->IsInRaidWith(ally)))
                {
                    uint32 amount = player->SpellHealingBonusDone(ally, GetSpellInfo(),
                                                                  std::max(0, effect->GetAmount()), DOT, EFFECT_0);
                    amount = ally->SpellHealingBonusTaken(player, GetSpellInfo(), amount, DOT);
                    HealInfo heal(player, ally, amount, GetSpellInfo(), SPELL_SCHOOL_MASK_ARCANE);
                    player->HealBySpell(heal);
                    Unit::ProcSkillsAndAuras(player, ally, PROC_FLAG_DONE_PERIODIC, PROC_FLAG_TAKEN_PERIODIC,
                                             PROC_EX_NORMAL_HIT | PROC_EX_INTERNAL_HOT, amount, BASE_ATTACK,
                                             GetSpellInfo(), nullptr, EFFECT_0, nullptr, nullptr, &heal);
                    if (!--remaining)
                        break;
                }
        }
    }
    uint8 _ticks = 0;
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_starcaller_lifecycle::Apply, EFFECT_ALL, SPELL_AURA_ANY,
                                              AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_starcaller_lifecycle::Remove, EFFECT_ALL, SPELL_AURA_ANY,
                                                AURA_EFFECT_HANDLE_REAL);
        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(m_scriptSpellId);
            info && info->HasAura(SPELL_AURA_PERIODIC_DUMMY))
            OnEffectPeriodic +=
                AuraEffectPeriodicFn(aura_ascension_starcaller_lifecycle::Tick, EFFECT_ALL, SPELL_AURA_PERIODIC_DUMMY);
    }
};
class aura_ascension_starcaller_absorb : public AuraScript
{
    PrepareAuraScript(aura_ascension_starcaller_absorb);
    void Calculate(AuraEffect const*, int32& amount, bool& recalculate)
    {
        amount = -1;
        recalculate = false;
    }
    void Absorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        amount = 0;
        Player* player = Owner(GetTarget());
        if (!player || damage.GetAttacker() == player)
            return;
        uint32 id = GetId(), hit = damage.GetDamage();
        if (id == 680786)
            amount = std::min(hit, uint32(player->GetMaxPower(POWER_MANA) * .015f));
        if (id == 574351 && uint64(hit) * 5 > player->GetMaxHealth())
        {
            amount = uint64(hit) * 15 / 100;
            Mana(player, amount, 574365);
        }
        if (id == 704785 && damage.GetDamageType() != DOT && (damage.GetSchoolMask() & SPELL_SCHOOL_MASK_MAGIC))
        {
            amount = uint64(hit) * 30 / 100;
            if (!DelayDamage(player, amount))
                amount = 0;
        }
    }
    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_starcaller_absorb::Calculate, EFFECT_ALL, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_starcaller_absorb::Absorb, EFFECT_ALL);
    }
};
}
void AddSC_AscensionStarcallerAuras()
{
    RegisterSpellScript(aura_ascension_starcaller_lifecycle);
    RegisterSpellScript(aura_ascension_starcaller_absorb);
}
