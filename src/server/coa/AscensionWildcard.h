/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_WILDCARD_H
#define ASCENSION_WILDCARD_H

#include "AscensionCoATalentState.h"
#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

class Player;

namespace AscensionWildcard
{
constexpr std::uint32_t GAME_MODE_WILDCARD = 0x40;
constexpr std::uint16_t WILDCARD_SEASON_EVENT = 194;
constexpr std::uint32_t DRAFT_ROLL_LIMIT = 200;
constexpr std::size_t STARTING_ABILITY_COUNT = 4;
constexpr std::uint8_t STARTING_REROLL_MAX_LEVEL = 9;
constexpr std::uint32_t ABILITY_ROLL_COST = 2;
constexpr std::uint32_t TALENT_ROLL_COST = 1;
constexpr std::uint32_t TALENT_POOL_START_LEVEL = 10;
constexpr std::uint32_t TAME_GROUP = 2;
constexpr std::uint32_t ENTRY_MASK = 0xFFFFF;
constexpr std::uint32_t RANK_SHIFT = 20;
constexpr std::uint32_t RANK_MASK = 0x7;
constexpr std::uint32_t TALENT = 0x800000;
constexpr std::uint32_t LOCKED = 0x80000000;
constexpr std::size_t SPECIALIZATION_COUNT = 20;
constexpr std::array<std::uint32_t, SPECIALIZATION_COUNT> SPECIALIZATION_SWAP_SPELLS = { 979993, 979994, 979995,
    979996, 979997, 979986, 979987, 979988, 84874, 84876, 84878, 84880, 84882, 84884, 84886, 84888, 84890, 84892,
    84894, 84896 };
constexpr std::array<std::uint32_t, SPECIALIZATION_COUNT> SCROLL_OF_FORTUNE_ITEMS = { 1101244, 1111244, 1121244,
    1131244, 1141244, 1151244, 1161244, 1171244, 752026, 752027, 752028, 752029, 752039, 752040, 752041, 752042,
    752043, 752044, 752045, 752046 };
constexpr std::uint32_t ABILITY_SCROLL_OF_FORTUNE_ITEM = 97913;
constexpr std::uint32_t TALENT_SCROLL_OF_FORTUNE_ITEM = 97933;
constexpr std::uint32_t RUNE_OF_ASCENSION_ITEM = 375250;
constexpr std::uint32_t ENDGAME_SCROLL_CLAIMS = 458;
constexpr char CLAIM_OK[] = "COLLECT_SCROLL_OF_FORTUNE_REWARDS_OK";

struct PrimaryStatPath
{
    std::uint32_t EntryId;
    std::uint32_t SpellId;
};

constexpr std::array<PrimaryStatPath, 5> PRIMARY_STAT_PATHS = { {
    { 1149, 84864 },
    { 1150, 84865 },
    { 1151, 84866 },
    { 1152, 84867 },
    { 18149, 129243 },
} };

struct LevelingReward
{
    std::uint32_t Level;
    std::uint32_t Scrolls;
    std::uint32_t TalentScrolls;
};

constexpr std::array<LevelingReward, 6> LEVELING_REWARDS = { {
    { 10, 2, 6 },
    { 20, 4, 8 },
    { 30, 6, 10 },
    { 40, 8, 12 },
    { 50, 10, 14 },
    { 60, 12, 16 },
} };

struct Slot
{
    std::uint32_t EntryId = 0;
    bool Locked = false;
    std::uint32_t Rank = 1;
    bool Talent = false;
};

struct Entry
{
    std::uint32_t EntryId = 0;
    bool Talent = false;
    std::uint32_t MinLevel = 0;
    std::uint32_t Group = 0;
    std::vector<std::uint32_t> RankSpells;
    bool Glyph = false;
    std::uint32_t AbilityCost = ABILITY_ROLL_COST;
};

struct Essence
{
    std::uint32_t Level = 0;
    std::uint32_t Ability = 0;
    std::uint32_t Talent = 0;
};

struct StarterCard
{
    std::uint32_t EntryId = 0;
    bool Golden = false;
};

enum SkillCardType : std::size_t
{
    SKILL_CARD_DEFAULT_NORMAL,
    SKILL_CARD_DEFAULT_GOLDEN,
    SKILL_CARD_STARTER_NORMAL,
    SKILL_CARD_STARTER_GOLDEN,
    SKILL_CARD_LUCKY_NORMAL,
    SKILL_CARD_LUCKY_GOLDEN,
    SKILL_CARD_TALENT_NORMAL,
    SKILL_CARD_TALENT_GOLDEN,
    SKILL_CARD_MAX_TYPE,
    SKILL_CARD_TYPE_COUNT
};

enum SkillCardQuality : std::size_t
{
    SKILL_CARD_COMMON,
    SKILL_CARD_UNCOMMON,
    SKILL_CARD_RARE,
    SKILL_CARD_EPIC,
    SKILL_CARD_LEGENDARY,
    SKILL_CARD_QUALITY_COUNT
};

constexpr std::array<char const*, SKILL_CARD_QUALITY_COUNT> SKILL_CARD_QUALITY_NAMES = { "SKILL_CARD_COMMON",
    "SKILL_CARD_UNCOMMON", "SKILL_CARD_RARE", "SKILL_CARD_EPIC", "SKILL_CARD_LEGENDARY" };
constexpr std::array<std::uint32_t, SKILL_CARD_QUALITY_COUNT> DUPLICATE_PROGRESS = { 1, 2, 4, 8, 10 };
constexpr std::uint32_t BONUS_PACK_PROGRESS = 100;
constexpr std::uint32_t DARKMOON_TICKET_ITEM = 246190;
constexpr std::uint32_t GOLDEN_DARKMOON_TICKET_ITEM = 97399;

struct SkillCard
{
    std::uint32_t EntryId = 0;
    SkillCardType Type = SKILL_CARD_MAX_TYPE;
    std::uint32_t Rank = 1;
    SkillCardQuality Quality = SKILL_CARD_COMMON;
};

constexpr std::size_t SEALED_CARD_TYPE_COUNT = 24;
constexpr std::size_t SEALED_CARD_TYPES_PER_CATEGORY = SKILL_CARD_QUALITY_COUNT;
constexpr std::uint32_t CARDS_PER_SEALED_PURCHASE = 3;
constexpr std::array<SkillCardType, 4> SEALED_CARD_CATEGORIES = { SKILL_CARD_DEFAULT_NORMAL, SKILL_CARD_TALENT_NORMAL,
    SKILL_CARD_DEFAULT_GOLDEN, SKILL_CARD_TALENT_GOLDEN };
constexpr std::array<char const*, SEALED_CARD_TYPE_COUNT> SEALED_CARD_TYPE_NAMES = {
    "PURCHASE_SEALED_CARD_TYPE_NORMAL_LEGENDARY_ABILITIES", "PURCHASE_SEALED_CARD_TYPE_NORMAL_EPIC_ABILITIES",
    "PURCHASE_SEALED_CARD_TYPE_NORMAL_RARE_ABILITIES", "PURCHASE_SEALED_CARD_TYPE_NORMAL_UNCOMMON_ABILITIES",
    "PURCHASE_SEALED_CARD_TYPE_NORMAL_COMMON_ABILITIES", "PURCHASE_SEALED_CARD_TYPE_NORMAL_LEGENDARY_TALENTS",
    "PURCHASE_SEALED_CARD_TYPE_NORMAL_EPIC_TALENTS", "PURCHASE_SEALED_CARD_TYPE_NORMAL_RARE_TALENTS",
    "PURCHASE_SEALED_CARD_TYPE_NORMAL_UNCOMMON_TALENTS", "PURCHASE_SEALED_CARD_TYPE_NORMAL_COMMON_TALENTS",
    "PURCHASE_SEALED_CARD_TYPE_GOLDEN_LEGENDARY_ABILITIES", "PURCHASE_SEALED_CARD_TYPE_GOLDEN_EPIC_ABILITIES",
    "PURCHASE_SEALED_CARD_TYPE_GOLDEN_RARE_ABILITIES", "PURCHASE_SEALED_CARD_TYPE_GOLDEN_UNCOMMON_ABILITIES",
    "PURCHASE_SEALED_CARD_TYPE_GOLDEN_COMMON_ABILITIES", "PURCHASE_SEALED_CARD_TYPE_GOLDEN_LEGENDARY_TALENTS",
    "PURCHASE_SEALED_CARD_TYPE_GOLDEN_EPIC_TALENTS", "PURCHASE_SEALED_CARD_TYPE_GOLDEN_RARE_TALENTS",
    "PURCHASE_SEALED_CARD_TYPE_GOLDEN_UNCOMMON_TALENTS", "PURCHASE_SEALED_CARD_TYPE_GOLDEN_COMMON_TALENTS",
    "PURCHASE_SEALED_CARD_TYPE_DEFAULT_PACK", "PURCHASE_SEALED_CARD_TYPE_DEFAULT_GOLDEN_PACK",
    "PURCHASE_SEALED_CARD_TYPE_DEFAULT_TALENT_PACK", "PURCHASE_SEALED_CARD_TYPE_DEFAULT_GOLDEN_TALENT_PACK" };
using SealedCardCosts = std::array<std::uint32_t, SEALED_CARD_TYPE_COUNT>;

struct Tables
{
    std::vector<Entry> Entries;
    std::vector<Essence> Budget;
    std::unordered_map<std::uint32_t, StarterCard> StarterCards;
    std::array<std::vector<std::uint32_t>, SKILL_CARD_TYPE_COUNT> PackCards;
    std::unordered_map<std::uint32_t, SkillCard> Cards;
    std::unordered_map<std::uint32_t, std::uint32_t> CardItems;
    std::vector<std::uint32_t> DropItems;
    std::unordered_map<std::uint32_t, std::uint32_t> BossMarks;
    std::vector<SealedCardCosts> SealedCosts;
    std::unordered_map<std::uint32_t, std::vector<std::uint32_t>> SpellTags;
    std::unordered_map<std::uint32_t, std::unordered_set<std::uint32_t>> Linked;
    std::unordered_map<std::uint32_t, std::unordered_set<std::uint32_t>> Related;
    std::unordered_map<std::uint32_t, std::vector<std::uint32_t>> SynergyTags;
    std::unordered_map<std::uint32_t, std::unordered_set<std::uint32_t>> Mentioned;
    std::unordered_map<std::uint32_t, std::string> TagNames;
    std::unordered_map<std::uint32_t, std::vector<std::uint32_t>> RankLadders;
    std::unordered_map<std::uint32_t, std::uint32_t> RankRoots;
    std::unordered_map<std::uint32_t, std::uint32_t> AbilityCosts;
};

struct PendingCard
{
    std::uint32_t Id = 0;
    std::uint32_t Card = 0;
};

struct CardCollection
{
    std::unordered_set<std::uint32_t> Collected;
    std::vector<PendingCard> Pending;
    std::unordered_map<std::uint32_t, std::uint32_t> Progress;
    std::uint32_t BonusProgress = 0;
    std::array<std::uint32_t, SEALED_CARD_TYPE_COUNT> Purchases{};
};

struct CardClaim
{
    std::vector<PendingCard> Claimed;
    std::uint32_t Tickets = 0;
    std::uint32_t GoldenTickets = 0;
    std::vector<std::uint32_t> BonusPacks;
};

struct StoreCard
{
    std::uint32_t Item = 0;
    std::uint32_t Token = 0;
    std::uint32_t Price = 0;
};

constexpr std::uint32_t DARKMOON_PRIZES_STORE = 4;
constexpr std::uint32_t SKILL_CARD_STORE = 5;
constexpr std::uint32_t GOLDEN_SKILL_CARD_STORE = 6;
constexpr std::uint32_t SKILL_CARD_STORE_PRICE = 250;
constexpr std::uint32_t DARKMOON_PRIZE_PRICE_PETS_AND_ACCESSORIES = 250;
constexpr std::uint32_t DARKMOON_PRIZE_PRICE_TRANSMOG = 500;
constexpr std::uint32_t DARKMOON_PRIZE_PRICE_MOUNTS_AND_TOYS = 1000;

struct SealedPurchase
{
    char const* Result = "PURCHASE_SEALED_CARD_OK";
    std::uint32_t Token = 0;
    std::uint32_t Cost = 0;
    std::vector<std::uint32_t> Cards;
};

struct CardPack
{
    char const* PurchaseType;
    std::uint32_t Item;
    std::uint32_t Spell;
    SkillCardType Cards;
};

constexpr std::uint32_t CARDS_PER_PACK = 5;
constexpr std::uint32_t MAX_PACKS_PER_PURCHASE = 200;
constexpr std::uint32_t BOOSTER_PRICE = 500000;
constexpr std::uint32_t MAX_BOOSTERS_PER_PURCHASE = 0x10C6;
constexpr std::array<CardPack, 4> CARD_PACKS = { {
    { "PURCHASE_SEALED_CARD_TYPE_DEFAULT_PACK", 97885, 93330, SKILL_CARD_DEFAULT_NORMAL },
    { "PURCHASE_SEALED_CARD_TYPE_DEFAULT_GOLDEN_PACK", 778998, 93333, SKILL_CARD_DEFAULT_GOLDEN },
    { "PURCHASE_SEALED_CARD_TYPE_DEFAULT_TALENT_PACK", 97886, 93331, SKILL_CARD_TALENT_NORMAL },
    { "PURCHASE_SEALED_CARD_TYPE_DEFAULT_GOLDEN_TALENT_PACK", 97870, 93329, SKILL_CARD_TALENT_GOLDEN },
} };
constexpr std::array<std::uint32_t, 2> BOOSTER_PACK_ITEMS = { 778998, 97870 };

struct CardSlot
{
    std::uint32_t Card = 0;
    bool Used = false;
};

using StarterCardSlots = std::array<CardSlot, STARTING_ABILITY_COUNT>;

constexpr std::array<SkillCardType, 4> ROLL_CARD_TYPES = { SKILL_CARD_DEFAULT_NORMAL, SKILL_CARD_DEFAULT_GOLDEN,
    SKILL_CARD_TALENT_NORMAL, SKILL_CARD_TALENT_GOLDEN };
constexpr std::size_t ROLL_CARDS_PER_TYPE = 3;
constexpr std::array<std::uint32_t, ROLL_CARDS_PER_TYPE> ABILITY_CARD_SLOT_LEVELS = { 0, 25, 40 };
using RollCardSlots = std::array<CardSlot, ROLL_CARD_TYPES.size() * ROLL_CARDS_PER_TYPE>;

constexpr std::array<std::uint32_t, SKILL_CARD_TYPE_COUNT> SKILL_CARD_SLOTS = { 3, 3, 2, 2, 3, 3, 3, 3, 0 };
constexpr std::array<char const*, SKILL_CARD_TYPE_COUNT> SKILL_CARD_TYPE_NAMES = { "SKILL_CARD_DEFAULT_NORMAL",
    "SKILL_CARD_DEFAULT_GOLDEN", "SKILL_CARD_STARTER_NORMAL", "SKILL_CARD_STARTER_GOLDEN", "SKILL_CARD_LUCKY_NORMAL",
    "SKILL_CARD_LUCKY_GOLDEN", "SKILL_CARD_TALENT_NORMAL", "SKILL_CARD_TALENT_GOLDEN", "SKILL_CARD_MAX" };

struct BuildChoice
{
    char const* Result = "CA_UPDATE_ENTRIES_OK";
    char const* Learn = "";
    std::uint32_t PrimaryStat = 0;
};

enum Scroll : std::size_t
{
    SCROLL_GENERIC,
    SCROLL_ABILITIES,
    SCROLL_TALENTS,
    SCROLL_COUNT
};

struct RepurchasePrice
{
    std::uint32_t Runes;
    std::uint32_t Money;
    std::uint32_t Limit;
};

constexpr std::array<RepurchasePrice, SCROLL_COUNT> REPURCHASE_PRICES = { {
    { 50, 200000, 10737 },
    { 50, 200000, 10737 },
    { 33, 150000, 14316 },
} };
constexpr char REPURCHASE_OK[] = "REPURCHASE_WILDCARD_ROLL_OK";

using Scrolls = std::array<std::uint32_t, SCROLL_COUNT>;

struct ScrollToken
{
    std::uint32_t Spec = 0;
    Scroll Kind = SCROLL_GENERIC;
};

std::optional<ScrollToken> ScrollTokenOf(std::int32_t tokenType);
std::string ScrollTokenName(ScrollToken token);
std::string SpecSettingSource(char const* source, std::uint32_t spec);

struct QuickRoll
{
    bool Ability = false;
    std::uint32_t Threshold = 0;
    std::uint32_t Max = 0;
};

constexpr std::array<QuickRoll, 4> QUICK_ROLLS = { {
    { true, 0, 5 },
    { true, 50, 10 },
    { false, 0, 5 },
    { false, 50, 10 },
} };

struct RapidRequest
{
    std::uint32_t Count = 0;
    std::vector<std::uint32_t> DesiredIds;
    std::vector<std::uint32_t> DesiredTags;
};

struct RapidRoll
{
    std::optional<Slot> Rolled;
    std::vector<Scroll> Spent;
    std::uint32_t LastSkipped = 0;
    char const* StopCode = "STOP_RAPID_ROLLING_COUNT_DEPLETED";
};
using RandomBelow = std::function<std::uint32_t(std::uint32_t bound)>;
using SpellFilter = std::function<bool(std::uint32_t spellId)>;

std::vector<Slot> RollStartingAbilities(std::vector<Slot> slots, RandomBelow const& random,
    SpellFilter const& available, std::array<std::uint32_t, STARTING_ABILITY_COUNT> const& chosen = {});

std::optional<std::uint32_t> PoolLevel(std::vector<Essence> const& budget, std::vector<Slot> const& slots,
    std::uint32_t level, bool talent);

constexpr std::uint32_t SYNERGY_WEIGHT_LIMIT = 1000;
constexpr std::uint32_t WEAPON_SCHOOL_TAG_OFFSET = 1000;

struct SynergySettings
{
    std::uint32_t ChancePercent = 65;
    std::uint32_t LinkWeight = 3;
    std::uint32_t RelatedWeight = 2;
    std::uint32_t SpecTagWeight = 2;
    std::uint32_t SchoolTagWeight = 1;
    std::uint32_t TooltipWeight = 3;
    bool TalentsNeedTarget = true;
    bool LogRolls = true;
};

bool IsSpecTag(std::uint32_t tag);
bool IsSchoolTag(std::uint32_t tag);
std::uint32_t SynergyTagOf(std::uint32_t tag, bool weapon);
std::uint32_t SynergyTagWeight(std::uint32_t tag, SynergySettings const& synergy = {});

void RelateAcrossClasses(Tables& tables, std::unordered_set<std::uint32_t> const& weaponAttacks);

std::uint32_t SynergyScore(Tables const& tables, std::uint32_t candidate, std::vector<std::uint32_t> const& build,
    SynergySettings const& synergy = {});

enum class SynergyKind : std::uint8_t
{
    Link,
    Related,
    Tooltip,
    Tag
};

struct SynergyReason
{
    std::uint32_t Known = 0;
    SynergyKind Kind = SynergyKind::Link;
    std::uint32_t Tag = 0;
    std::uint32_t Points = 0;
};

std::vector<SynergyReason> SynergyReasons(Tables const& tables, std::uint32_t candidate,
    std::vector<std::uint32_t> const& build, SynergySettings const& synergy = {});

enum class RollSource : std::uint8_t
{
    Random,
    Synergy,
    Card
};

struct RollTrace
{
    RollSource Source = RollSource::Random;
    std::uint32_t Score = 0;
    std::uint32_t Total = 0;
    std::uint32_t Candidates = 0;
    std::uint32_t Scored = 0;
};

std::optional<Slot> RollLevelEntry(Tables const& tables, std::vector<Slot> const& slots, std::uint32_t level,
    std::uint32_t excludedEntry, RandomBelow const& random, SpellFilter const& available,
    std::vector<Slot> const& carded = {}, SynergySettings const& synergy = {}, RollTrace* trace = nullptr);

void Place(std::vector<Slot>& slots, Slot slot);

std::uint32_t RapidRollLimit(std::uint32_t rerolled, bool ability);

RapidRoll RollRapidly(Tables const& tables, std::vector<Slot> const& slots, std::uint32_t level,
    std::uint32_t excludedEntry, RapidRequest const& request, Scrolls scrolls, RandomBelow const& random,
    SpellFilter const& available, SynergySettings const& synergy = {}, RollTrace* trace = nullptr);

char const* CheckUnlearn(std::vector<Essence> const& budget, std::vector<Slot> const& slots, std::uint32_t level,
    std::uint32_t entryId);

std::optional<Scroll> ScrollToSpend(Scrolls const& scrolls, bool talent);

BuildChoice CheckBuildUpload(std::vector<Slot> const& slots, std::uint32_t primaryStat,
    std::vector<AscensionCoATalentState::KnownEntry> const& upload);

std::uint32_t EndgameScrollClaimCost(std::uint32_t claim);

std::uint32_t EndgameScrollClaimsCost(std::uint32_t claimed, std::uint32_t count);

std::array<std::pair<std::uint32_t, std::uint32_t>, 4> EndgameScrollClaimRewards(std::uint32_t tier);

char const* CheckScrollClaim(std::uint32_t tier, std::uint32_t count, bool leveling, std::uint32_t claimed,
    std::uint32_t level, std::uint32_t maxLevel, std::uint32_t runes);

std::vector<std::uint8_t> ScrollRewardsPayload(std::uint32_t maxLevel);

std::uint32_t ScrollItem(std::uint32_t spec, Scroll kind);

char const* CheckRepurchase(Scroll kind, std::uint32_t count, bool gold, std::uint32_t available,
    std::uint32_t level, std::uint32_t maxLevel, std::uint32_t runes, std::uint32_t money);

bool InStartingPhase(std::vector<Slot> const& slots);

std::optional<std::size_t> StarterCardPosition(std::size_t type, std::uint32_t index);

char const* CheckSetStarterCard(Tables const& tables, std::vector<Slot> const& slots,
    StarterCardSlots const& cards, std::size_t position, std::uint32_t card);

std::array<std::uint32_t, STARTING_ABILITY_COUNT> ChosenStarters(Tables const& tables,
    StarterCardSlots const& cards);

std::optional<std::size_t> RollCardPosition(std::size_t type, std::uint32_t index);

char const* CheckSetRollCard(Tables const& tables, std::vector<Slot> const& slots, RollCardSlots const& cards,
    CardCollection const& collection, std::size_t position, std::uint32_t card);

std::vector<Slot> CardedEntries(Tables const& tables, RollCardSlots const& cards, std::uint32_t level);

struct SpecCardSlots
{
    StarterCardSlots Starters{};
    RollCardSlots Cards{};
};

std::vector<std::uint8_t> SkillCardSlotsPayload(Tables const& tables, std::vector<SpecCardSlots> const& specs);

std::vector<std::uint8_t> SkillCardCollectionPayload(Tables const& tables, CardCollection const& collection);

std::vector<std::uint32_t> DrawCards(std::vector<std::uint32_t> pool, std::uint32_t count, RandomBelow const& random);

constexpr std::uint32_t CARD_DROP_CHANCE_PER_MILLE = 30;

std::optional<std::uint32_t> RollCardDrop(Tables const& tables, RandomBelow const& random);

std::vector<std::uint32_t> OpenCardPack(Tables const& tables, SkillCardType cards, RandomBelow const& random);

void AddPending(CardCollection& collection, std::vector<std::uint32_t> const& cards);

std::uint32_t SealedCardToken(std::size_t type);

SealedPurchase CheckSealedPurchase(Tables const& tables, CardCollection const& collection, std::size_t type,
    std::uint32_t amount, std::uint32_t tokens, RandomBelow const& random);

std::vector<std::uint32_t> CollectCard(Tables const& tables, CardCollection& collection, std::uint32_t card,
    RandomBelow const& random);

CardClaim ClaimPendingCards(Tables const& tables, CardCollection& collection, std::vector<std::uint32_t> const& ids,
    RandomBelow const& random);

std::vector<StoreCard> SkillCardStore(Tables const& tables, std::uint32_t store);
std::vector<StoreCard> DarkmoonPrizeStore();

std::vector<std::uint8_t> CustomStorePayload(std::uint32_t store, std::vector<StoreCard> const& cards);

std::vector<std::uint8_t> PendingCardsPayload(Tables const& tables, std::vector<PendingCard> const& cards);

std::string PendingCardName(std::uint32_t id);

std::uint32_t SpellOf(std::uint32_t entryId);

std::vector<AscensionCoATalentState::KnownEntry> KnownEntries(std::vector<Slot> const& slots,
    std::uint32_t primaryStat = 0);

inline std::uint32_t Encode(Slot slot)
{
    return (slot.EntryId & ENTRY_MASK) | (((slot.Rank - 1) & RANK_MASK) << RANK_SHIFT) |
        (slot.Talent ? TALENT : 0) | (slot.Locked ? LOCKED : 0);
}

inline Slot Decode(std::uint32_t value)
{
    return { value & ENTRY_MASK, (value & LOCKED) != 0, ((value >> RANK_SHIFT) & RANK_MASK) + 1,
        (value & TALENT) != 0 };
}

Tables const& LoadedTables();
bool IsWildcardHero(Player const* player);
bool IsClasslessHero(Player const* player);
bool PlaysWildcard(std::string_view realmModes);

std::uint32_t ActiveSpec(Player const* player);

std::uint32_t PrestigeSpecialization(Player* player);

void SendPrestigeInfo(Player* player);

void SignalRollReady(Player* player);

std::vector<Slot> Slots(Player const* player);
std::vector<Slot> Slots(Player const* player, std::uint32_t spec);
std::uint32_t PrimaryStat(Player const* player);
std::uint32_t PrimaryStat(Player const* player, std::uint32_t spec);
StarterCardSlots StarterCards(Player const* player);
RollCardSlots RollCards(Player const* player);
CardCollection Collection(Player const* player);
std::vector<AscensionCoATalentState::KnownEntry> KnownEntries(Player const* player);
std::vector<AscensionCoATalentState::KnownEntry> KnownEntries(Player const* player, std::uint32_t spec);
BuildChoice ApplyBuildUpload(Player* player, std::vector<AscensionCoATalentState::KnownEntry> const& upload);
using StarterPick = std::function<std::size_t(std::vector<std::vector<Slot>> const& candidates)>;
void DraftBuild(Player* player, StarterPick const& pickStarters = {}, std::uint32_t starterDraws = 1);
void ClaimLevelingScrolls(Player* player);
bool UnlearnForReroll(Player* player, std::uint32_t entryId);
}

#endif
