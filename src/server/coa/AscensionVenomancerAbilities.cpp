/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionVenomancer.h"
#include "AscensionVenomancerData.h"
#include "DynamicObject.h"
#include "Map.h"
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
using namespace AscensionVenomancer;
bool Select(uint32 id, SpellInfo const* info)
{
    switch (id)
    {
        case 504737: case 560201: return Named(info,504342);
        case 504211: return Named(info,800870);
        case 631226: return Named(info,804961);
        case 560265: return Named(info,803193);
        case 707097: return Named(info,800926);
        case 681321: case 706032: return Named(info,800946);
        case 706272: return Any(info,{800880,504705});
        case 800906: return Any(info,{800880,504705});
        case 504341: return info != nullptr;
        case 806602: return Any(info,{804977,706962,800871});
        default: return false;
    }
}
void Finish(Player* player, Spell* spell)
{
    for (uint32 id : VenomancerFinite)
        if (uint64 generation = spell->GetScriptValue(id))
            if (Aura* aura = player->GetAura(id); aura && generation == aura->GetScriptValue(Brood))
            {
                if (id == 504737 && aura->GetCharges() > 1)
                    aura->SetCharges(aura->GetCharges()-1);
                else
                    aura->Remove();
            }
}
class venomancer_spells : public AllSpellScript
{
public:
    venomancer_spells() : AllSpellScript("venomancer_spells",
        {ALLSPELLHOOK_ON_SPELL_CHECK_CAST,ALLSPELLHOOK_ON_BEFORE_EFFECTS,ALLSPELLHOOK_ON_CAST,
         ALLSPELLHOOK_ON_CALCULATED_TARGET,ALLSPELLHOOK_ON_CRIT_CHANCE,ALLSPELLHOOK_ON_HIT_RESULT}) { }
    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        Player* player = Owner(spell->GetCaster());
        auto* info = spell->GetSpellInfo();
        if (!info->IsAffectingArea() && CrossesLair(spell->GetCaster(),spell->m_targets.GetUnitTarget()))
            result = SPELL_FAILED_LINE_OF_SIGHT;
        if (!player || spell->IsTriggered() || result != SPELL_CAST_OK)
            return;
        if (player->HasAura(800921) && info->Id != 803537)
            result = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        if (info->SpellFamilyName != 35)
            return;
        if (Spender(info) && !Count(player,Brood))
            result = SPELL_FAILED_NO_POWER;
        if (info->Id == 504705 && (!player->HasAura(807600) || Count(player,807244) < 2))
            result = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        Unit* target = spell->m_targets.GetUnitTarget();
        if (Named(info,800880) && player->HasAura(807600) && Count(player,807244) >= 2)
            result = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        if (info->Id == 800921 && (!target || target == player || !target->IsPlayer() || player->IsInCombat()))
            result = SPELL_FAILED_BAD_TARGETS;
        if (info->Id == 806217 && (!player->HasAura(806154) || !spell->m_targets.HasDst() ||
            player->GetExactDist(spell->m_targets.GetDstPos()) > 30 ||
            !player->IsWithinLOS(spell->m_targets.GetDstPos()->GetPositionX(),spell->m_targets.GetDstPos()->GetPositionY(),
                                 spell->m_targets.GetDstPos()->GetPositionZ())))
            result = SPELL_FAILED_BAD_TARGETS;
        if (info->Id == 803525 && player->IsInCombat())
            result = SPELL_FAILED_AFFECTING_COMBAT;
        if (info->Id == 804968 && !player->HasAura(Spider) && !player->HasAura(Beetle))
            result = SPELL_FAILED_ONLY_SHAPESHIFT;
    }
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || caster != player || spell->IsTriggered())
            return;
        for (uint32 id : VenomancerFinite)
            if (Select(id,info))
                if (Aura* aura = player->GetAura(id))
                {
                    if (!aura->GetScriptValue(Brood))
                        aura->SetScriptValue(Brood,++State(player).sequence);
                    spell->SetScriptValue(id,aura->GetScriptValue(Brood));
                    if (id == 806602)
                        spell->SetScriptValue(id+1,aura->GetStackAmount());
                }
        if (info->SpellFamilyName != 35)
            return;
        if (info->Id == 800848)
            if (Aura* window = player->GetAura(800848))
                spell->SetScriptValue(800848,std::max(1,window->GetDuration()));
        if (Spender(info))
        {
            uint32 marks = Count(player,Brood);
            spell->SetScriptValue(Brood,marks);
            spell->SetScriptValue(Brood+1,uint64(BroodMultiplier(marks,player->HasAura(804969) ? Amount(804969) : 0)*10000));
            Resource(player,Brood,-int32(marks));
        }
        if (Any(info,{803197,805094,803196}))
        {
            uint32 stacks = Count(player,Exposed);
            spell->SetScriptValue(Exposed,stacks);
            if (AuraEffect* effect = player->GetAuraEffect(Exposed,EFFECT_1))
                spell->SetScriptValue(Exposed+1,std::max(0,effect->GetAmount()));
            ClearExposed(player);
        }
        if (info->Id == 805097)
            if (Unit* target = spell->m_targets.GetUnitTarget())
                spell->SetScriptValue(805097,target->GetVictim() != player &&
                    !target->IsImmunedToSpellEffect(info,EFFECT_0));
        if (info->Id == 800921)
        {
            auto& state = State(player);
            state.host = spell->m_targets.GetUnitTargetGUID();
            state.exit.Relocate(*player);
            state.hostMap = player->GetMapId();
        }
    }
    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Player* player = Owner(spell->GetCaster());
        if (player && spell->GetSpellInfo()->Id == 504705 && player->HasAura(503852) && HasDispel(target,DISPEL_DISEASE))
            chance += Amount(503852);
    }
    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        Player* player = Owner(spell->GetCaster());
        auto* info = spell->GetSpellInfo();
        if (!player || !target || info->SpellFamilyName != 35 || Derived(info))
            return;
        float factor = 1;
        if (hit.damage > 0)
        {
            if (Spender(info) && spell->GetScriptValue(Brood+1))
                factor *= spell->GetScriptValue(Brood+1) / 10000.0f;
            if (hit.crit && Any(info,{800880,504705,804961}) && player->HasAura(504704) && HasDispel(target,DISPEL_POISON))
                factor *= 1 + Amount(504704) / 100.0f;
        }
        else if (hit.damage < 0)
            factor *= HealingFactor(player,target,info);
        hit.damage = int32(hit.damage * factor);
        hit.damageBeforeTakenMods = int32(hit.damageBeforeTakenMods * factor);
    }
    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = Owner(caster);
        if (!player || caster != player)
            return;
        if (Venom(info) && Chance(player,500230))
            player->EnergizeBySpell(player,525041,5,POWER_ENERGY);
        if (spell->IsTriggered())
            return;
        Finish(player,spell);
        if (!info->HasAura(SPELL_AURA_MOD_SHAPESHIFT) && Chance(player,500219))
            Cast(player,player,800861);
        if (info->SpellFamilyName != 35)
            return;
        uint32 id = info->Id;
        Unit* target = spell->m_targets.GetUnitTarget();
        if (Named(info,800946))
        {
            if (player->HasAura(504736))
                Cast(player,player,504737);
            if (player->HasAura(706007))
                Cast(player,player,572767);
            if (player->HasAura(706945))
                player->RestoreSpellCharge(Highest(player,504342));
            if (player->HasAura(680763) && target)
                Mushroom(player,*target,.125f);
        }
        if (Named(info,800902))
        {
            if (player->HasAura(503918))
                Mana(player,CalculatePct(player->GetCreateMana(),Amount(504797)));
            if (player->HasAura(681320))
            {
                Reduce(player,800946,INT32_MAX);
                Cast(player,player,681321);
            }
        }
        if (Any(info,{800946,800902}) && Chance(player,504339))
            player->RestoreSpellCharge(Highest(player,504342));
        if (id == 504352 && target != player && player->HasAura(504356))
            Cast(player,player,504352);
        if (id == 800892 && player->HasAura(300680))
            ClearExposed(player);
        if (Named(info,800871) && player->HasAura(630934))
            Cast(player,player,631226);
        if (Spender(info))
        {
            uint32 marks = uint32(spell->GetScriptValue(Brood));
            if (marks && player->HasAura(503799) && roll_chance_i(std::abs(Amount(503799))))
                Resource(player,Brood,int32(marks));
            if (marks >= 5 && player->HasAura(706270))
                player->EnergizeBySpell(player,572584,Amount(572584),POWER_ENERGY);
        }
        if (Any(info,{803193,803199}) && player->HasAura(Beetle) && Chance(player,704264))
            Summon(player,target ? target : player->GetVictim(),560989);
        if (Named(info,800880) && player->HasAura(807600))
            Cast(player,player,807244);
        if (id == 504705)
            player->RemoveAurasDueToSpell(807244);
        if (id == 800848)
        {
            if (Aura* window = player->GetAura(id))
            {
                if (uint64 duration = spell->GetScriptValue(id))
                    window->SetDuration(int32(duration));
                if (window->GetStackAmount() >= 3)
                    window->Remove();
                else
                    Reduce(player,id,INT32_MAX);
            }
        }
        if (id == 800921)
            Reduce(player,id,INT32_MAX);
        if (id == 706021)
        {
            Mana(player,CalculatePct(player->GetMaxPower(POWER_MANA),Amount(706022)));
            for (Unit* ally : Allies(player,player,40))
                ally->RemoveAurasDueToSpell(806454,player->GetGUID());
        }
        if (id == 800841 || id == 803183 || id == 804980 || id == 800912)
            if (player->HasAura(503907))
                player->RemoveMovementImpairingAuras(true);
        Refresh(player);
    }
    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool) override
    {
        Player* player = Owner(spell->GetCaster());
        auto* info = spell->GetSpellInfo();
        if (!player || !target || info->SpellFamilyName != 35 || miss != SPELL_MISS_NONE)
            return;
        if (Named(info,804961) && damage)
            Cast(player,target,800884);
        if (Spender(info) && player->HasAura(707668))
            Cast(player,target,712455);
        if (Named(info,804961) && spell->GetScriptValue(631226) && !spell->GetScriptValue(631227))
        {
            spell->SetScriptValue(631227,1);
            uint32 left = 2;
            for (Unit* enemy : Nearby(target,8))
                if (enemy != target && player->IsValidAttackTarget(enemy))
                {
                    Copy(player,enemy,504794,damage);
                    Cast(player,enemy,800884);
                    if (!--left)
                        break;
                }
        }
        if (info->Id == 805097 && spell->GetScriptValue(805097))
            ApplyVenoms(player,target);
    }
};
class spell_ascension_venomancer_ability : public SpellScript
{
    PrepareSpellScript(spell_ascension_venomancer_ability);
    bool performed = false;
    void Effect(SpellEffIndex index)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetSpellInfo()->Id;
        Unit* target = IsInTargetHook() ? GetHitUnit() : nullptr;
        if (GetSpellInfo()->Effects[index].Effect != SPELL_EFFECT_DUMMY)
            return;
        PreventHitDefaultEffect(index);
        if (!target && id != 800910 && id != 681056 && id != 806217)
            return;
        if (!target)
            target = player;
        if (performed)
            return;
        performed = true;
        if (id == 805774 && player->IsValidAttackTarget(target))
            ApplyVenoms(player,target);
        if (id == 803196)
        {
            Aura* stinger = target->GetAura(803206,player->GetGUID());
            bool ripped = stinger != nullptr;
            if (ripped)
            {
                Cast(player,target,803208);
                stinger->Remove();
                target->RemoveAurasDueToSpell(680854,player->GetGUID());
            }
            Cast(player,target,803206);
            if (Aura* added = target->GetAura(803206,player->GetGUID()))
            {
                int32 duration = added->GetMaxDuration() + int32(GetSpell()->GetScriptValue(Exposed+1));
                added->SetMaxDuration(duration);
                added->SetDuration(duration);
            }
            if (!ripped)
                Cast(player,target,803220);
        }
        if (id == 805102)
            Expose(player,15,true);
        if (id == 800892)
        {
            Cast(player,player,800960);
            if (Aura* aura = player->GetAura(800960))
                aura->SetStackAmount(15);
        }
        if (id == 704235)
        {
            Cast(player,target,706000);
            if (Aura* aura = target->GetAura(706000,player->GetGUID()))
                aura->SetDuration(Amount(704235,2));
        }
        if (Named(GetSpellInfo(),504342))
            ExtendOwned(player,target,800870,Amount(id,1));
        if (id == 680767)
            for (Unit* ally : Allies(player,player,Radius(id)))
                for (uint32 root : {800901,800899})
                    ExtendOwned(player,ally,root,Amount(id));
        if (id == 800910)
        {
            uint32 count = GetSpellInfo()->MaxAffectedTargets;
            if (player->HasAura(706956))
                count += Amount(706956,1);
            Position const* pos = GetExplTargetDest();
            for (Unit* enemy : Nearby(player,80))
                if (pos && enemy->GetExactDist(pos) <= Radius(id) && player->IsValidAttackTarget(enemy))
                {
                    Cast(player,enemy,Highest(player,804982));
                    Cast(player,enemy,Highest(player,804983));
                    if (count && !--count)
                        break;
                }
            if (pos)
                Mushroom(player,*pos);
        }
        if (id == 681056)
        {
            for (uint32 n = 0; n < 12; ++n)
                Mushroom(player,player->GetRandomPoint(*player,Radius(680764)));
            player->CastSpell(player->GetPositionX(),player->GetPositionY(),player->GetPositionZ(),681291,true);
        }
        if (id == 806217 && GetExplTargetDest())
        {
            Position pos = *GetExplTargetDest();
            player->RemoveAurasDueToSpell(806154);
            player->NearTeleportTo(pos.GetPositionX(),pos.GetPositionY(),pos.GetPositionZ(),pos.GetOrientation());
        }
    }
    void SkipSummon(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        if (performed)
            return;
        performed = true;
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetSpellInfo()->Id;
        Unit* target = GetExplTargetUnit();
        Summon(player,target,id,GetExplTargetDest());
        if (id == 504344 && target && player->HasAura(804989))
            for (uint32 n = 0; n < 3; ++n)
                Mushroom(player,target->GetNearPosition(float(n),n * 2.0943951f));
    }
    void After()
    {
        Player* player = Owner(GetCaster());
        Aura* aura = GetHitAura();
        if (!player || !aura || aura->GetCasterGUID() != player->GetGUID())
            return;
        auto* info = GetSpellInfo();
        if (Spender(info) && GetSpell()->GetScriptValue(Brood+1))
            if (AuraEffect* periodic = aura->GetEffect(EFFECT_0))
                periodic->SetAmount(int32(periodic->GetAmount() * (GetSpell()->GetScriptValue(Brood+1) / 10000.0f)));
        if (Any(info,{803197,805094}) && GetSpell()->GetScriptValue(Exposed+1))
        {
            int32 duration = aura->GetMaxDuration() + int32(GetSpell()->GetScriptValue(Exposed+1));
            aura->SetMaxDuration(duration);
            aura->SetDuration(duration);
        }
        if (uint32 stacks = uint32(GetSpell()->GetScriptValue(806603)))
        {
            int32 duration = std::max(1,CalculatePct(aura->GetMaxDuration(),100-stacks*std::abs(Amount(806602))));
            aura->SetMaxDuration(duration);
            aura->SetDuration(duration);
            aura->GetEffect(EFFECT_2)->SetAmount(int32(stacks));
            if (AuraEffect* periodic = aura->GetEffect(EFFECT_0))
            {
                periodic->CalculatePeriodic(player,true,false);
                periodic->SetPeriodicTimer(periodic->GetAmplitude());
            }
        }
    }
    void Register() override
    {
        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(m_scriptSpellId);
        if (!spellInfo)
            return;

        if (spellInfo->HasEffect(SPELL_EFFECT_DUMMY))
        {
            OnEffectHitTarget += SpellEffectFn(spell_ascension_venomancer_ability::Effect,EFFECT_ALL,SPELL_EFFECT_DUMMY);
            OnEffectHit += SpellEffectFn(spell_ascension_venomancer_ability::Effect,EFFECT_ALL,SPELL_EFFECT_DUMMY);
        }
        if (spellInfo->HasEffect(SPELL_EFFECT_SUMMON))
        {
            OnEffectHit += SpellEffectFn(spell_ascension_venomancer_ability::SkipSummon,EFFECT_ALL,SPELL_EFFECT_SUMMON);
            OnEffectHitTarget += SpellEffectFn(spell_ascension_venomancer_ability::SkipSummon,EFFECT_ALL,SPELL_EFFECT_SUMMON);
        }
        AfterHit += SpellHitFn(spell_ascension_venomancer_ability::After);
    }
};
}
void AddSC_AscensionVenomancerAbilities()
{
    new venomancer_spells();
    RegisterSpellScript(spell_ascension_venomancer_ability);
}
