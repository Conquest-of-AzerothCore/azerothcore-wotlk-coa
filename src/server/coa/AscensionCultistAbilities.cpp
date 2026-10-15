/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCultist.h"
#include "AscensionCultistData.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "ThreatManager.h"
#include <algorithm>
namespace
{
using namespace AscensionCultist;
constexpr uint32 selected[] = {502133, 301186, 561288, 301259, 806250, 255070, 681794};
bool Select(uint32 id, SpellInfo const* info)
{
    switch (id)
    {
        case 502133: return Named(info, 500720);
        case 301186: return Named(info, 500711);
        case 561288: return Named(info, 806222);
        case 301259: return Named(info, 500715);
        case 806250: return Named(info, 805116);
        case 255070: return info->Id == 504719;
        case 681794: return info->Id == 680576;
        default: return false;
    }
}
void Finish(Player* player, Spell* spell)
{
    for (uint32 id : selected)
        if (uint64 generation = spell->GetScriptValue(id))
            if (Aura* aura = player->GetAura(id); aura && generation == aura->GetScriptValue(Insanity))
                aura->Remove();
}
class cultist_spells : public AllSpellScript
{
public:
    cultist_spells() : AllSpellScript("cultist_spells",
        {ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_ON_BEFORE_EFFECTS, ALLSPELLHOOK_ON_CAST,
         ALLSPELLHOOK_ON_CRIT_CHANCE, ALLSPELLHOOK_ON_HIT_RESULT, ALLSPELLHOOK_ON_CALC_MAX_DURATION}) { }
    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        Player* player = Owner(spell->GetCaster());
        if (!player || spell->IsTriggered() || result != SPELL_CAST_OK)
            return;
        auto* info = spell->GetSpellInfo();
        if (Any(info, {805116, 804152}) && !player->HasAura(Madness) && Count(player, Insanity) < 40)
            result = SPELL_FAILED_NO_POWER;
        if (info->Id == 520345 && spell->m_targets.GetUnitTarget() == player)
            result = SPELL_FAILED_BAD_TARGETS;
    }
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || caster != player || info->SpellFamilyName != 31 || spell->IsTriggered())
            return;
        spell->SetScriptValue(Insanity, Count(player, Insanity));
        for (uint32 id : selected)
            if (Select(id, info))
                if (Aura* aura = player->GetAura(id))
                {
                    if (!aura->GetScriptValue(Insanity))
                        aura->SetScriptValue(Insanity, ++State(player).sequence);
                    spell->SetScriptValue(id, aura->GetScriptValue(Insanity));
                }
        if (Named(info, 800416) && Count(player, 712291) >= 3)
            spell->SetScriptValue(712291, 1);
        if (Any(info, {805116, 804152}))
            Resource(player, Insanity, -40);
    }
    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Player* player = Owner(spell->GetCaster());
        auto* info = spell->GetSpellInfo();
        if (!player || !target || info->SpellFamilyName != 31)
            return;
        if (Any(info, {808043, 808044, 808045, 808050, 808051, 808052}) && player->HasAura(560977) &&
            (State(player).shockInsanity ? State(player).shockInsanity - 1 : Count(player, Insanity)) >= 60)
            chance = 100;
        if (Named(info, 805116) && spell->GetScriptValue(806250) && player->HasAura(680377))
            chance = 100;
        if (Named(info, 520333) && player->HasAura(300264) && target->HasAura(BlackBlood, player->GetGUID()))
            chance += Amount(300264);
        if (Named(info, 500720) && player->HasAura(Herald) && player->HasAura(301258))
            chance += Amount(301258);
    }
    void OnCalcMaxDuration(Aura const* aura, int32& duration) override
    {
        Player* player = Owner(aura->GetCaster());
        if (!player || duration <= 0)
            return;
        if (aura->GetId() == Herald && player->HasAura(807128))
            duration = std::max(1000, duration - std::abs(Amount(806769)));
        if (Named(aura->GetSpellInfo(), 582591) && player->HasAura(704881))
            duration += std::abs(Amount(704881, 2));
    }
    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = Owner(caster);
        if (!player || caster != player || info->SpellFamilyName != 31 || spell->IsTriggered())
            return;
        uint32 id = info->Id;
        Unit* target = spell->m_targets.GetUnitTarget();
        if (Named(info, 500110) || id == 680576)
        {
            if (player->HasAura(704869))
                RestoreBlade(player);
            if (player->HasAura(300296) && player->HasAura(803339))
                Cast(player, player, 803340);
            if (player->HasAura(300298))
            {
                Reduce(player, 573028, std::abs(Amount(300297)));
                Reduce(player, 800432, std::abs(Amount(300297, 1)));
            }
            for (Unit* ally : Allies(player, player, 100))
                if (Aura* marks = ally->GetAura(301982, player->GetGUID()))
                {
                    uint32 stacks = marks->GetStackAmount();
                    float amount = Amount(301983, 0, player) + .35f * player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_SHADOW);
                    Copy(player, ally, 301983, uint32(std::max(0.0f, amount)));
                    if (Aura* remaining = ally->GetAura(301982, player->GetGUID()); remaining && remaining->GetStackAmount() == stacks)
                        remaining->Remove();
                }
            if (target && player->IsValidAttackTarget(target))
            {
                Command(player, target);
                if (player->HasAura(302015) && Chance(player, 302015))
                    Command(player, target, true);
            }
        }
        if (id == 680576)
        {
            Resource(player, Insanity, 30);
            player->RemoveAurasDueToSpell(681532);
        }
        if (Any(info, {805116, 804152}) && player->HasAura(704869))
            RestoreBlade(player);
        if (Named(info, 800413))
        {
            if (target && (player->HasAura(301200) || player->HasAura(301067)))
                Summon(player, 533030, target->GetNearPosition(3, 0), 12000, target);
            if (player->HasAura(301068))
                Cast(player, player, 301067);
        }
        if (info->DmgClass == SPELL_DAMAGE_CLASS_MELEE && player->HasAura(301183))
        {
            Cast(player, player, 301980);
            if (Count(player, 301980) >= 3)
            {
                player->RemoveAurasDueToSpell(301980);
                Cast(player, player, 301186);
            }
        }
        if (Named(info, 800416))
        {
            if (player->HasAura(704892))
            {
                Cast(player, player, 255020);
                if (Count(player, 255020) >= 3)
                {
                    player->RemoveAurasDueToSpell(255020);
                    Cast(player, player, 255070);
                }
            }
            if (player->HasAura(706909) && Count(player, 712291) < 3 && !spell->GetScriptValue(712291))
                Cast(player, player, 712291);
        }
        if (id == 504719)
            Resource(player, Insanity, 10);
        if (id == 804275)
        {
            if (player->HasAura(807877))
                for (Unit* ally : Allies(player, player, Radius(807878)))
                    if (Aura* blood = ally->GetAura(BlackBlood, player->GetGUID()))
                        blood->SetDuration(blood->GetMaxDuration());
            if (player->HasAura(806382))
                Cast(player, player, 807124);
        }
        if (id == 804670 || id == 804711)
        {
            if (Aura* ward = player->GetAura(id))
                ward->SetStackAmount(5 + (player->HasAura(805126) ? std::max(0, Amount(805126)) : 0));
            if (player->HasAura(680570))
                Cast(player, player, 680571);
        }
        if (id == 806175)
            StartDash(player);
        if (id == 805114 && player->HasAura(707429) && spell->GetScriptValue(Insanity) >= 80)
            Reduce(player, id, 60000);
        if (Any(info, {808036, 808037, 808038}) && player->HasAura(560977))
            Reduce(player, id, INT32_MAX);
        Finish(player, spell);
        Refresh(player);
    }
    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32 healing, bool) override
    {
        Player* player = Owner(spell->GetCaster());
        auto* info = spell->GetSpellInfo();
        if (!player || !target || miss != SPELL_MISS_NONE || info->SpellFamilyName != 31)
            return;
        uint32 id = info->Id;
        if (id == 500862 && healing)
        {
            bool old = State(player).event;
            State(player).event = true;
            if (player->HasAura(301209))
                for (Unit* ally : Allies(player, target, Radius(301211), 2))
                    Copy(player, ally, 301211, healing);
            if (player->HasAura(704884) && target != player)
                Copy(player, player, 707185, CalculatePct(healing, Amount(704884)));
            State(player).event = old;
        }
        if (Named(info, 520333) && healing && player->HasAura(706188))
            Cast(player, target, 807344);
        if (Any(info, {808043, 808044, 808045, 808050, 808051, 808052}) && player->HasAura(704880) && (damage || healing))
        {
            uint32 consumed = damage ? 705107 : 705106;
            player->RemoveAurasDueToSpell(consumed);
            Cast(player, player, damage ? 705106 : 705107);
        }
        if (spell->IsTriggered())
            return;
        if (Named(info, 500720) && damage)
        {
            if (player->HasAura(300275))
                Cast(player, player, 300274);
            if (spell->GetScriptValue(502133) && target == spell->GetOriginalTarget())
                for (Unit* enemy : Nearby(target, 8))
                    if (enemy != target && player->IsValidAttackTarget(enemy))
                    {
                        Copy(player, enemy, 707750, damage);
                        break;
                    }
        }
        if (Named(info, 805116) && damage && spell->GetScriptValue(806250))
        {
            Copy(player, target, 807083, CalculatePct(damage, Amount(806250)));
            if (!spell->GetScriptValue(807216))
            {
                spell->SetScriptValue(807216, 1);
                player->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(), 807216, true);
            }
        }
        if (Named(info, 800416) && damage && spell->GetScriptValue(712291))
        {
            Accumulate(player, target, 706910, damage / 2);
            player->RemoveAurasDueToSpell(712291);
        }
        if (Named(info, 500714) && damage)
        {
            auto allies = Allies(player, player, Radius(BlackBlood));
            allies.sort([player](Unit* a, Unit* b)
            {
                bool linkedA = a->GetGUID() == State(player).covenant;
                bool linkedB = b->GetGUID() == State(player).covenant;
                if (linkedA != linkedB)
                    return linkedA;
                uint32 stacksA = a->GetAura(BlackBlood, player->GetGUID()) ? a->GetAura(BlackBlood, player->GetGUID())->GetStackAmount() : 0;
                uint32 stacksB = b->GetAura(BlackBlood, player->GetGUID()) ? b->GetAura(BlackBlood, player->GetGUID())->GetStackAmount() : 0;
                return stacksA != stacksB ? stacksA < stacksB : a->GetHealthPct() < b->GetHealthPct();
            });
            uint32 count = sSpellMgr->GetSpellInfo(BlackBlood)->MaxAffectedTargets;
            for (Unit* ally : allies)
            {
                if (!count--)
                    break;
                AuraEffect* previous = ally->GetAuraEffect(BlackBlood, EFFECT_0, player->GetGUID());
                int32 next = previous ? previous->GetPeriodicTimer() : -1;
                Copy(player, ally, BlackBlood, std::max(0, info->Effects[1].CalcValue(player)));
                if (AuraEffect* tick = ally->GetAuraEffect(BlackBlood, EFFECT_0, player->GetGUID()); tick && next >= 0)
                    tick->SetPeriodicTimer(next);
            }
        }
        if (Named(info, 524876) && damage && player->HasAura(704889))
        {
            uint32 existing = 0;
            if (AuraEffect* shield = player->GetAuraEffect(850002, EFFECT_0))
                existing = std::max(0, shield->GetAmount());
            Copy(player, player, 850002, existing + CalculatePct(damage, Amount(704889)));
        }
        if (id == 500717)
            Cast(player, player, 500723);
        if (id == 560109 && player->HasAura(525049))
            for (Unit* enemy : Nearby(target, Radius(560943)))
                if (player->IsValidAttackTarget(enemy))
                    Cast(player, enemy, 560943);
    }
};
class spell_ascension_cultist_resource : public SpellScript
{
    PrepareSpellScript(spell_ascension_cultist_resource);
    bool reset = false;
    void Effect(SpellEffIndex index)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        auto const& effect = GetSpellInfo()->Effects[index];
        uint32 id = GetSpellInfo()->Id;
        if ((id == 801157 || id == 570188) && !reset)
        {
            Player* target = Owner(GetHitUnit());
            if (!target || target != GetHitUnit())
                return;
            reset = true;
            if (id == 801157)
            {
                target->RemoveAurasDueToSpell(Madness);
                target->RemoveAurasDueToSpell(803060);
                target->RemoveAurasDueToSpell(560110);
            }
            Resource(target, Insanity, -100, true);
        }
        if (id == 801157 || id == 570188)
            PreventHitDefaultEffect(index);
        if (effect.Effect == 175 && effect.TriggerSpell == Insanity)
        {
            PreventHitDefaultEffect(index);
            if (id != 500728 || !player->IsInCombat())
                Resource(player, Insanity, effect.MiscValue, id == 500728);
        }
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_cultist_resource::Effect, EFFECT_ALL, SPELL_EFFECT_ANY);
    }
};
class spell_ascension_cultist_sanity_tap : public SpellScript
{
    PrepareSpellScript(spell_ascension_cultist_sanity_tap);
    void Effect(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        SpellInfo const* info = GetSpellInfo();
        int32 misc = info->Effects[index].MiscValue;
        if (!caster || !target || !target->IsAlive() || misc < 0 || misc >= int32(MAX_POWERS))
            return;
        if (target->HasUnitState(UNIT_STATE_ISOLATED))
        {
            caster->SendSpellDamageImmune(target, info->Id);
            return;
        }
        Powers power = Powers(misc);
        if (target->IsPlayer() && !target->CanReceivePowerFromSpell(power) &&
            !info->HasAttribute(SPELL_ATTR7_ONLY_IN_SPELLBOOK_UNTIL_LEARNED))
            return;
        uint32 maxPower = target->GetMaxPower(power);
        uint32 currentPower = target->GetPower(power);
        if (currentPower >= maxPower)
            return;
        caster->EnergizeBySpell(target, info->Id, CalculatePct(maxPower - currentPower, GetEffectValue()), power);
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_cultist_sanity_tap::Effect, EFFECT_1,
            SPELL_EFFECT_ENERGIZE_PCT);
    }
};
class spell_ascension_cultist_worrysome_idol : public SpellScript
{
    PrepareSpellScript(spell_ascension_cultist_worrysome_idol);
    void Effect(SpellEffIndex index)
    {
        Unit* caster = GetCaster();
        if (!Owner(caster))
            return;
        PreventHitDefaultEffect(index);
        Unit* target = GetHitUnit();
        SpellInfo const* info = GetSpellInfo();
        int32 misc = info->Effects[index].MiscValue;
        if (!caster || !target || !target->IsAlive() || misc < 0 || misc >= int32(MAX_POWERS))
            return;
        if (target->HasUnitState(UNIT_STATE_ISOLATED))
        {
            caster->SendSpellDamageImmune(target, info->Id);
            return;
        }
        Powers power = Powers(misc);
        if (target->IsPlayer() && !target->CanReceivePowerFromSpell(power) &&
            !info->HasAttribute(SPELL_ATTR7_ONLY_IN_SPELLBOOK_UNTIL_LEARNED))
            return;
        uint32 maxPower = target->GetMaxPower(power);
        uint32 currentPower = target->GetPower(power);
        if (currentPower >= maxPower)
            return;
        caster->EnergizeBySpell(target, info->Id, CalculatePct(maxPower - currentPower, GetEffectValue()), power);
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_cultist_worrysome_idol::Effect, EFFECT_0,
            SPELL_EFFECT_ENERGIZE_PCT);
    }
};
class spell_ascension_cultist_ability : public SpellScript
{
    PrepareSpellScript(spell_ascension_cultist_ability);
    bool done = false;
    void Effect(SpellEffIndex index, Unit* target)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetSpellInfo()->Id;
        auto const& effect = GetSpellInfo()->Effects[index];
        if (Any(GetSpellInfo(), {808036, 808037, 808038}) && !index && target)
        {
            uint32 offset = id - 808036;
            uint32 previous = State(player).shockInsanity;
            State(player).shockInsanity = GetSpell()->GetScriptValue(Insanity) + 1;
            Cast(player, target, (player->IsFriendlyTo(target) ? 808050 : 808043) + offset);
            State(player).shockInsanity = previous;
        }
        if (id == 500704 && target && target != player && !index)
            Cast(player, target, 804533);
        if (id == 805114 && target && !target->IsPlayer() && !index)
            Cast(player, target, 32747);
        if (id == 301184 && !index)
        {
            PreventHitDefaultEffect(index);
            if (player->HasAura(Herald) && player->HasAura(300753))
                Reduce(player, 800105, 2000);
        }
        if (id == 560301 && effect.Effect == SPELL_EFFECT_TRIGGER_SPELL)
            PreventHitDefaultEffect(index);
        if (id == 560301 && !done && !index)
        {
            done = true;
            player->GetThreatMgr().RemoveMeFromThreatLists();
            uint32 duration = sSpellMgr->GetSpellInfo(706932)->GetDuration();
            for (uint32 n = 0; n < 3; ++n)
                Summon(player, 840000, player->GetNearPosition(2, float(n) * 2), duration, player->GetVictim());
        }
        if (effect.Effect == SPELL_EFFECT_SUMMON)
        {
            PreventHitDefaultEffect(index);
            if (!done)
            {
                done = true;
                Position position = GetExplTargetDest() ? GetExplTargetDest()->GetPosition() : player->GetNearPosition(2, 0);
                Summon(player, effect.MiscValue, position, std::max(1000, GetSpellInfo()->GetDuration()), GetExplTargetUnit());
            }
        }
        if (id == 804779 && (effect.Effect == 174 || effect.Effect == 164))
            PreventHitDefaultEffect(index);
    }
    void EffectHit(SpellEffIndex index)
    {
        Effect(index, nullptr);
    }
    void EffectHitTarget(SpellEffIndex index)
    {
        Effect(index, GetHitUnit());
    }
    void Launch(SpellEffIndex index)
    {
        if (Owner(GetCaster()) && GetSpellInfo()->Id == 560301 &&
            GetSpellInfo()->Effects[index].Effect == SPELL_EFFECT_TRIGGER_SPELL)
            PreventHitDefaultEffect(index);
    }
    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_cultist_ability::Launch, EFFECT_ALL, SPELL_EFFECT_ANY);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_cultist_ability::Launch, EFFECT_ALL, SPELL_EFFECT_ANY);
        OnEffectHit += SpellEffectFn(spell_ascension_cultist_ability::EffectHit, EFFECT_ALL, SPELL_EFFECT_ANY);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_cultist_ability::EffectHitTarget, EFFECT_ALL,
            SPELL_EFFECT_ANY);
    }
};
class spell_ascension_cultist_shield : public SpellScript
{
    PrepareSpellScript(spell_ascension_cultist_shield);
    void After()
    {
        Player* player = Owner(GetCaster());
        Unit* target = GetExplTargetUnit();
        if (!player || !target || GetSpell()->IsTriggered() || !player->HasAura(572064))
            return;
        auto allies = Allies(player, target, 15);
        allies.remove(target);
        allies.remove_if([](Unit* ally) { return ally->HasAura(805801); });
        if (!allies.empty())
            Cast(player, allies.front(), GetSpellInfo()->Id);
    }
    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_cultist_shield::After);
    }
};
constexpr uint32 SPELL_SHADOW_TRAINING = 805607;
constexpr uint32 SPELL_GAZE_OF_CTHUN_HEAL_TRIGGER = 520333;
class aura_ascension_cultist_shadow_training : public AuraScript
{
    PrepareAuraScript(aura_ascension_cultist_shadow_training);
    bool Validate(SpellInfo const* spellInfo) override
    {
        if (!spellInfo || spellInfo->Id != SPELL_SHADOW_TRAINING || spellInfo->SpellFamilyName != 31 ||
            spellInfo->Effects[EFFECT_1].Effect != SPELL_EFFECT_APPLY_AURA ||
            spellInfo->Effects[EFFECT_1].ApplyAuraName != SPELL_AURA_MOD_EXPERTISE ||
            spellInfo->Effects[EFFECT_1].MiscValue != 0 || spellInfo->Effects[EFFECT_1].BasePoints != 99 ||
            spellInfo->Effects[EFFECT_1].DieSides != 1)
            return false;
        SpellInfo const* gazeHeal = sSpellMgr->GetSpellInfo(SPELL_GAZE_OF_CTHUN_HEAL_TRIGGER);
        return gazeHeal && gazeHeal->SpellFamilyName == 31 && (gazeHeal->SpellFamilyFlags & flag96(2097152, 0, 0));
    }
    void AddGazeHealingModifier(AuraEffect const* aurEff, SpellModifier*& spellMod)
    {
        if (spellMod)
            return;
        spellMod = new SpellModifier(aurEff->GetBase());
        spellMod->op = SPELLMOD_DAMAGE;
        spellMod->type = SPELLMOD_PCT;
        spellMod->spellId = SPELL_SHADOW_TRAINING;
        spellMod->mask = flag96(2097152, 0, 0);
        spellMod->value = 100;
    }
    void Register() override
    {
        DoEffectCalcSpellMod += AuraEffectCalcSpellModFn(
            aura_ascension_cultist_shadow_training::AddGazeHealingModifier, EFFECT_1, SPELL_AURA_MOD_EXPERTISE);
    }
};
}
void AddSC_AscensionCultistAbilities()
{
    new cultist_spells();
    RegisterSpellScript(spell_ascension_cultist_resource);
    RegisterSpellScript(spell_ascension_cultist_sanity_tap);
    RegisterSpellScript(spell_ascension_cultist_worrysome_idol);
    RegisterSpellScript(spell_ascension_cultist_ability);
    RegisterSpellScript(spell_ascension_cultist_shield);
    RegisterSpellScript(aura_ascension_cultist_shadow_training);
}
