/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionPyromancer.h"
#include "AscensionPyromancerData.h"
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
using namespace AscensionPyromancer;
constexpr uint32 selected[] = {802168, 520927, 573284, 520823, 524707, 806783, 707478};
bool Select(uint32 id, SpellInfo const* info)
{
    switch (id)
    {
    case 802168:
    case 573284:
        return Any(info, {802174, 801915});
    case 520927:
        return Named(info, 805500);
    case 520823:
        return Any(info, {802107, 801905});
    case 524707:
        return Named(info, 803950);
    case 806783:
        return Any(info, {800806, 803819});
    case 707478:
        return Named(info, 800790);
    default:
        return false;
    }
}
constexpr uint32 ChargesKey = 1802168;
void Snapshot(Player* player, Spell* spell)
{
    if (spell->IsTriggered())
        return;
    for (uint32 id : selected)
        if (Select(id, spell->GetSpellInfo()))
            if (Aura* aura = player->GetAura(id))
            {
                if (!aura->GetScriptValue(802168))
                    aura->SetScriptValue(802168, ++State(player).sequence);
                spell->SetScriptValue(id, aura->GetScriptValue(802168));
                if (id == 802168 && !spell->GetScriptValue(ChargesKey))
                    spell->SetScriptValue(ChargesKey, aura->GetCharges());
            }
}
void Finish(Player* player, Spell* spell)
{
    for (uint32 id : selected)
        if (uint64 generation = spell->GetScriptValue(id))
            if (Aura* aura = player->GetAura(id); aura && generation == aura->GetScriptValue(802168))
            {
                if (id == 802168 && aura->IsUsingCharges())
                {
                    spell->m_appliedMods.erase(aura);
                    uint32 const start = uint32(spell->GetScriptValue(ChargesKey));
                    if (start > 1)
                        aura->SetCharges(start - 1);
                    else
                        aura->Remove();
                }
                else if ((id == 524707 || id == 802168) && aura->GetCharges() > 1)
                    aura->SetCharges(aura->GetCharges() - 1);
                else
                    aura->Remove();
            }
}
class pyromancer_spells : public AllSpellScript
{
  public:
    pyromancer_spells()
        : AllSpellScript("pyromancer_spells", {ALLSPELLHOOK_ON_BEFORE_EFFECTS, ALLSPELLHOOK_ON_CAST,
                                               ALLSPELLHOOK_ON_HIT_RESULT, ALLSPELLHOOK_ON_CRIT_CHANCE,
                                               ALLSPELLHOOK_ON_INTERRUPT_DURATION})
    {
    }
    void OnSpellInterruptDuration(Spell* spell, Unit*, int32& duration) override
    {
        Player* player = Owner(spell->GetCaster());
        if (player && Named(spell->GetSpellInfo(), 800808) && player->HasAura(707126))
            duration += Amount(707126, 1);
    }
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || info->SpellFamilyName != 30)
            return;
        Snapshot(player, spell);
        if (info->Id == 680369 && !spell->IsTriggered())
        {
            spell->SetScriptValue(680369, Count(player, FlamecastingAura));
            State(player).ignis = Count(player, FlamecastingAura);
            player->RemoveAurasDueToSpell(FlamecastingAura);
        }
    }
    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Player* player = Owner(spell->GetCaster());
        SpellInfo const* info = spell->GetSpellInfo();
        if (!player || !target)
            return;
        if (spell->GetScriptValue(802168))
            chance = 100;
        if (Any(info, {803950, 800806}) && player->HasAura(706877) && Burning(player, target))
            chance += Amount(706877);
    }
    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = Owner(caster);
        if (!player || info->SpellFamilyName != 30)
            return;
        uint32 id = info->Id;
        if (id == 680369)
            if (Aura* aura = player->GetAura(id))
                aura->SetScriptValue(id, spell->GetScriptValue(id));
        if (id == 800103 && player->HasAura(706894))
            Cast(player, player, 706895);
        if (spell->IsTriggered())
            return;
        if (Named(info, 800790))
        {
            if (player->HasAura(524875))
                Cast(player, player, 524874);
            if (Chance(player, 704816))
            {
                ObjectGuid guid = spell->m_targets.GetUnitTargetGUID();
                State(player).scheduler.Schedule(300ms,
                                                 [player, guid, id](TaskContext)
                                                 {
                                                     if (Unit* target = ObjectAccessor::GetUnit(*player, guid);
                                                         target && player->IsValidAttackTarget(target))
                                                         Cast(player, target, id);
                                                 });
            }
        }
        if (Any(info, {800792, 801915}) && player->HasAura(524875))
            Cast(player, player, 572625);
        if (id == 802119)
        {
            if (player->HasAura(573283))
                Cast(player, player, 573284);
            if (player->HasAura(704809))
                Flames(player, 5);
        }
        if (id == 680378)
            Flames(player, 5);
        if (id == 801911)
            StartDash(player);
        if (id == 520019 && player->HasAura(704824))
            Cast(player, player, 524707);
        if (Named(info, 805496) && player->HasAura(704807))
            Cast(player, player, 707483);
        if (Named(info, 802107) && player->HasAura(707493))
            Flames(player, 2);
        if (Named(info, 504380) && player->HasAura(706858) && spell->m_targets.GetUnitTarget() &&
            spell->m_targets.GetUnitTarget() != player)
            Reduce(player, 504380, std::abs(Amount(806791)));
        if (Any(info, {802174, 801915}) && player->HasAura(802780))
        {
            if (Count(player, 803712) >= 2)
            {
                State(player).earth = 0;
                player->RemoveAurasDueToSpell(803712);
                Cast(player, player, 807400);
            }
            else
                Cast(player, player, 803712);
        }
        if (Named(info, 802174))
        {
            uint32 const extra = player->HasAura(704814) ? uint32(std::max(0, Amount(704814))) : 0;
            for (auto const& pair : player->GetSpellMap())
                if (player->HasSpell(pair.first))
                {
                    uint32 percent = 5;
                    if (extra && Named(sSpellMgr->GetSpellInfo(pair.first), 802168))
                        percent += extra;
                    uint32 const delay = player->GetSpellCooldownDelay(pair.first);
                    player->ModifySpellCooldown(pair.first, -int32(CalculatePct(delay, percent)));
                }
        }
        if (spell->GetScriptValue(524707))
            Reduce(player, 803950, INT32_MAX);
        Finish(player, spell);
    }
    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32 healing, bool critical) override
    {
        Player* player = Owner(spell->GetCaster());
        SpellInfo const* info = spell->GetSpellInfo();
        if (!player || !target || miss != SPELL_MISS_NONE || info->SpellFamilyName != 30)
            return;
        uint32 id = info->Id;
        if (id == 503864)
        {
            State(player).aspectDamage = damage;
            if (damage && Chance(player, 520770))
                Cast(player, player, 520927);
            return;
        }
        if (Derived(info))
            return;
        if (id == 804076)
            Cast(player, target, 300985);
        bool old = State(player).event;
        State(player).event = true;
        if (damage)
        {
            if (Named(info, 803950))
            {
                if (player->HasAura(92124))
                    Cast(player, target, 706874);
                if (player->HasAura(704813))
                {
                    SpellInfo const* spread = sSpellMgr->GetSpellInfo(800834);
                    Spread(player, target, {805500}, spread->MaxAffectedTargets, spread->Effects[0].CalcRadius(player));
                }
                if (player->HasAura(704815) && target->GetAuraOfRankedSpell(805500, player->GetGUID()))
                    for (Unit* other : Nearby(target, sSpellMgr->GetSpellInfo(704817)->Effects[0].CalcRadius(player)))
                        if (other != target && player->IsValidAttackTarget(other))
                            Copy(player, other, 704817, CalculatePct(damage, Amount(704815)));
            }
            if (Any(info, {803950, 801905}) && player->HasAura(802170))
            {
                ExtendOwned(player, target, 805500, 3000, INT32_MAX);
                Cast(player, target, 301212);
            }
            if (Any(info, {802174, 801915}))
                Aspect(player, target, damage, spell->GetScriptValue(802168) != 0);
            if (Named(info, 802174) && Chance(player, 520770))
                Cast(player, player, 520927);
            if (Any(info, {800792, 801915}) && critical && player->HasAura(560525) && player->HasAura(704823) &&
                !spell->GetScriptValue(560525))
            {
                spell->SetScriptValue(560525, 1);
                Spread(player, target, {800791, 805500, 680962, 706874, 520826}, 1,
                       sSpellMgr->GetSpellInfo(573277)->Effects[0].CalcRadius(player));
            }
            if (Any(info, {800790, 800792, 801915}) && player->HasAura(807146))
                if (Aura* fumes = target->GetAura(807224, player->GetGUID()))
                {
                    uint32 stacks = fumes->GetStackAmount();
                    fumes->Remove();
                    Copy(player, target, 801687, stacks * Amount(801687));
                    ExtendOwned(player, target, 805500, 1000, INT32_MAX);
                }
            if (id == 802173)
            {
                if (player->HasAura(681334))
                    Cast(player, player, 681362);
                if (Chance(player, 707651))
                {
                    float percent = std::max(0, Amount(707651)) + player->GetStat(STAT_INTELLECT) * .125f;
                    Copy(player, target, 804103, uint32(std::min<double>(INT32_MAX, double(damage) * percent / 100)));
                    player->ModifyPower(
                        POWER_MANA, -int32(std::min<float>(float(INT32_MAX / 2),
                                                           Amount(707651, 1) + player->GetStat(STAT_INTELLECT) * .4f)));
                }
            }
            if (Named(info, 806611) && player->HasAura(807319) && !spell->GetScriptValue(807319))
                spell->SetScriptValue(807319, 1), Reduce(player, 806611, std::abs(Amount(807349)));
            if (Named(info, 500129))
                Cast(player, player, 503648);
            if ((info->SchoolMask & SPELL_SCHOOL_MASK_FIRE) && player->HasAura(800128) &&
                !spell->GetScriptValue(800128))
                spell->SetScriptValue(800128, 1), Cast(player, player, 800129);
        }
        if (healing)
        {
            if (Named(info, 803819) && player->HasAura(805448))
                Cast(player, target, 805474);
            if (Named(info, 800818))
            {
                if (player->HasAura(570001))
                    Flames(player);
                Aura* tender = player->GetAura(707786);
                if (!tender)
                    tender = player->GetAura(704273);
                if (tender)
                    for (Unit* ally : Allies(player, target, 10, sSpellMgr->GetSpellInfo(704274)->MaxAffectedTargets))
                        Copy(player, ally, 704274, CalculatePct(healing, Amount(tender->GetId())));
                if (player->HasAura(806747) && target->ToCreature() && AnyPet(target))
                {
                    SpellInfo const* fuel = sSpellMgr->GetSpellInfo(806749);
                    for (Unit* ally :
                         Allies(player, target, fuel->Effects[0].CalcRadius(player), fuel->MaxAffectedTargets))
                        Cast(player, ally, 806749);
                }
            }
        }
        if (id == 802120 && target != player && player->HasAura(807686))
            Mana(player, (player->GetMaxPower(POWER_MANA) - player->GetPower(POWER_MANA)) / 4);
        State(player).event = old;
    }
    bool AnyPet(Unit* target)
    {
        Player* owner = Owner(target);
        return owner && (target->GetEntry() == 50258 || target->GetEntry() == 50359);
    }
};
class spell_ascension_pyromancer_resource : public SpellScript
{
    PrepareSpellScript(spell_ascension_pyromancer_resource);
    uint32 before = 0;
    int32 flameDuration = -1;
    void Before()
    {
        if (Player* player = Owner(GetCaster()))
        {
            before = Count(player, EmberAura);
            if (Aura* aura = player->GetAura(FlamecastingAura))
                flameDuration = aura->GetDuration();
        }
    }
    void After()
    {
        if (GetSpellInfo()->Id == FlamecastingAura)
        {
            if (flameDuration >= 0)
                if (Aura* aura = GetCaster()->GetAura(FlamecastingAura))
                    aura->SetDuration(flameDuration);
            return;
        }
        if (GetSpellInfo()->Id != EmberAura)
            return;
        if (Player* player = Owner(GetCaster()))
        {
            uint32 after = Count(player, EmberAura);
            if (after > before)
                Generated(player, after - before);
            Refresh(player);
        }
    }
    void Effect(SpellEffIndex index)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        auto const& effect = GetSpellInfo()->Effects[index];
        if (effect.Effect == 175 && effect.TriggerSpell == FlamecastingAura)
        {
            PreventHitDefaultEffect(index);
            Flames(player, std::max(0, effect.MiscValue));
        }
        if (GetSpellInfo()->Id == 572381 && index == EFFECT_1)
            PreventHitDefaultEffect(index);
        if (effect.Effect == 175 && (effect.TriggerSpell == HeatAura || effect.TriggerSpell == EmberAura))
        {
            PreventHitDefaultEffect(index);
            Resource(player, effect.TriggerSpell, effect.MiscValue);
            if (GetSpellInfo()->Id == 807402)
                Mana(player, (player->GetMaxPower(POWER_MANA) - player->GetPower(POWER_MANA)) * 2 / 100, 807402);
        }
        if (GetSpellInfo()->Id == 808064)
        {
            PreventHitDefaultEffect(index);
            Resource(player, HeatAura, urand(1, 3));
        }
        if (GetSpellInfo()->Id == 807768)
        {
            PreventHitDefaultEffect(index);
            if (Player* ally = GetHitUnit() ? GetHitUnit()->ToPlayer() : nullptr)
                Mana(ally, (ally->GetMaxPower(POWER_MANA) - ally->GetPower(POWER_MANA)) / 4);
        }
    }
    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_pyromancer_resource::Before);
        AfterCast += SpellCastFn(spell_ascension_pyromancer_resource::After);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_pyromancer_resource::Effect, EFFECT_ALL, SPELL_EFFECT_ANY);
    }
};
class spell_ascension_pyromancer_ability : public SpellScript
{
    PrepareSpellScript(spell_ascension_pyromancer_ability);
    bool summoned = false, commanded = false;
    SpellCastResult Check()
    {
        uint32 id = GetSpellInfo()->Id;
        if ((id == 706854 || id == 800816) && !CanPhoenixCommand(Owner(GetCaster()), GetExplTargetUnit(), id == 706854))
            return SPELL_FAILED_NO_PET;
        return SPELL_CAST_OK;
    }
    void Effect(SpellEffIndex index)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetSpellInfo()->Id;
        if (id == 520868 && index == EFFECT_0 && IsInTargetHook() && GetHitUnit())
        {
            PreventHitDefaultEffect(index);
            Cast(player, GetHitUnit(), 1604);
            if (Aura* slow = GetHitUnit()->GetAura(1604, player->GetGUID()))
            {
                int32 duration = std::max(0, Amount(520868));
                slow->SetMaxDuration(duration);
                slow->SetDuration(duration);
            }
        }
        if (GetSpellInfo()->Effects[index].Effect == SPELL_EFFECT_SUMMON)
        {
            PreventHitDefaultEffect(index);
            if (!summoned)
            {
                summoned = true;
                Position position =
                    GetExplTargetDest() ? GetExplTargetDest()->GetPosition() : player->GetNearPosition(2, 0);
                Summon(player, GetSpellInfo()->Effects[index].MiscValue, GetSpellInfo()->Effects[index].MiscValueB,
                       position, std::max(0, GetSpellInfo()->GetDuration()));
            }
        }
        if (id == 520019 && GetHitUnit())
        {
            PreventHitDefaultEffect(index);
            Unit* target = GetHitUnit();
            uint64 total = 0;
            std::vector<uint32> consumed;
            for (auto const& pair : target->GetAppliedAuras())
            {
                Aura* aura = pair.second->GetBase();
                if (aura->GetCasterGUID() == player->GetGUID() && aura->GetSpellInfo()->SpellFamilyName == 30 &&
                    aura->GetSpellInfo()->HasAura(SPELL_AURA_PERIODIC_DAMAGE))
                    total += Remaining(aura), consumed.push_back(aura->GetId());
            }
            for (uint32 aura : consumed)
                target->RemoveAurasDueToSpell(aura, player->GetGUID());
            total = total * 2 + player->GetLevel() * urand(35, 37);
            Accumulate(player, target, 520826, uint32(std::min<uint64>(INT32_MAX, total)));
        }
        if (id == 706854 || id == 800816)
        {
            PreventHitDefaultEffect(index);
            if (!index && !commanded)
            {
                commanded = true;
                PhoenixCommand(player, GetExplTargetUnit(), id == 706854);
            }
        }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_pyromancer_ability::Check);
        OnEffectHit += SpellEffectFn(spell_ascension_pyromancer_ability::Effect, EFFECT_ALL, SPELL_EFFECT_ANY);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_pyromancer_ability::Effect, EFFECT_ALL, SPELL_EFFECT_ANY);
    }
};
}
void AddSC_AscensionPyromancerAbilities()
{
    new pyromancer_spells();
    RegisterSpellScript(spell_ascension_pyromancer_resource);
    RegisterSpellScript(spell_ascension_pyromancer_ability);
}
