/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionClassMechanics.h"
#include "AscensionBarbarian.h"
#include "AscensionClassMechanics12To17.h"
#include "AscensionClassMechanics19To25.h"
#include "AscensionClassMechanics26To32.h"
#include "AscensionRangerDamage.h"
#include "AscensionRangerTalents.h"
#include "AscensionWitchHunterTonics.h"
#include "AscensionWitchHunterFlames.h"
#include "AscensionWitchHunterScaling.h"
#include "AscensionWitchHunterTargeting.h"
#include "AscensionWitchHunterStake.h"
#include "AscensionWitchHunterCompletion.h"
#include "AscensionWitchDoctorCompletion.h"
#include "AscensionNecromancer.h"
#include "AscensionTemplar.h"
#include "AscensionFelsworn.h"
#include "AscensionXoroth.h"
#include "AscensionStarcaller.h"
#include "AscensionPyromancer.h"
#include "AscensionCultist.h"
#include "AscensionVenomancer.h"
#include "AscensionTinker.h"
#include "AscensionSunCleric.h"
#include "AscensionStormbringer.h"
#include "AscensionSunClericRadiance.h"
#include "AscensionConditionalCombat.h"
#include "AscensionRunemasterGlyphs.h"
#include "AscensionRunemasterBrand.h"
#include "AscensionRunemasterScaling.h"
#include "AscensionRunemasterDamageModifiers.h"
#include "AscensionTinkerCombustion.h"
#include "AscensionTinkerOverload.h"
#include "AscensionRunemasterZenith.h"
#include "AscensionTemplarLibrams.h"
#include "AscensionHealingStatSelectors.h"
#include "AscensionHeroWarrior.h"
#include "AscensionGuardianResources.h"
#include "AscensionSpellProgressionData.h"
#include "AscensionHeroHunter.h"
#include "AscensionHeroRogue.h"
#include "AscensionHeroPriest.h"
#include "AscensionHeroWarlock.h"
#include "AscensionHeroPaladin.h"
#include "AscensionWarcraftRebornDruid.h"
#include "AscensionWarcraftRebornHunter.h"
#include "AscensionWarcraftRebornMage.h"
#include "AscensionWarcraftRebornPaladin.h"
#include "AscensionWarcraftRebornPriest.h"
#include "AscensionWarcraftRebornRogue.h"
#include "AscensionWarcraftRebornWarlock.h"
#include "AscensionWarcraftRebornWarrior.h"
#include "Cell.h"
#include "CellImpl.h"
#include "ClientDBC.h"
#include "DBCStores.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Item.h"
#include "Log.h"
#include "Player.h"
#include "Random.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <list>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace
{
constexpr uint32 SPELL_TINKER_SCRAP = 801816;
constexpr uint32 SPELL_TINKER_SCRAPPER = 525039;
constexpr uint32 SPELL_TINKER_GENERATE_TEN_SCRAP = 704594;
constexpr uint32 SPELL_TINKER_GENERATE_TWENTY_SCRAP = 707596;
constexpr uint32 SPELL_GUARDIAN_TOWER_FORMATION = 800317;
constexpr uint32 SPELL_GUARDIAN_TOWER_FORMATION_EFFECTS = 803431;
constexpr uint32 SPELL_GUARDIAN_TOWER_FORMATION_STANCE = 803907;
constexpr uint32 SPELL_GUARDIAN_LINE_FORMATION = 803130;
constexpr uint32 SPELL_GUARDIAN_LINE_FORMATION_EFFECTS = 803151;
constexpr uint32 SPELL_GUARDIAN_ASSAULT_FORMATION = 803417;
constexpr uint32 SPELL_GUARDIAN_ASSAULT_FORMATION_EFFECTS = 803709;
constexpr uint32 SPELL_GUARDIAN_ASSAULT_FORMATION_VISUAL = 803419;
constexpr uint32 SPELL_GUARDIAN_TOWER_FORMATION_VISUAL = 803941;
constexpr uint32 SPELL_GUARDIAN_FOOTMANS_CALLING = 92105;
constexpr uint32 SPELL_GUARDIAN_FOOTMANS_CALLING_EFFECTS = 807728;
constexpr uint32 SPELL_GUARDIAN_REPRISAL = 800316;
constexpr uint32 SPELL_GUARDIAN_REPRISAL_READY = 504885;
constexpr uint32 SPELL_GUARDIAN_CENTURION_SWORD_ATTACKS = 807967;
constexpr uint8 GUARDIAN_CENTURION_SWORD_EVENT = 16;
constexpr uint8 GUARDIAN_CENTURION_POLEARM_EVENT = 22;
constexpr uint32 SPELL_GUARDIAN_CENTURION_AXE_EFFECTS = 542238;
constexpr uint32 SPELL_GUARDIAN_CENTURION_MACE_EFFECTS = 542265;
constexpr uint32 SPELL_GUARDIAN_RAISE_SHIELD = 500168;
constexpr uint32 SPELL_GUARDIAN_RAISE_SHIELD_ENERGIZE = 500493;
constexpr uint32 SPELL_GUARDIAN_GUARDBREAKER = 504385;
constexpr uint32 SPELL_GUARDIAN_GUARDBREAKER_RESET = 802895;
constexpr uint32 SPELL_GUARDIAN_REFUSE = 804892;
constexpr uint32 SPELL_GUARDIAN_REFUSE_RESET = 807191;
constexpr uint32 SPELL_GUARDIAN_NO_ESCAPE = 802300;
constexpr uint32 SPELL_GUARDIAN_NO_ESCAPE_RESET = 806544;
constexpr uint32 SPELL_GUARDIAN_BULWARK_RUSH = 300536;
constexpr uint32 SPELL_GUARDIAN_BULWARK_RUSH_EFFECTS = 300537;
constexpr uint32 SPELL_GUARDIAN_ORDER_IN_THE_COURT = 707716;
constexpr uint32 SPELL_GUARDIAN_ORDER_IN_THE_COURT_DEBUFF = 704417;
constexpr uint32 SPELL_GUARDIAN_FORCEFUL_IMPACT = 705346;
constexpr uint32 SPELL_GUARDIAN_BRACE = 800313;
constexpr uint32 SPELL_GUARDIAN_KINGS_GUARD = 803134;
constexpr uint32 SPELL_GUARDIAN_KINGS_GUARD_RESET = 520284;
constexpr uint32 SPELL_GUARDIAN_WRECK_FORMATION = 803126;
constexpr uint32 SPELL_GUARDIAN_WRECK_FORMATION_AP = 803416;
constexpr uint32 SPELL_GUARDIAN_HIGH_GUARD = 707621;
constexpr uint32 SPELL_GUARDIAN_HIGH_GUARD_EFFECTS = 504586;
constexpr uint32 SPELL_GUARDIAN_PLATE_BUSTER = 705333;
constexpr uint32 SPELL_GUARDIAN_PLATE_BUSTER_RESET = 705334;
constexpr uint32 SPELL_GUARDIAN_VANGUARDS_MIGHT = 705345;
constexpr uint32 SPELL_GUARDIAN_VANGUARDS_MIGHT_EFFECTS = 802894;
constexpr uint32 SPELL_GUARDIAN_VETERAN = 300540;
constexpr uint32 SPELL_GUARDIAN_VETERAN_HEAL = 705382;
constexpr uint32 SPELL_GUARDIAN_HONORABLE = 705377;
constexpr uint32 SPELL_GUARDIAN_HONORABLE_EFFECTS = 524931;
constexpr uint32 SPELL_GUARDIAN_RECUPERATION = 801121;
constexpr uint32 SPELL_GUARDIAN_RECUPERATION_ENERGIZE = 803135;
constexpr uint32 SPELL_GUARDIAN_PINNED_DOWN = 301252;
constexpr uint32 SPELL_GUARDIAN_PINNED_DOWN_REFRESH = 600325;
constexpr uint32 SPELL_GUARDIAN_SHOW_OF_FORCE = 573047;
constexpr uint32 SPELL_GUARDIAN_SHOW_OF_FORCE_DISPEL = 520861;
constexpr uint32 SPELL_GUARDIAN_KNIGHTS_SONG = 505228;
constexpr uint32 SPELL_GUARDIAN_KNIGHTS_SONG_EFFECTS = 807460;
constexpr uint32 SPELL_GUARDIAN_MINSTREL = 704533;
constexpr uint32 SPELL_GUARDIAN_MINSTREL_EFFECTS = 704534;
constexpr int32 GUARDIAN_RAISE_SHIELD_ENERGY_BASE_POINTS = 19;
constexpr uint32 GUARDIAN_FORCEFUL_IMPACT_EXTENSION_MS = 1000;
constexpr uint32 GUARDIAN_KINGS_GUARD_ICD_MS = 1000;
constexpr uint8 GUARDIAN_GUARDBREAKER_CHANCE = 20;
constexpr uint8 GUARDIAN_KINGS_GUARD_CHANCE = 10;
constexpr float GUARDIAN_CENTURION_POLEARM_DEPTH = 5.0f;
constexpr float GUARDIAN_CENTURION_POLEARM_HALF_WIDTH = 2.5f;
constexpr uint32 GUARDIAN_CENTURION_DAMAGE_EFFECT_MASK =
    (1u << EFFECT_0) | (1u << EFFECT_2);

constexpr uint32 SPELL_RANGER_ADVANTAGE = 804329;
constexpr uint32 SPELL_RANGER_ADVANTAGE_DECREMENT = 520618;
constexpr uint32 SPELL_RANGER_ADVANTAGE_DECREMENT_PASSIVE = 582770;
constexpr uint32 SPELL_RANGER_ADVANTAGE_INCREMENT = 524659;
constexpr uint32 SPELL_RANGER_ELUDE = 801345;
constexpr uint32 SPELL_RANGER_ELUDE_EFFECTS = 524862;
constexpr uint32 SPELL_RANGER_ELUDE_SPEED_PENALTY = 524886;
constexpr uint32 SPELL_RANGER_ELUSIVE_CHARACTER = 560340;
constexpr uint32 SPELL_RANGER_ELUSIVE_CHARACTER_EFFECTS = 705046;
constexpr uint32 SPELL_RANGER_FOREST_DWELLER = 524864;
constexpr uint32 SPELL_RANGER_FOREST_DWELLER_HEAL = 524863;
constexpr uint32 SPELL_RANGER_RAVAGER = 92116;
constexpr uint32 SPELL_RANGER_RAVAGER_LEGACY = 500024;
constexpr uint32 SPELL_RANGER_HUNTING_TACTICS = 300897;
constexpr uint32 SPELL_RANGER_ARCHERY_MASTER = 706281;
constexpr uint32 SPELL_RANGER_RUB_IT_IN = 705085;
constexpr uint32 SPELL_RANGER_SNIPERS_FOCUS = 680470;
constexpr uint32 SPELL_RANGER_SNIPERS_FOCUS_ENERGIZE = 807318;
constexpr uint32 SPELL_RANGER_MAXIMUM_POWER = 560688;
constexpr uint32 SPELL_RANGER_MAXIMUM_POWER_EXTENSION = 560689;
constexpr uint32 SPELL_RANGER_LETHAL_CUNNING = 704320;
constexpr uint32 SPELL_RANGER_LETHAL_CUNNING_EFFECTS = 704321;
constexpr uint32 SPELL_RANGER_SKIRMISH = 802039;
constexpr uint32 SPELL_RANGER_SEARING_QUIVER = 500103;
constexpr uint32 SPELL_RANGER_POISON_QUIVER = 800260;
constexpr uint32 SPELL_RANGER_LIGHT_QUIVER = 800261;
constexpr uint32 SPELL_RANGER_HUNTING_QUIVER = 800262;
constexpr uint32 SPELL_RANGER_SKIRMISHERS_QUIVER = 801069;
constexpr uint32 SPELL_RANGER_SEARING_QUIVER_DAMAGE = 681109;
constexpr uint32 SPELL_RANGER_POISON_QUIVER_DAMAGE = 500104;
constexpr uint32 SPELL_RANGER_BOUNTY_HUNTER = 803114;
constexpr uint32 SPELL_RANGER_BOUNTY_HUNTER_DEBUFF = 560722;
constexpr uint32 SPELL_RANGER_RUSTY_SHIV_DAMAGE = 681459;
constexpr uint8 RANGER_ADVANTAGE_REFUND_CHANCE = 20;
constexpr uint8 RANGER_ADVANTAGE_CAST_EVENT = 30;
constexpr uint8 RANGER_ARCHERY_MASTER_EVENT = 31;

constexpr uint32 SPELL_CULTIST_TWILIGHT_SHIELDTOSS_SLOW = 524880;

constexpr std::array<uint32, 3> GUARDIAN_FORMATIONS =
{{
    SPELL_GUARDIAN_TOWER_FORMATION,
    SPELL_GUARDIAN_LINE_FORMATION,
    SPELL_GUARDIAN_ASSAULT_FORMATION
}};

constexpr std::array<uint32, 7> GUARDIAN_FORMATION_HELPERS =
{{
    SPELL_GUARDIAN_TOWER_FORMATION_EFFECTS,
    SPELL_GUARDIAN_TOWER_FORMATION_STANCE,
    SPELL_GUARDIAN_LINE_FORMATION_EFFECTS,
    SPELL_GUARDIAN_ASSAULT_FORMATION_EFFECTS,
    SPELL_GUARDIAN_FOOTMANS_CALLING_EFFECTS,
    SPELL_GUARDIAN_ASSAULT_FORMATION_VISUAL,
    SPELL_GUARDIAN_TOWER_FORMATION_VISUAL
}};

constexpr std::array<uint32, 5> RANGER_QUIVERS =
{{
    SPELL_RANGER_SEARING_QUIVER,
    SPELL_RANGER_POISON_QUIVER,
    SPELL_RANGER_LIGHT_QUIVER,
    SPELL_RANGER_HUNTING_QUIVER,
    SPELL_RANGER_SKIRMISHERS_QUIVER
}};

void RemoveGuardianFormationHelpers(Player* player)
{
    for (uint32 spellId : GUARDIAN_FORMATION_HELPERS)
        player->RemoveAurasDueToSpell(spellId);
}

void ApplyGuardianFormation(Player* player, uint32 spellId)
{
    for (uint32 formationId : GUARDIAN_FORMATIONS)
        if (formationId != spellId)
            player->RemoveAurasDueToSpell(formationId);

    RemoveGuardianFormationHelpers(player);
    switch (spellId)
    {
        case SPELL_GUARDIAN_TOWER_FORMATION:
            player->CastSpell(player, SPELL_GUARDIAN_TOWER_FORMATION_EFFECTS, true);
            player->CastSpell(player, SPELL_GUARDIAN_TOWER_FORMATION_STANCE, true);
            break;
        case SPELL_GUARDIAN_LINE_FORMATION:
            player->CastSpell(player, SPELL_GUARDIAN_LINE_FORMATION_EFFECTS, true);
            break;
        case SPELL_GUARDIAN_ASSAULT_FORMATION:
            player->CastSpell(player, SPELL_GUARDIAN_ASSAULT_FORMATION_EFFECTS, true);
            break;
        default:
            break;
    }

    if ((spellId == SPELL_GUARDIAN_TOWER_FORMATION ||
            spellId == SPELL_GUARDIAN_LINE_FORMATION) &&
        player->HasAura(SPELL_GUARDIAN_FOOTMANS_CALLING))
    {
        player->CastSpell(player, SPELL_GUARDIAN_FOOTMANS_CALLING_EFFECTS,
            true);
    }
}

bool IsSpellInRange(uint32 spellId, uint32 first, uint32 last)
{
    return spellId >= first && spellId <= last;
}

bool IsGuardianCenturionStrike(uint32 spellId)
{
    switch (spellId)
    {
        case 802286:
        case 802734:
        case 802735:
        case 802736:
        case 802737:
        case 802738:
            return true;
        default:
            return false;
    }
}

bool IsGuardianRam(uint32 spellId)
{
    return spellId == 802284 || IsSpellInRange(spellId, 573204, 573211);
}

bool IsGuardianPulverize(uint32 spellId)
{
    return spellId == 800311 || IsSpellInRange(spellId, 802439, 802443) ||
        spellId == 573286 || spellId == 573292;
}

bool IsGuardianHeavyBlow(uint32 spellId)
{
    return spellId == 803129 || IsSpellInRange(spellId, 503119, 503126);
}

bool IsGuardianHammerOfJustice(uint32 spellId)
{
    return spellId == 704418 || IsSpellInRange(spellId, 707710, 707715);
}

bool IsGuardianSpearThrow(uint32 spellId)
{
    return spellId == 500463 || IsSpellInRange(spellId, 572142, 572147);
}

bool IsGuardianAdvance(uint32 spellId)
{
    return spellId == 500170 || IsSpellInRange(spellId, 503344, 503351);
}

bool IsGuardianBattleRush(uint32 spellId)
{
    return spellId == 802197 || IsSpellInRange(spellId, 501546, 501548);
}

bool IsGuardianBalladOfTheConqueror(uint32 spellId)
{
    return spellId == 801776 || IsSpellInRange(spellId, 501068, 501074) ||
        spellId == 574340;
}

bool IsGuardianBallad(uint32 spellId)
{
    return IsGuardianBalladOfTheConqueror(spellId) || spellId == 801772 ||
        IsSpellInRange(spellId, 572717, 572719) ||
        IsSpellInRange(spellId, 574363, 574364) ||
        IsSpellInRange(spellId, 501066, 501067) || spellId == 574341;
}

bool IsGuardianStandardOfValiance(uint32 spellId)
{
    return spellId == 800315 || spellId == 800319 ||
        IsSpellInRange(spellId, 501538, 501545) ||
        IsSpellInRange(spellId, 803931, 803938);
}

void ExtendGuardianBrace(Player* player)
{
    Aura* brace = player->GetAura(SPELL_GUARDIAN_BRACE);
    if (!brace)
        return;

    int32 extendedDuration = std::min(brace->GetMaxDuration(),
        brace->GetDuration() + int32(GUARDIAN_FORCEFUL_IMPACT_EXTENSION_MS));
    brace->SetDuration(extendedDuration);
}

void TryGuardianKingsGuardReset(Player* player)
{
    if (!player->HasAura(SPELL_GUARDIAN_KINGS_GUARD) ||
        player->HasSpellCooldown(SPELL_GUARDIAN_KINGS_GUARD) ||
        !roll_chance_i(GUARDIAN_KINGS_GUARD_CHANCE))
    {
        return;
    }

    player->CastSpell(player, SPELL_GUARDIAN_KINGS_GUARD_RESET, true);
    player->AddSpellCooldown(SPELL_GUARDIAN_KINGS_GUARD, 0,
        GUARDIAN_KINGS_GUARD_ICD_MS);
}

uint32 GetMainHandWeaponSubclass(Player const* player)
{
    Item const* weapon = player->GetWeaponForAttack(BASE_ATTACK, true);
    ItemTemplate const* itemTemplate = weapon ? weapon->GetTemplate() : nullptr;
    if (!itemTemplate || itemTemplate->Class != ITEM_CLASS_WEAPON)
        return MAX_ITEM_SUBCLASS_WEAPON;
    return itemTemplate->SubClass;
}

bool IsSwordSubclass(uint32 subclass)
{
    return subclass == ITEM_SUBCLASS_WEAPON_SWORD ||
        subclass == ITEM_SUBCLASS_WEAPON_SWORD2;
}

bool IsAxeSubclass(uint32 subclass)
{
    return subclass == ITEM_SUBCLASS_WEAPON_AXE ||
        subclass == ITEM_SUBCLASS_WEAPON_AXE2;
}

bool IsMaceSubclass(uint32 subclass)
{
    return subclass == ITEM_SUBCLASS_WEAPON_MACE ||
        subclass == ITEM_SUBCLASS_WEAPON_MACE2;
}

void RemoveGuardianCenturionWeaponEffects(Player* player)
{
    player->RemoveAurasDueToSpell(SPELL_GUARDIAN_CENTURION_AXE_EFFECTS);
    player->RemoveAurasDueToSpell(SPELL_GUARDIAN_CENTURION_MACE_EFFECTS);
}

void AddGuardianCenturionPolearmTargets(Spell* spell, Player* player)
{
    Unit* primary = spell->GetOriginalTarget();
    if (!primary || primary == player)
        return;

    float directionX = primary->GetPositionX() - player->GetPositionX();
    float directionY = primary->GetPositionY() - player->GetPositionY();
    float directionLength = std::hypot(directionX, directionY);
    if (directionLength <= 0.001f)
        return;

    directionX /= directionLength;
    directionY /= directionLength;

    float searchRange = directionLength + GUARDIAN_CENTURION_POLEARM_DEPTH;
    std::list<Unit*> candidates;
    Acore::AnyUnfriendlyUnitInObjectRangeCheck check(player, player, searchRange);
    Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(
        player, candidates, check);
    Cell::VisitObjects(player, searcher, searchRange);

    for (Unit* candidate : candidates)
    {
        if (!candidate || candidate == primary || !candidate->IsAlive() ||
            !player->IsValidAttackTarget(candidate, spell->GetSpellInfo()) ||
            !player->IsWithinLOSInMap(candidate))
            continue;

        float relativeX = candidate->GetPositionX() - primary->GetPositionX();
        float relativeY = candidate->GetPositionY() - primary->GetPositionY();
        float depth = relativeX * directionX + relativeY * directionY;
        float lateral = std::abs(relativeX * directionY - relativeY * directionX);
        if (depth <= 0.0f || depth > GUARDIAN_CENTURION_POLEARM_DEPTH ||
            lateral > GUARDIAN_CENTURION_POLEARM_HALF_WIDTH + candidate->GetCombatReach() ||
            std::abs(candidate->GetPositionZ() - primary->GetPositionZ()) >
                GUARDIAN_CENTURION_POLEARM_DEPTH)
            continue;

        spell->AddUnitTargetForScript(candidate,
            GUARDIAN_CENTURION_DAMAGE_EFFECT_MASK, true, true);
    }
}

bool IsRangerWildStrike(uint32 spellId)
{
    return spellId == 800083 || IsSpellInRange(spellId, 501724, 501734);
}

bool IsRangerFlank(uint32 spellId)
{
    return spellId == 804940 || IsSpellInRange(spellId, 805082, 805088) ||
        IsSpellInRange(spellId, 582530, 582531);
}

bool IsRangerQuickShot(uint32 spellId)
{
    return spellId == 500074 || IsSpellInRange(spellId, 572727, 572732);
}

bool IsRangerHuntingShot(uint32 spellId)
{
    return spellId == 801191 || IsSpellInRange(spellId, 547202, 547208);
}

bool IsRangerToxicDart(uint32 spellId)
{
    return spellId == 807237 || IsSpellInRange(spellId, 807324, 807330);
}

void ApplyRangerEludeExitEffects(Player* player, bool removedByDeath)
{
    if (!player || player->getClass() != CLASS_RANGER || removedByDeath || !player->IsAlive() ||
        !player->IsInWorld() || !player->GetSession() || player->GetSession()->PlayerLogout() ||
        player->HasAura(SPELL_RANGER_ELUDE) || !player->HasAura(SPELL_RANGER_ELUSIVE_CHARACTER))
        return;

    player->CastSpell(player, SPELL_RANGER_ELUSIVE_CHARACTER_EFFECTS, true);
}

void RefreshRangerEludePenalty(Player* player)
{
    if (!player || player->getClass() != CLASS_RANGER)
        return;

    AuraEffect* penalty = player->GetAuraEffect(SPELL_RANGER_ELUDE_SPEED_PENALTY, EFFECT_2);
    if (!penalty || penalty->GetAuraType() != SPELL_AURA_MOD_DECREASE_SPEED)
        return;

    if (player->HasAura(SPELL_RANGER_FOREST_DWELLER))
        penalty->ChangeAmount(0);
    else
    {
        penalty->SetCanBeRecalculated(true);
        penalty->ChangeAmount(penalty->CalculateAmount(player), false);
    }
}

void ApplyTinkerScrapperContract(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->Id != SPELL_TINKER_SCRAPPER ||
        spellInfo->SpellFamilyName != uint32(CLASS_TINKER) + 6)
        return;

    SpellEffectInfo& tick = spellInfo->Effects[EFFECT_0];
    if (tick.Effect == SPELL_EFFECT_APPLY_AURA &&
        tick.ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL &&
        (tick.TriggerSpell == SPELL_TINKER_GENERATE_TWENTY_SCRAP ||
            tick.TriggerSpell == SPELL_TINKER_GENERATE_TEN_SCRAP))
    {
        tick.TriggerSpell = SPELL_TINKER_GENERATE_TEN_SCRAP;
    }
    else
    {
        LOG_ERROR("coa",
            "Skipped unexpected Scrapper resource record {}", spellInfo->Id);
    }
}

void ApplyTinkerScrapResourceContract(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->Id != SPELL_TINKER_SCRAP ||
        spellInfo->SpellFamilyName != uint32(CLASS_TINKER) + 6)
        return;

    std::array<uint32, MAX_SPELL_EFFECTS> const originalAuras =
        {SPELL_AURA_ADD_FLAT_MODIFIER, SPELL_AURA_ADD_PCT_MODIFIER,
            SPELL_AURA_ADD_FLAT_MODIFIER};
    std::array<int32, MAX_SPELL_EFFECTS> const originalBasePoints = {999, 9, 1};
    for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
    {
        SpellEffectInfo const& effect = spellInfo->Effects[index];
        if (effect.Effect != SPELL_EFFECT_APPLY_AURA ||
            (effect.ApplyAuraName != originalAuras[index] &&
                effect.ApplyAuraName != SPELL_AURA_DUMMY) ||
            effect.MiscValue != SPELLMOD_DAMAGE || effect.SpellClassMask ||
            effect.BasePoints != originalBasePoints[index] || effect.DieSides != 1)
        {
            LOG_ERROR("coa",
                "Skipped unexpected Scrap resource record {}", spellInfo->Id);
            return;
        }
    }

    for (SpellEffectInfo& effect : spellInfo->Effects)
        effect.ApplyAuraName = SPELL_AURA_DUMMY;
}

void ApplyRangerFixedDurationContract(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->Id != SPELL_RANGER_ADVANTAGE ||
        spellInfo->SpellFamilyName != uint32(CLASS_RANGER) + 6)
        return;

    SpellEffectInfo& duration = spellInfo->Effects[EFFECT_1];
    if (duration.Effect == SPELL_EFFECT_APPLY_AURA &&
        duration.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
        duration.MiscValue == SPELLMOD_DURATION &&
        (duration.SpellClassMask == flag96(16777280, 0, 1048704) ||
            duration.SpellClassMask == flag96(16777216, 0, 1048704)))
    {
        duration.SpellClassMask = flag96(16777216, 0, 1048704);
    }
    else
    {
        LOG_ERROR("coa", "Skipped unexpected Advantage duration record {}", spellInfo->Id);
    }
}

void ApplyRangerConditionalDamageContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != uint32(CLASS_RANGER) + 6)
        return;

    SpellEffIndex index;
    int32 amount;
    AuraStateType state;
    flag96 mask;
    if (spellInfo->Id == SPELL_RANGER_RAVAGER)
    {
        index = EFFECT_2;
        amount = 49;
        state = AURA_STATE_BLEEDING;
        mask = flag96(0, 32768, 0);
    }
    else if (spellInfo->Id == SPELL_RANGER_HUNTING_TACTICS)
    {
        index = EFFECT_0;
        amount = 29;
        state = AURA_STATE_ASCENSION_POISONED;
        mask = flag96(0, 134217728, 0);
    }
    else
        return;

    SpellEffectInfo& effect = spellInfo->Effects[index];
    bool const copied = effect.ApplyAuraName == SPELL_AURA_OVERRIDE_CLASS_SCRIPTS &&
        effect.MiscValue == ASCENSION_CLASSMASK_AURASTATE_DAMAGE && effect.MiscValueB == int32(state);
    bool const converted = effect.ApplyAuraName == SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE &&
        effect.MiscValue == int32(state) && effect.MiscValueB == ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
    if (effect.Effect == SPELL_EFFECT_APPLY_AURA && (copied || converted) && effect.BasePoints == amount &&
        effect.DieSides == 1 && effect.SpellClassMask == mask &&
        effect.TargetA.GetTarget() == TARGET_UNIT_CASTER && effect.TargetB.GetTarget() == 0)
    {
        effect.ApplyAuraName = SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE;
        effect.MiscValue = int32(state);
        effect.MiscValueB = ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
    }
    else
        LOG_ERROR("coa", "Skipped unexpected Ranger conditional damage record {}", spellInfo->Id);
}

void ApplyRangerSerrationsContract(SpellInfo* spellInfo)
{
    if (spellInfo->Id != 705050 && spellInfo->Id != 707850)
        return;

    int32 amount = spellInfo->Id == 705050 ? 4 : 9;
    for (SpellEffectInfo& effect : spellInfo->Effects)
    {
        if (effect.Effect != SPELL_EFFECT_APPLY_AURA ||
            effect.ApplyAuraName != SPELL_AURA_OVERRIDE_CLASS_SCRIPTS ||
            effect.MiscValue != ASCENSION_CLASSMASK_AURASTATE_DAMAGE)
            continue;

        if (effect.BasePoints == amount && effect.DieSides == 1)
        {
            effect.ApplyAuraName = SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE;
            effect.MiscValue = effect.MiscValueB;
            effect.MiscValueB = ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
        }
        else
            LOG_ERROR("coa", "Skipped unexpected Ranger Serrations record {}", spellInfo->Id);
        return;
    }

    LOG_ERROR("coa", "Skipped unexpected Ranger Serrations record {}", spellInfo->Id);
}

void ApplyRangerUnderhandedContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != uint32(CLASS_RANGER) + 6 ||
        (spellInfo->Id != 705061 && spellInfo->Id != 707884))
        return;

    int32 const basePoints = spellInfo->Id == 705061 ? 14 : 29;
    std::array<flag96, 2> const masks = {{flag96(0, 134217728, 0), flag96(0, 0, 128)}};
    for (SpellEffIndex index : {EFFECT_0, EFFECT_1})
    {
        SpellEffectInfo const& effect = spellInfo->Effects[index];
        int32 const copiedIndex = index == EFFECT_0 ? 42 : 45;
        int32 const script = index == EFFECT_0 ? ASCENSION_DIRECT_AP_COEFFICIENT_PCT : ASCENSION_PERIODIC_AP_COEFFICIENT_PCT;
        bool const copied = effect.ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER && effect.MiscValue == copiedIndex;
        bool const converted = effect.ApplyAuraName == SPELL_AURA_OVERRIDE_CLASS_SCRIPTS && effect.MiscValue == script;
        if (effect.Effect != SPELL_EFFECT_APPLY_AURA || (!copied && !converted) || effect.MiscValueB != 0 ||
            effect.BasePoints != basePoints || effect.DieSides != 1 || effect.SpellClassMask != masks[index] ||
            effect.TargetA.GetTarget() != TARGET_UNIT_CASTER || effect.TargetB.GetTarget() != 0)
        {
            LOG_ERROR("coa", "Skipped unexpected Underhanded coefficient record {}", spellInfo->Id);
            return;
        }
    }

    for (SpellEffIndex index : {EFFECT_0, EFFECT_1})
    {
        spellInfo->Effects[index].ApplyAuraName = SPELL_AURA_OVERRIDE_CLASS_SCRIPTS;
        spellInfo->Effects[index].MiscValue = index == EFFECT_0 ? ASCENSION_DIRECT_AP_COEFFICIENT_PCT : ASCENSION_PERIODIC_AP_COEFFICIENT_PCT;
    }
}

void ApplyRangerInstinctualCombatantContract(SpellInfo* spellInfo)
{
    if (!spellInfo || (spellInfo->Id != 520572 && spellInfo->Id != 707319) ||
        spellInfo->SpellFamilyName != uint32(CLASS_RANGER) + 6)
        return;

    if (spellInfo->Id == 707319)
    {
        SpellEffectInfo& attackPower = spellInfo->Effects[EFFECT_1];
        if (attackPower.Effect == SPELL_EFFECT_APPLY_AURA && attackPower.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
            attackPower.MiscValue == SPELLMOD_EFFECT2 && attackPower.MiscValueB == 0 &&
            attackPower.BasePoints == 9 && attackPower.DieSides == 1 &&
            attackPower.TargetA.GetTarget() == TARGET_UNIT_CASTER && attackPower.TargetB.GetTarget() == 0 &&
            (attackPower.SpellClassMask == flag96(16, 0, 8) || attackPower.SpellClassMask == flag96(16, 0, 0)))
            attackPower.SpellClassMask = flag96(16, 0, 0);
        else
            LOG_ERROR("coa", "Skipped unexpected Instinctual Combatant talent record {}", spellInfo->Id);
        return;
    }

    SpellEffectInfo& criticalChance = spellInfo->Effects[EFFECT_1];
    if (spellInfo->ProcFlags == 0 && (spellInfo->ProcCharges == 0 || spellInfo->ProcCharges == 3) &&
        spellInfo->GetDuration() == 20000 &&
        criticalChance.Effect == SPELL_EFFECT_APPLY_AURA &&
        criticalChance.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
        criticalChance.MiscValue == SPELLMOD_CRITICAL_CHANCE && criticalChance.MiscValueB == 0 &&
        criticalChance.BasePoints == 99 && criticalChance.DieSides == 1 &&
        criticalChance.TargetA.GetTarget() == TARGET_UNIT_CASTER && criticalChance.TargetB.GetTarget() == 0 &&
        (criticalChance.SpellClassMask == flag96(0, 134250498, 0) ||
            criticalChance.SpellClassMask == flag96(0, 134250496, 0)))
    {
        spellInfo->ProcCharges = 3;
        criticalChance.SpellClassMask = flag96(0, 134250496, 0);
    }
    else
        LOG_ERROR("coa", "Skipped unexpected Instinctual Combatant record {}", spellInfo->Id);
}

void ApplyAdditionalTargetContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    enum AdditionalTargetSpells : uint32
    {
        AdvantageQuills = 801429,
        AerialAssault = 705068,
        PulsarExplosionRankOne = 704794,
        PulsarExplosionRankTwo = 707894,
        GoodVenom = 680797,
        Lifemender = 706477,
        PropheticSpeaker = 706956,
        Earthsplitter = 806081
    };

    struct Contract
    {
        uint32 SpellId;
        uint32 Family;
        SpellEffIndex EffectIndex;
        int32 BasePoints;
        std::array<uint32, 3> Mask;
    };
    static constexpr std::array<Contract, 8> contracts =
    {{
        {AdvantageQuills, 27, EFFECT_1, 0, {{0, 4, 0}}},
        {AerialAssault, 27, EFFECT_2, 1, {{512, 0, 0}}},
        {PulsarExplosionRankOne, 32, EFFECT_0, 0, {{0, 128, 0}}},
        {PulsarExplosionRankTwo, 32, EFFECT_0, 1, {{0, 128, 0}}},
        {GoodVenom, 35, EFFECT_0, 0, {{0, 0, 524288}}},
        {Lifemender, 35, EFFECT_0, 4, {{4194304, 0, 0}}},
        {PropheticSpeaker, 35, EFFECT_1, 4, {{0, 0, 8}}},
        {Earthsplitter, 24, EFFECT_2, 0, {{16, 0, 0}}}
    }};

    for (Contract const& contract : contracts)
    {
        if (spellInfo->Id != contract.SpellId)
            continue;

        SpellEffectInfo& effect = spellInfo->Effects[contract.EffectIndex];
        if (spellInfo->SpellFamilyName == contract.Family &&
            spellInfo->ProcCharges == 0 &&
            effect.Effect == SPELL_EFFECT_APPLY_AURA &&
            (effect.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER ||
                effect.ApplyAuraName == SPELL_AURA_MOD_MAX_AFFECTED_TARGETS) &&
            effect.MiscValue == 34 && effect.BasePoints == contract.BasePoints &&
            effect.DieSides == 1 && effect.TargetA.GetTarget() == TARGET_UNIT_CASTER &&
            effect.TargetB.GetTarget() == 0 &&
            effect.SpellClassMask == flag96(contract.Mask[0], contract.Mask[1], contract.Mask[2]))
        {
            effect.ApplyAuraName = SPELL_AURA_MOD_MAX_AFFECTED_TARGETS;
        }
        else
        {
            LOG_ERROR("coa",
                "Skipped unexpected additional-target record {}", spellInfo->Id);
        }
        return;
    }
}

void ApplyRangerForestDwellerContract(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->Id != SPELL_RANGER_FOREST_DWELLER ||
        spellInfo->SpellFamilyName != uint32(CLASS_RANGER) + 6)
        return;

    SpellEffectInfo const& heal = spellInfo->Effects[EFFECT_0];
    SpellEffectInfo& obsoleteSpeed = spellInfo->Effects[EFFECT_1];
    if (heal.Effect != SPELL_EFFECT_APPLY_AURA || heal.ApplyAuraName != SPELL_AURA_PERIODIC_TRIGGER_SPELL ||
        heal.TriggerSpell != SPELL_RANGER_FOREST_DWELLER_HEAL || heal.Amplitude != 3000 ||
        !((obsoleteSpeed.Effect == SPELL_EFFECT_APPLY_AURA &&
            obsoleteSpeed.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
            obsoleteSpeed.MiscValue == SPELLMOD_EFFECT1) || obsoleteSpeed.Effect == 0))
    {
        LOG_ERROR("coa", "Skipped unexpected Forest Dweller record {}", spellInfo->Id);
        return;
    }

    obsoleteSpeed.Effect = 0;
    obsoleteSpeed.ApplyAuraName = SPELL_AURA_NONE;
}

void ApplyRangerOffensiveSpellContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != uint32(CLASS_RANGER) + 6)
        return;

    bool const toxicDart = IsRangerToxicDart(spellInfo->Id);
    bool const precisionShot = spellInfo->Id == 500075 || IsSpellInRange(spellInfo->Id, 572108, 572113);
    if (toxicDart || precisionShot)
    {
        SpellEffectInfo const& damage = spellInfo->Effects[EFFECT_0];
        bool const expectedDamage = toxicDart
            ? damage.Effect == SPELL_EFFECT_APPLY_AURA && damage.ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE
            : damage.Effect == SPELL_EFFECT_SCHOOL_DAMAGE;
        SpellEffectInfo& helper = spellInfo->Effects[EFFECT_1];
        if (!expectedDamage || spellInfo->DmgClass != SPELL_DAMAGE_CLASS_RANGED ||
            (toxicDart && (helper.Effect != SPELL_EFFECT_TRIGGER_SPELL ||
                (helper.TriggerSpell != 681293 && helper.TriggerSpell != 807821))))
        {
            LOG_ERROR("coa", "Skipped unexpected Ranger offensive spell {}", spellInfo->Id);
            return;
        }

        spellInfo->AttributesEx &= ~SPELL_ATTR1_ALLOW_WHILE_STEALTHED;
        if (toxicDart)
        {
            helper.TriggerSpell = 807821;
        }
    }

    if (spellInfo->Id == 570017)
    {
        SpellEffectInfo const& stealth = spellInfo->Effects[EFFECT_1];
        if (stealth.Effect == SPELL_EFFECT_APPLY_AURA && stealth.ApplyAuraName == SPELL_AURA_MOD_STEALTH)
        {
            spellInfo->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_CAST |
                AURA_INTERRUPT_FLAG_MELEE_ATTACK | AURA_INTERRUPT_FLAG_SPELL_ATTACK;
        }
        else
            LOG_ERROR("coa", "Skipped unexpected Woodland Adept stealth {}", spellInfo->Id);
    }
}

bool IsRangerBountyHunterTrigger(uint32 spellId)
{
    return IsRangerFlank(spellId) ||
        spellId == SPELL_RANGER_RUSTY_SHIV_DAMAGE;
}

bool IsCultistTwilightShieldtoss(uint32 spellId)
{
    switch (spellId)
    {
        case 503487:
        case 503488:
        case 524876:
        case 572140:
        case 572141:
        case 572715:
        case 804208:
            return true;
        default:
            return false;
    }
}

void AddRangerAdvantage(Player* player, uint8 amount)
{
    for (uint8 index = 0; index < amount; ++index)
        player->CastSpell(player, SPELL_RANGER_ADVANTAGE_INCREMENT, true);
}

void HandleRangerAdvantageCast(Spell* spell, Player* player)
{
    uint32 spellId = spell->GetSpellInfo()->Id;
    uint8 amount = 0;
    if (IsRangerWildStrike(spellId))
        amount = player->HasAura(SPELL_RANGER_RAVAGER) || player->HasAura(SPELL_RANGER_RAVAGER_LEGACY) ? 2 : 1;
    else if (IsRangerFlank(spellId))
        amount = 2;
    else if (IsRangerQuickShot(spellId) || IsRangerToxicDart(spellId))
        amount = 1;
    else if (IsRangerHuntingShot(spellId))
    {
        for (TargetInfo const& target : *spell->GetUniqueTargetInfo())
            if (target.targetGUID != player->GetGUID())
                ++amount;
    }

    if (amount && spell->TryMarkScriptEventHandled(RANGER_ADVANTAGE_CAST_EVENT))
        AddRangerAdvantage(player, amount);
}

void ApplyRangerQuiver(Player* player, uint32 spellId)
{
    for (uint32 quiverId : RANGER_QUIVERS)
        if (quiverId != spellId)
            player->RemoveAurasDueToSpell(quiverId);
}

void SynchronizeRangerQuiver(Player* player)
{
    Aura const* newest = nullptr;
    uint32 newestId = 0;
    for (uint32 spellId : RANGER_QUIVERS)
    {
        Aura const* aura = player->GetAura(spellId);
        if (aura && (!newest || aura->GetApplyTime() > newest->GetApplyTime()))
        {
            newest = aura;
            newestId = spellId;
        }
    }

    if (newest)
        ApplyRangerQuiver(player, newestId);
}

bool DidRangerAdvantageConsumerSucceed(Spell* spell, Player const* player)
{
    bool hasExternalTarget = false;
    for (TargetInfo const& targetInfo : *spell->GetUniqueTargetInfo())
    {
        if (targetInfo.targetGUID == player->GetGUID())
            continue;

        hasExternalTarget = true;
        if (targetInfo.missCondition == SPELL_MISS_NONE)
            return true;
    }

    return !hasExternalTarget;
}

void HandleRangerQuiverHit(Player* player, Unit* target,
    SpellInfo const* spellInfo, uint32 damage)
{
    if (spellInfo->DmgClass != SPELL_DAMAGE_CLASS_RANGED)
        return;

    if (AuraEffect const* searing = player->GetAuraEffect(
            SPELL_RANGER_SEARING_QUIVER, EFFECT_0); searing && damage)
    {
        int32 fireDamage = CalculatePct(damage, searing->GetAmount());
        player->CastCustomSpell(target, SPELL_RANGER_SEARING_QUIVER_DAMAGE,
            &fireDamage, nullptr, nullptr, true, nullptr, searing);
    }

    if (AuraEffect const* poison = player->GetAuraEffect(
            SPELL_RANGER_POISON_QUIVER, EFFECT_1))
    {
        player->CastSpell(target, SPELL_RANGER_POISON_QUIVER_DAMAGE, true,
            nullptr, poison);
    }
}

void HandleRangerBountyHunterHit(Player* player, Unit* target,
    uint32 spellId, uint32 damage)
{
    if (damage && player->HasAura(SPELL_RANGER_BOUNTY_HUNTER) &&
        IsRangerBountyHunterTrigger(spellId))
    {
        player->CastSpell(target, SPELL_RANGER_BOUNTY_HUNTER_DEBUFF, true);
    }
}

void HandleRangerAdvantageSpent(Player* player, uint8 amount)
{
    if (player->HasAura(SPELL_RANGER_RUB_IT_IN))
    {
        for (uint8 index = 0; index < amount; ++index)
            if (roll_chance_i(RANGER_ADVANTAGE_REFUND_CHANCE))
                AddRangerAdvantage(player, 1);
    }

    if (player->HasAura(SPELL_RANGER_SNIPERS_FOCUS))
    {
        for (uint8 index = 0; index < amount; ++index)
            if (roll_chance_i(RANGER_ADVANTAGE_REFUND_CHANCE))
                player->CastSpell(player,
                    SPELL_RANGER_SNIPERS_FOCUS_ENERGIZE, true);
    }

    if (amount == 5 && player->HasAura(SPELL_RANGER_MAXIMUM_POWER) &&
        player->HasAura(SPELL_RANGER_SKIRMISH))
    {
        player->CastSpell(player, SPELL_RANGER_MAXIMUM_POWER_EXTENSION, true);
    }
}
}

namespace
{
bool IsCustomClassFamily(uint32 family)
{
    return family >= 18 && family <= 38;
}

bool HasDeprecatedWord(char const* text)
{
    if (!text)
        return false;

    std::string lower(text);
    std::transform(lower.begin(), lower.end(), lower.begin(), [](unsigned char c) { return char(std::tolower(c)); });
    auto isWordChar = [](char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_'; };
    for (std::string_view word : { std::string_view("deprecated"), std::string_view("depreacated") })
        for (std::size_t at = lower.find(word); at != std::string::npos; at = lower.find(word, at + 1))
            if ((at == 0 || !isWordChar(lower[at - 1])) &&
                (at + word.size() == lower.size() || !isWordChar(lower[at + word.size()])))
                return true;

    return false;
}

uint32 RepairedRangedInventoryMask(int32 itemClass, uint32 subclassMask, uint32 inventoryMask)
{
    uint32 const rangedSubclasses = (1 << 2) | (1 << 3) | (1 << 16) | (1 << 18) | (1 << 19);
    if (itemClass != ITEM_CLASS_WEAPON || !subclassMask || (subclassMask & ~rangedSubclasses) || !inventoryMask)
        return inventoryMask;

    uint32 corrected = inventoryMask;
    if (subclassMask & ((1 << 2) | (1 << 3) | (1 << 18)))
        corrected |= (1 << INVTYPE_RANGED) | (1 << INVTYPE_RANGEDRIGHT);
    if (subclassMask & (1 << 16))
        corrected |= 1 << INVTYPE_THROWN;
    if (subclassMask & (1 << 19))
        corrected |= 1 << INVTYPE_RANGEDRIGHT;
    return corrected;
}

struct ClientSpellCharge
{
    uint32 Maximum;
    uint32 RecoveryMs;
    uint32 Category;
};

std::unordered_map<uint32, ClientSpellCharge> const& ClientSpellCharges()
{
    static std::unordered_map<uint32, ClientSpellCharge> const charges = []
    {
        std::unordered_map<uint32, ClientSpellCharge> result;
        ClientDBC categories;
        ClientDBC links;
        if (!categories.Load(GetClientDBCPath("SpellChargesCategory.dbc"), 3) ||
            !links.Load(GetClientDBCPath("SpellCharges.dbc"), 2))
            return result;

        std::unordered_map<uint32, std::pair<uint32, uint32>> byCategory;
        for (uint32 row = 0; row < categories.GetRecordCount(); ++row)
        {
            ClientDBC::Record record = categories.GetRecord(row);
            byCategory[record.GetUInt32(0)] = { record.GetUInt32(1), record.GetUInt32(2) };
        }

        for (uint32 row = 0; row < links.GetRecordCount(); ++row)
        {
            ClientDBC::Record record = links.GetRecord(row);
            uint32 const spellId = record.GetUInt32(0);
            uint32 const categoryId = record.GetUInt32(1);
            auto category = byCategory.find(categoryId);
            if (category == byCategory.end() || category->second.first < 1 || category->second.first > 20 ||
                category->second.second < 1 || category->second.second > 86400000)
            {
                LOG_ERROR("coa", "Skipped invalid client charge category {} of spell {}",
                    categoryId, spellId);
                continue;
            }

            result[spellId] = { category->second.first, category->second.second, categoryId };
        }

        LOG_INFO("coa", "Loaded {} client spell charge records", result.size());
        return result;
    }();
    return charges;
}

uint32 ChargeRankRoot(uint32 spellId)
{
    static std::unordered_map<uint32, uint32> const roots = []
    {
        std::unordered_map<uint32, uint32> result;
        for (AscensionProgression::Rank const& rank : AscensionProgression::Ranks)
            result.emplace(rank.SpellId, rank.FirstSpellId);
        return result;
    }();
    auto root = roots.find(spellId);
    return root != roots.end() ? root->second : spellId;
}

void ApplyClientSpellCharges(SpellInfo* spellInfo)
{
    auto charge = ClientSpellCharges().find(spellInfo->Id);
    if (charge == ClientSpellCharges().end() || spellInfo->IsDeprecatedForPlayers)
        return;

    uint32 const root = ChargeRankRoot(spellInfo->Id);
    uint32 recoveryMs = charge->second.RecoveryMs;
    if (root == 707141 && charge->second.Category == 110 && charge->second.Maximum == 3 && recoveryMs == 5000)
        recoveryMs = 6000;

    spellInfo->MaxCharges = charge->second.Maximum;
    spellInfo->ChargeRecoveryTime = recoveryMs;
    spellInfo->ChargeRecoveryKey = root;
    spellInfo->ChargeCategoryId = charge->second.Category;
}
}

void ApplyAscensionClassMechanics(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    ApplyAscensionGuardianResourceContracts(spellInfo);

    if (spellInfo->Id == 707188)
        spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;

    ApplyAscensionClassMechanics19To25(spellInfo);
    ApplyAscensionBarbarianSpellChanges(spellInfo);
    ApplyAscensionWarcraftRebornWarriorContracts(spellInfo);
    ApplyAscensionHeroWarriorContracts(spellInfo);
    ApplyAscensionWarcraftRebornPaladinContracts(spellInfo);
    ApplyAscensionWarcraftRebornHunterContracts(spellInfo);
    ApplyAscensionWarcraftRebornRogueContracts(spellInfo);
    ApplyAscensionWarcraftRebornPriestContracts(spellInfo);
    ApplyAscensionWarcraftRebornMageContracts(spellInfo);
    ApplyAscensionWarcraftRebornWarlockContracts(spellInfo);
    ApplyAscensionWarcraftRebornDruidContracts(spellInfo);
    ApplyAscensionHeroHunterContracts(spellInfo);
    ApplyAscensionHeroRogueContracts(spellInfo); ApplyAscensionHeroPriestContracts(spellInfo); ApplyAscensionHeroWarlockContracts(spellInfo); ApplyAscensionHeroPaladinContracts(spellInfo);
    ApplyTinkerScrapResourceContract(spellInfo);
    ApplyTinkerScrapperContract(spellInfo);
    ApplyRangerFixedDurationContract(spellInfo);
    ApplyRangerConditionalDamageContracts(spellInfo);
    ApplyRangerSerrationsContract(spellInfo);
    ApplyRangerUnderhandedContracts(spellInfo);
    ApplyRangerInstinctualCombatantContract(spellInfo);
    ApplyAscensionRangerDamageContracts(spellInfo);
    ApplyAscensionWitchHunterTonicContracts(spellInfo);
    ApplyAscensionWitchHunterFlameContracts(spellInfo);
    ApplyAscensionWitchHunterScalingContracts(spellInfo);
    ApplyAscensionWitchHunterTargetingContracts(spellInfo);
    ApplyAscensionWitchHunterStakeContracts(spellInfo);
    AscensionWitchHunter::ApplyContracts(spellInfo);
    AscensionWitchDoctor::ApplyContracts(spellInfo);
    AscensionNecromancer::ApplyContracts(spellInfo);
    AscensionTemplar::ApplyContracts(spellInfo);
    AscensionFelsworn::ApplyContracts(spellInfo);
    AscensionXoroth::ApplyContracts(spellInfo);
    AscensionStarcaller::ApplyContracts(spellInfo);
    AscensionPyromancer::ApplyContracts(spellInfo);
    AscensionCultist::ApplyContracts(spellInfo);
    AscensionVenomancer::ApplyContracts(spellInfo);
    AscensionTinker::ApplyContracts(spellInfo);
    AscensionSunCleric::ApplyContracts(spellInfo);
    AscensionStormbringer::ApplyContracts(spellInfo);
    ApplyAscensionConditionalCombatContracts(spellInfo);
    ApplyAscensionRunemasterGlyphContracts(spellInfo);
    ApplyAscensionRunemasterBrandContracts(spellInfo);
    ApplyAscensionRunemasterScalingContracts(spellInfo);
    ApplyAscensionRunemasterDamageModifierContracts(spellInfo);
    ApplyAscensionTinkerCombustionContracts(spellInfo);
    ApplyAscensionTinkerOverloadMetadata(spellInfo);
    ApplyAscensionRunemasterZenithContracts(spellInfo);
    ApplyAscensionTemplarLibramContracts(spellInfo);
    ApplyAscensionHealingStatSelectorContracts(spellInfo);
    ApplyAdditionalTargetContracts(spellInfo);
    ApplyRangerOffensiveSpellContracts(spellInfo);
    ApplyRangerForestDwellerContract(spellInfo);
    ApplyAscensionSunClericRadianceContracts(spellInfo);

    if (spellInfo->Id == 504144)
    {
        SpellEffectInfo& effect = spellInfo->Effects[EFFECT_0];
        if (spellInfo->SpellFamilyName == uint32(CLASS_GUARDIAN) + 6 &&
            effect.Effect == SPELL_EFFECT_APPLY_AURA &&
            effect.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
            effect.MiscValue == SPELLMOD_EFFECT3 && effect.SpellClassMask == flag96(0, 0, 0x00100000))
        {
            effect.ApplyAuraName = SPELL_AURA_DUMMY;
        }
        else
            LOG_ERROR("coa", "Skipped unexpected Bannerman record {}", spellInfo->Id);
    }

    if (spellInfo->Id == SPELL_GUARDIAN_RAISE_SHIELD_ENERGIZE)
    {
        SpellEffectInfo& effect = spellInfo->Effects[EFFECT_0];
        if (effect.Effect == SPELL_EFFECT_ENERGIZE &&
            effect.MiscValue == POWER_ENERGY &&
            effect.DieSides == 1 &&
            (effect.BasePoints == 29 ||
                effect.BasePoints == GUARDIAN_RAISE_SHIELD_ENERGY_BASE_POINTS))
        {
            effect.BasePoints = GUARDIAN_RAISE_SHIELD_ENERGY_BASE_POINTS;
        }
        else
        {
            LOG_ERROR("coa",
                "Skipped unexpected Raise Shield energize record {}",
                spellInfo->Id);
        }
    }

    if (spellInfo->Id == SPELL_RANGER_BOUNTY_HUNTER)
    {
        SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_0];
        if (spellInfo->SpellFamilyName == uint32(CLASS_RANGER) + 6 &&
            (spellInfo->ProcFlags == PROC_FLAG_DONE_MELEE_AUTO_ATTACK ||
                spellInfo->ProcFlags == PROC_FLAG_NONE) &&
            effect.Effect == SPELL_EFFECT_APPLY_AURA &&
            effect.ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL &&
            effect.TriggerSpell == SPELL_RANGER_BOUNTY_HUNTER_DEBUFF)
        {
            spellInfo->ProcFlags = PROC_FLAG_NONE;
        }
        else
        {
            LOG_ERROR("coa",
                "Skipped unexpected Bounty Hunter record {}", spellInfo->Id);
        }
    }

    spellInfo->IsDeprecatedForPlayers =
        HasDeprecatedWord(spellInfo->SpellName[0]) || HasDeprecatedWord(spellInfo->Rank[0]);
    ApplyClientSpellCharges(spellInfo);
    AscensionTinker::ApplyBeaconChargePool(spellInfo);
    AscensionTinker::ApplyReplenishmentFieldAura(spellInfo);

    if (IsCustomClassFamily(spellInfo->SpellFamilyName))
        spellInfo->EquippedItemInventoryTypeMask = int32(RepairedRangedInventoryMask(spellInfo->EquippedItemClass,
            uint32(spellInfo->EquippedItemSubClassMask), uint32(spellInfo->EquippedItemInventoryTypeMask)));
}

void SynchronizeAscensionClassMechanics(Player* player)
{
    if (!player || !IsAscensionClass(player->getClass()))
        return;

    std::vector<uint32> obsolete;
    for (auto const& [spellId, playerSpell] : player->GetSpellMap())
    {
        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
        if (playerSpell->State != PLAYERSPELL_REMOVED && spellInfo && spellInfo->IsDeprecatedForPlayers)
            obsolete.push_back(spellId);
    }
    for (uint32 spellId : obsolete)
        player->removeSpell(spellId, SPEC_MASK_ALL, false);

    if (player->getClass() == CLASS_GUARDIAN)
    {
        if (player->HasAura(SPELL_GUARDIAN_TOWER_FORMATION))
            ApplyGuardianFormation(player, SPELL_GUARDIAN_TOWER_FORMATION);
        else if (player->HasAura(SPELL_GUARDIAN_LINE_FORMATION))
            ApplyGuardianFormation(player, SPELL_GUARDIAN_LINE_FORMATION);
        else if (player->HasAura(SPELL_GUARDIAN_ASSAULT_FORMATION))
            ApplyGuardianFormation(player, SPELL_GUARDIAN_ASSAULT_FORMATION);
        else
            RemoveGuardianFormationHelpers(player);
    }
    else if (player->getClass() == CLASS_RANGER)
    {
        SynchronizeRangerQuiver(player);
        if (player->HasAura(SPELL_RANGER_ELUDE))
        {
            if (!player->HasAura(SPELL_RANGER_ELUDE_EFFECTS))
                player->CastSpell(player, SPELL_RANGER_ELUDE_EFFECTS, true);
            if (!player->HasAura(SPELL_RANGER_ELUDE_SPEED_PENALTY))
                player->CastSpell(player, SPELL_RANGER_ELUDE_SPEED_PENALTY, true);
            RefreshRangerEludePenalty(player);
        }
        else
        {
            player->RemoveAurasDueToSpell(SPELL_RANGER_ELUDE_EFFECTS);
            player->RemoveAurasDueToSpell(SPELL_RANGER_ELUDE_SPEED_PENALTY);
        }
    }

    player->SendAllSpellChargeStates();
}

void PrepareAscensionClassMechanicsCast(Spell* spell)
{
    if (!spell || spell->IsTriggered())
        return;

    Player* player = spell->GetCaster()->ToPlayer();
    if (!player || player->getClass() != CLASS_GUARDIAN ||
        !IsGuardianCenturionStrike(spell->GetSpellInfo()->Id))
        return;

    RemoveGuardianCenturionWeaponEffects(player);
    uint32 weaponSubclass = GetMainHandWeaponSubclass(player);
    if (IsAxeSubclass(weaponSubclass))
        player->CastSpell(player, SPELL_GUARDIAN_CENTURION_AXE_EFFECTS, true);
    else if (IsMaceSubclass(weaponSubclass))
        player->CastSpell(player, SPELL_GUARDIAN_CENTURION_MACE_EFFECTS, true);
    else if (weaponSubclass == ITEM_SUBCLASS_WEAPON_POLEARM)
        AddGuardianCenturionPolearmTargets(spell, player);
}

void HandleAscensionClassMechanicsCalculatedTarget(Spell* spell, Player* player,
    Unit* target, TargetInfo& targetInfo)
{
    if (!spell || !player || !target)
        return;

    HandleAscensionClassMechanics12To17CalculatedTarget(spell, player, target,
        targetInfo);
}

void HandleAscensionClassMechanicsHit(Spell* spell, Player* player,
    Unit* target, std::uint8_t missInfo, std::uint32_t damage,
    std::uint32_t, bool critical)
{
    if (!spell || !player || !target || missInfo != SPELL_MISS_NONE)
        return;

    HandleAscensionClassMechanics12To17Hit(spell, player, target, missInfo,
        damage, critical);
    HandleAscensionClassMechanics19To25Hit(spell, player, target, missInfo,
        damage);
    HandleAscensionClassMechanics26To32Hit(spell, player, target, missInfo,
        damage, critical);

    if (target == player || player->IsFriendlyTo(target))
        return;

    uint32 spellId = spell->GetSpellInfo()->Id;
    if (player->getClass() == CLASS_RANGER)
        HandleRangerBountyHunterHit(player, target, spellId, damage);

    if (spell->IsTriggered())
        return;

    if (player->getClass() == CLASS_GUARDIAN)
    {
        if (IsGuardianCenturionStrike(spellId) &&
            IsSwordSubclass(GetMainHandWeaponSubclass(player)) &&
            target == spell->GetOriginalTarget() &&
            spell->TryMarkScriptEventHandled(GUARDIAN_CENTURION_SWORD_EVENT))
        {
            player->CastSpell(player,
                SPELL_GUARDIAN_CENTURION_SWORD_ATTACKS, true);
        }

        if (IsGuardianCenturionStrike(spellId) && damage &&
            GetMainHandWeaponSubclass(player) == ITEM_SUBCLASS_WEAPON_POLEARM &&
            target == spell->GetOriginalTarget() &&
            spell->TryMarkScriptEventHandled(GUARDIAN_CENTURION_POLEARM_EVENT))
        {
            SpellInfo const* centurion = spell->GetSpellInfo();
            uint32 const struck = Unit::DealDamage(player, target, damage,
                nullptr, SPELL_DIRECT_DAMAGE, centurion->GetSchoolMask(),
                centurion, false);
            player->SendSpellNonMeleeDamageLog(target, centurion, struck,
                centurion->GetSchoolMask(), 0, 0, true, 0, critical);
        }

        if (!damage)
            return;

        if (IsGuardianRam(spellId))
        {
            if (player->HasAura(SPELL_GUARDIAN_NO_ESCAPE) &&
                target->HasRootAura())
            {
                player->CastSpell(player, SPELL_GUARDIAN_NO_ESCAPE_RESET,
                    true);
            }
            if (critical && player->HasAura(SPELL_GUARDIAN_PLATE_BUSTER))
                player->CastSpell(player, SPELL_GUARDIAN_PLATE_BUSTER_RESET,
                    true);
            if (player->HasAura(SPELL_GUARDIAN_SHOW_OF_FORCE))
                player->CastSpell(target, SPELL_GUARDIAN_SHOW_OF_FORCE_DISPEL,
                    true);
            TryGuardianKingsGuardReset(player);
        }
        else if (IsGuardianPulverize(spellId))
            TryGuardianKingsGuardReset(player);
        else if (IsGuardianHammerOfJustice(spellId) &&
            player->HasAura(SPELL_GUARDIAN_ORDER_IN_THE_COURT))
        {
            player->CastSpell(target,
                SPELL_GUARDIAN_ORDER_IN_THE_COURT_DEBUFF, true);
        }
        else if (IsGuardianSpearThrow(spellId) &&
            player->HasAura(SPELL_GUARDIAN_PINNED_DOWN))
        {
            player->CastSpell(target, SPELL_GUARDIAN_PINNED_DOWN_REFRESH,
                true);
        }
        return;
    }

    if (player->getClass() == CLASS_CULTIST && IsCultistTwilightShieldtoss(spellId))
    {
        player->CastSpell(target, SPELL_CULTIST_TWILIGHT_SHIELDTOSS_SLOW, true);
        return;
    }

    if (player->getClass() != CLASS_RANGER)
        return;

    HandleRangerQuiverHit(player, target, spell->GetSpellInfo(), damage);

    if (IsRangerQuickShot(spellId) && critical && player->HasAura(SPELL_RANGER_ARCHERY_MASTER) &&
        spell->TryMarkScriptEventHandled(RANGER_ARCHERY_MASTER_EVENT))
        AddRangerAdvantage(player, 1);
}

void HandleAscensionClassMechanicsCast(Spell* spell)
{
    HandleAscensionGuardianResourceCast(spell);
    HandleAscensionBarbarianCast(spell);
    if (!spell || spell->IsTriggered())
        return;
    Player* player = spell->GetCaster()->ToPlayer();
    if (!player)
        return;

    SpellInfo const* info = spell->GetSpellInfo();
    if (player->getClass() == CLASS_WARLOCK && info->Id == 217364 &&
        !player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND))
    {
        if (Unit* target = spell->GetOriginalTarget())
            player->CastSpell(target, 281295, true);
    }
    if (player->getClass() == CLASS_RANGER)
        HandleRangerAdvantageCast(spell, player);

    if (player->getClass() == CLASS_RANGER &&
        info->CasterAuraSpell == SPELL_RANGER_ADVANTAGE)
    {
        if (!DidRangerAdvantageConsumerSucceed(spell, player))
            return;

        HandleAscensionRangerStonemason(spell, player);
        HandleAscensionRangerPhoenixPlumes(spell, player);

        float consumeChance = 100.0f;
        player->ApplySpellMod(SPELL_RANGER_ADVANTAGE_DECREMENT_PASSIVE,
            SPELLMOD_CHANCE_OF_SUCCESS, consumeChance, spell);
        if (roll_chance_f(consumeChance))
        {
            uint8 spent = 0;
            if (Aura const* advantage = player->GetAura(SPELL_RANGER_ADVANTAGE))
                spent = advantage->GetStackAmount();
            player->CastSpell(player, SPELL_RANGER_ADVANTAGE_DECREMENT, true);
            HandleRangerAdvantageSpent(player, spent);
        }
        return;
    }

    if (player->getClass() != CLASS_GUARDIAN)
        return;

    uint32 firstRank = sSpellMgr->GetFirstSpellInChain(info->Id);
    if (firstRank == 800316)
    {
        player->CastSpell(player, 500175, true);
        player->RemoveAurasDueToSpell(SPELL_GUARDIAN_REPRISAL_READY);
    }
    else if (IsGuardianCenturionStrike(info->Id) && player->HasAura(504140))
    {
        player->CastSpell(player, 504143, true);
    }

    uint32 spellId = info->Id;
    bool guardbreakerAbility = IsGuardianPulverize(spellId) ||
        IsGuardianRam(spellId) ||
        (player->HasAura(505344) &&
            IsGuardianBalladOfTheConqueror(spellId));
    if (guardbreakerAbility && player->HasAura(SPELL_GUARDIAN_GUARDBREAKER) &&
        roll_chance_i(GUARDIAN_GUARDBREAKER_CHANCE))
    {
        player->CastSpell(player, SPELL_GUARDIAN_GUARDBREAKER_RESET, true);
    }

    if (IsGuardianAdvance(spellId) && player->HasAura(SPELL_GUARDIAN_REFUSE))
        player->CastSpell(player, SPELL_GUARDIAN_REFUSE_RESET, true);

    if (IsGuardianBattleRush(spellId) &&
        player->HasAura(SPELL_GUARDIAN_BULWARK_RUSH))
    {
        player->CastSpell(player, SPELL_GUARDIAN_BULWARK_RUSH_EFFECTS, true);
    }

    if ((spellId == SPELL_GUARDIAN_RAISE_SHIELD ||
            IsGuardianHeavyBlow(spellId)) &&
        player->HasAura(SPELL_GUARDIAN_FORCEFUL_IMPACT))
    {
        ExtendGuardianBrace(player);
    }

    if (IsGuardianHeavyBlow(spellId))
    {
        if (player->HasAura(SPELL_GUARDIAN_VANGUARDS_MIGHT))
        {
            player->CastSpell(player,
                SPELL_GUARDIAN_VANGUARDS_MIGHT_EFFECTS, true);
        }
        if (player->HasAura(SPELL_GUARDIAN_HIGH_GUARD_EFFECTS))
        {
            player->RemoveAurasDueToSpell(
                SPELL_GUARDIAN_HIGH_GUARD_EFFECTS);
            player->CastSpell(player, SPELL_GUARDIAN_REPRISAL_READY, true);
        }
    }

    if ((spellId == SPELL_GUARDIAN_RAISE_SHIELD ||
            IsGuardianAdvance(spellId) || IsGuardianBattleRush(spellId)) &&
        player->HasAura(SPELL_GUARDIAN_HIGH_GUARD))
    {
        player->CastSpell(player, SPELL_GUARDIAN_HIGH_GUARD_EFFECTS, true);
    }

    if ((IsGuardianStandardOfValiance(spellId) || spellId == 803420) &&
        player->HasAura(SPELL_GUARDIAN_WRECK_FORMATION))
    {
        player->CastSpell(player, SPELL_GUARDIAN_WRECK_FORMATION_AP, true);
    }

    if (IsGuardianBallad(spellId))
    {
        if (player->HasAura(SPELL_GUARDIAN_KNIGHTS_SONG))
        {
            player->CastSpell(player,
                SPELL_GUARDIAN_KNIGHTS_SONG_EFFECTS, true);
        }
        if (player->HasAura(SPELL_GUARDIAN_MINSTREL))
            player->CastSpell(player, SPELL_GUARDIAN_MINSTREL_EFFECTS, true);
    }

    if (IsGuardianCenturionStrike(info->Id))
        RemoveGuardianCenturionWeaponEffects(player);
}

void HandleAscensionClassMechanicsBlock(Player* player)
{
    if (!player || player->getClass() != CLASS_GUARDIAN)
        return;

    if (player->HasAura(SPELL_GUARDIAN_RAISE_SHIELD))
        player->CastSpell(player, SPELL_GUARDIAN_RAISE_SHIELD_ENERGIZE, true);

    if (player->HasSpell(SPELL_GUARDIAN_REPRISAL))
        player->CastSpell(player, SPELL_GUARDIAN_REPRISAL_READY, true);
    if (player->HasAura(SPELL_GUARDIAN_VETERAN))
        player->CastSpell(player, SPELL_GUARDIAN_VETERAN_HEAL, true);
    if (player->HasAura(SPELL_GUARDIAN_HONORABLE))
        player->CastSpell(player, SPELL_GUARDIAN_HONORABLE_EFFECTS, true);
}

void HandleAscensionClassMechanicsAuraApply(Player* player, std::uint32_t spellId)
{
    HandleAscensionBarbarianAura(player, spellId, true);
    if (!player)
        return;

    if (player->getClass() == CLASS_RANGER &&
        (spellId == SPELL_RANGER_FOREST_DWELLER || spellId == SPELL_RANGER_ELUDE_SPEED_PENALTY))
        RefreshRangerEludePenalty(player);

    auto formation = std::find(GUARDIAN_FORMATIONS.begin(), GUARDIAN_FORMATIONS.end(), spellId);
    if (player->getClass() == CLASS_GUARDIAN && formation != GUARDIAN_FORMATIONS.end())
    {
        ApplyGuardianFormation(player, spellId);
        if (spellId == SPELL_GUARDIAN_TOWER_FORMATION)
            player->CastSpell(player, SPELL_GUARDIAN_TOWER_FORMATION_VISUAL, true);
        return;
    }

    if (player->getClass() == CLASS_GUARDIAN &&
        spellId == SPELL_GUARDIAN_FOOTMANS_CALLING)
    {
        if (player->HasAura(SPELL_GUARDIAN_TOWER_FORMATION))
            ApplyGuardianFormation(player, SPELL_GUARDIAN_TOWER_FORMATION);
        else if (player->HasAura(SPELL_GUARDIAN_LINE_FORMATION))
            ApplyGuardianFormation(player, SPELL_GUARDIAN_LINE_FORMATION);
        return;
    }

    if (player->getClass() == CLASS_RANGER && spellId == SPELL_RANGER_ELUDE)
    {
        player->CastSpell(player, SPELL_RANGER_ELUDE_EFFECTS, true);
        player->CastSpell(player, SPELL_RANGER_ELUDE_SPEED_PENALTY, true);
        if (player->HasAura(SPELL_RANGER_LETHAL_CUNNING))
            player->CastSpell(player, SPELL_RANGER_LETHAL_CUNNING_EFFECTS,
                true);
    }

    else if (player->getClass() == CLASS_RANGER &&
        std::find(RANGER_QUIVERS.begin(), RANGER_QUIVERS.end(), spellId) !=
            RANGER_QUIVERS.end())
    {
        ApplyRangerQuiver(player, spellId);
    }
}

void HandleAscensionClassMechanicsAuraRemove(Player* player, std::uint32_t spellId, bool removedByDeath)
{
    RemoveAscensionGuardianResourceTalent(player, spellId);
    HandleAscensionBarbarianAura(player, spellId, false);
    if (!player)
        return;

    auto formation = std::find(GUARDIAN_FORMATIONS.begin(), GUARDIAN_FORMATIONS.end(), spellId);
    if (player->getClass() == CLASS_GUARDIAN && formation != GUARDIAN_FORMATIONS.end())
    {
        RemoveGuardianFormationHelpers(player);
        return;
    }

    if (player->getClass() == CLASS_GUARDIAN &&
        spellId == SPELL_GUARDIAN_FOOTMANS_CALLING)
    {
        player->RemoveAurasDueToSpell(
            SPELL_GUARDIAN_FOOTMANS_CALLING_EFFECTS);
        return;
    }

    if (player->getClass() == CLASS_RANGER && spellId == SPELL_RANGER_ELUDE)
    {
        player->RemoveAurasDueToSpell(SPELL_RANGER_ELUDE_EFFECTS);
        player->RemoveAurasDueToSpell(SPELL_RANGER_ELUDE_SPEED_PENALTY);
        ApplyRangerEludeExitEffects(player, removedByDeath);
    }

    if (player->getClass() == CLASS_RANGER && spellId == SPELL_RANGER_ELUSIVE_CHARACTER)
        player->RemoveAurasDueToSpell(SPELL_RANGER_ELUSIVE_CHARACTER_EFFECTS);

    if (player->getClass() == CLASS_RANGER && spellId == SPELL_RANGER_FOREST_DWELLER)
        RefreshRangerEludePenalty(player);
}
