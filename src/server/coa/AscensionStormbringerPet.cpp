/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Pet.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
enum AirElementalSpells : uint32
{
    SPELL_SUMMON_AIR_ELEMENTAL = 804019,
    SPELL_AIR_ELEMENTAL_PASSIVE = 806010,
    SPELL_INVIGORATION_PROC = 806020,
    SPELL_GENERATE_INVIGORATION = 500348,
    SPELL_INVIGORATION = 680918,
    SPELL_AURAT_SCRIPTS = 712431,
    SPELL_AURAT_SCRIPTS_PROC = 712488,
    SPELL_AURAT_GALE = 500019,
    SPELL_FLURRY_READY = 807465,
    SPELL_FLURRY_DOT = 807555,
    SPELL_FLURRY_DEBUFF = 807464,
    SPELL_COMFORTING_WINDS = 704209,
    SPELL_COMFORTING_WINDS_PET_BOND = 584238,
    SPELL_GIFT_OF_AIR_PET = 804033,
    SPELL_GIFT_OF_AIR_TAILWIND = 583254
};

enum AirElementalEntries : uint32
{
    NPC_AIR_ELEMENTAL = 500941
};

enum StormbringerSpellFamily : uint32
{
    SPELL_FAMILY_STORMBRINGER = 22,
    FAMILY_MASK_GALE = 0x4000,
    FAMILY_MASK_KISS_OF_THE_CLOUDS = 0x100000
};

Player* AirElementalOwner(Unit* unit)
{
    Pet* pet = unit ? unit->ToPet() : nullptr;
    if (!pet || pet->GetEntry() != NPC_AIR_ELEMENTAL)
        return nullptr;
    Player* owner = pet->GetOwner();
    return owner && owner->getClass() == CLASS_STORMBRINGER && owner->GetPet() == pet &&
        owner->HasActiveSpell(SPELL_SUMMON_AIR_ELEMENTAL) ? owner : nullptr;
}

Player* StormbringerProcActor(Unit* target, ProcEventInfo& event)
{
    Player* owner = target ? target->ToPlayer() : nullptr;
    return owner && owner->getClass() == CLASS_STORMBRINGER && owner->IsAlive() && owner->IsInWorld() &&
        event.GetActor() == owner ? owner : nullptr;
}

Pet* EmpoweredAirElemental(Player* owner)
{
    Pet* pet = owner ? owner->GetPet() : nullptr;
    return pet && pet->GetEntry() == NPC_AIR_ELEMENTAL && pet->IsAlive() && pet->IsInWorld() &&
        owner->IsInMap(pet) && owner->InSamePhase(pet) ? pet : nullptr;
}

Pet* EchoingAirElemental(Player* owner, Unit* victim)
{
    Pet* pet = EmpoweredAirElemental(owner);
    return pet && victim && pet->IsInMap(victim) && pet->InSamePhase(victim) &&
        pet->IsValidAttackTarget(victim) ? pet : nullptr;
}

class stormbringer_pet_lifecycle : public PlayerScript
{
public:
    stormbringer_pet_lifecycle() : PlayerScript("stormbringer_pet_lifecycle",
        {PLAYERHOOK_ON_BEFORE_GUARDIAN_INIT_STATS_FOR_LEVEL, PLAYERHOOK_ON_UPDATE}) { }

    void OnPlayerBeforeGuardianInitStatsForLevel(Player* player, Guardian* guardian, CreatureTemplate const*,
        PetType& type) override
    {
        if (player->getClass() == CLASS_STORMBRINGER && guardian && guardian->GetEntry() == NPC_AIR_ELEMENTAL)
            type = SUMMON_PET;
    }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        if (player->getClass() != CLASS_STORMBRINGER)
            return;
        Pet* pet = player->GetPet();
        if (!pet || pet->GetEntry() != NPC_AIR_ELEMENTAL || pet->isBeingLoaded())
            return;
        if (!player->HasActiveSpell(SPELL_SUMMON_AIR_ELEMENTAL))
        {
            player->RemovePet(pet, PET_SAVE_NOT_IN_SLOT);
            return;
        }
        if (!player->IsAlive() || !pet->IsAlive() || !player->IsInWorld() || !pet->IsInWorld() ||
            player->GetMap() != pet->GetMap() || !player->InSamePhase(pet))
            return;
        if (!pet->HasAura(SPELL_AIR_ELEMENTAL_PASSIVE, player->GetGUID()) ||
            !pet->HasAura(SPELL_INVIGORATION_PROC, pet->GetGUID()))
            player->CastSpell(pet, SPELL_AIR_ELEMENTAL_PASSIVE, true);
        bool const bonded = player->HasAura(SPELL_COMFORTING_WINDS);
        bool const petBonded = pet->HasAura(SPELL_COMFORTING_WINDS_PET_BOND, player->GetGUID());
        if (bonded && !petBonded)
            player->CastSpell(pet, SPELL_COMFORTING_WINDS_PET_BOND, true);
        else if (!bonded && petBonded)
            pet->RemoveAurasDueToSpell(SPELL_COMFORTING_WINDS_PET_BOND, player->GetGUID());
    }
};

class aura_ascension_air_invigoration : public AuraScript
{
    PrepareAuraScript(aura_ascension_air_invigoration);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_GENERATE_INVIGORATION, SPELL_AURAT_SCRIPTS_PROC, SPELL_AURAT_GALE,
            SPELL_FLURRY_READY, SPELL_FLURRY_DOT});
    }

    bool CheckProc(ProcEventInfo& event)
    {
        Unit* pet = GetTarget();
        Player* owner = AirElementalOwner(pet);
        Unit* victim = event.GetActionTarget();
        return owner && owner->IsAlive() && owner->IsInWorld() && pet->IsAlive() && pet->IsInWorld() &&
            owner->GetMap() == pet->GetMap() && owner->InSamePhase(pet) && event.GetActor() == pet &&
            victim && victim != pet && !pet->IsFriendlyTo(victim) &&
            event.GetDamageInfo() && event.GetDamageInfo()->GetDamage();
    }

    void Invigorate(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), SPELL_GENERATE_INVIGORATION, true);
        Player* owner = AirElementalOwner(GetTarget());
        if (owner && GetTarget()->HasAura(SPELL_FLURRY_READY, GetTarget()->GetGUID()))
        {
            GetTarget()->RemoveAurasDueToSpell(SPELL_FLURRY_READY, GetTarget()->GetGUID());
            int32 amount = sSpellMgr->GetSpellInfo(SPELL_FLURRY_DOT)->Effects[EFFECT_0].CalcValue(owner) +
                int32(owner->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE) * 0.2f);
            GetTarget()->CastCustomSpell(SPELL_FLURRY_DOT, SPELLVALUE_BASE_POINT0, amount,
                event.GetActionTarget(), true);
        }
        if (owner && owner->HasActiveSpell(SPELL_AURAT_SCRIPTS) &&
            roll_chance_i(sSpellMgr->GetSpellInfo(SPELL_AURAT_SCRIPTS_PROC)->ProcChance))
        {
            owner->CastSpell(owner, SPELL_AURAT_GALE, true);
            if (Aura* empowerment = owner->GetAura(SPELL_AURAT_GALE, owner->GetGUID()))
                empowerment->SetCharges(1);
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_air_invigoration::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_air_invigoration::Invigorate,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_ascension_enveloping_winds : public AuraScript
{
    PrepareAuraScript(aura_ascension_enveloping_winds);

    static bool IsGale(SpellInfo const* info)
    {
        return info && info->SpellFamilyName == SPELL_FAMILY_STORMBRINGER &&
            (info->SpellFamilyFlags[0] & FAMILY_MASK_GALE);
    }

    bool CheckProc(ProcEventInfo& event)
    {
        return IsGale(event.GetSpellInfo()) &&
            EchoingAirElemental(StormbringerProcActor(GetTarget(), event), event.GetActionTarget()) != nullptr;
    }

    void EchoGale(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        SpellInfo const* gale = event.GetSpellInfo();
        Unit* victim = event.GetActionTarget();
        Pet* pet = EchoingAirElemental(StormbringerProcActor(GetTarget(), event), victim);
        if (IsGale(gale) && pet)
            pet->CastSpell(victim, gale->Id, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_enveloping_winds::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_enveloping_winds::EchoGale, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class aura_ascension_gift_of_air : public AuraScript
{
    PrepareAuraScript(aura_ascension_gift_of_air);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_GIFT_OF_AIR_PET, SPELL_GIFT_OF_AIR_TAILWIND});
    }

    static bool KissedTheClouds(ProcEventInfo& event)
    {
        SpellInfo const* info = event.GetSpellInfo();
        return (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_CAST) && info &&
            info->SpellFamilyName == SPELL_FAMILY_STORMBRINGER &&
            (info->SpellFamilyFlags[2] & FAMILY_MASK_KISS_OF_THE_CLOUDS);
    }

    static bool StruckCritically(ProcEventInfo& event)
    {
        return (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_HIT) &&
            (event.GetHitMask() & PROC_HIT_CRITICAL);
    }

    bool CheckProc(ProcEventInfo& event)
    {
        return StormbringerProcActor(GetTarget(), event) &&
            (KissedTheClouds(event) || StruckCritically(event));
    }

    void Empower(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Player* owner = StormbringerProcActor(GetTarget(), event);
        if (!owner)
            return;
        if (KissedTheClouds(event))
            if (Pet* pet = EmpoweredAirElemental(owner))
                owner->CastSpell(pet, SPELL_GIFT_OF_AIR_PET, true);
        if (StruckCritically(event))
            owner->CastSpell(owner, SPELL_GIFT_OF_AIR_TAILWIND, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_gift_of_air::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_gift_of_air::Empower,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_air_invigoration_duration : public SpellScript
{
    PrepareSpellScript(spell_ascension_air_invigoration_duration);
    int32 remaining = 0;

    bool Load() override { return AirElementalOwner(GetCaster()) != nullptr; }

    void SnapshotDuration()
    {
        if (Aura* aura = GetCaster()->GetAura(SPELL_INVIGORATION, GetCaster()->GetGUID()))
            remaining = aura->GetDuration();
    }

    void RestoreDuration()
    {
        if (remaining > 0)
            if (Aura* aura = GetCaster()->GetAura(SPELL_INVIGORATION, GetCaster()->GetGUID()))
                aura->SetDuration(remaining);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_air_invigoration_duration::SnapshotDuration);
        AfterCast += SpellCastFn(spell_ascension_air_invigoration_duration::RestoreDuration);
    }
};

class stormbringer_pet_contracts : public GlobalScript
{
public:
    stormbringer_pet_contracts() : GlobalScript("stormbringer_pet_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info && info->Id == SPELL_FLURRY_DEBUFF && info->SpellFamilyName == 22 &&
            info->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN)
            info->Effects[EFFECT_1].BasePoints = info->Effects[EFFECT_1].CalcBaseValue(2);
        if (info && info->Id == SPELL_FLURRY_DOT && info->SpellFamilyName == 22)
        {
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        }
    }
};
}

void AddSC_AscensionStormbringerPet()
{
    new stormbringer_pet_lifecycle();
    new stormbringer_pet_contracts();
    RegisterSpellScript(aura_ascension_air_invigoration);
    RegisterSpellScript(aura_ascension_enveloping_winds);
    RegisterSpellScript(aura_ascension_gift_of_air);
    RegisterSpellScript(spell_ascension_air_invigoration_duration);
}
