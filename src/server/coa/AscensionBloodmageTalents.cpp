/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionClientSpellPatches.h"
#include "AscensionPooledVitality.h"
#include "AscensionRealmClock.h"
#include "DBCStores.h"
#include "Group.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <list>
#include <utility>
#include <limits>
#include <vector>

namespace
{
enum BloodmageTalentSpells : uint32
{
    SPELL_LIQUIFY = 806310,
    SPELL_VAMPIRIC_POOLS = 504088,
    SPELL_VAMPIRIC_POOLS_LEECH = 806311,
    SPELL_DARKCASTING = 712383,
    SPELL_BLOOD_TEAR_SPAWN = 712417,
    SPELL_ACCURSED_FORM = 562572,
    SPELL_SANGUINE_SCRIPTURE = 804851,
    SPELL_SANGUINE_SCRIPTURE_BUFF = 504264,
    SPELL_CURSED_FORM_REQUIREMENT = 525031,
    SPELL_CURSED_FORM_REQUIREMENT_2 = 524861,
    SPELL_BLOODMOON_POWER = 801961,
    SPELL_ETERNAL_CURSE = 800157,
    SPELL_ETERNAL_CURSE_ARMOR = 804320,
    SPELL_ETERNAL_CURSE_TANK_STANCE = 807736,
    SPELL_BLOOD_SHIELD = 504296,
    SPELL_COAGULATION_DISPEL = 504102,
    SPELL_DARK_MARK = 705731,
    SPELL_DARK_MARK_AURA = 707375,
    SPELL_TERRORIZER = 806210,
    SPELL_ENDURING = 300585,
    SPELL_CLOTTING = 704115,
    SPELL_ADRENALINE_BOOST = 680675,
    SPELL_BLOOD_PLAGUE = 575335,
    SPELL_APPETITE_FOR_BLOOD = 560479,
    SPELL_DARK_SIGIL = 560535,
    SPELL_BLOODLORDS_CURSE = 707449,
    SPELL_BLOOD_MOON = 707623,
    SPELL_BLOOD_MOON_HEAL = 572786,
    SPELL_CURSED_BLOOD = 707435,
    SPELL_CURSED_BLOOD_RUPTURE = 707708,
    SPELL_BLOODSURGE = 553267,
    SPELL_BLOODCHASER = 523721,
    SPELL_BLOOD_BOND_REWARD = 505325,
    SPELL_BLOOD_BOND_SPEED = 505169,
    SPELL_GORE_TOME = 807788,
    SPELL_GORE_TOME_WINDOW = 808014,
    SPELL_ONE_MANS_CURSE = 680661,
    SPELL_ONE_MANS_CURSE_HEAL = 680662,
    SPELL_BLOOD_CONSTRUCTOR = 561196,
    SPELL_THIRST = 706613,
    SPELL_THIRST_ANIMATED_BLOOD = 300796,
    SPELL_CRIMSON_EXPEDITION = 523727,
    SPELL_SANGUINE_SCION = 807292,
    SPELL_BLOOD_RUNS_COLD = 560257,
    SPELL_CURSED_GROUND = 561195,
    SPELL_BLOOD_SCENT = 804223,
    SPELL_BLOOD_SCENT_LEECH = 807300,
    SPELL_ATHERANNS_ANGUISH = 680680,
    SPELL_ATHERANNS_ANGUISH_EXPLOSION = 680681,
    SPELL_NIGHT_STALKER_BUFF = 808013,
    SPELL_TRANSGRESSION = 801076,
    SPELL_VAMPIRIC_FEAST = 804934,
    SPELL_CARDIAC_ARREST_LEECH = 806946,
    SPELL_BLOOD_ORB_PERIODIC = 712418,
    SPELL_BLOOD_ORB_CDR = 712385,
    SPELL_SANGUINE_ESSENCE = 680692,
    SPELL_SANGUINE_ESSENCE_HEAL = 680693,
    SPELL_SANGUINE_ESSENCE_DAMAGE = 681399,
    SPELL_NIGHTMARE_TALENT = 300226,
    SPELL_NIGHTMARE_BUFF = 301273,
    SPELL_BLOOD_VEIL = 504263,
    SPELL_HUNTER_AND_HUNTED = 807487,
    SPELL_DARK_EMBRACE = 804854,
    SPELL_BLOODGALE = 681310,
    SPELL_INFUSE = 681403,
    SPELL_INFUSE_UNLEASH = 681404,
    SPELL_DARK_FRENZY = 704644,
    SPELL_DARK_FRENZY_GCD = 804845,
    SPELL_CRIMSON_SCION_INSTANT = 806425
};

constexpr uint32 NPC_BLOOD_ORB = 315303;
constexpr int32 AtherannsAnguishPercent = 30;
constexpr uint32 AtherannsAnguishScale = 100;
constexpr uint32 CardiacArrestDamagePercent = 50;

constexpr uint32 InfuseAccumulationPercent = 10;
constexpr uint32 InfuseDamageCapMultiplier = 3;
constexpr uint32 InfusePoolScale = 100;
constexpr uint32 InfuseRemainderScriptValue = SPELL_INFUSE_UNLEASH;

bool HasCursedForm(Player const* player, Aura const* ignored = nullptr);

void SyncDarkFrenzy(Player* player)
{
    if (!player || !player->IsAlive() || !player->IsInWorld() || !player->HasAura(SPELL_DARK_FRENZY))
        return;

    if (HasCursedForm(player))
    {
        if (!player->HasAura(SPELL_DARK_FRENZY_GCD))
            player->CastSpell(player, SPELL_DARK_FRENZY_GCD, true);
    }
    else
        player->RemoveAurasDueToSpell(SPELL_DARK_FRENZY_GCD);
}

constexpr uint32 SanguineRuptureMinimumTargets = 5;

constexpr uint32 BloodboltClassMask1 = 0x00020000;

enum AscensionRawCombatSelector : int32
{
    RAW_MASKED_CRIT = 20000,
    RAW_MASKED_CRIT_DAMAGE = 20001,
    RAW_CREATURE_DAMAGE = 20014
};

constexpr uint32 AnimatedBloodSummons[] = {325301, 335301, 315301};

constexpr uint32 CursedForms[] = {562572, 562720, 680692, 800157, 801076, 524865};
constexpr uint32 MortalAbilityForms[] = {680692, 801076};

constexpr float BloodVeilSpiritScale = 1.5f;
constexpr float BloodVeilAttackPowerScale = 0.75f;
constexpr uint32 BloodVeilRanks[] = {504263, 572277, 572278, 572279};

bool IsCursedForm(uint32 id)
{
    return std::find(std::begin(CursedForms), std::end(CursedForms), id) != std::end(CursedForms);
}

bool IsBloodVeilRank(uint32 id)
{
    return std::find(std::begin(BloodVeilRanks), std::end(BloodVeilRanks), id) != std::end(BloodVeilRanks);
}

bool BloodScentTarget(Unit const* player, Unit const* target)
{
    return player && target && target != player && !player->IsFriendlyTo(target) &&
        target->GetHealthPct() < 35.0f;
}

uint32 BloodScentDamage(Unit* target, Unit* attacker, uint32 amount)
{
    Player* player = attacker ? attacker->ToPlayer() : nullptr;
    if (!player || player->getClass() != CLASS_SON_OF_ARUGAL || !player->IsAlive() || !amount ||
        !BloodScentTarget(player, target) || !player->HasAura(SPELL_ACCURSED_FORM, player->GetGUID()))
        return amount;
    AuraEffect const* effect = player->GetAuraEffect(SPELL_BLOOD_SCENT, EFFECT_0, player->GetGUID());
    if (!effect || effect->GetAmount() <= 0)
        return amount;
    uint64 const result = uint64(amount) * (100 + uint64(effect->GetAmount())) / 100;
    return uint32(std::min<uint64>(result, std::numeric_limits<uint32>::max()));
}

class bloodmage_blood_scent_damage : public UnitScript
{
public:
    bloodmage_blood_scent_damage() : UnitScript("bloodmage_blood_scent_damage", true,
        {UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
        UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK}) { }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& amount) override
    {
        amount = BloodScentDamage(target, attacker, amount);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& amount, SpellInfo const* info) override
    {
        if (amount > 0 && info && !info->AscensionInheritsResolvedAmount)
            amount = int32(std::min<uint32>(BloodScentDamage(target, attacker, uint32(amount)),
                std::numeric_limits<int32>::max()));
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& amount,
        SpellInfo const* info) override
    {
        if (info && !info->AscensionInheritsResolvedAmount && !info->IsPositive() &&
            !info->HasAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT))
            amount = BloodScentDamage(target, attacker, amount);
    }
};

constexpr uint8 CursedFormWeaponSlots[] = {EQUIPMENT_SLOT_MAINHAND, EQUIPMENT_SLOT_OFFHAND, EQUIPMENT_SLOT_RANGED};

bool HasCursedForm(Player const* player, Aura const* ignored)
{
    for (uint32 form : CursedForms)
        if (Aura const* aura = player->GetAura(form, player->GetGUID()); aura && aura != ignored)
            return true;
    return false;
}

bool HasCursedFormRestrictingMortalAbilities(Player const* player)
{
    for (uint32 form : CursedForms)
    {
        if (std::find(std::begin(MortalAbilityForms), std::end(MortalAbilityForms), form) !=
            std::end(MortalAbilityForms))
            continue;
        if (player->HasAura(form, player->GetGUID()))
            return true;
    }
    return false;
}

void ClearVisibleWeapon(Player* player, uint8 slot)
{
    player->SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + slot * 2, 0);
    player->SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + slot * 2, 0);
}

void UpdateCursedFormWeapons(Player* player, bool hidden)
{
    for (uint8 slot : CursedFormWeaponSlots)
        if (hidden)
            ClearVisibleWeapon(player, slot);
        else
            player->SetVisibleItemSlot(slot, player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
}

void SyncCursedFormRequirement(Player* player)
{
    bool active = HasCursedForm(player);

    for (uint32 marker : {uint32(SPELL_CURSED_FORM_REQUIREMENT), uint32(SPELL_CURSED_FORM_REQUIREMENT_2)})
    {
        if (!active)
            player->RemoveAurasDueToSpell(marker, player->GetGUID());
        else if (player->IsInWorld() && player->IsAlive() && !player->HasAura(marker, player->GetGUID()))
            player->CastSpell(player, marker, true);
    }

    if (!HasCursedFormRestrictingMortalAbilities(player))
        player->RemoveAurasDueToSpell(AscensionBloodmage::CursedForm, player->GetGUID());
    else if (player->IsInWorld() && player->IsAlive() &&
        !player->HasAura(AscensionBloodmage::CursedForm, player->GetGUID()))
        player->CastSpell(player, AscensionBloodmage::CursedForm, true);
}

void ApplyBloodmageConditionalContracts(SpellInfo* info)
{
    auto scoped = [info](uint8 index, int32 raw, AuraType aura)
    {
        SpellEffectInfo& effect = info->Effects[index];
        if (effect.Effect != SPELL_EFFECT_APPLY_AURA ||
            effect.ApplyAuraName != SPELL_AURA_OVERRIDE_CLASS_SCRIPTS || effect.MiscValue != raw ||
            effect.MiscValueB <= 0 || !effect.SpellClassMask)
        {
            LOG_ERROR("coa", "Skipped unexpected Bloodmage scoped damage record {}",
                info->Id);
            return;
        }
        effect.ApplyAuraName = aura;
        std::swap(effect.MiscValue, effect.MiscValueB);
    };

    auto conditional = [info](uint8 index, int32 raw, int32 selector)
    {
        SpellEffectInfo& effect = info->Effects[index];
        if (effect.Effect != SPELL_EFFECT_APPLY_AURA ||
            effect.ApplyAuraName != SPELL_AURA_OVERRIDE_CLASS_SCRIPTS || effect.MiscValue != raw ||
            effect.MiscValueB <= 0 || !effect.SpellClassMask)
        {
            LOG_ERROR("coa", "Skipped unexpected Bloodmage conditional record {}",
                info->Id);
            return;
        }
        effect.MiscValue = selector;
    };

    switch (info->Id)
    {
        case SPELL_TERRORIZER:
        case SPELL_ENDURING:
            scoped(EFFECT_0, ASCENSION_CLASSMASK_AURASTATE_DAMAGE, SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE);
            break;
        case SPELL_CLOTTING:
            scoped(EFFECT_1, ASCENSION_CLASSMASK_AURASTATE_DAMAGE, SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE);
            break;
        case SPELL_APPETITE_FOR_BLOOD:
            scoped(EFFECT_0, RAW_CREATURE_DAMAGE, SPELL_AURA_MOD_DAMAGE_DONE_VERSUS);
            break;
        case SPELL_ADRENALINE_BOOST:
            conditional(EFFECT_0, RAW_MASKED_CRIT, ASCENSION_STATE_MASKED_CRIT);
            conditional(EFFECT_2, RAW_MASKED_CRIT, ASCENSION_STATE_MASKED_CRIT);
            break;
        case SPELL_BLOOD_PLAGUE:
            conditional(EFFECT_0, RAW_MASKED_CRIT, ASCENSION_STATE_MASKED_CRIT);
            conditional(EFFECT_1, RAW_MASKED_CRIT_DAMAGE, ASCENSION_STATE_MASKED_CRIT_DAMAGE);
            break;
        default:
            break;
    }
}

class spell_ascension_animated_blood : public SpellScript
{
    PrepareSpellScript(spell_ascension_animated_blood);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_DARKCASTING, SPELL_BLOOD_TEAR_SPAWN});
    }

    void HandleExtraWorms(SpellEffIndex index)
    {
        if (GetSpellInfo()->Effects[index].TriggerSpell != SPELL_BLOOD_TEAR_SPAWN)
            return;
        PreventHitDefaultEffect(index);
        Unit* caster = GetCaster();
        Aura* darkcasting = caster->GetAura(SPELL_DARKCASTING, caster->GetGUID());
        if (!darkcasting)
            return;
        uint8 const count = darkcasting->GetStackAmount();
        darkcasting->Remove();
        if (count)
            caster->CastCustomSpell(SPELL_BLOOD_TEAR_SPAWN, SPELLVALUE_BASE_POINT0, count, caster, true);
    }

    void ReplacePreviousBrood()
    {
        if (Unit* caster = GetCaster())
            for (uint32 entry : AnimatedBloodSummons)
                caster->RemoveAllMinionsByEntry(entry);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_animated_blood::ReplacePreviousBrood);
        OnEffectLaunch += SpellEffectFn(spell_ascension_animated_blood::HandleExtraWorms,
            EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL);
    }
};

struct npc_ascension_animated_blood : public ScriptedAI
{
    npc_ascension_animated_blood(Creature* creature) : ScriptedAI(creature) { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        me->SetReactState(REACT_DEFENSIVE);
        Unit* owner = summoner ? summoner->ToUnit() : nullptr;
        if (!owner || !owner->IsInCombat())
            return;
        if (Unit* target = owner->GetVictim(); target && me->CanStartAttack(target, true))
            AttackStart(target);
    }
};

void HunterAndHuntedCharge(Player* player)
{
    if (!player || !player->IsAlive() || !player->IsInWorld())
        return;
    Unit* target = ObjectAccessor::GetUnit(*player, player->GetTarget());
    if (!target)
        target = player->GetVictim();
    SpellInfo const* darkEmbrace = sSpellMgr->GetSpellInfo(SPELL_DARK_EMBRACE);
    if (!darkEmbrace || !target || target == player || !target->IsAlive() || !target->IsInWorld() ||
        player->GetMap() != target->GetMap() || !player->IsValidAttackTarget(target) ||
        !player->IsWithinDistInMap(target, darkEmbrace->GetMaxRange()))
        return;
    player->CastSpell(target, SPELL_DARK_EMBRACE, true);
}

void ArmHunterAndHuntedReactivation(Player* player)
{
    if (!player || player->GetTemporarySpellReplacement(SPELL_ACCURSED_FORM) == SPELL_BLOODGALE)
        return;
    if (player->GetSpellMap().find(SPELL_BLOODGALE) == player->GetSpellMap().end())
        player->learnSpell(SPELL_BLOODGALE, true);
    player->SetTemporarySpellReplacement(SPELL_ACCURSED_FORM, SPELL_BLOODGALE);
}

void ClearHunterAndHuntedReactivation(Player* player)
{
    if (!player || player->GetTemporarySpellReplacement(SPELL_ACCURSED_FORM) != SPELL_BLOODGALE)
        return;
    player->SetTemporarySpellReplacement(SPELL_ACCURSED_FORM, 0);
    player->removeSpell(SPELL_BLOODGALE, SPEC_MASK_ALL, true);
}

class bloodmage_talent_events : public UnitScript
{
public:
    bloodmage_talent_events() : UnitScript("bloodmage_talent_events", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL || !aura)
            return;
        if (IsCursedForm(aura->GetId()))
        {
            SyncCursedFormRequirement(player);
            SyncDarkFrenzy(player);
        }
        if (IsCursedForm(aura->GetId()))
            UpdateCursedFormWeapons(player, true);
        if (aura->GetId() == SPELL_ETERNAL_CURSE)
        {
            player->CastSpell(player, SPELL_ETERNAL_CURSE_ARMOR, true);
            player->CastSpell(player, SPELL_ETERNAL_CURSE_TANK_STANCE, true);
        }
        if (aura->GetId() == SPELL_DARK_MARK)
            player->CastSpell(player, SPELL_DARK_MARK_AURA, true);
        if (IsCursedForm(aura->GetId()) && aura->GetCasterGUID() == player->GetGUID() &&
            player->HasAura(SPELL_GORE_TOME, player->GetGUID()))
            player->CastSpell(player, SPELL_GORE_TOME_WINDOW, true);
        if (IsCursedForm(aura->GetId()) && aura->GetCasterGUID() == player->GetGUID() &&
            player->HasAura(SPELL_HUNTER_AND_HUNTED, player->GetGUID()))
        {
            ClearHunterAndHuntedReactivation(player);
            HunterAndHuntedCharge(player);
        }
        if (aura->GetId() == SPELL_ACCURSED_FORM && aura->GetCasterGUID() == player->GetGUID() &&
            player->HasAura(SPELL_ONE_MANS_CURSE, player->GetGUID()))
            player->CastSpell(player, SPELL_ONE_MANS_CURSE_HEAL, true);
        if (aura->GetId() == SPELL_ACCURSED_FORM && aura->GetCasterGUID() == player->GetGUID() &&
            player->HasAura(SPELL_BLOODSURGE, player->GetGUID()))
        {
            player->RemoveAurasDueToSpell(SPELL_BLOODSURGE, player->GetGUID());
            player->CastSpell(player, SPELL_BLOODCHASER, true);
        }
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode mode) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL || !application)
            return;
        Aura* aura = application->GetBase();
        if (IsCursedForm(aura->GetId()))
        {
            SyncCursedFormRequirement(player);
            SyncDarkFrenzy(player);
        }
        if (IsCursedForm(aura->GetId()) && !HasCursedForm(player, aura))
            UpdateCursedFormWeapons(player, false);
        if (aura->GetId() == SPELL_ETERNAL_CURSE)
        {
            player->RemoveAurasDueToSpell(SPELL_ETERNAL_CURSE_ARMOR);
            player->RemoveAurasDueToSpell(SPELL_ETERNAL_CURSE_TANK_STANCE);
        }
        if (aura->GetId() == SPELL_DARK_MARK)
            player->RemoveAurasDueToSpell(SPELL_DARK_MARK_AURA, player->GetGUID());
        if (aura->GetId() == SPELL_NIGHTMARE_TALENT)
            player->RemoveAurasDueToSpell(SPELL_NIGHTMARE_BUFF);
        if (aura->GetId() == SPELL_HUNTER_AND_HUNTED)
            ClearHunterAndHuntedReactivation(player);
        if (!player->IsAlive() || !player->IsInWorld() || mode == AURA_REMOVE_BY_DEATH)
            return;
        if (aura->GetId() == SPELL_LIQUIFY && aura->GetCasterGUID() == player->GetGUID() &&
            player->HasAura(SPELL_VAMPIRIC_POOLS))
            player->CastSpell(player, SPELL_VAMPIRIC_POOLS_LEECH, true);
        if (aura->GetId() == SPELL_LIQUIFY && aura->GetCasterGUID() == player->GetGUID() &&
            player->HasAura(SPELL_BLOODMOON_POWER))
        {
            std::vector<uint32> remove;
            for (auto const& pair : player->GetAppliedAuras())
                if (!pair.second->IsPositive() && pair.second->GetBase()->GetSpellInfo()->Dispel != DISPEL_NONE)
                    remove.push_back(pair.second->GetBase()->GetId());
            for (uint32 id : remove)
                player->RemoveAurasDueToSpell(id);
        }
        if (aura->GetId() == SPELL_ACCURSED_FORM && aura->GetCasterGUID() == player->GetGUID() &&
            player->HasAura(SPELL_SANGUINE_SCRIPTURE))
            player->CastSpell(player, SPELL_SANGUINE_SCRIPTURE_BUFF, true);
        if (aura->GetId() == SPELL_ACCURSED_FORM && aura->GetCasterGUID() == player->GetGUID() &&
            mode == AURA_REMOVE_BY_EXPIRE && player->HasAura(SPELL_HUNTER_AND_HUNTED, player->GetGUID()))
            ArmHunterAndHuntedReactivation(player);
        if (aura->GetId() == SPELL_BLOODSURGE && aura->GetCasterGUID() == player->GetGUID() &&
            mode == AURA_REMOVE_BY_EXPIRE)
            player->CastSpell(player, SPELL_BLOODCHASER, true);
    }
};

class bloodmage_cursed_form_death : public PlayerScript
{
public:
    bloodmage_cursed_form_death() : PlayerScript("bloodmage_cursed_form_death", {PLAYERHOOK_ON_PLAYER_JUST_DIED}) { }

    void OnPlayerJustDied(Player* player) override
    {
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL)
            return;
        for (uint32 form : CursedForms)
            player->RemoveAurasDueToSpell(form);
        SyncCursedFormRequirement(player);
        player->RemoveAurasDueToSpell(SPELL_DARK_FRENZY_GCD);
        ClearHunterAndHuntedReactivation(player);
    }
};

class bloodmage_cursed_form_weapons : public PlayerScript
{
public:
    bloodmage_cursed_form_weapons() : PlayerScript("bloodmage_cursed_form_weapons",
        {PLAYERHOOK_ON_AFTER_SET_VISIBLE_ITEM_SLOT}) { }

    void OnPlayerAfterSetVisibleItemSlot(Player* player, uint8 slot, Item*) override
    {
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL)
            return;
        if (std::find(std::begin(CursedFormWeaponSlots), std::end(CursedFormWeaponSlots), slot) ==
            std::end(CursedFormWeaponSlots) || !HasCursedForm(player))
            return;
        ClearVisibleWeapon(player, slot);
    }
};

class bloodmage_blood_constructor : public PlayerScript
{
public:
    bloodmage_blood_constructor() : PlayerScript("bloodmage_blood_constructor",
        {PLAYERHOOK_ON_BEFORE_TEMP_SUMMON_INIT_STATS}) { }

    void OnPlayerBeforeTempSummonInitStats(Player* player, TempSummon* summon, uint32& duration) override
    {
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL || !summon || !duration)
            return;
        if (std::find(std::begin(AnimatedBloodSummons), std::end(AnimatedBloodSummons), summon->GetEntry())
            == std::end(AnimatedBloodSummons))
            return;
        if (!player->HasAura(SPELL_BLOOD_CONSTRUCTOR, player->GetGUID()))
            return;
        Aura const* thirst = player->GetAura(SPELL_THIRST, player->GetGUID());
        SpellInfo const* helper = sSpellMgr->GetSpellInfo(SPELL_THIRST_ANIMATED_BLOOD);
        if (!thirst || !helper)
            return;
        int32 const perStack = helper->Effects[EFFECT_0].CalcValue(player);
        if (perStack > 0)
            duration += uint32(perStack) * thirst->GetStackAmount();
    }
};

bool IsBloodmageDamageProc(Unit* player, Unit* caster, ProcEventInfo& event)
{
    Unit* victim = event.GetActionTarget();
    DamageInfo const* damage = event.GetDamageInfo();
    return player->IsPlayer() && player->getClass() == CLASS_SON_OF_ARUGAL && player->IsAlive() &&
        caster == player && event.GetActor() == player && victim && victim != player &&
        !player->IsFriendlyTo(victim) && damage && damage->GetDamage();
}

int32 BloodmageProcShare(AuraEffect const* effect, ProcEventInfo& event)
{
    uint64 share = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
    return int32(std::min<uint64>(share, std::numeric_limits<int32>::max()));
}

class spell_ascension_bloodmage_sanguine_rupture : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_sanguine_rupture);

    void HandleBleed(SpellEffIndex effIndex)
    {
        bool shouldBleed = GetCaster()->HasAura(SPELL_CURSED_GROUND);
        if (shouldBleed)
        {
            uint32 successfulTargets = 0;
            for (auto const& target : *GetSpell()->GetUniqueTargetInfo())
                if ((target.effectMask & (1 << EFFECT_1)) && target.missCondition == SPELL_MISS_NONE)
                    ++successfulTargets;

            shouldBleed = successfulTargets >= SanguineRuptureMinimumTargets;
        }

        if (!shouldBleed)
            PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_bloodmage_sanguine_rupture::HandleBleed,
            EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL);
    }
};

class aura_ascension_bloodmage_blood_scent : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_blood_scent);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_BLOOD_SCENT_LEECH}); }

    bool Check(ProcEventInfo& event)
    {
        SpellInfo const* info = event.GetSpellInfo();
        return IsBloodmageDamageProc(GetTarget(), GetCaster(), event) &&
            BloodScentTarget(GetTarget(), event.GetActionTarget()) &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) && (!info || info->Id != SPELL_BLOOD_SCENT_LEECH);
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (int32 amount = BloodmageProcShare(effect, event))
            GetTarget()->CastCustomSpell(SPELL_BLOOD_SCENT_LEECH, SPELLVALUE_BASE_POINT0, amount,
                event.GetActionTarget(), TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_blood_scent::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_bloodmage_blood_scent::Proc, EFFECT_1, AuraType(354));
    }
};

class aura_ascension_bloodmage_dark_sigil : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_dark_sigil);

    bool Check(ProcEventInfo& event)
    {
        return IsBloodmageDamageProc(GetTarget(), GetCaster(), event) && (event.GetHitMask() & PROC_HIT_CRITICAL);
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (int32 heal = BloodmageProcShare(effect, event))
            GetTarget()->CastCustomSpell(SPELL_BLOODLORDS_CURSE, SPELLVALUE_BASE_POINT0, heal, GetTarget(),
                TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_dark_sigil::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_bloodmage_dark_sigil::Proc, EFFECT_1, AuraType(354));
    }
};

class aura_ascension_bloodmage_thick_pelt : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_thick_pelt);

    void Calculate(AuraEffect const*, int32& amount, bool&)
    {
        Unit* caster = GetCaster();
        amount = caster ? std::min(0, 15 - int32(caster->GetTotalAttackPowerValue(BASE_ATTACK) * 0.2f)) : 0;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_bloodmage_thick_pelt::Calculate,
            EFFECT_0, SPELL_AURA_MOD_DAMAGE_TAKEN);
    }
};

constexpr float BloodMoonHealthThreshold = 75.0f;

class aura_ascension_bloodmage_blood_moon : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_blood_moon);

    bool Check(ProcEventInfo& event)
    {
        return IsBloodmageDamageProc(GetTarget(), GetCaster(), event) &&
            GetTarget()->GetHealthPct() < BloodMoonHealthThreshold;
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (int32 heal = BloodmageProcShare(effect, event))
            GetTarget()->CastCustomSpell(SPELL_BLOOD_MOON_HEAL, SPELLVALUE_BASE_POINT0, heal, GetTarget(),
                TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_blood_moon::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_bloodmage_blood_moon::Proc, EFFECT_0, AuraType(354));
    }
};

class aura_ascension_bloodmage_cursed_blood : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_cursed_blood);

    bool Check(ProcEventInfo& event)
    {
        return IsBloodmageDamageProc(GetTarget(), GetCaster(), event);
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (int32 damage = BloodmageProcShare(effect, event))
            GetTarget()->CastCustomSpell(SPELL_CURSED_BLOOD_RUPTURE, SPELLVALUE_BASE_POINT0, damage,
                event.GetActionTarget(), TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_cursed_blood::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_bloodmage_cursed_blood::Proc, EFFECT_0, AuraType(354));
    }
};

class aura_ascension_bloodmage_transgression : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_transgression);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_TRANSGRESSION &&
            info->Effects[EFFECT_2].IsAura(AuraType(354)) &&
            info->Effects[EFFECT_2].TriggerSpell == SPELL_VAMPIRIC_FEAST &&
            ValidateSpellInfo({SPELL_VAMPIRIC_FEAST});
    }

    bool Check(ProcEventInfo& event)
    {
        return IsBloodmageDamageProc(GetTarget(), GetCaster(), event);
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (int32 damage = BloodmageProcShare(effect, event))
            GetTarget()->CastCustomSpell(SPELL_VAMPIRIC_FEAST, SPELLVALUE_BASE_POINT0, damage,
                event.GetActionTarget(), TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_transgression::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_bloodmage_transgression::Proc, EFFECT_2, AuraType(354));
    }
};

class aura_ascension_bloodmage_crimson_feast : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_crimson_feast);

    void Tick(AuraEffect const*)
    {
        Player* player = GetTarget() ? GetTarget()->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL || !HasCursedForm(player))
            PreventDefaultAction();
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_bloodmage_crimson_feast::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class aura_ascension_bloodmage_coagulation : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_coagulation);

    void Tick(AuraEffect const*)
    {
        Unit* target = GetTarget();
        if (!target || !target->HasAura(SPELL_BLOOD_SHIELD, target->GetGUID()))
            PreventDefaultAction();
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_bloodmage_coagulation::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

constexpr uint32 TaldaramsTormentEnergizeRage = 30;

class aura_ascension_bloodmage_taldarams_torment : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_taldarams_torment);

    void Tick(AuraEffect const*)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;
        caster->EnergizeBySpell(caster, GetId(), TaldaramsTormentEnergizeRage, POWER_RAGE);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_bloodmage_taldarams_torment::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

class aura_ascension_bloodmage_forbidden_power : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_forbidden_power);

    void Calculate(AuraEffect const*, int32& amount, bool&)
    {
        amount = 0;
        Player* player = GetUnitOwner() ? GetUnitOwner()->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL)
            return;
        uint32 rating = player->GetUInt32Value(
            static_cast<uint16>(PLAYER_FIELD_COMBAT_RATING_1) + static_cast<uint16>(CR_ARMOR_PENETRATION));
        amount = -int32(std::min<uint32>(rating, uint32(std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_bloodmage_forbidden_power::Calculate,
            EFFECT_0, SPELL_AURA_MOD_TARGET_RESISTANCE);
    }
};

constexpr float EssenceHarvesterHealthThreshold = 35.0f;

class aura_ascension_bloodmage_essence_harvester : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_essence_harvester);

    bool Check(ProcEventInfo& event)
    {
        Unit* target = GetTarget();
        Unit* attacker = event.GetActor();
        return target && target->IsPlayer() && target->IsAlive() && attacker && attacker != target &&
            !target->IsFriendlyTo(attacker) && target->GetHealthPct() < EssenceHarvesterHealthThreshold;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_essence_harvester::Check);
    }
};

class aura_ascension_bloodmage_blood_bond : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_blood_bond);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_BLOOD_BOND_REWARD, SPELL_BLOOD_BOND_SPEED});
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetCaster();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner && owner->IsPlayer() && owner->IsAlive() && owner->IsInWorld() && GetTarget() &&
            GetTarget() != owner && damage && damage->GetDamage();
    }

    void Proc(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        if (Unit* owner = GetCaster())
            owner->CastSpell(owner, SPELL_BLOOD_BOND_REWARD, true);
    }

    void Speed(AuraEffect const*)
    {
        Unit* target = GetTarget();
        Unit* caster = GetCaster();
        if (!target->IsInCombat() && !target->IsPetInCombat() &&
            (!caster || (!caster->IsInCombat() && !caster->IsPetInCombat())))
            return;
        PreventDefaultAction();
        target->RemoveAurasDueToSpell(SPELL_BLOOD_BOND_SPEED, GetCasterGUID());
        if (caster)
            caster->RemoveAurasDueToSpell(SPELL_BLOOD_BOND_SPEED, GetCasterGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_blood_bond::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_bloodmage_blood_bond::Proc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_bloodmage_blood_bond::Speed, EFFECT_1,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class aura_ascension_bloodmage_atheranns_anguish : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_atheranns_anguish);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
            spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_ATHERANNS_ANGUISH_EXPLOSION &&
            spellInfo->Effects[EFFECT_1].IsAura(SPELL_AURA_DUMMY) &&
            spellInfo->Effects[EFFECT_1].MiscValueB == AtherannsAnguishPercent &&
            spellInfo->Effects[EFFECT_2].IsAura(SPELL_AURA_DUMMY) &&
            ValidateSpellInfo({SPELL_ATHERANNS_ANGUISH_EXPLOSION});
    }

    void Calculate(AuraEffect const*, int32& amount, bool& canBeRecalculated)
    {
        amount = 0;
        canBeRecalculated = false;
    }

    bool Check(ProcEventInfo& event)
    {
        DamageInfo const* damage = event.GetDamageInfo();
        Unit* caster = GetCaster();
        return caster && damage && damage->GetDamage() && event.GetActor() == caster &&
            damage->GetAttacker() == caster && damage->GetVictim() == GetTarget() &&
            (!damage->GetSpellInfo() || damage->GetSpellInfo()->Id != SPELL_ATHERANNS_ANGUISH_EXPLOSION);
    }

    void Accumulate(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        AuraEffect* remainder = GetEffect(EFFECT_2);
        uint64 total = uint64(std::max(0, effect->GetAmount())) * AtherannsAnguishScale;
        if (remainder)
            total += uint64(std::clamp(remainder->GetAmount(), 0, int32(AtherannsAnguishScale - 1)));
        total += uint64(event.GetDamageInfo()->GetDamage()) * AtherannsAnguishPercent;
        total = std::min(total, uint64(std::numeric_limits<int32>::max()) * AtherannsAnguishScale);
        GetEffect(EFFECT_0)->SetAmount(int32(total / AtherannsAnguishScale));
        if (remainder)
            remainder->SetAmount(int32(total % AtherannsAnguishScale));
    }

    void Explode(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;

        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        int32 const amount = effect->GetAmount();
        if (!caster || !caster->IsAlive() || !caster->IsInWorld() || !target->IsAlive() || !target->IsInWorld() ||
            caster->GetMap() != target->GetMap() || amount <= 0)
            return;

        caster->CastCustomSpell(SPELL_ATHERANNS_ANGUISH_EXPLOSION, SPELLVALUE_BASE_POINT0, amount, target,
            TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_bloodmage_atheranns_anguish::Calculate,
            EFFECT_ALL, SPELL_AURA_DUMMY);
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_atheranns_anguish::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_bloodmage_atheranns_anguish::Accumulate,
            EFFECT_0, SPELL_AURA_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_bloodmage_atheranns_anguish::Explode,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_bloodmage_atheranns_anguish_explosion : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_atheranns_anguish_explosion);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_0];
        return effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE && effect.DieSides == 1 &&
            !effect.RealPointsPerLevel && !effect.PointsPerComboPoint;
    }

    bool Load() override
    {
        return GetSpell()->IsTriggered();
    }

    void SetAccumulatedDamage(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        int64 const amount = int64(GetSpellValue()->EffectBasePoints[EFFECT_0]) + 1;
        SetHitDamage(int32(std::clamp<int64>(amount, 0, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(
            spell_ascension_bloodmage_atheranns_anguish_explosion::SetAccumulatedDamage,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

bool IsInfuseContributor(Unit* caster, Unit* attacker)
{
    if (!caster || !attacker)
        return false;
    if (attacker == caster)
        return true;

    Player* casterPlayer = caster->GetCharmerOrOwnerPlayerOrPlayerItself();
    Unit* source = attacker->GetCharmerOrOwnerPlayerOrPlayerItself();
    if (!casterPlayer || !source)
        return false;
    if (source == casterPlayer)
        return true;

    Group* group = casterPlayer->GetGroup();
    return group && group->IsMember(source->GetGUID());
}

class spell_ascension_bloodmage_infuse_unleash : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_infuse_unleash);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_0];
        return spellInfo->Id == SPELL_INFUSE_UNLEASH && effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
            effect.DieSides == 1 && !effect.RealPointsPerLevel && !effect.PointsPerComboPoint;
    }

    bool Load() override
    {
        return GetSpell()->IsTriggered();
    }

    void SetStoredDamage(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        SetHitDamage(GetSpellValue()->EffectBasePoints[EFFECT_0] + 1);
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(
            spell_ascension_bloodmage_infuse_unleash::SetStoredDamage,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class aura_ascension_bloodmage_infuse : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_infuse);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo->SpellFamilyName == 26 &&
            spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
            spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_INFUSE_UNLEASH &&
            spellInfo->Effects[EFFECT_1].IsAura() &&
            ValidateSpellInfo({SPELL_INFUSE_UNLEASH});
    }

    void Unleash(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;

        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        uint64 const stored = GetAura()->GetScriptValue(SPELL_INFUSE);
        if (!caster || !caster->IsAlive() || !caster->IsInWorld() || !target->IsAlive() ||
            !target->IsInWorld() || caster->GetMap() != target->GetMap() || !stored)
            return;

        caster->CastCustomSpell(SPELL_INFUSE_UNLEASH, SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(stored, uint64(std::numeric_limits<int32>::max()))), target,
            TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_bloodmage_infuse::Unleash,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class bloodmage_infuse_accumulation : public UnitScript
{
public:
    bloodmage_infuse_accumulation() : UnitScript("bloodmage_infuse_accumulation", true,
        {UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
        UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_ON_BEFORE_HEAL_ABSORB}) { }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& amount) override
    {
        Accumulate(target, attacker, amount);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& amount,
        SpellInfo const* info) override
    {
        if (amount > 0 && info && !info->AscensionInheritsResolvedAmount)
            Accumulate(target, attacker, uint32(amount));
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& amount,
        SpellInfo const* info) override
    {
        if (info && !info->AscensionInheritsResolvedAmount && !info->IsPositive() &&
            !info->HasAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT))
            Accumulate(target, attacker, amount);
    }

private:
    void Accumulate(Unit* victim, Unit* attacker, uint32 damage)
    {
        if (!damage || !attacker || !victim || attacker == victim || !victim->HasAura(SPELL_INFUSE))
            return;

        for (AuraEffect* effect : victim->GetAuraEffectsByType(SPELL_AURA_DUMMY))
        {
            if (effect->GetId() != SPELL_INFUSE || effect->GetEffIndex() != EFFECT_0)
                continue;

            Aura* aura = effect->GetBase();
            Unit* caster = aura->GetCaster();
            if (aura->IsRemoved() || !caster || !IsInfuseContributor(caster, attacker))
                continue;

            uint64 const cap = uint64(caster->GetMaxHealth()) * InfuseDamageCapMultiplier;
            uint64 const pool = aura->GetScriptValue(SPELL_INFUSE);
            uint64 const remainder = aura->GetScriptValue(InfuseRemainderScriptValue);
            uint64 const total = pool * InfusePoolScale + remainder +
                uint64(damage) * InfuseAccumulationPercent;
            uint64 const scaled = total / InfusePoolScale;
            uint64 const stored = std::min<uint64>(scaled, cap);
            uint32 const leftover = scaled <= cap ? uint32(total % InfusePoolScale) : 0;
            if (stored == pool && leftover == remainder)
                continue;

            aura->SetScriptValue(SPELL_INFUSE, stored);
            aura->SetScriptValue(InfuseRemainderScriptValue, leftover);
            if (AuraEffect* absorb = aura->GetEffect(EFFECT_1))
                absorb->SetAmount(int32(std::min<uint64>(stored, uint64(std::numeric_limits<int32>::max()))));
        }
    }

    void OnBeforeHealAbsorb(HealInfo& healInfo) override
    {
        Unit* target = healInfo.GetTarget();
        if (!healInfo.GetHeal() || !target || !target->HasAura(SPELL_INFUSE))
            return;

        for (AuraEffect* effect : target->GetAuraEffectsByType(SPELL_AURA_DUMMY))
        {
            if (effect->GetId() != SPELL_INFUSE || effect->GetEffIndex() != EFFECT_0)
                continue;

            AuraEffect* absorb = effect->GetBase()->GetEffect(EFFECT_1);
            int32 const capacity = absorb ? absorb->GetAmount() : 0;
            uint32 const absorbed = std::min<uint32>(uint32(std::max(0, capacity)), healInfo.GetHeal());
            if (!absorbed)
                continue;

            absorb->SetAmount(capacity - int32(absorbed));
            healInfo.AbsorbHeal(absorbed);
        }
    }
};

class aura_ascension_bloodmage_night_stalker : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_night_stalker);

    void Tick(AuraEffect const*)
    {
        Unit* target = GetTarget();
        if (AscensionRealmClock::IsNight() || !target->IsOutdoors() || target->GetMap()->IsDungeon())
            return;

        PreventDefaultAction();
        target->RemoveAurasDueToSpell(SPELL_NIGHT_STALKER_BUFF, target->GetGUID());
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_bloodmage_night_stalker::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class aura_ascension_bloodmage_sanguine_essence : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_sanguine_essence);

    bool Validate(SpellInfo const* info) override
    {
        SpellInfo const* heal = sSpellMgr->GetSpellInfo(SPELL_SANGUINE_ESSENCE_HEAL);
        SpellInfo const* damage = sSpellMgr->GetSpellInfo(SPELL_SANGUINE_ESSENCE_DAMAGE);
        return info->Id == SPELL_SANGUINE_ESSENCE && info->Effects[EFFECT_0].IsAura(AuraType(354)) &&
            info->Effects[EFFECT_0].TriggerSpell == SPELL_SANGUINE_ESSENCE_HEAL && heal &&
            heal->Effects[EFFECT_0].IsAura(SPELL_AURA_PERIODIC_HEAL) && damage &&
            damage->Effects[EFFECT_0].IsAura(SPELL_AURA_PERIODIC_DAMAGE);
    }

    bool Check(ProcEventInfo& event)
    {
        SpellInfo const* info = event.GetSpellInfo();
        HealInfo const* heal = event.GetHealInfo();
        DamageInfo const* damage = event.GetDamageInfo();
        if (!info || event.GetActor() != GetTarget())
            return false;
        if (AscensionBloodmage::GetEmpowerment(info->Id) == AscensionBloodmage::Mend)
            return heal && heal->GetHeal() && heal->GetTarget() && heal->GetTarget()->IsAlive();
        return info->SpellFamilyName == 26 && (info->SpellFamilyFlags[1] & 8192) && damage &&
            damage->GetDamage() && damage->GetVictim() && damage->GetVictim()->IsAlive();
    }

    void Replicate(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        HealInfo const* healing = event.GetHealInfo();
        uint64 const resolved = healing ? healing->GetHeal() : event.GetDamageInfo()->GetDamage();
        uint64 const amount = resolved *
            uint32(std::clamp(effect->GetAmount(), 0, 100)) / 100;
        if (!amount)
            return;

        int32 const perTick = int32(std::min<uint64>(amount, std::numeric_limits<int32>::max()));
        Unit* target = healing ? healing->GetTarget() : event.GetDamageInfo()->GetVictim();
        uint32 const spellId = healing ? SPELL_SANGUINE_ESSENCE_HEAL : SPELL_SANGUINE_ESSENCE_DAMAGE;
        GetTarget()->CastCustomSpell(spellId, SPELLVALUE_BASE_POINT0,
            perTick, target, TRIGGERED_FULL_MASK, nullptr, effect);
        if (AuraEffect* echo = target->GetAuraEffect(spellId, EFFECT_0,
            GetTarget()->GetGUID()))
        {
            echo->SetAmount(perTick);
            echo->SetCritChance(0.0f);
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_sanguine_essence::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_bloodmage_sanguine_essence::Replicate,
            EFFECT_0, AuraType(354));
    }
};

class aura_ascension_bloodmage_cardiac_arrest : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_cardiac_arrest);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_CARDIAC_ARREST_LEECH}); }

    bool Check(ProcEventInfo& event)
    {
        return IsBloodmageDamageProc(GetTarget(), GetCaster(), event);
    }

    void Proc(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        SpellInfo const* leech = sSpellMgr->AssertSpellInfo(SPELL_CARDIAC_ARREST_LEECH);
        int32 const amplitude = leech->Effects[EFFECT_0].Amplitude;
        int32 const duration = leech->GetMaxDuration();
        if (amplitude <= 0 || duration < amplitude)
            return;

        uint64 const ticks = uint64(duration / amplitude);
        uint64 const perTick = uint64(event.GetDamageInfo()->GetDamage()) * CardiacArrestDamagePercent / 100 / ticks;
        if (perTick)
            GetTarget()->CastCustomSpell(SPELL_CARDIAC_ARREST_LEECH, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(perTick, std::numeric_limits<int32>::max())), event.GetActionTarget(),
                TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_cardiac_arrest::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_bloodmage_cardiac_arrest::Proc, EFFECT_0, AuraType(354));
    }
};

class spell_ascension_bloodmage_lunge : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_lunge);

    void FaceTarget(SpellEffIndex)
    {
        Unit* target = GetExplTargetUnit();
        WorldLocation const* destination = GetExplTargetDest();
        if (target && destination)
            GetSpell()->SetJumpFinalOrientation(destination->GetAngle(target));
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_bloodmage_lunge::FaceTarget,
            EFFECT_0, SPELL_EFFECT_JUMP_DEST);
    }
};

class spell_ascension_bloodmage_blood_orb_spawn : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_blood_orb_spawn);

    void Summon(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        int32 duration = GetSpellInfo()->GetDuration();
        if (!player || duration <= 0)
            return;

        player->ApplySpellMod(GetSpellInfo()->Id, SPELLMOD_DURATION, duration);
        Position const position =
            player->GetRandomPoint(*player, GetSpellInfo()->Effects[index].CalcRadius(player));
        if (TempSummon* orb = player->SummonCreature(NPC_BLOOD_ORB, position, TEMPSUMMON_TIMED_DESPAWN,
            uint32(duration)))
            orb->SetUInt32Value(UNIT_CREATED_BY_SPELL, GetSpellInfo()->Id);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_bloodmage_blood_orb_spawn::Summon,
            EFFECT_0, SPELL_EFFECT_SUMMON);
    }
};

struct npc_ascension_bloodmage_blood_orb : public ScriptedAI
{
    explicit npc_ascension_bloodmage_blood_orb(Creature* creature) : ScriptedAI(creature) { }

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void EnterEvadeMode(EvadeReason) override { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = summoner ? summoner->ToPlayer() : nullptr;
        if (!player)
        {
            me->DespawnOrUnsummon();
            return;
        }

        me->SetOwnerGUID(player->GetGUID());
        me->SetReactState(REACT_PASSIVE);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveIdle();
        me->CastSpell(me, SPELL_BLOOD_ORB_PERIODIC, true);
    }
};

class spell_ascension_bloodmage_blood_orb_pickup : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_blood_orb_pickup);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_DARKCASTING, SPELL_BLOOD_ORB_PERIODIC, SPELL_BLOOD_ORB_CDR});
    }

    void SelectOwner(std::list<WorldObject*>& targets)
    {
        ObjectGuid const owner = GetCaster()->GetOwnerGUID();
        targets.remove_if([owner](WorldObject* object)
        {
            Unit* unit = object->ToUnit();
            return !unit || unit->GetGUID() != owner || !unit->IsAlive();
        });
    }

    void Collect(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Creature* orb = GetCaster()->ToCreature();
        Unit* owner = GetHitUnit();
        if (!orb || !owner || !orb->HasAura(SPELL_BLOOD_ORB_PERIODIC))
            return;

        orb->RemoveAurasDueToSpell(SPELL_BLOOD_ORB_PERIODIC);
        owner->CastSpell(owner, SPELL_DARKCASTING, true);
        owner->CastSpell(owner, SPELL_BLOOD_ORB_CDR, true);
        orb->DespawnOrUnsummon();
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(
            spell_ascension_bloodmage_blood_orb_pickup::SelectOwner, EFFECT_0, TARGET_UNIT_SRC_AREA_ALLY);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_bloodmage_blood_orb_pickup::Collect,
            EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL);
    }
};

class aura_ascension_blood_veil : public AuraScript
{
    PrepareAuraScript(aura_ascension_blood_veil);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo->SpellFamilyName == 26 &&
            spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
            spellInfo->Effects[EFFECT_1].IsAura(SPELL_AURA_SCHOOL_ABSORB) &&
            spellInfo->Effects[EFFECT_0].BasePoints + 1 > 0;
    }

    void Calculate(AuraEffect const*, int32& amount, bool& recalculate)
    {
        Player* caster = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!caster)
            return;
        amount += int32(caster->GetStat(STAT_SPIRIT) * BloodVeilSpiritScale +
            caster->GetTotalAttackPowerValue(BASE_ATTACK) * BloodVeilAttackPowerScale);
        recalculate = false;
    }

    void Absorb(AuraEffect*, DamageInfo& damage, uint32& absorb)
    {
        uint32 const percent = uint32(std::clamp(GetSpellInfo()->Effects[EFFECT_0].BasePoints + 1, 0, 100));
        absorb = uint32(std::min<uint64>(absorb, uint64(damage.GetDamage()) * percent / 100));
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_blood_veil::Calculate,
            EFFECT_1, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_blood_veil::Absorb, EFFECT_1);
    }
};

class bloodmage_hunter_and_hunted_casts : public AllSpellScript
{
public:
    bloodmage_hunter_and_hunted_casts() : AllSpellScript("bloodmage_hunter_and_hunted_casts",
        {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL || !info ||
            info->Id != SPELL_BLOODGALE || spell->IsTriggered() ||
            player->GetTemporarySpellReplacement(SPELL_ACCURSED_FORM) != SPELL_BLOODGALE)
            return;
        ClearHunterAndHuntedReactivation(player);
    }
};

class bloodmage_talent_contracts : public GlobalScript
{
public:
    bloodmage_talent_contracts() : GlobalScript("bloodmage_talent_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || info->SpellFamilyName != 26)
            return;

        uint32 const excludeCasterAuraSpell = info->ExcludeCasterAuraSpell;
        info->ExcludeCasterAuraSpell = AscensionBloodmage::RuntimeExcludeCasterAuraSpell(
            info->SpellFamilyName, excludeCasterAuraSpell);
        if (info->ExcludeCasterAuraSpell != excludeCasterAuraSpell)
            Ascension::ClientSpellPatches::Instance().Register(info->Id);

        if (info->Id == SPELL_SANGUINE_ESSENCE_HEAL || info->Id == SPELL_SANGUINE_ESSENCE_DAMAGE)
            info->AscensionInheritsResolvedAmount = true;

        ApplyBloodmageConditionalContracts(info);

        if (info->Id == SPELL_BLOOD_SCENT &&
            info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_EFFECT2)
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        if (info->Id == SPELL_BLOOD_SCENT_LEECH &&
            info->Effects[EFFECT_0].Effect == SPELL_EFFECT_HEALTH_LEECH)
        {
            info->AscensionInheritsResolvedAmount = true;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
        }

        if (info->Id == SPELL_ATHERANNS_ANGUISH && info->Effects[EFFECT_1].IsAura(SPELL_AURA_SCHOOL_ABSORB) &&
            info->Effects[EFFECT_1].MiscValueB == AtherannsAnguishPercent)
        {
            info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
            info->Effects[EFFECT_1].BasePoints = -1;
        }

        if (IsBloodVeilRank(info->Id) && info->Effects[EFFECT_0].IsAura(SPELL_AURA_SCHOOL_ABSORB) &&
            info->Effects[EFFECT_1].IsAura(SPELL_AURA_SCHOOL_ABSORB))
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;

        if (info->Id == SPELL_INFUSE && info->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
            info->Effects[EFFECT_0].TriggerSpell == SPELL_INFUSE_UNLEASH &&
            info->Effects[EFFECT_1].IsAura(SPELL_AURA_SCHOOL_ABSORB))
        {
            info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
            info->Effects[EFFECT_1].BasePoints = -1;
        }

        if ((info->Id == SPELL_CRIMSON_EXPEDITION || info->Id == SPELL_SANGUINE_SCION) &&
            info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_CRITICAL_CHANCE)
            info->Effects[EFFECT_0].SpellClassMask[1] |= BloodboltClassMask1;

        if (info->Id == SPELL_BLOOD_RUNS_COLD &&
            info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_EFFECT1)
            info->Effects[EFFECT_0].MiscValue = SPELLMOD_EFFECT2;

        if (info->Id == SPELL_COAGULATION_DISPEL &&
            info->Effects[EFFECT_0].Effect == SPELL_EFFECT_DISPEL_MECHANIC &&
            info->Effects[EFFECT_0].MiscValue == int32(MECHANIC_BLEED))
            info->Effects[EFFECT_0].BasePoints = 1;

        if (info->Id == SPELL_NIGHTMARE_BUFF)
        {
            info->DurationEntry = sSpellDurationStore.LookupEntry(21);
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }

        if (info->Id != SPELL_VAMPIRIC_POOLS_LEECH ||
            info->Effects[EFFECT_0].Effect != SPELL_EFFECT_HEALTH_LEECH)
            return;

        info->DurationEntry = sSpellDurationStore.LookupEntry(32);
        info->AttributesCu |= SPELL_ATTR0_CU_NEGATIVE_EFF1;
        auto& fear = info->Effects[EFFECT_1];
        fear.Effect = SPELL_EFFECT_APPLY_AURA;
        fear.ApplyAuraName = SPELL_AURA_MOD_FEAR;
        fear.Mechanic = MECHANIC_FEAR;
        fear.TargetA = info->Effects[EFFECT_0].TargetA;
        fear.TargetB = info->Effects[EFFECT_0].TargetB;
        fear.RadiusEntry = info->Effects[EFFECT_0].RadiusEntry;
    }
};

class spell_ascension_bloodmage_sanguine_mend : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_sanguine_mend);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_CRIMSON_SCION_INSTANT});
    }

    void ConsumeCrimsonScion()
    {
        if (GetCaster()->HasAura(SPELL_CRIMSON_SCION_INSTANT))
            GetCaster()->RemoveAurasDueToSpell(SPELL_CRIMSON_SCION_INSTANT);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_bloodmage_sanguine_mend::ConsumeCrimsonScion);
    }
};
}

void AddSC_AscensionBloodmageTalents()
{
    new bloodmage_talent_events();
    new bloodmage_blood_scent_damage();
    new bloodmage_cursed_form_death();
    new bloodmage_cursed_form_weapons();
    new bloodmage_hunter_and_hunted_casts();
    new bloodmage_infuse_accumulation();
    new bloodmage_blood_constructor();
    new bloodmage_talent_contracts();
    RegisterSpellScript(spell_ascension_bloodmage_sanguine_rupture);
    RegisterSpellScript(spell_ascension_animated_blood);
    RegisterCreatureAI(npc_ascension_animated_blood);
    RegisterSpellScript(aura_ascension_bloodmage_crimson_feast);
    RegisterSpellScript(aura_ascension_bloodmage_coagulation);
    RegisterSpellScript(aura_ascension_bloodmage_taldarams_torment);
    RegisterSpellScript(aura_ascension_bloodmage_forbidden_power);
    RegisterSpellScript(aura_ascension_bloodmage_dark_sigil);
    RegisterSpellScript(aura_ascension_bloodmage_blood_scent);
    RegisterSpellScript(aura_ascension_bloodmage_thick_pelt);
    RegisterSpellScript(aura_ascension_bloodmage_blood_moon);
    RegisterSpellScript(aura_ascension_bloodmage_cursed_blood);
    RegisterSpellScript(aura_ascension_bloodmage_transgression);
    RegisterSpellScript(aura_ascension_bloodmage_essence_harvester);
    RegisterSpellScript(aura_ascension_bloodmage_blood_bond);
    RegisterSpellScript(aura_ascension_bloodmage_atheranns_anguish);
    RegisterSpellScript(spell_ascension_bloodmage_atheranns_anguish_explosion);
    RegisterSpellScript(aura_ascension_bloodmage_night_stalker);
    RegisterSpellScript(aura_ascension_bloodmage_cardiac_arrest);
    RegisterSpellScript(aura_ascension_bloodmage_sanguine_essence);
    RegisterSpellScript(aura_ascension_blood_veil);
    RegisterSpellScript(aura_ascension_bloodmage_infuse);
    RegisterSpellScript(spell_ascension_bloodmage_infuse_unleash);
    RegisterSpellScript(spell_ascension_bloodmage_lunge);
    RegisterSpellScript(spell_ascension_bloodmage_blood_orb_spawn);
    RegisterCreatureAI(npc_ascension_bloodmage_blood_orb);
    RegisterSpellScript(spell_ascension_bloodmage_blood_orb_pickup);
    RegisterSpellScript(spell_ascension_bloodmage_sanguine_mend);
}
