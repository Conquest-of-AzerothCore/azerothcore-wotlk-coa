/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionSunCleric.h"
#include "AscensionSunClericData.h"
#include "DynamicObject.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <vector>
namespace
{
using namespace AscensionSunCleric;
enum SunwellSpells : uint32
{
    SPELL_SUNWELL = 560123,
    SPELL_SUNWELL_VISUAL = 560124
};
bool First(AuraEffect const* effect)
{
    for (uint8 slot = 0; slot < effect->GetEffIndex(); ++slot)
        if (effect->GetBase()->HasEffect(slot))
            return false;
    return true;
}
class aura_ascension_sun_cleric_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_sun_cleric_lifecycle);
    bool depleted = false;
    bool Validate(SpellInfo const* info) override
    {
        return info->Id != SPELL_SUNWELL || ValidateSpellInfo({SPELL_SUNWELL_VISUAL});
    }
    void Apply(AuraEffect const* effect, AuraEffectHandleModes mode)
    {
        Player* player = Owner(GetCaster());
        if (!player || !First(effect))
            return;
        uint32 id = GetId();
        Unit* target = GetTarget();
        GetAura()->SetScriptValue(SolarPower, ++State(player).sequence);
        if (id == SPELL_SUNWELL)
        {
            if (Aura* visual = GetCaster()->AddAura(SPELL_SUNWELL_VISUAL, target))
            {
                visual->SetMaxDuration(GetAura()->GetMaxDuration());
                visual->SetDuration(GetDuration());
            }
        }
        for (auto list : {std::pair(SunClericVows,std::size(SunClericVows)),
                         std::pair(SunClericDevotions,std::size(SunClericDevotions))})
            if (std::find(list.first,list.first+list.second,id) != list.first+list.second)
                for (size_t i = 0; i < list.second; ++i)
                    if (list.first[i] != id)
                        target->RemoveAurasDueToSpell(list.first[i],player->GetGUID());
        if (id == Bless && target != player)
        {
            ObjectGuid previous = State(player).blessed;
            if (!previous.IsEmpty() && previous != target->GetGUID())
                if (Unit* ally = ObjectAccessor::GetUnit(*player,previous))
                    ally->RemoveAurasDueToSpell(Bless,player->GetGUID());
            State(player).blessed = target->GetGUID();
            Cast(player,player,Bless);
        }
        if (id == 520647)
        {
            if (player->GetHealthPct() >= 10)
                Cast(player,target,560347);
        }
        if (id == 561328 || id == 704585 || id == 805267 || id == 300314)
            Refresh(player);
        if (id == 560095)
        {
            if (mode & AURA_EFFECT_HANDLE_REAPPLY)
            {
                int32 blocks = 5;
                if (AuraEffect const* talent = player->GetAuraEffectOfRankedSpell(680647,EFFECT_0))
                    blocks += talent->GetAmount();
                GetAura()->SetCharges(uint8(std::clamp(blocks,1,255)));
            }
            GetAura()->SetUsingCharges(false);
        }
        if (id == 680888)
            GetAura()->SetUsingCharges(false);
        if ((id == Dawn || id == 301265 || id == 301242) && (mode & AURA_EFFECT_HANDLE_REAPPLY))
            GetAura()->SetCharges(id == Dawn ? 10 : id == 301265 ? 3 : 2);
        if (id == Dawn || id == 301265 || id == 301242)
            GetAura()->SetUsingCharges(false);
        if (id == 301266)
        {
            if (player->HasAura(Sunrise))
                Reduce(player,500154,INT32_MAX);
            if (player->HasAura(Sunset))
                Reduce(player,806477,INT32_MAX);
        }
        if (id == 803238)
            Refresh(player);
    }
    void Calculate(AuraEffect const* effect, int32& amount, bool& recalculate)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        uint8 slot = effect->GetEffIndex();
        if (id == Dawn && slot == 0)
        {
            amount = 1;
            recalculate = false;
        }
        if ((id == 680624 && slot == 0) || id == 301005 || id == 505340)
            recalculate = false;
        if (id == 561023 && slot == 2)
            amount = int32(player->GetItemArmorBySubclass(ITEM_SUBCLASS_ARMOR_SHIELD));
        if (id == 680639 && slot == 1)
            amount = int32(5 * player->GetStat(STAT_INTELLECT));
    }
    void Period(AuraEffect const* effect, bool& periodic, int32& amplitude)
    {
        Player* player = Owner(GetCaster());
        if (player && effect->GetEffIndex() == 0 && Named(GetSpellInfo(),300351) && player->HasAura(800602))
        {
            periodic = true;
            amplitude = std::max(1000, amplitude - std::abs(Amount(800602,1)));
        }
    }
    void Remove(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        if (GetId() == SPELL_SUNWELL)
            GetTarget()->RemoveAurasDueToSpell(SPELL_SUNWELL_VISUAL, GetCasterGUID());
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        Unit* target = GetTarget();
        AuraRemoveMode mode = GetTargetApplication()->GetRemoveMode();
        if (id == Bless && State(player).blessed == target->GetGUID())
            State(player).blessed.Clear();
        if (id == 520647)
            target->RemoveAurasDueToSpell(560347,player->GetGUID());
        if (id == 803238)
            Refresh(player);
        if (!player->IsAlive() || !player->IsInWorld())
            return;
        if (id == Dawn && target == player && (mode == AURA_REMOVE_BY_CANCEL || mode == AURA_REMOVE_BY_EXPIRE))
            Resource(player, SolarPower, GetAura()->GetCharges());
        bool old = State(player).event;
        State(player).event = true;
        if (id == 802598 && depleted && player->HasAura(680637))
            Cast(player,player,570187);
        if (id == 680624 && mode == AURA_REMOVE_BY_EXPIRE)
        {
            uint32 amount = std::max(0,GetEffect(EFFECT_0)->GetAmount()) / 4;
            auto enemies = Nearby(target,Radius(570147));
            if (std::find(enemies.begin(),enemies.end(),target) == enemies.end())
                enemies.push_front(target);
            for (Unit* enemy : enemies)
                if (player->IsValidAttackTarget(enemy))
                    Copy(player,enemy,570147,amount);
        }
        if (id == 572752 && mode == AURA_REMOVE_BY_EXPIRE && target->IsAlive())
        {
            Cast(player,target,572753);
            player->CastSpell(target->GetPositionX(),target->GetPositionY(),target->GetPositionZ(),572754,true);
        }
        if (id == 704930 && mode == AURA_REMOVE_BY_EXPIRE)
            Cast(player,player,704931);
        if (id == 570125 && player->HasAura(804628))
            if (Aura* charge = target->GetAura(807080,player->GetGUID()))
                ReleaseSuncharge(player,target,charge->GetStackAmount());
        if (id == 807080 && mode == AURA_REMOVE_BY_EXPIRE && GetAura()->GetStackAmount())
            ReleaseSuncharge(player,target,GetAura()->GetStackAmount());
        State(player).event = old;
    }
    void Tick(AuraEffect const* effect)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        uint8 slot = effect->GetEffIndex();
        Unit* target = GetTarget();
        if (id == RejuvenatingRays && !slot)
        {
            PreventDefaultAction();
            if (target->IsAlive() && !target->IsInCombat())
                player->CastSpell(target, Rejuvenating,
                    TriggerCastFlags(TRIGGERED_FULL_MASK | TRIGGERED_NO_PERIODIC_RESET));
        }
        if (id == 803719 && !slot)
        {
            PreventDefaultAction();
            Resource(player,SolarPower,2);
        }
        if (id == Bless && !slot)
        {
            PreventDefaultAction();
            uint32 percent = std::max(0,effect->GetAmount());
            Copy(player,target,707522,CalculatePct(target->GetMaxHealth(),percent));
            if (target == player)
            {
                int32 mana = Amount(805360,1);
                if (player->HasAura(300357))
                    mana *= 2;
                Mana(player,CalculatePct(player->GetMaxPower(POWER_MANA),mana));
            }
        }
        if (id == 300361)
        {
            PreventDefaultAction();
            if (player->HasAura(Sunrise))
                ReducePercent(player,500154,std::abs(Amount(301176,1)));
            if (player->HasAura(Sunset))
                ReducePercent(player,806477,std::abs(Amount(301176,1)));
        }
        if (id == 572752 || id == 704930 || id == 807080)
            PreventDefaultAction();
        if (id == 570125 && slot == 2)
        {
            PreventDefaultAction();
            if (player->HasAura(804628))
                Cast(player,target,807080);
        }
        if (id == 520647 && !slot)
        {
            PreventDefaultAction();
            if (!player->IsAlive() || player->GetHealthPct() < 10)
            {
                if (DynamicObject* zone = player->GetDynObject(520647))
                    zone->Remove();
                return;
            }
            Cast(player,target,520648);
            if (!target->HasAura(560347,player->GetGUID()))
                Cast(player,target,560347);
        }
    }
    void Absorb(AuraEffect* effect, DamageInfo&, uint32& amount)
    {
        if (GetId() == 802598)
            depleted = effect->GetAmount() > 0 && amount >= uint32(effect->GetAmount());
    }
    void Split(AuraEffect*, DamageInfo&, uint32& amount)
    {
        Player* player = Owner(GetCaster());
        if (!player || !player->IsAlive() || player->GetHealthPct() < 10 ||
            !GetTarget()->HasAura(520647,player->GetGUID()))
        {
            amount = 0;
            GetAura()->Remove();
        }
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_sun_cleric_lifecycle::Apply,EFFECT_ALL,SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_sun_cleric_lifecycle::Remove,EFFECT_ALL,SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_sun_cleric_lifecycle::Calculate,EFFECT_ALL,SPELL_AURA_ANY);
        auto* info = sSpellMgr->GetSpellInfo(m_scriptSpellId);
        if (!info)
            return;
        bool periodic = false;
        for (uint8 slot=0;slot<MAX_SPELL_EFFECTS;++slot)
        {
            periodic |= info->Effects[slot].IsAura() && info->Effects[slot].Amplitude;
            if (info->Effects[slot].IsAura(SPELL_AURA_SCHOOL_ABSORB))
                AfterEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_sun_cleric_lifecycle::Absorb,SpellEffIndex(slot));
            if (info->Effects[slot].IsAura(SPELL_AURA_SPLIT_DAMAGE_PCT))
                OnEffectSplit += AuraEffectSplitFn(aura_ascension_sun_cleric_lifecycle::Split,SpellEffIndex(slot));
        }
        if (periodic)
        {
            OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_sun_cleric_lifecycle::Tick,EFFECT_ALL,SPELL_AURA_ANY);
            DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_ascension_sun_cleric_lifecycle::Period,EFFECT_ALL,SPELL_AURA_ANY);
        }
    }
};

class aura_ascension_rejuvenating_rays : public AuraScript
{
    PrepareAuraScript(aura_ascension_rejuvenating_rays);
    uint32 _seconds = 0;

    void Tick(AuraEffect const* effect)
    {
        Unit* target = GetTarget();
        if (target->IsInCombat() || !target->HasAura(RejuvenatingRays, GetCasterGUID()))
        {
            PreventDefaultAction();
            GetAura()->Remove();
            return;
        }

        if (effect->GetEffIndex() != EFFECT_0 || ++_seconds < 10)
            return;

        std::vector<std::pair<uint32, ObjectGuid>> diseases;
        for (auto const& entry : target->GetAppliedAuras())
            if (!entry.second->IsPositive() && entry.second->GetBase()->GetSpellInfo()->Dispel == DISPEL_DISEASE)
                diseases.emplace_back(entry.first, entry.second->GetBase()->GetCasterGUID());
        for (auto const& disease : diseases)
            if (Aura* aura = target->GetAura(disease.first, disease.second))
                target->RemoveAurasDueToSpellByDispel(disease.first, RejuvenatingRays, disease.second, target,
                    aura->IsUsingCharges() ? aura->GetCharges() : aura->GetStackAmount());
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_rejuvenating_rays::Tick,
            EFFECT_0, SPELL_AURA_OBS_MOD_HEALTH);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_rejuvenating_rays::Tick,
            EFFECT_1, SPELL_AURA_OBS_MOD_POWER);
    }
};
}
void AddSC_AscensionSunClericAuras()
{
    RegisterSpellScript(aura_ascension_sun_cleric_lifecycle);
    RegisterSpellScript(aura_ascension_rejuvenating_rays);
}
