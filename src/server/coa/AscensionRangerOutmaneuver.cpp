/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"

namespace
{
enum OutmaneuverIds : uint32
{
    SPELL_OUTMANEUVER = 557325,
    SPELL_DECOY_WINDOW = 557326,
    SPELL_DECOY_ROOT = 557327,
    SPELL_DECOY_STRIKE = 557328,
    SPELL_CLONE_APPEARANCE = 45204,
    NPC_OUTMANEUVER_DECOY = 50171
};

Player* ManeuverRanger(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_RANGER ? player : nullptr;
}

bool CanManeuver(Player* player)
{
    return player && player->IsAlive() && player->IsInWorld() && !player->IsBeingTeleported() &&
        !player->IsInFlight() && !player->GetTransport() && !player->GetVehicle() &&
        player->HasActiveSpell(SPELL_OUTMANEUVER);
}

Creature* FindDecoy(Player* player, Aura const* window)
{
    if (!player || !player->IsInWorld() || !window)
        return nullptr;
    ObjectGuid guid(window->GetScriptValue(NPC_OUTMANEUVER_DECOY));
    Creature* decoy = player->GetMap()->GetCreature(guid);
    return decoy && decoy->GetEntry() == NPC_OUTMANEUVER_DECOY && decoy->GetOwnerGUID() == player->GetGUID() &&
        decoy->IsAlive() && decoy->IsInWorld() && player->InSamePhase(decoy) ? decoy : nullptr;
}

Unit* ManeuverTarget(Player* player)
{
    if (!CanManeuver(player))
        return nullptr;
    Aura* window = player->GetAura(SPELL_DECOY_WINDOW, player->GetGUID());
    if (!FindDecoy(player, window))
        return nullptr;
    Unit* target = ObjectAccessor::GetUnit(*player, ObjectGuid(window->GetScriptValue(SPELL_OUTMANEUVER)));
    return target && target->IsAlive() && player->InSamePhase(target) && player->IsValidAttackTarget(target) &&
        target->HasAura(SPELL_OUTMANEUVER, player->GetGUID()) ? target : nullptr;
}

class aura_ascension_decoy_window : public AuraScript
{
    PrepareAuraScript(aura_ascension_decoy_window);

    void Clear(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = ManeuverRanger(GetTarget());
        if (!player || GetCaster() != player)
            return;
        Creature* decoy = FindDecoy(player, GetAura());
        ObjectGuid targetGuid(GetAura()->GetScriptValue(SPELL_OUTMANEUVER));
        player->SetTemporarySpellReplacement(SPELL_OUTMANEUVER, 0);
        player->removeSpell(SPELL_DECOY_STRIKE, SPEC_MASK_ALL, true);
        if (Unit* target = ObjectAccessor::GetUnit(*player, targetGuid))
            target->RemoveAurasDueToSpell(SPELL_OUTMANEUVER, player->GetGUID());
        if (decoy)
            decoy->DespawnOrUnsummon();
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_decoy_window::Clear,
            EFFECT_1, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

struct npc_ascension_outmaneuver_decoy : ScriptedAI
{
    explicit npc_ascension_outmaneuver_decoy(Creature* creature) : ScriptedAI(creature) { }
    uint32 elapsed = 0;

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = ManeuverRanger(summoner ? summoner->ToUnit() : nullptr);
        if (!player)
        {
            me->DespawnOrUnsummon();
            return;
        }
        me->SetOwnerGUID(player->GetGUID());
        me->SetFaction(player->GetFaction());
        me->SetLevel(player->GetLevel());
        me->SetReactState(REACT_PASSIVE);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveIdle();
        player->CastSpell(me, SPELL_CLONE_APPEARANCE, true);
        me->CastSpell(me, SPELL_DECOY_ROOT, true);
    }

    void End()
    {
        if (Player* player = me->GetCharmerOrOwnerPlayerOrPlayerItself())
            if (Aura* window = player->GetAura(SPELL_DECOY_WINDOW, player->GetGUID()))
                if (window->GetScriptValue(NPC_OUTMANEUVER_DECOY) == me->GetGUID().GetRawValue())
                    player->RemoveAurasDueToSpell(SPELL_DECOY_WINDOW, player->GetGUID());
        me->DespawnOrUnsummon();
    }

    void JustDied(Unit*) override { End(); }
    void EnterEvadeMode(EvadeReason) override { End(); }

    void UpdateAI(uint32 diff) override
    {
        elapsed += diff;
        if (elapsed < 250)
            return;
        elapsed = 0;
        Player* player = me->GetCharmerOrOwnerPlayerOrPlayerItself();
        Aura* window = player ? player->GetAura(SPELL_DECOY_WINDOW, player->GetGUID()) : nullptr;
        if (!player || !player->IsAlive() || !player->IsInWorld() || player->GetMap() != me->GetMap() ||
            !player->InSamePhase(me) || !player->HasActiveSpell(SPELL_OUTMANEUVER) || !window ||
            window->GetScriptValue(NPC_OUTMANEUVER_DECOY) != me->GetGUID().GetRawValue())
            End();
    }
};

class spell_ascension_outmaneuver : public SpellScript
{
    PrepareSpellScript(spell_ascension_outmaneuver);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_DECOY_WINDOW, SPELL_DECOY_STRIKE, SPELL_DECOY_ROOT, SPELL_CLONE_APPEARANCE});
    }

    SpellCastResult Check()
    {
        return CanManeuver(ManeuverRanger(GetCaster())) ? SPELL_CAST_OK : SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
    }

    void ClearPrevious() { GetCaster()->RemoveAurasDueToSpell(SPELL_DECOY_WINDOW, GetCaster()->GetGUID()); }
    void PreventNative(SpellEffIndex index) { PreventHitDefaultEffect(index); }

    void Begin()
    {
        Player* player = ManeuverRanger(GetCaster());
        Unit* target = GetHitUnit();
        WorldLocation const* destination = GetExplTargetDest();
        if (!CanManeuver(player) || !target || target != GetExplTargetUnit() || !GetHitAura() || !destination)
            return;
        TempSummon* decoy = player->SummonCreature(NPC_OUTMANEUVER_DECOY, target->GetPosition(),
            TEMPSUMMON_MANUAL_DESPAWN);
        if (!decoy)
        {
            target->RemoveAurasDueToSpell(SPELL_OUTMANEUVER, player->GetGUID());
            return;
        }
        Aura* window = player->AddAura(SPELL_DECOY_WINDOW, player);
        if (!window)
        {
            decoy->DespawnOrUnsummon();
            target->RemoveAurasDueToSpell(SPELL_OUTMANEUVER, player->GetGUID());
            return;
        }
        window->SetScriptValue(NPC_OUTMANEUVER_DECOY, decoy->GetGUID().GetRawValue());
        window->SetScriptValue(SPELL_OUTMANEUVER, target->GetGUID().GetRawValue());
        if (player->GetSpellMap().find(SPELL_DECOY_STRIKE) == player->GetSpellMap().end())
            player->learnSpell(SPELL_DECOY_STRIKE, true);
        player->SetTemporarySpellReplacement(SPELL_OUTMANEUVER, SPELL_DECOY_STRIKE);
        if (player->GetTemporarySpellReplacement(SPELL_OUTMANEUVER) != SPELL_DECOY_STRIKE)
        {
            player->RemoveAurasDueToSpell(SPELL_DECOY_WINDOW, player->GetGUID());
            return;
        }
        Position teleportDestination = *destination;
        player->NearTeleportTo(teleportDestination, true);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_outmaneuver::Check);
        BeforeCast += SpellCastFn(spell_ascension_outmaneuver::ClearPrevious);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_outmaneuver::PreventNative, EFFECT_0,
            SPELL_EFFECT_TELEPORT_UNITS);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_outmaneuver::PreventNative, EFFECT_1,
            SPELL_EFFECT_TRIGGER_SPELL);
        OnHit += SpellHitFn(spell_ascension_outmaneuver::Begin);
    }
};

class aura_ascension_outmaneuver_mark : public AuraScript
{
    PrepareAuraScript(aura_ascension_outmaneuver_mark);

    bool Check(ProcEventInfo& event)
    {
        DamageInfo const* damage = event.GetDamageInfo();
        return ManeuverRanger(GetCaster()) && event.GetActor() == GetCaster() &&
            event.GetActionTarget() == GetTarget() &&
            damage && damage->GetDamage() && (event.GetTypeMask() &
                (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS)) &&
            (!event.GetSpellInfo() || event.GetSpellInfo()->Id != SPELL_DECOY_STRIKE);
    }

    void Stack(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetAura()->ModStackAmount(1);
    }

    void Clear(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = ManeuverRanger(GetCaster()))
            if (Aura* window = player->GetAura(SPELL_DECOY_WINDOW, player->GetGUID()))
                if (window->GetScriptValue(SPELL_OUTMANEUVER) == GetTarget()->GetGUID().GetRawValue() &&
                    !window->GetScriptValue(SPELL_DECOY_STRIKE))
                    player->RemoveAurasDueToSpell(SPELL_DECOY_WINDOW, player->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_outmaneuver_mark::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_outmaneuver_mark::Stack,
            EFFECT_2, SPELL_AURA_MOD_DAMAGE_FROM_CASTER);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_outmaneuver_mark::Clear,
            EFFECT_2, SPELL_AURA_MOD_DAMAGE_FROM_CASTER, AURA_EFFECT_HANDLE_REAL);
    }
};

class ranger_decoy_target : public AllSpellScript
{
public:
    ranger_decoy_target() : AllSpellScript("ranger_decoy_target",
        {ALLSPELLHOOK_CAN_PREPARE, ALLSPELLHOOK_ON_SPELL_CHECK_CAST}) { }

    bool CanPrepare(Spell* spell, SpellCastTargets const*, AuraEffect const*) override
    {
        if (spell->GetSpellInfo()->Id != SPELL_DECOY_STRIKE || spell->GetSpellInfo()->SpellFamilyName != 27)
            return true;
        Unit* target = ManeuverTarget(ManeuverRanger(spell->GetCaster()));
        if (!target)
            return false;
        spell->m_targets.SetUnitTarget(target);
        return true;
    }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        if (spell->GetSpellInfo()->Id != SPELL_DECOY_STRIKE || spell->GetSpellInfo()->SpellFamilyName != 27)
            return;
        Unit* target = ManeuverTarget(ManeuverRanger(spell->GetCaster()));
        if (!target || target != spell->m_targets.GetUnitTarget())
            result = SPELL_FAILED_BAD_TARGETS;
    }
};

class spell_ascension_decoy_strike : public SpellScript
{
    PrepareSpellScript(spell_ascension_decoy_strike);
    Position _departure;
    bool _return = false;

    void Record()
    {
        Player* player = ManeuverRanger(GetCaster());
        Aura* window = player ? player->GetAura(SPELL_DECOY_WINDOW, player->GetGUID()) : nullptr;
        if (Creature* decoy = FindDecoy(player, window))
        {
            _departure = decoy->GetPosition();
            _return = true;
            window->SetScriptValue(SPELL_DECOY_STRIKE, 1);
        }
    }

    void Return()
    {
        if (!_return)
            return;
        _return = false;
        Player* player = ManeuverRanger(GetCaster());
        if (!player)
            return;
        player->RemoveAurasDueToSpell(SPELL_DECOY_WINDOW, player->GetGUID());
        if (CanManeuver(player))
            player->NearTeleportTo(_departure, true);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_decoy_strike::Record);
        AfterCast += SpellCastFn(spell_ascension_decoy_strike::Return);
    }
};

class ranger_decoy_contracts : public GlobalScript
{
public:
    ranger_decoy_contracts() : GlobalScript("ranger_decoy_contracts", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info && info->Id == SPELL_DECOY_WINDOW && info->SpellFamilyName == 27)
        {
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
    }
};
}

void AddSC_AscensionRangerOutmaneuver()
{
    RegisterCreatureAI(npc_ascension_outmaneuver_decoy);
    RegisterSpellScript(spell_ascension_outmaneuver);
    RegisterSpellScript(spell_ascension_decoy_strike);
    RegisterSpellScript(aura_ascension_outmaneuver_mark);
    RegisterSpellScript(aura_ascension_decoy_window);
    new ranger_decoy_target();
    new ranger_decoy_contracts();
}
