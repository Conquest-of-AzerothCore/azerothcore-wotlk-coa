/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionFelsworn.h"
#include "GameObject.h"
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
using namespace AscensionFelsworn;
constexpr uint32 selected[] = {706269, 705146, 300486, 525027, 555277, 807424, 806128, 801902};
bool Select(SpellInfo const* info, uint32 aura)
{
    switch (aura)
    {
    case 706269:
    case 705146:
        return Named(info, 802060);
    case 300486:
    case 807424:
        return Named(info, 801312);
    case 525027:
        return Direct(info) || Named(info, 801904) || Twin(info);
    case 555277:
        return Named(info, 801895);
    case 806128:
        return Rush(info);
    case 801902:
        return Named(info, 801903);
    default:
        return false;
    }
}
class felsworn_casts : public AllSpellScript
{
  public:
    felsworn_casts()
        : AllSpellScript("felsworn_casts",
                         {ALLSPELLHOOK_ON_BEFORE_EFFECTS, ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_CALCULATED_TARGET,
                          ALLSPELLHOOK_ON_HIT_RESULT, ALLSPELLHOOK_ON_CALC_MAX_DURATION,
                          ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_ON_SUCCESSFUL_INTERRUPT,
                          ALLSPELLHOOK_ON_SUCCESSFUL_STEAL, ALLSPELLHOOK_ON_CRIT_CHANCE})
    {
    }
    void OnCalcMaxDuration(Aura const* aura, int32& duration) override
    {
        if (aura && aura->GetId() == 804216 && Owner(aura->GetCaster()))
            duration = 5000 * std::max(1u, Fury(aura->GetCaster()));
    }
    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        Player* player = Owner(spell->GetCaster());
        if (!player || Triggered(spell) || result != SPELL_CAST_OK)
            return;
        uint32 id = spell->GetSpellInfo()->Id;
        if (id == 804216 && !Fury(player))
            result = SPELL_FAILED_NO_POWER;
        if (id == 561216)
        {
            bool found = false;
            for (Unit* unit : Nearby(player, 15.0f))
                if (player->IsValidAttackTarget(unit) && player->CanSeeOrDetect(unit) && player->IsWithinLOSInMap(unit))
                    found = true;
            if (!found)
                result = SPELL_FAILED_BAD_TARGETS;
        }
        if (id == 807942 && player->GetPower(POWER_ENERGY) < 2)
            result = SPELL_FAILED_NO_POWER;
    }
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        if (!Triggered(spell) && !info->IsPositive() && info->DmgClass == SPELL_DAMAGE_CLASS_MAGIC &&
            !info->HasAttribute(SPELL_ATTR1_NO_REFLECTION))
            if (Aura* bane = caster->GetAura(525001); bane && Owner(bane->GetCaster()))
            {
                bool reflected = false;
                for (TargetInfo& target : *spell->GetUniqueTargetInfo())
                    if (target.targetGUID != caster->GetGUID())
                    {
                        target.missCondition = SPELL_MISS_REFLECT;
                        target.reflectResult = SPELL_MISS_NONE;
                        reflected = true;
                    }
                if (reflected)
                    bane->Remove();
            }
        for (TargetInfo& target : *spell->GetUniqueTargetInfo())
            if (target.missCondition == SPELL_MISS_NONE && target.targetGUID != caster->GetGUID())
                if (Player* victim = Owner(ObjectAccessor::GetUnit(*caster, target.targetGUID));
                    ResistDebuff(victim, info))
                    target.missCondition = SPELL_MISS_RESIST;
        Player* player = Owner(caster);
        if (!player || info->SpellFamilyName != 20)
            return;
        if (Inner(player))
            spell->SetScriptValue(804216, 1);
        if (info->Id == 803715)
            spell->SetScriptValue(800206, State(player).carveSteps);
        if (Named(info, 801312))
        {
            uint32 extra = player->HasAura(802058) ? 3 : 0;
            if (Aura* carve = player->GetAura(807424))
                extra = std::max(extra, uint32(carve->GetScriptValue(800206)));
            if (Unit* target = spell->m_targets.GetUnitTarget())
                for (Unit* enemy : Nearby(target, 10.0f))
                    if (extra && enemy != target && player->IsValidAttackTarget(enemy) &&
                        target->IsWithinLOSInMap(enemy))
                    {
                        spell->AddUnitTargetForScript(enemy, 1);
                        --extra;
                    }
        }
        if (info->Id == 805243 && player->HasAura(800220))
        {
            float radius = info->Effects[0].CalcRadius(player);
            for (Unit* ally : Nearby(player, radius))
                if (player->IsFriendlyTo(ally))
                    spell->AddUnitTargetForScript(ally, 7);
        }
        if (!Triggered(spell) && Spender(info))
        {
            uint32 energy = player->GetPower(POWER_ENERGY) + std::max(0, spell->GetPowerCost());
            uint32 bonus = player->HasAura(300489) ? energy / 10 * std::max(1, Amount(300489, 1)) : 0;
            spell->SetScriptValue(300489, uint64(State(player).spenderCrit) + 1);
            State(player).spenderCrit = bonus;
        }
        if (SpenderImpact(info))
            spell->SetScriptValue(560087, State(player).spenderCrit);
        if (Triggered(spell))
            return;
        if (info->Id == 804216)
            spell->SetScriptValue(800058, Fury(player));
        for (uint32 sid : selected)
            if (Select(info, sid))
                if (Aura* aura = player->GetAura(sid))
                    spell->SetScriptValue(sid, aura->GetScriptValue(800058));
        if (player->CanCastDuringChannel(info))
            spell->SetScriptValue(800355, std::max(0, spell->GetPowerCost()));
    }
    void OnSpellCritChance(Spell* spell, Unit*, float& chance) override
    {
        SpellInfo const* info = spell->GetSpellInfo();
        if (Owner(spell->GetCaster()) && SpenderImpact(info) && info->IsCritCapable() &&
            !info->HasAttribute(SPELL_ATTR2_CANT_CRIT))
            chance += float(spell->GetScriptValue(560087));
    }
    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        Player* player = Owner(spell->GetCaster());
        SpellInfo const* info = spell->GetSpellInfo();
        if (!player || !target || hit.damage <= 0 || hit.missCondition != SPELL_MISS_NONE || Derived(info))
            return;
        if (Direct(info))
            if (Aura* aura = player->GetAura(803904))
                if (uint64 charges = aura->GetScriptValue(803904))
                {
                    hit.crit = true;
                    aura->SetScriptValue(803904, charges - 1);
                    Unit::DealDamage(player, player, player->CountPctFromMaxHealth(5), nullptr, NODAMAGE,
                                     SPELL_SCHOOL_MASK_NORMAL, nullptr, false);
                    if (charges == 1)
                        aura->Remove();
                }
        float factor = 1;
        if (info->Id == 803715 && player->HasAura(805236) && hit.crit)
            factor *= 1.0f + .03f * std::min<uint64>(10, spell->GetScriptValue(800206));
        if (Named(info, 801312))
        {
            uint32 index = 0;
            for (auto const& row : *spell->GetUniqueTargetInfo())
            {
                if (row.targetGUID == target->GetGUID())
                    break;
                if (row.effectMask & 1)
                    ++index;
            }
            factor *= std::max(.20f, 1.0f - .10f * index);
        }
        hit.damage = int32(hit.damage * factor);
        hit.damageBeforeTakenMods = int32(hit.damageBeforeTakenMods * factor);
    }
    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        if (!Triggered(spell))
            for (auto const& pair : caster->GetAppliedAuras())
                if (Aura* aura = pair.second->GetBase(); aura->GetId() == 712483 && Owner(aura->GetCaster()))
                {
                    uint64 count = std::min<uint64>(30, aura->GetScriptValue(712483) + 1);
                    aura->SetScriptValue(712483, count);
                    aura->SetStackAmount(std::max<uint64>(1, count));
                }
        Player* player = Owner(caster);
        if (!player || info->SpellFamilyName != 20 || Triggered(spell))
            return;
        auto talent = [player](uint32 passive, uint32 child) {
            if (player->HasAura(passive))
                Cast(player, player, child);
        };
        for (uint32 sid : selected)
            if (uint64 sequence = spell->GetScriptValue(sid))
                if (Aura* aura = player->GetAura(sid); aura && aura->GetScriptValue(800058) == sequence)
                    aura->Remove();
        if (uint64 previous = spell->GetScriptValue(300489))
            State(player).spenderCrit = uint32(previous - 1);
        if (uint32 refund = spell->GetScriptValue(800355))
            player->EnergizeBySpell(player, 800355, refund, POWER_ENERGY);
        if (Spender(info))
        {
            talent(807431, 521234);
            if (player->HasAura(520240))
                for (uint32 root : {705129, 800209, 805239})
                    Reduce(player, root, 500);
            if (Inner(player) && player->HasAura(560637) &&
                (Named(info, 801895) || Named(info, 520236) || info->Id == 705121))
                Cast(player, player, 521243);
        }
        if (info->Id == 804216)
        {
            player->RemoveAurasDueToSpell(800058);
            player->RemoveAurasDueToSpell(803468);
            player->RemoveAurasDueToSpell(803465);
            if (spell->GetScriptValue(800058) >= 6)
                talent(520257, 520258);
            Refresh(player);
        }
        if (Named(info, 705129) && player->HasAura(300468) && !player->HasAura(524635))
        {
            Cast(player, player, 300469);
            Cast(player, player, 524635);
        }
        if (info->Id == 803904)
            talent(560838, 555277);
        if (Rush(info))
        {
            talent(704360, 524633);
            talent(524947, 525027);
            talent(707513, 525042);
            talent(705141, 705142);
            talent(520805, 520806);
            if (player->HasAura(705135))
                Reduce(player, 800204, std::abs(Amount(680318)));
            if (info->Id == 500610)
                Gain(player, 1);
        }
        if (Named(info, 800204))
            talent(705141, 705143);
        if (Named(info, 801904))
            talent(560645, 560646);
        if ((Named(info, 801895) || Named(info, 520236)) && player->HasAura(560840))
            if (++State(player).ruin % 3 == 0)
                Summon(player,
                       spell->m_targets.HasDst() ? Position(*spell->m_targets.GetDstPos()) : player->GetPosition(),
                       false);
        if (player->HasAura(704374) && (Named(info, 801901) || Named(info, 801312)))
        {
            Cast(player, player, 707518);
            if (Aura* aura = player->GetAura(707518); aura && aura->GetStackAmount() >= 3)
            {
                aura->Remove();
                Gain(player, 1);
            }
        }
        if (info->Id == 560284)
            Summon(player, spell->m_targets.HasDst() ? Position(*spell->m_targets.GetDstPos()) : player->GetPosition(),
                   Inner(player));
    }
    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool crit) override
    {
        if (!target)
            return;
        SpellInfo const* info = spell->GetSpellInfo();
        Player* player = Owner(spell->GetCaster());
        if (!player || miss != SPELL_MISS_NONE)
            return;
        if (target == player)
        {
            uint32 generated = info->Id == 800058 ? 1 : 0;
            for (auto const& effect : info->Effects)
                if (effect.Effect == 175 && effect.TriggerSpell == 800058 && effect.MiscValue > 0)
                    generated += effect.MiscValue;
            Generated(player, generated);
        }
        if (Bane(info) && info->Id != 704368 && !Named(info, 704368) && target != player &&
            !player->IsFriendlyTo(target) && !spell->GetScriptValue(800059))
        {
            spell->SetScriptValue(800059, 1);
            Gain(player, 1);
        }
        if (info->Id == 704371 && player->HasAura(560641))
            Cast(player, target, 704397);
        if (Named(info, 801904) && Inner(player) && target != player && !player->IsFriendlyTo(target))
            Cast(player, player, 803089);
        if (!damage || target == player || player->IsFriendlyTo(target))
            return;
        if (Named(info, 801312))
        {
            if (spell->GetScriptValue(804216) && player->HasAura(92088))
                Cast(player, target, 802678);
            if (player->HasAura(802058))
                Cast(player, player, 524632);
        }
        if (Named(info, 802060))
            Cast(player, player, 521213);
        if (Named(info, 802060) && spell->GetScriptValue(804216))
            Copy(player, target, 803467, damage);
        if (Named(info, 801895) && spell->GetScriptValue(804216))
            CopyDot(player, target, 805748, uint64(damage) * 30 / 100);
        if (info->Id == 712399 && spell->GetScriptValue(804216))
            Cast(player, target, 803477);
        if (Named(info, 520236) && spell->GetScriptValue(804216))
        {
            uint64 count = spell->GetScriptValue(520832) + 1;
            spell->SetScriptValue(520832, count);
            if (count == 5)
                for (auto const& row : *spell->GetUniqueTargetInfo())
                    if (row.processed && row.missCondition == SPELL_MISS_NONE && row.damage > 0)
                        if (Unit* enemy = ObjectAccessor::GetUnit(*player, row.targetGUID))
                            Cast(player, enemy, 520832);
            if (count > 5)
                Cast(player, target, 520832);
        }
        if (Twin(info) && Direct(info))
        {
            if (crit && player->HasAura(801892))
                Gain(player, 1);
            if (Aura* aura = player->GetAura(807163))
            {
                Gain(player, 1);
                uint64 remaining = aura->GetScriptValue(807163);
                if (remaining > 1)
                    aura->SetScriptValue(807163, remaining - 1);
                else
                    aura->Remove();
            }
        }
        if (crit && Direct(info) && player->HasAura(801235) && !State(player).event)
        {
            Cast(player, player, 555276);
            if (Aura* aura = player->GetAura(555276); aura && aura->GetStackAmount() >= 3)
            {
                aura->Remove();
                Cast(player, player, 555277);
            }
        }
    }
    void OnSpellSuccessfulInterrupt(Spell* spell, Unit* target) override
    {
        if (Player* player = Owner(spell->GetCaster()); player && spell->GetSpellInfo()->Id == 800203)
            Cast(player, target, 804809);
    }
    void OnSpellSuccessfulSteal(Spell* spell, Unit* target, uint32) override
    {
        if (Player* player = Owner(spell->GetCaster()); player && spell->GetSpellInfo()->Id == 800353)
            Cast(player, target, 806062);
    }
};

class spell_ascension_felsworn_ability : public SpellScript
{
    PrepareSpellScript(spell_ascension_felsworn_ability);
    void Hit(SpellEffIndex effect)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetSpellInfo()->Id;
        if (id == 807942)
        {
            PreventHitDefaultEffect(effect);
            uint32 spent = player->GetPower(POWER_ENERGY) / 2 * 2;
            player->ModifyPower(POWER_ENERGY, -int32(spent));
            HealInfo heal(player, player, player->CountPctFromMaxHealth(spent / 2), GetSpellInfo(),
                          GetSpellInfo()->GetSchoolMask());
            player->HealBySpell(heal);
        }
        if (id == 705121)
        {
            PreventHitDefaultEffect(effect);
            ObjectGuid guid = player->GetGUID();
            uint32 map = player->GetMapId();
            uint32 phase = player->GetPhaseMask();
            uint32 bonus = uint32(GetSpell()->GetScriptValue(560087));
            for (uint32 index = 0; index < 3; ++index)
            {
                float const distance = 4.0f + 7.0f * index;
                Position position = player->GetPosition();
                if (player->IsInWater())
                {
                    position.RelocateOffset(Position(distance, 0, 0, 0));
                    Acore::NormalizeMapCoord(position.m_positionX);
                    Acore::NormalizeMapCoord(position.m_positionY);
                }
                else
                    position = player->GetNearPosition(distance, 0);
                State(player).scheduler.Schedule(
                    Milliseconds(index * 300), [guid, position, map, phase, bonus](TaskContext) {
                        Player* player = ObjectAccessor::FindPlayer(guid);
                        if (player && player->IsInWorld() && player->IsAlive() && player->GetMapId() == map &&
                            player->GetPhaseMask() == phase)
                        {
                            uint32 previous = State(player).spenderCrit;
                            State(player).spenderCrit = bonus;
                            player->CastSpell(position.GetPositionX(), position.GetPositionY(), position.GetPositionZ(),
                                              712399, true);
                            State(player).spenderCrit = previous;
                            player->CastSpell(position.GetPositionX(), position.GetPositionY(), position.GetPositionZ(),
                                              556503, true);
                        }
                    });
            }
            if (player->HasAura(803478))
                for (uint32 delay : {2000, 4000})
                    State(player).scheduler.Schedule(Milliseconds(delay), [guid, map, phase](TaskContext) {
                        Player* player = ObjectAccessor::FindPlayer(guid);
                        if (player && player->IsInWorld() && player->IsAlive() && player->GetMapId() == map &&
                            player->GetPhaseMask() == phase)
                            Cast(player, player, 804600);
                    });
        }
    }
    void SummonHit(SpellEffIndex effect)
    {
        if (Player* player = Owner(GetCaster()))
        {
            PreventHitDefaultEffect(effect);
            Summon(player, GetExplTargetDest() ? Position(*GetExplTargetDest()) : player->GetPosition(),
                   GetSpellInfo()->Id == 572183 && Inner(player));
        }
    }
    void ExtendInnerDemon(SpellEffIndex effect)
    {
        PreventHitDefaultEffect(effect);
        if (Player* player = Owner(GetCaster()))
            Extend(player, GetEffectValue());
    }
    void Register() override
    {
        SpellInfo const* info = sSpellMgr->GetSpellInfo(m_scriptSpellId);
        if (info->Id == 572163 || info->Id == 572183)
            OnEffectHit += SpellEffectFn(spell_ascension_felsworn_ability::SummonHit, EFFECT_0, SPELL_EFFECT_SUMMON);
        if (info->Id == 807942 || info->Id == 705121)
            OnEffectHitTarget += SpellEffectFn(spell_ascension_felsworn_ability::Hit, EFFECT_0, SPELL_EFFECT_DUMMY);
        if (info->Id == 803089)
            OnEffectHitTarget += SpellEffectFn(spell_ascension_felsworn_ability::ExtendInnerDemon, EFFECT_0,
                                               SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION);
    }
};
class spell_ascension_felsworn_chaos_rush : public SpellScript
{
    PrepareSpellScript(spell_ascension_felsworn_chaos_rush);

    void Surge(SpellEffIndex effect)
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player)
            return;
        bool moving = player->HasUnitMovementFlag(MOVEMENTFLAG_FORWARD | MOVEMENTFLAG_BACKWARD |
                                                    MOVEMENTFLAG_STRAFE_LEFT | MOVEMENTFLAG_STRAFE_RIGHT);
        if (!moving)
            return;
        float distance = GetSpellInfo()->Effects[EFFECT_0].CalcRadius(player);
        if (distance <= 0.0f)
            return;
        float rate = player->GetSpeedRate(MOVE_RUN);
        float speed = player->GetSpeed(MOVE_RUN);
        if (speed <= 0.0f || speed >= SPEED_CHARGE)
            return;
        PreventHitDefaultEffect(effect);
        auto& state = State(player);
        state.rushSurgeRate = rate * SPEED_CHARGE / speed;
        state.rushSurgeMs = uint32(1000.0f * distance / SPEED_CHARGE);
        player->SetSpeed(MOVE_RUN, state.rushSurgeRate, true);
    }
    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_felsworn_chaos_rush::Surge, EFFECT_0, SPELL_EFFECT_CHARGE_DEST);
    }
};
}
void AddSC_AscensionFelswornAbilities()
{
    new felsworn_casts();
    RegisterSpellScript(spell_ascension_felsworn_ability);
    RegisterSpellScript(spell_ascension_felsworn_chaos_rush);
}
