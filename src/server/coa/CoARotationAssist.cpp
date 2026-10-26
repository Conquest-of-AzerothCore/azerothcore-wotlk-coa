/*
 * Copyright (C) 2016+ AzerothCore, GNU AGPL v3.
 * Rotation adaptation credits: mod-playerbots contributors, GPL v2 or later; docs/coa/rotation-assist.md.
 */

#include "CoARotationAssist.h"
#include "CoARotationData.h"
#include "AscensionSpecialization.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "CommandScript.h"
#include "Config.h"
#include "DisableMgr.h"
#include "Player.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "WorldPacket.h"
#include "WorldScript.h"
#include "WorldSession.h"

#include <algorithm>
#include <atomic>
#include <map>
#include <set>
#include <string>
#include <tuple>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
    using namespace CoARotationAssist;

    std::atomic<bool> Enabled = true;

    std::string SpellName(std::string_view name)
    {
        std::string result(name);
        for (char& letter : result)
            if (letter >= 'A' && letter <= 'Z')
                letter += 'a' - 'A';
        return result;
    }

    uint32 AuraStacks(Unit const* unit, std::string_view name, ObjectGuid caster = ObjectGuid::Empty)
    {
        std::string const wanted = SpellName(name);
        uint32 stacks = 0;
        for (auto const& [id, application] : unit->GetAppliedAuras())
        {
            Aura const* aura = application->GetBase();
            if ((!caster || aura->GetCasterGUID() == caster) &&
                SpellName(aura->GetSpellInfo()->SpellName[0]) == wanted)
                stacks = std::max<uint32>(stacks, aura->GetStackAmount());
        }
        return stacks;
    }

    bool HasManualEffect(SpellInfo const* info, uint8 depth = 0)
    {
        if (depth > 3)
            return true;

        for (SpellEffectInfo const& effect : info->Effects)
        {
            switch (effect.Effect)
            {
                case SPELL_EFFECT_JUMP:
                case SPELL_EFFECT_JUMP_DEST:
                case SPELL_EFFECT_CHARGE:
                case SPELL_EFFECT_CHARGE_DEST:
                case SPELL_EFFECT_LEAP:
                case SPELL_EFFECT_LEAP_BACK:
                case SPELL_EFFECT_TELEPORT_UNITS:
                case SPELL_EFFECT_TELEPORT_UNITS_FACE_CASTER:
                case SPELL_EFFECT_ATTACK_ME:
                case SPELL_EFFECT_SUMMON:
                case SPELL_EFFECT_SUMMON_PET:
                case SPELL_EFFECT_RESURRECT:
                case SPELL_EFFECT_RESURRECT_NEW:
                case SPELL_EFFECT_SELF_RESURRECT:
                case SPELL_EFFECT_CREATE_ITEM:
                case SPELL_EFFECT_CREATE_ITEM_2:
                case SPELL_EFFECT_LEARN_SPELL:
                case SPELL_EFFECT_OPEN_LOCK:
                    return true;
                default:
                    break;
            }

            if (effect.ApplyAuraName == SPELL_AURA_MOD_TAUNT ||
                effect.ApplyAuraName == SPELL_AURA_MOD_SHAPESHIFT ||
                effect.ApplyAuraName == SPELL_AURA_MOD_POSSESS || effect.ApplyAuraName == SPELL_AURA_MOD_CHARM ||
                effect.ApplyAuraName == SPELL_AURA_FORCE_MOVE_FORWARD)
                return true;

            if (effect.TriggerSpell)
                if (SpellInfo const* triggered = sSpellMgr->GetSpellInfo(effect.TriggerSpell))
                    if (HasManualEffect(triggered, depth + 1))
                        return true;
        }
        return false;
    }

    bool DealsDamage(SpellInfo const* info, uint8 depth = 0)
    {
        if (depth > 3)
            return false;

        for (SpellEffectInfo const& effect : info->Effects)
        {
            switch (effect.Effect)
            {
                case SPELL_EFFECT_SCHOOL_DAMAGE:
                case SPELL_EFFECT_WEAPON_DAMAGE:
                case SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL:
                case SPELL_EFFECT_NORMALIZED_WEAPON_DMG:
                case SPELL_EFFECT_WEAPON_PERCENT_DAMAGE:
                case SPELL_EFFECT_HEALTH_LEECH:
                case SPELL_EFFECT_POWER_BURN:
                    return true;
                default:
                    break;
            }
            if (effect.ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE ||
                effect.ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE_PERCENT ||
                effect.ApplyAuraName == SPELL_AURA_PERIODIC_LEECH)
                return true;
            if (effect.TriggerSpell)
                if (SpellInfo const* triggered = sSpellMgr->GetSpellInfo(effect.TriggerSpell))
                    if (DealsDamage(triggered, depth + 1))
                        return true;
        }
        return false;
    }

    bool Heals(SpellInfo const* info, uint8 depth = 0)
    {
        if (depth > 3)
            return false;
        for (SpellEffectInfo const& effect : info->Effects)
        {
            if (effect.Effect == SPELL_EFFECT_HEAL || effect.Effect == SPELL_EFFECT_HEAL_PCT ||
                effect.Effect == SPELL_EFFECT_HEAL_MAX_HEALTH || effect.ApplyAuraName == SPELL_AURA_PERIODIC_HEAL)
                return true;
            if (effect.TriggerSpell)
                if (SpellInfo const* triggered = sSpellMgr->GetSpellInfo(effect.TriggerSpell))
                    if (Heals(triggered, depth + 1))
                        return true;
        }
        return false;
    }

    bool Allowed(SpellInfo const* info, bool healing)
    {
        return info && (healing ? Heals(info) : DealsDamage(info) && !info->IsPositive() &&
            info->NeedsExplicitUnitTarget()) &&
            !info->IsPassive() && !info->IsAutoRepeatRangedSpell() &&
            !HasManualEffect(info) &&
            !(info->GetExplicitTargetMask() & (TARGET_FLAG_DEST_LOCATION | TARGET_FLAG_ITEM |
                TARGET_FLAG_TRADE_ITEM | TARGET_FLAG_GAMEOBJECT | TARGET_FLAG_GAMEOBJECT_ITEM));
    }

    bool Ready(Player* player, Unit* target, SpellInfo const* info, bool healing)
    {
        if (!Allowed(info, healing) || !player->HasActiveSpell(info->Id) ||
            sDisableMgr->IsDisabledFor(DISABLE_TYPE_SPELL, info->Id, player) ||
            (healing && target != player && !info->NeedsExplicitUnitTarget()))
            return false;

        if (healing && info->IsPositive())
            if (SpellInfo const* ranked = info->GetAuraRankForLevel(target->GetLevel()))
                info = ranked;

        Spell probe(player, info, TRIGGERED_NONE);
        SpellCastTargets targets;
        targets.SetUnitTarget(target);
        probe.InitExplicitTargets(targets);
        probe.m_cast_count = 1;
        probe.LoadScripts();
        SpellCastResult const result = probe.CheckPetCast(target);
        bool const movementBlocked = player->isMoving() &&
            (info->IsChanneled() || info->CalcCastTime(player, &probe)) &&
            (info->InterruptFlags & SPELL_INTERRUPT_FLAG_MOVEMENT) &&
            !player->HasManastormMovementGrace() && !player->CanCastSpellWhileMoving(info);
        player->RestoreSpellMods(&probe);
        return result == SPELL_CAST_OK && !movementBlocked;
    }

    float Observe(Player* player, Unit* target, Rule const& rule)
    {
        switch (rule.When)
        {
            case RuleCondition::MissingDebuff:
            case RuleCondition::TargetAura:
                return AuraStacks(target, rule.Argument);
            case RuleCondition::HasAura:
            case RuleCondition::MissingAura:
            case RuleCondition::AuraStacks:
                return AuraStacks(player, rule.Argument);
            case RuleCondition::TargetHealth:
                return target->GetHealthPct();
            case RuleCondition::SelfHealth:
                return player->GetHealthPct();
            case RuleCondition::Mana:
                return player->GetMaxPower(POWER_MANA) ? player->GetPowerPct(POWER_MANA) : 100.0f;
            case RuleCondition::Resource:
            {
                Powers const power = rule.Argument == "energy" ? POWER_ENERGY : POWER_RUNIC_POWER;
                return player->HasActivePowerType(power) ? player->GetPowerPct(power) : 0.0f;
            }
            case RuleCondition::Ready:
                return 0;
        }
        return 0;
    }
}

namespace CoARotationAssist
{
    uint32_t ChooseSpell(Player* player, Unit* target, bool healing)
    {
        std::map<std::string, SpellInfo const*> learned;
        for (auto const& [id, state] : player->GetSpellMap())
        {
            if (!player->HasActiveSpell(id))
                continue;
            SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
            if (!info || info->IsPassive())
                continue;
            SpellInfo const*& best = learned[SpellName(info->SpellName[0])];
            if (!best || std::tuple(sSpellMgr->GetSpellRank(info->Id), info->SpellLevel, info->Id) >
                std::tuple(sSpellMgr->GetSpellRank(best->Id), best->SpellLevel, best->Id))
                best = info;
        }

        std::set<uint32> checked;
        auto usable = [&](SpellInfo const* learnedInfo, bool fallback)
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(player->GetCastReplacement(learnedInfo->Id));
            if (!Allowed(info, healing) ||
                (fallback && (std::max(info->RecoveryTime, info->CategoryRecoveryTime) > 15000 ||
                info->IsAffectingArea())) || !checked.insert(info->Id).second)
                return uint32(0);
            if (info->HasAura(SPELL_AURA_PERIODIC_DAMAGE) || info->HasAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT) ||
                info->HasAura(SPELL_AURA_PERIODIC_LEECH) || info->HasAura(SPELL_AURA_PERIODIC_HEAL))
                if (AuraStacks(target, info->SpellName[0], player->GetGUID()))
                    return uint32(0);
            return Ready(player, target, info, healing) ? learnedInfo->Id : uint32(0);
        };

        uint32 const selected = Select(Rules, GetAscensionActiveSpecialization(player), [&](Rule const& rule)
        {
            auto const found = learned.find(SpellName(rule.Spell));
            if (found == learned.end() || (rule.SelfOnly && target != player) ||
                !Matches(rule.When, Observe(player, target, rule), rule.Threshold))
                return uint32(0);
            return usable(found->second, false);
        });
        if (selected)
            return selected;

        std::vector<SpellInfo const*> fallback;
        for (auto const& [name, info] : learned)
            fallback.push_back(info);
        std::sort(fallback.begin(), fallback.end(), [](SpellInfo const* left, SpellInfo const* right)
        {
            return std::tie(left->SpellLevel, left->Id) > std::tie(right->SpellLevel, right->Id);
        });
        for (SpellInfo const* info : fallback)
            if (uint32 const spell = usable(info, true))
                return spell;
        return 0;
    }
}

namespace
{
    using namespace CoARotationAssist;

    class RotationConfig final : public WorldScript
    {
    public:
        RotationConfig() : WorldScript("CoARotationConfig", { WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

        void OnAfterConfigLoad(bool) override
        {
            Enabled = sConfigMgr->GetOption<bool>("CoA.RotationAssist.Enable", true);
        }
    };

    class RotationCommands final : public CommandScript
    {
    public:
        RotationCommands() : CommandScript("CoARotationCommands") { }

        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable const commands =
            {
                { "rotation", HandleRotation, SEC_PLAYER, Console::No }
            };
            return commands;
        }

        static bool HandleRotation(ChatHandler* handler)
        {
            Player* player = handler->GetPlayer();
            if (!Enabled || !player)
            {
                handler->SendErrorMessage("Rotation assistance is disabled on this realm.");
                return false;
            }
            if (!player->IsInWorld() || !player->FindMap() || !player->IsAlive() || player->IsInFlight() ||
                player->m_mover != player || player->isPossessing() || player->IsCharmed() ||
                player->IsNonMeleeSpellCast(false, false, true) || player->GetCurrentSpell(CURRENT_MELEE_SPELL) ||
                !player->SpellQueue.empty())
                return true;

            Unit* target = player->GetSelectedUnit();
            if (!target || !target->IsAlive() ||
                (!player->IsValidAttackTarget(target) && !player->IsValidAssistTarget(target)))
            {
                handler->SendErrorMessage("Select a living enemy to attack or a friendly target to heal.");
                return false;
            }

            bool const healing = !player->IsValidAttackTarget(target);
            if (healing && target->GetHealth() == target->GetMaxHealth())
                return true;

            if (uint32 const spell = ChooseSpell(player, target, healing))
            {
                SpellCastTargets targets;
                targets.SetUnitTarget(target);
                WorldPacket packet(CMSG_CAST_SPELL, 32);
                packet << uint8(1) << spell << uint8(0);
                targets.Write(packet);
                player->GetSession()->HandleCastSpellOpcode(packet);
            }
            return true;
        }
    };
}

void AddCoARotationAssistScripts()
{
    new RotationConfig();
    new RotationCommands();
}
