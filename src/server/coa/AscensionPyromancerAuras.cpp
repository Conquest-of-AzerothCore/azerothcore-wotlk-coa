/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionPyromancer.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
namespace
{
using namespace AscensionPyromancer;
bool First(AuraEffect const* effect)
{
    for (uint8 i = 0; i < effect->GetEffIndex(); ++i)
        if (effect->GetBase()->HasEffect(i))
            return false;
    return true;
}
class aura_ascension_pyromancer_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_pyromancer_lifecycle);
    void Apply(AuraEffect const* effect, AuraEffectHandleModes mode)
    {
        if (!First(effect))
            return;
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        GetAura()->SetScriptValue(802168, ++State(player).sequence);
        if (Any(GetSpellInfo(), {800791, 805500, 706874}))
            GetAura()->SetScriptValue(704856, 0);
        if (Any(GetSpellInfo(), {800791, 706874}) && (mode & AURA_EFFECT_HANDLE_REAPPLY) && GetEffect(EFFECT_1))
            GetEffect(EFFECT_1)->SetAmount(0);
        if (id == 680842 && player->HasAura(503806))
        {
            Cast(player, GetTarget(), 503807);
            if (Aura* aura = GetTarget()->GetAura(503807, player->GetGUID()))
                aura->SetDuration(GetDuration());
        }
        if (Named(GetSpellInfo(), 805500))
            if (AuraEffect* periodic = GetEffect(EFFECT_0))
                if (GetEffect(EFFECT_1) && GetEffect(EFFECT_1)->GetAmount() > 0)
                    periodic->SetCritChance(100);
        if (GetTarget() != player)
            return;
        if (id == 524707 && (mode & AURA_EFFECT_HANDLE_REAPPLY))
            GetAura()->SetCharges(3);
        if (id == 680369)
            GetAura()->SetScriptValue(id, State(player).ignis);
        if (id == 807146)
            Cast(player, player, 807147);
        if (id == 92128 || id == 520937)
            Refresh(player);
        for (auto const& family :
             {std::vector<uint32>{504707, 504720, 680387, 681314},
              std::vector<uint32>{1119751, 1119754, 1119755, 1119756, 1119757, 1119758, 1119901, 1119944, 1119953}})
            if (std::find(family.begin(), family.end(), id) != family.end())
                for (uint32 other : family)
                    if (other != id)
                        player->RemoveAurasDueToSpell(other);
    }
    void Calculate(AuraEffect const* effect, int32& amount, bool& recalculate)
    {
        Player* player = Owner(GetCaster());
        if (player && GetId() == FlamecastingAura && effect->GetEffIndex() == EFFECT_0 && player->HasAura(706859))
            amount = Amount(706859);
        if (player && Named(GetSpellInfo(), 805500) && effect->GetEffIndex() != EFFECT_0)
        {
            amount = player->HasAura(520927) ? (effect->GetEffIndex() == EFFECT_1 ? 100 : Amount(520927, 1)) : 0;
            recalculate = false;
        }
        if (player && Any(GetSpellInfo(), {800791, 706874}) && effect->GetEffIndex() == EFFECT_1)
        {
            amount = 0;
            recalculate = false;
        }
        if (player && Any(GetSpellInfo(), {680962, 807403, 520826}) && effect->GetEffIndex() != EFFECT_0)
        {
            amount = 0;
            recalculate = false;
        }
    }
    void HealArea(Player* player, uint32 id)
    {
        SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
        uint32 count = info->MaxAffectedTargets;
        float radius = info->Effects[0].CalcRadius(player);
        for (Unit* ally : Allies(player, GetTarget(), radius > 0 ? radius : 10, count))
            Cast(player, ally, id);
    }
    void Remove(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        bool expired = GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE;
        if (id == 680842)
            GetTarget()->RemoveAurasDueToSpell(503807, player->GetGUID());
        if (id == 807944 && expired && !player->HasAura(706860))
            HealArea(player, 806742);
        if (GetTarget() != player)
            return;
        if (id == 807146)
            player->RemoveAurasDueToSpell(807147);
        if (id == 92128 || id == 520937)
            Refresh(player);
        if (id == 573220 && expired && player->IsAlive())
            Cast(player, player, 573231);
        if (id == 680369)
        {
            if (expired && player->IsAlive())
            {
                State(player).ignis = uint32(std::min<uint64>(10, GetAura()->GetScriptValue(id)));
                Cast(player, player, 680370);
                Cast(player, player, 680371);
            }
            State(player).ignis = 0;
        }
        if (id == FlamecastingAura && expired && player->HasAura(800811) && player->IsAlive())
        {
            uint32 count = sSpellMgr->GetSpellInfo(680973)->MaxAffectedTargets;
            for (Unit* enemy : Nearby(player, 40))
                if (count && player->IsValidAttackTarget(enemy) && Burning(player, enemy))
                {
                    Cast(player, enemy, Highest(player, 800790));
                    --count;
                }
        }
    }
    void Tick(AuraEffect const* effect)
    {
        Player* player = Owner(GetCaster());
        if (!player || !player->IsAlive())
            return;
        uint32 id = GetId();
        if (id == 802120)
        {
            Unit* target = GetTarget();
            uint32 percent = 4 * (target == player ? 2 : 1);
            target->EnergizeBySpell(target, id, CalculatePct(target->GetMaxPower(POWER_MANA), percent), POWER_MANA);
        }
        if (id == 807944)
        {
            if (effect->GetEffIndex() == EFFECT_1)
                HealArea(player, 806743);
            else if (player->HasAura(706860))
                HealArea(player, 806742);
        }
        if ((id == 680962 || id == 807403 || id == 520826) && !effect->GetEffIndex())
        {
            uint32 total = GetEffect(EFFECT_1) ? std::max(0, GetEffect(EFFECT_1)->GetAmount()) : 0;
            uint32 ticks = GetEffect(EFFECT_2) ? std::max(0, GetEffect(EFFECT_2)->GetAmount()) : 0;
            if (ticks)
            {
                uint32 amount = total / ticks;
                const_cast<AuraEffect*>(effect)->SetAmount(amount);
                GetEffect(EFFECT_1)->SetAmount(total - amount);
                GetEffect(EFFECT_2)->SetAmount(ticks - 1);
                GetAura()->SetScriptValue(id, total - amount);
                GetAura()->SetScriptValue(id + 1, ticks - 1);
            }
        }
    }
    void Dispel(DispelInfo* dispel)
    {
        if (Player* player = Owner(GetCaster()); player && dispel->GetDispeller())
            Cast(player, dispel->GetDispeller(), 803455);
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_pyromancer_lifecycle::Apply, EFFECT_ALL, SPELL_AURA_ANY,
                                              AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_pyromancer_lifecycle::Remove, EFFECT_ALL, SPELL_AURA_ANY,
                                                AURA_EFFECT_HANDLE_REAL);
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_pyromancer_lifecycle::Calculate, EFFECT_ALL, SPELL_AURA_ANY);
        SpellInfo const* info = sSpellMgr->GetSpellInfo(m_scriptSpellId);
        if (info)
        {
            bool periodic = false;
            for (auto const& effect : info->Effects)
                periodic |= effect.IsAura() && effect.Amplitude;
            if (periodic)
                OnEffectPeriodic +=
                    AuraEffectPeriodicFn(aura_ascension_pyromancer_lifecycle::Tick, EFFECT_ALL, SPELL_AURA_ANY);
            if (Named(info, 800791))
                AfterDispel += AuraDispelFn(aura_ascension_pyromancer_lifecycle::Dispel);
        }
    }
};
class aura_ascension_pyromancer_phoenix : public AuraScript
{
    PrepareAuraScript(aura_ascension_pyromancer_phoenix);
    void Calculate(AuraEffect const*, int32& amount, bool& recalculate)
    {
        amount = -1;
        recalculate = false;
    }
    void Absorb(AuraEffect*, DamageInfo& damage, uint32& absorb)
    {
        absorb = 0;
        Player* player = Owner(GetTarget());
        if (!player || player->HasAura(573230) || damage.GetDamage() < player->GetHealth())
            return;
        absorb = damage.GetDamage() - player->GetHealth() + 1;
        Cast(player, player, 573230);
        Cast(player, player, 573220);
    }
    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_pyromancer_phoenix::Calculate, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_pyromancer_phoenix::Absorb, EFFECT_0);
    }
};
}
class aura_ascension_pyromancer_draconic_form : public AuraScript
{
    PrepareAuraScript(aura_ascension_pyromancer_draconic_form);
    static uint32 constexpr DraconicDisplay = 142067;
    bool Validate(SpellInfo const* info) override { return info->Id == 802117; }
    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = Owner(GetTarget()))
            player->SetDisplayId(DraconicDisplay);
    }
    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = Owner(GetTarget()))
            player->RestoreDisplayId();
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_pyromancer_draconic_form::Apply, EFFECT_ALL,
                                              SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_pyromancer_draconic_form::Remove, EFFECT_ALL,
                                                SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};
void AddSC_AscensionPyromancerAuras()
{
    RegisterSpellScript(aura_ascension_pyromancer_lifecycle);
    RegisterSpellScript(aura_ascension_pyromancer_phoenix);
    RegisterSpellScript(aura_ascension_pyromancer_draconic_form);
}
