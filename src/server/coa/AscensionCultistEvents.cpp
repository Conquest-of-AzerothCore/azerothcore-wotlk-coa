/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCultist.h"
#include "AscensionCultistData.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
namespace
{
using namespace AscensionCultist;
constexpr uint32 NzothTentacleSummon = 500707;
constexpr uint32 YshaarjCurse = 807632;
constexpr uint32 DespoiledGround = 805180;
bool Infusion(uint32 id)
{
    return std::find(std::begin(CultistInfusions), std::end(CultistInfusions), id) != std::end(CultistInfusions);
}
int32 ModifiedDuration(Player* player, uint32 id)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    int32 duration = info ? info->GetDuration() : 0;
    player->ApplySpellMod(id, SPELLMOD_DURATION, duration);
    return std::max(0, duration);
}
class aura_ascension_cultist_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_cultist_event);
    Player* Caster()
    {
        return Infusion(GetId()) ? Owner(GetCaster()) : Owner(GetTarget());
    }
    bool Check(ProcEventInfo& event)
    {
        Player* player = Caster();
        if (!player || !event.GetActor() || !event.GetActionTarget() || State(player).event)
            return false;
        uint32 id = GetId();
        auto* info = event.GetSpellInfo();
        auto* damage = event.GetDamageInfo();
        uint32 dealt = damage ? damage->GetDamage() : 0;
        uint32 healed = event.GetHealInfo() ? event.GetHealInfo()->GetEffectiveHeal() : 0;
        bool periodic = event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC);
        bool critical = event.GetHitMask() & PROC_HIT_CRITICAL;
        bool avoided = event.GetHitMask() & (PROC_HIT_DODGE | PROC_HIT_PARRY | PROC_HIT_MISS);
        bool automatic = event.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK);
        bool melee = automatic || (info && info->DmgClass == SPELL_DAMAGE_CLASS_MELEE);
        if (Infusion(id))
            return event.GetActionTarget() == GetTarget() && dealt;
        bool owned = Owner(event.GetActor()) == player;
        if (!owned && event.GetActionTarget() == GetTarget())
        {
            switch (id)
            {
                case 300278: return avoided && Chance(player, id);
                case 706182: return avoided;
                case 800463: return (avoided || (damage && damage->GetAbsorb())) && Chance(player, id);
                case 802043: return avoided;
                case 560715: return dealt && player->GetHealthPct() < 35 && Chance(player, id, 120000);
                case 525065: return info && (event.GetHitMask() & (PROC_HIT_DEFLECT | PROC_HIT_REFLECT));
                default: return false;
            }
        }
        if (!owned || Derived(info))
            return false;
        uint32 entry = event.GetActor()->GetEntry();
        bool tentacle = event.GetActor() != player && State(player).summons.count(event.GetActor()->GetGUID()) &&
            (entry == 50272 || entry == 501464 || entry == 500465 || entry == 50096 || entry == 500464);
        bool ability = info && !periodic;
        switch (id)
        {
            case 300280: case 301262: case 504642: return dealt && melee && critical;
            case 300286: return healed && !periodic;
            case 300300: return dealt && (periodic || (info && info->IsChanneled())) && Chance(player, id);
            case 300308: case 704527: return dealt && (periodic || (info && info->IsChanneled()));
            case 300313: return dealt && Chance(player, id);
            case 520388: return (dealt || healed) && !periodic && event.GetActor() == player &&
                Chance(player, id, 3000);
            case 500719: case 500767: return dealt && Named(info, 805573);
            case 520405: return dealt && tentacle;
            case 524887: case 525078: return dealt && Named(info, 500720);
            case 560091: case 561336: return dealt && info && (info->SchoolMask & SPELL_SCHOOL_MASK_SHADOW) && Chance(player, id);
            case 560320: return dealt && melee && Chance(player, id);
            case 572064: return event.GetTypeMask() & PROC_FLAG_KILL;
            case 574318: return dealt && melee && Count(player, Insanity) > 40;
            case 680508: return dealt && Named(info, 805116);
            case 680579: return dealt && critical;
            case 681425: case 681474: return dealt && ability && critical && event.GetActor() == player;
            case 706245: return dealt && Any(info, {800416, 800413}) && Chance(player, id);
            case 706911: return dealt && Named(info, 520332) && Chance(player, id);
            case 707640: return dealt && Named(info, 500720) && Chance(player, id);
            case 803035: case 803037: case 803082: case 803339: case 805606:
                return dealt && event.GetActor() == player && Chance(player, id);
            case 805110: return dealt && !periodic && Chance(player, id);
            case 807307: return dealt && melee && ability;
            case 255283: return dealt && critical;
            case 300295: return dealt && !State(player).covenant.IsEmpty();
            case 525307: case 706926: case 600327: case 704871: case 707749: case 707785:
                return dealt && automatic && event.GetActor() == player;
            case 680581: return dealt && Named(info, 524876);
            default: return false;
        }
    }
    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        Player* player = Caster();
        if (!player)
            return;
        bool old = State(player).event;
        State(player).event = true;
        uint32 id = GetId();
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        uint32 healing = event.GetHealInfo() ? event.GetHealInfo()->GetEffectiveHeal() : 0;
        Unit* target = event.GetActionTarget() == GetTarget() && event.GetActor() != GetTarget()
            ? event.GetActor() : event.GetActionTarget();
        if (Infusion(id))
        {
            Unit* recipient = GetTarget();
            uint32 next = GetSpellInfo()->Effects[0].MiscValue;
            uint32 count = GetSpellInfo()->Effects[0].MiscValueB;
            bool third = next && sSpellMgr->GetSpellInfo(next) && sSpellMgr->GetSpellInfo(next)->Effects[0].MiscValue == 0;
            uint32 amount = std::max(0, GetEffect(EFFECT_0)->GetAmount());
            GetAura()->Remove();
            Copy(player, recipient, 570263, amount);
            if (next && (!third || player->HasAura(807877)))
            {
                auto allies = Allies(player, recipient, 20);
                allies.remove(recipient);
                allies.remove_if([player, next](Unit* ally) { return ally->HasAura(next, player->GetGUID()); });
                uint32 chosen = 0;
                for (Unit* ally : allies)
                {
                    if (chosen++ == count)
                        break;
                    Cast(player, ally, next);
                }
            }
            State(player).event = old;
            return;
        }
        switch (id)
        {
            case 300278: case 504642:
                RestoreBlade(player);
                if (id == 504642)
                    Mana(player, CalculatePct(player->GetCreateMana(), Amount(505172, 1)));
                break;
            case 300280:
                Reduce(player, 806250, std::abs(Amount(505168)));
                Reduce(player, 500110, std::abs(Amount(505168)));
                break;
            case 300286: Cast(player, target, 301982); break;
            case 300300: Cast(player, target, 560943); break;
            case 300308:
                Resource(player, Insanity, 2);
                Reduce(player, 805572, std::abs(Amount(300605, 1)));
                Cast(player, player, 300605);
                break;
            case 300313: case 706245:
                Reduce(player, 500110, INT32_MAX);
                if (id == 300313)
                    Resource(player, Insanity, 5);
                break;
            case 301262: Cast(player, player, 600327); break;
            case 520388:
                if (damage)
                {
                    for (Unit* enemy : Nearby(target, Radius(520450)))
                        if (player->IsValidAttackTarget(enemy))
                            Copy(player, enemy, 520450, CalculatePct(damage, Amount(id)));
                }
                else
                    for (Unit* ally : Allies(player, target, Radius(520497)))
                        Copy(player, ally, 520497, CalculatePct(healing, Amount(id)));
                break;
            case 500719: case 500767: Cast(player, target, 804369); break;
            case 520405: Reduce(player, 560322, std::abs(Amount(520872))); break;
            case 524887: case 525078:
                for (Unit* ally : Allies(player, player, 40, 1))
                {
                    float flat = Amount(500748, 0, player) + .4f * player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_SHADOW) +
                                 .1f * player->GetTotalAttackPowerValue(BASE_ATTACK);
                    flat *= .5f;
                    Copy(player, ally, 500748, CalculatePct(damage, Amount(id)) + uint32(std::max(0.0f, flat)));
                }
                break;
            case 525065: Cast(player, target, 525066); break;
            case 560091: case 561336: Reduce(player, 524876, INT32_MAX); break;
            case 560320:
                Reduce(player, 806222, INT32_MAX);
                Cast(player, player, 561288);
                break;
            case 560715:
                for (uint32 n = 0; n < 3; ++n)
                    Summon(player, 397771, player->GetNearPosition(2, float(n) * 2), 10000, target);
                break;
            case 572064:
                if (player->isHonorOrXPTarget(target))
                    player->RemoveAurasDueToSpell(805801);
                break;
            case 574318: Cast(player, player, 300277); break;
            case 680508: Cast(player, target, 572046); break;
            case 680579:
                Reduce(player, 806175, std::abs(Amount(681475)));
                Reduce(player, 567524, std::abs(Amount(681475)));
                break;
            case 681425:
                Summon(player, 397771, player->GetNearPosition(2, 0), sSpellMgr->GetSpellInfo(680573)->GetDuration(), target);
                break;
            case 681474:
                Cast(player, player, 681532);
                if (Count(player, 681532) >= 5 && !player->HasAura(681794))
                    Cast(player, player, 681794);
                Refresh(player);
                break;
            case 704527: Cast(player, target, 706908); break;
            case 706182: Resource(player, Insanity, 3); break;
            case 706911:
                Summon(player, 533030, target->GetNearPosition(3, 0), 12000, target);
                break;
            case 707640: Cast(player, player, 805113); break;
            case 800463: Cast(player, player, 502133); break;
            case 802043: Cast(player, player, 572613); break;
            case 803035:
                if (target && target->IsAlive())
                    player->CastCustomSpell(DespoiledGround, SPELLVALUE_AURA_DURATION,
                        ModifiedDuration(player, YshaarjCurse), target, true);
                break;
            case 803037:
                Summon(player, 500464, player->GetNearPosition(1, 0),
                    ModifiedDuration(player, NzothTentacleSummon), target);
                break;
            case 803082: Cast(player, target, 803083); break;
            case 803339: Cast(player, player, 803340); break;
            case 805110: Cast(player, target, 806039); break;
            case 805606: Cast(player, player, 706725); break;
            case 807307:
                for (Unit* ally : Allies(player, player, Radius(807308)))
                    if (Aura* aura = ally->GetAura(805801, player->GetGUID()))
                        aura->SetDuration(std::max(0, aura->GetDuration() - std::abs(Amount(807308))));
                break;
            case 255283: Copy(player, player, 680769, CalculatePct(damage, Amount(255283, 2))); break;
            case 300295:
                if (Unit* ally = ObjectAccessor::GetUnit(*player, State(player).covenant);
                    ally && ally->IsAlive() && ally->GetAura(500751, player->GetGUID()) && player->IsWithinDistInMap(ally, 100))
                {
                    uint32 amount = CalculatePct(damage, Amount(300295) + (player->HasAura(806384) ? Amount(806384) : 0));
                    Copy(player, ally, 500862, amount);
                }
                break;
            case 525307: case 706926:
            {
                auto allies = Allies(player, player, 40);
                allies.remove_if([player](Unit* ally) { return !ally->HasAura(BlackBlood, player->GetGUID()); });
                if (!allies.empty())
                    Copy(player, allies.front(), 500773, CalculatePct(damage, Amount(id)));
                break;
            }
            case 600327:
                for (Unit* ally : Allies(player, player, 40, 1))
                    Copy(player, ally, 302897, CalculatePct(damage, Amount(id)));
                break;
            case 680581: Copy(player, player, 680769, CalculatePct(damage, Amount(id))); break;
            case 704871: case 707749: case 707785: Copy(player, target, 707750, CalculatePct(damage, Amount(id))); break;
        }
        (void)healing;
        State(player).event = old;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_cultist_event::Check);
        OnProc += AuraProcFn(aura_ascension_cultist_event::Proc);
    }
};
}
void AddSC_AscensionCultistEvents()
{
    RegisterSpellScript(aura_ascension_cultist_event);
}
