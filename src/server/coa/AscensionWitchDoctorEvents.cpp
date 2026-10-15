/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchDoctorCompletion.h"
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
using namespace AscensionWitchDoctor;
bool Damage(ProcEventInfo const& event)
{
    return event.GetDamageInfo() && event.GetDamageInfo()->GetDamage();
}
bool Periodic(ProcEventInfo const& event)
{
    SpellInfo const* info = event.GetSpellInfo();
    return (event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC)) ||
           (info && info->Id == PuppetHit);
}
bool Derived(SpellInfo const* info)
{
    if (!info)
        return false;
    switch (info->Id)
    {
        case ThreadsDamage:
        case BottleDamage:
        case LoaEchoHeal:
        case WaveHeal:
        case DevotionHeal:
        case ThistleHeal:
        case ConcoctionsHeal:
        case FrenzyHeal:
        case StringsDamage:
        case GuileDamage:
        case Spirit:
            return true;
        default:
            return false;
    }
}

class aura_ascension_witch_doctor_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_witch_doctor_event);
    bool _executing = false;

    bool Check(ProcEventInfo& event)
    {
        if (_executing || !event.GetActionTarget())
            return false;
        uint32 id = GetId();
        bool outgoing = event.GetActor() == GetTarget();
        SpellInfo const* info = event.GetSpellInfo();
        bool damage = Damage(event);
        bool healing = event.GetHealInfo() && event.GetHealInfo()->GetEffectiveHeal();
        bool periodic = Periodic(event);
        bool critical = event.GetHitMask() & PROC_HIT_CRITICAL;
        if (id == Crystal)
            return event.GetActionTarget() == GetTarget() && healing;
        if (id == PotionThistle || id == SplashThistle)
            return outgoing && damage && !Derived(info);
        Player* player = Owner(GetTarget());
        if (!player || player != GetTarget() || !outgoing)
            return false;
        if (Derived(info) && id != Overflow)
            return false;
        switch (id)
        {
            case Puppeteer:
                return damage && event.GetActionTarget() != player &&
                       (event.GetActionTarget()->HasAura(Threads, player->GetGUID()) || (info && !periodic));
            case LoaSpiritsOne:
            case LoaSpiritsTwo:
            case MojoMadness:
                return damage || healing;
            case Traditionalist:
            case GrowingMalice:
            case HexfireMass:
                return damage && periodic && IsHex(info);
            case Eye:
            case Hexplosion:
                return damage && critical;
            case UmbralTalent:
                return damage && (!info || info->Id != Umbral) &&
                       (event.GetTypeMask() &
                        (PROC_FLAG_DONE_RANGED_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS)) &&
                       roll_chance_f(GetSpellInfo()->ProcChance + player->GetRatingBonusValue(CR_CRIT_RANGED));
            case Malignant:
                return damage && (IsJuju(info) || Family(info, 1, 262144));
            case Overflow:
                return damage && info && (info->Id == PuppetHit || info->Id == ThreadsDamage);
            case MaliciousGolems:
                return damage && ((periodic && IsHex(info)) || (info && info->Id == PuppetHit));
            case HollowSpirit:
                return damage &&
                       (Family(info, 0, 4) || Family(info, 1, 262144) || (info && info->Id == ShadowflareHit));
            case Berserking:
            case Voice:
                return damage && periodic;
            case HexOfDeath:
                return damage && IsArrow(info);
            case OtherSide:
                return damage && info && info->Id == PuppetHit;
            case Devotion:
                return damage && !periodic;
            case Frenzy:
                return damage;
            default:
                return false;
        }
    }

    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        _executing = true;
        Player* player = Owner(GetTarget());
        Unit* target = event.GetActionTarget();
        Unit* owner = GetTarget();
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        auto buff = [owner](uint32 spell) { Cast(owner, owner, spell); };
        switch (GetId())
        {
            case Puppeteer:
            {
                Aura* aura = target->GetAura(Threads, owner->GetGUID());
                if (!aura)
                    aura = owner->AddAura(Threads, target);
                if (aura)
                    if (AuraEffect* stored = aura->GetEffect(EFFECT_0))
                        stored->ChangeAmount(int32(std::min<uint64>(
                            INT32_MAX, uint64(std::max(0, stored->GetAmount())) + uint64(damage) * 15 / 100)));
                break;
            }
            case LoaSpiritsOne:
            case LoaSpiritsTwo:
            case Traditionalist:
                GainSpirit(player);
                break;
            case MojoMadness:
                buff(MojoFree);
                break;
            case Eye:
                Cast(owner, target, EyeDebuff);
                break;
            case Hexplosion:
                buff(HasteBuff);
                break;
            case UmbralTalent:
                buff(UmbralReady);
                SyncReplacements(player);
                break;
            case Malignant:
                SpreadHex(player, target);
                break;
            case Overflow:
                Reduce(player, BadJuju, INT32_MAX);
                buff(OverflowBuff);
                break;
            case MaliciousGolems:
                Reduce(player, WarGolem, 1000);
                break;
            case HollowSpirit:
                Cast(owner, target, HollowDebuff);
                break;
            case Berserking:
                WardBuff(player, WardHaste);
                break;
            case HexOfDeath:
                Cast(owner, target, HealingDebuff);
                break;
            case Voice:
                Cast(owner, target, VoiceExplosion);
                break;
            case OtherSide:
            {
                Aura* previous = owner->GetAura(OtherSideBuff);
                int32 remaining = previous ? previous->GetDuration() : 0;
                buff(OtherSideBuff);
                if (previous)
                    if (Aura* current = owner->GetAura(OtherSideBuff))
                        current->SetDuration(remaining);
                break;
            }
            case Devotion:
                Copy(owner, owner, DevotionHeal, uint64(damage) * Amount(Devotion) / 100);
                break;
            case Frenzy:
                Copy(owner, owner, FrenzyHeal, uint64(damage) * GetEffect(EFFECT_2)->GetAmount() / 100);
                break;
            case PotionThistle:
            case SplashThistle:
            {
                Unit* caster = GetCaster();
                Copy(caster ? caster : owner, owner, ThistleHeal,
                     uint64(damage) * std::max(0, GetEffect(EFFECT_0)->GetAmount()) / 100);
                break;
            }
            case Crystal:
            {
                uint32 shield = event.GetHealInfo()->GetEffectiveHeal() / 5;
                if (AuraEffect* previous = owner->GetAuraEffect(CrystalShield, EFFECT_0, GetCasterGUID()))
                    shield += std::max(0, previous->GetAmount());
                Copy(GetCaster(), owner, CrystalShield, std::min(shield, owner->GetMaxHealth()));
                break;
            }
            case GrowingMalice:
            {
                Aura* hex = OwnedHex(player, target);
                AuraEffect* dot = hex ? hex->GetEffect(EFFECT_0) : nullptr;
                if (!dot)
                    break;
                Aura* growth = target->GetAura(GrowingDebuff, player->GetGUID());
                uint32 stacks = growth ? growth->GetStackAmount() : 0;
                uint32 percent = Amount(GrowingDebuff);
                Cast(player, target, GrowingDebuff);
                growth = target->GetAura(GrowingDebuff, player->GetGUID());
                if (growth)
                    dot->ChangeAmount(int64(dot->GetAmount()) * (100 + percent * growth->GetStackAmount()) /
                                      (100 + percent * stacks));
                break;
            }
            case HexfireMass:
                Summon(player, SerpentMass, target, target->GetPosition());
                break;
        }
        _executing = false;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_witch_doctor_event::Check);
        OnProc += AuraProcFn(aura_ascension_witch_doctor_event::Proc);
    }
};
}
void AddAscensionWitchDoctorEventScripts()
{
    RegisterSpellScript(aura_ascension_witch_doctor_event);
}
