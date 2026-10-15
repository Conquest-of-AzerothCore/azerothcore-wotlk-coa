/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionStarcaller.h"
#include "AscensionStarcallerData.h"
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
#include <cmath>
namespace
{
using namespace AscensionStarcaller;
constexpr uint32 selected[] = {800386, 680821, 503780, 561046, 801243, 707425, 504630, 504631, 680713, 802681, 572319};
bool IsLunarEclipseActivation(Spell const* spell)
{
    constexpr uint32 allowedFlags = TRIGGERED_IGNORE_CAST_IN_PROGRESS | TRIGGERED_CAST_DIRECTLY;
    return spell->GetSpellInfo()->Id == 800386 && !(uint32(spell->GetTriggeredCastFlags()) & ~allowedFlags);
}

bool Select(uint32 id, SpellInfo const* info, Player* player)
{
    switch (id)
    {
    case 800386:
        return Lunar(info, player);
    case 680821:
        return Named(info, 800370) && !player->HasAura(800386);
    case 503780:
        return info->Id == 801990;
    case 561046:
        return Named(info, 680220);
    case 801243:
    case 680713:
        return info->Id == 805563;
    case 707425:
        return Named(info, 800497);
    case 504630:
        return info->HasEffect(SPELL_EFFECT_HEAL);
    case 504631:
        return Named(info, 520590) || info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE) ||
               info->HasEffect(SPELL_EFFECT_NORMALIZED_WEAPON_DMG);
    case 802681:
        return info->Id == 801125;
    case 572319:
        return info->Id == 802682;
    default:
        return false;
    }
}
void Snapshot(Player* player, Spell* spell)
{
    if (spell->IsTriggered())
        return;
    for (uint32 id : selected)
        if (Select(id, spell->GetSpellInfo(), player))
            if (Aura* aura = player->GetAura(id))
            {
                if (!aura->GetScriptValue(800386))
                    aura->SetScriptValue(800386, ++State(player).sequence);
                spell->SetScriptValue(id, aura->GetScriptValue(800386));
            }
}
void FinishSelected(Player* player, Spell* spell)
{
    for (uint32 id : selected)
        if (uint64 generation = spell->GetScriptValue(id))
            if (Aura* aura = player->GetAura(id); aura && aura->GetScriptValue(800386) == generation)
                aura->Remove();
}
void ExtraTargets(Player* player, Spell* spell, uint32 count)
{
    Unit* target = spell->m_targets.GetUnitTarget();
    if (!target || !count)
        return;
    for (Unit* unit : Nearby(target, 10))
        if (unit != target && player->IsValidAttackTarget(unit) && player->IsWithinLOSInMap(unit))
        {
            spell->AddUnitTargetForScript(unit, 7);
            if (!--count)
                break;
        }
}
void Warden(Player* player, Unit* target)
{
    if (player->HasAura(801128))
        Cast(player, target, 805511);
    else if (player->HasAura(801123))
        Cast(player, target, 807195);
    else if (player->HasAura(805356))
    {
        uint32 mana = std::min(target->GetPower(POWER_MANA), target->GetMaxPower(POWER_MANA) / 10);
        target->ModifyPower(POWER_MANA, -int32(mana));
        Mana(player, mana, 807816);
    }
    else if (player->HasAura(802203))
        Cast(player, target, 807992);
    else if (player->HasAura(800510) || player->HasAura(803887) || player->HasAura(803888))
        Cast(player, target, 805510);
    else if (player->HasAura(574360))
        Cast(player, player, 805512);
}
bool BurningBonus(Player* player, Unit* target, SpellInfo const* info)
{
    if (!Burning(target))
        return false;
    if (Named(info, 801132) && player->HasAura(561062))
        return true;
    if (!player->HasAura(707751))
        return false;
    if (Named(info, 801978))
        return true;
    return std::find(std::begin(StarcallerTrueshotHelpers), std::end(StarcallerTrueshotHelpers), info->Id) !=
           std::end(StarcallerTrueshotHelpers);
}
class starcaller_spells : public AllSpellScript
{
  public:
    starcaller_spells()
        : AllSpellScript("starcaller_spells",
                         {ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_ON_BEFORE_EFFECTS, ALLSPELLHOOK_ON_CAST,
                          ALLSPELLHOOK_ON_CALCULATED_TARGET, ALLSPELLHOOK_ON_HIT_RESULT, ALLSPELLHOOK_ON_CRIT_CHANCE,
                          ALLSPELLHOOK_ON_CALC_MAX_DURATION})
    {
    }
    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        Player* player = Owner(spell->GetCaster());
        if (!player || result != SPELL_CAST_OK || (spell->IsTriggered() && !IsLunarEclipseActivation(spell)))
            return;
        uint32 id = spell->GetSpellInfo()->Id;
        if (id == 800386 && (Count(player, 802985) < LunarPhaseThreshold || player->HasAura(800386)))
            result = SPELL_FAILED_CASTER_AURASTATE;
        if ((id == 801125 && !player->HasAura(802681)) || (id == 802682 && !player->HasAura(572319)))
            result = SPELL_FAILED_CASTER_AURASTATE;
    }
    void OnCalcMaxDuration(Aura const* aura, int32& duration) override
    {
        if (aura->GetType() != UNIT_AURA_TYPE || !Owner(aura->GetCaster()))
            return;
        if (aura->GetUnitOwner()->IsControlledByPlayer())
        {
            if (aura->GetId() == 805546)
                duration = std::min(duration, 6000);
            if (aura->GetId() == 807195)
                duration = std::min(duration, 8000);
        }
    }
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || info->SpellFamilyName != 32)
            return;
        Snapshot(player, spell);
        if (IsLunarEclipseActivation(spell))
        {
            if (Aura* phase = player->GetAura(802985))
                phase->ModStackAmount(-int32(LunarPhaseThreshold));
            if (Count(player, 802985) < LunarPhaseThreshold)
                player->RemoveAurasDueToSpell(704519);
        }
        if (Named(info, 801132) && player->HasAura(520482))
            ExtraTargets(player, spell, 1);
        if (Named(info, 680220) && player->HasAura(520481))
            ExtraTargets(player, spell, std::max(0, Amount(520481) - 1));
        if (Named(info, 800370) && player->HasAura(504001) && spell->m_targets.GetUnitTarget() != player)
            spell->AddUnitTargetForScript(player, 1);
        if (info->Id == 805563)
        {
            Unit* target = spell->m_targets.GetUnitTarget();
            if (target && (player->HasAura(680847) || player->HasAura(680822)))
                Cast(player, target, 531756);
        }
        if (!spell->IsTriggered() && info->PowerType == POWER_MANA && spell->GetPowerCost() > 0 &&
            player->HasAura(680742))
        {
            auto& state = State(player);
            state.spentPercent += 100.0 * spell->GetPowerCost() / std::max<uint32>(1, player->GetMaxPower(POWER_MANA));
            while (state.spentPercent >= 100)
            {
                state.spentPercent -= 100;
                Cast(player, player, 572033);
            }
        }
    }
    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Player* player = Owner(spell->GetCaster());
        if (player && spell->GetSpellInfo()->Id == 801996 && player->HasAura(704788))
            chance += 10;
        if (player && BurningBonus(player, target, spell->GetSpellInfo()))
            chance = Named(spell->GetSpellInfo(), 801132) ? 100.0f : chance + 25.0f;
    }
    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        Player* player = Owner(spell->GetCaster());
        SpellInfo const* info = spell->GetSpellInfo();
        if (!player || !target || info->SpellFamilyName != 32 || Derived(info))
            return;
        float factor = 1;
        if (info->Id == 804995 && player->HasAura(807659))
            factor *= 1.5f;
        if (info->Id == 801401 && player->HasAura(807659))
            factor *= 1.5f;
        if ((info->Id == 804995 || info->Id == 801401) && player->HasAura(805524))
            factor *= 1.5f;
        if (info->Id == 804995 && player->HasAura(574360))
            factor *= 2;
        if (hit.crit && info->Id == 804995 && player->HasAura(504694))
            factor *= 1.1f;
        if (hit.crit && player->HasAura(504003) && Any(info, {801990, 575030}))
            factor *= 1.15f;
        if (hit.crit && info->Id == 801401 && player->HasAura(504694))
            factor *= 1.1f;
        if (hit.crit && BurningBonus(player, target, info))
            factor *= 1.25f;
        if (spell->GetScriptValue(800386))
        {
            if (Named(info, 575039))
                factor *= 2;
            if (Named(info, 800370) && hit.damage < 0)
            {
                int32 bonus = int32(target->GetMaxHealth() * .05f);
                hit.damage -= bonus;
                hit.damageBeforeTakenMods -= bonus;
            }
        }
        hit.damage = int32(hit.damage * factor);
        hit.damageBeforeTakenMods = int32(hit.damageBeforeTakenMods * factor);
    }
    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32 healing, bool critical) override
    {
        Player* player = Owner(spell->GetCaster());
        SpellInfo const* info = spell->GetSpellInfo();
        if (!player || !target || miss != SPELL_MISS_NONE || info->SpellFamilyName != 32 || Derived(info))
            return;
        uint32 id = info->Id;
        bool old = State(player).event;
        State(player).event = true;
        if (player != target && !player->IsFriendlyTo(target))
        {
            if (id == 800507 && damage && player->HasAura(503584))
                Cast(player, player, 503585);
            if (Any(info, {680220, 801127, 800497, 680703}))
                Stars(player, target, (Named(info, 680703) && player->HasAura(680708)) ? 2 : 1);
            if (Named(info, 680220) && spell->GetScriptValue(800386))
                Stars(player, target, 2);
            if (Named(info, 801978) && spell->GetScriptValue(800386) && player->HasAura(500205))
                Cast(player, target, 561122);
            if (Named(info, 800496))
                Mana(player, player->GetMaxPower(POWER_MANA) / 10 + 20, 562714);
            if (Named(info, 801181))
                Mana(player, player->GetMaxPower(POWER_MANA) / 50, 805989);
            if (Named(info, 805508))
                Warden(player, target);
            if (Named(info, 680703) && player->HasAura(680711))
            {
                Cast(player, target, 680710);
                if (target->HasAura(680710, player->GetGUID()))
                    Cast(player, player, 680713);
            }
            if (Named(info, 801127) && critical && player->HasAura(680725))
                Stars(player, target);
            if (Any(info, {801132, 574165}) && player->HasAura(706574))
                Cast(player, target, 805566);
            if (Named(info, 801972))
            {
                if (player->HasAura(503779))
                    Cast(player, player, 503780);
                if (player->HasAura(504004))
                    Cast(player, target, 504005);
            }
            if (Named(info, 801978))
            {
                if (player->HasAura(504006))
                    Cast(player, target, 680811);
                if (!old && Chance(player, 704740))
                    Cast(player, target, Highest(player, 680220));
            }
            if (Named(info, 680220) && player->HasAura(520481))
                Cast(player, target, 805548);
            if (Named(info, 800497) && player->HasAura(520481))
                Reduce(player, 520481, 2000);
            if (Any(info, {680220, 800497}) && player->HasAura(801975))
                Stars(player, target);
            if (Named(info, 800506) && player->HasAura(704784))
                Stars(player, target), Mana(player, player->GetMaxPower(POWER_MANA) / 5, 805543);
            if (id == 805563 && damage && critical && player->HasAura(707635))
            {
                Copy(player, target, 807672, damage * 40 / 100);
                Copy(player, target, 807672, damage * 20 / 100);
            }
            if (id == 805563 && !old && Chance(player, 807160))
            {
                Reduce(player, 805563, INT32_MAX);
                if (!spell->IsTriggered())
                    Mana(player, std::max(0, spell->GetPowerCost()), 807568);
            }
            if (Named(info, 801127))
                if (Aura* aura = player->GetAura(704171); aura && aura->GetScriptValue(704171))
                {
                    Cast(player, player, 805436);
                    uint64 uses = aura->GetScriptValue(704171) - 1;
                    aura->SetScriptValue(704171, uses);
                    if (!uses)
                        aura->Remove();
                }
        }
        if (healing)
        {
            if (Named(info, 575039) && player->HasAura(704741))
            {
                uint32 remaining = 5;
                for (Unit* enemy : Nearby(target, 15))
                    if (player->IsValidAttackTarget(enemy))
                    {
                        Stars(player, enemy);
                        if (!--remaining)
                            break;
                    }
            }
            if ((Any(info, {801990, 574328}) && player->HasAura(800504)) ||
                (Any(info, {575030, 801987}) && critical && player->HasAura(704725)))
                Cast(player, target, 574154);
            if (Any(info, {801990, 574328}) && player->HasAura(300237))
                Copy(player, target, 524703, healing / 10);
        }
        State(player).event = old;
    }
    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = Owner(caster);
        if (!player || info->SpellFamilyName != 32)
            return;
        uint32 id = info->Id;
        if (Named(info, 680220))
            MarkedHeal(player);
        if (Named(info, 801972) && player->HasAura(704764))
            for (uint32 root : {801987, 575030, 801231})
                Reduce(player, root, root == 801987 ? 3000 : 2000);
        if (!spell->IsTriggered() && Named(info, 801978) && Chance(player, 707639))
        {
            Cast(player, player, 803573);
            if (Aura* aura = player->GetAura(803573))
            {
                aura->SetMaxDuration(5000);
                aura->SetDuration(5000);
            }
        }
        if (Named(info, 805508))
        {
            if (player->HasAura(680212))
                Cast(player, spell->m_targets.GetUnitTarget(), 680213);
            if (player->HasAura(805437))
            {
                player->RemoveAurasDueToSpell(805436);
                Cast(player, player, 704171);
            }
            if (player->HasAura(806738))
                Cast(player, player, 806739);
        }
        if (id == 804652 && player->HasAura(560951))
            Cast(player, player, 574327);
        if (id == 801975)
            player->RemoveAurasDueToSpell(803573);
        if (spell->GetScriptValue(800386))
        {
            if (Named(info, 575030))
            {
                Reduce(player, 575030, INT32_MAX);
                for (Unit* enemy : Nearby(player, 30))
                    if (player->IsValidAttackTarget(enemy) && player->IsInCombatWith(enemy))
                        StartConsume(player, enemy);
            }
            if (id == 574328)
                Mana(player, std::max(0, spell->GetPowerCost()), 574329), GainPhase(player);
        }
        if (id == 572784)
        {
            for (Unit* ally : Nearby(player, 40))
                if (player->IsValidAssistTarget(ally) && (ally == player || player->IsInRaidWith(ally)))
                    Cast(player, ally, 574154);
            if (player->HasAura(707637))
                Reduce(player, 801987, INT32_MAX);
        }
        if (id == 807741)
            Cast(player, player, 807722);
        if (id == 680822)
        {
            Unit* target = spell->m_targets.GetUnitTarget();
            if (target && target != player)
            {
                Cast(player, target, 531756);
                if (player->IsValidAttackTarget(target))
                    Cast(player, target, 531757);
            }
            Cast(player, player, 680847);
        }
        if (id == 524636 && player->HasAura(680812))
        {
            Unit* target = spell->m_targets.GetUnitTarget();
            if (!target)
                target = player;
            std::vector<uint32> remove;
            for (auto const& pair : target->GetAppliedAuras())
                if (!pair.second->IsPositive() && pair.second->GetBase()->GetSpellInfo()->Dispel != DISPEL_NONE)
                    remove.push_back(pair.second->GetBase()->GetId());
            for (uint32 aura : remove)
                target->RemoveAurasDueToSpell(aura);
        }
        if (Named(info, 680703) && player->HasAura(680770))
            Reduce(player, 680703, 5000);
        if (!spell->IsTriggered() && Named(info, 801978) && player->HasAura(704739))
        {
            if (++State(player).barrage == 3)
                State(player).barrage = 0, Cast(player, player, 572319);
        }
        if (!spell->IsTriggered())
            FinishSelected(player, spell);
    }
};
class aura_ascension_starcaller_shattered_stars : public AuraScript
{
    PrepareAuraScript(aura_ascension_starcaller_shattered_stars);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({707724, 707725}); }

    void Extend(AuraEffect const* effect)
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_STARCALLER || player != GetTarget() ||
            int32(effect->GetTickNumber()) != effect->GetTotalTicks())
            return;
        AuraEffect const* talent = player->GetAuraEffect(704771, EFFECT_0, player->GetGUID());
        if (!talent || talent->GetAmount() <= 0)
            return;
        float const length = GetSpellInfo()->Effects[EFFECT_0].CalcRadius(player);
        float const radius = sSpellMgr->AssertSpellInfo(707725)->Effects[EFFECT_0].CalcRadius(player);
        if (radius <= 0.0f)
            return;
        uint32 const segments = uint32(std::ceil(talent->GetAmount() / (2.0f * radius)));
        for (uint32 segment = 1; segment <= segments; ++segment)
        {
            float const distance = length + float(talent->GetAmount()) * segment / segments;
            Position position = player->GetPosition();
            player->MovePositionToFirstCollision(position, distance, 0.0f);
            player->CastSpell(position.GetPositionX(), position.GetPositionY(), position.GetPositionZ(), 707725, true);
        }
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_starcaller_shattered_stars::Extend,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class spell_ascension_starcaller_ability : public SpellScript
{
    PrepareSpellScript(spell_ascension_starcaller_ability);
    void Effect(SpellEffIndex index)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetSpellInfo()->Id;
        if (id == 680803)
            PreventHitDefaultEffect(index);
        if (id == 570184)
            PreventHitDefaultEffect(index);
        if (Named(GetSpellInfo(), 801132) && index == EFFECT_1 && !player->HasAura(560662))
            PreventHitDefaultEffect(index);
        if (id == 801401 && index == EFFECT_1 && !player->HasAura(560896))
            PreventHitDefaultEffect(index);
    }
    void Hit(SpellEffIndex index)
    {
        Effect(index);
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetSpellInfo()->Id;
        if (id == 572315)
        {
            PreventHitDefaultEffect(index);
            StartConsume(player, GetHitUnit());
        }
        if (id == 570184 && index == EFFECT_0)
            Mana(player,
                 std::max<int64>(0, int64(player->GetMaxPower(POWER_MANA)) - player->GetPower(POWER_MANA)) * 15 / 100,
                 id);
    }
    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_starcaller_ability::Effect, EFFECT_ALL, SPELL_EFFECT_ANY);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_starcaller_ability::Hit, EFFECT_ALL, SPELL_EFFECT_ANY);
    }
};
}
void AddSC_AscensionStarcallerAbilities()
{
    new starcaller_spells();
    RegisterSpellScript(aura_ascension_starcaller_shattered_stars);
    RegisterSpellScript(spell_ascension_starcaller_ability);
}
