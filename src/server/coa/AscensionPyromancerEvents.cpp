/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionPyromancer.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
namespace
{
using namespace AscensionPyromancer;
class aura_ascension_pyromancer_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_pyromancer_event);
    Player* GetOwner()
    {
        return (GetId() == 524624 || GetId() == 680378 || Named(GetSpellInfo(), 504380)) ? Owner(GetCaster())
                                                                                         : Owner(GetTarget());
    }
    bool Check(ProcEventInfo& e)
    {
        Player* player = GetOwner();
        if (!player || !e.GetActor() || !e.GetActionTarget() || State(player).event)
            return false;
        uint32 id = GetId();
        SpellInfo const* info = e.GetSpellInfo();
        bool periodic = e.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC);
        bool critical = e.GetHitMask() & PROC_HIT_CRITICAL;
        uint32 damage = e.GetDamageInfo() ? e.GetDamageInfo()->GetDamage() : 0;
        uint32 healing = e.GetHealInfo() ? e.GetHealInfo()->GetEffectiveHeal() : 0;
        bool outgoing = e.GetActor() == GetTarget() || (GetTarget() == player && Owner(e.GetActor()) == player);
        if (Derived(info) || (info && Any(info, {524623, 680366, 802173, 801687})))
            return false;
        if (!outgoing && e.GetActionTarget() == GetTarget())
        {
            if (Named(GetSpellInfo(), 504380))
                return !periodic && e.GetDamageInfo() && (damage || e.GetDamageInfo()->GetAbsorb());
            bool weapon =
                e.GetTypeMask() & (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS |
                                   PROC_FLAG_TAKEN_RANGED_AUTO_ATTACK | PROC_FLAG_TAKEN_SPELL_RANGED_DMG_CLASS);
            if (id == 680387)
                return damage && weapon;
            if (id == 706239)
                return damage &&
                       (e.GetTypeMask() &
                        (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS)) &&
                       player->HasAura(802117) && Chance(player, id);
            return false;
        }
        if (!outgoing || (!damage && !healing))
            return false;
        bool fire = info && (info->GetSchoolMask() & SPELL_SCHOOL_MASK_FIRE);
        switch (id)
        {
        case 300755:
            return damage && critical && !periodic;
        case 300757:
            return damage && fire && critical;
        case 300975:
            return damage && critical;
        case 504720:
            return damage && periodic;
        case 504733:
        case 707432:
            return healing && critical;
        case 300932:
        case 704863:
            return healing && info && Any(info, {707110, 706856});
        case 524624:
            return damage && !periodic && roll_chance_i(GetSpellInfo()->ProcChance);
        case 680378:
            return damage && !periodic;
        case 538441:
            return damage && periodic && Chance(player, id);
        case 572582:
            return damage && fire && !periodic;
        case 704275:
            return healing && critical;
        case 704800:
            return periodic && Chance(player, id);
        case 704801:
            return damage && critical && !periodic && Spender(info);
        case 704855:
            return healing && info && Any(info, {800806, 803819});
        case 706464:
            return damage && periodic;
        case 707483:
            return damage && periodic && Chance(player, id);
        case 802068:
            return damage && periodic && fire && Chance(player, id);
        case 802117:
            return damage && !periodic && info && info->SpellFamilyName == 30;
        case 805468:
            return damage && critical && info && Any(info, {800792, 801915}) && player->HasAura(704823);
        case 806736:
            return healing && critical && !periodic && Chance(player, id, 5000);
        case 807146:
            return damage && periodic && critical && info && Any(info, {800791, 805500});
        case 807400:
            return damage && !periodic && info && info->SpellFamilyName == 30;
        case 704856:
            return damage && periodic && critical && info && Any(info, {800791, 706874});
        default:
            return false;
        }
    }
    void Proc(ProcEventInfo& e)
    {
        PreventDefaultAction();
        Player* player = GetOwner();
        if (!player)
            return;
        bool old = State(player).event;
        State(player).event = true;
        uint32 id = GetId();
        uint32 damage = e.GetDamageInfo() ? e.GetDamageInfo()->GetDamage() : 0;
        uint32 healing = e.GetHealInfo() ? e.GetHealInfo()->GetEffectiveHeal() : 0;
        Unit* target =
            e.GetActionTarget() == GetTarget() && e.GetActor() != GetTarget() ? e.GetActor() : e.GetActionTarget();
        if (Named(GetSpellInfo(), 504380))
        {
            float retaliation = GetSpellInfo()->Effects[1].CalcValue(player) + player->GetStat(STAT_SPIRIT) * .1f;
            player->ApplySpellMod(id, SPELLMOD_DAMAGE, retaliation);
            Copy(player, target, 524623, uint32(std::clamp(retaliation, 0.0f, float(INT32_MAX / 2))));
        }
        switch (id)
        {
        case 300755:
            Resource(player, HeatAura, 20);
            break;
        case 300757:
            Cast(player, target, 504843);
            break;
        case 300975:
            Resource(player, HeatAura, 10);
            Mana(player, CalculatePct(player->GetCreateMana(), Amount(504878)), 504878);
            break;
        case 504720:
            Mana(player, CalculatePct(player->GetCreateMana(), Amount(505187)), 505187);
            break;
        case 504733:
            Resource(player, HeatAura, 10);
            break;
        case 707432:
            Cast(player, player, 1257670);
            break;
        case 300932:
            Cast(player, e.GetActionTarget(), 524624);
            break;
        case 704863:
            Resource(player, HeatAura, 5);
            break;
        case 524624:
            GetTarget()->CastSpell(target, 524623, true, nullptr, nullptr, player->GetGUID());
            break;
        case 680378:
            Cast(player, target, 680366);
            break;
        case 538441:
            Cast(player, player, 800103);
            if (Aura* aura = player->GetAura(800103))
            {
                aura->SetMaxDuration(Amount(538442));
                aura->SetDuration(Amount(538442));
            }
            break;
        case 572582:
            Cast(player, target, 572626);
            break;
        case 680387:
            Copy(player, target, 524623,
                 uint32(std::clamp(Amount(id, 1, player) +
                                       .05f * std::max(0, player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE)),
                                   0.0f, float(INT32_MAX / 2))));
            Resource(player, HeatAura, urand(1, 3));
            break;
        case 704275:
            Copy(player, e.GetActionTarget(), 704277, CalculatePct(healing, Amount(id)));
            break;
        case 704800:
            Cast(player, player, 503803);
            break;
        case 704801:
            Accumulate(player, target, 680962, CalculatePct(damage, 30));
            break;
        case 704855:
            Accumulate(player, e.GetActionTarget(), 807403, CalculatePct(healing, 30));
            break;
        case 706239:
            Cast(player, player, 707478);
            break;
        case 706464:
            for (Unit* ally : Allies(player, player, 40, 1))
                Copy(player, ally, 707892, CalculatePct(damage, Amount(id)));
            break;
        case 707483:
            Cast(player, target, Highest(player, 805496));
            break;
        case 802068:
            Flames(player, (e.GetHitMask() & PROC_HIT_CRITICAL) ? 2 : 1);
            break;
        case 802117:
            Cast(player, target, 802173);
            break;
        case 805468:
            ExtendOwned(player, player, 704823, std::max(0, Amount(807099)), INT32_MAX);
            break;
        case 806736:
            Cast(player, e.GetActionTarget(), 807944);
            break;
        case 807146:
            Cast(player, target, 807224);
            break;
        case 807400:
            player->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(), 807540, true);
            GetAura()->Remove();
            break;
        case 704856:
            ExtendOwned(player, target, e.GetSpellInfo()->Id, 3000, 12000);
            break;
        default:
            break;
        }
        State(player).event = old;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_pyromancer_event::Check);
        OnProc += AuraProcFn(aura_ascension_pyromancer_event::Proc);
    }
};
}
void AddSC_AscensionPyromancerEvents()
{
    RegisterSpellScript(aura_ascension_pyromancer_event);
}
