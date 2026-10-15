/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionNecromancer.h"
#include "Creature.h"
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
enum StanceSpells
{
    SPELL_UNDEAD_ASSAULT = 500982,
    SPELL_UNDEAD_PACIFY = 500983,
    SPELL_UNDEAD_PROTECT = 500985
};

enum WardSpells
{
    SPELL_FETID_WARD = 680388,
    SPELL_GLACIAL_WARD = 681460,
    SPELL_BONE_WARD = 681529
};

class aura_ascension_necromancer_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_necromancer_lifecycle);
    int32 _cost = 0;
    bool _expired = false;
    bool First(AuraEffect const* effect) const
    {
        for (uint8 index = 0; index < effect->GetEffIndex(); ++index)
            if (GetEffect(index))
                return false;
        return true;
    }
    void Calculate(AuraEffect const* effect, int32& amount, bool&)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        uint8 index = uint8(effect->GetEffIndex());
        if ((id == 572638 || id == 706472) && index == 0)
        {
            float stamina = 0;
            for (Creature* unit : Minions(player, true))
                stamina += unit->GetStat(STAT_STAMINA);
            amount = int32(stamina * (id == 572638 ? 0.3f : 0.15f));
        }
        if (id == 531126 && index == 1)
            amount = int32(Count(player, {50076}) * 5);
        if (id == 560012 && index == 0)
            amount = Count(player, {50075}) ? Amount(523613, 1, player) : 0;
        if (id == SPELL_UNDEAD_ASSAULT && index == 2)
            amount = player->HasAura(560595) ? 5 : 0;
        if (id == SPELL_UNDEAD_PROTECT && index == 1)
            amount = player->HasAura(560595) ? -75 : 0;
        if (id == 301207 && index == 0)
            amount = int32(Count(player, {50068, 50115}) * 30);
    }
    void Periodic(AuraEffect const* effect, bool& periodic, int32& interval)
    {
        if ((GetId() == 804371 || GetId() == 525600) && First(effect))
        {
            periodic = true;
            interval = 2000;
        }
    }
    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        if (GetTarget() == player &&
            (id == SPELL_UNDEAD_ASSAULT || id == SPELL_UNDEAD_PACIFY || id == SPELL_UNDEAD_PROTECT))
        {
            State(player).stance = id;
            for (uint32 stance : {SPELL_UNDEAD_ASSAULT, SPELL_UNDEAD_PACIFY, SPELL_UNDEAD_PROTECT})
                if (stance != id)
                {
                    player->RemoveAurasDueToSpell(stance, player->GetGUID());
                    for (Creature* minion : Minions(player))
                        minion->RemoveAurasDueToSpell(stance, player->GetGUID());
                }
            if (id == SPELL_UNDEAD_PACIFY)
                State(player).focus.Clear();
        }
        if (!First(effect))
            return;
        if (GetTarget() != player && player->HasAura(801747))
            GetAura()->SetScriptValue(801747, 1);
        if (id == 807796)
            _expired = false;
        if (Named(GetSpellInfo(), 500217))
            _cost = GetSpellInfo()->CalcPowerCost(player, GetSpellInfo()->GetSchoolMask());
        if (GetTarget() != player)
            return;
        if (id == SPELL_FETID_WARD || id == SPELL_GLACIAL_WARD || id == SPELL_BONE_WARD)
        {
            for (uint32 ward : {SPELL_FETID_WARD, SPELL_GLACIAL_WARD, SPELL_BONE_WARD})
                if (ward != id)
                {
                    player->RemoveAurasDueToSpell(ward);
                    for (Creature* minion : Minions(player))
                        minion->RemoveAurasDueToSpell(ward, player->GetGUID());
                }
            for (Creature* minion : Minions(player))
                if (Aura* ward = player->AddAura(id, minion))
                    ward->SetDuration(GetDuration());
        }
        if (id == 500981 || id == 804371)
            Cast(player, player, 504747);
        if (id == 500981)
            Cast(player, player, 504691);
        if (id == 804371)
            player->ApplySpellImmune(id, IMMUNITY_DISPEL, DISPEL_DISEASE, true);
        for (uint32 charge : {800979, 801747, 707176, 807856, 572777})
            if (id == charge)
            {
                GetAura()->SetCharges(id == 801747 ? 2 : 1);
                GetAura()->SetScriptValue(805011, ++State(player).sequence);
            }
    }
    void Tick(AuraEffect const* effect)
    {
        Player* player = Owner(GetCaster());
        if (!player || !player->IsAlive())
            return;
        uint32 id = GetId();
        if (Named(GetSpellInfo(), 500338) && effect->GetEffIndex() == 0)
            Cast(player, player, 804272);
        if (Named(GetSpellInfo(), 562210))
        {
            PreventDefaultAction();
            if (effect->GetEffIndex() != 1 || GetTarget() != player)
                return;
            uint32 drained = 0;
            for (Creature* minion : Minions(player, true))
                if (player->IsWithinDistInMap(minion, 40.0f))
                {
                    uint32 take = std::min<uint32>(std::max(0, Amount(id, 1, player)), minion->GetPower(POWER_MANA));
                    minion->ModifyPower(POWER_MANA, -int32(take));
                    drained += take;
                }
            player->EnergizeBySpell(player, id, drained / 2, POWER_RUNIC_POWER);
        }
        if (Named(GetSpellInfo(), 500217) && effect->GetEffIndex() == 1)
            PreventDefaultAction();
        if (id == 561138 && effect->GetEffIndex() == 0)
        {
            PreventDefaultAction();
            Summon(player, 561316, player->GetVictim(), player->GetPosition());
            player->EnergizeBySpell(player, id, 300, POWER_RUNIC_POWER);
        }
        if (id == 704676 && player->HasAura(500981))
            for (uint32 champion : {805049, 807811, 807813})
                Reduce(player, champion, 5000);
        if (id == 301207 && effect->GetEffIndex() == 1)
        {
            PreventDefaultAction();
            player->ModifyHealth(player->CountPctFromMaxHealth(2) * Count(player, {50068, 50115}));
        }
        if (id == 807796 && effect->GetEffIndex() == 1 && !_expired)
        {
            PreventDefaultAction();
            _expired = true;
            if (GetTarget()->HealthBelowPct(20))
                Copy(player, GetTarget(), 808016, std::max(0, effect->GetAmount()));
        }
        if (id == 804371 && GetTarget() == player && First(effect))
        {
            Cast(player, player, 520891);
            for (Creature* minion : Minions(player))
                Cast(minion, minion, 520891);
        }
        if (id == 525600 && GetTarget() == player && First(effect))
        {
            bool eligible = Count(player, {50068}) == 1;
            for (Creature* minion : Minions(player))
                if (eligible && minion->HasAura(805290))
                    Cast(player, minion, 525388);
                else
                    minion->RemoveAurasDueToSpell(525388, player->GetGUID());
        }
    }
    void Removed(AuraEffect const* effect, AuraEffectHandleModes)
    {
        Player* player = Owner(GetCaster());
        if (!player || !First(effect))
            return;
        uint32 id = GetId();
        bool expired = GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE;
        if (Named(GetSpellInfo(), 500217) && expired)
        {
            Copy(player, GetTarget(), 500267, std::max(0, Amount(id, 1, player)));
            int32 percent = player->HasAura(302920) ? 50 : player->HasAura(302888) ? 25 : 0;
            int32 paid = GetAura()->GetScriptValue(500217) ? int32(GetAura()->GetScriptValue(359505)) : _cost;
            player->EnergizeBySpell(player, 500307, CalculatePct(paid, percent), Powers(GetSpellInfo()->PowerType));
        }
        if (Family(GetSpellInfo(), 0, 2) && expired && player->HasAura(560800))
            Summon(player, 805977, GetTarget(), GetTarget()->GetPosition());
        if (id == 500730 && State(player).shade)
        {
            State(player).shade = false;
            player->RemoveAurasDueToSpell(500729);
            if (player->IsAlive())
                Unit::Kill(player, player);
        }
        if (GetTarget() == player)
        {
            if (id == 500981)
                player->RemoveAurasDueToSpell(504691);
            if ((id == 500981 || id == 804371) && !player->HasAura(500981) && !player->HasAura(804371))
                player->RemoveAurasDueToSpell(504747);
            if (id == 804371)
                player->ApplySpellImmune(id, IMMUNITY_DISPEL, DISPEL_DISEASE, false);
            if (id == 803782)
            {
                State(player).diseases.clear();
                player->SetTemporarySpellReplacement(801938, 0);
            }
            if (id == SPELL_FETID_WARD || id == SPELL_GLACIAL_WARD || id == SPELL_BONE_WARD)
                for (Creature* minion : Minions(player))
                    minion->RemoveAurasDueToSpell(id, player->GetGUID());
        }
    }
    void Dispel(DispelInfo*)
    {
        if (Player* player = Owner(GetCaster()))
            if (Named(GetSpellInfo(), 801945))
                Cast(player, GetTarget(), 680928);
    }
    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_necromancer_lifecycle::Calculate, EFFECT_ALL, SPELL_AURA_ANY);
        DoEffectCalcPeriodic +=
            AuraEffectCalcPeriodicFn(aura_ascension_necromancer_lifecycle::Periodic, EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_necromancer_lifecycle::Apply, EFFECT_ALL, SPELL_AURA_ANY,
                                              AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectPeriodic +=
            AuraEffectPeriodicFn(aura_ascension_necromancer_lifecycle::Tick, EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_necromancer_lifecycle::Removed, EFFECT_ALL,
                                                SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
        if (Named(sSpellMgr->GetSpellInfo(m_scriptSpellId), 801945))
            AfterDispel += AuraDispelFn(aura_ascension_necromancer_lifecycle::Dispel);
    }
};
}
void AddAscensionNecromancerAuraScripts()
{
    RegisterSpellScript(aura_ascension_necromancer_lifecycle);
}
