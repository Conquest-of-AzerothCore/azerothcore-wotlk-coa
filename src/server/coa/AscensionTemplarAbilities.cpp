/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTemplar.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>

namespace
{
using namespace AscensionTemplar;
bool Selected(SpellInfo const* info, uint32 aura)
{
    switch (aura)
    {
    case 806354:
        return info->Id == 805417;
    case 807004:
        return info->Id == 801205;
    case 561156:
        return Named(info, 804929);
    case 681136:
        return info->SpellFamilyName == 25 && !info->IsPassive();
    case 712378:
        return Named(info, 801165);
    case 524766:
        return Named(info, 801448);
    case 806523:
        return info->Id == 801832;
    case 524617:
        return Named(info, 803157);
    default:
        return false;
    }
}
constexpr uint32 SPELL_VISUAL_KIT_BENEDICTION_CAST = 4565;
constexpr uint32 SPELL_VISUAL_KIT_BENEDICTION_IMPACT = 4566;
constexpr uint32 selected[] = {806354, 807004, 561156, 681136, 712378, 524766, 806523, 524617};
void ConsumeSelected(Player* player, Spell* spell)
{
    for (uint32 sid : selected)
        if (uint64 sequence = spell->GetScriptValue(sid))
            if (Aura* aura = player->GetAura(sid))
                if (aura->GetScriptValue(704576) == sequence)
                    aura->DropCharge(AURA_REMOVE_BY_EXPIRE);
}
class templar_casts : public AllSpellScript
{
  public:
    templar_casts()
        : AllSpellScript("templar_casts",
                         {ALLSPELLHOOK_ON_BEFORE_EFFECTS, ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_CALCULATED_TARGET,
                          ALLSPELLHOOK_ON_HIT_RESULT, ALLSPELLHOOK_ON_CALC_MAX_DURATION})
    {
    }
    void OnCalcMaxDuration(Aura const* aura, int32& duration) override
    {
        Player* player = aura ? Owner(aura->GetCaster()) : nullptr;
        if (player && aura->GetId() == 560116 && player->HasAura(712678))
            duration += 2000;
    }
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || info->SpellFamilyName != 25)
            return;
        for (uint32 sid : selected)
            if ((!spell->IsTriggered() || info->Id == 801832) && Selected(info, sid))
                if (Aura* aura = player->GetAura(sid))
                    spell->SetScriptValue(sid, aura->GetScriptValue(704576));
        if (spell->IsTriggered())
            return;
        if (Aura* aura = player->GetAura(704576))
            spell->SetScriptValue(704576, aura->GetStackAmount());
        if ((Breaker(info) && Ability(info)) || info->Id == 500689)
            if (Aura* aura = player->GetAura(807648))
                spell->SetScriptValue(807648, aura->GetStackAmount());
        if (Named(info, 803157) && player->HasAura(524617))
            if (Aura* aura = player->GetAura(805416))
                spell->SetScriptValue(805416, aura->GetStackAmount());
        if (info->Id == 560116 && player->HasAura(712437))
            if (Unit* primary = spell->m_targets.GetUnitTarget())
                for (Unit* extra : Nearby(primary, 8.0f))
                    if (extra != primary && player->IsValidAttackTarget(extra) && player->IsWithinLOSInMap(extra))
                    {
                        spell->AddUnitTargetForScript(extra, 7);
                        break;
                    }
    }
    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        Player* player = Owner(spell->GetCaster());
        if (!player || !target)
            return;
        SpellInfo const* info = spell->GetSpellInfo();
        if (Named(info, 804929))
            spell->SetScriptValue(801832, 1);
        float factor = 1.0f;
        if (Named(info, 805410))
            for (auto const& pair : player->GetAppliedAuras())
                if (Aura* aura = pair.second->GetBase(); Named(aura->GetSpellInfo(), 805409))
                {
                    factor *= 1.0f + float(aura->GetScriptValue(805409)) / 100.0f;
                    break;
                }
        if (info->Id == 801832 && (target->GetCreatureType() == CREATURE_TYPE_UNDEAD || spell->GetScriptValue(806523)))
            hit.crit = true;
        if (spell->GetScriptValue(524617) && spell->GetScriptValue(805416))
        {
            factor *= 1.5f;
            hit.crit = true;
        }
        if (player->HasAura(300520) && target->HealthBelowPct(20) &&
            (info->Id == 801832 || info->Id == 807035 || Named(info, 806521)))
            factor *= 1.25f;
        hit.damage = int32(hit.damage * factor);
        hit.damageBeforeTakenMods = int32(hit.damageBeforeTakenMods * factor);
    }
    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = Owner(caster);
        if (!player || info->SpellFamilyName != 25)
            return;
        if (info->Id == 801450 && player->HasAura(704576))
            Cast(player, player, 807764);
        if (info->Id == 801832)
        {
            ConsumeSelected(player, spell);
            return;
        }
        if (spell->IsTriggered())
            return;
        ConsumeSelected(player, spell);
        auto talent = [player](uint32 passive, uint32 child) {
            if (player->HasAura(passive))
                Cast(player, player, child);
        };
        if (Named(info, 805421))
            talent(301309, 680870);
        Unit* target = spell->m_targets.GetUnitTarget();
        if (Family(info, 2, 1) || info->Id == 500689)
        {
            uint32 oath = Named(info, 801443)   ? 804904
                          : Named(info, 801445) ? 804903
                          : Named(info, 804906) ? 804922
                                                : 805332;
            GrantOath(player, oath);
            talent(705286, 560834);
        }
        if (Breaker(info))
        {
            if (player->HasAura(300502) && spell->GetScriptValue(704576) >= 10)
                for (Unit* enemy : Nearby(player, 40.0f))
                    for (auto const& pair : enemy->GetAppliedAuras())
                        if (Aura* aura = pair.second->GetBase();
                            Named(aura->GetSpellInfo(), 803872) && aura->GetCasterGUID() == player->GetGUID())
                            aura->SetDuration(aura->GetMaxDuration());
            if (!player->HasAura(92109) && !player->HasAura(803149) && !Named(info, 805409))
                ClearOaths(player);
            if (Named(info, 501562))
                player->RemoveAurasDueToSpell(807764);
            if (player->HasAura(707606) && (Named(info, 501562) || Named(info, 803872)))
                State(player).retribution = true;
            talent(806273, 806353);
            if (player->HasAura(804927))
                ReduceLibrams(player, std::abs(Amount(806106)));
            if (player->HasAura(705300))
                Cast(player, player, 707111);
            if (player->HasAura(504807))
            {
                Zealotry(player, target ? target : player->GetVictim());
                for (uint32 root : {500694, 806153, 801455})
                    Reduce(player, root, 1000);
                ReduceLibrams(player, 1000);
            }
            if (player->HasAura(803159) || player->HasAura(803844))
            {
                Unit* center = target ? target : player;
                for (Unit* ally : Nearby(center, 15.0f))
                    if (ally == player || player->IsInRaidWith(ally))
                        Cast(player, ally, 803160);
            }
        }
        if (spell->GetScriptValue(807648))
        {
            player->RemoveAurasDueToSpell(807648);
            Copy(player, player, 807763, uint32(std::min<uint64>(3, spell->GetScriptValue(807648))));
        }
        if (spell->GetScriptValue(524617))
            if (Aura* aura = player->GetAura(805416))
                aura->ModStackAmount(-int32(spell->GetScriptValue(805416)));
        if (info->Id == 805417 && spell->GetScriptValue(806354))
            ReduceDebt(player, 100);
        if (info->Id == 560116 && player->HasAura(712678))
            player->ModifySpellCooldown(info->Id, 5000);
        if (Libram(info) && player->HasAura(706468))
            ReduceDebt(player, 70);
        if (Named(info, 801448))
        {
            talent(707364, 712378);
            if (target && (player->HasAura(680399) || player->HasAura(681483)))
                Cast(player, target, 525052);
        }
        if (Named(info, 801165))
        {
            talent(705256, 681136);
            if (target && target != player && roll_chance_i(player->HasAura(804571) ? 40 : 0))
                player->RestoreSpellCharge(info->Id);
        }
        if (Named(info, 705293))
        {
            talent(705295, 706583);
            talent(712677, 712679);
        }
        if (Named(info, 804929))
        {
            if (player->HasAura(301065) && spell->GetScriptValue(561156))
                Cast(player, player, 301172);
            if (player->HasAura(520812) && ++State(player).argent % 2 == 0)
                GrantOath(player, 804924);
        }
        if (info->Id == 807035)
        {
            player->RemoveAurasDueToSpell(301172);
            talent(301254, 521240);
        }
        if (info->Id == 500689)
        {
            State(player).zealotry = 0;
            player->RemoveAurasDueToSpell(563270);
            player->RemoveAurasDueToSpell(563269);
        }
        if (Named(info, 804929) || info->Id == 807035)
            talent(806522, 806523);
        if (Named(info, 801478) || info->Id == 801455 || info->Id == 1397742)
            if (target || info->Id == 1397742)
                Cast(player, target ? target : player, 102208);
    }
    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32 healing, bool) override
    {
        Player* player = Owner(spell->GetCaster());
        if (!player || !target || spell->GetSpellInfo()->SpellFamilyName != 25)
            return;
        SpellInfo const* info = spell->GetSpellInfo();
        bool const hit = miss == SPELL_MISS_NONE;
        if (hit && healing && Named(info, 801448) && player->HasAura(524765))
            Cast(player, player, 524766);
        if (hit && damage && Named(info, 804929))
            Copy(player, player, 807414, damage);
        if (Named(info, 804929) && spell->GetScriptValue(801832))
            Cast(player, target, 801832);
        if (!hit || !damage || !player->IsValidAttackTarget(target))
            return;
        if (info->Id == 801450)
        {
            if (player->HasAura(504107) && !player->HasAura(563269))
                Cast(player, player, 563270);
            if (player->HasAura(504561))
                Cast(player, player, 504809);
            if (player->HasAura(523712))
                Cast(player, target, 523713);
            if (Chance(player, 504808))
                Copy(player, player, 505206, 1);
            return;
        }
        if (info->Id == 801832)
        {
            if (player->HasAura(705255))
                player->AddAura(803372, player);
            return;
        }
        if (info->Id == 707111 && player->HasAura(573452) && !spell->GetScriptValue(806106))
        {
            spell->SetScriptValue(806106, 1);
            ReduceLibrams(player, std::abs(Amount(806106)));
        }
        if (Named(info, 805410) && player->HasAura(301339))
            SpreadCondemn(player, target);
        if (Named(info, 804929))
        {
            if (!spell->IsTriggered() &&
                (Chance(player, 520883) || (!player->HasAura(520883) && Chance(player, 520017))))
                Cast(player, target, info->Id);
            if (player->HasAura(500011))
                if (Aura* aura = target->GetAura(560116, player->GetGUID()))
                    aura->SetDuration(std::min(aura->GetMaxDuration(), aura->GetDuration() + Amount(500014)));
        }
        if (Named(info, 801446) || info->Id == 500689)
        {
            Zealotry(player, target);
            if (info->Id == 500689)
                Cast(player, target, 572051);
        }
        if (Ability(info) && !spell->IsTriggered())
            if (AuraEffect* oath = player->GetAuraEffect(805332, EFFECT_0))
                if (roll_chance_i(oath->GetAmount()))
                    Zealotry(player, target);
        if (Named(info, 803157))
        {
            if (player->HasAura(680891))
                Cast(player, target, 801832);
            if (player->HasAura(705259) && HasLibram(player) && !spell->GetScriptValue(706466))
            {
                spell->SetScriptValue(706466, 1);
                Cast(player, target, 706466);
            }
        }
        if ((Named(info, 705293) || Named(info, 805421)) && player->HasAura(805420))
            Cast(player, target, 572052);
        if (Named(info, 806153) && player->HasAura(804897) && !spell->GetScriptValue(804918))
            for (auto const& pair : target->GetAppliedAuras())
                if (Aura* aura = pair.second->GetBase();
                    Named(aura->GetSpellInfo(), 803872) && aura->GetCasterGUID() == player->GetGUID())
                {
                    spell->SetScriptValue(804918, 1);
                    Reduce(player, 806153, 4000);
                    break;
                }
        if (info->Id == 805410 || Family(info, 0, 2))
            if (player->HasAura(520534) && !spell->GetScriptValue(520544))
            {
                spell->SetScriptValue(520544, 1);
                Cast(player, player, 520544);
                for (Unit* enemy : Nearby(player, 15.0f))
                    if (player->IsValidAttackTarget(enemy) && !enemy->HasAura(520694, player->GetGUID()))
                    {
                        Cast(player, enemy, 520694);
                        Cast(player, enemy, 520695);
                    }
            }
    }
};

class spell_ascension_templar_ability : public SpellScript
{
    PrepareSpellScript(spell_ascension_templar_ability);
    void Launch(SpellEffIndex effect)
    {
        Player* player = Owner(GetCaster());
        if (!player || !Named(GetSpellInfo(), 801448) || player->HasAura(705287))
            return;
        PreventHitDefaultEffect(effect);
        player->SendPlaySpellVisual(SPELL_VISUAL_KIT_BENEDICTION_CAST);
        if (Unit* target = GetHitUnit())
            target->SendPlaySpellVisual(SPELL_VISUAL_KIT_BENEDICTION_IMPACT);
    }
    void Enlighten(SpellEffIndex effect)
    {
        SpellEffectInfo const& info = GetSpellInfo()->Effects[effect];
        Player* player = Owner(GetCaster());
        if (!player || info.Effect != 192)
            return;
        PreventHitDefaultEffect(effect);
        for (auto const& pair : player->GetSpellMap())
            if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), uint32(info.MiscValue)))
                if (uint32 remaining = player->GetSpellCooldownDelay(pair.first))
                    player->ModifySpellCooldown(pair.first, -int32(CalculatePct(remaining, GetEffectValue())));
    }
    void Devotion(SpellEffIndex effect)
    {
        PreventHitDefaultEffect(effect);
        if (Player* player = Owner(GetCaster()); player && effect == EFFECT_0)
            ReduceLibrams(player, std::abs(GetEffectValue()));
    }
    void Absolve()
    {
        if (Player* player = Owner(GetCaster()))
            Cast(player, player, 520659);
    }
    void Transcend(SpellEffIndex effect)
    {
        SpellEffectInfo const& info = GetSpellInfo()->Effects[effect];
        Player* player = Owner(GetCaster());
        SpellInfo const* named = sSpellMgr->GetSpellInfo(uint32(info.MiscValue));
        if (!player || !named)
            return;
        PreventHitDefaultEffect(effect);
        int32 const delta = GetEffectValue();
        for (auto const& pair : player->GetSpellMap())
        {
            SpellInfo const* owned = player->HasSpell(pair.first) ? sSpellMgr->GetSpellInfo(pair.first) : nullptr;
            if (!owned || owned->SpellFamilyName != named->SpellFamilyName ||
                !(owned->SpellFamilyFlags & named->SpellFamilyFlags))
                continue;
            if (player->GetSpellCooldownDelay(pair.first))
                player->ModifySpellCooldown(pair.first, delta);
        }
    }
    void Register() override
    {
        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(m_scriptSpellId); Named(info, 801448))
            OnEffectLaunchTarget +=
                SpellEffectFn(spell_ascension_templar_ability::Launch, EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL);
        if (m_scriptSpellId == 680953)
            OnEffectHitTarget += SpellEffectFn(spell_ascension_templar_ability::Enlighten, EFFECT_ALL, SPELL_EFFECT_ANY);
        if (m_scriptSpellId == 560097)
            OnEffectHitTarget += SpellEffectFn(spell_ascension_templar_ability::Devotion, EFFECT_ALL,
                                               SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
        if (m_scriptSpellId == 800424)
            AfterCast += SpellCastFn(spell_ascension_templar_ability::Absolve);
        if (m_scriptSpellId == 804918)
            OnEffectHitTarget += SpellEffectFn(spell_ascension_templar_ability::Transcend, EFFECT_ALL,
                                               SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
    }
};
}
void AddSC_AscensionTemplarAbilities()
{
    new templar_casts();
    RegisterSpellScript(spell_ascension_templar_ability);
}
