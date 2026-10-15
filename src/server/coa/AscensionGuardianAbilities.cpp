/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionGuardianCompletion.h"
#include "EventProcessor.h"
#include "Map.h"
#include "MoveSpline.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "ThreatManager.h"
#include <algorithm>

namespace
{
class GuardianLanding : public BasicEvent
{
public:
    GuardianLanding(Player* owner, Position const& destination) : _owner(owner->GetGUID()),
        _map(owner->GetMapId()), _instance(owner->GetInstanceId()), _destination(destination) { }

    bool Execute(uint64 time, uint32) override
    {
        Player* player = ObjectAccessor::FindPlayer(_owner);
        if (!player || !player->IsAlive() || !player->IsInWorld() || player->GetMapId() != _map ||
            player->GetInstanceId() != _instance || ++_attempts > 100)
            return true;
        if (!player->movespline->Finalized())
        {
            player->m_Events.AddEvent(this, time + 50);
            return false;
        }
        if (player->GetExactDist2d(&_destination) <= 3.0f)
            player->CastSpell(_destination.GetPositionX(), _destination.GetPositionY(),
                _destination.GetPositionZ(), 802874, true);
        return true;
    }

private:
    ObjectGuid _owner;
    uint32 _map;
    uint32 _instance;
    Position _destination;
    uint32 _attempts = 0;
};

class spell_ascension_guardian_ability : public SpellScript
{
    PrepareSpellScript(spell_ascension_guardian_ability);
    uint32 _energy = 0;
    uint32 _perilStacks = 0;

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_GUARDIAN;
    }

    void Before()
    {
        _energy = GetCaster()->GetPower(POWER_ENERGY);
    }

    SpellCastResult Check()
    {
        if (GetSpellInfo()->Id == 500673)
        {
            bool ready = false;
            for (auto const& pair : GetCaster()->GetAppliedAuras())
            {
                Aura const* aura = pair.second->GetBase();
                if (AscensionGuardian::Advance(aura->GetId()) && aura->GetMaxDuration() - aura->GetDuration() >= 500)
                    ready = true;
            }
            if (!ready && !GetSpell()->IsTriggered())
                return SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        }
        if (GetSpellInfo()->Id == 802629 && !GetCaster()->HasAura(707138))
            return SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        if (GetSpellInfo()->Id == 802629)
            for (auto const& pair : GetCaster()->ToPlayer()->GetSpellMap())
                if (AscensionGuardian::HeavyBlow(pair.first) && GetCaster()->ToPlayer()->GetSpellCooldownDelay(pair.first))
                    return SPELL_FAILED_NOT_READY;
        return SPELL_CAST_OK;
    }

    void After()
    {
        Player* player = GetCaster()->ToPlayer();
        uint32 id = GetSpellInfo()->Id;
        if (id == 802871)
        {
            if (WorldLocation const* dest = GetExplTargetDest())
                player->m_Events.AddEvent(new GuardianLanding(player, *dest), player->m_Events.CalculateTime(50));
            return;
        }
        if (id == 500673)
        {
            std::vector<uint32> remove;
            for (auto const& pair : player->GetAppliedAuras())
                if (AscensionGuardian::Advance(pair.first))
                    remove.push_back(pair.first);
            for (uint32 aura : remove)
                player->RemoveAurasDueToSpell(aura);
            player->RemoveAurasDueToSpell(801160);
            return;
        }
        if (GetSpell()->IsTriggered())
            return;
        if (AscensionGuardian::Ram(id))
        {
            if (player->HasAura(520650))
                player->CastSpell(player, 520651, true);
        }
        if ((AscensionGuardian::Ram(id) || AscensionGuardian::Pulverize(id)) && player->HasAura(807297))
            player->CastSpell(player, 705381, true);
        if (AscensionGuardian::HeavyBlow(id))
            AscensionGuardian::AddParagon(player, 3);
        if (id == 802629)
        {
            player->RemoveAurasDueToSpell(707138);
            for (auto const& pair : player->GetSpellMap())
                if (AscensionGuardian::HeavyBlow(pair.first) && player->HasActiveSpell(pair.first))
                    player->AddSpellCooldown(pair.first, 0, GetSpellInfo()->RecoveryTime, true);
        }
        if (sSpellMgr->GetFirstSpellInChain(id) == 805150 && player->HasAura(805155))
            player->CastSpell(player, 806081, true);
        if (id == 803963)
            player->CastSpell(player, 807140, true);
        if (_perilStacks)
        {
            uint32 remaining = player->GetSpellCooldownDelay(300983);
            player->ModifySpellCooldown(300983, -int32(uint64(remaining) * std::min(10u, _perilStacks) / 10));
        }
    }

    void Hit()
    {
        Player* player = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        uint32 id = GetSpellInfo()->Id;
        if (!target)
            return;
        if (id == 572904 && player->IsFriendlyTo(target) && target != player)
        {
            auto threats = target->GetThreatMgr().GetThreatenedByMeList();
            for (auto const& entry : threats)
            {
                ThreatReference* reference = entry.second;
                Unit* enemy = reference->GetOwner();
                float amount = reference->GetThreat() * 0.5f;
                enemy->GetThreatMgr().ModifyThreatByPercent(target, -50);
                enemy->GetThreatMgr().AddThreat(player, amount, GetSpellInfo(), true, true);
            }
            return;
        }
        if (GetSpell()->IsTriggered() || target == player || player->IsFriendlyTo(target))
            return;
        if (id == 500258 && !target->IsAlive())
            player->RemoveSpellCooldown(id, true);
        if (!target->IsAlive() || GetHitDamage() <= 0)
            return;
        uint32 root = sSpellMgr->GetFirstSpellInChain(id);
        if (player->HasAura(705341) && (root == 805150 || root == 800316 || root == 500463))
            player->CastCustomSpell(705342, SPELLVALUE_BASE_POINT0, int32(std::min(_energy, 1000u) * 2), target,
                TRIGGERED_FULL_MASK);
        if (AscensionGuardian::Pulverize(id) || id == 801776 || (id >= 501068 && id <= 501074) || id == 574340)
        {
            if (Aura* peril = target->GetAura(524610, player->GetGUID()))
            {
                uint8 stacks = peril->GetStackAmount();
                _perilStacks += stacks;
                target->RemoveAurasDueToSpell(524610, player->GetGUID());
                player->CastCustomSpell(524608, SPELLVALUE_BASE_POINT0,
                    int32(player->GetTotalAttackPowerValue(BASE_ATTACK) * 0.1f * stacks), target, TRIGGERED_FULL_MASK);
            }
        }
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_guardian_ability::Check);
        BeforeCast += SpellCastFn(spell_ascension_guardian_ability::Before);
        AfterCast += SpellCastFn(spell_ascension_guardian_ability::After);
        AfterHit += SpellHitFn(spell_ascension_guardian_ability::Hit);
    }
};

class aura_ascension_guardian_advance : public AuraScript
{
    PrepareAuraScript(aura_ascension_guardian_advance);

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_ROOT, true);
        GetTarget()->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_SNARE, true);
        GetTarget()->RemoveAurasWithMechanic((1 << MECHANIC_ROOT) | (1 << MECHANIC_SNARE), AURA_REMOVE_BY_DEFAULT);
    }

    void Removed(AuraEffect const* effect, AuraEffectHandleModes)
    {
        Unit* owner = GetTarget();
        owner->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_ROOT, false);
        owner->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_SNARE, false);
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE && owner->IsAlive() && owner->IsInWorld())
            owner->CastSpell(owner, 500673, true, nullptr, effect);
        owner->RemoveAurasDueToSpell(801160);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_guardian_advance::Apply,
            EFFECT_1, SPELL_AURA_FORCE_MOVE_FORWARD, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_guardian_advance::Removed,
            EFFECT_1, SPELL_AURA_FORCE_MOVE_FORWARD, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_guardian_hold_the_line : public AuraScript
{
    PrepareAuraScript(aura_ascension_guardian_hold_the_line);

    void SetExtraImmunities(bool apply)
    {
        Unit* target = GetTarget();
        target->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_KNOCKOUT, apply);
        target->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_SAPPED, apply);
        target->ApplySpellImmune(GetId(), IMMUNITY_EFFECT, SPELL_EFFECT_KNOCK_BACK_DEST, apply);
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        SetExtraImmunities(true);
        if (GetSpellInfo()->HasAttribute(SPELL_ATTR1_IMMUNITY_PURGES_EFFECT))
            GetTarget()->RemoveAurasWithMechanic((1ULL << MECHANIC_KNOCKOUT) | (1ULL << MECHANIC_SAPPED),
                AURA_REMOVE_BY_DEFAULT, GetId());
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* target = GetTarget();
        auto const& effects = target->GetAuraEffectsByType(SPELL_AURA_EFFECT_IMMUNITY);
        bool protectedByAnother = std::any_of(effects.begin(), effects.end(), [this, target](AuraEffect const* other)
        {
            if (other->GetId() != GetId() || other->GetBase() == GetAura())
                return false;
            AuraApplication const* application = other->GetBase()->GetApplicationOfTarget(target->GetGUID());
            return application && application->IsActive(other->GetEffIndex());
        });
        SetExtraImmunities(protectedByAnother);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_guardian_hold_the_line::Apply,
            EFFECT_1, SPELL_AURA_EFFECT_IMMUNITY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_guardian_hold_the_line::Remove,
            EFFECT_1, SPELL_AURA_EFFECT_IMMUNITY, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddAscensionGuardianAbilityScripts()
{
    RegisterSpellScript(spell_ascension_guardian_ability);
    RegisterSpellScript(aura_ascension_guardian_advance);
    RegisterSpellScript(aura_ascension_guardian_hold_the_line);
}
