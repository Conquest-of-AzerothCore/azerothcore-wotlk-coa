/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <list>
#include <string_view>
#include <utility>
#include <vector>

namespace
{
std::string_view NameOf(SpellInfo const* info)
{
    char const* const name = info->SpellName[LOCALE_enUS];
    return name ? std::string_view(name) : std::string_view();
}

struct AuraCopy
{
    struct Effect
    {
        bool Present = false;
        int32 Amount = 0;
        float PctMods = 1.0f;
        float Crit = 0.0f;
        int32 Timer = 0;
        bool Periodic = false;
    };

    uint32 SpellId = 0;
    uint8 EffectMask = 0;
    uint8 Stacks = 1;
    int32 Duration = 0;
    int32 MaxDuration = 0;
    std::array<Effect, MAX_SPELL_EFFECTS> Effects{};
};

AuraCopy CopyAura(Aura const* aura)
{
    AuraCopy copy;
    copy.SpellId = aura->GetId();
    copy.Stacks = aura->GetStackAmount();
    copy.Duration = aura->GetDuration();
    copy.MaxDuration = aura->GetMaxDuration();
    for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
        if (AuraEffect const* effect = aura->GetEffect(i))
        {
            copy.EffectMask |= 1u << i;
            copy.Effects[i] = { true, effect->GetAmount(), effect->GetPctMods(), effect->GetCritChance(),
                effect->GetPeriodicTimer(), effect->IsPeriodic() };
        }
    return copy;
}

bool ApplyAuraCopy(Unit* caster, Unit* recipient, AuraCopy const& copy)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(copy.SpellId);
    if (!info || !copy.EffectMask || !recipient->IsAlive() || recipient->IsImmunedToSpell(info, caster))
        return false;
    recipient->RemoveAurasDueToSpell(copy.SpellId, caster->GetGUID());
    Aura* aura = caster->AddAura(info, copy.EffectMask, recipient);
    if (!aura)
        return false;
    if (copy.Stacks > 1)
        aura->SetStackAmount(copy.Stacks);
    aura->SetMaxDuration(copy.MaxDuration);
    aura->SetDuration(copy.Duration);
    for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
        if (AuraEffect* effect = aura->GetEffect(i))
            if (copy.Effects[i].Present)
            {
                effect->ChangeAmount(copy.Effects[i].Amount);
                effect->SetPctMods(copy.Effects[i].PctMods);
                effect->SetCritChance(copy.Effects[i].Crit);
                effect->SetCanBeRecalculated(false);
                if (copy.Effects[i].Periodic)
                    effect->SetPeriodicTimer(copy.Effects[i].Timer);
            }
    return true;
}

constexpr uint32 SOUL_SWAP = 954614;
constexpr uint32 SOUL_SWAP_REBORN = 2304614;
constexpr uint32 SOUL_SWAP_HELD = 954615;
constexpr uint32 SOUL_SWAP_HELD_REBORN = 2304615;
constexpr uint32 SOUL_SWAP_EXHALE_REBORN = 2304853;
constexpr char const* SOUL_SWAP_HELD_SCRIPT = "spell_dummysystem_caster_soul_swap_held";

bool IsSoulSwapCopyable(Aura const* aura, Unit const* caster, bool reborn)
{
    SpellInfo const* info = aura->GetSpellInfo();
    if (aura->IsRemoved() || aura->GetCasterGUID() != caster->GetGUID() || aura->GetDuration() <= 0 ||
        info->IsPassive() || info->IsChanneled() || info->IsPositive())
        return false;
    bool const damageOverTime = aura->HasEffectType(SPELL_AURA_PERIODIC_DAMAGE) ||
        aura->HasEffectType(SPELL_AURA_PERIODIC_DAMAGE_PERCENT) || aura->HasEffectType(SPELL_AURA_PERIODIC_LEECH);
    if (!damageOverTime)
        return false;
    if (!reborn)
        return true;
    std::string_view const name = NameOf(info);
    return info->SpellFamilyName == SPELLFAMILY_WARLOCK &&
        (name == "Corruption" || name == "Curse of Agony" || name == "Unstable Affliction");
}

class spell_dummysystem_caster_soul_swap_held : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_caster_soul_swap_held);

public:
    void Hold(std::vector<AuraCopy> copies) { _copies = std::move(copies); }
    std::vector<AuraCopy> const& Held() const { return _copies; }

private:
    void Register() override { }

    std::vector<AuraCopy> _copies;
};

class spell_dummysystem_caster_soul_swap : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_caster_soul_swap);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SOUL_SWAP_HELD, SOUL_SWAP_HELD_REBORN });
    }

    void HandleInhale(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target)
            return;
        bool const reborn = GetSpellInfo()->Id == SOUL_SWAP_REBORN;
        std::vector<AuraCopy> copies;
        for (auto const& [id, application] : target->GetAppliedAuras())
            if (IsSoulSwapCopyable(application->GetBase(), caster, reborn))
                copies.push_back(CopyAura(application->GetBase()));
        if (copies.empty())
            return;
        uint32 const held = reborn ? SOUL_SWAP_HELD_REBORN : SOUL_SWAP_HELD;
        caster->CastSpell(caster, held, true);
        if (Aura* aura = caster->GetAura(held, caster->GetGUID()))
            if (auto* script = aura->GetScript<spell_dummysystem_caster_soul_swap_held>(SOUL_SWAP_HELD_SCRIPT))
                script->Hold(std::move(copies));
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummysystem_caster_soul_swap::HandleInhale, EFFECT_0,
            SPELL_EFFECT_APPLY_AURA);
    }
};

class spell_dummysystem_caster_soul_swap_exhale : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_caster_soul_swap_exhale);

    bool Reborn() { return GetSpellInfo()->Id == SOUL_SWAP_EXHALE_REBORN; }

    SpellCastResult CheckCast()
    {
        Unit* caster = GetCaster();
        if (!caster->HasAura(Reborn() ? SOUL_SWAP_HELD_REBORN : SOUL_SWAP_HELD, caster->GetGUID()))
            return SPELL_FAILED_CASTER_AURASTATE;
        if (Unit* target = GetExplTargetUnit())
            if (target->HasAura(Reborn() ? SOUL_SWAP_REBORN : SOUL_SWAP, caster->GetGUID()))
                return SPELL_FAILED_BAD_TARGETS;
        return SPELL_CAST_OK;
    }

    void HandleExhale(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        Aura* held = caster->GetAura(Reborn() ? SOUL_SWAP_HELD_REBORN : SOUL_SWAP_HELD, caster->GetGUID());
        if (!target || !held)
            return;
        std::vector<AuraCopy> failed;
        auto* script = held->GetScript<spell_dummysystem_caster_soul_swap_held>(SOUL_SWAP_HELD_SCRIPT);
        if (script)
            for (AuraCopy const& copy : script->Held())
                if (!ApplyAuraCopy(caster, target, copy))
                    failed.push_back(copy);
        if (script && !failed.empty())
        {
            script->Hold(std::move(failed));
            return;
        }
        held->Remove();
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_dummysystem_caster_soul_swap_exhale::CheckCast);
        OnEffectHitTarget += SpellEffectFn(spell_dummysystem_caster_soul_swap_exhale::HandleExhale, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

constexpr uint32 APOSTLE_OF_EREDATH = 902185;
constexpr uint32 BEAM_OF_HATRED = 902186;
constexpr uint32 DESTRUCTIVE_BARGAIN = 902189;
constexpr uint32 SOUL_FIRE_EMPOWERMENT = 902194;
constexpr uint32 CHAOS_BOLT_EMPOWERMENT = 902195;
constexpr uint32 RAIN_OF_FIRE_EMPOWERMENT = 902196;
constexpr uint32 SOUL_RESTORATION = 902197;
constexpr uint32 BEAM_OF_HATRED_REDUCTION = 902198;
constexpr uint32 HAND_OF_DEATH_SHARE = 902199;
constexpr uint32 UNSTABLE_KINDLING = 902201;
constexpr uint32 HAND_OF_DEATH = 902202;
constexpr uint8 CONFLAGRATE_DOT_TICKS = 3;
constexpr std::array<uint32, 2> DECIMATION = { 63165, 63167 };
constexpr float UNSTABLE_KINDLING_RANGE = 60.0f;

enum class WarlockSpell
{
    Other,
    SoulFire,
    Incinerate,
    ChaosBolt,
    RainOfFire,
    Conflagrate
};

WarlockSpell ClassifyWarlockSpell(SpellInfo const* info)
{
    if (info->SpellFamilyName != SPELLFAMILY_WARLOCK)
        return WarlockSpell::Other;
    flag96 const& flags = info->SpellFamilyFlags;
    if (flags[1] & 0x00000080)
        return WarlockSpell::SoulFire;
    if (flags[1] & 0x00000040)
        return WarlockSpell::Incinerate;
    if (flags[1] & 0x00020000)
        return WarlockSpell::ChaosBolt;
    if (flags[1] & 0x00800000)
        return WarlockSpell::Conflagrate;
    if (flags[0] & 0x00000020)
        return WarlockSpell::RainOfFire;
    return WarlockSpell::Other;
}

class spell_dummysystem_caster_apostle_of_eredath : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_caster_apostle_of_eredath);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        uint32 rank = 0;
        for (uint32 id = BEAM_OF_HATRED; id; id = sSpellMgr->GetNextSpellInChain(id))
        {
            if (player->HasSpell(id))
                return;
            SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
            if (info && info->SpellLevel <= player->GetLevel())
                rank = id;
        }
        if (!rank)
            return;
        player->learnSpell(rank, true);
        _taught = rank;
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (Player* player = GetTarget()->ToPlayer())
            if (_taught)
                player->removeSpell(_taught, SPEC_MASK_ALL, true);
        _taught = 0;
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummysystem_caster_apostle_of_eredath::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_caster_apostle_of_eredath::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }

    uint32 _taught = 0;
};

void SpreadConflagrate(Unit* caster, Unit* struck, Spell* conflagrate)
{
    SpellInfo const* share = sSpellMgr->GetSpellInfo(HAND_OF_DEATH_SHARE);
    SpellInfo const* handOfDeath = sSpellMgr->GetSpellInfo(HAND_OF_DEATH);
    if (!share || !handOfDeath || !handOfDeath->Effects[EFFECT_0].Amplitude)
        return;
    int32 const conflagrateTick = conflagrate->CalculateSpellDamage(EFFECT_1, struck);
    int32 const spreadTicks = std::max<int32>(1,
        handOfDeath->GetMaxDuration() / int32(handOfDeath->Effects[EFFECT_0].Amplitude));
    int32 const perTick = int32(CalculatePct(int64(conflagrateTick) * CONFLAGRATE_DOT_TICKS,
        share->Effects[EFFECT_0].CalcValue()) / spreadTicks);
    if (perTick <= 0)
        return;

    std::list<Unit*> enemies;
    Acore::AnyUnfriendlyUnitInObjectRangeCheck check(caster, caster, UNSTABLE_KINDLING_RANGE);
    Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(caster, enemies, check);
    Cell::VisitObjects(caster, searcher, UNSTABLE_KINDLING_RANGE);
    for (Unit* enemy : enemies)
    {
        if (enemy == struck || !enemy->HasAura(UNSTABLE_KINDLING, caster->GetGUID()) ||
            !caster->IsValidAttackTarget(enemy))
            continue;
        enemy->RemoveAurasDueToSpell(UNSTABLE_KINDLING, caster->GetGUID());
        if (Aura* spread = caster->AddAura(handOfDeath, 1u << EFFECT_0, enemy))
            if (AuraEffect* effect = spread->GetEffect(EFFECT_0))
            {
                effect->ChangeAmount(perTick);
                effect->SetCanBeRecalculated(false);
            }
    }
}

void SpendConflagrateEmpowerment(Unit* caster, Unit* struck, Spell* conflagrate)
{
    if (caster->HasAura(SOUL_FIRE_EMPOWERMENT, caster->GetGUID()))
    {
        caster->RemoveAurasDueToSpell(SOUL_FIRE_EMPOWERMENT, caster->GetGUID());
        if (caster->HasAura(DESTRUCTIVE_BARGAIN, caster->GetGUID()))
            caster->CastSpell(caster, SOUL_RESTORATION, true);
    }
    else if (caster->HasAura(CHAOS_BOLT_EMPOWERMENT, caster->GetGUID()))
    {
        caster->RemoveAurasDueToSpell(CHAOS_BOLT_EMPOWERMENT, caster->GetGUID());
        caster->CastSpell(caster, BEAM_OF_HATRED_REDUCTION, true);
    }
    else if (caster->HasAura(RAIN_OF_FIRE_EMPOWERMENT, caster->GetGUID()))
    {
        caster->RemoveAurasDueToSpell(RAIN_OF_FIRE_EMPOWERMENT, caster->GetGUID());
        SpreadConflagrate(caster, struck, conflagrate);
    }
}

constexpr uint32 SOUL_FRAGMENT = 272514;
constexpr uint8 SOUL_FRAGMENTS_FOR_VISIONS = 6;
constexpr uint32 SHADOW_VISIONS = 272515;
constexpr uint32 SHADOW_VISIONS_LATER = 1570626;
constexpr uint32 MIND_BLAST_EMPOWERMENT = 272519;
constexpr uint32 DEVOURING_SHADOWS = 272518;

struct ShadowVisionsVersion
{
    uint32 Buff;
    uint32 DevouringPlagueEmpowerment;
    uint32 VampiricTouchDebuff;
    uint32 PsychicSurge;
    uint32 DevouringPlagueCooldownMs;
};

constexpr std::array<ShadowVisionsVersion, 2> SHADOW_VISIONS_VERSIONS = { {
    { SHADOW_VISIONS, 272522, 272516, 272520, 0 },
    { SHADOW_VISIONS_LATER, 1570632, 1570627, 1570630, 12000 } } };

ShadowVisionsVersion const* FindShadowVisions(uint32 buff)
{
    auto const itr = std::find_if(SHADOW_VISIONS_VERSIONS.begin(), SHADOW_VISIONS_VERSIONS.end(),
        [buff](ShadowVisionsVersion const& version) { return version.Buff == buff; });
    return itr == SHADOW_VISIONS_VERSIONS.end() ? nullptr : &*itr;
}

enum class PriestSpell
{
    Other,
    MindBlast,
    DevouringPlague,
    VampiricTouch
};

PriestSpell ClassifyPriestSpell(SpellInfo const* info)
{
    if (!info || info->SpellFamilyName != SPELLFAMILY_PRIEST)
        return PriestSpell::Other;
    if (info->SpellFamilyFlags[0] & 0x00002000)
        return PriestSpell::MindBlast;
    if (info->SpellFamilyFlags[0] & 0x02000000)
        return PriestSpell::DevouringPlague;
    if (info->SpellFamilyFlags[1] & 0x00000400)
        return PriestSpell::VampiricTouch;
    return PriestSpell::Other;
}

class spell_dummysystem_caster_shadow_visions_fragments : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_caster_shadow_visions_fragments);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SOUL_FRAGMENT, SHADOW_VISIONS });
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        Unit* priest = GetTarget();
        priest->CastSpell(priest, SOUL_FRAGMENT, true, nullptr, aurEff);
        Aura const* fragments = priest->GetAura(SOUL_FRAGMENT, priest->GetGUID());
        if (fragments && fragments->GetStackAmount() >= SOUL_FRAGMENTS_FOR_VISIONS)
            priest->CastSpell(priest, SHADOW_VISIONS, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_caster_shadow_visions_fragments::HandleProc, EFFECT_0,
            SPELL_AURA_DUMMY);
    }
};

class spell_dummysystem_caster_shadow_visions : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_caster_shadow_visions);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ MIND_BLAST_EMPOWERMENT, DEVOURING_SHADOWS, 272522, 272516, 272520, 1570632,
            1570627, 1570630 });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        ShadowVisionsVersion const* version = FindShadowVisions(GetId());
        if (!version)
            return;
        Unit* priest = GetTarget();
        priest->CastSpell(priest, MIND_BLAST_EMPOWERMENT, true, nullptr, aurEff);
        priest->CastSpell(priest, version->DevouringPlagueEmpowerment, true, nullptr, aurEff);
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        ShadowVisionsVersion const* version = FindShadowVisions(GetId());
        if (!version)
            return;
        Unit* priest = GetTarget();
        priest->RemoveAurasDueToSpell(MIND_BLAST_EMPOWERMENT, priest->GetGUID());
        priest->RemoveAurasDueToSpell(version->DevouringPlagueEmpowerment, priest->GetGUID());
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        return target && target != GetTarget() && ClassifyPriestSpell(eventInfo.GetSpellInfo()) != PriestSpell::Other;
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        ShadowVisionsVersion const* version = FindShadowVisions(GetId());
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        Unit* priest = GetTarget();
        Unit* target = eventInfo.GetProcTarget();
        if (!version || !spell || !target)
            return;
        PriestSpell const kind = ClassifyPriestSpell(spell);
        Remove();
        switch (kind)
        {
            case PriestSpell::MindBlast:
                priest->CastSpell(priest, version->PsychicSurge, true);
                break;
            case PriestSpell::VampiricTouch:
                priest->CastSpell(target, version->VampiricTouchDebuff, true);
                break;
            case PriestSpell::DevouringPlague:
                priest->CastSpell(target, DEVOURING_SHADOWS, true);
                if (version->DevouringPlagueCooldownMs)
                    if (Player* player = priest->ToPlayer())
                        player->AddSpellCooldown(spell->Id, 0, version->DevouringPlagueCooldownMs, true);
                break;
            default:
                break;
        }
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummysystem_caster_shadow_visions::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_caster_shadow_visions::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_caster_shadow_visions::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_caster_shadow_visions::HandleProc, EFFECT_0,
            SPELL_AURA_DUMMY);
    }
};

class spell_dummysystem_caster_psychic_surge : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_caster_psychic_surge);

    void HandleProc(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
        AuraEffect* bonus = GetEffect(EFFECT_0);
        if (!bonus)
            return;
        int32 const left = bonus->GetAmount() - 1;
        if (left <= 0)
            Remove();
        else
            bonus->ChangeAmount(left);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_caster_psychic_surge::HandleProc, EFFECT_2,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 BURNING_DETERMINATION_CAPSTONE = 854747;
constexpr uint32 BURNING_DETERMINATION_DELAYED = 854750;
constexpr uint32 BURNING_HASTE = 854752;
constexpr uint32 BURNING_DETERMINATION_ICD = 411136;
constexpr uint32 BLAZING_DETERMINATION_ENCHANT = 965354;
constexpr uint32 BLAZING_DETERMINATION = 283620;
constexpr uint32 BLAZING_DETERMINATION_ICD = 283623;
constexpr std::array<uint32, 2> BLAZING_DETERMINATION_SHIELDS = { 283621, 283622 };

void TriggerDeterminationCapstone(Player* mage)
{
    if (mage->HasAura(BLAZING_DETERMINATION_ENCHANT))
    {
        if (!mage->HasAura(BLAZING_DETERMINATION_ICD))
            mage->CastSpell(mage, BLAZING_DETERMINATION, true);
        return;
    }
    if (mage->HasAura(BURNING_DETERMINATION_ICD))
        return;
    mage->CastSpell(mage, BURNING_DETERMINATION_DELAYED, true);
    mage->CastSpell(mage, BURNING_HASTE, true);
    mage->CastSpell(mage, BURNING_DETERMINATION_ICD, true);
}

void EndBlazingShields(Unit* owner)
{
    for (uint32 shield : BLAZING_DETERMINATION_SHIELDS)
        owner->RemoveAurasDueToSpell(shield, owner->GetGUID());
}

class BlazingDeterminationWatch : public BasicEvent
{
public:
    explicit BlazingDeterminationWatch(Unit* owner) : _owner(owner) { }

    bool Execute(uint64 , uint32 ) override
    {
        if (_owner->HasAura(BLAZING_DETERMINATION) && _owner->IsNonMeleeSpellCast(false))
            _owner->m_Events.AddEventAtOffset(new BlazingDeterminationWatch(_owner), 100ms);
        else
            EndBlazingShields(_owner);
        return true;
    }

private:
    Unit* _owner;
};

void ShieldCast(Unit* caster)
{
    Aura const* blazing = caster->GetAura(BLAZING_DETERMINATION);
    if (!blazing)
        return;
    for (uint32 shield : BLAZING_DETERMINATION_SHIELDS)
    {
        caster->CastSpell(caster, shield, true);
        if (Aura* applied = caster->GetAura(shield, caster->GetGUID()))
            if (applied->GetDuration() > blazing->GetDuration())
                applied->SetDuration(blazing->GetDuration());
    }
    caster->m_Events.AddEventAtOffset(new BlazingDeterminationWatch(caster), 100ms);
}

constexpr uint32 UNSEALED = 825958;
constexpr std::array<uint32, 4> SEALS_OF_RIGHTEOUSNESS = { 21084, 20154, 1121084, 1120154 };
constexpr std::array<uint32, 2> SEALS_OF_VENGEANCE = { 31801, 1131801 };
constexpr std::array<uint32, 2> SEALS_OF_CORRUPTION = { 53736, 1153736 };
constexpr std::array<uint32, 2> SEALS_OF_COMMAND = { 20375, 1120375 };
constexpr uint32 SEAL_OF_RIGHTEOUSNESS_DAMAGE = 25742;
constexpr uint32 HOLY_VENGEANCE = 31803;
constexpr uint32 SEAL_OF_VENGEANCE_DAMAGE = 42463;
constexpr uint32 BLOOD_CORRUPTION = 53742;
constexpr uint32 SEAL_OF_CORRUPTION_DAMAGE = 53739;
constexpr uint32 SEAL_OF_COMMAND_DAMAGE = 20424;

template <std::size_t N>
AuraEffect const* FindSeal(Unit const* paladin, std::array<uint32, N> const& seals, uint32& seal)
{
    for (uint32 id : seals)
        if (AuraEffect const* effect = paladin->GetAuraEffect(id, EFFECT_0, paladin->GetGUID()))
        {
            seal = id;
            return effect;
        }
    return nullptr;
}

void TriggerRighteousness(Unit* paladin, Unit* target, uint32 seal, AuraEffect const* sealEffect)
{
    float const ap = paladin->GetTotalAttackPowerValue(BASE_ATTACK);
    int32 const holy = paladin->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_HOLY) +
        target->SpellBaseDamageBonusTaken(SPELL_SCHOOL_MASK_HOLY);
    int32 const bp = std::max<int32>(0,
        int32((ap * 0.022f + 0.044f * holy) * paladin->GetAttackTime(BASE_ATTACK) / 1000));
    paladin->CastCustomSpell(sSpellMgr->GetSpellTwinFor(SEAL_OF_RIGHTEOUSNESS_DAMAGE, seal), SPELLVALUE_BASE_POINT0, bp,
        target, true, nullptr, sealEffect);
}

void TriggerVengeance(Unit* paladin, Unit* target, uint32 seal, AuraEffect const* sealEffect, bool corruption)
{
    uint32 const damageSpell = sSpellMgr->GetSpellTwinFor(corruption ? SEAL_OF_CORRUPTION_DAMAGE :
        SEAL_OF_VENGEANCE_DAMAGE, seal);
    if (AuraEffect const* dot = target->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_PALADIN, 0x00000000,
        0x00000800, 0x00000000, paladin->GetGUID()))
        if (SpellInfo const* damage = sSpellMgr->GetSpellInfo(damageSpell))
        {
            int32 const maxStacks = std::max<int32>(1, int32(dot->GetSpellInfo()->StackAmount));
            int32 const amount = damage->Effects[EFFECT_0].CalcValue() * dot->GetBase()->GetStackAmount() / maxStacks;
            paladin->CastCustomSpell(damageSpell, SPELLVALUE_BASE_POINT0, amount, target, true, nullptr, sealEffect);
        }
    paladin->CastSpell(target, sSpellMgr->GetSpellTwinFor(corruption ? BLOOD_CORRUPTION : HOLY_VENGEANCE, seal), true,
        nullptr, sealEffect);
}

void TriggerActiveSeal(Unit* paladin, Unit* target, bool command)
{
    if (!target || !target->IsAlive())
        return;
    uint32 seal = 0;
    if (AuraEffect const* righteousness = FindSeal(paladin, SEALS_OF_RIGHTEOUSNESS, seal))
        TriggerRighteousness(paladin, target, seal, righteousness);
    else if (AuraEffect const* vengeance = FindSeal(paladin, SEALS_OF_VENGEANCE, seal))
        TriggerVengeance(paladin, target, seal, vengeance, false);
    else if (AuraEffect const* corruption = FindSeal(paladin, SEALS_OF_CORRUPTION, seal))
        TriggerVengeance(paladin, target, seal, corruption, true);
    else if (command)
        if (AuraEffect const* strike = FindSeal(paladin, SEALS_OF_COMMAND, seal))
            paladin->CastSpell(target, sSpellMgr->GetSpellTwinFor(SEAL_OF_COMMAND_DAMAGE, seal), true, nullptr, strike);
}

class spell_dummysystem_caster_unsealed : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_caster_unsealed);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Unit* target = eventInfo.GetProcTarget();
        if (!spell || !damage || !damage->GetDamage() || !target || !target->IsAlive())
            return false;
        bool const castHolySpell = spell->DmgClass == SPELL_DAMAGE_CLASS_MAGIC &&
            (spell->GetSchoolMask() & SPELL_SCHOOL_MASK_HOLY) && (spell->CalcCastTime() > 0 || spell->IsChanneled());
        bool const rangedAbility = spell->DmgClass == SPELL_DAMAGE_CLASS_RANGED && !spell->IsAutoRepeatRangedSpell();
        return castHolySpell || rangedAbility;
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        TriggerActiveSeal(GetTarget(), eventInfo.GetProcTarget(), true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_caster_unsealed::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_caster_unsealed::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_dummysystem_caster_elemental_conviction : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_caster_elemental_conviction);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Unit* target = eventInfo.GetProcTarget();
        return GetTarget()->HasAura(UNSEALED, GetTarget()->GetGUID()) && damage && damage->GetDamage() && target &&
            target->IsAlive();
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        TriggerActiveSeal(GetTarget(), eventInfo.GetProcTarget(), false);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_caster_elemental_conviction::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_caster_elemental_conviction::HandleProc, EFFECT_0,
            SPELL_AURA_DUMMY);
    }
};

constexpr uint32 SKELETON_KING = 299140;
constexpr uint32 SKELETON_KING_HEALTH = 299142;
constexpr std::array<uint32, 2> FROST_PRESENCE = { 48263, 1148263 };
constexpr std::array<uint32, 3> BONE_SHIELD = { 49222, 1149222, 1249222 };

class spell_dummysystem_caster_skeleton_king_death_pact : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_caster_skeleton_king_death_pact);

    void KeepMinion(SpellEffIndex effIndex)
    {
        if (GetCaster()->HasAura(SKELETON_KING))
            PreventHitDefaultEffect(effIndex);
    }

    void HandleAfterCast()
    {
        Unit* knight = GetCaster();
        if (!knight->HasAura(SKELETON_KING) ||
            std::none_of(FROST_PRESENCE.begin(), FROST_PRESENCE.end(),
                [knight](uint32 presence) { return knight->HasAura(presence, knight->GetGUID()); }))
            return;
        for (uint32 id : BONE_SHIELD)
            if (Aura* shield = knight->GetAura(id, knight->GetGUID()))
            {
                shield->SetCharges(shield->CalcMaxCharges());
                knight->CastSpell(knight, SKELETON_KING_HEALTH, true);
                return;
            }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummysystem_caster_skeleton_king_death_pact::KeepMinion, EFFECT_1,
            SPELL_EFFECT_INSTAKILL);
        AfterCast += SpellCastFn(spell_dummysystem_caster_skeleton_king_death_pact::HandleAfterCast);
    }
};

class spell_dummysystem_caster_skeleton_king_bone_shield : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_caster_skeleton_king_bone_shield);

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        GetTarget()->RemoveAurasDueToSpell(SKELETON_KING_HEALTH, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_caster_skeleton_king_bone_shield::HandleRemove,
            EFFECT_0, SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN, AURA_EFFECT_HANDLE_REAL);
    }
};

class dummysystem_caster_spell_hooks : public AllSpellScript
{
public:
    dummysystem_caster_spell_hooks() : AllSpellScript("dummysystem_caster_spell_hooks",
        { ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_PREPARE, ALLSPELLHOOK_ON_SUCCESSFUL_INTERRUPT,
            ALLSPELLHOOK_ON_HIT_RESULT }) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool ) override
    {
        if (spell->IsTriggered() || !caster->HasAura(APOSTLE_OF_EREDATH))
            return;
        WarlockSpell const kind = ClassifyWarlockSpell(info);
        if (kind == WarlockSpell::Incinerate || (kind == WarlockSpell::SoulFire &&
            std::any_of(DECIMATION.begin(), DECIMATION.end(), [caster](uint32 id) { return caster->HasAura(id); })))
            caster->CastSpell(caster, DESTRUCTIVE_BARGAIN, true);
        uint32 const empowerment = kind == WarlockSpell::SoulFire ? SOUL_FIRE_EMPOWERMENT :
            kind == WarlockSpell::ChaosBolt ? CHAOS_BOLT_EMPOWERMENT :
            kind == WarlockSpell::RainOfFire && info->IsChanneled() ? RAIN_OF_FIRE_EMPOWERMENT : 0;
        if (empowerment)
            caster->CastSpell(caster, empowerment, true);
    }

    void OnSpellPrepare(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        if (spell->IsTriggered() || (!spell->GetCastTime() && !info->IsChanneled()) ||
            !caster->HasAura(BLAZING_DETERMINATION) || !caster->IsNonMeleeSpellCast(false))
            return;
        ShieldCast(caster);
    }

    void OnSpellSuccessfulInterrupt(Spell* spell, Unit* target) override
    {
        Interrupted = { spell, target ? target->GetGUID() : ObjectGuid::Empty };
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 missInfo, uint32 damage, uint32 ,
        bool ) override
    {
        bool const interrupted = target && Interrupted.first == spell && Interrupted.second == target->GetGUID();
        if (interrupted)
            Interrupted = { nullptr, ObjectGuid::Empty };
        if (!target || missInfo != SPELL_MISS_NONE)
            return;
        Unit* caster = spell->GetCaster();
        SpellInfo const* info = spell->GetSpellInfo();

        if (!interrupted && caster != target && info->HasEffect(SPELL_EFFECT_INTERRUPT_CAST))
            if (Player* mage = target->ToPlayer())
                if (mage->HasAura(BURNING_DETERMINATION_CAPSTONE) && !mage->IsNonMeleeSpellCast(false, false, true))
                    TriggerDeterminationCapstone(mage);

        if (!caster || !caster->HasAura(APOSTLE_OF_EREDATH) || !info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE))
            return;
        WarlockSpell const kind = ClassifyWarlockSpell(info);
        if (kind == WarlockSpell::RainOfFire && damage && caster->IsValidAttackTarget(target))
            caster->CastSpell(target, UNSTABLE_KINDLING, true);
        else if (kind == WarlockSpell::Conflagrate && !spell->IsTriggered())
            SpendConflagrateEmpowerment(caster, target, spell);
    }

private:
    static thread_local std::pair<Spell const*, ObjectGuid> Interrupted;
};

thread_local std::pair<Spell const*, ObjectGuid> dummysystem_caster_spell_hooks::Interrupted{ nullptr, ObjectGuid::Empty };
}

void ApplyAscensionDummySystemCasterContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    flag96 const devouringPlague(0x02000000, 0, 0);
    switch (spellInfo->Id)
    {
        case 272520:
        case 1570630:
            spellInfo->Effects[EFFECT_0].BasePoints = 24;
            spellInfo->Effects[EFFECT_0].DieSides = 1;
            spellInfo->ProcCharges = 0;
            break;
        case MIND_BLAST_EMPOWERMENT:
            spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
            spellInfo->ProcFlags = 0;
            break;
        case 272522:
            spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
            spellInfo->Effects[EFFECT_2].SpellClassMask = devouringPlague;
            spellInfo->ProcFlags = 0;
            break;
        case 1570632:
            spellInfo->Effects[EFFECT_0].SpellClassMask = devouringPlague;
            spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
            spellInfo->Effects[EFFECT_2].SpellClassMask = devouringPlague;
            spellInfo->ProcFlags = 0;
            break;
        case BURNING_DETERMINATION_ICD:
            spellInfo->ProcFlags = 0;
            spellInfo->ProcCharges = 0;
            break;
        case 283621:
        case 283622:
            spellInfo->ProcFlags = 0;
            spellInfo->ProcCharges = 0;
            break;
        default:
            break;
    }
}

void AddAscensionDummySystemCasterScripts()
{
    RegisterSpellScript(spell_dummysystem_caster_soul_swap);
    RegisterSpellScript(spell_dummysystem_caster_soul_swap_held);
    RegisterSpellScript(spell_dummysystem_caster_soul_swap_exhale);
    RegisterSpellScript(spell_dummysystem_caster_apostle_of_eredath);
    RegisterSpellScript(spell_dummysystem_caster_shadow_visions_fragments);
    RegisterSpellScript(spell_dummysystem_caster_shadow_visions);
    RegisterSpellScript(spell_dummysystem_caster_psychic_surge);
    RegisterSpellScript(spell_dummysystem_caster_unsealed);
    RegisterSpellScript(spell_dummysystem_caster_elemental_conviction);
    RegisterSpellScript(spell_dummysystem_caster_skeleton_king_death_pact);
    RegisterSpellScript(spell_dummysystem_caster_skeleton_king_bone_shield);
    new dummysystem_caster_spell_hooks();
}
