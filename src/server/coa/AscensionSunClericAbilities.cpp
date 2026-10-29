/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionSunCleric.h"
#include "AscensionSunClericData.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include <algorithm>
namespace
{
using namespace AscensionSunCleric;
constexpr uint32 ChosenKing = 707079;
constexpr uint32 HammerOfKings = 804751;
constexpr uint32 Anointed = 524998;
bool Select(uint32 id, SpellInfo const* info)
{
    switch (id)
    {
        case 800722: case 301293: case 680642: return Named(info, 500143);
        case 807059: return Named(info, 806060);
        case 300354: return Named(info, 500141);
        case 800601: return Named(info, 800357);
        case 503691: return Gavel(info);
        case 807299: case 804631: return Named(info, 500146);
        case 301265: return info && info->SpellFamilyName == 33 && info->DmgClass == SPELL_DAMAGE_CLASS_MAGIC;
        case 301242: return Any(info, {800357, 500143, 500141, 800231});
        case 803238: return info && info->Id == 504764;
        case 807061: return Named(info, 806477);
        case 807077: return Named(info, 500154);
        case 807523: return Named(info, 806060);
        default: return false;
    }
}
bool Useful(SpellInfo const* info)
{
    for (auto const& effect : info->Effects)
        if (effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE || effect.Effect == SPELL_EFFECT_HEAL ||
            effect.Effect == SPELL_EFFECT_HEAL_PCT || effect.Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE ||
            effect.Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG || effect.Effect == SPELL_EFFECT_WEAPON_DAMAGE ||
            effect.ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE || effect.ApplyAuraName == SPELL_AURA_PERIODIC_HEAL ||
            effect.ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE)
            return true;
    return Gavel(info) || Any(info, {800626, 520359, 520024, 800054, 804751,804249,572752});
}
constexpr uint32 ScorchMarks = 807059;
constexpr uint32 BurnTheHeretics = 560857;
constexpr uint32 BurnTheHereticsMagicDamage = 560856;
constexpr uint32 SunStride = 680700;
constexpr uint32 SunStrideVisual = 681434;
void Finish(Player* player, Spell* spell)
{
    for (uint32 id : SunClericFinite)
        if (uint64 generation = spell->GetScriptValue(id))
            if (Aura* aura = player->GetAura(id); aura && generation == aura->GetScriptValue(SolarPower))
            {
                if ((id == 301265 || id == 301242) && aura->GetCharges() > 1)
                    aura->SetCharges(aura->GetCharges() - 1);
                else
                    aura->Remove();
                if (id == 680642)
                    Cast(player, player, 524859);
                if (id == 800722 && player->HasAura(680648))
                    StackWithoutRefresh(player, 681254);
                if (id == ScorchMarks && player->HasAura(BurnTheHeretics))
                    Cast(player, player, BurnTheHereticsMagicDamage);
            }
}
class sun_cleric_spells : public AllSpellScript
{
public:
    sun_cleric_spells() : AllSpellScript("sun_cleric_spells",
        {ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_ON_BEFORE_EFFECTS, ALLSPELLHOOK_ON_CAST,
         ALLSPELLHOOK_ON_CRIT_CHANCE, ALLSPELLHOOK_ON_HIT_RESULT}) { }
    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        Player* player = Owner(spell->GetCaster());
        auto* info = spell->GetSpellInfo();
        if (!player || info->SpellFamilyName != 33 || spell->IsTriggered() || result != SPELL_CAST_OK)
            return;
        if (info->Id == DawnCast && !player->HasAura(Dawn) && Count(player, SolarPower) < 20)
            result = SPELL_FAILED_NO_POWER;
        if (info->Id == 680630 && !player->HasAura(Dawn))
            result = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        if (info->Id == 805629 && !player->HasAura(Dawn))
            result = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        if (Any(info, {804249, 804253, 804254, 804250}))
        {
            Unit* target = spell->m_targets.GetUnitTarget();
            if (!target || !target->HasAura(Bless, player->GetGUID()))
                result = SPELL_FAILED_BAD_TARGETS;
        }
    }
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || caster != player || info->SpellFamilyName != 33)
            return;
        if (spell->IsTriggered())
        {
            if (info->Id == 570034)
            {
                spell->SetScriptValue(DawnCast,State(player).landingDawn);
                spell->SetScriptValue(Dawn,State(player).landingFulfillment);
            }
            if (Spell* origin = Origin(player,spell); origin != spell)
                for (uint32 key : {Dawn,DawnCast,807523u})
                    spell->SetScriptValue(key,origin->GetScriptValue(key));
            return;
        }
        for (uint32 id : SunClericFinite)
            if (Select(id, info))
                if (Aura* aura = player->GetAura(id))
                {
                    if (!aura->GetScriptValue(SolarPower))
                        aura->SetScriptValue(SolarPower, ++State(player).sequence);
                    spell->SetScriptValue(id, aura->GetScriptValue(SolarPower));
                    if (id == 807061 || id == 807077)
                        spell->SetScriptValue(id + 1, aura->GetStackAmount());
                }
        if (info->Id == DawnCast || !Useful(info))
            return;
        if (Aura* dawn = player->GetAura(Dawn))
        {
            spell->SetScriptValue(DawnCast, 1);
            if (!State(player).timers.HasTimeUntilEvent(Dawn))
            {
                spell->SetScriptValue(Dawn, 1);
                State(player).timers.ScheduleEvent(Dawn, 1s);
            }
            if (AuraEffect* choice = dawn->GetEffect(EFFECT_0); choice && choice->GetAmount() &&
                (player->HasSpell(92135) || player->HasAura(92135)))
            {
                uint32 school = info->SchoolMask & (SPELL_SCHOOL_MASK_HOLY | SPELL_SCHOOL_MASK_FIRE);
                if (school)
                {
                    choice->SetAmount(0);
                    bool fire = school == SPELL_SCHOOL_MASK_FIRE;
                    player->RemoveAurasDueToSpell(fire ? Sunrise : Sunset);
                    Cast(player, player, fire ? Sunset : Sunrise);
                    if (player->HasAura(300360))
                        Cast(player, player, 301265);
                }
            }
            if (dawn->GetCharges() > 1)
                dawn->SetCharges(dawn->GetCharges() - 1);
            else
                dawn->Remove();
        }
    }
    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Player* player = Owner(spell->GetCaster());
        auto* info = spell->GetSpellInfo();
        if (!player || !target || info->SpellFamilyName != 33 || (Derived(info) && info->Id != 807994))
            return;
        uint32 type = target->GetCreatureType();
        if (player->HasAura(680618) && target->GetHealthPct() > 80 && (info->SchoolMask & SPELL_SCHOOL_MASK_HOLY))
            chance += Amount(680618);
        if (player->HasAura(300343) && target->GetHealthPct() < 20)
            chance += Amount(300343);
        if (player->HasAura(704909) && type == CREATURE_TYPE_UNDEAD)
            chance += Amount(704909, 1);
        if ((Named(info, 680621) && (type == CREATURE_TYPE_UNDEAD || type == CREATURE_TYPE_DEMON)) ||
            (Gavel(info) && player->HasAura(680645) && type == CREATURE_TYPE_UNDEAD) ||
            (Named(info, 500141) && player->HasAura(707517) && target->HasAura(Bless, player->GetGUID())))
            chance = 100;
    }
    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = Owner(caster);
        if (!player || caster != player || info->SpellFamilyName != 33 || spell->IsTriggered())
            return;
        uint32 id = info->Id;
        if (id == SunStride)
            if (Aura* stride = player->GetAura(SunStride, player->GetGUID()))
                if (Aura* visual = player->AddAura(SunStrideVisual, player))
                {
                    visual->SetMaxDuration(stride->GetMaxDuration());
                    visual->SetDuration(stride->GetDuration());
                }
        if (id == HammerOfKings && player->HasAura(ChosenKing, player->GetGUID()))
            Cast(player, player, Anointed);
        if (Invocation(info))
        {
            if (player->HasAura(681436))
                Mana(player, CalculatePct(player->GetMaxPower(POWER_MANA) - player->GetPower(POWER_MANA), Amount(504679)));
            if (player->HasAura(681253))
                Cast(player, player, 681506);
        }
        if (Named(info, 500143) && player->HasAura(681253))
            ReduceInvocations(player, std::abs(Amount(681789)));
        if (Named(info, 500147) && player->HasAura(301256))
            Cast(player, player, 301242);
        if (Any(info, {500146, 800231}) && Chance(player, 806021))
            Cast(player, player, 807059);
        if (Named(info, 800231) && Chance(player, 704908))
            Cast(player, player, 803238);
        if (Named(info, 500154))
        {
            if (player->HasAura(704908))
                Cast(player, player, 803238);
            if (player->HasAura(560111))
                Reduce(player, 800626, INT32_MAX);
        }
        if (Any(info, {500154, 806477}) && Chance(player, 300367))
            Reduce(player, id, INT32_MAX);
        if (Named(info, 806477) && player->HasAura(804630))
            Cast(player, player, 804631);
        if (id == 504764)
            Cast(player, player, 807059);
        if (Named(info, 800654))
        {
            if (player->HasAura(704929))
                Cast(player, player, 704930);
            if (Chance(player, 503690))
            {
                for (uint32 root : {800611,800614,800617})
                    Reduce(player, root, INT32_MAX);
                Cast(player, player, 503691);
            }
        }
        if (Named(info, 805629) && player->HasAura(300318))
            Reduce(player, 680630, std::abs(Amount(570145, 1)));
        if (Gavel(info) && spell->GetScriptValue(503691))
            Reduce(player, id, INT32_MAX);
        if (spell->GetScriptValue(Dawn) && player->HasAura(803719) && player->HasAura(707528))
            ReducePercent(player,id,std::abs(Amount(707528)));
        if (id == 520024)
            Valkyr(player, spell->m_targets.GetUnitTarget(),spell->GetScriptValue(DawnCast),spell->GetScriptValue(Dawn));
        Finish(player, spell);
        Refresh(player);
    }
    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32 healing, bool critical) override
    {
        Player* player = Owner(spell->GetCaster());
        auto* info = spell->GetSpellInfo();
        if (!player || !target || miss != SPELL_MISS_NONE || info->SpellFamilyName != 33)
            return;
        if (info->Id == 707774 && damage)
            Copy(player,player,707522,damage / 10);
        if (info->Id == 707522 && spell->GetCaster() == player && target == player && healing &&
            State(player).gavelHealing && player->HasAura(301011))
        {
            auto allies = Allies(player, player, Radius(301012));
            allies.remove(player);
            if (allies.size() > 5)
                allies.resize(5);
            for (Unit* ally : allies)
                Copy(player, ally, 301012, CalculatePct(healing, Amount(301011)));
        }
        if (Derived(info) || State(player).event)
            return;
        (void)critical;
        bool old = State(player).event;
        bool oldDawn = State(player).dawnEvent;
        State(player).event = true;
        State(player).dawnEvent = spell->GetScriptValue(DawnCast);
        if (Named(info, 500154))
        {
            Cast(player, target, 572050);
            if (!spell->IsTriggered())
                for (Unit* enemy : Nearby(player, 8))
                    if (enemy != target && player->IsValidAttackTarget(enemy) && player->isInFrontInMap(enemy, 8))
                        Cast(player, enemy, 572050);
            if (damage && player->HasAura(680656))
                Cast(player,player,1257670);
        }
        if (info->Id == 806980)
            Cast(player, target, 572067);
        if (Gavel(info) && damage)
        {
            if (Named(info, 800611))
            {
                uint32 copied = CalculatePct(damage, Amount(707521));
                bool const oldGavelHealing = State(player).gavelHealing;
                State(player).gavelHealing = true;
                Copy(player, player, 707522, copied);
                State(player).gavelHealing = oldGavelHealing;
                if (player->HasAura(HolyForm) && player->HasAura(300353))
                    Copy(player, player, 805489, copied);
            }
            if (player->HasAura(HolyForm) && player->HasAura(300353))
            {
                if (Named(info, 800614))
                    Mana(player, CalculatePct(player->GetMaxPower(POWER_MANA), Amount(504722)));
                if (Named(info, 800617) && !spell->IsTriggered())
                {
                    uint32 count = 0;
                    for (Unit* enemy : Nearby(target, 8))
                        if (enemy != target && player->IsValidAttackTarget(enemy) && count++ < 5)
                        {
                            SpellNonMeleeDamage extra(player, enemy, info, info->GetSchoolMask());
                            player->CalculateSpellDamageTaken(&extra, int32(damage), info);
                            Unit::DealDamageMods(enemy, extra.damage, &extra.absorb);
                            player->SendSpellNonMeleeDamageLog(&extra);
                            player->DealSpellDamage(&extra, true);
                        }
                }
            }
        }
        if (info->Id == 800691 || info->Id == 802566)
            if (uint32 const dealt = spell->GetScriptHealthLeechDamage())
                Mana(player, CalculatePct(dealt, Amount(807451)));
        if (healing && player->HasAura(300344) && target->HasAura(Bless, player->GetGUID()) &&
            !spell->IsTriggered() && !spell->GetScriptValue(300344))
        {
            spell->SetScriptValue(300344, 1);
            Mana(player, CalculatePct(std::max(0, spell->GetPowerCost()), Amount(300344, 1)));
        }
        if (healing && player->HasAura(HolyForm) && player->GetMaxPower(POWER_MANA) &&
            player->GetPower(POWER_MANA) * 100u >= player->GetMaxPower(POWER_MANA) * 30u)
        {
            Unit* ally = ObjectAccessor::GetUnit(*player, State(player).blessed);
            if (ally && ally->IsAlive() && ally->HasAura(Bless, player->GetGUID()) && player->IsWithinDistInMap(ally, 100))
            {
                AuraEffect const* form = player->GetAuraEffect(HolyForm,EFFECT_1);
                uint32 extra = uint32(std::clamp(double(healing) * player->GetPower(POWER_MANA) *
                    std::max(0,form ? form->GetAmount() : Amount(HolyForm,1)) /
                    (100.0 * player->GetMaxPower(POWER_MANA)),0.0,double(INT32_MAX)));
                uint32 paid = (extra + 3) / 4;
                if (paid && player->GetPower(POWER_MANA) >= paid)
                {
                    player->ModifyPower(POWER_MANA, -int32(paid));
                    State(player).event = false;
                    Copy(player, ally, 807994, extra);
                    State(player).event = true;
                }
            }
        }
        if (healing && Named(info, 500143) && player->HasAura(681506) && !spell->IsTriggered())
        {
            auto allies = Allies(player, target, 10);
            allies.remove(target);
            if (!allies.empty())
                Copy(player, allies.front(), 803816, CalculatePct(healing, 70));
        }
        if (info->Id == 807058 && spell->GetScriptValue(807523))
            Cast(player, player, 807524);
        if (!spell->IsTriggered())
        {
            if (damage && Named(info, 500146) && spell->GetScriptValue(804631))
            {
                Cast(player, target, info->Id);
                Cast(player, target, 807175);
            }
            for (auto [marker, root, copy] : {std::tuple(807061u,806477u,807078u), std::tuple(807077u,500154u,807215u)})
                if (damage && Named(info, root) && spell->GetScriptValue(marker))
                    Copy(player, target, copy, CalculatePct(damage, Amount(marker) * spell->GetScriptValue(marker + 1)));
        }
        State(player).event = old;
        State(player).dawnEvent = oldDawn;
    }
};
class spell_ascension_sun_cleric_resource : public SpellScript
{
    PrepareSpellScript(spell_ascension_sun_cleric_resource);
    void Effect(SpellEffIndex index)
    {
        if (Player* player = Owner(GetCaster()))
            if (auto const& effect = GetSpellInfo()->Effects[index]; effect.Effect == 175 && effect.TriggerSpell == SolarPower)
            {
                PreventHitDefaultEffect(index);
                if (effect.MiscValue < 0 || !GetSpell()->GetScriptValue(DawnCast))
                    Resource(player, SolarPower, effect.MiscValue);
            }
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_sun_cleric_resource::Effect, EFFECT_ALL, SPELL_EFFECT_ANY);
    }
};
class spell_ascension_sun_cleric_ability : public SpellScript
{
    PrepareSpellScript(spell_ascension_sun_cleric_ability);
    bool done = false;
    uint32 hitIndex = 0;
    uint32 targetCount = 1;
    void CountTargets(std::list<WorldObject*>& targets)
    {
        targetCount = uint32(std::max<size_t>(1,targets.size()));
    }
    void Launch(SpellEffIndex index)
    {
        uint32 id = GetSpellInfo()->Id;
        if (id == 807064 && index == EFFECT_1)
            PreventHitDefaultEffect(index);
        if (id == DawnCast || Any(GetSpellInfo(), {804249,804253,804254,804250}))
            PreventHitDefaultEffect(index);
    }
    void Effect(SpellEffIndex index)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetSpellInfo()->Id;
        if (id == 807064 && index == EFFECT_1)
            PreventHitDefaultEffect(index);
        if (id == DawnCast || id == RadiantConversion || id == 680630 || id == 802161 || id == 520024 || id == 520026 ||
            id == 807441)
            PreventHitDefaultEffect(index);
        if (id == 800764 && index == 1)
            PreventHitDefaultEffect(index);
        if (done || index)
            return;
        if (id == DawnCast)
        {
            done = true;
            if (Aura* dawn = player->GetAura(Dawn))
                dawn->Remove(AURA_REMOVE_BY_CANCEL);
            else
                ActivateDawn(player);
        }
        if (id == RadiantConversion)
        {
            done = true;
            if (Aura* dawn = player->GetAura(Dawn))
                dawn->Remove(AURA_REMOVE_BY_CANCEL);
        }
        if (id == 680630)
        {
            done = true;
            if (Aura* aura = player->GetAura(Dawn))
            {
                aura->SetCharges(aura->CalcMaxCharges());
                aura->SetDuration(aura->GetMaxDuration());
            }
        }
        if (id == 802161)
        {
            done = true;
            SunGate(player);
        }
        if (Any(GetSpellInfo(), {804249,804253,804254,804250}))
        {
            PreventHitDefaultEffect(index);
            Unit* ally = GetHitUnit();
            if (!ally || !ally->HasAura(Bless, player->GetGUID()))
                return;
            if (Named(GetSpellInfo(), 804249))
            {
                float amount = GetEffectValue() + 1.5f * player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_HOLY);
                for (Unit* enemy : Nearby(ally, Radius(804252)))
                    if (player->IsValidAttackTarget(enemy) && ally->HasInArc(float(M_PI), enemy))
                        Copy(player, enemy, 804252, uint32(std::max(0.0f, amount)));
            }
            else
                Cast(player, ally, id == 804253 ? 680889 : id == 804254 ? 680888 : 680911);
            done = true;
        }
    }
    void Hit()
    {
        if (Owner(GetCaster()) && Named(GetSpellInfo(), 806477))
            SetHitDamage(int32(GetHitDamage() * std::pow(.85f, float(hitIndex++))));
        if (Owner(GetCaster()) && GetSpellInfo()->Id == 570187)
            SetHitDamage(GetHitDamage() / int32(targetCount));
    }
    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_sun_cleric_ability::Launch, EFFECT_ALL, SPELL_EFFECT_ANY);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_sun_cleric_ability::Launch, EFFECT_ALL, SPELL_EFFECT_ANY);
        OnEffectHit += SpellEffectFn(spell_ascension_sun_cleric_ability::Effect, EFFECT_ALL, SPELL_EFFECT_ANY);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_sun_cleric_ability::Effect, EFFECT_ALL, SPELL_EFFECT_ANY);
        OnHit += SpellHitFn(spell_ascension_sun_cleric_ability::Hit);
        if (m_scriptSpellId == 570187)
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_sun_cleric_ability::CountTargets,
                EFFECT_0,TARGET_UNIT_SRC_AREA_ENEMY);
    }
};
}
void AddSC_AscensionSunClericAbilities()
{
    new sun_cleric_spells();
    RegisterSpellScript(spell_ascension_sun_cleric_ability);
    RegisterSpellScript(spell_ascension_sun_cleric_resource);
}
