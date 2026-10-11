/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWildcard.h"
#include "AscensionRemovedSpellActionBars.h"
#include "AscensionCacheRewards.h"
#include "AscensionHeroClass.h"
#include "AscensionFreepick.h"
#include "AscensionCoAConfig.h"
#include "AscensionCompatOpcodes.h"
#include "AscensionSpecialization.h"
#include "AscensionWildcardStarterData.h"
#include "Chat.h"
#include "ClientDBC.h"
#include "Config.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GameEventMgr.h"
#include "GameTime.h"
#include "Group.h"
#include "ObjectMgr.h"
#include "ItemScript.h"
#include "Log.h"
#include "Pet.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "StringFormat.h"
#include "Tokenize.h"
#include "Trainer.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <deque>
#include <limits>
#include <map>
#include <mutex>
#include <set>
#include <span>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <zlib.h>

namespace AscensionWildcard
{
namespace
{
using StarterEntry = AscensionWildcardStarterData::Entry;

constexpr uint16 CMSG_WILDCARD_UNLEARN_ABILITY = 0x061D;
constexpr uint16 SMSG_WILDCARD_UNLEARN_ABILITY_RESULT = 0x061E;
constexpr uint16 SMSG_WILDCARD_ENTRY_LEARNED = 0x0621;
constexpr uint16 CMSG_SET_SKILL_CARD = 0x0622;
constexpr uint16 SMSG_SET_SKILL_CARD_RESULT = 0x0623;
constexpr uint16 SMSG_UPDATE_SKILL_CARDS = 0x0624;
constexpr uint16 SMSG_UPDATE_SKILL_CARD = 0x0625;
constexpr uint16 SMSG_SKILL_CARD_COLLECTION_LIST = 0x0648;
constexpr uint16 SMSG_SKILL_CARD_COLLECTED = 0x0649;
constexpr uint16 SMSG_PENDING_SKILL_CARD_LIST = 0x0653;
constexpr uint16 SMSG_PENDING_SKILL_CARD_ADDED = 0x0654;
constexpr uint16 SMSG_PENDING_SKILL_CARD_REMOVED = 0x0655;
constexpr uint16 CMSG_CLAIM_PENDING_SKILL_CARD = 0x0656;
constexpr uint16 SMSG_CLAIM_PENDING_SKILL_CARD_RESULT = 0x0657;
constexpr uint16 CMSG_PURCHASE_SEALED_CARD = 0x066A;
constexpr uint16 SMSG_PURCHASE_SEALED_CARD_RESULT = 0x066B;
constexpr uint16 CMSG_PURCHASE_SEALED_CARD_BOOSTER_PACK = 0x06DD;
constexpr uint16 SMSG_PURCHASE_SEALED_CARD_BOOSTER_PACK_RESULT = 0x06DE;
constexpr uint16 CMSG_QUERY_CUSTOM_STORE = 0x06B9;
constexpr uint16 SMSG_QUERY_CUSTOM_STORE_RESULT = 0x06BA;
constexpr uint16 CMSG_PURCHASE_CUSTOM_STORE_ITEM = 0x06BB;
constexpr uint16 SMSG_PURCHASE_CUSTOM_STORE_ITEM_RESULT = 0x06BC;
constexpr uint16 SMSG_CUSTOM_STORE_TYPE_LIST = 0x06BD;
constexpr uint16 SMSG_WILDCARD_REROLL_COUNTS = 0x06EE;
constexpr uint16 SMSG_WILDCARD_REROLL_COUNT = 0x06EF;
constexpr uint16 SMSG_WILDCARD_QUICK_ROLLS = 0x06F0;
constexpr uint16 CMSG_REPURCHASE_WILDCARD_ROLLS = 0x06F1;
constexpr uint16 CMSG_REPURCHASE_WILDCARD_ABILITY_ROLLS = 0x06F2;
constexpr uint16 CMSG_REPURCHASE_WILDCARD_TALENT_ROLLS = 0x06F3;
constexpr uint16 SMSG_REPURCHASE_WILDCARD_ROLLS_RESULT = 0x06F4;
constexpr uint16 SMSG_WILDCARD_PRESTIGE_INFO = 0x0720;
constexpr uint16 CMSG_WILDCARD_ROLL_ABILITIES = 0x0643;
constexpr uint16 SMSG_WILDCARD_ROLL_ABILITIES_RESULT = 0x0644;
constexpr uint16 CMSG_WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES = 0x064B;
constexpr uint16 SMSG_WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES_RESULT = 0x064C;
constexpr uint16 CMSG_CHARACTER_ADVANCEMENT_LOCK_ENTRY = 0x0658;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT = 0x0659;
constexpr uint16 CMSG_CHARACTER_ADVANCEMENT_UNLOCK_ENTRY = 0x065A;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT = 0x065B;
constexpr uint16 SMSG_TOKEN_LIST = 0x066F;
constexpr uint16 SMSG_TOKEN_UPDATE = 0x0670;
constexpr uint16 SMSG_FIRE_CLIENT_EVENT = 0x068E;
constexpr uint16 SMSG_SCROLL_OF_FORTUNE_REWARDS_LIST = 0x06AB;
constexpr uint16 CMSG_COLLECT_SCROLL_OF_FORTUNE_REWARDS = 0x06B5;
constexpr uint16 SMSG_COLLECT_SCROLL_OF_FORTUNE_REWARDS_RESULT = 0x06B6;
constexpr uint16 SMSG_COLLECTED_SCROLL_OF_FORTUNE_REWARDS_LIST = 0x06B8;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_ACTIVE_SPEC = 0x0725;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES = 0x0726;
constexpr uint32 DICE_OF_DESTINY_ITEM = 777992;
constexpr std::array<uint32, 5> STARTING_KIT_SPELLS = { 129243, 129246, 979700, 777000, 777003 };
constexpr std::array<std::pair<uint32, uint32>, 5> STARTING_KIT_ITEMS = { {
    { 25, 1 }, { 2092, 1 }, { 2362, 1 }, { 2504, 1 }, { 35, 1 } } };
constexpr uint32 DICE_OF_DESTINY_SPELL = 18283;
constexpr uint32 AUTO_SHOT_ENTRY_SPELL = 965202;
constexpr uint32 AUTO_SHOT_SPELL = 75;
constexpr uint32 TAME_BEAST_ENTRY_SPELL = 965200;
constexpr uint32 CAT_FORM_SPELL = 768;
constexpr uint32 BEAR_FORM_SPELL = 5487;
constexpr uint32 DIRE_BEAR_FORM_SPELL = 9634;
constexpr uint32 FERAL_FORM_MASK = (1u << (FORM_CAT - 1)) | (1u << (FORM_BEAR - 1)) |
    (1u << (FORM_DIREBEAR - 1));

struct EntrySpells
{
    uint32 EntrySpell;
    std::array<uint32, 6> Spells;
};

constexpr std::array<EntrySpells, 31> ENTRY_SPELLS = { {
    { 84864, { 986202, 986203 } },
    { 84865, { 986200, 986201 } },
    { 84866, { 92839, 92840 } },
    { 84867, { 92842, 92843 } },
    { 129243, { 129245, 129246 } },
    { AUTO_SHOT_ENTRY_SPELL, { AUTO_SHOT_SPELL } },
    { TAME_BEAST_ENTRY_SPELL, { 1515, 883, 2641, 6991, 982, 1462 } },
    { 891, { 885, 889, 893, 109980 } },
    { 890, { 884, 887, 892, 109981 } },
    { 91634, { 91631, 91633, 91652, 109982 } },
    { 91606, { 91602, 91605, 91651, 109983 } },
    { BEAR_FORM_SPELL, { 779, 277420 } },
    { CAT_FORM_SPELL, { 1082 } },
    { 49377, { 16979, 49376 } },
    { 33917, { 33876, 33878 } },
    { 850073, { 939300 } },
    { 939300, { 939320, 939340 } },
    { 939301, { 939321, 939341 } },
    { 939302, { 939322, 939342 } },
    { 939303, { 939323, 939343 } },
    { 939304, { 939324, 939344 } },
    { 939305, { 939325, 939345 } },
    { 939306, { 939326, 939346 } },
    { 939307, { 939327, 939347 } },
    { 939308, { 939328, 939348 } },
    { 939309, { 939329, 939349 } },
    { 48263, { 56222 } },
    { 25780, { 277422 } },
    { 71, { 277421 } },
    { 701463, { 277423 } },
    { 275585, { 217364, 275588 } } } };
constexpr uint32 SPELL_RANK_FIRST_SPELL = 1;
constexpr uint32 SPELL_RANK_SPELL = 2;
constexpr uint32 SPELL_RANK_RANK = 3;
constexpr uint32 SPELL_RANK_MAX = 100;
constexpr std::array<std::pair<uint32, uint32>, 7> TRAINER_PRICE_PER_SQUARED_LEVEL = { {
    { 10, 3 }, { 20, 10 }, { 30, 11 }, { 50, 12 }, { 60, 13 }, { 70, 20 }, { 255, 36 } } };
constexpr uint32 SKILL_CARD_ITEM_SPELL = 92657;
constexpr uint32 SPECIALIZATION_CACHE_ITEM = 2977359;
constexpr std::array<std::pair<uint32, uint32>, 5> SPECIALIZATION_CACHE_CONTENTS = { {
    { 106954, 1 }, { 134980, 1 }, { 134981, 1 }, { 134982, 1 }, { 134983, 1 } } };
constexpr char DICE_OF_DESTINY_USED[] = "DICE_OF_DESTINY_USED";
constexpr char SKILL_CARD_COLLECTION_ITEM_USED[] = "SKILL_CARD_COLLECTION_ITEM_USED";
constexpr char WILDCARD_ROLL_READY[] = "WILDCARD_ROLL_READY";
constexpr char SLOTS_SETTING[] = "core.wildcard";
constexpr char SCROLLS_SETTING[] = "core.wildcard.scrolls";
constexpr char UNLEARNED_SETTING[] = "core.wildcard.unlearned";
constexpr char PRIMARY_STAT_SETTING[] = "core.wildcard.path";
constexpr char CLAIMED_REWARDS_SETTING[] = "core.wildcard.rewards";
constexpr std::size_t LEVELING_CLAIMS = 0;
constexpr std::size_t ENDGAME_CLAIMS = 1;
constexpr char STARTER_CARDS_SETTING[] = "core.wildcard.startercards";
constexpr char REROLLS_SETTING[] = "core.wildcard.rerolls";
constexpr char ROLL_CARDS_SETTING[] = "core.wildcard.cards";
constexpr char ACTIVE_SPEC_SETTING[] = "core.wildcard.spec";
constexpr char ACTION_BARS_SETTING[] = "core.wildcard.bars";
constexpr char TRAINED_RANKS_SETTING[] = "core.wildcard.trainedranks";
constexpr char REPURCHASE_SETTING[] = "core.wildcard.repurchase";
constexpr std::array<uint32, 8> PRESTIGE_DELETED_ITEMS = { 1278048, 1278049, 98453, 98454, 98465, 98466, 1478051,
    1478052 };
constexpr std::array<std::uint32_t, 7> SCHOOL_TAGS = { 17, 18, 19, 20, 21, 22, 126 };
constexpr std::array<std::uint32_t, 15> EFFECT_TAGS = { 5, 6, 7, 9, 10, 11, 12, 49, 50, 52, 53, 131, 132, 133, 134 };
constexpr std::uint32_t FIRST_SPEC_TAG = 78;
constexpr std::uint32_t LAST_SPEC_TAG = 107;
constexpr uint32 SPELL_TAG_TYPE_NAME = 44;
constexpr std::string_view SET_SKILL_CARD_OK = "SET_SKILL_CARD_OK";
constexpr std::string_view PURCHASE_SEALED_CARD_OK = "PURCHASE_SEALED_CARD_OK";
constexpr char REVEAL_STOP_CODE[] = "STOP_RAPID_ROLLING_NONE";
constexpr std::string_view UNLEARN_OK = "CA_UNLEARN_OK";
constexpr std::size_t MaxQueuedRequests = 16;

enum AdvancementDwordField : uint32
{
    ADVANCEMENT_ID                = 0,
    ADVANCEMENT_TYPE              = 1,
    ADVANCEMENT_SPELLS            = 5,
    ADVANCEMENT_RANK_COUNT        = 5,
    ADVANCEMENT_WILDCARD_LEVEL    = 28,
    ADVANCEMENT_WILDCARD_AE       = 22,
    ADVANCEMENT_GROUP             = 29,
    ADVANCEMENT_FLAGS             = 120,
    ADVANCEMENT_MODES             = 121,
};

enum EssenceDwordField : uint32
{
    ESSENCE_LEVEL       = 1,
    ESSENCE_CLASS       = 2,
    ESSENCE_DRAFT       = 3,
    ESSENCE_WILDCARD    = 4,
    ESSENCE_SPEC_DRAFT  = 5,
    ESSENCE_UNUSED_MODE = 6,
    ESSENCE_AE          = 7,
    ESSENCE_TE          = 8,
};

enum SkillCardDwordField : uint32
{
    SKILL_CARD_ID       = 1,
    SKILL_CARD_RANK     = 2,
    SKILL_CARD_ITEM     = 3,
    SKILL_CARD_SPELL    = 4,
    SKILL_CARD_TYPE     = 5,
    SKILL_CARD_CLASS    = 7,
    SKILL_CARD_QUALITY  = 8,
    SKILL_CARD_WILDCARD = 9,
    SKILL_CARD_STARTER  = 11,
};

constexpr uint32 DRAFT_ONLY = 0x1000000;

Tables Loaded;
std::mutex SynergyLock;
SynergySettings Synergy;

SynergySettings CurrentSynergy()
{
    std::lock_guard<std::mutex> lock(SynergyLock);
    return Synergy;
}

void LoadSynergySettings()
{
    SynergySettings settings;
    auto const weight = [](char const* name, uint32 fallback)
    {
        return std::min(SYNERGY_WEIGHT_LIMIT, sConfigMgr->GetOption<uint32>(name, fallback));
    };
    settings.ChancePercent = std::min<uint32>(100,
        sConfigMgr->GetOption<uint32>("Wildcard.Synergy.ChancePercent", settings.ChancePercent));
    settings.LinkWeight = weight("Wildcard.Synergy.LinkWeight", settings.LinkWeight);
    settings.RelatedWeight = weight("Wildcard.Synergy.RelatedWeight", settings.RelatedWeight);
    settings.SpecTagWeight = weight("Wildcard.Synergy.SpecTagWeight", settings.SpecTagWeight);
    settings.SchoolTagWeight = weight("Wildcard.Synergy.SchoolTagWeight", settings.SchoolTagWeight);
    settings.TooltipWeight = weight("Wildcard.Synergy.TooltipWeight", settings.TooltipWeight);
    settings.TalentsNeedTarget = sConfigMgr->GetOption<bool>("Wildcard.Synergy.TalentsNeedTarget",
        settings.TalentsNeedTarget);
    settings.LogRolls = sConfigMgr->GetOption<bool>("Wildcard.Synergy.LogRolls", settings.LogRolls);
    LOG_INFO("coa", "Wildcard synergy settings: chance {}%, weights link {}, related {}, specialization {}, school {}, "
        "tooltip {}; talents need a target {}, roll reasons logged {}", settings.ChancePercent, settings.LinkWeight,
        settings.RelatedWeight, settings.SpecTagWeight, settings.SchoolTagWeight, settings.TooltipWeight,
        settings.TalentsNeedTarget, settings.LogRolls);
    std::lock_guard<std::mutex> lock(SynergyLock);
    Synergy = settings;
}

std::uint32_t RankOf(Tables const& tables, std::uint32_t card)
{
    auto const found = tables.Cards.find(card);
    return found == tables.Cards.end() ? 1 : found->second.Rank;
}

std::uint32_t CardEntry(Tables const& tables, std::uint32_t card)
{
    auto const found = tables.Cards.find(card);
    return found == tables.Cards.end() ? 0 : found->second.EntryId;
}

std::uint32_t Pick(std::span<StarterEntry const> pool, std::unordered_set<std::uint32_t> const& taken,
    RandomBelow const& random, SpellFilter const& available)
{
    auto const allowed = [&](StarterEntry const& entry)
    {
        return !taken.count(entry.EntryId) && available(entry.SpellId);
    };

    std::uint32_t total = 0;
    for (StarterEntry const& entry : pool)
        if (allowed(entry))
            total += entry.Weight;
    if (!total)
        return 0;

    std::uint32_t roll = random(total);
    for (StarterEntry const& entry : pool)
    {
        if (!allowed(entry))
            continue;
        if (roll < entry.Weight)
            return entry.EntryId;
        roll -= entry.Weight;
    }
    return 0;
}

struct Spent
{
    std::uint32_t Ability = 0;
    std::uint32_t Talent = 0;
};

Spent SpentEssence(std::vector<Slot> const& slots)
{
    Spent spent;
    for (Slot const& slot : slots)
    {
        if (!slot.EntryId)
            continue;
        if (slot.Talent)
            spent.Talent += TALENT_ROLL_COST;
        else if (auto const cost = Loaded.AbilityCosts.find(slot.EntryId); cost != Loaded.AbilityCosts.end())
            spent.Ability += cost->second;
        else
            spent.Ability += ABILITY_ROLL_COST;
    }
    return spent;
}

void LoadSkillCards(ClientDBC const& cards, Tables& tables)
{
    std::unordered_map<uint32, Entry const*> abilityBySpell;
    std::unordered_map<uint32, uint32> talentBySpell;
    for (Entry const& entry : tables.Entries)
    {
        if (entry.Talent)
        {
            for (uint32 spellId : entry.RankSpells)
                talentBySpell.emplace(spellId, entry.EntryId);
            continue;
        }
        auto const [known, inserted] = abilityBySpell.emplace(entry.RankSpells.front(), &entry);
        if (!inserted && known->second->MinLevel > 1 && entry.MinLevel <= 1)
            known->second = &entry;
    }

    for (uint32 row = 0; row < cards.GetRecordCount(); ++row)
    {
        ClientDBC::Record record = cards.GetRecord(row);
        std::string_view const typeName = record.GetString(SKILL_CARD_TYPE);
        auto const type = std::find_if(SKILL_CARD_TYPE_NAMES.begin(), SKILL_CARD_TYPE_NAMES.end(),
            [typeName](char const* name) { return typeName == name; });
        std::string_view const qualityName = record.GetString(SKILL_CARD_QUALITY);
        auto const quality = std::find_if(SKILL_CARD_QUALITY_NAMES.begin(), SKILL_CARD_QUALITY_NAMES.end(),
            [qualityName](char const* name) { return qualityName == name; });
        if (!record.GetUInt32(SKILL_CARD_WILDCARD) || type == SKILL_CARD_TYPE_NAMES.end() ||
            quality == SKILL_CARD_QUALITY_NAMES.end() || record.GetString(SKILL_CARD_CLASS) != "CLASS_HERO")
            continue;

        uint32 const card = record.GetUInt32(SKILL_CARD_ID);
        uint32 const rank = record.GetUInt32(SKILL_CARD_RANK);
        uint32 const spellId = record.GetUInt32(SKILL_CARD_SPELL);
        SkillCardType const cardType = SkillCardType(type - SKILL_CARD_TYPE_NAMES.begin());
        bool const golden = cardType == SKILL_CARD_DEFAULT_GOLDEN;
        bool const talent = cardType == SKILL_CARD_TALENT_NORMAL || cardType == SKILL_CARD_TALENT_GOLDEN;
        auto const ability = abilityBySpell.find(spellId);
        auto const talentEntry = talentBySpell.find(spellId);
        uint32 const entryId = talent ? (talentEntry == talentBySpell.end() ? 0 : talentEntry->second)
            : (ability == abilityBySpell.end() ? 0 : ability->second->EntryId);
        tables.CardItems[record.GetUInt32(SKILL_CARD_ITEM)] = card;
        tables.Cards[card] = { entryId, cardType, rank,
            SkillCardQuality(quality - SKILL_CARD_QUALITY_NAMES.begin()) };
        if (!record.GetUInt32(SKILL_CARD_STARTER))
            tables.PackCards[cardType].push_back(card);
        else if (rank == 1 && entryId && (golden || cardType == SKILL_CARD_DEFAULT_NORMAL))
            tables.StarterCards[card] = { entryId, golden };
        if (!record.GetUInt32(SKILL_CARD_STARTER) && entryId &&
            (cardType == SKILL_CARD_DEFAULT_NORMAL || cardType == SKILL_CARD_TALENT_NORMAL))
            tables.DropItems.push_back(record.GetUInt32(SKILL_CARD_ITEM));
    }
}

void LoadSealedCardCosts(ClientDBC const& costs, Tables& tables)
{
    for (uint32 row = 0; row < costs.GetRecordCount(); ++row)
    {
        ClientDBC::Record record = costs.GetRecord(row);
        uint32 const purchase = record.GetUInt32(0);
        if (!purchase)
            continue;
        if (tables.SealedCosts.size() < purchase)
            tables.SealedCosts.resize(purchase);
        for (std::size_t type = 0; type < SEALED_CARD_TYPE_COUNT; ++type)
            tables.SealedCosts[purchase - 1][type] = record.GetUInt32(uint32(type + 1));
    }
}

void LoadSpellTags(ClientDBC const& spellTags, Tables& tables)
{
    std::unordered_set<uint32> spells;
    for (Entry const& entry : tables.Entries)
        spells.insert(entry.RankSpells.begin(), entry.RankSpells.end());
    for (uint32 row = 0; row < spellTags.GetRecordCount(); ++row)
    {
        ClientDBC::Record record = spellTags.GetRecord(row);
        if (spells.contains(record.GetUInt32(1)))
            tables.SpellTags[record.GetUInt32(1)].push_back(record.GetUInt32(2));
    }
}

bool IsModifiedBy(SpellInfo const* spell, SpellInfo const* modifier)
{
    return std::any_of(modifier->Effects.begin(), modifier->Effects.end(), [&](SpellEffectInfo const& effect)
        { return effect.SpellClassMask && spell->IsAffected(modifier->SpellFamilyName, effect.SpellClassMask); });
}

void LinkSynergies(Tables& tables)
{
    for (Entry const& talent : tables.Entries)
    {
        SpellInfo const* modifier = talent.Talent ? sSpellMgr->GetSpellInfo(talent.RankSpells.front()) : nullptr;
        if (!modifier || !modifier->SpellFamilyName)
            continue;
        for (Entry const& ability : tables.Entries)
            if (!ability.Talent && std::any_of(ability.RankSpells.begin(), ability.RankSpells.end(),
                    [&](uint32 spellId)
                    {
                        SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
                        return spell && IsModifiedBy(spell, modifier);
                    }))
            {
                tables.Linked[talent.EntryId].insert(ability.EntryId);
                tables.Linked[ability.EntryId].insert(talent.EntryId);
            }
    }

    std::unordered_map<uint32, Entry const*> byId;
    for (Entry const& entry : tables.Entries)
        byId[entry.EntryId] = &entry;
    auto const isWeaponAttack = [](Entry const& entry)
    {
        SpellInfo const* spell = sSpellMgr->GetSpellInfo(entry.RankSpells.front());
        return spell && (spell->DmgClass == SPELL_DAMAGE_CLASS_MELEE || spell->DmgClass == SPELL_DAMAGE_CLASS_RANGED);
    };
    std::unordered_set<std::uint32_t> weaponAttacks;
    for (Entry const& entry : tables.Entries)
    {
        if (isWeaponAttack(entry))
            weaponAttacks.insert(entry.EntryId);
        std::vector<std::uint32_t> synergy;
        auto const add = [&](Entry const& source, bool schoolOnly)
        {
            bool const weapon = isWeaponAttack(source);
            for (uint32 spellId : source.RankSpells)
                if (auto const tags = tables.SpellTags.find(spellId); tags != tables.SpellTags.end())
                    for (std::uint32_t tag : tags->second)
                        if ((IsSpecTag(tag) || IsSchoolTag(tag)) && (!schoolOnly || IsSchoolTag(tag)) &&
                            std::find(synergy.begin(), synergy.end(), SynergyTagOf(tag, weapon)) == synergy.end())
                            synergy.push_back(SynergyTagOf(tag, weapon));
        };
        add(entry, false);
        if (auto const linked = tables.Linked.find(entry.EntryId); entry.Talent && linked != tables.Linked.end())
            for (uint32 abilityId : linked->second)
                add(*byId.at(abilityId), true);
        if (!synergy.empty())
            tables.SynergyTags[entry.EntryId] = std::move(synergy);
    }
    RelateAcrossClasses(tables, weaponAttacks);
}

void LoadRankLadders(ClientDBC const& spellRanks, Tables& tables)
{
    std::unordered_set<uint32> firstRanks;
    for (Entry const& entry : tables.Entries)
        if (!entry.Talent)
            firstRanks.insert(entry.RankSpells.front());
    for (EntrySpells const& entry : ENTRY_SPELLS)
        for (uint32 spellId : entry.Spells)
            if (spellId)
                firstRanks.insert(spellId);

    for (uint32 row = 0; row < spellRanks.GetRecordCount(); ++row)
    {
        ClientDBC::Record record = spellRanks.GetRecord(row);
        uint32 const first = record.GetUInt32(SPELL_RANK_FIRST_SPELL);
        uint32 const rank = record.GetUInt32(SPELL_RANK_RANK);
        if (!firstRanks.contains(first) || !rank || rank > SPELL_RANK_MAX)
            continue;
        std::vector<uint32>& ladder = tables.RankLadders[first];
        ladder.resize(std::max<std::size_t>(ladder.size(), rank));
        ladder[rank - 1] = record.GetUInt32(SPELL_RANK_SPELL);
        if (rank > 1 && ladder[rank - 1])
            tables.RankRoots[ladder[rank - 1]] = first;
    }
}

bool IsGlyph(uint32 spellId)
{
    SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
    return spell && std::string_view(spell->SpellName[LOCALE_enUS]).starts_with("Glyph of ");
}

void LoadTables()
{
    ClientDBC advancement, essence, cards, costs, spellTags;
    if (!advancement.Load(GetClientDBCPath("CharacterAdvancement.dbc"), ADVANCEMENT_MODES + 1) ||
        !essence.Load(GetClientDBCPath("CharacterAdvancementEssence.dbc"), ESSENCE_TE + 1) ||
        !cards.Load(GetClientDBCPath("SkillCard.dbc"), SKILL_CARD_STARTER + 1) ||
        !costs.Load(GetClientDBCPath("SealedCardCosts.dbc"), SEALED_CARD_TYPE_COUNT + 1))
        return;

    Tables tables;
    for (uint32 row = 0; row < advancement.GetRecordCount(); ++row)
    {
        ClientDBC::Record record = advancement.GetRecord(row);
        std::string_view const type = record.GetString(ADVANCEMENT_TYPE);
        bool const talent = type == "Talent";
        if ((!talent && type != "Ability" && type != "TalentAbility") ||
            ((record.GetUInt32(ADVANCEMENT_MODES) >> 8) & 0xFF) != 1 ||
            (record.GetUInt32(ADVANCEMENT_FLAGS) & DRAFT_ONLY) || record.GetUInt32(ADVANCEMENT_ID) > ENTRY_MASK)
            continue;

        Entry entry{ record.GetUInt32(ADVANCEMENT_ID), talent, record.GetUInt32(ADVANCEMENT_WILDCARD_LEVEL),
            record.GetUInt32(ADVANCEMENT_GROUP), {} };
        for (uint32 field = ADVANCEMENT_SPELLS; field < ADVANCEMENT_SPELLS + ADVANCEMENT_RANK_COUNT; ++field)
            if (uint32 const spellId = record.GetUInt32(field))
                entry.RankSpells.push_back(spellId);
        if (entry.RankSpells.empty())
            continue;
        entry.Glyph = IsGlyph(entry.RankSpells.front());
        if (!talent)
        {
            entry.AbilityCost = record.GetUInt32(ADVANCEMENT_WILDCARD_AE);
            tables.AbilityCosts[entry.EntryId] = entry.AbilityCost;
        }
        tables.Entries.push_back(std::move(entry));
    }

    for (uint32 row = 0; row < essence.GetRecordCount(); ++row)
    {
        ClientDBC::Record record = essence.GetRecord(row);
        if (record.GetUInt32(ESSENCE_CLASS) == uint32(CLASS_HERO) && record.GetUInt32(ESSENCE_WILDCARD) &&
            !record.GetUInt32(ESSENCE_DRAFT) && !record.GetUInt32(ESSENCE_SPEC_DRAFT) &&
            !record.GetUInt32(ESSENCE_UNUSED_MODE))
            tables.Budget.push_back({ record.GetUInt32(ESSENCE_LEVEL), record.GetUInt32(ESSENCE_AE),
                record.GetUInt32(ESSENCE_TE) });
    }
    std::sort(tables.Budget.begin(), tables.Budget.end(),
        [](Essence const& left, Essence const& right) { return left.Level < right.Level; });

    LoadSkillCards(cards, tables);
    LoadSealedCardCosts(costs, tables);
    ClientDBC spellRanks;
    if (spellRanks.Load(GetClientDBCPath("SpellRank.dbc"), SPELL_RANK_RANK + 1))
        LoadRankLadders(spellRanks, tables);
    ClientDBC tagTypes;
    if (tagTypes.Load(GetClientDBCPath("SpellTagTypes.dbc"), SPELL_TAG_TYPE_NAME + 1))
        for (uint32 row = 0; row < tagTypes.GetRecordCount(); ++row)
        {
            ClientDBC::Record record = tagTypes.GetRecord(row);
            if (IsSpecTag(record.GetUInt32(0)) || IsSchoolTag(record.GetUInt32(0)))
                tables.TagNames[record.GetUInt32(0)] = std::string(record.GetString(SPELL_TAG_TYPE_NAME));
        }
    if (spellTags.Load(GetClientDBCPath("SpellTags.dbc"), 3))
        LoadSpellTags(spellTags, tables);
    LinkSynergies(tables);
    if (QueryResult result = WorldDatabase.Query("SELECT `Talent`, `Ability` FROM `ascension_wildcard_tooltip_links`"))
        do
        {
            Field* fields = result->Fetch();
            tables.Mentioned[fields[0].Get<uint32>()].insert(fields[1].Get<uint32>());
            tables.Mentioned[fields[1].Get<uint32>()].insert(fields[0].Get<uint32>());
        } while (result->NextRow());
    if (QueryResult result = WorldDatabase.Query(
            "SELECT `CreatureEntry`, `Amount` FROM `ascension_wildcard_boss_marks`"))
        do
        {
            Field* fields = result->Fetch();
            tables.BossMarks[fields[0].Get<uint32>()] = fields[1].Get<uint32>();
        } while (result->NextRow());

    LOG_INFO("coa", "Loaded {} Wildcard entries ({} glyphs, never rolled), {} Hero essence levels and {} skill cards, "
        "{} of them starters and {} dropped by creatures; {} bosses pay Runes of Ascension", tables.Entries.size(),
        std::count_if(tables.Entries.begin(), tables.Entries.end(), [](Entry const& entry) { return entry.Glyph; }),
        tables.Budget.size(), tables.Cards.size(), tables.StarterCards.size(), tables.DropItems.size(),
        tables.BossMarks.size());
    LOG_INFO("coa", "Wildcard synergy: {} entries linked by spell modifiers, {} named in talent tooltips, {} related "
        "across classes, {} with school or specialization tags", tables.Linked.size(), tables.Mentioned.size(),
        tables.Related.size(), tables.SynergyTags.size());
    LOG_INFO("coa", "Wildcard rank ladders: {} abilities train higher ranks", tables.RankLadders.size());
    Loaded = std::move(tables);
}

std::vector<std::uint32_t> RankSpellsOf(std::uint32_t entryId)
{
    auto const itr = std::find_if(Loaded.Entries.begin(), Loaded.Entries.end(),
        [entryId](Entry const& entry) { return entry.EntryId == entryId; });
    return itr == Loaded.Entries.end() ? std::vector<std::uint32_t>() : itr->RankSpells;
}

uint32 FirstSpellOf(uint32 entryId)
{
    std::vector<std::uint32_t> const spells = RankSpellsOf(entryId);
    return spells.empty() ? SpellOf(entryId) : spells.front();
}

bool CanTake(Player const* player, uint32 spellId)
{
    SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
    if (!spell || player->HasSpell(spellId))
        return false;

    if (!spell->Stances || (spell->Stances & ~FERAL_FORM_MASK) ||
        spell->CheckShapeshift(FORM_NONE) == SPELL_CAST_OK)
        return true;

    for (AuraEffect const* effect : player->GetAuraEffectsByType(SPELL_AURA_MOD_IGNORE_SHAPESHIFT))
        if (effect->IsAffectedOnSpell(spell))
            return true;

    return ((spell->Stances & (1u << (FORM_CAT - 1))) && player->HasSpell(CAT_FORM_SPELL)) ||
        ((spell->Stances & (1u << (FORM_BEAR - 1))) && player->HasSpell(BEAR_FORM_SPELL)) ||
        ((spell->Stances & (1u << (FORM_DIREBEAR - 1))) && player->HasSpell(DIRE_BEAR_FORM_SPELL));
}

uint32 PrimaryStatSpell(uint32 entryId)
{
    auto const path = std::find_if(PRIMARY_STAT_PATHS.begin(), PRIMARY_STAT_PATHS.end(),
        [entryId](PrimaryStatPath const& candidate) { return candidate.EntryId == entryId; });
    return path == PRIMARY_STAT_PATHS.end() ? 0 : path->SpellId;
}

uint32 SettingAt(Player const* player, std::string const& source, std::size_t index)
{
    PlayerSettingVector const* stored = player->FindPlayerSettings(source);
    return stored && stored->size() > index ? (*stored)[index].value : 0;
}

uint32 FirstSetting(Player const* player, std::string const& source)
{
    return SettingAt(player, source, 0);
}

void ClearSetting(Player* player, std::string const& source)
{
    if (PlayerSettingVector const* stored = player->FindPlayerSettings(source))
        for (uint32 index = 0; index < stored->size(); ++index)
            player->UpdatePlayerSetting(source, index, 0);
}

void RememberTrainedRank(Player* player, uint32 spellId)
{
    uint32 free = 0;
    if (PlayerSettingVector const* stored = player->FindPlayerSettings(TRAINED_RANKS_SETTING))
    {
        free = uint32(stored->size());
        for (uint32 index = 0; index < stored->size(); ++index)
        {
            if ((*stored)[index].value == spellId)
                return;
            if (!(*stored)[index].value && free == stored->size())
                free = index;
        }
    }
    player->UpdatePlayerSetting(TRAINED_RANKS_SETTING, free, spellId);
}

void RestoreTrainedRanks(Player* player, uint32 firstSpellId)
{
    PlayerSettingVector const* stored = player->FindPlayerSettings(TRAINED_RANKS_SETTING);
    if (!stored)
        return;
    std::vector<uint32> remembered;
    for (uint32 index = 0; index < stored->size(); ++index)
        if (uint32 const spellId = (*stored)[index].value)
            if (auto const root = Loaded.RankRoots.find(spellId); root != Loaded.RankRoots.end() && root->second == firstSpellId)
            {
                remembered.push_back(spellId);
                player->UpdatePlayerSetting(TRAINED_RANKS_SETTING, index, 0);
            }
    for (uint32 rankSpellId : Loaded.RankLadders.at(firstSpellId))
        if (rankSpellId && std::find(remembered.begin(), remembered.end(), rankSpellId) != remembered.end() &&
            !player->HasSpell(rankSpellId) && sSpellMgr->GetSpellInfo(rankSpellId))
            player->learnSpell(rankSpellId);
}

void AppendUInt32(std::vector<std::uint8_t>& out, std::uint32_t value)
{
    for (int shift = 0; shift < 32; shift += 8)
        out.push_back(std::uint8_t(value >> shift));
}

void AppendScrollReward(std::vector<std::uint8_t>& payload, std::uint32_t tier, bool leveling, std::uint32_t level,
    std::span<std::pair<std::uint32_t, std::uint32_t> const> items, std::uint32_t cost)
{
    AppendUInt32(payload, tier);
    payload.push_back(leveling ? 1 : 0);
    AppendUInt32(payload, level);
    for (std::size_t index = 0; index < 4; ++index)
        AppendUInt32(payload, index < items.size() ? items[index].first : 0);
    for (std::size_t index = 0; index < 4; ++index)
        AppendUInt32(payload, index < items.size() ? items[index].second : 0);
    AppendUInt32(payload, cost);
    AppendUInt32(payload, 0);
}

struct Request
{
    uint16 Opcode = 0;
    uint32 EntryId = 0;
    uint32 Count = 0;
    uint8 Flag = 0;
    std::string CardType;
    uint32 CardSlot = 0;
    uint32 Card = 0;
    std::vector<uint32> PendingIds;
    RapidRequest Rapid;
    bool RollAbility = false;
};

std::optional<std::size_t> ReadString(WorldPacket const& packet, std::size_t offset, std::string& text)
{
    if (offset >= packet.size())
        return std::nullopt;
    char const* start = reinterpret_cast<char const*>(packet.contents()) + offset;
    std::size_t const length = strnlen(start, packet.size() - offset);
    if (offset + length >= packet.size())
        return std::nullopt;
    text.assign(start, length);
    return offset + length + 1;
}

void ReadSetSkillCard(WorldPacket const& packet, Request& request)
{
    std::optional<std::size_t> const tail = ReadString(packet, sizeof(uint32), request.CardType);
    if (!tail || *tail + 2 * sizeof(uint32) > packet.size())
        return;
    request.CardSlot = packet.read<uint32>(*tail);
    request.Card = packet.read<uint32>(*tail + sizeof(uint32));
}

void ReadPurchaseSealedCard(WorldPacket const& packet, Request& request)
{
    std::optional<std::size_t> const tail = ReadString(packet, 0, request.CardType);
    request.Count = tail && *tail + sizeof(uint32) <= packet.size() ? packet.read<uint32>(*tail) : 0;
}

void ReadRollAbilities(WorldPacket const& packet, Request& request)
{
    std::size_t offset = 0;
    auto const read = [&packet, &offset](uint32& value)
    {
        if (offset + sizeof(uint32) > packet.size())
            return false;
        value = packet.read<uint32>(offset);
        offset += sizeof(uint32);
        return true;
    };
    uint32 count = 0;
    if (!read(request.Rapid.Count) || !read(count))
        return;
    for (uint32 index = 0, id = 0; index < count && read(id); ++index)
        request.Rapid.DesiredIds.push_back(id);
    if (!read(count))
        return;
    for (uint32 index = 0, tag = 0; index < count && read(tag); ++index)
        request.Rapid.DesiredTags.push_back(tag);
    request.RollAbility = offset < packet.size() && packet.read<uint8>(offset);
}

void ReadClaimPendingCards(WorldPacket const& packet, Request& request)
{
    std::size_t offset = sizeof(uint32);
    std::string name;
    for (uint32 index = 0; index < request.EntryId; ++index)
    {
        std::optional<std::size_t> const tail = ReadString(packet, offset, name);
        if (!tail || *tail + 2 * sizeof(uint32) > packet.size())
            return;
        request.PendingIds.push_back(uint32(std::strtoul(name.c_str(), nullptr, 10)));
        offset = *tail + 2 * sizeof(uint32);
    }
}

std::mutex PendingLock;
std::unordered_map<uint32, std::deque<Request>> PendingRequests;
std::atomic<bool> AnyPending = false;

void Enqueue(uint32 account, Request const& request)
{
    std::lock_guard<std::mutex> lock(PendingLock);
    std::deque<Request>& queue = PendingRequests[account];
    if (queue.size() < MaxQueuedRequests)
        queue.push_back(request);
    AnyPending = true;
}

struct BotRequests final : DataMap::Base
{
    std::deque<Request> Queue;
};

std::string const BotRequestsKey = "AscensionWildcardBotRequests";

void Enqueue(Player* player, Request const& request)
{
    if (!player->GetSession()->IsBot())
    {
        Enqueue(player->GetSession()->GetAccountId(), request);
        return;
    }

    std::deque<Request>& queue = player->CustomData.GetDefault<BotRequests>(BotRequestsKey)->Queue;
    if (queue.size() < MaxQueuedRequests)
        queue.push_back(request);
}

bool QueueRequest(WorldSession* session, WorldPacket const& packet)
{
    if (!session)
        return true;

    Request request{ packet.GetOpcode() };
    if (packet.size() >= sizeof(uint32))
        request.EntryId = packet.read<uint32>(0);
    if (packet.size() >= 2 * sizeof(uint32))
        request.Count = packet.read<uint32>(sizeof(uint32));
    if (packet.size() > 2 * sizeof(uint32))
        request.Flag = packet.read<uint8>(2 * sizeof(uint32));
    if (request.Opcode == CMSG_SET_SKILL_CARD)
        ReadSetSkillCard(packet, request);
    else if (request.Opcode == CMSG_PURCHASE_SEALED_CARD)
        ReadPurchaseSealedCard(packet, request);
    else if (request.Opcode == CMSG_CLAIM_PENDING_SKILL_CARD)
        ReadClaimPendingCards(packet, request);
    else if (request.Opcode == CMSG_WILDCARD_ROLL_ABILITIES)
        ReadRollAbilities(packet, request);
    else if (request.Opcode >= CMSG_REPURCHASE_WILDCARD_ROLLS
        && request.Opcode <= CMSG_REPURCHASE_WILDCARD_TALENT_ROLLS)
    {
        request.Count = request.EntryId;
        request.Flag = packet.size() > sizeof(uint32) ? packet.read<uint8>(sizeof(uint32)) : 0;
    }
    Enqueue(session->GetAccountId(), request);
    return true;
}

std::string SpecSource(Player const* player, char const* source)
{
    return SpecSettingSource(source, ActiveSpec(player));
}

void Save(Player* player, std::vector<Slot> const& slots)
{
    std::string const source = SpecSource(player, SLOTS_SETTING);
    for (std::size_t index = 0; index < slots.size(); ++index)
        player->UpdatePlayerSetting(source, uint32(index), Encode(slots[index]));
}

void SendKnownEntries(Player* player, std::vector<Slot> const& slots)
{
    std::vector<uint8> const body =
        AscensionCoATalentState::KnownEntriesPayload(KnownEntries(slots, PrimaryStat(player)));
    WorldPacket packet(SMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES, body.size());
    packet.append(body.data(), body.size());
    player->SendDirectMessage(&packet);
}

template <std::size_t Count>
void SaveCardSlots(Player* player, std::string const& source, std::array<CardSlot, Count> const& cards)
{
    for (std::size_t position = 0; position < cards.size(); ++position)
        player->UpdatePlayerSetting(source, uint32(position),
            cards[position].Card | (cards[position].Used ? LOCKED : 0));
}

template <std::size_t Count>
std::array<CardSlot, Count> StoredCardSlots(Player const* player, std::string const& source)
{
    std::array<CardSlot, Count> cards{};
    if (PlayerSettingVector const* stored = player->FindPlayerSettings(source))
        for (std::size_t position = 0; position < cards.size() && position < stored->size(); ++position)
            cards[position] = { (*stored)[position].value & ~LOCKED, ((*stored)[position].value & LOCKED) != 0 };
    return cards;
}

void SaveStarterCards(Player* player, StarterCardSlots const& cards)
{
    SaveCardSlots(player, SpecSource(player, STARTER_CARDS_SETTING), cards);
}

void SendSkillCards(Player* player)
{
    std::vector<SpecCardSlots> specs(SPECIALIZATION_COUNT);
    for (uint32 spec = 0; spec < SPECIALIZATION_COUNT; ++spec)
        specs[spec] = { StoredCardSlots<STARTING_ABILITY_COUNT>(player, SpecSettingSource(STARTER_CARDS_SETTING, spec)),
            StoredCardSlots<std::tuple_size_v<RollCardSlots>>(player, SpecSettingSource(ROLL_CARDS_SETTING, spec)) };
    std::vector<uint8> const body = SkillCardSlotsPayload(Loaded, specs);
    WorldPacket packet(SMSG_UPDATE_SKILL_CARDS, body.size());
    packet.append(body.data(), body.size());
    player->SendDirectMessage(&packet);
}

std::mutex CollectionLock;
std::unordered_map<uint32, CardCollection> Collections;

template <typename Row>
void ForEachRow(QueryResult result, Row const& row)
{
    if (result)
        do
            row(result->Fetch());
        while (result->NextRow());
}

CardCollection& CachedCollection(uint32 account)
{
    auto const [itr, inserted] = Collections.try_emplace(account);
    CardCollection& collection = itr->second;
    if (!inserted)
        return collection;

    ForEachRow(CharacterDatabase.Query("SELECT card, progress FROM coa_wildcard_skill_card WHERE account = {}",
        account), [&collection](Field const* fields)
    {
        collection.Collected.insert(fields[0].Get<uint32>());
        if (uint32 const progress = fields[1].Get<uint32>())
            collection.Progress[fields[0].Get<uint32>()] = progress;
    });
    ForEachRow(CharacterDatabase.Query(
        "SELECT id, card FROM coa_wildcard_skill_card_pending WHERE account = {} ORDER BY id", account),
        [&collection](Field const* fields)
    {
        collection.Pending.push_back({ fields[0].Get<uint32>(), fields[1].Get<uint32>() });
    });
    ForEachRow(CharacterDatabase.Query(
        "SELECT bonus_progress FROM coa_wildcard_skill_card_account WHERE account = {}", account),
        [&collection](Field const* fields) { collection.BonusProgress = fields[0].Get<uint32>(); });
    ForEachRow(CharacterDatabase.Query(
        "SELECT type, count FROM coa_wildcard_skill_card_purchase WHERE account = {}", account),
        [&collection](Field const* fields)
    {
        if (uint8 const type = fields[0].Get<uint8>(); type < SEALED_CARD_TYPE_COUNT)
            collection.Purchases[type] = fields[1].Get<uint32>();
    });
    return collection;
}

void SendPayload(Player* player, uint16 opcode, std::vector<uint8> const& body)
{
    WorldPacket packet(opcode, body.size());
    packet.append(body.data(), body.size());
    player->SendDirectMessage(&packet);
}

void SendSkillCardCollection(Player* player)
{
    SendPayload(player, SMSG_SKILL_CARD_COLLECTION_LIST, SkillCardCollectionPayload(Loaded, Collection(player)));
}

void SendPendingCards(Player* player)
{
    SendPayload(player, SMSG_PENDING_SKILL_CARD_LIST, PendingCardsPayload(Loaded, Collection(player).Pending));
}

void StorePending(uint32 account, std::vector<PendingCard> const& added)
{
    std::string rows;
    for (PendingCard const& pending : added)
        rows += Acore::StringFormat("{}({}, {}, {})", rows.empty() ? "" : ", ", account, pending.Id, pending.Card);
    CharacterDatabase.Execute("INSERT INTO coa_wildcard_skill_card_pending (account, id, card) VALUES {}", rows);
}

void AppendCollected(CharacterDatabaseTransaction& transaction, uint32 account, CardCollection const& collection,
    std::vector<uint32> const& cards)
{
    std::string rows;
    for (uint32 card : cards)
    {
        auto const progress = collection.Progress.find(card);
        rows += Acore::StringFormat("{}({}, {}, {})", rows.empty() ? "" : ", ", account, card,
            progress == collection.Progress.end() ? 0 : progress->second);
    }
    transaction->Append("REPLACE INTO coa_wildcard_skill_card (account, card, progress) VALUES {}", rows);
    transaction->Append("REPLACE INTO coa_wildcard_skill_card_account (account, bonus_progress) VALUES ({}, {})",
        account, collection.BonusProgress);
}

void StoreClaim(uint32 account, CardCollection const& collection, CardClaim const& claim)
{
    std::string ids;
    std::vector<uint32> cards;
    for (PendingCard const& claimed : claim.Claimed)
    {
        ids += Acore::StringFormat("{}{}", ids.empty() ? "" : ", ", claimed.Id);
        cards.push_back(claimed.Card);
    }
    CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
    transaction->Append("DELETE FROM coa_wildcard_skill_card_pending WHERE account = {} AND id IN ({})", account, ids);
    AppendCollected(transaction, account, collection, cards);
    CharacterDatabase.CommitTransaction(transaction);
}

void StoreCollected(uint32 account, CardCollection const& collection, uint32 card)
{
    CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
    AppendCollected(transaction, account, collection, { card });
    CharacterDatabase.CommitTransaction(transaction);
}

void SendCardSlot(Player* player, SkillCardType type, std::size_t index, CardSlot const& slot)
{
    WorldPacket update(SMSG_UPDATE_SKILL_CARD, 48);
    update << ActiveSpec(player) << SKILL_CARD_TYPE_NAMES[type] << uint32(index) << slot.Card
           << uint32(slot.Card ? RankOf(Loaded, slot.Card) : 0) << uint8(slot.Used ? 1 : 0);
    player->SendDirectMessage(&update);
}

void SendStarterCard(Player* player, std::size_t position, CardSlot const& slot)
{
    std::size_t const perType = SKILL_CARD_SLOTS[SKILL_CARD_STARTER_NORMAL];
    SendCardSlot(player, position < perType ? SKILL_CARD_STARTER_NORMAL : SKILL_CARD_STARTER_GOLDEN,
        position % perType, slot);
}

void SendRollCard(Player* player, std::size_t position, CardSlot const& slot)
{
    SendCardSlot(player, ROLL_CARD_TYPES[position / ROLL_CARDS_PER_TYPE], position % ROLL_CARDS_PER_TYPE, slot);
}

void ClearStarterSkillCards(Player* player)
{
    SaveStarterCards(player, {});
    for (std::size_t position = 0; position < STARTING_ABILITY_COUNT; ++position)
        SendStarterCard(player, position, {});
}

void RemoveFromActionBars(Player* player, std::unordered_set<uint32> const& spells)
{
    bool removed = false;
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
    {
        ActionButton const* action = player->GetActionButton(button);
        if (!action || action->GetType() != ACTION_BUTTON_SPELL || !spells.contains(action->GetAction()))
            continue;
        player->removeActionButton(button);
        removed = true;
    }
    if (removed)
        player->SendActionButtons(1);
}

void RevealLearnedEntry(Player* player, Slot const& slot, char const* stopCode = REVEAL_STOP_CODE)
{
    WorldPacket learned(SMSG_WILDCARD_ENTRY_LEARNED, 64);
    learned << slot.EntryId << slot.Rank << stopCode;
    player->SendDirectMessage(&learned);

    std::vector<std::uint32_t> const spells = RankSpellsOf(slot.EntryId);
    if (slot.Rank <= spells.size())
        player->learnSpell(spells[slot.Rank - 1]);
}

std::array<uint32, 2> RerollCounts(Player const* player, uint32 spec)
{
    std::array<uint32, 2> counts{};
    if (PlayerSettingVector const* stored = player->FindPlayerSettings(SpecSettingSource(REROLLS_SETTING, spec)))
        for (std::size_t index = 0; index < counts.size() && index < stored->size(); ++index)
            counts[index] = (*stored)[index].value;
    return counts;
}

std::array<uint32, SCROLL_COUNT> RepurchaseCounts(Player const* player, uint32 spec)
{
    std::array<uint32, SCROLL_COUNT> counts{};
    std::string const source = SpecSettingSource(REPURCHASE_SETTING, spec);
    for (std::size_t kind = 0; kind < counts.size(); ++kind)
        counts[kind] = SettingAt(player, source, kind);
    return counts;
}

void SendRerollCounts(Player* player, uint16 opcode)
{
    bool const list = opcode == SMSG_WILDCARD_REROLL_COUNTS;
    uint32 const first = list ? 0 : ActiveSpec(player);
    uint32 const last = list ? uint32(SPECIALIZATION_COUNT) : first + 1;
    WorldPacket packet(opcode, sizeof(uint32) + SPECIALIZATION_COUNT * 5 * sizeof(uint32));
    if (list)
        packet << uint32(SPECIALIZATION_COUNT);
    for (uint32 spec = first; spec < last; ++spec)
    {
        std::array<uint32, 2> const counts = RerollCounts(player, spec);
        std::array<uint32, SCROLL_COUNT> const repurchase = RepurchaseCounts(player, spec);
        packet << counts[0] << counts[1] << repurchase[SCROLL_GENERIC] << repurchase[SCROLL_ABILITIES]
               << repurchase[SCROLL_TALENTS];
    }
    player->SendDirectMessage(&packet);
}

void AddRerolls(Player* player, bool talent, uint32 rerolls)
{
    uint32 const spec = ActiveSpec(player);
    player->UpdatePlayerSetting(SpecSettingSource(REROLLS_SETTING, spec), talent ? 1 : 0,
        RerollCounts(player, spec)[talent ? 1 : 0] + rerolls);
    SendRerollCounts(player, SMSG_WILDCARD_REROLL_COUNT);
}

void SendQuickRolls(Player* player)
{
    WorldPacket packet(SMSG_WILDCARD_QUICK_ROLLS, sizeof(uint32) + QUICK_ROLLS.size() * 9);
    packet << uint32(QUICK_ROLLS.size());
    for (QuickRoll const& quick : QUICK_ROLLS)
        packet << uint8(quick.Ability ? 1 : 0) << quick.Threshold << quick.Max;
    player->SendDirectMessage(&packet);
}

Scrolls ScrollCounts(Player const* player, uint32 spec)
{
    Scrolls scrolls{};
    if (PlayerSettingVector const* stored = player->FindPlayerSettings(SpecSettingSource(SCROLLS_SETTING, spec)))
        for (std::size_t index = 0; index < scrolls.size() && index < stored->size(); ++index)
            scrolls[index] = (*stored)[index].value;
    return scrolls;
}

Scrolls ScrollCounts(Player const* player)
{
    return ScrollCounts(player, ActiveSpec(player));
}

uint32 RedeemAmount(SpellInfo const* redeem)
{
    return uint32(std::max(redeem->Effects[EFFECT_0].MiscValueB, 0));
}

void SetScrolls(Player* player, ScrollToken token, uint32 amount)
{
    player->UpdatePlayerSetting(SpecSettingSource(SCROLLS_SETTING, token.Spec), uint32(token.Kind), amount);
    WorldPacket update(SMSG_TOKEN_UPDATE, 64);
    update << ScrollTokenName(token) << amount << uint32(0);
    player->SendDirectMessage(&update);
}

void SetScrolls(Player* player, Scroll scroll, uint32 amount)
{
    SetScrolls(player, { ActiveSpec(player), scroll }, amount);
}

void SendScrolls(Player* player)
{
    WorldPacket list(SMSG_TOKEN_LIST, SPECIALIZATION_COUNT * SCROLL_COUNT * 48);
    list << uint32(SPECIALIZATION_COUNT * SCROLL_COUNT);
    for (uint32 spec = 0; spec < SPECIALIZATION_COUNT; ++spec)
    {
        Scrolls const scrolls = ScrollCounts(player, spec);
        for (std::size_t kind = 0; kind < SCROLL_COUNT; ++kind)
            list << ScrollTokenName({ spec, Scroll(kind) }) << scrolls[kind] << uint32(0);
    }
    player->SendDirectMessage(&list);
}

std::optional<ScrollToken> RedeemToken(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->Effects[EFFECT_0].Effect != SPELL_EFFECT_DUMMY ||
        !std::string_view(spellInfo->SpellName[0]).starts_with("Redeem TOKEN_TYPE_SCROLL_OF_FORTUNE_"))
        return std::nullopt;
    return ScrollTokenOf(spellInfo->Effects[EFFECT_0].MiscValue);
}

void SendScrollRewards(Player* player)
{
    std::vector<uint8> const payload = ScrollRewardsPayload(sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL));
    uLongf size = compressBound(uLong(payload.size()));
    std::vector<uint8> compressed(size);
    if (compress(compressed.data(), &size, payload.data(), uLong(payload.size())) != Z_OK)
        return;

    WorldPacket packet(SMSG_SCROLL_OF_FORTUNE_REWARDS_LIST, sizeof(uint32) + size);
    packet << uint32(payload.size());
    packet.append(compressed.data(), size);
    player->SendDirectMessage(&packet);
}

void SendClaimedRewards(Player* player)
{
    WorldPacket packet(SMSG_COLLECTED_SCROLL_OF_FORTUNE_REWARDS_LIST, (2 + 3 * SPECIALIZATION_COUNT) * sizeof(uint32));
    packet << uint32(SPECIALIZATION_COUNT);
    for (uint32 spec = 0; spec < SPECIALIZATION_COUNT; ++spec)
    {
        std::string const source = SpecSettingSource(CLAIMED_REWARDS_SETTING, spec);
        packet << spec << SettingAt(player, source, LEVELING_CLAIMS) << SettingAt(player, source, ENDGAME_CLAIMS);
    }
    packet << uint32(0);
    player->SendDirectMessage(&packet);
}

bool SpecializationUnlocked(Player const* player, uint32 spec)
{
    return spec < SPECIALIZATION_COUNT && (spec == 0 || player->HasSpell(SPECIALIZATION_SWAP_SPELLS[spec]));
}

bool GiveItems(Player* player, std::span<std::pair<uint32, uint32> const> items)
{
    std::vector<AscensionCacheRewards::Reward> rewards;
    for (auto const& [itemId, count] : items)
        rewards.push_back({ itemId, 0, 0, 0, count });
    return AscensionCacheRewards::Deliver(player, rewards, nullptr);
}

char const* ClaimScrollRewards(Player* player, Request const& request)
{
    if (!IsWildcardHero(player))
        return "COLLECT_SCROLL_OF_FORTUNE_REWARDS_UNKNOWN";

    uint32 const spec = request.EntryId;
    if (!SpecializationUnlocked(player, spec))
        return "COLLECT_SCROLL_OF_FORTUNE_REWARDS_SPECIALIZATION_OUT_OF_RANGE";
    bool const leveling = request.Flag != 0;
    std::size_t const track = leveling ? LEVELING_CLAIMS : ENDGAME_CLAIMS;
    std::string const source = SpecSettingSource(CLAIMED_REWARDS_SETTING, spec);
    uint32 const claimed = SettingAt(player, source, track);
    char const* result = CheckScrollClaim(spec, request.Count, leveling, claimed, player->GetLevel(),
        sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL), player->GetItemCount(RUNE_OF_ASCENSION_ITEM));
    if (std::string_view(result) != CLAIM_OK)
        return result;

    std::vector<std::pair<uint32, uint32>> items;
    if (leveling)
    {
        items = { { SCROLL_OF_FORTUNE_ITEMS[spec], 0 }, { TALENT_SCROLL_OF_FORTUNE_ITEM + spec, 0 } };
        for (uint32 index = claimed; index < claimed + request.Count; ++index)
        {
            items[0].second += LEVELING_REWARDS[index].Scrolls;
            items[1].second += LEVELING_REWARDS[index].TalentScrolls;
        }
    }
    else
        for (auto const& [itemId, count] : EndgameScrollClaimRewards(spec))
            items.emplace_back(itemId, count * request.Count);
    if (!GiveItems(player, items))
        return "COLLECT_SCROLL_OF_FORTUNE_REWARDS_UNKNOWN";

    uint32 const cost = leveling ? 0 : EndgameScrollClaimsCost(claimed, request.Count);
    if (cost)
        player->DestroyItemCount(RUNE_OF_ASCENSION_ITEM, cost, true);
    player->UpdatePlayerSetting(source, track, claimed + request.Count);
    LOG_INFO("coa", "Wildcard {} scrolls {} to {} of spec {} claimed by {} for {} runes",
        leveling ? "leveling" : "endgame", claimed + 1, claimed + request.Count, spec + 1, player->GetName(), cost);
    return result;
}

char const* RepurchaseScrolls(Player* player, Scroll kind, uint32 count, bool gold)
{
    if (!IsWildcardHero(player))
        return "REPURCHASE_WILDCARD_ROLL_NOT_WILDCARD";

    uint32 const spec = ActiveSpec(player);
    std::array<uint32, SCROLL_COUNT> const available = RepurchaseCounts(player, spec);
    char const* result = CheckRepurchase(kind, count, gold, available[kind], player->GetLevel(),
        sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL), player->GetItemCount(RUNE_OF_ASCENSION_ITEM),
        player->GetMoney());
    if (std::string_view(result) != REPURCHASE_OK)
        return result;

    std::array<std::pair<uint32, uint32>, 1> const items = { { { ScrollItem(spec, kind), count } } };
    if (!GiveItems(player, items))
        return "REPURCHASE_WILDCARD_ROLL_UNKNOWN";
    RepurchasePrice const& price = REPURCHASE_PRICES[kind];
    if (gold)
        player->ModifyMoney(-int32(price.Money * count));
    else
        player->DestroyItemCount(RUNE_OF_ASCENSION_ITEM, price.Runes * count, true);
    player->UpdatePlayerSetting(SpecSettingSource(REPURCHASE_SETTING, spec), uint32(kind), available[kind] - count);
    SendRerollCounts(player, SMSG_WILDCARD_REROLL_COUNT);
    LOG_INFO("coa", "Wildcard scrolls of kind {} repurchased by {}: {} for {}", uint32(kind), player->GetName(), count,
        gold ? "gold" : "runes");
    return result;
}

uint32 RandomBelowBound(uint32 bound)
{
    return urand(0, bound - 1);
}

template <typename Reward>
void RewardKillers(Player* killer, Creature* killed, Reward const& reward)
{
    Group* group = killer->GetGroup();
    if (!group)
    {
        reward(killer);
        return;
    }
    for (GroupReference* member = group->GetFirstMember(); member; member = member->next())
        if (Player* player = member->GetSource(); player && player->IsAtGroupRewardDistance(killed))
            reward(player);
}

void DropCards(Player* killer, Creature* killed)
{
    RewardKillers(killer, killed, [killed](Player* player)
    {
        if (!IsWildcardHero(player) || !player->IsAlive() || !player->isHonorOrXPTarget(killed))
            return;
        if (std::optional<std::uint32_t> const item = RollCardDrop(Loaded, RandomBelowBound))
        {
            std::array<std::pair<uint32, uint32>, 1> const drop = { { { *item, 1 } } };
            GiveItems(player, drop);
        }
    });
}

void GrantBossMarks(Player* killer, Creature* killed)
{
    auto const marks = Loaded.BossMarks.find(killed->GetEntry());
    if (marks == Loaded.BossMarks.end())
        return;
    std::array<std::pair<uint32, uint32>, 1> const runes = { { { RUNE_OF_ASCENSION_ITEM, marks->second } } };
    RewardKillers(killer, killed, [&runes](Player* player)
    {
        if (IsWildcardHero(player))
            GiveItems(player, runes);
    });
}

void QueuePendingCards(Player* player, CardCollection& collection, std::vector<uint32> const& cards)
{
    std::size_t const before = collection.Pending.size();
    AddPending(collection, cards);
    std::vector<PendingCard> const added(collection.Pending.begin() + before, collection.Pending.end());
    StorePending(player->GetSession()->GetAccountId(), added);
    SendPayload(player, SMSG_PENDING_SKILL_CARD_ADDED, PendingCardsPayload(Loaded, added));
}

char const* OpenCardPacks(Player* player, CardPack const& pack, uint32 amount)
{
    if (!amount || amount > MAX_PACKS_PER_PURCHASE)
        return "PURCHASE_SEALED_CARD_BAD_AMOUNT";
    if (!player->HasItemCount(pack.Item, amount))
        return "PURCHASE_SEALED_CARD_NO_TOKEN";

    std::lock_guard<std::mutex> lock(CollectionLock);
    CardCollection& collection = CachedCollection(player->GetSession()->GetAccountId());
    if (!collection.Pending.empty())
        return "PURCHASE_SEALED_CARD_UNCLAIMED_CARDS";

    std::vector<uint32> cards;
    for (uint32 opened = 0; opened < amount; ++opened)
    {
        std::vector<uint32> const drawn = OpenCardPack(Loaded, pack.Cards, RandomBelowBound);
        cards.insert(cards.end(), drawn.begin(), drawn.end());
    }
    if (cards.empty())
        return "PURCHASE_SEALED_CARD_UNKNOWN";

    player->DestroyItemCount(pack.Item, amount, true);
    QueuePendingCards(player, collection, cards);
    LOG_INFO("coa", "Wildcard skill card packs opened by {}: {} x {}", player->GetName(), amount, pack.Item);
    return PURCHASE_SEALED_CARD_OK.data();
}

char const* BuySealedCards(Player* player, std::size_t type, uint32 amount)
{
    uint32 const account = player->GetSession()->GetAccountId();
    std::lock_guard<std::mutex> lock(CollectionLock);
    CardCollection& collection = CachedCollection(account);
    SealedPurchase const purchase = CheckSealedPurchase(Loaded, collection, type, amount,
        player->GetItemCount(SealedCardToken(type)), RandomBelowBound);
    if (std::string_view(purchase.Result) != PURCHASE_SEALED_CARD_OK)
        return purchase.Result;

    player->DestroyItemCount(purchase.Token, purchase.Cost, true);
    uint32 const bought = ++collection.Purchases[type];
    CharacterDatabase.Execute("REPLACE INTO coa_wildcard_skill_card_purchase (account, type, count) "
        "VALUES ({}, {}, {})", account, type, bought);
    QueuePendingCards(player, collection, purchase.Cards);
    LOG_INFO("coa", "Wildcard sealed cards bought by {}: {} for {} x {}", player->GetName(),
        SEALED_CARD_TYPE_NAMES[type], purchase.Cost, purchase.Token);
    return purchase.Result;
}

char const* PurchaseSealedCards(Player* player, Request const& request)
{
    if (!IsWildcardHero(player))
        return "PURCHASE_SEALED_CARD_RANDOM_MODE_NOT_ENABLED";
    auto const pack = std::find_if(CARD_PACKS.begin(), CARD_PACKS.end(),
        [&request](CardPack const& candidate) { return request.CardType == candidate.PurchaseType; });
    if (pack != CARD_PACKS.end())
        return OpenCardPacks(player, *pack, request.Count);
    auto const sealed = std::find_if(SEALED_CARD_TYPE_NAMES.begin(), SEALED_CARD_TYPE_NAMES.end(),
        [&request](char const* name) { return request.CardType == name; });
    return BuySealedCards(player, std::size_t(sealed - SEALED_CARD_TYPE_NAMES.begin()), request.Count);
}

char const* RevealPendingCards(Player* player, std::vector<uint32> const& ids)
{
    uint32 const account = player->GetSession()->GetAccountId();
    std::lock_guard<std::mutex> lock(CollectionLock);
    CardCollection& collection = CachedCollection(account);
    CardClaim const claim = ClaimPendingCards(Loaded, collection, ids, RandomBelowBound);
    if (claim.Claimed.empty())
        return "CLAIM_SKILL_CARD_UNKNOWN";

    StoreClaim(account, collection, claim);
    WorldPacket removed(SMSG_PENDING_SKILL_CARD_REMOVED, 16 * claim.Claimed.size());
    WorldPacket collected(SMSG_SKILL_CARD_COLLECTED, 16 * claim.Claimed.size());
    removed << uint32(claim.Claimed.size());
    collected << uint32(claim.Claimed.size());
    for (PendingCard const& claimed : claim.Claimed)
    {
        removed << PendingCardName(claimed.Id);
        collected << claimed.Card << RankOf(Loaded, claimed.Card) << uint8(0);
    }
    player->SendDirectMessage(&removed);
    player->SendDirectMessage(&collected);
    if (claim.Tickets)
        player->AddItem(DARKMOON_TICKET_ITEM, claim.Tickets);
    if (claim.GoldenTickets)
        player->AddItem(GOLDEN_DARKMOON_TICKET_ITEM, claim.GoldenTickets);
    for (uint32 pack : claim.BonusPacks)
        player->AddItem(pack, 1);
    return "CLAIM_SKILL_CARD_OK";
}

char const* PurchaseBoosterPacks(Player* player, uint32 count)
{
    if (!IsWildcardHero(player))
        return "PURCHASE_SEALED_CARD_BOOSTER_PACK_RANDOM_MODE_NOT_ENABLED";
    if (!count)
        return "PURCHASE_SEALED_CARD_BOOSTER_PACK_TOO_FEW";
    if (count > MAX_BOOSTERS_PER_PURCHASE)
        return "PURCHASE_SEALED_CARD_BOOSTER_PACK_TOO_MANY";
    uint32 const price = count * BOOSTER_PRICE;
    if (!player->HasEnoughMoney(price))
        return "PURCHASE_SEALED_CARD_BOOSTER_PACK_NO_MONEY";
    if (!GiveItems(player, { { { BOOSTER_PACK_ITEMS[0], count }, { BOOSTER_PACK_ITEMS[1], count } } }))
        return "PURCHASE_SEALED_CARD_BOOSTER_PACK_UNKNOWN";

    player->ModifyMoney(-int32(price));
    LOG_INFO("coa", "Wildcard booster packs bought by {}: {}", player->GetName(), count);
    return "PURCHASE_SEALED_CARD_BOOSTER_PACK_OK";
}

char const* RerollStartingAbilities(Player* player, StarterPick const& pick = {}, uint32 draws = 1)
{
    std::vector<Slot> kept = Slots(player);
    bool const fresh = std::none_of(kept.begin(), kept.end(), [](Slot const& slot) { return slot.EntryId; });
    if (!IsWildcardHero(player) || (player->GetLevel() > STARTING_REROLL_MAX_LEVEL && !fresh))
        return "REROLL_UNLOCKED_STARTING_ABILITIES_NOT_ALLOWED";

    kept.resize(std::max(kept.size(), STARTING_ABILITY_COUNT));
    auto const startingEnd = kept.begin() + STARTING_ABILITY_COUNT;
    if (std::all_of(kept.begin(), startingEnd, [](Slot const& slot) { return slot.Locked; }))
        return "REROLL_UNLOCKED_STARTING_ABILITIES_ALL_LOCKED";

    std::unordered_set<uint32> releasedSpells;
    for (auto slot = kept.begin(); slot != startingEnd; ++slot)
    {
        if (slot->Locked)
            continue;
        if (uint32 const spellId = FirstSpellOf(slot->EntryId))
            releasedSpells.insert(spellId);
        *slot = {};
    }

    StarterCardSlots cards = StarterCards(player);
    std::array<std::uint32_t, STARTING_ABILITY_COUNT> const chosen = ChosenStarters(Loaded, cards);
    std::vector<std::vector<Slot>> candidates;
    for (uint32 draw = 0; draw < std::max<uint32>(draws, 1); ++draw)
        candidates.push_back(RollStartingAbilities(kept,
            [](uint32 bound) { return urand(0, bound - 1); },
            [player, &releasedSpells](uint32 spellId)
            {
                return releasedSpells.count(spellId) || !player->HasSpell(spellId);
            }, chosen));
    std::vector<Slot> const& rolled = candidates[pick ? std::min(pick(candidates), candidates.size() - 1) : 0];

    std::unordered_set<uint32> lostSpells = releasedSpells;
    for (Slot const& slot : rolled)
        lostSpells.erase(FirstSpellOf(slot.EntryId));
    for (uint32 spellId : lostSpells)
        player->removeSpell(spellId, SPEC_MASK_ALL, false);
    RemoveFromActionBars(player, lostSpells);
    SendKnownEntries(player, kept);
    for (std::size_t index = 0; index < STARTING_ABILITY_COUNT; ++index)
    {
        if (rolled[index].Locked || !rolled[index].EntryId)
            continue;
        if (chosen[index] && rolled[index].EntryId == chosen[index])
        {
            cards[index].Used = true;
            SendStarterCard(player, index, cards[index]);
        }
        RevealLearnedEntry(player, rolled[index]);
    }
    Save(player, rolled);
    SaveStarterCards(player, cards);
    SendKnownEntries(player, rolled);

    LOG_INFO("coa", "Wildcard starting abilities of {}: {} {} {} {}", player->GetName(), rolled[0].EntryId,
        rolled[1].EntryId, rolled[2].EntryId, rolled[3].EntryId);
    return "OK";
}

std::string EntryName(uint32 entryId)
{
    std::vector<std::uint32_t> const spells = RankSpellsOf(entryId);
    SpellInfo const* spell = spells.empty() ? nullptr : sSpellMgr->GetSpellInfo(spells.front());
    return spell ? std::string(spell->SpellName[LOCALE_enUS]) : std::to_string(entryId);
}

std::string ReasonName(SynergyKind kind, uint32 tag)
{
    switch (kind)
    {
        case SynergyKind::Link:
            return "spell modifier link";
        case SynergyKind::Related:
            return "related across classes";
        case SynergyKind::Tooltip:
            return "named in talent tooltip";
        default:
        {
            bool const weapon = tag > WEAPON_SCHOOL_TAG_OFFSET;
            auto const name = Loaded.TagNames.find(weapon ? tag - WEAPON_SCHOOL_TAG_OFFSET : tag);
            std::string const text = name != Loaded.TagNames.end() ? name->second : Acore::StringFormat("tag {}", tag);
            return weapon ? text + " (weapon)" : text;
        }
    }
}

std::string DescribeRoll(RollTrace const& trace, uint32 entryId, std::vector<Slot> const& slots,
    SynergySettings const& synergy)
{
    std::string text = EntryName(entryId);
    if (trace.Source == RollSource::Card)
        return text + ", skill card";
    text += Acore::StringFormat(", {} roll (synergy chance {}%): score {} of {} ({:.2f}%), {} of {} candidates scored",
        trace.Source == RollSource::Synergy ? "synergy" : "random", synergy.ChancePercent, trace.Score, trace.Total,
        trace.Total ? 100.0 * trace.Score / trace.Total : 0.0, trace.Scored, trace.Candidates);

    std::vector<std::uint32_t> build;
    for (Slot const& slot : slots)
        if (slot.EntryId)
            build.push_back(slot.EntryId);
    std::map<std::pair<SynergyKind, std::uint32_t>, std::pair<std::uint32_t, std::string>> grouped;
    for (SynergyReason const& reason : SynergyReasons(Loaded, entryId, build, synergy))
    {
        auto& [points, with] = grouped[{ reason.Kind, reason.Tag }];
        points += reason.Points;
        with += (with.empty() ? "" : ", ") + EntryName(reason.Known);
    }
    for (auto const& [key, value] : grouped)
        text += Acore::StringFormat("; {} +{} ({})", ReasonName(key.first, key.second), value.first, value.second);
    return text;
}

char const* RapidRollAbilities(Player* player, Request const& request)
{
    if (player->GetLevel() < sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL))
        return "CAN_START_RAPID_ROLLING_NOT_MAX_LEVEL";
    if (request.Rapid.DesiredIds.empty() && request.Rapid.DesiredTags.empty())
        return "CAN_START_RAPID_ROLLING_NO_DESIRED_ENTRIES";

    std::vector<Slot> slots = Slots(player);
    uint32 const level = player->GetLevel();
    bool const talent = !request.RollAbility;
    if (PoolLevel(Loaded.Budget, slots, level, !talent))
        return talent ? "CAN_START_RAPID_ROLLING_UNSPENT_ABILITY_ESSENCE" :
            "CAN_START_RAPID_ROLLING_UNSPENT_TALENT_ESSENCE";
    if (!PoolLevel(Loaded.Budget, slots, level, talent))
        return "CAN_START_RAPID_ROLLING_NO_ROLL";
    std::uint32_t const rerolled = RerollCounts(player, ActiveSpec(player))[talent ? 1 : 0];
    if (!request.Rapid.Count || request.Rapid.Count > RapidRollLimit(rerolled, !talent))
        return "CAN_START_RAPID_ROLLING_TOO_HIGH_COUNT";

    Scrolls scrolls = ScrollCounts(player);
    SynergySettings const synergy = CurrentSynergy();
    RollTrace trace;
    RapidRoll const rapid = AscensionWildcard::RollRapidly(Loaded, slots, level,
        FirstSetting(player, SpecSource(player, UNLEARNED_SETTING)), request.Rapid, scrolls, RandomBelowBound,
        [player](uint32 spellId) { return CanTake(player, spellId); }, synergy, &trace);
    if (!rapid.Rolled)
        return "ROLL_ABILITIES_NO_ROLL";
    std::string const reason =
        synergy.LogRolls ? ": " + DescribeRoll(trace, rapid.Rolled->EntryId, slots, synergy) : "";

    WorldPacket started(SMSG_WILDCARD_ROLL_ABILITIES_RESULT, 48);
    started << "CAN_START_RAPID_ROLLING_OK";
    player->SendDirectMessage(&started);
    Scrolls const before = scrolls;
    for (Scroll scroll : rapid.Spent)
        --scrolls[scroll];
    for (std::size_t index = 0; index < SCROLL_COUNT; ++index)
        if (scrolls[index] != before[index])
            SetScrolls(player, Scroll(index), scrolls[index]);
    if (!rapid.Spent.empty())
        AddRerolls(player, talent, uint32(rapid.Spent.size()));
    if (rapid.LastSkipped)
        player->UpdatePlayerSetting(SpecSource(player, UNLEARNED_SETTING), 0, rapid.LastSkipped);
    Place(slots, *rapid.Rolled);
    RevealLearnedEntry(player, *rapid.Rolled, rapid.StopCode);
    Save(player, slots);
    SendKnownEntries(player, slots);
    LOG_INFO("coa", "Wildcard rapid roll of {}: {} after {} rerolls, {}{}", player->GetName(), rapid.Rolled->EntryId,
        rapid.Spent.size(), rapid.StopCode, reason);
    return nullptr;
}

char const* RollAbilities(Player* player, Request const& request)
{
    if (!IsWildcardHero(player))
        return "ROLL_ABILITIES_NO_ROLL";
    if (request.Rapid.Count)
        return RapidRollAbilities(player, request);

    std::vector<Slot> slots = Slots(player);
    RollCardSlots cards = RollCards(player);
    SynergySettings const synergy = CurrentSynergy();
    RollTrace trace;
    std::optional<Slot> const rolled = RollLevelEntry(Loaded, slots, player->GetLevel(),
        FirstSetting(player, SpecSource(player, UNLEARNED_SETTING)),
        [](uint32 bound) { return urand(0, bound - 1); },
        [player](uint32 spellId) { return CanTake(player, spellId); },
        CardedEntries(Loaded, cards, player->GetLevel()), synergy, &trace);
    if (!rolled)
    {
        SendKnownEntries(player, slots);
        return "ROLL_ABILITIES_NO_ROLL";
    }
    std::string const reason = synergy.LogRolls ? ": " + DescribeRoll(trace, rolled->EntryId, slots, synergy) : "";

    bool const wasStarting = InStartingPhase(slots);
    Place(slots, *rolled);
    if (wasStarting && !InStartingPhase(slots))
        ClearStarterSkillCards(player);
    auto const card = std::find_if(cards.begin(), cards.end(),
        [rolled](CardSlot const& slot) { return !slot.Used && CardEntry(Loaded, slot.Card) == rolled->EntryId; });
    if (card != cards.end())
    {
        card->Used = true;
        SaveCardSlots(player, SpecSource(player, ROLL_CARDS_SETTING), cards);
        SendRollCard(player, std::size_t(card - cards.begin()), *card);
    }
    RevealLearnedEntry(player, *rolled);
    Save(player, slots);
    SendKnownEntries(player, slots);
    LOG_INFO("coa", "Wildcard level {} roll of {}: {} {} rank {}{}", player->GetLevel(), player->GetName(),
        rolled->Talent ? "talent" : "ability", rolled->EntryId, rolled->Rank, reason);
    return "ROLL_ABILITIES_OK";
}

char const* UnlearnWithScroll(Player* player, uint32 entryId)
{
    if (!IsWildcardHero(player))
        return "CA_UNLEARN_NOT_WILDCARD";

    std::vector<Slot> slots = Slots(player);
    char const* result = CheckUnlearn(Loaded.Budget, slots, player->GetLevel(), entryId);
    if (result != UNLEARN_OK)
        return result;

    auto const slot = std::find_if(slots.begin(), slots.end(),
        [entryId](Slot const& candidate) { return candidate.EntryId == entryId; });
    Scrolls const scrolls = ScrollCounts(player);
    std::optional<Scroll> const scroll = ScrollToSpend(scrolls, slot->Talent);
    if (!scroll)
        return "CA_UNLEARN_NO_SCROLL_OF_FORTUNE";

    SetScrolls(player, *scroll, scrolls[*scroll] - 1);
    AddRerolls(player, slot->Talent, 1);
    std::vector<std::uint32_t> const rankSpells = RankSpellsOf(entryId);
    std::unordered_set<uint32> const spells(rankSpells.begin(), rankSpells.end());
    for (uint32 spellId : spells)
        player->removeSpell(spellId, SPEC_MASK_ALL, false);
    RemoveFromActionBars(player, spells);
    *slot = {};
    player->UpdatePlayerSetting(SpecSource(player, UNLEARNED_SETTING), 0, entryId);
    Save(player, slots);
    if (std::size_t(std::count_if(slots.begin(), slots.end(),
            [](Slot const& known) { return known.EntryId && !known.Talent; })) > STARTING_ABILITY_COUNT)
        SendKnownEntries(player, slots);
    return result;
}

char const* SetRollCard(Player* player, Request const& request, std::size_t position)
{
    RollCardSlots cards = RollCards(player);
    char const* result = CheckSetRollCard(Loaded, Slots(player), cards, Collection(player), position, request.Card);
    if (std::string_view(result) != SET_SKILL_CARD_OK)
        return result;

    cards[position] = { request.Card, false };
    SaveCardSlots(player, SpecSource(player, ROLL_CARDS_SETTING), cards);
    SendRollCard(player, position, cards[position]);
    return result;
}

char const* SetSkillCard(Player* player, Request const& request)
{
    auto const type = std::find_if(SKILL_CARD_TYPE_NAMES.begin(), SKILL_CARD_TYPE_NAMES.end(),
        [&request](char const* name) { return request.CardType == name; });
    std::size_t const typeIndex = std::size_t(type - SKILL_CARD_TYPE_NAMES.begin());
    std::optional<std::size_t> const rollCard = RollCardPosition(typeIndex, request.CardSlot);
    std::optional<std::size_t> const position = StarterCardPosition(typeIndex, request.CardSlot);
    if (IsWildcardHero(player) && request.EntryId != ActiveSpec(player))
        return "SET_SKILL_CARD_UNKNOWN";
    if (IsWildcardHero(player) && rollCard)
        return SetRollCard(player, request, *rollCard);
    if (!IsWildcardHero(player) || !position)
        return "SET_SKILL_CARD_UNKNOWN";

    StarterCardSlots cards = StarterCards(player);
    char const* result = CheckSetStarterCard(Loaded, Slots(player), cards, *position, request.Card);
    if (std::string_view(result) != SET_SKILL_CARD_OK)
        return result;

    cards[*position] = { request.Card, false };
    SaveStarterCards(player, cards);
    SendStarterCard(player, *position, cards[*position]);
    return result;
}

char const* SetLocked(Player* player, uint32 entryId, bool locked)
{
    std::vector<Slot> slots = Slots(player);
    auto const slot = std::find_if(slots.begin(), slots.end(),
        [entryId](Slot const& candidate) { return candidate.EntryId == entryId; });
    if (!entryId || !IsWildcardHero(player) || slot == slots.end())
        return locked ? "LOCK_ENTRY_NOT_KNOWN" : "UNLOCK_ENTRY_NOT_KNOWN";
    if (slot->Locked == locked)
        return locked ? "LOCK_ENTRY_ALREADY_LOCKED" : "UNLOCK_ENTRY_NOT_LOCKED";

    slot->Locked = locked;
    Save(player, slots);
    SendKnownEntries(player, slots);
    return "OK";
}

void SignalClientEvent(Player* player, char const* name)
{
    WorldPacket event(SMSG_FIRE_CLIENT_EVENT, 64);
    event << name;
    player->SendDirectMessage(&event);
}

constexpr Milliseconds ROLL_READY_DELAY = 1s;

struct PendingRollReady final : DataMap::Base
{
    Milliseconds Due = Milliseconds::zero();
};

void SendDueRollReady(Player* player)
{
    PendingRollReady* pending = player->CustomData.Get<PendingRollReady>("AscensionWildcardRollReady");
    if (!pending || pending->Due == Milliseconds::zero() || GameTime::GetGameTimeMS() < pending->Due)
        return;
    pending->Due = Milliseconds::zero();
    SignalClientEvent(player, WILDCARD_ROLL_READY);
}

void SendActiveSpec(Player* player)
{
    WorldPacket packet(SMSG_CHARACTER_ADVANCEMENT_ACTIVE_SPEC, 2 * sizeof(uint32));
    packet << ActiveSpec(player) << uint32(SPECIALIZATION_COUNT);
    player->SendDirectMessage(&packet);
}

std::unordered_map<uint32, uint32> RankSpells(std::vector<Slot> const& slots, uint32 primaryStat)
{
    std::unordered_map<uint32, uint32> learned;
    for (Slot const& slot : slots)
    {
        std::vector<std::uint32_t> const spells = RankSpellsOf(slot.EntryId);
        if (slot.EntryId && slot.Rank && slot.Rank <= spells.size())
            learned[slot.EntryId] = spells[slot.Rank - 1];
    }
    if (uint32 const path = PrimaryStatSpell(primaryStat))
        learned[primaryStat] = path;
    return learned;
}

void SaveActionBars(Player* player, uint32 spec)
{
    std::string const source = SpecSettingSource(ACTION_BARS_SETTING, spec);
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
    {
        ActionButton const* action = player->GetActionButton(button);
        player->UpdatePlayerSetting(source, button, action ? action->packedData : 0);
    }
}

void LoadActionBars(Player* player, uint32 spec, std::unordered_set<uint32> const& released)
{
    PlayerSettingVector const* stored = player->FindPlayerSettings(SpecSettingSource(ACTION_BARS_SETTING, spec));
    if (!stored)
    {
        RemoveFromActionBars(player, released);
        return;
    }
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
    {
        uint32 const packed = button < stored->size() ? (*stored)[button].value : 0;
        if (packed)
            player->addActionButton(button, ACTION_BUTTON_ACTION(packed), ACTION_BUTTON_TYPE(packed));
        else if (player->GetActionButton(button))
            player->removeActionButton(button);
    }
    player->SendActionButtons(1);
}

bool SwitchSpecialization(Player* player, uint32 spec)
{
    uint32 const active = ActiveSpec(player);
    if (spec == active || !SpecializationUnlocked(player, spec))
        return false;
    if (std::string const refusal = AscensionSpecializationSwitchRefusal(player, active + 1, spec + 1);
        !refusal.empty())
    {
        ChatHandler(player->GetSession()).SendSysMessage(refusal);
        return false;
    }

    std::unordered_map<uint32, uint32> const before = RankSpells(Slots(player), PrimaryStat(player));
    SaveActionBars(player, active);
    player->UpdatePlayerSetting(ACTIVE_SPEC_SETTING, 0, spec);
    std::vector<Slot> const slots = Slots(player);
    std::unordered_map<uint32, uint32> const after = RankSpells(slots, PrimaryStat(player));

    std::unordered_set<uint32> released;
    for (auto const& [entryId, spellId] : before)
    {
        auto const kept = after.find(entryId);
        if (kept != after.end() && kept->second == spellId)
            continue;
        std::vector<std::uint32_t> const ranks = RankSpellsOf(entryId);
        released.insert(ranks.begin(), ranks.end());
        released.insert(spellId);
    }
    for (uint32 spellId : released)
        player->removeSpell(spellId, SPEC_MASK_ALL, false);
    for (auto const& [entryId, spellId] : after)
        if (!player->HasSpell(spellId))
            player->learnSpell(spellId);

    LoadActionBars(player, spec, released);
    SendActiveSpec(player);
    SendKnownEntries(player, slots);
    SendSkillCards(player);
    SendRerollCounts(player, SMSG_WILDCARD_REROLL_COUNT);
    SignalRollReady(player);
    LOG_INFO("coa", "Wildcard specialization of {}: {} -> {} ({} entries)", player->GetName(), active + 1, spec + 1,
        std::count_if(slots.begin(), slots.end(), [](Slot const& slot) { return slot.EntryId != 0; }));
    return true;
}

void Process(Player* player, Request const& request)
{
    WorldPacket response;
    char const* result;
    switch (request.Opcode)
    {
        case CMSG_WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES:
            result = RerollStartingAbilities(player);
            response.Initialize(SMSG_WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES_RESULT, 64);
            break;
        case CMSG_WILDCARD_ROLL_ABILITIES:
            result = RollAbilities(player, request);
            response.Initialize(SMSG_WILDCARD_ROLL_ABILITIES_RESULT, 64);
            break;
        case CMSG_WILDCARD_UNLEARN_ABILITY:
            result = UnlearnWithScroll(player, request.EntryId);
            response.Initialize(SMSG_WILDCARD_UNLEARN_ABILITY_RESULT, 64);
            break;
        case CMSG_COLLECT_SCROLL_OF_FORTUNE_REWARDS:
            result = ClaimScrollRewards(player, request);
            response.Initialize(SMSG_COLLECT_SCROLL_OF_FORTUNE_REWARDS_RESULT, 64);
            break;
        case CMSG_SET_SKILL_CARD:
            result = SetSkillCard(player, request);
            response.Initialize(SMSG_SET_SKILL_CARD_RESULT, 64);
            break;
        case CMSG_PURCHASE_SEALED_CARD:
            result = PurchaseSealedCards(player, request);
            response.Initialize(SMSG_PURCHASE_SEALED_CARD_RESULT, 64);
            break;
        case CMSG_CLAIM_PENDING_SKILL_CARD:
            result = RevealPendingCards(player, request.PendingIds);
            response.Initialize(SMSG_CLAIM_PENDING_SKILL_CARD_RESULT, 64);
            break;
        case CMSG_PURCHASE_SEALED_CARD_BOOSTER_PACK:
            result = PurchaseBoosterPacks(player, request.EntryId);
            response.Initialize(SMSG_PURCHASE_SEALED_CARD_BOOSTER_PACK_RESULT, 64);
            break;
        case CMSG_REPURCHASE_WILDCARD_ROLLS:
        case CMSG_REPURCHASE_WILDCARD_ABILITY_ROLLS:
        case CMSG_REPURCHASE_WILDCARD_TALENT_ROLLS:
            result = RepurchaseScrolls(player, Scroll(request.Opcode - CMSG_REPURCHASE_WILDCARD_ROLLS), request.Count,
                request.Flag != 0);
            response.Initialize(SMSG_REPURCHASE_WILDCARD_ROLLS_RESULT, 64);
            break;
        default:
        {
            bool const locked = request.Opcode == CMSG_CHARACTER_ADVANCEMENT_LOCK_ENTRY;
            result = SetLocked(player, request.EntryId, locked);
            response.Initialize(locked ? SMSG_CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT
                : SMSG_CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT, 64);
            response << request.EntryId;
            break;
        }
    }
    if (!result)
        return;
    response << result;
    player->SendDirectMessage(&response);
    if (result == PURCHASE_SEALED_CARD_OK)
        SendSkillCardCollection(player);
    LOG_INFO("coa", "Wildcard request 0x{:04X} (entry {}) from {}: {}", request.Opcode, request.EntryId,
        player->GetName(), result);
}

void GiveDiceOfDestiny(Player* player)
{
    if (IsWildcardHero(player) && !player->HasItemCount(DICE_OF_DESTINY_ITEM, 1, true))
        player->AddItem(DICE_OF_DESTINY_ITEM, 1);
}

uint32 TrainerPrice(uint32 spellId, uint32 level)
{
    static std::unordered_map<uint32, uint32> const listed = []
    {
        std::unordered_map<uint32, uint32> prices;
        for (auto const& [trainerId, trainer] : sObjectMgr->GetTrainers())
            if (trainer.GetTrainerType() == Trainer::Type::Class)
                for (Trainer::Spell const& spell : trainer.GetSpells())
                    prices.emplace(spell.SpellId, spell.MoneyCost);
        return prices;
    }();
    if (auto const price = listed.find(spellId); price != listed.end())
        return price->second;
    auto const band = std::find_if(TRAINER_PRICE_PER_SQUARED_LEVEL.begin(), TRAINER_PRICE_PER_SQUARED_LEVEL.end(),
        [level](std::pair<uint32, uint32> const& step) { return level <= step.first; });
    return band->second * level * level;
}

std::vector<Trainer::Spell> RankTrainerRows(Player const* player)
{
    std::vector<std::uint32_t> firstSpells;
    for (auto const& [firstSpellId, ladder] : Loaded.RankLadders)
        if (std::any_of(ladder.begin(), ladder.end(), [player](uint32 spellId) { return spellId && player->HasSpell(spellId); }))
            firstSpells.push_back(firstSpellId);
    std::sort(firstSpells.begin(), firstSpells.end());

    std::vector<Trainer::Spell> rows;
    for (std::uint32_t firstSpellId : firstSpells)
    {
        std::vector<uint32> const& ladder = Loaded.RankLadders.at(firstSpellId);
        uint32 previous = 0;
        for (uint32 spellId : ladder)
        {
            SpellInfo const* info = spellId ? sSpellMgr->GetSpellInfo(spellId) : nullptr;
            if (!info)
                continue;
            if (previous)
            {
                Trainer::Spell row;
                row.SpellId = info->Id;
                row.ReqAbility[0] = previous;
                SpellEntry const* entry = sSpellStore.LookupEntry(info->Id);
                uint32 const baseLevel = entry ? entry->BaseLevel : info->BaseLevel;
                uint32 const spellLevel = entry ? entry->SpellLevel : info->SpellLevel;
                row.ReqLevel = uint8(std::clamp<uint32>(baseLevel ? baseLevel : spellLevel, 1, 255));
                row.MoneyCost = TrainerPrice(info->Id, row.ReqLevel);
                rows.push_back(row);
            }
            previous = info->Id;
        }
    }
    return rows;
}

bool IsRealmHero(Player const* player);

void GrantEntrySpells(Player* player)
{
    if (!IsRealmHero(player) && !IsWildcardHero(player))
        return;
    for (EntrySpells const& entry : ENTRY_SPELLS)
        if (player->HasSpell(entry.EntrySpell))
            for (uint32 spell : entry.Spells)
                if (spell && !player->HasSpell(spell))
                    player->learnSpell(spell);
}

void GiveStartingKit(Player* player)
{
    if (!IsWildcardHero(player) || !player->HasAtLoginFlag(AT_LOGIN_FIRST))
        return;
    for (uint32 spellId : STARTING_KIT_SPELLS)
        player->learnSpell(spellId);
    GiveItems(player, STARTING_KIT_ITEMS);
}

void LearnFirstSpecialization(Player* player)
{
    if (IsWildcardHero(player) && !player->HasSpell(SPECIALIZATION_SWAP_SPELLS[0]))
        player->learnSpell(SPECIALIZATION_SWAP_SPELLS[0]);
}

void GiveSpecializationCache(Player* player)
{
    uint32 const account = player->GetSession()->GetAccountId();
    if (!IsWildcardHero(player) || player->GetSession()->IsBot() ||
        CharacterDatabase.Query("SELECT 1 FROM coa_wildcard_specialization_cache WHERE account = {}", account))
        return;
    std::array<std::pair<uint32, uint32>, 1> const cache = { { { SPECIALIZATION_CACHE_ITEM, 1 } } };
    if (!GiveItems(player, cache))
        return;
    CharacterDatabase.Execute(
        "INSERT IGNORE INTO coa_wildcard_specialization_cache (account, claimed_at) VALUES ({}, {})", account,
        uint32(GameTime::GetGameTime().count()));
    LOG_INFO("coa", "Wildcard Specialization Cache given to {} (account {})", player->GetName(), account);
}

thread_local uint32 CardItemInUse = 0;

void RevealCardItem(Player* player, uint32 item)
{
    uint32 const card = Loaded.CardItems.at(item);
    uint32 const account = player->GetSession()->GetAccountId();
    std::lock_guard<std::mutex> lock(CollectionLock);
    CardCollection& collection = CachedCollection(account);
    std::vector<uint32> const bonusPacks = CollectCard(Loaded, collection, card, RandomBelowBound);
    StoreCollected(account, collection, card);
    WorldPacket collected(SMSG_SKILL_CARD_COLLECTED, 16);
    collected << uint32(1) << card << RankOf(Loaded, card) << uint8(1);
    player->SendDirectMessage(&collected);
    for (uint32 pack : bonusPacks)
        player->AddItem(pack, 1);
    LOG_INFO("coa", "Wildcard skill card item {} revealed card {} for {}", item, card, player->GetName());
}

void SendCardStoreTypes(Player* player)
{
    WorldPacket packet(SMSG_CUSTOM_STORE_TYPE_LIST, 96);
    packet << uint32(3);
    packet << DARKMOON_PRIZES_STORE << uint32(0) << uint32(0) << "Darkmoon Prizes" << "";
    packet << SKILL_CARD_STORE << uint32(0) << uint32(0) << "Skill Cards" << "";
    packet << GOLDEN_SKILL_CARD_STORE << uint32(0) << uint32(0) << "Golden Skill Cards" << "";
    player->SendDirectMessage(&packet);
}

std::vector<StoreCard> StoreOffers(uint32 store)
{
    return store == DARKMOON_PRIZES_STORE ? DarkmoonPrizeStore() : SkillCardStore(Loaded, store);
}

bool QueryCardStore(WorldSession* session, WorldPacket const& packet)
{
    Player* player = session->GetPlayer();
    if (!player || packet.size() < sizeof(uint32))
        return false;
    uint32 const store = packet.read<uint32>(0);
    if (store != DARKMOON_PRIZES_STORE && store != SKILL_CARD_STORE && store != GOLDEN_SKILL_CARD_STORE)
        return false;
    SendPayload(player, SMSG_QUERY_CUSTOM_STORE_RESULT, CustomStorePayload(store, StoreOffers(store)));
    return true;
}

char const* SellStoreCard(Player* player, StoreCard const& offer, uint32 count)
{
    if (!IsWildcardHero(player))
        return "PURCHASE_CUSTOM_STORE_ITEM_CONDITIONS";
    if (!count)
        return "PURCHASE_CUSTOM_STORE_ITEM_COUNT_TOO_LOW";
    if (count > uint32(std::numeric_limits<int32>::max()) / offer.Price)
        return "PURCHASE_CUSTOM_STORE_ITEM_COUNT_ITEMS_OUT_OF_RANGE";
    if (!player->HasItemCount(offer.Token, offer.Price * count))
        return "PURCHASE_CUSTOM_STORE_ITEM_NOT_ENOUGH_ITEMS";

    ItemPosCountVec destination;
    InventoryResult const fits = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, offer.Item, count);
    if (fits != EQUIP_ERR_OK)
    {
        player->SendEquipError(fits, nullptr, nullptr, offer.Item);
        return "PURCHASE_CUSTOM_STORE_ITEM_UNKNOWN";
    }
    player->DestroyItemCount(offer.Token, offer.Price * count, true);
    if (Item* bought = player->StoreNewItem(destination, offer.Item, true))
        player->SendNewItem(bought, count, true, false);
    LOG_INFO("coa", "Wildcard store card {} x {} bought by {} for {} x {}", offer.Item, count, player->GetName(),
        offer.Price * count, offer.Token);
    return "PURCHASE_CUSTOM_STORE_ITEM_OK";
}

bool BuyStoreCard(WorldSession* session, WorldPacket const& packet)
{
    Player* player = session->GetPlayer();
    if (!player || packet.size() < 2 * sizeof(uint32))
        return false;
    uint32 const item = packet.read<uint32>(0);
    std::optional<StoreCard> offer;
    for (uint32 store : { DARKMOON_PRIZES_STORE, SKILL_CARD_STORE, GOLDEN_SKILL_CARD_STORE })
        for (StoreCard const& card : StoreOffers(store))
            if (card.Item == item)
                offer = card;
    if (!offer)
        return false;

    WorldPacket result(SMSG_PURCHASE_CUSTOM_STORE_ITEM_RESULT, 64);
    result << SellStoreCard(player, *offer, packet.read<uint32>(sizeof(uint32)));
    player->SendDirectMessage(&result);
    return true;
}

void SendLoginState(Player* player)
{
    SendScrolls(player);
    SendScrollRewards(player);
    SendClaimedRewards(player);
    SendSkillCardCollection(player);
    SendPendingCards(player);
    SendSkillCards(player);
    SendCardStoreTypes(player);
    SendQuickRolls(player);
    SendRerollCounts(player, SMSG_WILDCARD_REROLL_COUNTS);
}

bool RealmPlaysWildcard = false;

bool IsRealmHero(Player const* player)
{
    return player->getClass() == CLASS_HERO &&
        (RealmPlaysWildcard || AscensionFreepick::RealmIsClassless() || IsWildcardHero(player));
}

struct SentRunes final : DataMap::Base
{
    bool Sent = false;
    uint8 Ready = 0;
    std::array<RuneType, MAX_RUNES> Types{};
};

void SyncRunes(Player* player)
{
    if (!IsRealmHero(player))
        return;
    SentRunes& sent = *player->CustomData.GetDefault<SentRunes>("AscensionWildcardRunes");
    uint8 const ready = player->GetRunesState();
    for (uint8 rune = 0; rune < MAX_RUNES; ++rune)
    {
        RuneType const type = player->GetCurrentRune(rune);
        if (!sent.Sent)
            player->ConvertRune(rune, type);
        bool const retyped = !sent.Sent || sent.Types[rune] != type;
        if ((ready & (1 << rune)) && (retyped || !(sent.Ready & (1 << rune))))
            player->AddRunePower(rune);
        sent.Types[rune] = type;
    }
    sent.Ready = ready;
    sent.Sent = true;
}

static_assert(AscensionHeroClass::WARRIOR == CLASS_WARRIOR && AscensionHeroClass::PALADIN == CLASS_PALADIN &&
    AscensionHeroClass::HUNTER == CLASS_HUNTER && AscensionHeroClass::ROGUE == CLASS_ROGUE &&
    AscensionHeroClass::PRIEST == CLASS_PRIEST && AscensionHeroClass::DEATH_KNIGHT == CLASS_DEATH_KNIGHT &&
    AscensionHeroClass::SHAMAN == CLASS_SHAMAN && AscensionHeroClass::MAGE == CLASS_MAGE &&
    AscensionHeroClass::WARLOCK == CLASS_WARLOCK && AscensionHeroClass::DRUID == CLASS_DRUID);
static_assert(AscensionHeroClass::CONTEXT_ABILITY == CLASS_CONTEXT_ABILITY &&
    AscensionHeroClass::CONTEXT_ABILITY_REACTIVE == CLASS_CONTEXT_ABILITY_REACTIVE &&
    AscensionHeroClass::CONTEXT_PET == CLASS_CONTEXT_PET &&
    AscensionHeroClass::CONTEXT_PET_CHARM == CLASS_CONTEXT_PET_CHARM &&
    AscensionHeroClass::CONTEXT_EQUIP_RELIC == CLASS_CONTEXT_EQUIP_RELIC &&
    AscensionHeroClass::CONTEXT_EQUIP_SHIELDS == CLASS_CONTEXT_EQUIP_SHIELDS);

class AscensionWildcardPlayer final : public PlayerScript
{
public:
    AscensionWildcardPlayer() : PlayerScript("AscensionWildcardPlayer",
        { PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_LOGIN,
            PLAYERHOOK_ON_SEND_INITIAL_PACKETS_BEFORE_ADD_TO_MAP, PLAYERHOOK_ON_CREATURE_KILL,
            PLAYERHOOK_ON_CREATURE_KILLED_BY_PET, PLAYERHOOK_ON_LEARN_SPELL, PLAYERHOOK_ON_FORGOT_SPELL,
            PLAYERHOOK_ON_PLAYER_HAS_ACTIVE_POWER_TYPE, PLAYERHOOK_ON_PLAYER_IS_CLASS,
            PLAYERHOOK_ON_BEFORE_GUARDIAN_INIT_STATS_FOR_LEVEL })
    {
    }

    Optional<bool> OnPlayerIsClass(Player const* player, Classes playerClass, ClassContext context) override
    {
        if (!IsRealmHero(player))
            return std::nullopt;
        if (std::optional<bool> const answer = AscensionHeroClass::Answer(uint8(playerClass), uint8(context),
            [player](uint32 spellId) { return player->HasSpell(spellId); }))
            return *answer;
        return std::nullopt;
    }

    void OnPlayerBeforeGuardianInitStatsForLevel(Player* player, Guardian* guardian, CreatureTemplate const*,
        PetType& petType) override
    {
        if (!guardian->IsPet() || !IsRealmHero(player))
            return;
        petType = guardian->ToPet()->getPetType();
    }

    void OnPlayerCreatureKill(Player* killer, Creature* killed) override
    {
        DropCards(killer, killed);
        GrantBossMarks(killer, killed);
    }

    void OnPlayerCreatureKilledByPet(Player* owner, Creature* killed) override
    {
        DropCards(owner, killed);
        GrantBossMarks(owner, killed);
    }

    bool OnPlayerHasActivePowerType(Player const* player, Powers power) override
    {
        return (power == POWER_RAGE || power == POWER_ENERGY) && (IsRealmHero(player) || IsWildcardHero(player));
    }

    void OnPlayerLearnSpell(Player* player, uint32 spellId) override
    {
        if (std::any_of(ENTRY_SPELLS.begin(), ENTRY_SPELLS.end(),
            [spellId](EntrySpells const& entry) { return entry.EntrySpell == spellId; }))
            GrantEntrySpells(player);
        if ((IsRealmHero(player) || IsWildcardHero(player)) && Loaded.RankLadders.contains(spellId))
            RestoreTrainedRanks(player, spellId);
    }

    void OnPlayerForgotSpell(Player* player, uint32 spellId) override
    {
        if (!IsRealmHero(player) && !IsWildcardHero(player))
            return;
        if (Loaded.RankRoots.contains(spellId))
            RememberTrainedRank(player, spellId);
        for (EntrySpells const& entry : ENTRY_SPELLS)
            if (entry.EntrySpell == spellId)
                for (uint32 spell : entry.Spells)
                    if (spell)
                        player->removeSpell(spell, SPEC_MASK_ALL, false);
        if (auto const ladder = Loaded.RankLadders.find(spellId); ladder != Loaded.RankLadders.end())
            for (uint32 rankSpellId : ladder->second)
                if (rankSpellId && rankSpellId != spellId && player->HasSpell(rankSpellId))
                    player->removeSpell(rankSpellId, SPEC_MASK_ALL, false);
    }

    void OnPlayerLogin(Player* player) override
    {
        GiveStartingKit(player);
        GrantEntrySpells(player);
        GiveDiceOfDestiny(player);
        LearnFirstSpecialization(player);
        GiveSpecializationCache(player);
        if (IsWildcardHero(player))
            SendLoginState(player);
    }

    void OnPlayerSendInitialPacketsBeforeAddToMap(Player* player, WorldPacket&) override
    {
        bool const reconnectedInWorld = player->IsInWorld();
        if (reconnectedInWorld && IsWildcardHero(player))
            SendLoginState(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        uint32 const account = player->GetSession()->GetAccountId();
        {
            std::lock_guard<std::mutex> lock(CollectionLock);
            Collections.erase(account);
        }
        if (player->GetSession()->IsBot())
            return;
        std::lock_guard<std::mutex> lock(PendingLock);
        PendingRequests.erase(account);
        AnyPending = !PendingRequests.empty();
    }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        SyncRunes(player);
        SendDueRollReady(player);
        if (player->GetSession()->IsBot())
        {
            if (BotRequests* own = player->CustomData.Get<BotRequests>(BotRequestsKey))
                for (Request const& request : std::exchange(own->Queue, {}))
                    Process(player, request);
            return;
        }
        if (!AnyPending)
            return;

        std::deque<Request> requests;
        {
            std::lock_guard<std::mutex> lock(PendingLock);
            auto itr = PendingRequests.find(player->GetSession()->GetAccountId());
            if (itr == PendingRequests.end())
                return;
            requests = std::move(itr->second);
            PendingRequests.erase(itr);
            AnyPending = !PendingRequests.empty();
        }

        for (Request const& request : requests)
            Process(player, request);
    }
};

class AscensionWildcardItemSpells final : public AllSpellScript
{
public:
    AscensionWildcardItemSpells() : AllSpellScript("AscensionWildcardItemSpells", { ALLSPELLHOOK_ON_CAST }) { }

    void OnSpellCast(Spell*, Unit* caster, SpellInfo const* spellInfo, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player)
            return;

        if (spellInfo->Id == DICE_OF_DESTINY_SPELL)
            SignalClientEvent(player, DICE_OF_DESTINY_USED);
        if (spellInfo->Id == SKILL_CARD_ITEM_SPELL && CardItemInUse)
            RevealCardItem(player, std::exchange(CardItemInUse, 0));
        auto const pack = std::find_if(CARD_PACKS.begin(), CARD_PACKS.end(),
            [spellInfo](CardPack const& candidate) { return candidate.Spell == spellInfo->Id; });
        if (pack != CARD_PACKS.end())
        {
            SignalClientEvent(player, SKILL_CARD_COLLECTION_ITEM_USED);
            Request open{ CMSG_PURCHASE_SEALED_CARD };
            open.CardType = pack->PurchaseType;
            open.Count = 1;
            Enqueue(player, open);
        }

        if (std::optional<ScrollToken> const token = RedeemToken(spellInfo))
            SetScrolls(player, *token, ScrollCounts(player, token->Spec)[token->Kind] + RedeemAmount(spellInfo));
    }
};

class AscensionWildcardItems final : public AllItemScript
{
public:
    AscensionWildcardItems() : AllItemScript("AscensionWildcardItems") { }

    bool CanItemUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        CardItemInUse = Loaded.CardItems.contains(item->GetEntry()) ? item->GetEntry() : 0;
        SpellInfo const* redeem = sSpellMgr->GetSpellInfo(uint32(item->GetTemplate()->Spells[0].SpellId));
        std::optional<ScrollToken> const token = RedeemToken(redeem);
        uint32 rest = item->GetCount() - 1;
        if (!token || !rest)
            return false;

        uint32 const redeemed = rest;
        player->DestroyItemCount(item, rest, true);
        SetScrolls(player, *token, ScrollCounts(player, token->Spec)[token->Kind] + RedeemAmount(redeem) * redeemed);
        return false;
    }
};

class AscensionWildcardSpecializationCache final : public ItemScript
{
public:
    AscensionWildcardSpecializationCache() : ItemScript("item_wildcard_specialization_cache") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        std::vector<AscensionCacheRewards::Reward> rewards;
        for (auto const& [itemId, count] : SPECIALIZATION_CACHE_CONTENTS)
            rewards.insert(rewards.end(), count, { itemId, 0, 0, 0 });
        AscensionCacheRewards::Deliver(player, rewards, item);
        return true;
    }
};

class spell_wildcard_specialization_swap : public SpellScript
{
    PrepareSpellScript(spell_wildcard_specialization_swap);

    void Switch(SpellEffIndex index)
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || !IsWildcardHero(player))
            return;
        PreventHitDefaultEffect(index);
        SwitchSpecialization(player, uint32(std::max(GetEffectValue() - 1, 0)));
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_wildcard_specialization_swap::Switch, EFFECT_0,
            SPELL_EFFECT_TALENT_SPEC_SELECT);
    }
};

class aura_wildcard_victorious_state : public AuraScript
{
    PrepareAuraScript(aura_wildcard_victorious_state);

    static constexpr std::array<uint32, 3> VICTORY_RUSH_SPELLS = { 34428, 634428, 1134428 };

    bool KnowsVictoryRush(ProcEventInfo&)
    {
        Player const* player = GetTarget()->ToPlayer();
        return player && std::any_of(VICTORY_RUSH_SPELLS.begin(), VICTORY_RUSH_SPELLS.end(),
            [player](uint32 spell) { return player->HasSpell(spell); });
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_victorious_state::KnowsVictoryRush);
    }
};

class AscensionWildcardWorld final : public WorldScript
{
public:
    AscensionWildcardWorld() : WorldScript("AscensionWildcardWorld",
        { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP }) { }

    void OnAfterConfigLoad(bool) override
    {
        LoadSynergySettings();
    }

    void OnStartup() override
    {
        LoadTables();
        RealmPlaysWildcard = PlaysWildcard(sConfigMgr->GetOption<std::string>("CoAChallenges.GameModes.Realm", ""));
        if (RealmPlaysWildcard)
            sGameEventMgr->StartInternalEvent(WILDCARD_SEASON_EVENT);
    }
};
}

std::vector<Slot> RollStartingAbilities(std::vector<Slot> slots, RandomBelow const& random,
    SpellFilter const& available, std::array<std::uint32_t, STARTING_ABILITY_COUNT> const& chosen)
{
    slots.resize(std::max(slots.size(), STARTING_ABILITY_COUNT));
    std::unordered_set<std::uint32_t> taken;
    for (std::size_t index = 0; index < slots.size(); ++index)
        if (slots[index].Locked || index >= STARTING_ABILITY_COUNT)
            taken.insert(slots[index].EntryId);

    std::array<std::uint32_t, STARTING_ABILITY_COUNT> placed{};
    for (std::size_t index = 0; index < STARTING_ABILITY_COUNT; ++index)
        if (!slots[index].Locked && chosen[index] && taken.insert(chosen[index]).second)
            placed[index] = chosen[index];

    for (std::size_t index = 0; index < STARTING_ABILITY_COUNT; ++index)
    {
        if (slots[index].Locked)
            continue;
        if (placed[index])
        {
            slots[index] = { placed[index], false };
            continue;
        }
        std::span<StarterEntry const> const pool = index == 0
            ? std::span<StarterEntry const>(AscensionWildcardStarterData::FirstAbility)
            : std::span<StarterEntry const>(AscensionWildcardStarterData::OtherAbilities);
        slots[index] = { Pick(pool, taken, random, available), false };
        taken.insert(slots[index].EntryId);
    }
    return slots;
}

std::optional<std::uint32_t> PoolLevel(std::vector<Essence> const& budget, std::vector<Slot> const& slots,
    std::uint32_t level, bool talent)
{
    Spent const spent = SpentEssence(slots);
    std::uint32_t const need = talent ? spent.Talent + TALENT_ROLL_COST : spent.Ability + ABILITY_ROLL_COST;
    auto const essence = [talent](Essence const& row) { return talent ? row.Talent : row.Ability; };

    auto const current = std::find_if(budget.rbegin(), budget.rend(),
        [level](Essence const& row) { return row.Level <= level; });
    if (current == budget.rend() || essence(*current) < need)
        return std::nullopt;

    auto earned = std::find_if(budget.begin(), budget.end(),
        [&](Essence const& row) { return essence(row) >= need; });
    while (std::next(earned) != budget.end() && essence(*std::next(earned)) == essence(*earned))
        ++earned;

    std::uint32_t const poolLevel = talent ? std::max(earned->Level, TALENT_POOL_START_LEVEL) : earned->Level;
    return std::min(poolLevel, level);
}

bool IsSpecTag(std::uint32_t tag)
{
    return tag >= FIRST_SPEC_TAG && tag <= LAST_SPEC_TAG;
}

bool IsSchoolTag(std::uint32_t tag)
{
    return std::find(SCHOOL_TAGS.begin(), SCHOOL_TAGS.end(), tag) != SCHOOL_TAGS.end();
}

std::uint32_t SynergyTagOf(std::uint32_t tag, bool weapon)
{
    return weapon && IsSchoolTag(tag) ? tag + WEAPON_SCHOOL_TAG_OFFSET : tag;
}

std::uint32_t SynergyTagWeight(std::uint32_t tag, SynergySettings const& synergy)
{
    if (IsSpecTag(tag))
        return synergy.SpecTagWeight;
    bool const weaponSchool = tag > WEAPON_SCHOOL_TAG_OFFSET && IsSchoolTag(tag - WEAPON_SCHOOL_TAG_OFFSET);
    return IsSchoolTag(tag) || weaponSchool ? synergy.SchoolTagWeight : 0;
}

void RelateAcrossClasses(Tables& tables, std::unordered_set<std::uint32_t> const& weaponAttacks)
{
    using SchoolEffect = std::pair<std::uint32_t, std::uint32_t>;
    std::map<std::uint32_t, std::set<SchoolEffect>> abilities;
    for (Entry const& entry : tables.Entries)
    {
        if (entry.Talent)
            continue;
        std::set<std::uint32_t> schools;
        std::set<std::uint32_t> effects;
        for (std::uint32_t spellId : entry.RankSpells)
            if (auto const tags = tables.SpellTags.find(spellId); tags != tables.SpellTags.end())
                for (std::uint32_t tag : tags->second)
                {
                    if (std::find(SCHOOL_TAGS.begin(), SCHOOL_TAGS.end(), tag) != SCHOOL_TAGS.end())
                        schools.insert(tag);
                    if (std::find(EFFECT_TAGS.begin(), EFFECT_TAGS.end(), tag) != EFFECT_TAGS.end())
                        effects.insert(tag);
                }
        for (std::uint32_t school : schools)
            for (std::uint32_t effect : effects)
                abilities[entry.EntryId].emplace(SynergyTagOf(school, weaponAttacks.contains(entry.EntryId)), effect);
    }

    for (Entry const& talent : tables.Entries)
    {
        auto const linked = tables.Linked.find(talent.EntryId);
        if (!talent.Talent || linked == tables.Linked.end())
            continue;
        std::set<SchoolEffect> signature;
        for (std::uint32_t abilityId : linked->second)
            if (auto const pairs = abilities.find(abilityId); pairs != abilities.end())
                signature.insert(pairs->second.begin(), pairs->second.end());
        for (auto const& [abilityId, pairs] : abilities)
            if (!linked->second.contains(abilityId) && std::any_of(pairs.begin(), pairs.end(),
                    [&signature](SchoolEffect const& pair) { return signature.contains(pair); }))
            {
                tables.Related[talent.EntryId].insert(abilityId);
                tables.Related[abilityId].insert(talent.EntryId);
            }
    }
}

namespace
{
template <typename Visit>
void VisitSynergy(Tables const& tables, std::uint32_t candidate, std::vector<std::uint32_t> const& build,
    SynergySettings const& synergy, Visit const& visit)
{
    auto const links = tables.Linked.find(candidate);
    auto const related = tables.Related.find(candidate);
    auto const mentioned = tables.Mentioned.find(candidate);
    auto const tags = tables.SynergyTags.find(candidate);
    for (std::uint32_t known : build)
    {
        if (links != tables.Linked.end() && links->second.contains(known))
            visit(SynergyReason{ known, SynergyKind::Link, 0, synergy.LinkWeight });
        if (related != tables.Related.end() && related->second.contains(known))
            visit(SynergyReason{ known, SynergyKind::Related, 0, synergy.RelatedWeight });
        if (mentioned != tables.Mentioned.end() && mentioned->second.contains(known))
            visit(SynergyReason{ known, SynergyKind::Tooltip, 0, synergy.TooltipWeight });
        auto const knownTags = tables.SynergyTags.find(known);
        if (tags == tables.SynergyTags.end() || knownTags == tables.SynergyTags.end())
            continue;
        for (std::uint32_t tag : tags->second)
            if (std::find(knownTags->second.begin(), knownTags->second.end(), tag) != knownTags->second.end())
                visit(SynergyReason{ known, SynergyKind::Tag, tag, SynergyTagWeight(tag, synergy) });
    }
}
}

std::uint32_t SynergyScore(Tables const& tables, std::uint32_t candidate, std::vector<std::uint32_t> const& build,
    SynergySettings const& synergy)
{
    std::uint32_t score = 0;
    VisitSynergy(tables, candidate, build, synergy, [&score](SynergyReason const& reason) { score += reason.Points; });
    return score;
}

std::vector<SynergyReason> SynergyReasons(Tables const& tables, std::uint32_t candidate,
    std::vector<std::uint32_t> const& build, SynergySettings const& synergy)
{
    std::vector<SynergyReason> reasons;
    VisitSynergy(tables, candidate, build, synergy, [&reasons](SynergyReason const& reason)
    {
        if (reason.Points)
            reasons.push_back(reason);
    });
    return reasons;
}

std::optional<Slot> RollLevelEntry(Tables const& tables, std::vector<Slot> const& slots, std::uint32_t level,
    std::uint32_t excludedEntry, RandomBelow const& random, SpellFilter const& available,
    std::vector<Slot> const& carded, SynergySettings const& synergy, RollTrace* trace)
{
    std::optional<std::uint32_t> const abilityLevel = PoolLevel(tables.Budget, slots, level, false);
    std::optional<std::uint32_t> const talentLevel = PoolLevel(tables.Budget, slots, level, true);
    if (!abilityLevel && !talentLevel)
        return std::nullopt;

    bool const talent = !abilityLevel || (talentLevel && *talentLevel < *abilityLevel);
    std::uint32_t const poolLevel = talent ? *talentLevel : *abilityLevel;

    std::unordered_set<std::uint32_t> known;
    for (Slot const& slot : slots)
        if (slot.EntryId)
            known.insert(slot.EntryId);
    bool const tameKnown = std::any_of(tables.Entries.begin(), tables.Entries.end(),
        [&known](Entry const& entry) { return entry.Group == TAME_GROUP && known.count(entry.EntryId); });

    auto const eligible = [&](Entry const& entry)
    {
        return entry.Talent == talent && !entry.Glyph && (entry.Talent || entry.AbilityCost) && entry.MinLevel <= poolLevel && !known.count(entry.EntryId) &&
            entry.EntryId != excludedEntry && !(tameKnown && entry.Group == TAME_GROUP) &&
            !entry.RankSpells.empty() && available(entry.RankSpells.front());
    };

    for (Slot const& card : carded)
    {
        auto const entry = std::find_if(tables.Entries.begin(), tables.Entries.end(),
            [&card](Entry const& candidate) { return candidate.EntryId == card.EntryId; });
        if (entry != tables.Entries.end() && eligible(*entry) && card.Rank <= entry->RankSpells.size())
        {
            if (trace)
                *trace = { RollSource::Card };
            return Slot{ card.EntryId, false, card.Rank, talent };
        }
    }

    auto const anyKnown = [&known](std::unordered_set<std::uint32_t> const& targets)
    {
        return std::any_of(targets.begin(), targets.end(), [&known](std::uint32_t id) { return known.count(id); });
    };
    auto const targetKnown = [&](Entry const& entry)
    {
        if (!entry.Talent || !synergy.TalentsNeedTarget)
            return true;
        auto const links = tables.Linked.find(entry.EntryId);
        auto const mentioned = tables.Mentioned.find(entry.EntryId);
        bool const linkedTargets = links != tables.Linked.end() && !links->second.empty();
        bool const namedTargets = mentioned != tables.Mentioned.end() && !mentioned->second.empty();
        return (!linkedTargets && !namedTargets) || (linkedTargets && anyKnown(links->second)) ||
            (namedTargets && anyKnown(mentioned->second));
    };

    std::vector<Entry const*> candidates;
    for (Entry const& entry : tables.Entries)
        if (eligible(entry) && targetKnown(entry))
            candidates.push_back(&entry);
    if (candidates.empty())
        return std::nullopt;

    std::vector<std::uint32_t> const build(known.begin(), known.end());
    std::vector<std::uint32_t> weights;
    std::uint32_t total = 0;
    for (Entry const* candidate : candidates)
        total += weights.emplace_back(SynergyScore(tables, candidate->EntryId, build, synergy));
    std::size_t index = 0;
    bool const synergyRoll = total && random(100) < synergy.ChancePercent;
    if (synergyRoll)
    {
        std::uint32_t roll = random(total);
        while (roll >= weights[index])
            roll -= weights[index++];
    }
    else
        index = random(std::uint32_t(candidates.size()));
    Entry const* picked = candidates[index];
    if (trace)
        *trace = { synergyRoll ? RollSource::Synergy : RollSource::Random, weights[index], total,
            std::uint32_t(candidates.size()),
            std::uint32_t(std::count_if(weights.begin(), weights.end(), [](std::uint32_t weight) { return weight; })) };
    std::uint32_t const rank = talent ? random(std::uint32_t(picked->RankSpells.size())) + 1 : 1;
    return Slot{ picked->EntryId, false, rank, talent };
}

std::uint32_t RapidRollLimit(std::uint32_t rerolled, bool ability)
{
    std::uint32_t limit = 0;
    for (QuickRoll const& quick : QUICK_ROLLS)
        if (quick.Ability == ability && quick.Threshold <= rerolled)
            limit = std::max(limit, quick.Max);
    return limit;
}

RapidRoll RollRapidly(Tables const& tables, std::vector<Slot> const& slots, std::uint32_t level,
    std::uint32_t excludedEntry, RapidRequest const& request, Scrolls scrolls, RandomBelow const& random,
    SpellFilter const& available, SynergySettings const& synergy, RollTrace* trace)
{
    std::unordered_set<std::uint32_t> const desiredIds(request.DesiredIds.begin(), request.DesiredIds.end());
    std::unordered_set<std::uint32_t> const desiredTags(request.DesiredTags.begin(), request.DesiredTags.end());
    auto const desired = [&](Entry const& entry)
    {
        if (desiredIds.contains(entry.EntryId))
            return true;
        for (std::uint32_t spellId : entry.RankSpells)
            if (auto const tags = tables.SpellTags.find(spellId); tags != tables.SpellTags.end())
                for (std::uint32_t tag : tags->second)
                    if (desiredTags.contains(tag))
                        return true;
        return false;
    };

    RapidRoll rapid;
    std::unordered_set<std::uint32_t> skipped;
    SpellFilter const fresh = [&](std::uint32_t spellId) { return !skipped.contains(spellId) && available(spellId); };
    rapid.Rolled = RollLevelEntry(tables, slots, level, excludedEntry, random, fresh, {}, synergy, trace);
    for (std::uint32_t roll = 1; rapid.Rolled; ++roll)
    {
        auto const entry = std::find_if(tables.Entries.begin(), tables.Entries.end(),
            [&rapid](Entry const& candidate) { return candidate.EntryId == rapid.Rolled->EntryId; });
        if (desired(*entry))
        {
            rapid.StopCode = "STOP_RAPID_ROLLING_DESIRED_ENTRY_LEARNED";
            return rapid;
        }
        std::optional<Scroll> const scroll = ScrollToSpend(scrolls, rapid.Rolled->Talent);
        if (roll >= request.Count || !scroll)
            return rapid;
        skipped.insert(entry->RankSpells.front());
        std::optional<Slot> const next = RollLevelEntry(tables, slots, level, excludedEntry, random, fresh, {},
            synergy, trace);
        if (!next)
            return rapid;
        --scrolls[*scroll];
        rapid.Spent.push_back(*scroll);
        rapid.LastSkipped = entry->EntryId;
        rapid.Rolled = next;
    }
    return rapid;
}

void Place(std::vector<Slot>& slots, Slot slot)
{
    auto const hole = std::find_if(slots.begin(), slots.end(),
        [](Slot const& candidate) { return !candidate.EntryId; });
    if (hole == slots.end())
        slots.push_back(slot);
    else
        *hole = slot;
}

char const* CheckUnlearn(std::vector<Essence> const& budget, std::vector<Slot> const& slots, std::uint32_t level,
    std::uint32_t entryId)
{
    auto const slot = std::find_if(slots.begin(), slots.end(),
        [entryId](Slot const& candidate) { return candidate.EntryId == entryId; });
    if (!entryId || slot == slots.end())
        return "CA_UNLEARN_NOT_KNOWN";
    if (slot->Locked)
        return "CA_UNLEARN_LOCKED";

    Spent const spent = SpentEssence(slots);
    bool const beforeFirstTalent = spent.Ability && !spent.Talent;
    if (!beforeFirstTalent && PoolLevel(budget, slots, level, slot->Talent))
        return slot->Talent ? "CA_UNLEARN_WILDCARD_UNSPENT_TE" : "CA_UNLEARN_WILDCARD_UNSPENT_AE";
    return UNLEARN_OK.data();
}

std::optional<Scroll> ScrollToSpend(Scrolls const& scrolls, bool talent)
{
    Scroll const typed = talent ? SCROLL_TALENTS : SCROLL_ABILITIES;
    if (scrolls[typed])
        return typed;
    if (scrolls[SCROLL_GENERIC])
        return SCROLL_GENERIC;
    return std::nullopt;
}

BuildChoice CheckBuildUpload(std::vector<Slot> const& slots, std::uint32_t primaryStat,
    std::vector<AscensionCoATalentState::KnownEntry> const& upload)
{
    std::vector<std::uint32_t> chosen;
    std::size_t matched = 0;
    for (AscensionCoATalentState::KnownEntry const& item : upload)
    {
        if (PrimaryStatSpell(item.EntryId))
        {
            if (item.Rank && item.EntryId != primaryStat)
                chosen.push_back(item.EntryId);
            continue;
        }
        bool const known = std::any_of(slots.begin(), slots.end(), [&item](Slot const& slot)
            { return slot.EntryId && slot.EntryId == item.EntryId && slot.Rank == item.Rank; });
        if (!known)
            return { "CA_UPDATE_ENTRIES_BAD_ENTRY", "CA_LEARN_NOT_WILDCARD", primaryStat };
        ++matched;
    }

    std::size_t const rolled = std::count_if(slots.begin(), slots.end(),
        [](Slot const& slot) { return slot.EntryId != 0; });
    if (matched != rolled || chosen.size() > 1)
        return { "CA_UPDATE_ENTRIES_BAD_ENTRY", "", primaryStat };
    return { "CA_UPDATE_ENTRIES_OK", "", chosen.empty() ? primaryStat : chosen.front() };
}

std::uint32_t EndgameScrollClaimCost(std::uint32_t claim)
{
    return claim <= 21 ? 240 + 10 * claim : 50 * claim - 650;
}

std::uint32_t EndgameScrollClaimsCost(std::uint32_t claimed, std::uint32_t count)
{
    std::uint32_t cost = 0;
    for (std::uint32_t claim = claimed + 1; claim <= claimed + count; ++claim)
        cost += EndgameScrollClaimCost(claim);
    return cost;
}

std::array<std::pair<std::uint32_t, std::uint32_t>, 4> EndgameScrollClaimRewards(std::uint32_t tier)
{
    return { { { SCROLL_OF_FORTUNE_ITEMS[tier], 1 }, { TALENT_SCROLL_OF_FORTUNE_ITEM + tier, 2 },
        { CARD_PACKS[0].Item, 1 }, { CARD_PACKS[2].Item, 1 } } };
}

char const* CheckScrollClaim(std::uint32_t tier, std::uint32_t count, bool leveling, std::uint32_t claimed,
    std::uint32_t level, std::uint32_t maxLevel, std::uint32_t runes)
{
    if (tier >= SPECIALIZATION_COUNT)
        return "COLLECT_SCROLL_OF_FORTUNE_REWARDS_SPECIALIZATION_OUT_OF_RANGE";
    if (count > 100)
        return "COLLECT_SCROLL_OF_FORTUNE_REWARDS_COUNT_TOO_HIGH";
    if (!count || claimed + count > (leveling ? LEVELING_REWARDS.size() : ENDGAME_SCROLL_CLAIMS))
        return "COLLECT_SCROLL_OF_FORTUNE_REWARDS_INVALID_COUNT";
    if (!leveling && EndgameScrollClaimsCost(claimed, count) > runes)
        return "COLLECT_SCROLL_OF_FORTUNE_REWARDS_NOT_ENOUGH_MARKS_OF_ASCENSION";
    if ((leveling ? LEVELING_REWARDS[claimed + count - 1].Level : maxLevel) > level)
        return "COLLECT_SCROLL_OF_FORTUNE_REWARDS_TOO_LOW_LEVEL";
    return CLAIM_OK;
}

bool InStartingPhase(std::vector<Slot> const& slots)
{
    return std::size_t(std::count_if(slots.begin(), slots.end(), [](Slot const& slot) { return slot.EntryId != 0; }))
        <= STARTING_ABILITY_COUNT;
}

std::optional<std::size_t> StarterCardPosition(std::size_t type, std::uint32_t index)
{
    std::size_t const perType = SKILL_CARD_SLOTS[SKILL_CARD_STARTER_NORMAL];
    if (index >= perType || (type != SKILL_CARD_STARTER_NORMAL && type != SKILL_CARD_STARTER_GOLDEN))
        return std::nullopt;
    return type == SKILL_CARD_STARTER_GOLDEN ? perType + index : index;
}

char const* CheckSetStarterCard(Tables const& tables, std::vector<Slot> const& slots,
    StarterCardSlots const& cards, std::size_t position, std::uint32_t card)
{
    if (!card)
        return "SET_SKILL_CARD_OK";
    auto const found = tables.StarterCards.find(card);
    if (found == tables.StarterCards.end())
        return "SET_SKILL_CARD_NOT_COLLECTED";
    if (found->second.Golden != (position >= SKILL_CARD_SLOTS[SKILL_CARD_STARTER_NORMAL]))
        return "SET_SKILL_CARD_UNKNOWN";
    if (!InStartingPhase(slots))
        return "SET_SKILL_CARD_WILDCARD_STARTING_PHASE_COMPLETE";
    for (std::size_t other = 0; other < cards.size(); ++other)
    {
        auto const set = other == position ? tables.StarterCards.end() : tables.StarterCards.find(cards[other].Card);
        if (set != tables.StarterCards.end() && set->second.EntryId == found->second.EntryId)
            return "SET_SKILL_CARD_ENTRY_ALREADY_ACTIVATED";
    }
    return "SET_SKILL_CARD_OK";
}

std::array<std::uint32_t, STARTING_ABILITY_COUNT> ChosenStarters(Tables const& tables,
    StarterCardSlots const& cards)
{
    std::array<std::uint32_t, STARTING_ABILITY_COUNT> chosen{};
    for (std::size_t position = 0; position < cards.size(); ++position)
    {
        auto const card = cards[position].Used ? tables.StarterCards.end()
            : tables.StarterCards.find(cards[position].Card);
        if (card != tables.StarterCards.end())
            chosen[position] = card->second.EntryId;
    }
    return chosen;
}

std::optional<std::size_t> RollCardPosition(std::size_t type, std::uint32_t index)
{
    auto const found = std::find(ROLL_CARD_TYPES.begin(), ROLL_CARD_TYPES.end(), type);
    if (found == ROLL_CARD_TYPES.end() || index >= ROLL_CARDS_PER_TYPE)
        return std::nullopt;
    return std::size_t(found - ROLL_CARD_TYPES.begin()) * ROLL_CARDS_PER_TYPE + index;
}

char const* CheckSetRollCard(Tables const& tables, std::vector<Slot> const& slots, RollCardSlots const& cards,
    CardCollection const& collection, std::size_t position, std::uint32_t card)
{
    std::size_t const learned = std::count_if(slots.begin(), slots.end(),
        [](Slot const& slot) { return slot.EntryId != 0; });
    if (learned > STARTING_ABILITY_COUNT)
        return "SET_SKILL_CARD_WILDCARD_STARTING_PHASE_COMPLETE";
    if (learned < STARTING_ABILITY_COUNT)
        return "SET_SKILL_CARD_UNKNOWN";
    if (!card)
        return "SET_SKILL_CARD_OK";

    auto const found = tables.Cards.find(card);
    if (found == tables.Cards.end() || !found->second.EntryId ||
        found->second.Type != ROLL_CARD_TYPES[position / ROLL_CARDS_PER_TYPE])
        return "SET_SKILL_CARD_UNKNOWN";
    if (!collection.Collected.contains(card))
        return "SET_SKILL_CARD_NOT_COLLECTED";

    std::uint32_t const entryId = found->second.EntryId;
    bool activated = std::any_of(slots.begin(), slots.end(),
        [entryId](Slot const& slot) { return slot.EntryId == entryId; });
    for (std::size_t other = 0; other < cards.size(); ++other)
        activated = activated || (other != position && CardEntry(tables, cards[other].Card) == entryId);
    return activated ? "SET_SKILL_CARD_ENTRY_ALREADY_ACTIVATED" : "SET_SKILL_CARD_OK";
}

std::vector<Slot> CardedEntries(Tables const& tables, RollCardSlots const& cards, std::uint32_t level)
{
    std::vector<Slot> carded;
    for (std::size_t position = 0; position < cards.size(); ++position)
    {
        SkillCardType const type = ROLL_CARD_TYPES[position / ROLL_CARDS_PER_TYPE];
        bool const talent = type == SKILL_CARD_TALENT_NORMAL || type == SKILL_CARD_TALENT_GOLDEN;
        std::uint32_t const entryId = CardEntry(tables, cards[position].Card);
        if (cards[position].Used || !entryId ||
            (!talent && level < ABILITY_CARD_SLOT_LEVELS[position % ROLL_CARDS_PER_TYPE]))
            continue;
        carded.push_back({ entryId, false, RankOf(tables, cards[position].Card), talent });
    }
    return carded;
}

std::vector<std::uint8_t> SkillCardSlotsPayload(Tables const& tables, std::vector<SpecCardSlots> const& specs)
{
    std::vector<std::uint8_t> payload;
    AppendUInt32(payload, std::uint32_t(specs.size()));
    for (SpecCardSlots const& spec : specs)
        for (std::size_t type = 0; type < SKILL_CARD_TYPE_COUNT; ++type)
        {
            AppendUInt32(payload, SKILL_CARD_SLOTS[type]);
            for (std::uint32_t index = 0; index < SKILL_CARD_SLOTS[type]; ++index)
            {
                std::optional<std::size_t> const starter = StarterCardPosition(type, index);
                std::optional<std::size_t> const rollCard = RollCardPosition(type, index);
                CardSlot const slot = starter ? spec.Starters[*starter] : rollCard ? spec.Cards[*rollCard] : CardSlot{};
                AppendUInt32(payload, slot.Card);
                AppendUInt32(payload, slot.Card ? RankOf(tables, slot.Card) : 0);
                payload.push_back(slot.Used ? 1 : 0);
            }
        }
    return payload;
}

std::vector<std::uint8_t> SkillCardCollectionPayload(Tables const& tables, CardCollection const& collection)
{
    std::vector<std::uint32_t> collected(collection.Collected.begin(), collection.Collected.end());
    for (auto const& [card, starter] : tables.StarterCards)
        collected.push_back(card);
    std::sort(collected.begin(), collected.end());
    collected.erase(std::unique(collected.begin(), collected.end()), collected.end());

    std::vector<std::uint8_t> payload;
    AppendUInt32(payload, collection.BonusProgress);
    for (std::uint32_t bought : collection.Purchases)
        AppendUInt32(payload, bought);
    AppendUInt32(payload, std::uint32_t(collected.size()));
    for (std::uint32_t card : collected)
    {
        auto const progress = collection.Progress.find(card);
        AppendUInt32(payload, card);
        AppendUInt32(payload, progress == collection.Progress.end() ? 0 : progress->second);
        AppendUInt32(payload, RankOf(tables, card));
    }
    return payload;
}

std::optional<std::uint32_t> RollCardDrop(Tables const& tables, RandomBelow const& random)
{
    if (tables.DropItems.empty() || random(1000) >= CARD_DROP_CHANCE_PER_MILLE)
        return std::nullopt;
    return tables.DropItems[random(std::uint32_t(tables.DropItems.size()))];
}

std::vector<std::uint32_t> DrawCards(std::vector<std::uint32_t> pool, std::uint32_t count, RandomBelow const& random)
{
    std::vector<std::uint32_t> drawn;
    while (drawn.size() < count && !pool.empty())
    {
        std::size_t const pick = random(std::uint32_t(pool.size()));
        drawn.push_back(pool[pick]);
        pool[pick] = pool.back();
        pool.pop_back();
    }
    return drawn;
}

std::vector<std::uint32_t> OpenCardPack(Tables const& tables, SkillCardType cards, RandomBelow const& random)
{
    return DrawCards(tables.PackCards[cards], CARDS_PER_PACK, random);
}

void AddPending(CardCollection& collection, std::vector<std::uint32_t> const& cards)
{
    std::uint32_t next = 1;
    for (PendingCard const& pending : collection.Pending)
        next = std::max(next, pending.Id + 1);
    for (std::uint32_t card : cards)
        collection.Pending.push_back({ next++, card });
}

std::uint32_t SealedCardToken(std::size_t type)
{
    return type < 2 * SEALED_CARD_TYPES_PER_CATEGORY ? DARKMOON_TICKET_ITEM : GOLDEN_DARKMOON_TICKET_ITEM;
}

SealedPurchase CheckSealedPurchase(Tables const& tables, CardCollection const& collection, std::size_t type,
    std::uint32_t amount, std::uint32_t tokens, RandomBelow const& random)
{
    SealedPurchase purchase;
    if (type >= SEALED_CARD_CATEGORIES.size() * SEALED_CARD_TYPES_PER_CATEGORY)
        return { "PURCHASE_SEALED_CARD_BAD_TYPE" };
    std::uint32_t const bought = collection.Purchases[type];
    if (bought >= tables.SealedCosts.size())
        return { "PURCHASE_SEALED_CARD_NO_COST_ENTRY" };
    purchase.Cost = tables.SealedCosts[bought][type];
    purchase.Token = SealedCardToken(type);
    if (!purchase.Cost)
        return { "PURCHASE_SEALED_CARD_BAD_COST" };
    if (tokens < purchase.Cost)
        return { "PURCHASE_SEALED_CARD_NO_TOKEN" };

    SkillCardType const category = SEALED_CARD_CATEGORIES[type / SEALED_CARD_TYPES_PER_CATEGORY];
    SkillCardQuality const quality = SkillCardQuality(SKILL_CARD_LEGENDARY - type % SEALED_CARD_TYPES_PER_CATEGORY);
    std::vector<std::uint32_t> uncollected;
    for (std::uint32_t card : tables.PackCards[category])
        if (auto const info = tables.Cards.find(card); info != tables.Cards.end() &&
            info->second.Quality == quality && !collection.Collected.contains(card))
            uncollected.push_back(card);
    if (uncollected.empty())
        return { "PURCHASE_SEALED_CARD_NO_UNCOLLECTED_CARDS_OF_QUALITY" };
    if (amount != 1)
        return { "PURCHASE_SEALED_CARD_BAD_AMOUNT" };
    if (!collection.Pending.empty())
        return { "PURCHASE_SEALED_CARD_UNCLAIMED_CARDS" };

    purchase.Cards = DrawCards(std::move(uncollected), CARDS_PER_SEALED_PURCHASE, random);
    return purchase;
}

CardClaim ClaimPendingCards(Tables const& tables, CardCollection& collection, std::vector<std::uint32_t> const& ids,
    RandomBelow const& random)
{
    CardClaim claim;
    for (std::uint32_t id : ids)
    {
        auto const pending = std::find_if(collection.Pending.begin(), collection.Pending.end(),
            [id](PendingCard const& candidate) { return candidate.Id == id; });
        if (pending == collection.Pending.end())
            continue;
        PendingCard const claimed = *pending;
        collection.Pending.erase(pending);
        claim.Claimed.push_back(claimed);

        auto const info = tables.Cards.find(claimed.Card);
        bool const golden = info != tables.Cards.end() &&
            (info->second.Type == SKILL_CARD_DEFAULT_GOLDEN || info->second.Type == SKILL_CARD_TALENT_GOLDEN);
        ++(golden ? claim.GoldenTickets : claim.Tickets);
        std::vector<std::uint32_t> const packs = CollectCard(tables, collection, claimed.Card, random);
        claim.BonusPacks.insert(claim.BonusPacks.end(), packs.begin(), packs.end());
    }
    return claim;
}

std::vector<std::uint32_t> CollectCard(Tables const& tables, CardCollection& collection, std::uint32_t card,
    RandomBelow const& random)
{
    std::vector<std::uint32_t> bonusPacks;
    if (collection.Collected.insert(card).second)
        return bonusPacks;

    auto const info = tables.Cards.find(card);
    SkillCard const collected = info == tables.Cards.end() ? SkillCard{} : info->second;
    std::uint32_t const progress = DUPLICATE_PROGRESS[collected.Quality];
    bool const atMaxRank = collected.Rank == 1;
    if (!atMaxRank)
    {
        collection.Progress[card] += progress;
        return bonusPacks;
    }
    collection.BonusProgress += progress;
    for (; collection.BonusProgress >= BONUS_PACK_PROGRESS; collection.BonusProgress -= BONUS_PACK_PROGRESS)
        bonusPacks.push_back(CARD_PACKS[random(std::uint32_t(CARD_PACKS.size()))].Item);
    return bonusPacks;
}

constexpr std::array<std::uint32_t, 10> DARKMOON_PRIZE_PETS_AND_ACCESSORIES = {
    73764, 73765, 73905, 74981, 80008, 91003, 91040, 499320, 499321, 1201025 };
constexpr std::array<std::uint32_t, 22> DARKMOON_PRIZE_TRANSMOG = {
    78341, 120974, 121306, 121421, 121423, 121459, 121477, 121496, 121514, 121524, 121538, 121557, 121569, 121573,
    121617, 121636, 121714, 121715, 121775, 263031, 263032, 263033 };
constexpr std::array<std::uint32_t, 5> DARKMOON_PRIZE_MOUNTS_AND_TOYS = { 246192, 400272, 400273, 400274, 998100 };

std::vector<StoreCard> DarkmoonPrizeStore()
{
    std::vector<StoreCard> offers;
    for (std::uint32_t item : DARKMOON_PRIZE_PETS_AND_ACCESSORIES)
        offers.push_back({ item, DARKMOON_TICKET_ITEM, DARKMOON_PRIZE_PRICE_PETS_AND_ACCESSORIES });
    for (std::uint32_t item : DARKMOON_PRIZE_TRANSMOG)
        offers.push_back({ item, DARKMOON_TICKET_ITEM, DARKMOON_PRIZE_PRICE_TRANSMOG });
    for (std::uint32_t item : DARKMOON_PRIZE_MOUNTS_AND_TOYS)
        offers.push_back({ item, DARKMOON_TICKET_ITEM, DARKMOON_PRIZE_PRICE_MOUNTS_AND_TOYS });
    return offers;
}

std::vector<StoreCard> SkillCardStore(Tables const& tables, std::uint32_t store)
{
    std::vector<StoreCard> offers;
    if (store != SKILL_CARD_STORE && store != GOLDEN_SKILL_CARD_STORE)
        return offers;
    bool const goldenStore = store == GOLDEN_SKILL_CARD_STORE;
    for (auto const& [item, card] : tables.CardItems)
    {
        auto const info = tables.Cards.find(card);
        if (info == tables.Cards.end() || tables.StarterCards.contains(card) ||
            info->second.Quality >= SKILL_CARD_LEGENDARY)
            continue;
        bool const golden = info->second.Type == SKILL_CARD_DEFAULT_GOLDEN ||
            info->second.Type == SKILL_CARD_TALENT_GOLDEN;
        if (golden == goldenStore)
            offers.push_back({ item, golden ? GOLDEN_DARKMOON_TICKET_ITEM : DARKMOON_TICKET_ITEM,
                SKILL_CARD_STORE_PRICE });
    }
    std::sort(offers.begin(), offers.end(),
        [](StoreCard const& left, StoreCard const& right) { return left.Item < right.Item; });
    return offers;
}

std::vector<std::uint8_t> CustomStorePayload(std::uint32_t store, std::vector<StoreCard> const& cards)
{
    std::string_view const ok = "QUERY_CUSTOM_STORE_OK";
    std::vector<std::uint8_t> payload(ok.begin(), ok.end());
    payload.push_back(0);
    AppendUInt32(payload, std::uint32_t(cards.size()));
    for (StoreCard const& card : cards)
        for (std::uint32_t value : { card.Item, store, card.Item, 0u, card.Token, 0u, 0u, 0u, 0u, card.Price, 0u, 0u,
                 0u, 0u, 0u, 0u })
            AppendUInt32(payload, value);
    return payload;
}

std::vector<std::uint8_t> PendingCardsPayload(Tables const& tables, std::vector<PendingCard> const& cards)
{
    std::vector<std::uint8_t> payload;
    AppendUInt32(payload, std::uint32_t(cards.size()));
    for (PendingCard const& pending : cards)
    {
        std::string const name = PendingCardName(pending.Id);
        payload.insert(payload.end(), name.begin(), name.end());
        payload.push_back(0);
        AppendUInt32(payload, pending.Card);
        AppendUInt32(payload, RankOf(tables, pending.Card));
    }
    return payload;
}

std::string PendingCardName(std::uint32_t id)
{
    return std::to_string(id);
}

std::vector<std::uint8_t> ScrollRewardsPayload(std::uint32_t maxLevel)
{
    std::vector<std::uint8_t> payload;
    AppendUInt32(payload, std::uint32_t(SPECIALIZATION_COUNT * (LEVELING_REWARDS.size() + ENDGAME_SCROLL_CLAIMS)));
    for (std::uint32_t spec = 0; spec < SPECIALIZATION_COUNT; ++spec)
    {
        for (LevelingReward const& reward : LEVELING_REWARDS)
        {
            std::array<std::pair<std::uint32_t, std::uint32_t>, 2> const items = { { { SCROLL_OF_FORTUNE_ITEMS[spec],
                reward.Scrolls }, { TALENT_SCROLL_OF_FORTUNE_ITEM + spec, reward.TalentScrolls } } };
            AppendScrollReward(payload, spec, true, reward.Level, items, 0);
        }
        for (std::uint32_t claim = 1; claim <= ENDGAME_SCROLL_CLAIMS; ++claim)
            AppendScrollReward(payload, spec, false, maxLevel, EndgameScrollClaimRewards(spec),
                EndgameScrollClaimCost(claim));
    }
    return payload;
}

std::uint32_t ScrollItem(std::uint32_t spec, Scroll kind)
{
    if (kind == SCROLL_GENERIC)
        return SCROLL_OF_FORTUNE_ITEMS[spec];
    return (kind == SCROLL_ABILITIES ? ABILITY_SCROLL_OF_FORTUNE_ITEM : TALENT_SCROLL_OF_FORTUNE_ITEM) + spec;
}

char const* CheckRepurchase(Scroll kind, std::uint32_t count, bool gold, std::uint32_t available,
    std::uint32_t level, std::uint32_t maxLevel, std::uint32_t runes, std::uint32_t money)
{
    RepurchasePrice const& price = REPURCHASE_PRICES[kind];
    if (!available)
        return "REPURCHASE_WILDCARD_ROLL_NO_COUNT";
    if (level < maxLevel)
        return "REPURCHASE_WILDCARD_ROLL_NOT_MAX_LEVEL";
    if (!count)
        return "REPURCHASE_WILDCARD_ROLL_TOO_LOW_COUNT";
    if (count > price.Limit)
        return "REPURCHASE_WILDCARD_ROLL_TOO_HIGH_COUNT";
    if (count > available)
        return "REPURCHASE_WILDCARD_ROLL_NOT_ENOUGH_COUNT";
    if (!gold && runes < count * price.Runes)
        return "REPURCHASE_WILDCARD_ROLL_NO_TOKENS";
    if (gold && money < count * price.Money)
        return "REPURCHASE_WILDCARD_ROLL_NO_MONEY";
    return REPURCHASE_OK;
}

std::optional<ScrollToken> ScrollTokenOf(std::int32_t tokenType)
{
    if (tokenType < 0 || std::size_t(tokenType) >= SPECIALIZATION_COUNT * SCROLL_COUNT)
        return std::nullopt;
    return ScrollToken{ std::uint32_t(std::size_t(tokenType) % SPECIALIZATION_COUNT),
        Scroll(std::uint32_t(tokenType) / SPECIALIZATION_COUNT) };
}

std::string ScrollTokenName(ScrollToken token)
{
    static constexpr std::array<char const*, SPECIALIZATION_COUNT> ROMAN = { "I", "II", "III", "IV", "V", "VI",
        "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX" };
    static constexpr std::array<char const*, SCROLL_COUNT> KIND = { "", "_ABILITIES", "_TALENTS" };
    return std::string("TOKEN_TYPE_SCROLL_OF_FORTUNE_") + ROMAN[token.Spec] + KIND[token.Kind];
}

std::string SpecSettingSource(char const* source, std::uint32_t spec)
{
    return spec ? std::string(source) + ".spec" + std::to_string(spec + 1) : std::string(source);
}

std::uint32_t SpellOf(std::uint32_t entryId)
{
    auto const& pool = AscensionWildcardStarterData::OtherAbilities;
    auto const itr = std::find_if(pool.begin(), pool.end(),
        [entryId](StarterEntry const& entry) { return entry.EntryId == entryId; });
    return itr == pool.end() ? 0 : itr->SpellId;
}

std::vector<AscensionCoATalentState::KnownEntry> KnownEntries(std::vector<Slot> const& slots,
    std::uint32_t primaryStat)
{
    std::vector<AscensionCoATalentState::KnownEntry> known;
    for (std::size_t index = 0; index < slots.size(); ++index)
        if (slots[index].EntryId)
            known.push_back({ slots[index].EntryId, slots[index].Rank, slots[index].Rank, slots[index].Locked,
                uint32(index + 1) });
    if (primaryStat)
        known.push_back({ primaryStat, 1, 1, false, 0 });
    return known;
}

Tables const& LoadedTables()
{
    return Loaded;
}

bool PlaysWildcard(std::string_view realmModes)
{
    for (std::string_view mode : Acore::Tokenize(realmModes, ',', false))
        if (Acore::String::Trim(std::string(mode)) == "WildCard")
            return true;
    return false;
}

bool IsWildcardHero(Player const* player)
{
    if (player->getClass() != CLASS_HERO)
        return false;
    std::optional<uint32> const mask = sScriptMgr->OnPlayerGetGameModeMask(player);
    return mask && (*mask & GAME_MODE_WILDCARD);
}

bool IsClasslessHero(Player const* player)
{
    return IsRealmHero(player);
}

std::uint32_t ActiveSpec(Player const* player)
{
    return std::min<std::uint32_t>(FirstSetting(player, ACTIVE_SPEC_SETTING), SPECIALIZATION_COUNT - 1);
}

std::uint32_t PrestigeSpecialization(Player* player)
{
    uint32 const spec = ActiveSpec(player);
    std::unordered_map<uint32, uint32> const learned = RankSpells(Slots(player), PrimaryStat(player));
    std::unordered_set<uint32> forgotten;
    for (auto const& [entryId, spellId] : learned)
    {
        std::vector<std::uint32_t> const ranks = RankSpellsOf(entryId);
        forgotten.insert(ranks.begin(), ranks.end());
        forgotten.insert(spellId);
    }
    for (uint32 spellId : forgotten)
        player->removeSpell(spellId, SPEC_MASK_ALL, false);

    std::array<uint32, SCROLL_COUNT> repurchase = RepurchaseCounts(player, spec);
    Scrolls const tokens = ScrollCounts(player, spec);
    for (std::size_t kind = 0; kind < SCROLL_COUNT; ++kind)
    {
        uint32 const item = ScrollItem(spec, Scroll(kind));
        uint32 const held = player->GetItemCount(item, true);
        if (held)
            player->DestroyItemCount(item, held, true);
        repurchase[kind] += held + tokens[kind];
        player->UpdatePlayerSetting(SpecSettingSource(REPURCHASE_SETTING, spec), uint32(kind), repurchase[kind]);
        SetScrolls(player, ScrollToken{ spec, Scroll(kind) }, 0);
    }
    for (uint32 item : PRESTIGE_DELETED_ITEMS)
        if (uint32 const held = player->GetItemCount(item, true))
            player->DestroyItemCount(item, held, true);

    for (char const* source : { SLOTS_SETTING, PRIMARY_STAT_SETTING, UNLEARNED_SETTING, STARTER_CARDS_SETTING,
             ROLL_CARDS_SETTING })
        ClearSetting(player, SpecSettingSource(source, spec));
    player->UpdatePlayerSetting(SpecSettingSource(CLAIMED_REWARDS_SETTING, spec), LEVELING_CLAIMS, 0);

    SendKnownEntries(player, {});
    SendSkillCards(player);
    SendClaimedRewards(player);
    SendRerollCounts(player, SMSG_WILDCARD_REROLL_COUNT);
    LOG_INFO("coa", "Wildcard specialization {} of {} prestiged: {} entries forgotten, repurchasable scrolls {}/{}/{}",
        spec + 1, player->GetName(), learned.size(), repurchase[SCROLL_GENERIC], repurchase[SCROLL_ABILITIES],
        repurchase[SCROLL_TALENTS]);
    return uint32(learned.size());
}

void SignalRollReady(Player* player)
{
    player->CustomData.GetDefault<PendingRollReady>("AscensionWildcardRollReady")->Due =
        GameTime::GetGameTimeMS() + ROLL_READY_DELAY;
}

void SendPrestigeInfo(Player* player)
{
    uint32 const spec = ActiveSpec(player);
    Scrolls const tokens = ScrollCounts(player, spec);
    WorldPacket packet(SMSG_WILDCARD_PRESTIGE_INFO, 11 * sizeof(uint32));
    for (uint32 word = 0; word < 8; ++word)
        packet << uint32(0);
    for (std::size_t kind = 0; kind < SCROLL_COUNT; ++kind)
        packet << uint32(tokens[kind] + player->GetItemCount(ScrollItem(spec, Scroll(kind)), true));
    player->SendDirectMessage(&packet);
}

std::vector<Slot> Slots(Player const* player)
{
    return Slots(player, ActiveSpec(player));
}

std::vector<Slot> Slots(Player const* player, std::uint32_t spec)
{
    std::vector<Slot> slots;
    if (PlayerSettingVector const* stored = player->FindPlayerSettings(SpecSettingSource(SLOTS_SETTING, spec)))
        for (PlayerSetting const& value : *stored)
            slots.push_back(Decode(value.value));
    return slots;
}

std::uint32_t PrimaryStat(Player const* player)
{
    return PrimaryStat(player, ActiveSpec(player));
}

std::uint32_t PrimaryStat(Player const* player, std::uint32_t spec)
{
    return FirstSetting(player, SpecSettingSource(PRIMARY_STAT_SETTING, spec));
}

StarterCardSlots StarterCards(Player const* player)
{
    return StoredCardSlots<STARTING_ABILITY_COUNT>(player, SpecSource(player, STARTER_CARDS_SETTING));
}

RollCardSlots RollCards(Player const* player)
{
    return StoredCardSlots<std::tuple_size_v<RollCardSlots>>(player, SpecSource(player, ROLL_CARDS_SETTING));
}

CardCollection Collection(Player const* player)
{
    std::lock_guard<std::mutex> lock(CollectionLock);
    return CachedCollection(player->GetSession()->GetAccountId());
}

std::vector<AscensionCoATalentState::KnownEntry> KnownEntries(Player const* player)
{
    return KnownEntries(player, ActiveSpec(player));
}

std::vector<AscensionCoATalentState::KnownEntry> KnownEntries(Player const* player, std::uint32_t spec)
{
    return KnownEntries(Slots(player, spec), PrimaryStat(player, spec));
}

BuildChoice ApplyBuildUpload(Player* player, std::vector<AscensionCoATalentState::KnownEntry> const& upload)
{
    std::uint32_t const current = PrimaryStat(player);
    BuildChoice const choice = CheckBuildUpload(Slots(player), current, upload);
    if (choice.PrimaryStat == current)
        return choice;
    if (player->IsInCombat())
        return { "CA_UPDATE_ENTRIES_NOT_TRAVERSIBLE", "CA_LEARN_WILDCARD_NOT_IN_COMBAT", current };

    if (uint32 const previous = PrimaryStatSpell(current))
        player->removeSpell(previous, SPEC_MASK_ALL, false);
    player->learnSpell(PrimaryStatSpell(choice.PrimaryStat));
    player->UpdatePlayerSetting(SpecSource(player, PRIMARY_STAT_SETTING), 0, choice.PrimaryStat);
    LOG_INFO("coa", "Wildcard stat path of {}: entry {}", player->GetName(), choice.PrimaryStat);
    return choice;
}

void DraftBuild(Player* player, StarterPick const& pickStarters, std::uint32_t starterDraws)
{
    std::vector<Slot> const slots = Slots(player);
    if (std::none_of(slots.begin(), slots.end(), [](Slot const& slot) { return slot.EntryId; }))
        RerollStartingAbilities(player, pickStarters, starterDraws);
    for (uint32 roll = 0; roll < DRAFT_ROLL_LIMIT; ++roll)
        if (std::string_view(RollAbilities(player, {})) != "ROLL_ABILITIES_OK")
            break;
}

void ClaimLevelingScrolls(Player* player)
{
    uint32 const spec = ActiveSpec(player);
    std::string const source = SpecSettingSource(CLAIMED_REWARDS_SETTING, spec);
    uint32 const claimed = SettingAt(player, source, LEVELING_CLAIMS);
    uint32 reached = claimed;
    Scrolls scrolls = ScrollCounts(player, spec);
    for (; reached < LEVELING_REWARDS.size() && LEVELING_REWARDS[reached].Level <= player->GetLevel(); ++reached)
    {
        scrolls[SCROLL_GENERIC] += LEVELING_REWARDS[reached].Scrolls;
        scrolls[SCROLL_TALENTS] += LEVELING_REWARDS[reached].TalentScrolls;
    }
    if (reached == claimed)
        return;

    SetScrolls(player, ScrollToken{ spec, SCROLL_GENERIC }, scrolls[SCROLL_GENERIC]);
    SetScrolls(player, ScrollToken{ spec, SCROLL_TALENTS }, scrolls[SCROLL_TALENTS]);
    player->UpdatePlayerSetting(source, LEVELING_CLAIMS, reached);
}

bool UnlearnForReroll(Player* player, std::uint32_t entryId)
{
    return std::string_view(UnlearnWithScroll(player, entryId)) == UNLEARN_OK;
}
}

void AddAscensionWildcardScripts()
{
    new AscensionRemovedSpellActionBars::Script(AscensionWildcard::IsWildcardHero);
    for (uint16 opcode : { AscensionWildcard::CMSG_WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES,
             AscensionWildcard::CMSG_WILDCARD_ROLL_ABILITIES, AscensionWildcard::CMSG_WILDCARD_UNLEARN_ABILITY,
             AscensionWildcard::CMSG_CHARACTER_ADVANCEMENT_LOCK_ENTRY,
             AscensionWildcard::CMSG_CHARACTER_ADVANCEMENT_UNLOCK_ENTRY,
             AscensionWildcard::CMSG_COLLECT_SCROLL_OF_FORTUNE_REWARDS, AscensionWildcard::CMSG_SET_SKILL_CARD,
             AscensionWildcard::CMSG_PURCHASE_SEALED_CARD, AscensionWildcard::CMSG_CLAIM_PENDING_SKILL_CARD,
             AscensionWildcard::CMSG_PURCHASE_SEALED_CARD_BOOSTER_PACK,
             AscensionWildcard::CMSG_REPURCHASE_WILDCARD_ROLLS,
             AscensionWildcard::CMSG_REPURCHASE_WILDCARD_ABILITY_ROLLS,
             AscensionWildcard::CMSG_REPURCHASE_WILDCARD_TALENT_ROLLS })
        AscensionCompatOpcodes::Claim(opcode, &AscensionWildcard::QueueRequest);
    AscensionCompatOpcodes::Claim(AscensionWildcard::CMSG_QUERY_CUSTOM_STORE, &AscensionWildcard::QueryCardStore);
    AscensionCompatOpcodes::Claim(AscensionWildcard::CMSG_PURCHASE_CUSTOM_STORE_ITEM,
        &AscensionWildcard::BuyStoreCard);
    RegisterAscensionClientConfig([](AscensionClientConfig& config)
    {
        using namespace AscensionWildcard;
        config.Booleans.emplace_back("CONFIG_WILDCARD_QUICK_ROLLING_ENABLED", true);
        config.Booleans.emplace_back("CONFIG_WILDCARD_ROLL_REPURCHASING_ENABLED", true);
        config.Integers.emplace_back("CONFIG_RANDOM_MODE_MAX_DEFAULT_NORMAL_SKILL_CARDS",
            int32(SKILL_CARD_SLOTS[SKILL_CARD_DEFAULT_NORMAL]));
        config.Integers.emplace_back("CONFIG_RANDOM_MODE_MAX_LUCKY_NORMAL_SKILL_CARDS",
            int32(SKILL_CARD_SLOTS[SKILL_CARD_LUCKY_NORMAL]));
        config.Integers.emplace_back("CONFIG_RANDOM_MODE_MAX_TALENT_NORMAL_SKILL_CARDS",
            int32(SKILL_CARD_SLOTS[SKILL_CARD_TALENT_NORMAL]));
    });
    new AscensionWildcard::AscensionWildcardPlayer();
    new AscensionWildcard::AscensionWildcardItemSpells();
    new AscensionWildcard::AscensionWildcardItems();
    new AscensionWildcard::AscensionWildcardSpecializationCache();
    RegisterSpellScriptWithArgs(AscensionWildcard::spell_wildcard_specialization_swap,
        "spell_wildcard_specialization_swap");
    RegisterSpellScriptWithArgs(AscensionWildcard::aura_wildcard_victorious_state, "aura_wildcard_victorious_state");
    new AscensionWildcard::AscensionWildcardWorld();
    Trainer::SetWildcardRankRows(&AscensionWildcard::RankTrainerRows);
    Trainer::SetRankTrainerHero(&AscensionWildcard::IsClasslessHero);
}
