/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU
 * AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionFreshCharacterCheck.h"
#include "AscensionFreshCharacterExpectations.h"
#include "AscensionCustomClassData.h"
#include "AscensionLiveBaselineData.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "GameTime.h"
#include "Item.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "RBAC.h"
#include "SpellAuraDefines.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "World.h"
#include "WorldSession.h"
#include "WorldSessionMgr.h"

#include <algorithm>
#include <array>
#include <deque>
#include <exception>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iterator>
#include <locale>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

namespace
{
constexpr uint32 ReservedAccount = 4000000000;
constexpr uint32 FirstReservedGuid = 4000000000;
constexpr uint32 LastReservedGuid = FirstReservedGuid + 20;
constexpr char OutputDirectory[] = "C:/Ascension/Runtime/validation/live-class-baseline-20260903";

std::string JsonString(std::string const& value)
{
    std::ostringstream output;
    output << '"';
    for (unsigned char c : value)
    {
        if (c == '"' || c == '\\')
            output << '\\' << c;
        else if (c < 32)
            output << "\\u" << std::hex << std::setw(4) << std::setfill('0') << uint32(c) << std::dec;
        else
            output << c;
    }
    output << '"';
    return output.str();
}

bool ReservedIdsAreAbsent()
{
    for (uint32 id = FirstReservedGuid; id <= LastReservedGuid; ++id)
        if (ObjectAccessor::FindConnectedPlayer(ObjectGuid(HighGuid::Player, id)))
            return false;
    auto* accountStatement = LoginDatabase.GetPreparedStatement(LOGIN_SEL_FRESH_CHECK_ACCOUNT_COUNT);
    accountStatement->SetData(0, ReservedAccount);
    PreparedQueryResult account = LoginDatabase.Query(accountStatement);
    if (!account || account->Fetch()[0].Get<uint64>() != 0)
        return false;

    auto* characterStatement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_FRESH_CHECK_GUID_COUNT);
    characterStatement->SetData(0, FirstReservedGuid);
    characterStatement->SetData(1, LastReservedGuid);
    PreparedQueryResult characters = CharacterDatabase.Query(characterStatement);
    return characters && characters->Fetch()[0].Get<uint64>() == 0;
}

struct ProbeCreateInfo : CharacterCreateInfo
{
    explicit ProbeCreateInfo(AscensionFreshCharacterExpectations::Case const& expected)
    {
        Name = "Freshcheck" + std::string(1, char('a' + expected.ClassId - 12));
        Race = expected.RaceId;
        Class = expected.ClassId;
        Gender = expected.Gender;
    }
};

struct ProbePlayerDeleter
{
    WorldSession* Session;

    void operator()(Player* player) const
    {
        if (player)
        {
            if (player->GetGUID())
                player->CleanupsBeforeDelete();
            Session->SetPlayer(nullptr);
            delete player;
        }
    }
};

struct Preflight
{
    std::set<uint32> Learned;
    std::set<uint32> Executed;
    std::set<uint32> Deferred;
    std::set<uint32> Skills;
    std::vector<std::string> Blockers;
};

enum class ClosureEvent
{
    Learn,
    Execute,
    Deferred
};

bool SafeAura(uint32 aura)
{
    switch (aura)
    {
        case SPELL_AURA_MOD_STEALTH_DETECT:
        case SPELL_AURA_MOD_STAT:
        case SPELL_AURA_MOD_SKILL:
        case SPELL_AURA_MOD_DODGE_PERCENT:
        case SPELL_AURA_MOD_PARRY_PERCENT:
        case SPELL_AURA_MOD_BLOCK_PERCENT:
        case SPELL_AURA_MOD_DAMAGE_DONE:
        case SPELL_AURA_MOD_DAMAGE_PERCENT_DONE:
        case SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN:
        case SPELL_AURA_MOD_ATTACK_POWER:
        case SPELL_AURA_MOD_RANGED_ATTACK_POWER:
        case SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE:
        case SPELL_AURA_MOD_RESISTANCE:
        case SPELL_AURA_MOD_RESISTANCE_PCT:
        case SPELL_AURA_MOD_SKILL_TALENT:
        case SPELL_AURA_MOD_DETECTED_RANGE:
        case SPELL_AURA_MOD_STEALTH_LEVEL:
        case SPELL_AURA_MOD_REPUTATION_GAIN:
        case SPELL_AURA_MOD_FACTION_REPUTATION_GAIN:
        case SPELL_AURA_MOD_EXPERTISE:
        case SPELL_AURA_ADD_FLAT_MODIFIER:
        case SPELL_AURA_ADD_PCT_MODIFIER:
        case SPELL_AURA_PROC_TRIGGER_SPELL:
        case SPELL_AURA_PERIODIC_TRIGGER_SPELL:
        case SPELL_AURA_MOD_HIT_CHANCE:
        case SPELL_AURA_MOD_SPELL_HIT_CHANCE:
        case SPELL_AURA_MOD_RATING:
        case SPELL_AURA_ASCENSION_MOD_HIT_CHANCE_ALL_PCT:
            return true;
        default:
            return false;
    }
}

bool SafeEffect(uint32 effect)
{
    switch (effect)
    {
        case 0:
        case SPELL_EFFECT_DODGE:
        case SPELL_EFFECT_PARRY:
        case SPELL_EFFECT_BLOCK:
        case SPELL_EFFECT_WEAPON:
        case SPELL_EFFECT_DEFENSE:
        case SPELL_EFFECT_SPELL_DEFENSE:
        case SPELL_EFFECT_DETECT:
        case SPELL_EFFECT_LANGUAGE:
        case SPELL_EFFECT_DUAL_WIELD:
        case SPELL_EFFECT_PROFICIENCY:
        case SPELL_EFFECT_SKILL_STEP:
        case SPELL_EFFECT_SKILL:
        case SPELL_EFFECT_APPLY_AURA:
        case SPELL_EFFECT_APPLY_AREA_AURA_PARTY:
        case SPELL_EFFECT_TRIGGER_SPELL:
        case SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE:
        case SPELL_EFFECT_LEARN_SPELL:
            return true;
        default:
            return false;
    }
}

Preflight CheckPassiveClosure(AscensionFreshCharacterExpectations::Case const& expected, PlayerInfo const& info)
{
    Preflight result;
    std::deque<std::pair<uint32, ClosureEvent>> spells;
    std::deque<uint32> skills;
    for (uint32 id : info.customSpells)
        spells.emplace_back(id, ClosureEvent::Learn);
    for (auto const& skill : info.skills)
        skills.push_back(skill.SkillId);
    for (auto const& spell : AscensionLiveBaseline::Spells)
        if (spell.ClassId == expected.ClassId && (!spell.RaceId || spell.RaceId == expected.RaceId))
            spells.emplace_back(spell.SpellId, ClosureEvent::Learn);
    for (auto const& spell : AscensionLiveBaseline::Proficiencies)
        if (spell.ClassId == expected.ClassId)
            spells.emplace_back(spell.SpellId, ClosureEvent::Learn);
    for (auto const& skill : AscensionLiveBaseline::Skills)
        if (skill.ClassId == expected.ClassId)
            skills.push_back(skill.SkillId);
    for (auto const& item : AscensionCompatData::LiveStarterItems)
    {
        if (item.ClassId != expected.ClassId)
            continue;
        ItemTemplate const* prototype = sObjectMgr->GetItemTemplate(item.ItemId);
        if (!prototype)
        {
            result.Blockers.push_back("missing item template " + std::to_string(item.ItemId));
            continue;
        }
        if (prototype->ItemSet || prototype->RandomProperty || prototype->RandomSuffix)
            result.Blockers.push_back("unreviewed item set/random property " + std::to_string(item.ItemId));
        if (item.Slot < EQUIPMENT_SLOT_END)
            for (auto const& spell : prototype->Spells)
                if (spell.SpellId && spell.SpellTrigger == ITEM_SPELLTRIGGER_ON_EQUIP)
                    spells.emplace_back(spell.SpellId, ClosureEvent::Execute);
    }

    while (!spells.empty() || !skills.empty())
    {
        if (result.Learned.size() + result.Executed.size() + result.Deferred.size() + result.Skills.size() > 4096)
        {
            result.Blockers.push_back("passive/skill closure exceeds bounded 4096 records");
            break;
        }
        while (!skills.empty())
        {
            uint32 id = skills.front();
            skills.pop_front();
            if (!result.Skills.insert(id).second)
                continue;
            for (auto const* ability : GetSkillLineAbilitiesBySkillLine(id))
            {
                if (ability->AcquireMethod != SKILL_LINE_ABILITY_LEARNED_ON_SKILL_LEARN &&
                    ability->AcquireMethod != SKILL_LINE_ABILITY_LEARNED_ON_SKILL_VALUE)
                    continue;
                if (ability->RaceMask && !(ability->RaceMask & (1u << (expected.RaceId - 1))))
                    continue;
                if (ability->ClassMask && !(ability->ClassMask & (1u << (expected.ClassId - 1))))
                    continue;
                spells.emplace_back(ability->Spell, ClosureEvent::Learn);
            }
        }
        if (spells.empty())
            continue;
        auto [id, event] = spells.front();
        spells.pop_front();
        SpellInfo const* spell = sSpellMgr->GetSpellInfo(id);
        if (event == ClosureEvent::Deferred)
        {
            if (!result.Deferred.insert(id).second)
                continue;
            if (spell)
                for (auto const& effect : spell->Effects)
                    if (effect.TriggerSpell)
                        spells.emplace_back(effect.TriggerSpell, ClosureEvent::Deferred);
            continue;
        }
        if (!spell)
        {
            result.Blockers.push_back("missing closure spell " + std::to_string(id));
            continue;
        }
        bool const newLearn = event == ClosureEvent::Learn && result.Learned.insert(id).second;
        if (newLearn)
        {
            if (auto const* skill = sSpellMgr->GetSpellLearnSkill(id))
                skills.push_back(skill->skill);
            auto abilities = sSpellMgr->GetSkillLineAbilityMapBounds(id);
            for (auto itr = abilities.first; itr != abilities.second; ++itr)
                skills.push_back(itr->second->SkillLine);
        }
        bool const execute = event == ClosureEvent::Execute || spell->IsPassive() || spell->HasEffect(SPELL_EFFECT_SKILL_STEP) ||
            (spell->HasAttribute(SPELL_ATTR0_DO_NOT_DISPLAY) && spell->Stances);
        if (!execute || !result.Executed.insert(id).second)
            continue;
        auto scripts = sObjectMgr->GetSpellScriptsBounds(id);
        if (scripts.first != scripts.second)
            result.Blockers.push_back("unreviewed bound SpellScript/AuraScript " + std::to_string(id));
        auto areas = sSpellMgr->GetSpellAreaForAuraMapBounds(id);
        if (areas.first != areas.second)
            result.Blockers.push_back("unreviewed spell_area aura lifecycle " + std::to_string(id));
        for (int32 key : {int32(id), -int32(id), int32(id + SPELL_LINK_AURA), int32(id + SPELL_LINK_HIT)})
            if (auto const* links = sSpellMgr->GetSpellLinked(key); links && !links->empty())
                result.Blockers.push_back("unreviewed spell_linked_spell lifecycle " + std::to_string(id));
        for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
        {
            auto const& effect = spell->Effects[index];
            bool const wispDummy = id == 20585 && spell->SpellFamilyName == SPELLFAMILY_GENERIC && index == 0 &&
                effect.Effect == SPELL_EFFECT_DUMMY && effect.BasePoints == 0 && effect.DieSides == 0 &&
                effect.MiscValue == 0 && !effect.TriggerSpell && effect.TargetA.GetTarget() == TARGET_UNIT_CASTER &&
                !effect.TargetB.GetTarget() && !spell->Effects[1].Effect && !spell->Effects[2].Effect;
            bool const necromancyDummy = id == 804360 && spell->SpellFamilyName == 29 && index == 2 &&
                effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.ApplyAuraName == SPELL_AURA_DUMMY &&
                effect.BasePoints == -21 && effect.DieSides == 1 && effect.MiscValue == 5 && !effect.TriggerSpell &&
                effect.TargetA.GetTarget() == TARGET_UNIT_CASTER && !effect.TargetB.GetTarget();
            if (sSpellMgr->GetPetAura(id, index) || sSpellScripts.count(id | (uint32(index) << 24)))
                result.Blockers.push_back("unreviewed pet aura/DB effect script " + std::to_string(id));
            if (!SafeEffect(effect.Effect) && !wispDummy)
                result.Blockers.push_back("unreviewed executed effect " + std::to_string(id) + ":" + std::to_string(effect.Effect));
            if (effect.ApplyAuraName && !SafeAura(effect.ApplyAuraName) && !necromancyDummy)
                result.Blockers.push_back("unreviewed executed aura " + std::to_string(id) + ":" + std::to_string(effect.ApplyAuraName));
            if (effect.TriggerSpell)
            {
                bool const deferred = effect.ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL ||
                    effect.ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL;
                spells.emplace_back(effect.TriggerSpell, deferred ? ClosureEvent::Deferred :
                    (effect.Effect == SPELL_EFFECT_LEARN_SPELL ? ClosureEvent::Learn : ClosureEvent::Execute));
            }
            if (effect.Effect == SPELL_EFFECT_SKILL_STEP || effect.Effect == SPELL_EFFECT_SKILL)
                if (effect.MiscValue > 0)
                    skills.push_back(uint32(effect.MiscValue));
        }
    }
    std::sort(result.Blockers.begin(), result.Blockers.end());
    result.Blockers.erase(std::unique(result.Blockers.begin(), result.Blockers.end()), result.Blockers.end());
    return result;
}

void WriteStrings(std::ostream& output, std::vector<std::string> const& values)
{
    output << '[';
    bool separator = false;
    for (auto const& value : values)
    {
        if (separator)
            output << ',';
        separator = true;
        output << JsonString(value);
    }
    output << ']';
}

void WriteIds(std::ostream& output, std::set<uint32> const& values)
{
    output << '[';
    bool separator = false;
    for (uint32 value : values)
    {
        if (separator)
            output << ',';
        separator = true;
        output << value;
    }
    output << ']';
}

bool IsReviewedHiddenSkillReward(Player const& player, uint32 spellId)
{
    auto const& reviewed = AscensionFreshCharacterExpectations::HiddenSkillRewards;
    auto expected = std::find_if(reviewed.begin(), reviewed.end(), [spellId](auto const& row)
        { return row.SpellId == spellId; });
    if (expected == reviewed.end() || !player.HasSkill(expected->SkillId))
        return false;
    SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
    if (!spell || spell->SpellFamilyName != SPELLFAMILY_GENERIC ||
        (!spell->HasAttribute(SPELL_ATTR0_DO_NOT_DISPLAY) && !spell->HasAttribute(SPELL_ATTR4_NOT_IN_SPELLBOOK)))
        return false;
    auto links = sSpellMgr->GetSkillLineAbilityMapBounds(spellId);
    for (auto itr = links.first; itr != links.second; ++itr)
    {
        auto const* link = itr->second;
        if (link->ID != expected->LinkId || link->SkillLine != expected->SkillId ||
            (link->RaceMask && !(link->RaceMask & player.getRaceMask())) ||
            (link->ClassMask && !(link->ClassMask & player.getClassMask())))
            continue;
        if (link->AcquireMethod == SKILL_LINE_ABILITY_LEARNED_ON_SKILL_LEARN ||
            (link->AcquireMethod == SKILL_LINE_ABILITY_LEARNED_ON_SKILL_VALUE &&
                player.GetPureSkillValue(expected->SkillId) >= link->MinSkillLineRank))
            return true;
    }
    return false;
}

bool WritePlayer(std::ostream& output, Player& player, AscensionFreshCharacterExpectations::Case const& expected)
{
    bool gearMatches = true;
    output << ",\"gear\":[";
    bool separator = false;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
    {
        Item* item = player.GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        auto expectedItem = std::find_if(AscensionCompatData::LiveStarterItems.begin(), AscensionCompatData::LiveStarterItems.end(),
            [&expected, slot](auto const& row) { return row.ClassId == expected.ClassId && row.Slot == slot; });
        if (expectedItem == AscensionCompatData::LiveStarterItems.end())
            gearMatches = gearMatches && !item;
        else
            gearMatches = gearMatches && item && item->GetEntry() == expectedItem->ItemId && item->GetCount() == expectedItem->Count;
        if (!item)
            continue;
        if (separator)
            output << ',';
        separator = true;
        output << "{\"bag\":255,\"slot\":" << uint32(slot) << ",\"item_id\":" << item->GetEntry()
               << ",\"count\":" << item->GetCount() << '}';
    }
    output << "],\"gear_matches\":" << gearMatches << ",\"spells\":[";
    std::set<uint32> spells;
    for (auto const& [id, entry] : player.GetSpellMap())
        if (entry->State != PLAYERSPELL_REMOVED)
            spells.insert(id);
    separator = false;
    for (uint32 id : spells)
    {
        if (separator)
            output << ',';
        separator = true;
        auto const* entry = player.GetSpellMap().at(id);
        output << "{\"id\":" << id << ",\"active\":" << bool(entry->Active)
               << ",\"spec_mask\":" << uint32(entry->specMask) << ",\"state\":" << uint32(entry->State) << '}';
    }
    std::set<uint32> missing;
    std::set<uint32> expectedSpells;
    std::set<uint32> missingProficiencies;
    for (auto const& spell : AscensionLiveBaseline::Spells)
        if (spell.ClassId == expected.ClassId && (!spell.RaceId || spell.RaceId == expected.RaceId))
        {
            expectedSpells.insert(spell.SpellId);
            if (!player.HasSpell(spell.SpellId))
                missing.insert(spell.SpellId);
        }
    for (auto const& spell : AscensionLiveBaseline::Proficiencies)
        if (spell.ClassId == expected.ClassId)
        {
            expectedSpells.insert(spell.SpellId);
            if (!player.HasSpell(spell.SpellId))
                missingProficiencies.insert(spell.SpellId);
        }
    std::set<uint32> extraSpells;
    std::set_difference(spells.begin(), spells.end(), expectedSpells.begin(), expectedSpells.end(),
        std::inserter(extraSpells, extraSpells.end()));
    std::set<uint32> hiddenNativeRewards;
    std::set<uint32> unexplainedExtraSpells;
    for (uint32 id : extraSpells)
        (IsReviewedHiddenSkillReward(player, id) ? hiddenNativeRewards : unexplainedExtraSpells).insert(id);
    output << "],\"missing_captured_spells\":";
    WriteIds(output, missing);
    output << ",\"missing_proficiencies\":";
    WriteIds(output, missingProficiencies);
    output << ",\"unexpected_spells\":";
    WriteIds(output, extraSpells);
    output << ",\"reviewed_hidden_native_skill_rewards\":";
    WriteIds(output, hiddenNativeRewards);
    output << ",\"unexplained_extra_spells\":";
    WriteIds(output, unexplainedExtraSpells);
    output << ",\"extra_spell_labels\":{\"native_honorless_service\":" << bool(extraSpells.count(2479))
           << ",\"bushcraft_recipe\":" << bool(extraSpells.count(802808))
           << ",\"visible_dual_wield_duplicate\":" << bool(extraSpells.count(370094))
           << ",\"guardian_wand_customization\":" << (expected.ClassId == 18 && extraSpells.count(5019)) << '}';
    output << ",\"skills\":[";
    std::set<uint32> skills;
    for (auto const& [id, entry] : player.GetSkillStatusMap())
        if (entry.uState != SKILL_DELETED)
            skills.insert(id);
    separator = false;
    bool skillsPolicyMatch = true;
    bool skillsCaptureMatch = true;
    std::set<uint32> extraSkills;
    for (uint32 id : skills)
    {
        if (separator)
            output << ',';
        separator = true;
        uint16 const rank = player.GetPureSkillValue(id);
        uint16 const maximum = player.GetPureMaxSkillValue(id);
        output << "{\"id\":" << id << ",\"rank\":" << rank
               << ",\"maximum\":" << maximum << ",\"step\":" << player.GetSkillStep(id);
        auto captured = std::find_if(AscensionLiveBaseline::Skills.begin(), AscensionLiveBaseline::Skills.end(),
            [&expected, id](auto const& entry) { return entry.ClassId == expected.ClassId && entry.SkillId == id; });
        if (captured != AscensionLiveBaseline::Skills.end())
        {
            bool const scaledWeapon = std::any_of(AscensionCompatData::ProficiencyDefinitions.begin(),
                AscensionCompatData::ProficiencyDefinitions.end(), [id](auto const& row)
                { return row.SkillId == id && row.ScalesWithLevel; });
            bool const nativeUnarmed = id == SKILL_UNARMED;
            uint16 const policyMaximum = scaledWeapon || nativeUnarmed ?
                player.GetMaxSkillValueForLevel() : captured->Maximum;
            uint16 const policyRank = scaledWeapon ? policyMaximum : (nativeUnarmed ? 1 : captured->Rank);
            skillsPolicyMatch = skillsPolicyMatch && rank == policyRank && maximum == policyMaximum;
            skillsCaptureMatch = skillsCaptureMatch && rank == captured->Rank && maximum == captured->Maximum;
            output << ",\"captured_rank\":" << captured->Rank << ",\"captured_maximum\":" << captured->Maximum
                   << ",\"policy_rank\":" << policyRank << ",\"policy_maximum\":" << policyMaximum
                   << ",\"weapon_combat_scaling_deviation\":" << scaledWeapon
                   << ",\"native_unarmed_growth_deviation\":" << nativeUnarmed;
        }
        else
        {
            extraSkills.insert(id);
            bool const guardianRanged = expected.ClassId == 18 && (id == 45 || id == 46 || id == 176 || id == 226 || id == 228);
            skillsPolicyMatch = skillsPolicyMatch && guardianRanged;
            skillsCaptureMatch = false;
            output << ",\"prior_guardian_ranged_customization\":" << guardianRanged;
            PlayerInfo const* info = sObjectMgr->GetPlayerInfo(player.getRace(), player.getClass());
            bool const nativeDefault = info && std::any_of(info->skills.begin(), info->skills.end(),
                [id](auto const& row) { return row.SkillId == id; });
            bool const derivedDualWield = id == 118 && player.HasSpell(674);
            bool const derivedDraenei = id == 11760 && (player.HasSpell(814282) || player.HasSpell(1128878));
            output << ",\"native_default_skill\":" << nativeDefault
                   << ",\"derived_dual_wield_skill\":" << derivedDualWield
                   << ",\"derived_draenei_racial_skill\":" << derivedDraenei
                   << ",\"client_hidden_proven\":false";
        }
        output << '}';
    }
    std::set<uint32> missingSkills;
    for (auto const& skill : AscensionLiveBaseline::Skills)
        if (skill.ClassId == expected.ClassId && !skills.count(skill.SkillId))
            missingSkills.insert(skill.SkillId);
    skillsPolicyMatch = skillsPolicyMatch && missingSkills.empty();
    skillsCaptureMatch = skillsCaptureMatch && missingSkills.empty();
    output << "],\"extra_skills\":";
    WriteIds(output, extraSkills);
    output << ",\"missing_skills\":";
    WriteIds(output, missingSkills);
    output << ",\"skills_policy_match\":" << skillsPolicyMatch << ",\"skills_capture_match\":" << skillsCaptureMatch
           << ",\"stats\":[";
    bool statsMatch = true;
    for (uint8 index = 0; index < MAX_STATS; ++index)
    {
        if (index)
            output << ',';
        output << player.GetStat(Stats(index));
        statsMatch = statsMatch && player.GetStat(Stats(index)) == expected.Stats[index];
    }
    output << "],\"create_stats\":[";
    for (uint8 index = 0; index < MAX_STATS; ++index)
    {
        if (index)
            output << ',';
        output << player.GetCreateStat(Stats(index));
    }
    output << "],\"stats_match\":" << statsMatch << ",\"health\":" << player.GetHealth()
           << ",\"level\":" << uint32(player.GetLevel())
           << ",\"max_health\":" << player.GetMaxHealth() << ",\"expected_health\":" << expected.Health
           << ",\"create_health\":" << player.GetCreateHealth() << ",\"create_mana\":" << player.GetCreateMana()
           << ",\"armor\":" << player.GetArmor() << ",\"active_power\":" << uint32(player.getPowerType()) << ",\"powers\":[";
    bool powersCaptureMatch = true;
    bool activePowerMatch = uint32(player.getPowerType()) == expected.ActivePower;
    for (uint8 index = 0; index < expected.Powers.size(); ++index)
    {
        if (index)
            output << ',';
        output << "{\"id\":" << uint32(index) << ",\"expected_current\":" << expected.Powers[index].Current
               << ",\"expected_maximum\":" << expected.Powers[index].Maximum;
        if (index < MAX_POWERS)
        {
            uint32 const divisor = index == POWER_RAGE || index == POWER_RUNIC_POWER ? 10 : 1;
            uint32 const current = player.GetPower(Powers(index));
            uint32 const maximum = player.GetMaxPower(Powers(index));
            bool const match = current == expected.Powers[index].Current * divisor && maximum == expected.Powers[index].Maximum * divisor;
            powersCaptureMatch = powersCaptureMatch && match;
            if (index == expected.ActivePower)
                activePowerMatch = activePowerMatch && match;
            output << ",\"current\":" << current << ",\"maximum\":" << maximum
                   << ",\"display_divisor\":" << divisor << ",\"capture_match\":" << match;
        }
        else
        {
            powersCaptureMatch = false;
            output << ",\"not_a_native_power_channel\":true";
        }
        output << '}';
    }
    output << "],\"powers_capture_match\":" << powersCaptureMatch << ",\"active_power_match\":" << activePowerMatch
           << ",\"expected_active_power\":" << uint32(expected.ActivePower)
           << ",\"attack_power\":" << player.GetTotalAttackPowerValue(BASE_ATTACK)
           << ",\"ranged_attack_power\":" << player.GetTotalAttackPowerValue(RANGED_ATTACK)
           << ",\"mainhand_min\":" << player.GetFloatValue(UNIT_FIELD_MINDAMAGE)
           << ",\"mainhand_max\":" << player.GetFloatValue(UNIT_FIELD_MAXDAMAGE)
           << ",\"offhand_min\":" << player.GetFloatValue(UNIT_FIELD_MINOFFHANDDAMAGE)
           << ",\"offhand_max\":" << player.GetFloatValue(UNIT_FIELD_MAXOFFHANDDAMAGE)
           << ",\"ranged_min\":" << player.GetFloatValue(UNIT_FIELD_MINRANGEDDAMAGE)
           << ",\"ranged_max\":" << player.GetFloatValue(UNIT_FIELD_MAXRANGEDDAMAGE)
           << ",\"mainhand_time_ms\":" << player.GetAttackTime(BASE_ATTACK)
           << ",\"ranged_time_ms\":" << player.GetAttackTime(RANGED_ATTACK)
           << ",\"dodge\":" << player.GetFloatValue(PLAYER_DODGE_PERCENTAGE)
           << ",\"parry\":" << player.GetFloatValue(PLAYER_PARRY_PERCENTAGE)
           << ",\"block\":" << player.GetFloatValue(PLAYER_BLOCK_PERCENTAGE)
           << ",\"block_value\":" << player.GetShieldBlockValue()
           << ",\"melee_crit\":" << player.GetFloatValue(PLAYER_CRIT_PERCENTAGE)
           << ",\"ranged_crit\":" << player.GetFloatValue(PLAYER_RANGED_CRIT_PERCENTAGE)
           << ",\"spell_crit\":[";
    for (uint8 school = 0; school < MAX_SPELL_SCHOOL; ++school)
    {
        if (school)
            output << ',';
        output << player.GetFloatValue(PLAYER_SPELL_CRIT_PERCENTAGE1 + school);
    }
    output << "],\"spell_damage_bonus\":[";
    for (uint8 school = 0; school < MAX_SPELL_SCHOOL; ++school)
    {
        if (school)
            output << ',';
        output << player.GetInt32Value(PLAYER_FIELD_MOD_DAMAGE_DONE_POS + school);
    }
    output << "],\"healing_bonus\":" << player.GetInt32Value(PLAYER_FIELD_MOD_HEALING_DONE_POS)
           << ",\"cast_speed_multiplier\":" << player.GetFloatValue(UNIT_MOD_CAST_SPEED)
           << ",\"in_world\":" << player.IsInWorld();
    return gearMatches && missing.empty() && missingProficiencies.empty() && unexplainedExtraSpells.empty() &&
        skillsPolicyMatch && activePowerMatch && statsMatch && player.GetHealth() == expected.Health &&
        player.GetMaxHealth() == expected.Health && player.GetLevel() == 1 && !player.IsInWorld();
}
}

bool HandleAscensionFreshCharacterCheck(ChatHandler* handler) try
{
    if (!handler || handler->GetSession())
        return false;
    if (sWorldSessionMgr->GetActiveAndQueuedSessionCount() || sWorldSessionMgr->GetPlayerCount() ||
        sWorld->getIntConfig(CONFIG_START_PLAYER_LEVEL) != 1 || sWorld->getBoolConfig(CONFIG_ALWAYS_MAXSKILL) ||
        !ReservedIdsAreAbsent())
    {
        handler->SendSysMessage("Fresh Create check refused: require zero game sessions/players, start level 1, "
            "AlwaysMaxSkillForLevel 0, and positively absent reserved account/GUIDs.");
        return false;
    }

    std::filesystem::path root = std::filesystem::weakly_canonical("C:/Ascension/Runtime/validation");
    std::filesystem::path base = std::filesystem::weakly_canonical(OutputDirectory);
    if (!std::filesystem::is_directory(base) || base.parent_path() != root)
        return false;
    std::filesystem::path directory = base / ("fresh-create-" + std::to_string(GameTime::GetGameTime().count()));
    if (!std::filesystem::create_directory(directory))
    {
        handler->SendSysMessage("Fresh Create check refused: output directory already exists; never overwrite a previous result.");
        return false;
    }
    std::ofstream output(directory / "actual.json", std::ios::out);
    if (!output)
        return false;
    output.imbue(std::locale::classic());
    output << std::boolalpha << std::setprecision(10);
    output << "{\"schema\":\"ascension-fresh-create-v1\",\"expected_source_sha256\":"
           << JsonString(AscensionFreshCharacterExpectations::SourceSHA256)
           << ",\"limits\":[\"Creation only: no login, combat, world registration or persistence tested\","
              "\"Male used because normalized archive does not capture sex\","
              "\"Session destructor executes two zero-row account UPDATEs; verify full before/after DB snapshots\","
              "\"Native item allocation advances the in-memory item GUID generator; non-instance base maps may load\","
              "\"Blocked passive contracts are skipped, never counted as success\","
              "\"Preflight lists conservative candidates, not observed execution; skill rewards above initial rank may be included\","
              "\"Policy match permits documented weapon skill scaling; captured mismatches and inactive/virtual powers remain explicit\"],"
           << "\"unresolved_captured_skills\":" << AscensionLiveBaseline::UnresolvedSkillCount << ",\"classes\":[";
    uint32 created = 0;
    uint32 blocked = 0;
    uint32 mismatched = 0;
    bool separator = false;
    for (auto const& expected : AscensionFreshCharacterExpectations::Cases)
    {
        if (separator)
            output << ',';
        separator = true;
        output << "{\"class_id\":" << uint32(expected.ClassId) << ",\"race_id\":" << uint32(expected.RaceId)
               << ",\"gender\":" << uint32(expected.Gender);
        PlayerInfo const* info = sObjectMgr->GetPlayerInfo(expected.RaceId, expected.ClassId);
        MapEntry const* map = info ? sMapStore.LookupEntry(info->mapId) : nullptr;
        if (!map || map->Instanceable())
        {
            output << ",\"status\":\"blocked\",\"blockers\":[\"missing race/class info or instance start map\"]}";
            ++blocked;
            continue;
        }
        Preflight check = CheckPassiveClosure(expected, *info);
        output << ",\"preflight_learned\":";
        WriteIds(output, check.Learned);
        output << ",\"preflight_executed\":";
        WriteIds(output, check.Executed);
        output << ",\"preflight_deferred_not_executed\":";
        WriteIds(output, check.Deferred);
        output << ",\"blockers\":";
        WriteStrings(output, check.Blockers);
        if (!check.Blockers.empty())
        {
            output << ",\"status\":\"blocked\"}";
            ++blocked;
            continue;
        }

        WorldSession session(ReservedAccount, "AscensionFreshCheck", 0, nullptr,
            SEC_PLAYER, 2, 0, LOCALE_enUS, 0, false, false, 0);
        session.InitRBACDataForTest();
        session.GetRBACData()->GrantPermission(rbac::RBAC_PERM_CANNOT_EARN_ACHIEVEMENTS, 0);
        session.GetRBACData()->RecalculatePermissions();
        if (!session.HasPermission(rbac::RBAC_PERM_CANNOT_EARN_ACHIEVEMENTS) ||
            session.HasPermission(rbac::RBAC_PERM_USE_START_GM_LEVEL) || session.HasAccountFlag(ACCOUNT_FLAG_COLLECTOR))
        {
            output << ",\"status\":\"blocked\",\"reason\":\"in-memory RBAC safety guard failed\"}";
            ++blocked;
            continue;
        }
        std::unique_ptr<Player, ProbePlayerDeleter> player(new Player(&session), ProbePlayerDeleter{&session});
        player->GetMotionMaster()->Initialize();
        ProbeCreateInfo createInfo(expected);
        bool const success = player->Create(FirstReservedGuid + expected.ClassId - 12, &createInfo);
        output << ",\"status\":" << JsonString(success ? "created-not-saved" : "create-failed");
        if (success)
        {
            ++created;
            if (!WritePlayer(output, *player, expected))
                ++mismatched;
        }
        else
            ++blocked;
        output << '}';
    }
    bool const absentAfter = ReservedIdsAreAbsent();
    bool const cleanCount = sWorldSessionMgr->GetPlayerCount() == 0 && sWorldSessionMgr->GetActiveAndQueuedSessionCount() == 0;
    output << "],\"created\":" << created << ",\"blocked_or_failed\":" << blocked << ",\"mismatched\":" << mismatched
           << ",\"reserved_ids_absent_after\":" << absentAfter << ",\"player_counters_clean\":" << cleanCount << "}\n";
    output.flush();
    bool const reportWritten = bool(output);
    handler->PSendSysMessage("Fresh Create probe: {} created, {} blocked/failed, {} mismatched. Report: {}. Full DB preservation check is still required.",
        created, blocked, mismatched, (directory / "actual.json").string());
    return reportWritten && absentAfter && cleanCount && blocked == 0 && mismatched == 0 && created == 21;
}
catch (std::exception const& error)
{
    if (handler)
        handler->PSendSysMessage("Fresh Create probe failed with an exception: {}. Do not treat a partial report as success.", error.what());
    return false;
}
