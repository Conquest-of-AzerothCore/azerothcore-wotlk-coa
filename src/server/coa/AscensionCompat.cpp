/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU
 * AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AccountMgr.h"
#include "AscensionFelsworn.h"
#include "AscensionItemScaling.h"
#include "AscensionPyromancer.h"
#include "AscensionCultist.h"
#include "AscensionVenomancer.h"
#include "AscensionTinker.h"
#include "AscensionSunCleric.h"
#include "AllCreatureScript.h"
#include "AllItemScript.h"
#include "AllSpellScript.h"
#include "AscensionChangelogCompat.h"
#include "AscensionCompatOpcodes.h"
#include "AscensionCharacterSelection.h"
#include "AscensionManastorm.h"
#include "AscensionClassMechanics.h"
#include "AscensionClassMechanics19To25.h"
#include "AscensionClassMechanics26To32.h"
#include "AscensionCoATalentData.h"
#include "AscensionCoAConfig.h"
#include "WorldSessionMgr.h"
#include "AscensionCoATalentState.h"
#include "AscensionWildcard.h"
#include "AscensionStockScriptShapes.h"
#include "AscensionFreepick.h"
#include "AscensionRunemasterEchoes.h"
#include "AscensionCollectionModelData.h"
#include "AscensionWitchHunterCompletion.h"
#include "AscensionAmmunitionData.h"
#include "AscensionPersonalBank.h"
#include "AscensionCollectibleSpellData.h"
#include "AscensionCustomClassData.h"
#include "AscensionAuraAmounts.h"
#include "AscensionClientSpellPatches.h"
#include "DBCfmt.h"
#include "AscensionClassTuning.h"
#include "AscensionBarbarian.h"
#include "AscensionBarbarianScaling.h"
#include "AscensionCustomResourceData.h"
#include "AscensionFreshCharacterCheck.h"
#include "AscensionLiveBaselineData.h"
#include "AscensionRacialAbilities.h"
#include "AscensionPrimalistEarthquake.h"
#include "AscensionPrimalistEarthshaping.h"
#include "AscensionPrimalistSpiritBeast.h"
#include "AscensionPrimalistWeapons.h"
#include "AscensionRunemasterTalents.h"
#include "AscensionRangerTalents.h"
#include "AscensionChronomancerTalents.h"
#include "AscensionReaperTalents.h"
#include "AscensionReaperSoulStrike.h"
#include "AscensionReaperDeathwind.h"
#include "AscensionBloodmageHemoglobe.h"
#include "AscensionReaperPainmail.h"
#include "AscensionReaperScytheRush.h"
#include "AscensionVenomancerCatalyst.h"
#include "AscensionSpecialization.h"
#include "AscensionSpellProgressionData.h"
#include "AscensionTalentReplacementData.h"
#include "AscensionTaughtAbilityData.h"
#include "AscensionPooledVitality.h"
#include "AscensionCreaturePreset.h"
#include "AscensionItemAppearanceAliases.h"
#include "AsyncCallbackProcessor.h"
#include "Bag.h"
#include "Battlefield.h"
#include "BattlefieldMgr.h"
#include "Chat.h"
#include "StringFormat.h"
#include "ClientDBC.h"
#include "CommandScript.h"
#include "ConfigValueCache.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "GameTime.h"
#include "GossipDef.h"
#include "GlobalScript.h"
#include "GroupScript.h"
#include "GridTerrainData.h"
#include "GuildPackets.h"
#include "Item.h"
#include "ItemScript.h"
#include "LocalLevelScaling.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Pet.h"
#include "Player.h"
#include "QuestDef.h"
#include "Random.h"
#include "Realm.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "StringConvert.h"
#include "Timer.h"
#include "Tokenize.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <bit>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <type_traits>
#include <deque>
#include <limits>
#include <list>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <tuple>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

#ifndef _WIN32
extern char** environ;
#endif

using namespace Acore::ChatCommands;

namespace {
constexpr uint16 CMSG_ANTICHEAT_ALERT = 0x051F;
constexpr uint16 CMSG_CUSTOM_ASCENSION_POINT_SPEND_REQUEST = 0x0523;
constexpr uint16 CMSG_EXTENSION_INITIALIZED = 0x0561;
constexpr uint16 CMSG_CREATURE_QUERY_BULK = 0x061A;
constexpr uint16 CMSG_ITEM_QUERY_BULK = 0x061B;
constexpr uint16 CMSG_ITEM_STAT_QUERY = 0x06FF;
constexpr uint16 SMSG_PATCH_APPEARANCES = 0x0692;
constexpr uint16 SMSG_PATCH_ITEM_APPEARANCES = 0x0693;
constexpr uint16 CMSG_APPLY_APPEARANCES = 0x0697;
constexpr uint16 SMSG_APPLY_APPEARANCES_RESULT = 0x0698;
constexpr uint16 SMSG_APPEARANCE_COLLECTION_INFO = 0x0699;
constexpr uint16 SMSG_APPEARANCE_ACTIVE_INFO = 0x069A;
constexpr uint16 SMSG_APPEARANCE_ADDED = 0x069B;
constexpr uint16 SMSG_APPEARANCE_OUTFIT_INFO = 0x069D;
constexpr uint16 CMSG_SAVE_APPEARANCE_OUTFIT = 0x069E;
constexpr uint16 SMSG_SAVE_APPEARANCE_OUTFIT_RESULT = 0x069F;
constexpr uint16 CMSG_DELETE_APPEARANCE_OUTFIT = 0x06A0;
constexpr uint16 SMSG_DELETE_APPEARANCE_OUTFIT_RESULT = 0x06A1;
constexpr std::size_t MAX_APPEARANCE_OUTFIT_NAME_BYTES = 64;
constexpr std::size_t MAX_APPEARANCE_OUTFITS = 100;
constexpr uint16 SMSG_CAN_SEE_APPEARANCES_INFO = 0x06A2;
constexpr uint16 CMSG_SET_CAN_SEE_APPEARANCES = 0x06A3;
constexpr uint16 SMSG_VANITY_COLLECTION_INFO = 0x06F7;
constexpr uint16 SMSG_VANITY_COLLECTION_ADDED = 0x06F8;

constexpr uint16 CMSG_QUERY_CUSTOM_STORE = 0x06B9;
constexpr uint16 CMSG_PURCHASE_CUSTOM_STORE_ITEM = 0x06BB;
constexpr uint16 SMSG_QUERY_CUSTOM_STORE_RESULT = 0x06BA;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_ACTIVE_SPEC = 0x0725;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES = 0x0726;
constexpr uint16 CMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES = 0x0727;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_PURGE_TALENTS_RESULT = 0x072B;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT = 0x072C;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_CREDITS = 0x0926;
constexpr uint16 CMSG_INSPECT_CHARACTER_ADVANCEMENT = 0x06E1;
constexpr uint16 SMSG_INSPECT_CHARACTER_ADVANCEMENT_RESULT = 0x06E2;
constexpr uint16 CMSG_MISSILE_FIRE_POSITION = 0x09C7;

constexpr uint16 SMSG_PATCH_LOADING_SCREENS = 0x05F8;
constexpr uint16 SMSG_PATCH_CREATURE_DISPLAY_INFO = 0x0976;
constexpr uint16 SMSG_PATCH_ITEM = 0x0932;
constexpr uint16 SMSG_PATCH_ITEM_DISPLAY_INFO = 0x096B;
constexpr uint16 SMSG_PATCH_CHARACTER_ADVANCEMENT = 0x064A;
constexpr uint16 SMSG_PATCH_SPELL = 0x092A;
constexpr uint16 SMSG_PATCH_SUPER_TRACK = 0x06BE;
constexpr uint16 SMSG_PATCH_SKILL_LINE_ABILITY = 0x0934;
constexpr uint16 SMSG_PATCH_SPELL_SHAPESHIFT_FORM = 0x0949;
constexpr uint16 SMSG_PATCH_CREATURE_MODEL_DATA = 0x0974;
constexpr uint32 CUSTOM_DISPLAY_ID_FALLBACK_MIN = 652000;
constexpr uint32 DISPLAY_PATCH_FALLBACK_DELAY_MS = 5000;
constexpr uint32 DISPLAY_PATCH_RESEND_COOLDOWN_MS = 10000;

constexpr uint16 SMSG_PATCH_VANITY_COLLECTION = 0x0573;
constexpr uint16 SMSG_UPDATE_OBJECT_ADDON = 0x0578;
constexpr uint32 PLAYER_ADDON_FIELD_AVERAGE_ITEM_LEVEL = 5;

constexpr uint16 SMSG_REALM_INFO = 0x09BC;
constexpr uint16 SMSG_ASCENSION_SECURE_ADDONS = 0x094E;
constexpr uint8 REALM_CREATION_FLAG_CONQUEST_OF_AZEROTH = 6;
constexpr uint8 REALM_CREATION_FLAG_WARCRAFT_REBORN = 7;
constexpr uint8 REALM_INFO_ADDONS_ALLOWED = 1;
constexpr uint16 SMSG_GAME_MODE_STATE = 0x090B;

constexpr uint16 SMSG_BANK_PERMISSIONS = 0x0769;

constexpr uint32 MAX_CREATURE_QUERY_BULK_ENTRIES = 50;
constexpr uint32 MAX_ITEM_QUERY_BULK_ENTRIES = 50;
constexpr std::size_t MAX_EXTENSION_REPLIES_PER_UPDATE = 150;
static_assert(MAX_CREATURE_QUERY_BULK_ENTRIES <= MAX_EXTENSION_REPLIES_PER_UPDATE);
static_assert(MAX_ITEM_QUERY_BULK_ENTRIES <= MAX_EXTENSION_REPLIES_PER_UPDATE);
constexpr std::size_t POINT_SPEND_REQUEST_SIZE = sizeof(uint8) + sizeof(uint32);
constexpr uint8 VANITY_CURRENCY_DONATION_POINTS = 2;

constexpr std::array<uint16, 8> QUEUED_EXTENSION_OPCODES = {
    CMSG_APPLY_APPEARANCES, CMSG_SET_CAN_SEE_APPEARANCES,
    CMSG_EXTENSION_INITIALIZED, CMSG_CUSTOM_ASCENSION_POINT_SPEND_REQUEST,
    CMSG_SAVE_APPEARANCE_OUTFIT, CMSG_DELETE_APPEARANCE_OUTFIT,
    CMSG_INSPECT_CHARACTER_ADVANCEMENT, CMSG_ITEM_STAT_QUERY};

constexpr uint16 CMSG_QUERY_VENDORED_ITEM_RECOVERY = 0x05DE;
constexpr uint16 CMSG_RECOVER_VENDORED_ITEM = 0x05E0;
constexpr uint16 CMSG_CLAIM_TUTORIAL_REWARD = 0x06A8;

constexpr std::array<uint16, 3> MODULE_EXTENSION_OPCODES = {
    CMSG_QUERY_VENDORED_ITEM_RECOVERY, CMSG_RECOVER_VENDORED_ITEM, CMSG_CLAIM_TUTORIAL_REWARD};

constexpr std::array<uint16, 6> CORE_EXTENSION_OPCODES = {CMSG_RESET_DUNGEONS, CMSG_PORT_GRAVEYARD,
    CMSG_TAXI_REQUEST_EARLY_LANDING, CMSG_STABLE_DELETE_PET, CMSG_QUERY_INSTANCE_BINDS, CMSG_RESET_INSTANCE};

struct ExtensionOpcodeIdentity {
  uint16 Opcode;
  char const *Name;
};

constexpr ExtensionOpcodeIdentity EXTENSION_OPCODES[] = {
    {CMSG_ANTICHEAT_ALERT, "CMSG_ANTICHEAT_ALERT"},
    {CMSG_CUSTOM_ASCENSION_POINT_SPEND_REQUEST, "CMSG_CUSTOM_ASCENSION_POINT_SPEND_REQUEST"},
    {0x053B, "CMSG_ASCENSIONGM_TICKET_LIST_REQUEST"},
    {CMSG_EXTENSION_INITIALIZED, "CMSG_EXTENSION_INITIALIZED"},
    {0x05A1, "CMSG_CHALLENGE_QUERY_FAILURE"},
    {CMSG_ITEM_QUERY_BULK, "CMSG_ITEM_QUERY_BULK"},
    {CMSG_ITEM_STAT_QUERY, "CMSG_ITEM_STAT_QUERY"},
    {0x0667, "CMSG_SET_LEVEL_SCALING"},
    {SMSG_PATCH_APPEARANCES, "SMSG_PATCH_APPEARANCES"},
    {SMSG_PATCH_ITEM_APPEARANCES, "SMSG_PATCH_ITEM_APPEARANCES"},
    {CMSG_APPLY_APPEARANCES, "CMSG_APPLY_APPEARANCES"},
    {SMSG_APPLY_APPEARANCES_RESULT, "SMSG_APPLY_APPEARANCES_RESULT"},
    {SMSG_APPEARANCE_COLLECTION_INFO, "SMSG_APPEARANCE_COLLECTION_INFO"},
    {SMSG_APPEARANCE_ACTIVE_INFO, "SMSG_APPEARANCE_ACTIVE_INFO"},
    {SMSG_APPEARANCE_ADDED, "SMSG_APPEARANCE_ADDED"},
    {SMSG_APPEARANCE_OUTFIT_INFO, "SMSG_APPEARANCE_OUTFIT_INFO"},
    {SMSG_CAN_SEE_APPEARANCES_INFO, "SMSG_CAN_SEE_APPEARANCES_INFO"},
    {CMSG_SET_CAN_SEE_APPEARANCES, "CMSG_SET_CAN_SEE_APPEARANCES"},
    {0x06B9, "CMSG_QUERY_CUSTOM_STORE"},
    {SMSG_VANITY_COLLECTION_INFO, "SMSG_VANITY_COLLECTION_INFO"},
    {SMSG_VANITY_COLLECTION_ADDED, "SMSG_VANITY_COLLECTION_ADDED"},
    {SMSG_QUERY_CUSTOM_STORE_RESULT, "SMSG_QUERY_CUSTOM_STORE_RESULT"},
    {SMSG_CHARACTER_ADVANCEMENT_ACTIVE_SPEC, "SMSG_CHARACTER_ADVANCEMENT_ACTIVE_SPEC"},
    {SMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES, "SMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES"},
    {CMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES, "CMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES"},
    {0x0741, "CMSG_GOSSIP_CLOSE"},
    {0x0745, "CMSG_PLAYER_POLL_LIST_REQUEST"},
    {SMSG_BANK_PERMISSIONS, "SMSG_BANK_PERMISSIONS"},
    {0x0777, "CMSG_STATISTIC_QUERY"},
    {CMSG_MISSILE_FIRE_POSITION, "CMSG_MISSILE_FIRE_POSITION"},
};

[[nodiscard]] char const *ExtensionOpcodeName(uint16 opcode) {
  for (ExtensionOpcodeIdentity const &entry : EXTENSION_OPCODES)
    if (entry.Opcode == opcode)
      return entry.Name;
  return nullptr;
}

[[nodiscard]] std::string DescribePacketPayload(WorldPacket const &packet,
                                                std::size_t limit = 64) {
  std::size_t const size = packet.size();
  if (!size)
    return "";

  std::size_t count = std::min(size, limit);
  uint8 const *bytes = nullptr;
  try {
    bytes = const_cast<WorldPacket &>(packet).contents();
  } catch (...) {
    return "<unreadable>";
  }
  if (!bytes || !count)
    return "";

  static constexpr char HEX_DIGITS[] = "0123456789ABCDEF";
  std::string description;
  description.reserve(count * 3);
  for (std::size_t i = 0; i < count; ++i) {
    description += HEX_DIGITS[(bytes[i] >> 4) & 0x0F];
    description += HEX_DIGITS[bytes[i] & 0x0F];
    description += ' ';
  }
  if (packet.size() > limit)
    description += "...";
  return description;
}

[[nodiscard]] std::vector<uint32> ReadBulkQueryEntries(WorldPacket const& packet, uint32 maxEntries)
{
    if (packet.size() < sizeof(uint32))
        return {};

    uint32 const count = packet.read<uint32>(0);
    if (!count || count > maxEntries ||
        packet.size() != sizeof(uint32) + std::size_t(count) * sizeof(uint32))
        return {};

    std::vector<uint32> entries;
    entries.reserve(count);
    for (uint32 index = 0; index < count; ++index)
        entries.push_back(packet.read<uint32>(sizeof(uint32) + std::size_t(index) * sizeof(uint32)));
    return entries;
}

[[nodiscard]] std::size_t ExpectedReplies(WorldPacket const& packet)
{
    uint16 const opcode = packet.GetOpcode();
    return opcode == CMSG_ITEM_QUERY_BULK || opcode == CMSG_CREATURE_QUERY_BULK ? packet.read<uint32>(0) : 1;
}

constexpr uint32 SPELL_PYROMANCER_HEAT = 807389;
constexpr uint32 SPELL_PYROMANCER_EMBER = 807533;
constexpr uint32 SPELL_PRIMALIST_EARTHSHAPING = 680441;
constexpr uint32 SPELL_STORMBRINGER_STATIC = 803102;
constexpr uint32 SPELL_STORMBRINGER_CHARGED_CONDUIT = 803790;
constexpr uint32 SPELL_STORMBRINGER_WRATH_OF_ALAKIR = 300834;
constexpr uint32 SPELL_STORMBRINGER_UNSHACKLE_EXTENSION = 300835;
constexpr uint32 SPELL_BLOODMAGE_THIRST_PASSIVE = 92112;
constexpr uint32 SPELL_BLOODMAGE_THIRST = 706613;
constexpr uint32 BLOODMAGE_FLESHWEAVER_SPEC = 25;
constexpr uint32 SPELL_REAPER_REAPED_SOUL = 500363;
constexpr uint32 SPELL_REAPER_SOUL_INFUSION = 803031;
constexpr uint32 SPELL_REAPER_SOUL_INFUSION_REMOVER = 561290;
constexpr uint32 SPELL_REAPER_SOUL_FRAGMENT = 805077;
constexpr uint32 SPELL_REAPER_GENERATE_SOUL = 805078;
constexpr uint32 SPELL_REAPER_SCYTHE_RUSH = 500359;
constexpr uint32 SPELL_REAPER_SCYTHE_RUSH_MARKER = 500377;
constexpr uint32 SPELL_REAPER_HARVEST_TIME = 803995;
constexpr char ASCENSION_ACTIVE_SPEC_SETTING[] = "core.ascension_active_spec";
constexpr char ASCENSION_TALENT_BUILD_SETTING_PREFIX[] = "core.ascension_build.";
constexpr char ASCENSION_RESET_CREDITS_SETTING[] = "core.ascension_reset_credits";

enum CompanionLoot : uint32
{
    APPEARANCE_CATEGORY_COMPANION_LOOT = 38,
    APPEARANCE_CATEGORY_COMPANION_SKINNING = 61,
    APPEARANCE_LOOT_TRANSFIGURATOR = 47520,
    APPEARANCE_SKIN_PEELER = 639807,
    SPELL_LOOT_TRANSFIGURATOR = 84419,
    SPELL_SKIN_PEELER = 92864
};

constexpr uint8 PYROMANCER_HEAT_PER_EMBER = 100;
constexpr uint8 REAPER_SOUL_FRAGMENT_COST = 3;

constexpr std::array<uint32, 12> REAPER_ALL_SOUL_CONSUMERS =
{{
    500483,
    500484,
    500576,
    500631,
    572341, 572342, 573316, 573317, 573318, 573319, 573321, 573322
}};

constexpr std::array<std::pair<uint32, uint32>, 1> REAPER_ONE_SOUL_CONSUMERS =
{{
    {500361, 500361}
}};

constexpr std::size_t APPEARANCE_CATEGORY_COUNT = 69;
constexpr uint32 APPEARANCE_CATEGORY_AMMUNITION = 32;
constexpr uint32 APPEARANCE_CATEGORY_SHADOWHOUND = 68;
constexpr uint32 APPEARANCE_CATEGORY_TAMED_BEAST = 33;
constexpr uint32 TAME_BEAST_SPELL = 1515;
constexpr std::array<uint32, 3> CALL_PET_SPELLS = { 883, 574302, 1100883 };

AscensionCollectionModels::Entry const* FindCollectionModel(uint32 creatureId);
constexpr std::size_t MAX_APPEARANCE_SNAPSHOT_ENTRIES = 65536;
constexpr std::size_t APPEARANCE_ADDS_PER_BATCH = 16;
constexpr uint32 APPEARANCE_ADD_BATCH_INTERVAL_MS = 100;
constexpr uint32 APPEARANCE_ADD_INITIAL_DELAY_MS = 500;
constexpr uint32 APPEARANCE_LOGIN_RESYNC_DELAY_MS = 3000;
constexpr std::size_t MAX_QUEUED_EXTENSION_PACKETS = 64;
constexpr uint32 VANITY_CATEGORY_MOUNTS = 0x04000000;
constexpr uint32 VANITY_CATEGORY_COMPANIONS = 0x08000000;
constexpr uint32 ITEM_WONDROUS_WISDOMBALL = 101169;
constexpr uint32 ITEM_FIX_O_TRON_5000 = 97330;
constexpr std::size_t COMPANION_SPELLS_PER_BATCH = 4;
constexpr uint32 COMPANION_SPELL_BATCH_INTERVAL_MS = 200;

enum AscensionItems : uint32
{
    ITEM_HEARTWOOD_KEY = 1041710
};

enum AscensionRidingSpells : uint32
{
    SPELL_RIDING_APPRENTICE = 33388,
    SPELL_RIDING_JOURNEYMAN = 33391,
    SPELL_RIDING_EXPERT = 34090,
    SPELL_RIDING_ARTISAN = 34091,
    SPELL_COLD_WEATHER_FLYING = 54197
};

enum class AscensionCompatConfig {
  ENABLED,
  LOG_CONSUMED_PACKETS,
  FIRST_EXTENSION_OPCODE,
  LAST_EXTENSION_OPCODE,
  AUTO_COLLECT_APPEARANCES,
  UNLOCK_LOCAL_APPEARANCE_CATALOG,
  APPEARANCE_CATALOG_PER_CATEGORY,
  UNLOCK_ALL_VANITY,
  REALM_TYPE,
  CLASS_MODEL,
  ALLOW_LEARNED_SPELL_DELIVERY,
  LEARN_OWNED_COMPANIONS,
  MAX_RIDING_FROM_START,
  QUEST_LEVEL_SCALING,
  AUTO_PROGRESSION,
  GAME_MODE_MASK,
  CLIENT_BOOLEAN_CONFIGS,
  CLIENT_INTEGER_CONFIGS,
  SEND_DISPLAY_PATCHES,
  CLIENT_DBC_DIRECTORY,
  COLLECTIONS_FOR_BOTS,
  RANDOM_BOT_ACCOUNT_PREFIX,

  NUM_CONFIGS,
};

class AscensionCompatConfigData
    : public ConfigValueCache<AscensionCompatConfig> {
public:
  AscensionCompatConfigData()
      : ConfigValueCache(AscensionCompatConfig::NUM_CONFIGS) {}

  void BuildConfigCache() override {
    SetConfigValue<bool>(AscensionCompatConfig::ENABLED,
                         "CoA.Enable", true);
    SetConfigValue<bool>(AscensionCompatConfig::LOG_CONSUMED_PACKETS,
                         "CoA.LogConsumedPackets", true);
    SetConfigValue<uint32>(AscensionCompatConfig::FIRST_EXTENSION_OPCODE,
                           "CoA.FirstExtensionOpcode", 0x051F);
    SetConfigValue<uint32>(AscensionCompatConfig::LAST_EXTENSION_OPCODE,
                           "CoA.LastExtensionOpcode", 0x09D3);
    SetConfigValue<bool>(AscensionCompatConfig::AUTO_COLLECT_APPEARANCES,
                         "CoA.AutoCollectAppearances", true);
    SetConfigValue<bool>(
        AscensionCompatConfig::UNLOCK_LOCAL_APPEARANCE_CATALOG,
        "CoA.UnlockLocalAppearanceCatalog", true);
    SetConfigValue<uint32>(
        AscensionCompatConfig::APPEARANCE_CATALOG_PER_CATEGORY,
        "CoA.AppearanceCatalogPerCategory", 500);
    SetConfigValue<bool>(AscensionCompatConfig::UNLOCK_ALL_VANITY,
                         "CoA.UnlockAllVanity", true);
    SetConfigValue<std::string>(AscensionCompatConfig::REALM_TYPE,
                                "CoA.RealmType", "live");
    SetConfigValue<std::string>(AscensionCompatConfig::CLASS_MODEL,
                                "CoA.ClassModel", "coa");
    SetConfigValue<uint32>(AscensionCompatConfig::GAME_MODE_MASK, "CoA.GameModeMask", 0);
    SetConfigValue<std::string>(AscensionCompatConfig::CLIENT_BOOLEAN_CONFIGS, "CoA.ClientBooleanConfigs", "");
    SetConfigValue<std::string>(AscensionCompatConfig::CLIENT_INTEGER_CONFIGS, "CoA.ClientIntegerConfigs", "");
    SetConfigValue<bool>(AscensionCompatConfig::ALLOW_LEARNED_SPELL_DELIVERY,
                         "CoA.AllowLearnedSpellDelivery", true);
    SetConfigValue<bool>(AscensionCompatConfig::LEARN_OWNED_COMPANIONS,
                         "CoA.LearnOwnedCompanions", true);
    SetConfigValue<bool>(AscensionCompatConfig::MAX_RIDING_FROM_START,
                         "CoA.MaxRidingFromStart", true);
    SetConfigValue<bool>(AscensionCompatConfig::QUEST_LEVEL_SCALING,
                         "CoA.QuestLevelScaling", true);
    SetConfigValue<uint32>(AscensionCompatConfig::COLLECTIONS_FOR_BOTS,
                           "CoA.CollectionsForBots", 0);
    SetConfigValue<std::string>(AscensionCompatConfig::RANDOM_BOT_ACCOUNT_PREFIX,
                                "CoA.RandomBotAccountPrefix", "rndbot");
    SetConfigValue<bool>(AscensionCompatConfig::AUTO_PROGRESSION,
                         "CoA.AutoProgression", false);
    SetConfigValue<bool>(AscensionCompatConfig::SEND_DISPLAY_PATCHES,
                         "CoA.SendDisplayPatches", true);
    SetConfigValue<std::string>(AscensionCompatConfig::CLIENT_DBC_DIRECTORY,
                                "CoA.ClientDbcDirectory", "");
  }
};

AscensionCompatConfigData ascensionCompatConfig;

struct AppearanceInfo {
  uint32 SourceItem = 0;
  uint32 PrimaryCategory = 0;
  uint32 SecondaryCategory = 0;
  uint32 TertiaryCategory = 0;
  uint32 EnchantId = 0;
  uint32 CosmeticSpell = 0;
  uint32 CreatureDisplay = 0;
  uint32 CreatureEntry = 0;
};

struct VanityInfo {
  uint32 LearnedSpell = 0;
  uint32 Flags = 0;
  uint32 CategoryMask = 0;
};

struct PlayerCollectionState {
  uint32 AccountId = 0;
  std::unordered_set<uint32> CollectedAppearances;
  std::unordered_set<uint32> OwnedVanityItems;
  std::array<uint32, APPEARANCE_CATEGORY_COUNT> ActiveAppearances{};
  std::map<std::string, std::vector<uint32>> Outfits;
  std::vector<uint32> PendingAppearanceAdds;
  std::size_t NextPendingAppearanceAdd = 0;
  uint32 AppearanceAddTimer = 0;
  uint32 LoginResyncTimer = 0;
  std::vector<uint32> PendingCompanionSpells;
  std::size_t NextCompanionSpell = 0;
  uint32 CompanionSpellTimer = 0;
  uint32 CompanionLootTimer = 0;
  uint32 CompanionSkinningTimer = 0;
  uint32 CosmeticTimer = 0;
  std::unordered_set<uint32> AppliedCosmeticSpells;
  bool CanSeeItemAppearances = true;
  bool CanSeeSpellAppearances = true;
};

uint8 AppearanceCategoryForEquipmentSlot(uint8 slot) {
  switch (slot) {
  case EQUIPMENT_SLOT_HEAD:
    return 1;
  case EQUIPMENT_SLOT_SHOULDERS:
    return 2;
  case EQUIPMENT_SLOT_BACK:
    return 3;
  case EQUIPMENT_SLOT_CHEST:
    return 4;
  case EQUIPMENT_SLOT_TABARD:
    return 5;
  case EQUIPMENT_SLOT_BODY:
    return 6;
  case EQUIPMENT_SLOT_WRISTS:
    return 7;
  case EQUIPMENT_SLOT_HANDS:
    return 8;
  case EQUIPMENT_SLOT_WAIST:
    return 9;
  case EQUIPMENT_SLOT_LEGS:
    return 10;
  case EQUIPMENT_SLOT_FEET:
    return 11;
  case EQUIPMENT_SLOT_RANGED:
    return 12;
  case EQUIPMENT_SLOT_MAINHAND:
    return 13;
  case EQUIPMENT_SLOT_OFFHAND:
    return 14;
  default:
    return 0;
  }
}

uint8 WeaponEffectCategoryForEquipmentSlot(uint8 slot) {
  switch (slot) {
  case EQUIPMENT_SLOT_MAINHAND:
    return 15;
  case EQUIPMENT_SLOT_OFFHAND:
    return 16;
  default:
    return 0;
  }
}

bool IsAscensionCustomClass(Player const *player) {
  uint8 playerClass = player->getClass();
  return playerClass >= CLASS_BARBARIAN && playerClass <= CLASS_SPIRIT_MAGE;
}

bool ReceivesClientRequests(Player const *player) {
  return !player->GetSession()->IsBot();
}

enum LegacyQuestSpells : uint32
{
    QuestStoneskinTotem = 8073,
    QuestPathOfDefense = 8121,
    QuestSummonVoidwalker = 11520,
    QuestBearForm = 19179,
    LegacyDefensiveStance = 1100071,
    LegacyTaunt = 1100355,
    LegacySunderArmor = 1107386,
    LegacyStoneskinTotem = 1108071,
    LegacySummonVoidwalker = 1100697,
    LegacyBearForm = 1105487,
    LegacyGrowl = 1106795,
    LegacyMaul = 1106807
};

struct LegacyQuestReward
{
    uint32 Wrapper;
    std::array<uint32, MAX_SPELL_EFFECTS> Spells;
};

constexpr std::array<LegacyQuestReward, 4> LegacyQuestRewards = {{
    {QuestStoneskinTotem, {LegacyStoneskinTotem, 0, 0}},
    {QuestPathOfDefense, {LegacyDefensiveStance, LegacySunderArmor, LegacyTaunt}},
    {QuestSummonVoidwalker, {LegacySummonVoidwalker, 0, 0}},
    {QuestBearForm, {LegacyBearForm, LegacyGrowl, LegacyMaul}}
}};

LegacyQuestReward const* GetLegacyQuestReward(uint32 wrapper)
{
    for (LegacyQuestReward const& reward : LegacyQuestRewards)
        if (reward.Wrapper == wrapper)
            return &reward;
    return nullptr;
}

void RemoveLegacyQuestSpells(Player* player)
{
    if (!IsAscensionCustomClass(player))
        return;

    for (uint32 questId : player->getRewardedQuests())
        if (Quest const* quest = sObjectMgr->GetQuestTemplate(questId))
            if (LegacyQuestReward const* reward = GetLegacyQuestReward(quest->GetRewSpellCast()))
                for (uint32 spell : reward->Spells)
                    if (spell)
                        player->removeSpell(spell, SPEC_MASK_ALL, false);
}

AscensionCompatData::StarterKit const *GetStarterKit(uint8 playerClass) {
  auto itr = std::find_if(
      AscensionCompatData::StarterKits.begin(),
      AscensionCompatData::StarterKits.end(),
      [playerClass](AscensionCompatData::StarterKit const &kit) {
        return kit.ClassId == playerClass;
      });
  return itr == AscensionCompatData::StarterKits.end() ? nullptr : &*itr;
}

std::vector<uint32> GetAscensionRacialSpells(Player const* player)
{
    std::vector<uint32> spells;
    for (auto const& skill : AscensionRacialAbilities::Skills)
        if (skill.RaceId == player->getRace())
            for (SkillLineAbilityEntry const* ability : GetSkillLineAbilitiesBySkillLine(skill.SkillId))
                if (AscensionRacialAbilities::CanLearn(*ability, player->getRace(), player->getClass()))
                    spells.push_back(ability->Spell);

    std::sort(spells.begin(), spells.end());
    spells.erase(std::unique(spells.begin(), spells.end()), spells.end());
    return spells;
}

struct FelswornRiftGrant
{
    uint32 SpellId;
    uint8 RequiredLevel;
};

constexpr std::array<FelswornRiftGrant, 3> FelswornHordeCapitalRifts =
{{
    {535598, 26},
    {535599, 30},
    {535600, 36}
}};

bool CanGrantAscensionRacialSpell(Player const* player, uint32 spellId)
{
    if (!AscensionFelsworn::CanLearnRift(player, spellId))
        return false;
    bool racial = false;
    auto const bounds = sSpellMgr->GetSkillLineAbilityMapBounds(spellId);
    for (auto itr = bounds.first; itr != bounds.second; ++itr)
        if (AscensionRacialAbilities::GetRace(itr->second->SkillLine))
        {
            racial = true;
            if (AscensionRacialAbilities::CanLearn(*itr->second, player->getRace(), player->getClass()))
                return true;
        }
    return !racial;
}

std::vector<AscensionSpecializationSwitchGuard>& SpecializationSwitchGuards()
{
    static std::vector<AscensionSpecializationSwitchGuard> guards;
    return guards;
}

std::string SpecializationSwitchRefusal(Player* player, uint32 activeSpecializationId,
                                        uint32 requestedSpecializationId)
{
    for (AscensionSpecializationSwitchGuard const& guard : SpecializationSwitchGuards())
        if (std::string refusal = guard(player, activeSpecializationId, requestedSpecializationId);
            !refusal.empty())
            return refusal;
    return {};
}

struct UpdateEntriesRefusal
{
    char const* Result = "CA_UPDATE_ENTRIES_UNKNOWN";
    char const* Learn = "";
    uint32 Entry = 0;
    uint32 Rank = 0;
    std::string Detail;
    bool Announce = false;
};

UpdateEntriesRefusal SpecializationSwitchRefused(uint32 specializationId, std::string reason)
{
    if (!reason.empty())
        return { "CA_UPDATE_ENTRIES_NOT_TRAVERSIBLE", "CA_LEARN_MODE_RESTRICTED", 0, 0, std::move(reason), true };
    return { "CA_UPDATE_ENTRIES_BAD_ENTRY", "CA_LEARN_WRONG_CLASS", 0, 0,
             Acore::StringFormat("Specialization {} is not valid for your custom class.", specializationId) };
}

class AscensionClassService {
public:
  static AscensionClassService &Instance() {
    static AscensionClassService instance;
    return instance;
  }

  uint32 SynchronizeProgression(Player *player, bool explicitRequest = false) {
    if (!IsAscensionCustomClass(player))
      return 0;

    uint32 const activeSpec = GetActiveSpecialization(player);
    AscensionClassTuning::Synchronize(player, activeSpec, true);
    auto const racialSpells = GetAscensionRacialSpells(player);
    auto selectedTalentOwns = [player, activeSpec](uint32 spellId)
    {
      uint32 const root = sSpellMgr->GetFirstSpellInChain(spellId);
      return std::any_of(AscensionCompatData::CoATalentEntries.begin(),
          AscensionCompatData::CoATalentEntries.end(), [player, activeSpec, spellId, root](auto const& entry)
          {
            if (entry.ClassId != player->getClass() || (activeSpec && entry.SpecId && entry.SpecId != activeSpec) ||
                entry.RequiredLevel > player->GetLevel() || (!entry.AECost && !entry.TECost))
              return false;
            return std::any_of(entry.SpellIds.begin(), entry.SpellIds.end(),
                [spellId, root](uint32 id) { return id && (id == spellId || id == root); });
          });
    };
    auto currentGrantAllows = [player, activeSpec, &selectedTalentOwns, &racialSpells](uint32 spellId)
    {
      if (!CanGrantAscensionRacialSpell(player, spellId))
        return false;
      bool const observed = std::any_of(AscensionLiveBaseline::Spells.begin(), AscensionLiveBaseline::Spells.end(),
          [player, spellId](auto const& entry)
          { return entry.ClassId == player->getClass() && entry.SpellId == spellId && (!entry.RaceId || entry.RaceId == player->getRace()); });
      bool const proficiency = std::any_of(AscensionLiveBaseline::Proficiencies.begin(), AscensionLiveBaseline::Proficiencies.end(),
          [player, spellId](auto const& entry) { return entry.ClassId == player->getClass() && entry.SpellId == spellId; });
      bool const unresolved = std::any_of(AscensionCompatData::UnresolvedTrainerSpells.begin(), AscensionCompatData::UnresolvedTrainerSpells.end(),
          [player, spellId](auto const& entry) { return entry.ClassId == player->getClass() && entry.SpellId == spellId; });
      bool const automatic = player->GetLevel() > 1 && std::any_of(AscensionCompatData::CoATalentEntries.begin(),
          AscensionCompatData::CoATalentEntries.end(), [player, activeSpec, spellId](auto const& entry)
          {
            return CanGrantAutomaticEntry(player, entry, activeSpec) &&
                   std::find(entry.SpellIds.begin(), entry.SpellIds.end(), spellId) != entry.SpellIds.end();
          });
      return std::binary_search(racialSpells.begin(), racialSpells.end(), spellId) ||
          observed || proficiency || unresolved || automatic || selectedTalentOwns(spellId) ||
          std::any_of(AscensionCompatData::ClassSpells.begin(),
          AscensionCompatData::ClassSpells.end(), [player, spellId](auto const& entry)
          {
            return entry.ClassId == player->getClass() && entry.SpellId == spellId &&
                   entry.RequiredLevel <= player->GetLevel();
          });
    };
    uint32 removed = 0;
    auto reconcile = [player, &currentGrantAllows, &removed](auto const& entries)
    {
      for (auto const& entry : entries)
        if (entry.ClassId == player->getClass() && player->HasSpell(entry.SpellId) &&
            !currentGrantAllows(entry.SpellId))
        {
          player->removeSpell(entry.SpellId, SPEC_MASK_ALL, false);
          ++removed;
        }
    };
    reconcile(AscensionCompatData::LegacyGeneratedClassSpells);
    reconcile(AscensionCompatData::ClassSpells);
    if (player->getClass() == CLASS_DEMON_HUNTER)
      for (FelswornRiftGrant const& rift : FelswornHordeCapitalRifts)
        if (rift.RequiredLevel > player->GetLevel() && player->HasSpell(rift.SpellId))
        {
          player->removeSpell(rift.SpellId, SPEC_MASK_ALL, false);
          ++removed;
        }
    if (removed)
      LOG_INFO("coa", "Reconciled {} proven class grants for {} against live level {}",
          removed, player->GetName(), uint32(player->GetLevel()));
    uint32 learned = 0;
    bool const botCannotBuyBooksOfAscension = player->GetSession() && player->GetSession()->IsBot();
    bool const automaticProgression =
        explicitRequest || ascensionCompatConfig.GetConfigValue<bool>(
                               AscensionCompatConfig::AUTO_PROGRESSION) ||
        botCannotBuyBooksOfAscension;
    for (uint32 spellId : racialSpells)
        if (!player->HasSpell(spellId) && sSpellMgr->GetSpellInfo(spellId))
        {
            player->learnSpell(spellId, false);
            ++learned;
        }
    for (auto const& entry : AscensionLiveBaseline::Spells)
      if (automaticProgression && entry.ClassId == player->getClass() &&
          (!entry.RaceId || entry.RaceId == player->getRace()) &&
          CanGrantAscensionRacialSpell(player, entry.SpellId) &&
          !player->HasSpell(entry.SpellId) && sSpellMgr->GetSpellInfo(entry.SpellId))
      {
        player->learnSpell(entry.SpellId, false);
        ++learned;
      }
    for (AscensionCompatData::ClassSpell const &progressionSpell :
         AscensionCompatData::ClassSpells) {
      if (!automaticProgression ||
          progressionSpell.ClassId != player->getClass() ||
          progressionSpell.RequiredLevel > player->GetLevel() ||
          !CanGrantAscensionRacialSpell(player, progressionSpell.SpellId) ||
          player->HasSpell(progressionSpell.SpellId))
        continue;

      if (!sSpellMgr->GetSpellInfo(progressionSpell.SpellId))
      {
        LOG_ERROR("coa",
                  "Cannot teach missing Ascension class spell {} to {}",
                  progressionSpell.SpellId, player->GetName());
        continue;
      }

      player->learnSpell(progressionSpell.SpellId, false);
      ++learned;
    }
    if (player->getClass() == CLASS_DEMON_HUNTER)
      for (FelswornRiftGrant const& rift : FelswornHordeCapitalRifts)
        if (automaticProgression && rift.RequiredLevel <= player->GetLevel() &&
            CanGrantAscensionRacialSpell(player, rift.SpellId) &&
            !player->HasSpell(rift.SpellId) && sSpellMgr->GetSpellInfo(rift.SpellId))
        {
          player->learnSpell(rift.SpellId, false);
          ++learned;
        }

    ReconcileRunemasterFists(player, activeSpec);
    learned += SynchronizeAutomaticTalents(player, GetActiveSpecialization(player));
    for (AscensionProgression::Rank const& rank : AscensionProgression::Ranks)
    {
        if (!automaticProgression || rank.ClassId != player->getClass() ||
            rank.RequiredLevel > player->GetLevel() ||
            !player->HasSpell(rank.FirstSpellId) || player->HasSpell(rank.SpellId) ||
            (rank.FirstSpellId == 800792 && player->HasAura(520937)))
            continue;

        if (sSpellMgr->GetSpellInfo(rank.SpellId))
        {
            player->learnSpell(rank.SpellId, false);
            ++learned;
        }
    }

    learned += SynchronizeTaughtAbilities(player);
    learned += SynchronizeTalentReplacements(player);
    RemoveAscensionPrimalistWeapons(player);
    SynchronizeAscensionRunemasterEchoes(player, GetActiveSpecialization(player));

    if (learned)
    {
      ChatHandler(player->GetSession())
          .PSendSysMessage("Restored {} Ascension class abilities.", learned);
      LOG_INFO("coa",
               "Restored {} progression spells for {} (class {}, level {})",
               learned, player->GetName(), uint32(player->getClass()),
               uint32(player->GetLevel()));
    }

    return learned;
  }

    bool AffectsTaughtAbilities(uint32 spellId) const
    {
        return std::any_of(AscensionCompatData::TaughtAbilities.begin(),
            AscensionCompatData::TaughtAbilities.end(),
            [spellId](auto const& entry) { return entry.ParentSpellId == spellId; });
    }

    uint32 SynchronizeTaughtAbilities(Player* player, bool beforeMap = false)
    {
        if (!IsAscensionCustomClass(player))
            return 0;

        uint32 const specializationId = GetActiveSpecialization(player);
        uint32 learned = 0;
        for (auto const& entry : AscensionCompatData::TaughtAbilities)
        {
            if (entry.ClassId != player->getClass())
                continue;

            bool const allowed = specializationId == entry.SpecId &&
                player->GetLevel() >= entry.RequiredLevel && player->HasSpell(entry.ParentSpellId);
            if (!allowed)
            {
                player->removeSpell(entry.SpellId, SPEC_MASK_ALL, true);
                continue;
            }

            auto const& spells = player->GetSpellMap();
            if (spells.find(entry.SpellId) != spells.end() || !sSpellMgr->GetSpellInfo(entry.SpellId))
                continue;

            player->learnSpell(entry.SpellId, true);
            if (player->HasSpell(entry.SpellId))
                ++learned;
        }
        if (!beforeMap && player->getClass() == CLASS_SON_OF_ARUGAL)
        {
            bool const dualWield = player->HasSpell(674);
            if (player->CanDualWield() != dualWield)
            {
                player->SetCanDualWield(dualWield);
                if (!dualWield)
                    player->AutoUnequipOffhandIfNeed();
            }
        }
        return learned;
    }

    bool AffectsTalentReplacements(uint32 spellId) const
    {
        uint32 const root = sSpellMgr->GetFirstSpellInChain(spellId);
        return std::any_of(AscensionCompatData::TalentReplacements.begin(),
            AscensionCompatData::TalentReplacements.end(), [spellId, root](auto const& entry)
            {
                return entry.ParentSpellId == spellId || entry.OriginalSpellId == root;
            });
    }

    uint32 SynchronizeTalentReplacements(Player* player)
    {
        if (!IsAscensionCustomClass(player))
            return 0;

        uint32 const specializationId = GetActiveSpecialization(player);
        std::set<uint32> candidates;
        std::map<uint32, uint32> replacements;
        for (auto const& entry : AscensionCompatData::TalentReplacements)
        {
            if (entry.ClassId != player->getClass())
                continue;

            uint32 replacement = 0;
            Aura const* aura = entry.RequiresAura ? player->GetAura(entry.ParentSpellId, player->GetGUID()) : nullptr;
            bool const parentOwned = entry.RequiresAura ? aura && !aura->IsRemoved() :
                player->HasSpell(entry.ParentSpellId);
            bool const allowed = (!entry.SpecId || specializationId == entry.SpecId) && parentOwned;
            for (auto const& rank : entry.Ranks)
            {
                if (!rank.SpellId)
                    continue;
                candidates.insert(rank.SpellId);
                if (allowed && rank.RequiredLevel <= player->GetLevel() && sSpellMgr->GetSpellInfo(rank.SpellId))
                    replacement = rank.SpellId;
            }

            for (auto const& [id, spell] : player->GetSpellMap())
            {
                if (sSpellMgr->GetFirstSpellInChain(id) != entry.OriginalSpellId)
                    continue;
                replacements.try_emplace(id, 0);
                if (replacement && player->HasActiveSpell(id))
                    replacements[id] = replacement;
            }
        }

        std::set<uint32> desired;
        for (auto const& [id, replacement] : replacements)
        {
            if (replacement)
                desired.insert(replacement);
            if (player->GetTemporarySpellReplacement(id) != replacement)
                player->SetTemporarySpellReplacement(id, 0);
        }

        for (uint32 id : candidates)
        {
            if (desired.count(id))
                continue;
            bool const neededByHigherRank = std::any_of(desired.begin(), desired.end(), [id](uint32 rank)
            {
                return sSpellMgr->GetFirstSpellInChain(id) == sSpellMgr->GetFirstSpellInChain(rank) &&
                    sSpellMgr->GetSpellRank(id) < sSpellMgr->GetSpellRank(rank);
            });
            if (!neededByHigherRank)
                player->removeSpell(id, SPEC_MASK_ALL, true);
        }

        uint32 learned = 0;
        for (uint32 id : desired)
        {
            if (player->GetSpellMap().find(id) == player->GetSpellMap().end())
            {
                player->learnSpellWithoutAnnouncement(id);
                if (player->HasSpell(id))
                    ++learned;
            }
        }
        for (auto const& [id, replacement] : replacements)
            player->SetTemporarySpellReplacement(id, replacement);
        return learned;
    }

  bool AffectsProficiencies(uint32 spellId) const {
    bool const isProficiency = std::any_of(
        AscensionCompatData::ProficiencyDefinitions.begin(),
        AscensionCompatData::ProficiencyDefinitions.end(),
        [spellId](AscensionCompatData::ProficiencyDefinition const &entry) {
          return entry.SpellId == spellId;
        });
    if (isProficiency)
      return true;

    return std::any_of(
        AscensionCompatData::TalentProficiencies.begin(),
        AscensionCompatData::TalentProficiencies.end(),
        [spellId](AscensionCompatData::TalentProficiency const &entry) {
          return entry.TalentSpellId == spellId;
        });
  }

  void SynchronizeProficiencies(Player *player) {
    if (!IsAscensionCustomClass(player))
      return;

    uint32 const guid = player->GetGUID().GetCounter();
    {
      std::lock_guard<std::mutex> lock(_stateLock);
      if (!_proficiencySynchronizations.insert(guid).second)
        return;
    }

    auto isAllowed = [player](uint32 proficiencySpellId) {
      bool const isObserved = std::any_of(
          AscensionLiveBaseline::Proficiencies.begin(), AscensionLiveBaseline::Proficiencies.end(),
          [player, proficiencySpellId](AscensionLiveBaseline::Proficiency const& entry)
          {
              return entry.ClassId == player->getClass() && entry.SpellId == proficiencySpellId;
          });
      if (isObserved)
        return true;

      return std::any_of(
          AscensionCompatData::TalentProficiencies.begin(),
          AscensionCompatData::TalentProficiencies.end(),
          [player, proficiencySpellId](
              AscensionCompatData::TalentProficiency const &entry) {
            return entry.ClassId == player->getClass() &&
                   entry.ProficiencySpellId == proficiencySpellId &&
                   player->HasSpell(entry.TalentSpellId);
          });
    };

    uint32 learned = 0;
    uint32 removed = 0;
    for (AscensionCompatData::ProficiencyDefinition const &definition :
         AscensionCompatData::ProficiencyDefinitions) {
      bool const allowed = isAllowed(definition.SpellId);
      if (allowed)
      {
        if (!player->HasSpell(definition.SpellId))
        {
          if (sSpellMgr->GetSpellInfo(definition.SpellId))
          {
            player->learnSpell(definition.SpellId, false);
            ++learned;
          }
          else
          {
            LOG_ERROR("coa",
                      "Cannot teach missing proficiency spell {} to {}",
                      definition.SpellId, player->GetName());
          }
        }

        uint16 const maximum = definition.ScalesWithLevel
                                   ? player->GetMaxSkillValueForLevel()
                                   : 1;
        uint16 const step = player->HasSkill(definition.SkillId)
                                ? player->GetSkillStep(definition.SkillId)
                                : 0;
        player->SetSkill(definition.SkillId, step, maximum, maximum);
        continue;
      }

      if (player->HasSpell(definition.SpellId))
      {
        player->removeSpell(definition.SpellId, SPEC_MASK_ALL, false);
        ++removed;
      }
      if (player->HasSkill(definition.SkillId))
        player->SetSkill(definition.SkillId, 0, 0, 0);
    }

    for (uint16 skill : std::array<uint16, 2>{SKILL_DEFENSE, SKILL_UNARMED})
      if (player->HasSkill(skill))
      {
        uint16 const maximum = player->GetMaxSkillValueForLevel();
        player->SetSkill(skill, player->GetSkillStep(skill), maximum, maximum);
        if (skill == SKILL_DEFENSE)
          player->UpdateDefenseBonusesMod();
      }

    {
      std::lock_guard<std::mutex> lock(_stateLock);
      _proficiencySynchronizations.erase(guid);
    }
    if (learned || removed)
    {
      LOG_INFO("coa",
               "Synchronized proficiencies for {} (class {}, level {}): "
               "learned {}, removed {}",
               player->GetName(), uint32(player->getClass()),
               uint32(player->GetLevel()), learned, removed);
    }
  }

  bool InitializeLiveBaseline(Player* player)
  {
    if (!IsAscensionCustomClass(player) || player->IsInWorld())
      return false;

    for (uint32 spellId : GetAscensionRacialSpells(player))
    {
      if (!sSpellMgr->GetSpellInfo(spellId))
        return false;
      if (!player->HasSpell(spellId))
        player->addSpell(spellId, SPEC_MASK_ALL, true);
    }
    for (auto const& entry : AscensionLiveBaseline::Spells)
    {
      if (entry.ClassId != player->getClass() || (entry.RaceId && entry.RaceId != player->getRace()))
        continue;
      if (!CanGrantAscensionRacialSpell(player, entry.SpellId))
      {
        if (player->HasSpell(entry.SpellId))
          player->removeSpell(entry.SpellId, SPEC_MASK_ALL, false);
        continue;
      }
      if (!sSpellMgr->GetSpellInfo(entry.SpellId))
        return false;
      player->addSpell(entry.SpellId, SPEC_MASK_ALL, true);
    }
    for (auto const& entry : AscensionLiveBaseline::Proficiencies)
    {
      if (entry.ClassId != player->getClass())
        continue;
      if (!sSpellMgr->GetSpellInfo(entry.SpellId))
        return false;
      player->addSpell(entry.SpellId, SPEC_MASK_ALL, true);
    }
    for (auto const& entry : AscensionLiveBaseline::Skills)
    {
      if (entry.ClassId != player->getClass())
        continue;
      if (!sSkillLineStore.LookupEntry(entry.SkillId))
        return false;
      bool const weapon = std::any_of(AscensionCompatData::ProficiencyDefinitions.begin(),
          AscensionCompatData::ProficiencyDefinitions.end(), [&entry](auto const& definition)
          { return definition.SkillId == entry.SkillId && definition.ScalesWithLevel; });
      if (entry.SkillId == SKILL_UNARMED)
        continue;
      uint16 const maximum = weapon ? player->GetMaxSkillValueForLevel() : entry.Maximum;
      uint16 const value = weapon ? maximum : entry.Rank;
      player->SetSkill(entry.SkillId, 0, value, maximum);
    }
    return true;
  }

  bool InitializeLiveStarterKit(Player* player)
  {
    if (!IsAscensionCustomClass(player) || player->IsInWorld())
      return false;

    constexpr uint32 liveStarterRevision = 20260903;
    char const* const liveSetting = "core.ascension_starter_live";
    if (player->GetPlayerSetting(liveSetting, 0).value == liveStarterRevision)
      return true;

    for (uint8 slot = EQUIPMENT_SLOT_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
      if (player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
      {
        LOG_ERROR("coa", "Refused non-empty live starter initialization for class {}", uint32(player->getClass()));
        return false;
      }

    uint32 entries = 0;
    std::unordered_set<uint16> positions;
    for (AscensionCompatData::LiveStarterItem const& entry : AscensionCompatData::LiveStarterItems)
    {
      if (entry.ClassId != player->getClass())
        continue;

      bool const equipped = entry.Slot < EQUIPMENT_SLOT_END;
      uint16 const position = uint16(entry.Bag) << 8 | entry.Slot;
      ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry.ItemId);
      if (entry.Bag != INVENTORY_SLOT_BAG_0 ||
          (!equipped && (entry.Slot < INVENTORY_SLOT_ITEM_START || entry.Slot >= INVENTORY_SLOT_ITEM_END)) ||
          !entry.Count || !item || entry.Count > item->GetMaxStackSize() ||
          (equipped && entry.Count != 1) || !positions.insert(position).second)
      {
        LOG_ERROR("coa", "Invalid live starter class {} item {} slot {} count {}", uint32(entry.ClassId), entry.ItemId, uint32(entry.Slot), entry.Count);
        return false;
      }

      if (equipped)
      {
        uint16 destination = 0;
        InventoryResult const result = player->CanEquipNewItem(entry.Slot, destination, entry.ItemId, false);
        if (result != EQUIP_ERR_OK || destination != position)
        {
          LOG_ERROR("coa", "Cannot equip live starter class {} item {} in slot {}: {}", uint32(entry.ClassId), entry.ItemId, uint32(entry.Slot), uint32(result));
          return false;
        }
      }
      else
      {
        ItemPosCountVec destinations;
        InventoryResult const result = player->CanStoreNewItem(entry.Bag, entry.Slot, destinations, entry.ItemId, entry.Count);
        if (result != EQUIP_ERR_OK || destinations.size() != 1 ||
            destinations.front().pos != position || destinations.front().count != entry.Count)
        {
          LOG_ERROR("coa", "Cannot store live starter class {} item {} in slot {}: {}", uint32(entry.ClassId), entry.ItemId, uint32(entry.Slot), uint32(result));
          return false;
        }
      }
      ++entries;
    }
    if (!entries)
      return false;

    for (AscensionCompatData::LiveStarterItem const& entry : AscensionCompatData::LiveStarterItems)
    {
      if (entry.ClassId != player->getClass())
        continue;

      uint16 const position = uint16(entry.Bag) << 8 | entry.Slot;
      Item* created = nullptr;
      if (entry.Slot < EQUIPMENT_SLOT_END)
      {
        uint16 destination = 0;
        if (player->CanEquipNewItem(entry.Slot, destination, entry.ItemId, false) == EQUIP_ERR_OK && destination == position)
          created = player->EquipNewItem(destination, entry.ItemId, false);
      }
      else
      {
        ItemPosCountVec destinations;
        if (player->CanStoreNewItem(entry.Bag, entry.Slot, destinations, entry.ItemId, entry.Count) == EQUIP_ERR_OK &&
            destinations.size() == 1 && destinations.front().pos == position && destinations.front().count == entry.Count)
          created = player->StoreNewItem(destinations, entry.ItemId, false);
      }
      if (!created || created->GetEntry() != entry.ItemId || created->GetCount() != entry.Count ||
          player->GetItemByPos(entry.Bag, entry.Slot) != created)
      {
        LOG_ERROR("coa", "Failed exact live starter placement for class {} item {} slot {}", uint32(entry.ClassId), entry.ItemId, uint32(entry.Slot));
        return false;
      }
    }

    player->UpdatePlayerSetting(liveSetting, 0, liveStarterRevision);
    player->UpdatePlayerSetting("core.ascension_starter", 0, 1);
    return true;
  }

  bool RepairStarterKit(Player *player, bool force) {
    if (!IsAscensionCustomClass(player))
      return false;

    AscensionCompatData::StarterKit const *kit =
        GetStarterKit(player->getClass());
    if (!kit)
      return false;

    constexpr uint32 starterRevision = 1;
    char const* const setting = "core.ascension_starter";
    if (!force && player->GetPlayerSetting(setting, 0).value >= starterRevision)
      return false;

    uint32 restored = 0;
    bool complete = true;
    for (uint8 index = 0; index < kit->ItemCount; ++index) {
      uint32 itemId = kit->Items[index];
      if (player->HasItemCount(itemId, 1, true))
        continue;

      ItemTemplate const* item = sObjectMgr->GetItemTemplate(itemId);
      if (!item)
      {
        complete = false;
        LOG_ERROR("coa", "Missing starter item template {}", itemId);
        continue;
      }

      uint8 slot = EQUIPMENT_SLOT_END;
      switch (item->InventoryType)
      {
        case INVTYPE_HEAD: slot = EQUIPMENT_SLOT_HEAD; break;
        case INVTYPE_SHOULDERS: slot = EQUIPMENT_SLOT_SHOULDERS; break;
        case INVTYPE_BODY: slot = EQUIPMENT_SLOT_BODY; break;
        case INVTYPE_CHEST:
        case INVTYPE_ROBE: slot = EQUIPMENT_SLOT_CHEST; break;
        case INVTYPE_WAIST: slot = EQUIPMENT_SLOT_WAIST; break;
        case INVTYPE_LEGS: slot = EQUIPMENT_SLOT_LEGS; break;
        case INVTYPE_FEET: slot = EQUIPMENT_SLOT_FEET; break;
        case INVTYPE_WRISTS: slot = EQUIPMENT_SLOT_WRISTS; break;
        case INVTYPE_HANDS: slot = EQUIPMENT_SLOT_HANDS; break;
        case INVTYPE_CLOAK: slot = EQUIPMENT_SLOT_BACK; break;
        case INVTYPE_WEAPON:
        case INVTYPE_2HWEAPON:
        case INVTYPE_WEAPONMAINHAND: slot = EQUIPMENT_SLOT_MAINHAND; break;
        case INVTYPE_SHIELD:
        case INVTYPE_WEAPONOFFHAND:
        case INVTYPE_HOLDABLE: slot = EQUIPMENT_SLOT_OFFHAND; break;
        case INVTYPE_RANGED:
        case INVTYPE_RANGEDRIGHT:
        case INVTYPE_THROWN:
        case INVTYPE_RELIC: slot = EQUIPMENT_SLOT_RANGED; break;
        default: break;
      }
      if (slot == EQUIPMENT_SLOT_END)
      {
        complete = false;
        LOG_ERROR("coa", "Unsupported starter item inventory type for {}", itemId);
        continue;
      }
      if (player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot) ||
          (slot == EQUIPMENT_SLOT_OFFHAND && player->IsTwoHandUsed()) ||
          (item->InventoryType == INVTYPE_2HWEAPON &&
           player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND)))
        continue;

      if (player->StoreNewItemInBestSlots(itemId, 1))
        ++restored;
      else
        complete = false;
    }

    if (!player->HasItemCount(6948, 1, true))
    {
      if (player->StoreNewItemInBestSlots(6948, 1))
        ++restored;
      else
        complete = false;
    }
    if (complete)
      player->UpdatePlayerSetting(setting, 0, starterRevision);

    if (restored)
    {
      ChatHandler(player->GetSession())
          .PSendSysMessage("Restored {} custom-class starter items.",
                           restored);
      LOG_INFO("coa",
               "Restored {} starter items for {} (class {})", restored,
               player->GetName(), uint32(player->getClass()));
    }

    return restored != 0;
  }

  void OnPlayerLogin(Player *player) {
    if (!IsAscensionCustomClass(player))
    {
      QueueCharacterAdvancementState(player);
      return;
    }

    uint32 const specializationId = player->GetPlayerSetting(ASCENSION_ACTIVE_SPEC_SETTING, 0).value;
    if (specializationId)
    {
        std::lock_guard<std::mutex> lock(_stateLock);
        _activeSpecializations[player->GetGUID().GetCounter()] = specializationId;
    }

    if (auto const* stored = player->FindPlayerSettings(SlotSetting(ActiveSlot(player)));
        stored && stored->size() > 1 && (*stored)[0].value && (*stored)[1].value != player->getClass())
      ClearSlots(player);
    player->learnSpell(AscensionWildcard::SPECIALIZATION_SWAP_SPELLS[0]);
    SynchronizeProgression(player);
    SynchronizeProficiencies(player);
    RepairStarterKit(player, false);
    QueueCharacterAdvancementState(player);

    CharacterDatabasePreparedStatement* actionsStmt =
        CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHARACTER_ACTIONS_SPEC);
    actionsStmt->SetData(0, player->GetGUID().GetRawValue());
    actionsStmt->SetData(1, player->GetActiveSpec());

    WorldSession* session = player->GetSession();
    uint32 const slot = ActiveSlot(player);
    session->GetQueryProcessor().AddCallback(CharacterDatabase.AsyncQuery(actionsStmt)
        .WithPreparedCallback([session, slot](PreparedQueryResult result)
        {
            if (Player* owner = session->GetPlayer(); owner && ActiveSlot(owner) == slot)
                owner->LoadActions(result);
        }));
  }

  void PrepareTaughtAbilitiesBeforeMap(Player* player)
  {
    if (!IsAscensionCustomClass(player) || player->IsInWorld() ||
        !player->GetSession()->PlayerLoading())
      return;

    uint32 const specializationId = player->GetPlayerSetting(ASCENSION_ACTIVE_SPEC_SETTING, 0).value;
    if (specializationId)
    {
        std::lock_guard<std::mutex> lock(_stateLock);
        _activeSpecializations[player->GetGUID().GetCounter()] = specializationId;
    }

    if (uint32 const learned = SynchronizeTaughtAbilities(player, true))
    {
        player->SendInitialSpells();
        LOG_INFO("coa",
                 "Prepared {} taught abilities for {} before entering the world",
                 learned, player->GetName());
    }
  }

  static AscensionCompatData::CoATalentEntry const* FindTalentEntry(uint32 entryId)
  {
    auto const& entries = AscensionCompatData::CoATalentEntries;
    auto itr = std::lower_bound(entries.begin(), entries.end(), entryId,
        [](AscensionCompatData::CoATalentEntry const& entry, uint32 id) { return entry.EntryId < id; });
    return itr != entries.end() && itr->EntryId == entryId ? &*itr : nullptr;
  }

  static AscensionCoATalentState::HasSpell SpellbookOf(Player const* player)
  {
    return [player](uint32 spellId) { return player->HasSpell(spellId); };
  }

    static std::set<uint32> const& SharedPaidEntries()
    {
        static std::set<uint32> const shared = []
        {
            std::map<std::pair<uint8, uint32>, uint32> owners;
            std::set<uint32> entries;
            for (auto const& entry : AscensionCompatData::CoATalentEntries)
            {
                if (!entry.AECost && !entry.TECost)
                    continue;
                for (uint32 spellId : entry.SpellIds)
                {
                    if (!spellId)
                        continue;
                    auto const [itr, inserted] = owners.try_emplace({entry.ClassId, spellId}, entry.EntryId);
                    if (!inserted && itr->second != entry.EntryId)
                    {
                        entries.insert(itr->second);
                        entries.insert(entry.EntryId);
                    }
                }
            }
            return entries;
        }();
        return shared;
    }

    static bool SelectedSlot(Player const* player, AscensionCoATalentState::SpecializationSlot& slot)
    {
        auto const* values = player->FindPlayerSettings(SlotSetting(ActiveSlot(player)));
        if (!values)
            return false;
        std::vector<uint32> record;
        record.reserve(values->size());
        for (auto const& value : *values)
            record.push_back(value.value);
        return AscensionCoATalentState::ParseSpecializationSlot(record, slot) &&
            slot.ClassId == player->getClass();
    }

    static uint32 KnownRank(Player const* player, AscensionCompatData::CoATalentEntry const& entry)
    {
        uint32 const learned = AscensionCoATalentState::KnownRank(entry, SpellbookOf(player));
        if (!learned || !SharedPaidEntries().count(entry.EntryId))
            return learned;
        AscensionCoATalentState::SpecializationSlot slot;
        if (!SelectedSlot(player, slot))
            return learned;
        auto const selected = std::find_if(slot.Entries.begin(), slot.Entries.end(), [&entry](auto const& known)
        {
            return known.EntryId == entry.EntryId;
        });
        return selected == slot.Entries.end() ? 0 : std::min(learned, selected->Rank);
    }

    static void SelectSharedEntryRank(Player* player, AscensionCompatData::CoATalentEntry const& entry, uint32 rank)
    {
        if (!SharedPaidEntries().count(entry.EntryId))
            return;
        auto slot = LiveSlot(player, Instance().GetActiveSpecialization(player));
        std::erase_if(slot.Entries, [&entry](auto const& known) { return known.EntryId == entry.EntryId; });
        if (rank)
            slot.Entries.push_back({entry.EntryId, rank});
        StoreSlot(player, ActiveSlot(player), slot);
    }

    static bool SharedSpellStillSelected(Player const* player, AscensionCompatData::CoATalentEntry const& entry,
        uint32 spellId)
    {
        if (!SharedPaidEntries().count(entry.EntryId))
            return false;
        for (uint32 otherId : SharedPaidEntries())
        {
            auto const* other = FindTalentEntry(otherId);
            if (!other || otherId == entry.EntryId || other->ClassId != player->getClass())
                continue;
            uint32 const rank = KnownRank(player, *other);
            for (uint32 index = 0; index < rank; ++index)
                if (other->SpellIds[index] == spellId)
                    return true;
        }
        return false;
    }

  static std::vector<AscensionCoATalentState::KnownEntry> KnownTalentEntries(Player const* player)
  {
    if (AscensionWildcard::IsWildcardHero(player))
      return AscensionWildcard::KnownEntries(player);
    if (AscensionFreepick::HasFreepickBuild(player))
      return AscensionFreepick::KnownEntries(player);
    std::vector<AscensionCoATalentState::KnownEntry> known;
    for (auto const& entry : AscensionCompatData::CoATalentEntries)
        if (entry.ClassId == player->getClass())
            if (uint32 const rank = KnownRank(player, entry))
                known.push_back({entry.EntryId, rank});
    return known;
  }

  void QueueCharacterAdvancementState(Player* player)
  {
    std::lock_guard<std::mutex> lock(_stateLock);
    _advancementPending.insert(player->GetGUID().GetCounter());
    _advancementSent.erase(player->GetGUID().GetCounter());
  }

  void OnPlayerActiveMover(Player* player)
  {
    {
      std::lock_guard<std::mutex> lock(_stateLock);
      if (!_advancementPending.erase(player->GetGUID().GetCounter()))
        return;
      _advancementSent.insert(player->GetGUID().GetCounter());
    }
    SendCharacterAdvancementState(player);
  }

  void SendCharacterAdvancementState(Player* player)
  {
    WorldPacket packet(SMSG_CHARACTER_ADVANCEMENT_ACTIVE_SPEC, sizeof(uint32) * 2);
    bool const wildcard = AscensionWildcard::IsWildcardHero(player);
    packet << (wildcard ? AscensionWildcard::ActiveSpec(player) : ActiveSlot(player))
           << uint32(wildcard || IsAscensionCustomClass(player) || AscensionFreepick::IsFreepickHero(player) ?
        AscensionWildcard::SPECIALIZATION_COUNT : 1);
    player->GetSession()->SendPacket(&packet);

    uint32 const sent = SendKnownTalentEntries(player);
    if (wildcard)
      AscensionWildcard::SignalRollReady(player);
    LOG_INFO("coa",
             "Initialized Character Advancement for {} (class {}, level {}) with {} known entries",
             player->GetName(), uint32(player->getClass()), uint32(player->GetLevel()), sent);
  }

  void SendCharacterAdvancementKnownEntries(Player* player)
  {
    {
      std::lock_guard<std::mutex> lock(_stateLock);
      if (!_advancementSent.count(player->GetGUID().GetCounter()))
        return;
    }
    SendKnownTalentEntries(player);
  }

  void SendInspectResult(Player* player, ObjectGuid guid)
  {
    Player* target = ObjectAccessor::FindConnectedPlayer(guid);
    char const* result = "CA_INSPECT_OK";
    if (!target)
      result = "CA_INSPECT_TARGET_NOT_FOUND";
    else if (!target->IsInWorld())
      result = "CA_INSPECT_NOT_IN_WORLD";
    else if (!player->IsWithinDistInMap(target, std::max(INSPECT_DISTANCE, player->GetVisibilityRange())))
      result = "CA_INSPECT_TARGET_NOT_IN_RANGE";

    WorldPacket packet(SMSG_INSPECT_CHARACTER_ADVANCEMENT_RESULT, 64);
    packet << result;
    if (target && std::string_view(result) == "CA_INSPECT_OK")
    {
      bool const wildcard = AscensionWildcard::IsWildcardHero(target);
      std::vector<uint8> const body = AscensionCoATalentState::InspectSpecsPayload(InspectedSpecs(target));
      packet << guid.GetRawValue() << (wildcard ? AscensionWildcard::ActiveSpec(target) : ActiveSlot(target));
      packet.append(body.data(), body.size());
    }
    player->GetSession()->SendPacket(&packet);
  }

  static std::vector<std::vector<AscensionCoATalentState::KnownEntry>> InspectedSpecs(Player const* target)
  {
    std::vector<std::vector<AscensionCoATalentState::KnownEntry>> specs;
    if (AscensionWildcard::IsWildcardHero(target))
      for (uint32 spec = 0; spec < AscensionWildcard::SPECIALIZATION_COUNT; ++spec)
        specs.push_back(AscensionWildcard::KnownEntries(target, spec));
    else if (IsAscensionCustomClass(target))
      for (uint32 slot = 0; slot < AscensionWildcard::SPECIALIZATION_COUNT; ++slot)
        specs.push_back(SlotEntries(target, slot));
    else
      specs.push_back(KnownTalentEntries(target));
    return specs;
  }

  static AscensionCoATalentState::ResetCredits ResetCreditsOf(Player* player)
  {
    AscensionCoATalentState::ResetCredits credits{};
    for (uint32 index = 0; index < credits.size(); ++index)
      credits[index] = player->GetPlayerSetting(ASCENSION_RESET_CREDITS_SETTING, index).value;
    return credits;
  }

  static void RaiseResetCredit(Player* player, AscensionCoATalentState::ResetCreditType type)
  {
    uint32 const index = uint32(type) - 1;
    player->UpdatePlayerSetting(ASCENSION_RESET_CREDITS_SETTING, index,
                                player->GetPlayerSetting(ASCENSION_RESET_CREDITS_SETTING, index).value + 1);
  }

  static void SendResetCredits(Player* player)
  {
    AscensionCoATalentState::ResetCredits const credits = ResetCreditsOf(player);
    for (uint32 index = 0; index < credits.size(); ++index)
    {
      WorldPacket packet(SMSG_CHARACTER_ADVANCEMENT_CREDITS, 1 + sizeof(uint32));
      packet << uint8(index + 1) << credits[index];
      player->GetSession()->SendPacket(&packet);
    }
  }

  uint32 SendKnownTalentEntries(Player* player)
  {
    SendResetCredits(player);
    std::vector<AscensionCoATalentState::KnownEntry> const known = KnownTalentEntries(player);
    std::vector<uint8> const body = AscensionCoATalentState::KnownEntriesPayload(known);
    WorldPacket packet(SMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES, body.size());
    packet.append(body.data(), body.size());
    player->GetSession()->SendPacket(&packet);
    return uint32(known.size());
  }

  bool SetTalentRank(Player* player, AscensionCompatData::CoATalentEntry const& entry, uint32 rank,
                     std::string& error, bool checkBudget = true)
  {
    uint32 const entryId = entry.EntryId;
    if (entry.ClassId != player->getClass())
    {
      error = Acore::StringFormat("Talent entry {} does not belong to your custom class.", entryId);
      return false;
    }

    uint32 activeSpecialization = GetActiveSpecialization(player);
    if (rank > 0 && entry.SpecId != 0 && !activeSpecialization)
    {
      SwitchSpecialization(player, entry.SpecId);
      activeSpecialization = GetActiveSpecialization(player);
    }

    if (rank > 0 && entry.SpecId != 0 && entry.SpecId != activeSpecialization)
    {
      error = Acore::StringFormat(
          "Talent entry {} belongs to specialization {}, but your active specialization is {}.",
          entryId, uint32(entry.SpecId), activeSpecialization);
      return false;
    }

    if (rank > entry.SpellCount)
    {
      error = Acore::StringFormat("Talent entry {} only has {} rank(s).", entryId, uint32(entry.SpellCount));
      return false;
    }

    uint32 const freeChoiceGroup = GetSelectableFreeGroup(entryId);
    bool const automaticallyGranted = entry.AECost == 0 && entry.TECost == 0 && !freeChoiceGroup;
    if (automaticallyGranted && rank != 0 && rank != entry.SpellCount)
    {
      error = Acore::StringFormat("Progression entry {} must use its full automatic rank.", entryId);
      return false;
    }

    if (rank > 0 && player->GetLevel() < entry.RequiredLevel)
    {
      error = Acore::StringFormat("Talent entry {} requires level {}.", entryId, uint32(entry.RequiredLevel));
      return false;
    }

    if (automaticallyGranted)
    {
      bool const grantable = rank == 0 || CanGrantAutomaticEntry(player, entry, activeSpecialization);
      SynchronizeProgression(player);
      if (!grantable)
      {
        error = Acore::StringFormat("Progression entry {} requires its prerequisite ability.", entryId);
        return false;
      }
      return true;
    }

    uint32 const selectedSpellId = rank > 0 ? entry.SpellIds[rank - 1] : 0;
    if (rank > 0 && (!selectedSpellId || !sSpellMgr->GetSpellInfo(selectedSpellId)))
    {
      error = Acore::StringFormat("Talent entry {} rank {} references a missing server spell.", entryId, rank);
      return false;
    }

    uint32 const currentRank = KnownRank(player, entry);
    if (checkBudget && rank > currentRank && (entry.AECost || entry.TECost))
    {
      uint32 classBudget = 0;
      uint32 specializationBudget = 0;
      if (!TalentBudget(player, classBudget, specializationBudget, error))
        return false;

      bool const classTree = entry.SpecId == 0;
      AscensionCoATalentState::SpentPoints const spent =
          AscensionCoATalentState::Spent(KnownTalentEntries(player));
      uint32 const used = classTree ? spent.AE : spent.TE;
      uint32 const budget = classTree ? classBudget : specializationBudget;
      uint32 const cost = (rank - currentRank) * uint32(classTree ? entry.AECost : entry.TECost);
      if (used + cost > budget)
      {
        error = Acore::StringFormat(
            "Talent entry {} rank {} needs {} {} point(s), but {} of the {} available at level {} are spent.",
            entryId, rank, cost, classTree ? "class" : "specialization", used, budget,
            uint32(player->GetLevel()));
        return false;
      }
    }

    if (rank > 0 && freeChoiceGroup)
    {
      for (auto const& other : AscensionCompatData::CoATalentEntries)
        if (other.ClassId == player->getClass() && other.SpecId == entry.SpecId && other.EntryId != entryId &&
            GetSelectableFreeGroup(other.EntryId) == freeChoiceGroup)
          for (uint32 spellId : other.SpellIds)
            if (spellId && player->HasSpell(spellId))
              player->removeSpell(spellId, SPEC_MASK_ALL, false);
    }

    SelectSharedEntryRank(player, entry, rank);
    for (uint32 spellId : entry.SpellIds)
      if (spellId && player->HasSpell(spellId) && !SharedSpellStillSelected(player, entry, spellId))
        player->removeSpell(spellId, SPEC_MASK_ALL, false);

    if (rank > 0)
      player->learnSpell(selectedSpellId, false);
    for (uint32 spellId : AscensionCoATalentState::SpellsAboveRank(entry, rank))
      if (player->HasSpell(spellId) && !SharedSpellStillSelected(player, entry, spellId))
        player->removeSpell(spellId, SPEC_MASK_ALL, false);

    SynchronizeProgression(player);

    LOG_INFO("coa", "Set local CoA talent entry {} to rank {} for {} (class {})", entryId, rank,
             player->GetName(), uint32(player->getClass()));
    return true;
  }

  char const* PurgeTalents(Player* player)
  {
    bool const anyPaid = std::any_of(AscensionCompatData::CoATalentEntries.begin(),
        AscensionCompatData::CoATalentEntries.end(), [player](AscensionCompatData::CoATalentEntry const& entry)
        {
          return entry.ClassId == player->getClass() && (entry.AECost || entry.TECost) &&
                 KnownRank(player, entry);
        });
    if (!anyPaid)
      return "CA_PURGE_TALENTS_NO_KNOWN_TALENTS";

    AscensionCoATalentState::PurgePrice const price =
        AscensionCoATalentState::TalentPurgePriceAt(player->GetLevel(), ResetCreditsOf(player));
    if (price.ItemCount && player->GetItemCount(price.Item) >= price.ItemCount)
      player->DestroyItemCount(price.Item, price.ItemCount, true);
    else if (price.Marks && player->GetItemCount(AscensionCoATalentState::MARK_OF_ASCENSION_ITEM) >= price.Marks)
      player->DestroyItemCount(AscensionCoATalentState::MARK_OF_ASCENSION_ITEM, price.Marks, true);
    else if (price.Money && player->HasEnoughMoney(price.Money))
      player->ModifyMoney(-int32(price.Money));
    else if (price.ItemCount || price.Marks || price.Money)
      return "CA_PURGE_TALENTS_NO_PURGE_ITEM";

    ResetPaidTalents(player);
    RaiseResetCredit(player, AscensionCoATalentState::ResetCreditType::TalentReset);
    return "CA_PURGE_TALENTS_OK";
  }

  uint32 ResetPaidTalents(Player* player)
  {
    uint32 removed = 0;
    for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
    {
      if (entry.ClassId != player->getClass() || (!entry.AECost && !entry.TECost))
        continue;
      for (uint32 spellId : entry.SpellIds)
        if (spellId && player->HasSpell(spellId))
        {
          player->removeSpell(spellId, SPEC_MASK_ALL, false);
          ++removed;
        }
    }

    SynchronizeProgression(player);
    LOG_INFO("coa", "Reset {} paid CoA talent rank(s) for {} (class {})", removed,
             player->GetName(), uint32(player->getClass()));
    return removed;
  }

  bool TalentBudget(Player const* player, uint32& classBudget, uint32& specializationBudget, std::string& error)
  {
    if (AscensionCompatData::GetCoATalentBudget(player->getClass(), player->GetLevel(), classBudget,
                                                specializationBudget))
      return true;

    LOG_ERROR("coa", "No CoA talent budget row for class {} at level {} ({})",
              uint32(player->getClass()), uint32(player->GetLevel()), player->GetName());
    error = Acore::StringFormat("No talent budget is known for class {} at level {}; no rank can be raised.",
                                uint32(player->getClass()), uint32(player->GetLevel()));
    return false;
  }

  static uint32 PersistentRank(Player const* player, AscensionCompatData::CoATalentEntry const& entry)
  {
    uint32 rank = 0;
    for (uint32 index = 0; index < entry.SpellCount; ++index)
    {
      uint32 const spellId = entry.SpellIds[index];
      bool const granted = spellId && std::any_of(AscensionCompatData::ClassSpells.begin(),
          AscensionCompatData::ClassSpells.end(), [player, spellId](AscensionCompatData::ClassSpell const& spell)
          {
            return spell.ClassId == player->getClass() && spell.SpellId == spellId &&
                   spell.RequiredLevel <= player->GetLevel();
          });
      if (granted)
        rank = index + 1;
    }
    return rank;
  }

  bool ApplyKnownEntriesUpload(Player* player, std::vector<AscensionCoATalentState::KnownEntry> const& upload,
                               UpdateEntriesRefusal& refusal, std::optional<uint32> requestedSpec = std::nullopt)
  {
    AscensionCoATalentState::UploadedSpecialization const uploaded = AscensionCoATalentState::SpecializationOf(upload);
    if (uploaded.Mixed)
    {
      refusal = { "CA_UPDATE_ENTRIES_BAD_ENTRY", "", 0, 0, "The uploaded build mixes specializations." };
      return false;
    }

    uint32 const activeSpecialization = GetActiveSpecialization(player);
    uint32 const targetSpec = requestedSpec.value_or(uploaded.SpecId ? uploaded.SpecId : activeSpecialization);
    bool const switching = targetSpec != activeSpecialization;
    std::unordered_map<uint32, uint32> wanted;
    std::unordered_set<uint32> received;
    std::unordered_set<uint32> selectedGroups;
    for (AscensionCoATalentState::KnownEntry const& item : upload)
    {
      AscensionCompatData::CoATalentEntry const* entry = FindTalentEntry(item.EntryId);
      if (!entry || entry->ClassId != player->getClass())
      {
        refusal = { "CA_UPDATE_ENTRIES_BAD_ENTRY", "CA_LEARN_WRONG_CLASS", item.EntryId, item.Rank,
                    Acore::StringFormat("Talent entry {} does not belong to your custom class.", item.EntryId) };
        return false;
      }
      if (!received.insert(item.EntryId).second)
      {
        refusal = { "CA_UPDATE_ENTRIES_BAD_ENTRY", "", item.EntryId, item.Rank,
                    "The uploaded build repeats a talent entry." };
        return false;
      }
      if (item.Rank > entry->SpellCount)
      {
        refusal = { "CA_UPDATE_ENTRIES_BAD_ENTRY", "", entry->EntryId, item.Rank,
                    Acore::StringFormat("Talent entry {} only has {} rank(s).", entry->EntryId,
                                        uint32(entry->SpellCount)) };
        return false;
      }
      if (item.Rank > 0)
      {
        if (player->GetLevel() < entry->RequiredLevel)
        {
          refusal = { "CA_UPDATE_ENTRIES_NOT_TRAVERSIBLE", "CA_LEARN_LOW_LEVEL", entry->EntryId, item.Rank,
                      Acore::StringFormat("Talent entry {} requires level {}.", entry->EntryId,
                                          uint32(entry->RequiredLevel)) };
          return false;
        }
        if (!sSpellMgr->GetSpellInfo(entry->SpellIds[item.Rank - 1]))
        {
          refusal = { "CA_UPDATE_ENTRIES_BAD_ENTRY", "CA_LEARN_BAD_ABILITY", entry->EntryId, item.Rank,
                      Acore::StringFormat("Talent entry {} rank {} references a missing server spell.",
                                          entry->EntryId, item.Rank) };
          return false;
        }
      }
      if (item.Rank && entry->SpecId && entry->SpecId != targetSpec)
      {
        refusal = { "CA_UPDATE_ENTRIES_BAD_ENTRY", "CA_LEARN_WRONG_CLASS", item.EntryId, item.Rank,
                    "The uploaded build includes an entry of another specialization." };
        return false;
      }
      if (uint32 const group = GetSelectableFreeGroup(item.EntryId); item.Rank && group &&
          !selectedGroups.insert(group).second)
      {
        refusal = { "CA_UPDATE_ENTRIES_NOT_TRAVERSIBLE", "CA_LEARN_GROUP", item.EntryId, item.Rank,
                    "The uploaded build selects mutually exclusive talents." };
        return false;
      }
      if (entry->AECost || entry->TECost || GetSelectableFreeGroup(entry->EntryId))
        wanted[entry->EntryId] = item.Rank;
    }

    std::vector<AscensionCoATalentState::KnownEntry> priced;
    for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
    {
      if (entry.ClassId != player->getClass() || (!entry.AECost && !entry.TECost))
        continue;
      auto itr = wanted.find(entry.EntryId);
      uint32 const rank = std::max(itr == wanted.end() ? 0 : itr->second, PersistentRank(player, entry));
      if (rank)
        priced.push_back({ entry.EntryId, rank });
    }

    AscensionCoATalentState::SpecializationSlot proposed;
    proposed.ClassId = player->getClass();
    proposed.SpecId = targetSpec;
    proposed.Entries = priced;
    for (auto const& [entryId, rank] : wanted)
        if (rank && GetSelectableFreeGroup(entryId))
            proposed.Entries.push_back({ entryId, rank });
    std::vector<AscensionCoATalentState::KnownEntry> const proposedKnown =
        AscensionCoATalentState::SlotKnownEntries(proposed, player->GetLevel(), CarriedSpells(player));
    for (AscensionCoATalentState::KnownEntry const& item : priced)
    {
        AscensionCompatData::CoATalentEntry const* entry = FindTalentEntry(item.EntryId);
        if (entry->SpecId && entry->SpecId != targetSpec)
            continue;
        for (uint32 requiredId : entry->RequiredEntryIds)
            if (requiredId && std::none_of(proposedKnown.begin(), proposedKnown.end(),
                [requiredId](AscensionCoATalentState::KnownEntry const& known)
                {
                    return known.EntryId == requiredId && known.Rank;
                }))
            {
                refusal = { "CA_UPDATE_ENTRIES_NOT_TRAVERSIBLE", "", item.EntryId, item.Rank,
                    Acore::StringFormat("Talent entry {} requires entry {} in the uploaded build.",
                        item.EntryId, requiredId) };
                return false;
            }
    }

    uint32 classBudget = 0;
    uint32 specializationBudget = 0;
    if (!TalentBudget(player, classBudget, specializationBudget, refusal.Detail))
    {
      refusal.Result = "CA_UPDATE_ENTRIES_UNKNOWN";
      return false;
    }
    AscensionCoATalentState::SpentPoints const spent = AscensionCoATalentState::Spent(priced);
    if (spent.AE > classBudget || spent.TE > specializationBudget)
    {
      refusal = { "CA_UPDATE_ENTRIES_NOT_TRAVERSIBLE",
                  spent.AE > classBudget ? "CA_LEARN_MISSING_AE" : "CA_LEARN_MISSING_TE", 0, 0,
                  Acore::StringFormat(
                      "That build spends {} class and {} specialization point(s); level {} has {} and {}.",
                      spent.AE, spent.TE, uint32(player->GetLevel()), classBudget, specializationBudget) };
      return false;
    }

    std::vector<AscensionCompatData::CoATalentEntry const*> removed;
    AscensionCoATalentState::RemovalPayment payment;
    if (!requestedSpec)
    {
      AscensionCoATalentState::ResetCredits const credits = ResetCreditsOf(player);
      std::vector<AscensionCoATalentState::UnlearnPrice> prices;
      for (AscensionCoATalentState::KnownEntry const& known : KnownTalentEntries(player))
      {
        bool const kept = std::any_of(upload.begin(), upload.end(),
            [&known](AscensionCoATalentState::KnownEntry const& item)
            {
              return item.EntryId == known.EntryId && item.Rank;
            });
        if (AscensionCompatData::CoATalentEntry const* entry = FindTalentEntry(known.EntryId);
            entry && !kept && !AscensionCoATalentState::IsUnpricedRemoval(*entry))
        {
          removed.push_back(entry);
          prices.push_back(AscensionCoATalentState::UnlearnPriceAt(player->GetLevel(), credits, entry->FreeUnlearn));
        }
      }
      payment = AscensionCoATalentState::PayForRemovals(
          prices, player->GetItemCount(AscensionCoATalentState::MARK_OF_ASCENSION_ITEM), player->GetMoney());
      std::string charged;
      for (std::size_t index = 0; index < removed.size(); ++index)
        charged += Acore::StringFormat(" {}({}c/{}m)", removed[index]->EntryId, prices[index].Money,
                                       prices[index].Marks);
      std::string sent;
      for (AscensionCoATalentState::KnownEntry const& item : upload)
        sent += Acore::StringFormat(" {}:{}", item.EntryId, item.Rank);
      LOG_INFO("coa", "Talent upload from {}: sent [{} ] removes [{} ] paying {}c and {} marks{}", player->GetName(),
               sent, charged, payment.Money, payment.Marks, payment.Affordable ? "" : " (refused)");
      if (!payment.Affordable)
      {
        refusal = { "CA_UPDATE_ENTRIES_BAD_UPDATE_COSTS", "", 0, 0,
                    "You cannot pay to unlearn the talents this build removes." };
        return false;
      }
    }

    if (std::string reason; switching && !SwitchSpecialization(player, targetSpec, &reason, false))
    {
      refusal = SpecializationSwitchRefused(targetSpec, std::move(reason));
      return false;
    }

    std::vector<std::pair<AscensionCompatData::CoATalentEntry const*, uint32>> changes;
    for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
    {
      if (entry.ClassId != player->getClass() ||
          (!entry.AECost && !entry.TECost && !GetSelectableFreeGroup(entry.EntryId)))
        continue;
      auto itr = wanted.find(entry.EntryId);
      uint32 const rank = itr == wanted.end() ? 0 : itr->second;
      if (rank != KnownRank(player, entry))
        changes.emplace_back(&entry, rank);
    }
    if (changes.empty())
      SynchronizeProgression(player);
    std::stable_sort(changes.begin(), changes.end(),
                     [](auto const& left, auto const& right) { return (left.second == 0) > (right.second == 0); });
    for (auto const& [entry, rank] : changes)
      if (!SetTalentRank(player, *entry, rank, refusal.Detail, false))
      {
        LOG_ERROR("coa",
                  "Known-entries upload for {} failed after validation at entry {} rank {}: {}", player->GetName(),
                  entry->EntryId, rank, refusal.Detail);
        refusal.Result = "CA_UPDATE_ENTRIES_UNKNOWN";
        refusal.Entry = entry->EntryId;
        refusal.Rank = rank;
        return false;
      }

    if (payment.Marks)
      player->DestroyItemCount(AscensionCoATalentState::MARK_OF_ASCENSION_ITEM, payment.Marks, true);
    if (payment.Money)
      player->ModifyMoney(-int32(payment.Money));
    for (AscensionCompatData::CoATalentEntry const* entry : removed)
      RaiseResetCredit(player, entry->Talent ? AscensionCoATalentState::ResetCreditType::TalentUnlearn
                                             : AscensionCoATalentState::ResetCreditType::AbilityUnlearn);
    return true;
  }

  void QueueKnownEntriesUpload(uint32 accountId, WorldPacket const& packet)
  {
    TalentRequest request;
    if (packet.size())
      request.Upload.assign(packet.contents(), packet.contents() + packet.size());
    QueueTalentRequest(accountId, std::move(request));
  }

  void QueueTalentReset(uint32 accountId)
  {
    QueueTalentRequest(accountId, { true, {} });
  }

  void ProcessTalentRequests(Player* player)
  {
    if (!ReceivesClientRequests(player))
      return;

    std::deque<TalentRequest> requests;
    {
      std::lock_guard<std::mutex> lock(_stateLock);
      auto itr = _pendingTalentRequests.find(player->GetSession()->GetAccountId());
      if (itr == _pendingTalentRequests.end())
        return;
      requests = std::move(itr->second);
      _pendingTalentRequests.erase(itr);
    }

    if (!IsAscensionCustomClass(player) && !AscensionWildcard::IsWildcardHero(player) &&
        !AscensionFreepick::HasFreepickBuild(player))
      return;
    for (TalentRequest const& request : requests)
    {
      if (!request.Reset)
      {
        HandleKnownEntriesUpload(player, request.Upload);
        continue;
      }
      WorldPacket result(SMSG_CHARACTER_ADVANCEMENT_PURGE_TALENTS_RESULT, 40);
      result << PurgeTalents(player);
      SendCharacterAdvancementKnownEntries(player);
      player->SendDirectMessage(&result);
    }
  }

  void HandleKnownEntriesUpload(Player* player, std::vector<uint8> const& body)
  {
    std::vector<AscensionCoATalentState::KnownEntry> upload;
    UpdateEntriesRefusal refusal;
    if (!AscensionCoATalentState::ParseKnownEntriesUpload(body.data(), body.size(), upload))
    {
      refusal.Result = "CA_UPDATE_ENTRIES_UNKNOWN";
      LOG_WARN("coa", "Malformed Ascension known-entries upload from {} payload={} bytes",
               player->GetName(), body.size());
    }
    else if (AscensionWildcard::IsWildcardHero(player))
    {
      AscensionWildcard::BuildChoice const choice = AscensionWildcard::ApplyBuildUpload(player, upload);
      refusal.Result = choice.Result;
      refusal.Learn = choice.Learn;
    }
    else if (AscensionFreepick::HasFreepickBuild(player))
    {
      AscensionFreepick::UploadResult const applied = AscensionFreepick::ApplyUpload(player, upload);
      refusal.Result = applied.Result;
      refusal.Learn = applied.Learn;
      refusal.Entry = applied.EntryId;
      refusal.Rank = applied.Rank;
    }
    else if (!ApplyKnownEntriesUpload(player, upload, refusal))
    {
      LOG_INFO("coa", "Refused known-entries upload of {} record(s) from {}: {} {} {}",
               upload.size(), player->GetName(), refusal.Result, refusal.Learn, refusal.Detail);
      if (refusal.Announce)
        ChatHandler(player->GetSession()).SendSysMessage(refusal.Detail);
    }
    else
      refusal.Result = "CA_UPDATE_ENTRIES_OK";
    SendCharacterAdvancementKnownEntries(player);
    WorldPacket result(SMSG_CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT, 64);
    result << refusal.Result << refusal.Learn << refusal.Entry << refusal.Rank;
    player->SendDirectMessage(&result);
  }

  uint32 GetActiveSpecialization(Player const *player) const {
    std::lock_guard<std::mutex> lock(_stateLock);
    auto itr = _activeSpecializations.find(player->GetGUID().GetCounter());
    return itr == _activeSpecializations.end() ? 0 : itr->second;
  }

    static uint32 ActiveSlot(Player const* player)
    {
        auto const* values = player->FindPlayerSettings("core.ascension_slot.active");
        uint32 const slot = values && !values->empty() ? (*values)[0].value : 0;
        return slot < AscensionWildcard::SPECIALIZATION_COUNT ? slot : 0;
    }

    static std::string SlotSetting(uint32 slot)
    {
        return "core.ascension_slot." + std::to_string(slot);
    }

  static std::string BuildSetting(Player const* player, uint32 specializationId)
  {
    uint32 const slot = ActiveSlot(player);
    return (slot ? SlotSetting(slot) + ".build." : std::string(ASCENSION_TALENT_BUILD_SETTING_PREFIX)) +
        std::to_string(specializationId);
  }

  static std::vector<uint32> LivePicks(Player const* player, uint32 specializationId)
  {
    std::vector<uint32> picks;
    for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
    {
      if (entry.ClassId != player->getClass() || entry.SpecId != specializationId ||
          (!entry.AECost && !entry.TECost && !GetSelectableFreeGroup(entry.EntryId)))
        continue;
      if (uint32 const rank = KnownRank(player, entry))
        picks.push_back(entry.EntryId * 10 + rank);
    }
    return picks;
  }

  static void StoreBuild(Player* player, uint32 specializationId, std::vector<uint32> const& picks)
  {
    std::string const setting = BuildSetting(player, specializationId);
    std::size_t previous = 0;
    if (PlayerSettingVector const* values = player->FindPlayerSettings(setting))
      previous = values->size();

    player->UpdatePlayerSetting(setting, 0, uint32(picks.size()));
    for (std::size_t index = 0; index < picks.size(); ++index)
      player->UpdatePlayerSetting(setting, uint32(index) + 1, picks[index]);
    for (std::size_t index = picks.size() + 1; index < previous; ++index)
      player->UpdatePlayerSetting(setting, uint32(index), 0);
  }

  static std::vector<uint32> StoredBuild(Player const* player, uint32 specializationId)
  {
    std::vector<uint32> picks;
    PlayerSettingVector const* values = player->FindPlayerSettings(BuildSetting(player, specializationId));
    if (!values || values->empty())
      return picks;

    std::size_t const count = std::min<std::size_t>((*values)[0].value, values->size() - 1);
    for (std::size_t index = 1; index <= count; ++index)
      if (uint32 const pick = (*values)[index].value)
        picks.push_back(pick);
    return picks;
  }

  static std::string BarSetting(Player const* player, uint32 specializationId)
  {
    uint32 const slot = ActiveSlot(player);
    return (slot ? SlotSetting(slot) + ".bar." : "core.ascension_bar.") + std::to_string(specializationId);
  }

  static std::vector<std::pair<uint8, uint32>> StoredBar(Player const* player, uint32 specializationId)
  {
    std::vector<std::pair<uint8, uint32>> bar;
    PlayerSettingVector const* values = player->FindPlayerSettings(BarSetting(player, specializationId));
    if (!values || values->empty())
      return bar;

    std::size_t const count = std::min<std::size_t>((*values)[0].value, (values->size() - 1) / 2);
    for (std::size_t index = 0; index < count; ++index)
      if (uint32 const button = (*values)[2 * index + 1].value; button < MAX_ACTION_BUTTONS)
        if (uint32 const spell = (*values)[2 * index + 2].value)
          bar.emplace_back(uint8(button), spell);
    return bar;
  }

  static void StoreBar(Player* player, uint32 specializationId,
                       std::vector<std::pair<uint8, uint32>> const& bar)
  {
    std::string const setting = BarSetting(player, specializationId);
    std::size_t previous = 0;
    if (PlayerSettingVector const* values = player->FindPlayerSettings(setting))
      previous = values->size();

    player->UpdatePlayerSetting(setting, 0, uint32(bar.size()));
    for (std::size_t index = 0; index < bar.size(); ++index)
    {
      player->UpdatePlayerSetting(setting, uint32(2 * index + 1), bar[index].first);
      player->UpdatePlayerSetting(setting, uint32(2 * index + 2), bar[index].second);
    }
    for (std::size_t index = 2 * bar.size() + 1; index < previous; ++index)
      player->UpdatePlayerSetting(setting, uint32(index), 0);
  }

  static void RememberBarButtons(Player* player, uint32 specializationId,
                                 std::unordered_set<uint32> const& spells)
  {
    std::vector<std::pair<uint8, uint32>> bar;
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
    {
      ActionButton const* action = player->GetActionButton(button);
      if (!action || action->GetType() != ACTION_BUTTON_SPELL || !spells.contains(action->GetAction()))
        continue;

      bar.emplace_back(button, action->GetAction());
      player->removeActionButton(button);
    }
    StoreBar(player, specializationId, bar);
  }

  static void RestoreBarButtons(Player* player, uint32 specializationId, uint32 previousSpecialization)
  {
    uint32 const source = player->FindPlayerSettings(BarSetting(player, specializationId))
        ? specializationId : previousSpecialization;
    for (auto const& [button, spell] : StoredBar(player, source))
      if (player->HasSpell(spell) && !player->GetActionButton(button))
        player->addActionButton(button, spell, ACTION_BUTTON_SPELL);

    player->SendInitialActionButtons();
  }

  void StoreBuilds(Player* player, uint32 specializationId)
  {
    StoreBuild(player, 0, LivePicks(player, 0));
    StoreBuild(player, specializationId, LivePicks(player, specializationId));
  }

  uint32 RestoreBuilds(Player* player, uint32 specializationId)
  {
    uint32 restored = 0;
    for (uint32 const tree : { uint32(0), specializationId })
      for (uint32 const pick : StoredBuild(player, tree))
      {
        AscensionCompatData::CoATalentEntry const* entry = FindTalentEntry(pick / 10);
        uint32 const rank = pick % 10;
        if (!entry || entry->ClassId != player->getClass() || entry->SpecId != tree || !rank ||
            rank > entry->SpellCount)
          continue;
        if (KnownRank(player, *entry) >= rank)
          continue;

        std::string error;
        if (SetTalentRank(player, *entry, rank, error))
          ++restored;
        else
          LOG_INFO("coa", "Stored talent entry {} rank {} not restored for {}: {}",
                   entry->EntryId, rank, player->GetName(), error);
      }
    return restored;
  }

  bool SwitchSpecialization(Player* player, uint32 specializationId, std::string* refusal = nullptr,
                            bool restoreStoredBuild = true)
  {
    if (!IsAscensionCustomClass(player) || (!specializationId && restoreStoredBuild))
      return false;

    bool validSpecialization = std::any_of(
        AscensionCompatData::CoATalentEntries.begin(),
        AscensionCompatData::CoATalentEntries.end(),
        [player, specializationId](
            AscensionCompatData::CoATalentEntry const &entry) {
          return entry.ClassId == player->getClass() &&
                 entry.SpecId == specializationId;
        });
    if (!validSpecialization && (specializationId || restoreStoredBuild))
      return false;

    uint32 const previousSpecialization = GetActiveSpecialization(player);
    if (previousSpecialization != specializationId)
      if (std::string reason = SpecializationSwitchRefusal(player, previousSpecialization, specializationId);
          !reason.empty())
      {
        if (refusal)
          *refusal = std::move(reason);
        return false;
      }

    if (!previousSpecialization || previousSpecialization == specializationId)
    {
      {
        std::lock_guard<std::mutex> lock(_stateLock);
        _activeSpecializations[player->GetGUID().GetCounter()] = specializationId;
      }
      player->UpdatePlayerSetting(ASCENSION_ACTIVE_SPEC_SETTING, 0, specializationId);

      uint32 const restored = previousSpecialization || !restoreStoredBuild ? 0 : RestoreBuilds(player, specializationId);
      uint32 granted = SynchronizeProgression(player);
      LOG_INFO("coa",
               "Synchronized {} (class {}) with local specialization {}, restored {} stored rank(s) and "
               "granted {} missing automatic spells",
               player->GetName(), uint32(player->getClass()), specializationId, restored, granted);
      return true;
    }

    if (restoreStoredBuild)
      StoreBuilds(player, previousSpecialization);

    if (Pet* pet = player->GetPet())
      player->RemovePet(pet, PET_SAVE_NOT_IN_SLOT);

    std::unordered_set<uint32> visitedSpellIds;
    uint32 removed = 0;
    {
      std::unordered_set<uint32> talentSpells;
      for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
        if (entry.ClassId == player->getClass())
          for (uint32 spellId : entry.SpellIds)
            if (spellId && player->HasSpell(spellId))
              talentSpells.insert(spellId);
      player->SendActionButtons(2);
      if (restoreStoredBuild)
        RememberBarButtons(player, previousSpecialization, talentSpells);
    }
    for (AscensionCompatData::CoATalentEntry const &entry :
         AscensionCompatData::CoATalentEntries) {
      if (entry.ClassId != player->getClass())
        continue;

      for (uint32 spellId : entry.SpellIds) {
        if (!spellId || !visitedSpellIds.insert(spellId).second ||
            !player->HasSpell(spellId))
          continue;

        player->removeSpell(spellId, SPEC_MASK_ALL, false);
        ++removed;
      }
    }

    if (player->getClass() == CLASS_SON_OF_ARUGAL && previousSpecialization == BLOODMAGE_FLESHWEAVER_SPEC)
      player->RemoveAurasDueToSpell(AscensionBloodmage::PooledVitality);

    {
      std::lock_guard<std::mutex> lock(_stateLock);
      _activeSpecializations[player->GetGUID().GetCounter()] = specializationId;
    }
    player->UpdatePlayerSetting(ASCENSION_ACTIVE_SPEC_SETTING, 0, specializationId);

    uint32 const restored = restoreStoredBuild ? RestoreBuilds(player, specializationId) : 0;
    uint32 granted = SynchronizeProgression(player);
    if (restoreStoredBuild)
      RestoreBarButtons(player, specializationId, previousSpecialization);
    ChatHandler(player->GetSession())
        .PSendSysMessage(
            "Activated specialization {}. Stored the build of specialization {}, removed {} old talent "
            "spell(s), restored {} stored rank(s) and granted {} automatic ability/passive spell(s).",
            specializationId, previousSpecialization, removed, restored, granted);
    LOG_INFO("coa",
             "Switched {} (class {}) to local specialization {}: removed {} CoA spells, restored {} "
             "stored ranks and granted {} automatic spells",
             player->GetName(), uint32(player->getClass()), specializationId, removed, restored, granted);
    return true;
  }

    static AscensionCoATalentState::SpecializationSlot LiveSlot(Player* player, uint32 specializationId)
    {
        AscensionCoATalentState::SpecializationSlot slot;
        slot.ClassId = player->getClass();
        slot.SpecId = specializationId;
        for (uint32 tree : { uint32(0), specializationId })
        {
            for (uint32 pick : LivePicks(player, tree))
                slot.Entries.push_back({ pick / 10, pick % 10 });
            if (!specializationId)
                break;
        }
        for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
            if (ActionButton const* action = player->GetActionButton(button))
                slot.Actions.emplace_back(button, action->GetType() == ACTION_BUTTON_SPELL ?
                    player->GetSavedActionButtonSpell(action->GetAction()) | (uint32(ACTION_BUTTON_SPELL) << 24) :
                    action->packedData);
        return slot;
    }

    static void StoreSlot(Player* player, uint32 index, AscensionCoATalentState::SpecializationSlot const& slot)
    {
        std::string const setting = SlotSetting(index);
        auto const record = AscensionCoATalentState::SpecializationSlotRecord(slot);
        auto const* previous = player->FindPlayerSettings(setting);
        std::size_t const size = previous ? previous->size() : 0;
        for (std::size_t offset = 0; offset < std::max(size, record.size()); ++offset)
            player->UpdatePlayerSetting(setting, uint32(offset), offset < record.size() ? record[offset] : 0);
    }

    void SaveSlot(Player* player)
    {
        if (IsAscensionCustomClass(player) && !AscensionWildcard::IsWildcardHero(player))
            StoreSlot(player, ActiveSlot(player), LiveSlot(player, GetActiveSpecialization(player)));
    }

    void ClearSlots(Player* player)
    {
        {
            std::lock_guard<std::mutex> lock(_stateLock);
            _activeSpecializations[player->GetGUID().GetCounter()] = 0;
        }
        player->UpdatePlayerSetting(ASCENSION_ACTIVE_SPEC_SETTING, 0, 0);
        player->UpdatePlayerSetting("core.ascension_slot.active", 0, 0);
        std::unordered_set<uint32> trees = { 0 };
        for (auto const& entry : AscensionCompatData::CoATalentEntries)
            trees.insert(entry.SpecId);
        for (uint32 slot = 0; slot < AscensionWildcard::SPECIALIZATION_COUNT; ++slot)
        {
            player->UpdatePlayerSetting(SlotSetting(slot), 0, 0);
            for (uint32 tree : trees)
            {
                std::string const prefix = slot ? SlotSetting(slot) : "core.ascension";
                for (std::string const& setting : { prefix + (slot ? ".build." : "_build.") + std::to_string(tree),
                                                  prefix + (slot ? ".bar." : "_bar.") + std::to_string(tree) })
                    if (player->FindPlayerSettings(setting))
                        player->UpdatePlayerSetting(setting, 0, 0);
            }
        }
    }

    void SendActiveSlot(Player* player)
    {
        {
            std::lock_guard<std::mutex> lock(_stateLock);
            if (!_advancementSent.count(player->GetGUID().GetCounter()))
                return;
        }
        WorldPacket packet(SMSG_CHARACTER_ADVANCEMENT_ACTIVE_SPEC, sizeof(uint32) * 2);
        packet << ActiveSlot(player) << uint32(AscensionWildcard::SPECIALIZATION_COUNT);
        player->SendDirectMessage(&packet);
    }

    bool SwitchSlot(Player* player, uint32 index, std::string& error)
    {
        if (!IsAscensionCustomClass(player) || AscensionWildcard::IsWildcardHero(player) ||
            index >= AscensionWildcard::SPECIALIZATION_COUNT ||
            !player->HasSpell(AscensionWildcard::SPECIALIZATION_SWAP_SPELLS[index]))
        {
            error = "That specialization slot is not unlocked.";
            return false;
        }
        if (index == ActiveSlot(player))
            return true;

        AscensionCoATalentState::SpecializationSlot target;
        if (auto const* stored = player->FindPlayerSettings(SlotSetting(index));
            stored && !stored->empty() && (*stored)[0].value)
        {
            std::vector<uint32> values;
            for (auto const& setting : *stored)
                values.push_back(setting.value);
            if (!AscensionCoATalentState::ParseSpecializationSlot(values, target) ||
                target.ClassId != player->getClass())
            {
                error = "The saved specialization slot is invalid for this character.";
                return false;
            }
        }

        uint32 const previousIndex = ActiveSlot(player);
        auto const previous = LiveSlot(player, GetActiveSpecialization(player));
        UpdateEntriesRefusal refusal;
        if (!ApplyKnownEntriesUpload(player, target.Entries, refusal, target.SpecId))
        {
            error = refusal.Detail;
            return false;
        }

        StoreSlot(player, previousIndex, previous);
        player->SendActionButtons(2);
        for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
            player->removeActionButton(button);
        for (auto const& [button, action] : target.Actions)
        {
            uint8 const type = uint8(ACTION_BUTTON_TYPE(action));
            uint32 spell = ACTION_BUTTON_ACTION(action);
            if (type == ACTION_BUTTON_SPELL)
            {
                sScriptMgr->OnPlayerNormalizeActionButtonSpell(player, spell, true);
                spell = player->GetTemporarySpellReplacement(spell);
            }
            player->addActionButton(uint8(button), spell, type);
        }
        player->UpdatePlayerSetting("core.ascension_slot.active", 0, index);
        player->SaveToDB(false, false);
        player->SendActionButtons(1);
        SendCharacterAdvancementState(player);
        return true;
    }

    void UpdateClassTuning(Player* player, uint32 diff)
    {
        if (!IsAscensionCustomClass(player))
            return;

        {
            std::lock_guard<std::mutex> lock(_stateLock);
            uint32& remaining = _tuningUpdates[player->GetGUID()];
            if (diff < remaining)
            {
                remaining -= diff;
                return;
            }

            remaining = 1000;
        }
        AscensionClassTuning::Synchronize(player, GetActiveSpecialization(player), false);
    }

  void OnPlayerLogout(Player *player) {
    std::lock_guard<std::mutex> lock(_stateLock);
    _tuningUpdates.erase(player->GetGUID());
    _activeSpecializations.erase(player->GetGUID().GetCounter());
    _proficiencySynchronizations.erase(player->GetGUID().GetCounter());
    _advancementPending.erase(player->GetGUID().GetCounter());
    _advancementSent.erase(player->GetGUID().GetCounter());
    if (ReceivesClientRequests(player))
      _pendingTalentRequests.erase(player->GetSession()->GetAccountId());
  }

    static uint32 GetSelectableFreeGroup(uint32 entryId)
    {
        for (auto const& entry : AscensionCompatData::CoASelectableFreeEntries)
            if (entry.EntryId == entryId)
                return entry.GroupId;
        return 0;
    }

    static bool CanGrantAutomaticEntry(Player const* player,
        AscensionCompatData::CoATalentEntry const& entry, uint32 specializationId)
    {
        return AscensionCoATalentState::CanGrantAutomatic(entry, player->getClass(), player->GetLevel(),
            specializationId, SpellbookOf(player));
    }

    static AscensionCoATalentState::HasSpell CarriedSpells(Player const* player)
    {
        std::unordered_set<uint32> carried;
        auto const& dependencies = AscensionCompatData::CoAAutomaticDependencies;
        for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
        {
            auto const dependency = std::lower_bound(dependencies.begin(), dependencies.end(), entry.EntryId,
                [](AscensionCompatData::CoAAutomaticDependency const& value, uint32 id) { return value.EntryId < id; });
            if (entry.ClassId != player->getClass() || entry.SpecId || entry.AECost || entry.TECost ||
                GetSelectableFreeGroup(entry.EntryId) ||
                (dependency != dependencies.end() && dependency->EntryId == entry.EntryId))
                continue;
            for (uint32 spellId : entry.SpellIds)
                if (spellId && player->HasSpell(spellId))
                    carried.insert(spellId);
        }
        return [carried = std::move(carried)](uint32 spellId) { return carried.contains(spellId); };
    }

    static std::vector<AscensionCoATalentState::KnownEntry> SlotEntries(Player const* player, uint32 index)
    {
        if (index == ActiveSlot(player))
            return KnownTalentEntries(player);
        auto const* stored = player->FindPlayerSettings(SlotSetting(index));
        if (!stored || stored->empty() || !(*stored)[0].value)
            return {};
        std::vector<uint32> values;
        for (auto const& setting : *stored)
            values.push_back(setting.value);
        AscensionCoATalentState::SpecializationSlot slot;
        if (!AscensionCoATalentState::ParseSpecializationSlot(values, slot) || slot.ClassId != player->getClass())
            return {};
        return AscensionCoATalentState::SlotKnownEntries(slot, player->GetLevel(), CarriedSpells(player));
    }

    static void ReconcileRunemasterFists(Player* player, uint32 specializationId)
    {
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || !specializationId)
            return;

        auto const& entries = AscensionCompatData::CoATalentEntries;
        auto findEntry = [&entries](uint32 entryId)
        {
            return std::lower_bound(entries.begin(), entries.end(), entryId,
                [](AscensionCompatData::CoATalentEntry const& entry, uint32 id)
                {
                    return entry.EntryId < id;
                });
        };
        auto const fists = findEntry(4062);
        auto const zenith = findEntry(29521);
        if (fists == entries.end() || fists->EntryId != 4062 ||
            fists->ClassId != CLASS_SPIRIT_MAGE || fists->SpecId != 61 ||
            fists->SpellCount != 1 || fists->AECost || fists->TECost || fists->RequiredLevel != 10 ||
            fists->SpellIds != std::array<uint32, 3>{92153, 0, 0} ||
            zenith == entries.end() || zenith->EntryId != 29521 ||
            zenith->ClassId != CLASS_SPIRIT_MAGE || zenith->SpecId ||
            zenith->SpellCount != 1 || zenith->AECost != 1 || zenith->TECost || zenith->RequiredLevel ||
            zenith->SpellIds != std::array<uint32, 3>{712325, 0, 0})
            return;

        auto const& dependencies = AscensionCompatData::CoAAutomaticDependencies;
        auto const dependency = std::lower_bound(dependencies.begin(), dependencies.end(), uint32(4062),
            [](AscensionCompatData::CoAAutomaticDependency const& entry, uint32 id)
            {
                return entry.EntryId < id;
            });
        if (dependency == dependencies.end() || dependency->EntryId != 4062 ||
            dependency->RequiredEntryIds != std::array<uint32, 2>{29521, 0})
            return;

        if (!CanGrantAutomaticEntry(player, *fists, specializationId) && player->HasSpell(92153))
            player->removeSpell(92153, player->GetActiveSpecMask(), false);
    }

private:
    static uint32 SynchronizeAutomaticTalents(Player* player, uint32 specializationId)
    {
        if (player->GetLevel() == 1)
            return 0;
        uint32 learned = 0;
        bool changed = true;
        for (std::size_t pass = 0; changed && pass < AscensionCompatData::CoATalentEntries.size(); ++pass)
        {
            changed = false;
            for (auto const& entry : AscensionCompatData::CoATalentEntries)
            {
                if (!CanGrantAutomaticEntry(player, entry, specializationId))
                    continue;

                uint32 spellId = entry.SpellIds[entry.SpellCount - 1];
                if (!spellId || player->HasSpell(spellId) || !sSpellMgr->GetSpellInfo(spellId))
                    continue;

                player->learnSpell(spellId, false);
                ++learned;
                changed = true;
            }
        }
        return learned;
    }

  mutable std::mutex _stateLock;
  std::unordered_map<ObjectGuid, uint32> _tuningUpdates;
  std::unordered_map<uint32, uint32> _activeSpecializations;
  std::unordered_set<uint32> _proficiencySynchronizations;
  std::unordered_set<uint32> _advancementPending;
  std::unordered_set<uint32> _advancementSent;
  struct TalentRequest
  {
    bool Reset = false;
    std::vector<uint8> Upload;
  };

  void QueueTalentRequest(uint32 accountId, TalentRequest request)
  {
    std::lock_guard<std::mutex> lock(_stateLock);
    std::deque<TalentRequest>& queue = _pendingTalentRequests[accountId];
    if (queue.size() >= MAX_QUEUED_TALENT_REQUESTS)
    {
      LOG_WARN("coa", "Dropping talent request for account {}: its queue is full", accountId);
      return;
    }
    queue.push_back(std::move(request));
  }

  static constexpr std::size_t MAX_QUEUED_TALENT_REQUESTS = 8;
  std::unordered_map<uint32, std::deque<TalentRequest>> _pendingTalentRequests;
};

class AscensionResourceService
{
public:
    static AscensionResourceService& Instance()
    {
        static AscensionResourceService instance;
        return instance;
    }

    void ValidateDefinitions() const
    {
        std::unordered_set<uint32> checkedResourceSpells;
        uint32 missingResourceSpells = 0;
        uint32 missingAbilitySpells = 0;

        auto validateResourceSpell =
            [&checkedResourceSpells, &missingResourceSpells](uint32 spellId)
            {
                if (!spellId || !checkedResourceSpells.insert(spellId).second)
                    return;

                if (!sSpellMgr->GetSpellInfo(spellId))
                {
                    LOG_ERROR("coa",
                        "Ascension resource spell {} is missing from the server DBC",
                        spellId);
                    ++missingResourceSpells;
                }
            };

        for (AscensionCompatData::ResourceDisplay const& display :
             AscensionCompatData::ResourceDisplays)
            validateResourceSpell(display.SpellId);

        for (AscensionCompatData::ResourceThresholdRule const& rule :
             AscensionCompatData::ResourceThresholdRules)
        {
            validateResourceSpell(rule.ResourceSpellId);
            validateResourceSpell(rule.ThresholdSpellId);
        }

        validateResourceSpell(SPELL_REAPER_GENERATE_SOUL);
        validateResourceSpell(SPELL_BLOODMAGE_THIRST_PASSIVE);

        for (AscensionCompatData::ResourceGainRule const& rule :
             AscensionCompatData::ResourceGainRules)
        {
            validateResourceSpell(rule.ResourceSpellId);
            validateResourceSpell(rule.RequiredAuraSpellId);
            validateResourceSpell(rule.ForbiddenAuraSpellId);
            if (rule.ChancePercent > 100)
            {
                LOG_ERROR("coa",
                    "Ascension resource generator {}-{} has invalid chance {}",
                    rule.FirstSpellId, rule.LastSpellId,
                    uint32(rule.ChancePercent));
                ++missingResourceSpells;
            }

            if (!rule.FirstSpellId && !rule.LastSpellId)
                continue;

            for (uint32 spellId = rule.FirstSpellId;
                 spellId <= rule.LastSpellId; ++spellId)
            {
                if (!sSpellMgr->GetSpellInfo(spellId))
                {
                    LOG_ERROR("coa",
                        "Ascension resource generator spell {} is missing from the server DBC",
                        spellId);
                    ++missingAbilitySpells;
                }
            }
        }

        for (AscensionCompatData::NativePowerGainRule const& rule :
             AscensionCompatData::NativePowerGainRules)
        {
            validateResourceSpell(rule.RequiredAuraSpellId);
            validateResourceSpell(rule.ForbiddenAuraSpellId);
            validateResourceSpell(rule.AmountSpellId);
            if (rule.PowerType >= MAX_POWERS)
            {
                LOG_ERROR("coa",
                    "Ascension native resource generator has invalid power type {}",
                    uint32(rule.PowerType));
                ++missingResourceSpells;
            }

            if (!rule.FirstSpellId && !rule.LastSpellId)
                continue;

            for (uint32 spellId = rule.FirstSpellId;
                 spellId <= rule.LastSpellId; ++spellId)
            {
                if (!sSpellMgr->GetSpellInfo(spellId))
                {
                    LOG_ERROR("coa",
                        "Ascension native resource generator spell {} is missing from the server DBC",
                        spellId);
                    ++missingAbilitySpells;
                }
            }
        }

        for (AscensionCompatData::ResourceCostRule const& rule :
             AscensionCompatData::ResourceCostRules)
        {
            validateResourceSpell(rule.ResourceSpellId);
            validateResourceSpell(rule.PreserveCostAuraSpellId);
            if (rule.PreserveCostChancePercent > 100)
            {
                LOG_ERROR("coa",
                    "Ascension resource spender {}-{} has invalid preserve-cost chance {}",
                    rule.FirstSpellId, rule.LastSpellId,
                    uint32(rule.PreserveCostChancePercent));
                ++missingResourceSpells;
            }
            for (uint32 spellId = rule.FirstSpellId;
                 spellId <= rule.LastSpellId; ++spellId)
            {
                if (!sSpellMgr->GetSpellInfo(spellId))
                {
                    LOG_ERROR("coa",
                        "Ascension resource spender spell {} is missing from the server DBC",
                        spellId);
                    ++missingAbilitySpells;
                }
            }
        }

        for (uint32 spellId : REAPER_ALL_SOUL_CONSUMERS)
        {
            if (!sSpellMgr->GetSpellInfo(spellId))
            {
                LOG_ERROR("coa",
                    "Ascension Reaper all-soul consumer spell {} is missing from the server DBC",
                    spellId);
                ++missingAbilitySpells;
            }
        }

        for (std::pair<uint32, uint32> const& range :
             REAPER_ONE_SOUL_CONSUMERS)
        {
            for (uint32 spellId = range.first; spellId <= range.second;
                 ++spellId)
            {
                if (!sSpellMgr->GetSpellInfo(spellId))
                {
                    LOG_ERROR("coa",
                        "Ascension Reaper one-soul consumer spell {} is missing from the server DBC",
                        spellId);
                    ++missingAbilitySpells;
                }
            }
        }

        LOG_INFO("coa",
            "Validated {} custom resource auras and spell helpers; {} resource spells and {} mapped abilities are missing",
            checkedResourceSpells.size(), missingResourceSpells,
            missingAbilitySpells);
    }

    void OnPlayerLogin(Player* player) const
    {
        _staticDecayTimers.erase(player->GetGUID());
        if (IsAscensionCustomClass(player))
            SynchronizeThresholdResources(player);
    }

    void OnPlayerUpdate(Player* player, uint32 diff) const
    {
        if (IsAscensionCustomClass(player))
        {
            DecayStatic(player, diff);
            SynchronizeThresholdResources(player);
        }
    }

    void OnPlayerLogout(Player* player) const
    {
        if (player)
            _staticDecayTimers.erase(player->GetGUID());
    }

    [[nodiscard]] bool CanPrepare(Spell* spell) const
    {
        if (!spell)
            return true;

        Player* player = spell->GetCaster()->ToPlayer();
        if (!player)
            return true;

        if (spell->GetSpellInfo()->Id != SPELL_REAPER_GENERATE_SOUL ||
            player->getClass() != CLASS_REAPER)
            return true;

        return GetAuraStacks(player, SPELL_REAPER_SOUL_FRAGMENT) >=
               REAPER_SOUL_FRAGMENT_COST;
    }

    void CheckCast(Spell* spell, SpellCastResult& result) const
    {
        if (!spell || spell->IsTriggered() || result != SPELL_CAST_OK)
            return;

        Player* player = spell->GetCaster()->ToPlayer();
        if (!player)
            return;

        SpellInfo const* spellInfo = spell->GetSpellInfo();
        uint32 spellId = spellInfo->Id;
        if (player->getClass() == CLASS_RANGER &&
            spellInfo->SpellFamilyName == uint32(CLASS_RANGER) + 6 &&
            spellInfo->CasterAuraSpell == 804329 && !player->HasAura(804329))
        {
            result = SPELL_FAILED_CASTER_AURASTATE;
            return;
        }

        if (player->getClass() == CLASS_REAPER && spellId == SPELL_REAPER_SCYTHE_RUSH)
        {
            Unit* target = spell->m_targets.GetUnitTarget();
            if (target && target->HasAura(SPELL_REAPER_SCYTHE_RUSH_MARKER,
                    player->GetGUID()))
            {
                result = SPELL_FAILED_TARGET_AURASTATE;
                return;
            }
        }

        for (AscensionCompatData::ResourceCostRule const& rule :
             AscensionCompatData::ResourceCostRules)
        {
            if (!Matches(player, spellId, rule.ClassId, rule.FirstSpellId,
                    rule.LastSpellId))
                continue;

            if (GetAuraStacks(player, rule.ResourceSpellId) < rule.Amount)
                result = SPELL_FAILED_NO_POWER;
            return;
        }
    }

    void OnSpellCast(Spell* spell) const
    {
        if (!spell || spell->IsTriggered())
            return;

        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || !IsAscensionCustomClass(player))
            return;

        SpellInfo const* spellInfo = spell->GetSpellInfo();
        uint32 spellId = spellInfo->Id;

        if (player->getClass() == CLASS_SON_OF_ARUGAL && spellInfo->SpellFamilyName == 26 &&
            spellInfo->PowerType == POWER_HEALTH && spell->GetPowerCost() > 0 &&
            player->HasAura(SPELL_BLOODMAGE_THIRST_PASSIVE))
            ModifyAuraStacks(player, SPELL_BLOODMAGE_THIRST, 1);

        for (AscensionCompatData::ResourceGainRule const& rule :
             AscensionCompatData::ResourceGainRules)
        {
            if (!MatchesGainRule(player, spellId, rule) ||
                rule.Event != AscensionCompatData::ResourceGainEvent::Cast ||
                (rule.RequiredAuraSpellId &&
                    !player->HasAura(rule.RequiredAuraSpellId)) ||
                (rule.ForbiddenAuraSpellId &&
                    player->HasAura(rule.ForbiddenAuraSpellId)))
                continue;

            ApplyGainRule(player, rule);
        }

        for (AscensionCompatData::NativePowerGainRule const& rule :
             AscensionCompatData::NativePowerGainRules)
        {
            if (!MatchesNativePowerRule(player, spellId, rule) ||
                rule.Event != AscensionCompatData::ResourceGainEvent::Cast ||
                (rule.RequiredAuraSpellId &&
                    !player->HasAura(rule.RequiredAuraSpellId)) ||
                (rule.ForbiddenAuraSpellId &&
                    player->HasAura(rule.ForbiddenAuraSpellId)))
                continue;

            player->ModifyPower(static_cast<Powers>(rule.PowerType),
                rule.InternalAmount);
        }

        for (AscensionCompatData::ResourceCostRule const& rule :
             AscensionCompatData::ResourceCostRules)
        {
            if (!Matches(player, spellId, rule.ClassId, rule.FirstSpellId,
                    rule.LastSpellId))
                continue;

            if (rule.ClassId == CLASS_STORMBRINGER && rule.ResourceSpellId == SPELL_STORMBRINGER_STATIC &&
                player->HasAura(SPELL_STORMBRINGER_CHARGED_CONDUIT))
                break;

            if (rule.PreserveCostAuraSpellId &&
                player->HasAura(rule.PreserveCostAuraSpellId) &&
                rule.PreserveCostChancePercent &&
                roll_chance_i(rule.PreserveCostChancePercent))
                break;

            if (rule.Consumption ==
                AscensionCompatData::ResourceConsumption::Fixed)
            {
                ModifyAuraStacks(player, rule.ResourceSpellId, -rule.Amount);
                ExtendUnshackleOnStaticDepleted(player, rule);
            }
            else if (rule.Consumption ==
                     AscensionCompatData::ResourceConsumption::All)
            {
                player->RemoveAurasDueToSpell(rule.ResourceSpellId);
                ExtendUnshackleOnStaticDepleted(player, rule);
            }
            break;
        }

        ConsumeReaperSouls(player, spell);
        SynchronizeThresholdResources(player);
    }

    static bool SpellDealsDamage(SpellInfo const* spellInfo)
    {
        return spellInfo &&
            (spellInfo->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE) ||
                spellInfo->HasEffect(SPELL_EFFECT_WEAPON_DAMAGE) ||
                spellInfo->HasEffect(SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL) ||
                spellInfo->HasEffect(SPELL_EFFECT_WEAPON_PERCENT_DAMAGE) ||
                spellInfo->HasEffect(SPELL_EFFECT_NORMALIZED_WEAPON_DMG));
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 missInfo,
        uint32 damage, bool critical) const
    {
        if (!spell || spell->IsTriggered() || !target)
            return;

        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || !IsAscensionCustomClass(player))
            return;

        bool successful = missInfo == SPELL_MISS_NONE;
        bool hostile = target != player && !player->IsFriendlyTo(target);
        bool damaging = damage > 0 || SpellDealsDamage(spell->GetSpellInfo());
        uint32 spellId = spell->GetSpellInfo()->Id;
        std::array<int8, 9> firstEventState = {};
        bool changed = false;

        for (AscensionCompatData::ResourceGainRule const& rule :
             AscensionCompatData::ResourceGainRules)
        {
            if (!MatchesGainRule(player, spellId, rule) ||
                rule.Event == AscensionCompatData::ResourceGainEvent::Cast ||
                rule.Event ==
                    AscensionCompatData::ResourceGainEvent::PeriodicDamageTick ||
                rule.Event == AscensionCompatData::ResourceGainEvent::Block ||
                (rule.RequiredAuraSpellId &&
                    !player->HasAura(rule.RequiredAuraSpellId)) ||
                (rule.ForbiddenAuraSpellId &&
                    player->HasAura(rule.ForbiddenAuraSpellId)))
                continue;

            bool qualifies = false;
            bool firstOnly = false;
            switch (rule.Event)
            {
                case AscensionCompatData::ResourceGainEvent::FirstSuccessfulHostileTarget:
                    qualifies = successful && hostile;
                    firstOnly = true;
                    break;
                case AscensionCompatData::ResourceGainEvent::EachSuccessfulHostileTarget:
                    qualifies = successful && hostile;
                    break;
                case AscensionCompatData::ResourceGainEvent::FirstSuccessfulDamagingHit:
                    qualifies = successful && hostile && damaging;
                    firstOnly = true;
                    break;
                case AscensionCompatData::ResourceGainEvent::EachSuccessfulDamagingHit:
                    qualifies = successful && hostile && damaging;
                    break;
                case AscensionCompatData::ResourceGainEvent::FirstCriticalDamagingHit:
                    qualifies = successful && hostile && damaging && critical;
                    firstOnly = true;
                    break;
                case AscensionCompatData::ResourceGainEvent::EachCriticalDamagingHit:
                    qualifies = successful && hostile && damaging && critical;
                    break;
                default:
                    break;
            }

            if (!qualifies)
                continue;

            if (firstOnly)
            {
                uint8 eventIndex = static_cast<uint8>(rule.Event);
                if (!firstEventState[eventIndex])
                {
                    firstEventState[eventIndex] =
                        spell->TryMarkScriptEventHandled(eventIndex) ? 1 : -1;
                }
                if (firstEventState[eventIndex] < 0)
                    continue;
            }

            changed = ApplyGainRule(player, rule) || changed;
        }

        for (AscensionCompatData::NativePowerGainRule const& rule :
             AscensionCompatData::NativePowerGainRules)
        {
            if (!MatchesNativePowerRule(player, spellId, rule) ||
                rule.Event == AscensionCompatData::ResourceGainEvent::Cast ||
                rule.Event ==
                    AscensionCompatData::ResourceGainEvent::PeriodicDamageTick ||
                rule.Event == AscensionCompatData::ResourceGainEvent::Block ||
                (rule.RequiredAuraSpellId &&
                    !player->HasAura(rule.RequiredAuraSpellId)) ||
                (rule.ForbiddenAuraSpellId &&
                    player->HasAura(rule.ForbiddenAuraSpellId)))
                continue;

            bool qualifies = false;
            bool firstOnly = false;
            switch (rule.Event)
            {
                case AscensionCompatData::ResourceGainEvent::FirstSuccessfulHostileTarget:
                    qualifies = successful && hostile;
                    firstOnly = true;
                    break;
                case AscensionCompatData::ResourceGainEvent::EachSuccessfulHostileTarget:
                    qualifies = successful && hostile;
                    break;
                case AscensionCompatData::ResourceGainEvent::FirstSuccessfulDamagingHit:
                    qualifies = successful && hostile && damaging;
                    firstOnly = true;
                    break;
                case AscensionCompatData::ResourceGainEvent::EachSuccessfulDamagingHit:
                    qualifies = successful && hostile && damaging;
                    break;
                case AscensionCompatData::ResourceGainEvent::FirstCriticalDamagingHit:
                    qualifies = successful && hostile && damaging && critical;
                    firstOnly = true;
                    break;
                case AscensionCompatData::ResourceGainEvent::EachCriticalDamagingHit:
                    qualifies = successful && hostile && damaging && critical;
                    break;
                default:
                    break;
            }

            if (!qualifies)
                continue;

            if (firstOnly)
            {
                uint8 eventIndex = static_cast<uint8>(rule.Event);
                if (!firstEventState[eventIndex])
                {
                    firstEventState[eventIndex] =
                        spell->TryMarkScriptEventHandled(eventIndex) ? 1 : -1;
                }
                if (firstEventState[eventIndex] < 0)
                    continue;
            }

            int32 amount = rule.InternalAmount;
            if (rule.AmountSpellId)
                if (SpellInfo const* amountSpell = sSpellMgr->GetSpellInfo(rule.AmountSpellId))
                    if (amountSpell->Effects[EFFECT_0].Effect == SPELL_EFFECT_ENERGIZE &&
                        amountSpell->Effects[EFFECT_0].MiscValue == rule.PowerType)
                        amount = amountSpell->Effects[EFFECT_0].CalcValue(player);

            player->ModifyPower(static_cast<Powers>(rule.PowerType), amount);
            changed = true;
        }

        if (changed)
            SynchronizeThresholdResources(player);
    }

    void OnPeriodicDamageTick(Unit* target, Unit* attacker, uint32 damage,
        SpellInfo const* spellInfo) const
    {
        if (!target || !attacker || !spellInfo)
            return;

        Creature const* creature = target->ToCreature();
        if (!damage && !(creature && creature->GetScriptName() == "npc_training_dummy"))
            return;

        Player* player = attacker->ToPlayer();
        if (!player || !IsAscensionCustomClass(player) || target == player ||
            player->IsFriendlyTo(target))
            return;

        bool changed = false;
        for (AscensionCompatData::ResourceGainRule const& rule :
             AscensionCompatData::ResourceGainRules)
        {
            if (rule.Event !=
                    AscensionCompatData::ResourceGainEvent::PeriodicDamageTick ||
                !MatchesGainRule(player, spellInfo->Id, rule) ||
                (rule.RequiredAuraSpellId &&
                    !player->HasAura(rule.RequiredAuraSpellId)) ||
                (rule.ForbiddenAuraSpellId &&
                    player->HasAura(rule.ForbiddenAuraSpellId)))
                continue;

            changed = ApplyGainRule(player, rule) || changed;
        }

        for (AscensionCompatData::NativePowerGainRule const& rule :
             AscensionCompatData::NativePowerGainRules)
        {
            if (rule.Event !=
                    AscensionCompatData::ResourceGainEvent::PeriodicDamageTick ||
                !MatchesNativePowerRule(player, spellInfo->Id, rule) ||
                (rule.RequiredAuraSpellId &&
                    !player->HasAura(rule.RequiredAuraSpellId)) ||
                (rule.ForbiddenAuraSpellId &&
                    player->HasAura(rule.ForbiddenAuraSpellId)))
                continue;

            player->ModifyPower(static_cast<Powers>(rule.PowerType),
                rule.InternalAmount);
            changed = true;
        }

        if (changed)
            SynchronizeThresholdResources(player);
    }

    void OnBlock(Player* player) const
    {
        if (!player || !IsAscensionCustomClass(player))
            return;

        bool changed = false;
        for (AscensionCompatData::ResourceGainRule const& rule :
             AscensionCompatData::ResourceGainRules)
        {
            if (rule.ClassId != player->getClass() ||
                rule.Event != AscensionCompatData::ResourceGainEvent::Block ||
                (rule.RequiredAuraSpellId &&
                    !player->HasAura(rule.RequiredAuraSpellId)) ||
                (rule.ForbiddenAuraSpellId &&
                    player->HasAura(rule.ForbiddenAuraSpellId)))
                continue;

            changed = ApplyGainRule(player, rule) || changed;
        }

        if (changed)
            SynchronizeThresholdResources(player);
    }

    void SendStatus(ChatHandler* handler) const
    {
        Player* player = handler ? handler->GetPlayer() : nullptr;
        if (!player)
            return;

        handler->PSendSysMessage("Ascension resource status for class {}:",
            uint32(player->getClass()));

        if (player->getClass() == CLASS_REAPER)
        {
            handler->PSendSysMessage("Runic Power: {}/{}",
                player->GetPower(POWER_RUNIC_POWER) / 10,
                player->GetMaxPower(POWER_RUNIC_POWER) / 10);
        }

        uint32 displayed = 0;
        for (AscensionCompatData::ResourceDisplay const& resource :
             AscensionCompatData::ResourceDisplays)
        {
            if (resource.ClassId != player->getClass())
                continue;

            uint32 maximum = resource.DisplayMaximum;
            if (!maximum)
            {
                if (SpellInfo const* spellInfo =
                        sSpellMgr->GetSpellInfo(resource.SpellId))
                    maximum = spellInfo->StackAmount;
            }

            handler->PSendSysMessage("{} ({}): {}/{}", resource.Name,
                resource.SpellId, uint32(GetAuraStacks(player, resource.SpellId)),
                maximum);
            ++displayed;
        }

        for (AscensionCompatData::ResourceThresholdRule const& threshold :
             AscensionCompatData::ResourceThresholdRules)
        {
            if (threshold.ClassId != player->getClass())
                continue;

            handler->PSendSysMessage(
                "Threshold {} ({} {}): {}",
                threshold.ThresholdSpellId, threshold.Amount,
                threshold.ResourceSpellId,
                player->HasAura(threshold.ThresholdSpellId) ? "active" :
                                                               "inactive");
        }

        if (!displayed && player->getClass() != CLASS_REAPER)
            handler->SendSysMessage(
                "This class has no separate Ascension resource widget.");
    }

private:
    static bool ApplyGainRule(Player* player,
        AscensionCompatData::ResourceGainRule const& rule)
    {
        if (!rule.ChancePercent ||
            (rule.ChancePercent < 100 && !roll_chance_i(rule.ChancePercent)))
            return false;

        if (rule.Mutation ==
            AscensionCompatData::ResourceMutation::AuraStacks)
        {
            ModifyAuraStacks(player, rule.ResourceSpellId, rule.Amount);
            return true;
        }

        for (int16 count = 0; count < rule.Amount; ++count)
            player->CastSpell(player, rule.ResourceSpellId, true);
        return true;
    }

    static bool Matches(Player const* player, uint32 spellId, uint8 classId,
        uint32 firstSpellId, uint32 lastSpellId)
    {
        return player->getClass() == classId && spellId >= firstSpellId &&
               spellId <= lastSpellId;
    }

    static bool MatchesGainRule(Player const* player, uint32 spellId,
        AscensionCompatData::ResourceGainRule const& rule)
    {
        return player->getClass() == rule.ClassId &&
            ((!rule.FirstSpellId && !rule.LastSpellId) ||
                (spellId >= rule.FirstSpellId &&
                    spellId <= rule.LastSpellId));
    }

    static bool MatchesNativePowerRule(Player const* player, uint32 spellId,
        AscensionCompatData::NativePowerGainRule const& rule)
    {
        return player->getClass() == rule.ClassId &&
            ((!rule.FirstSpellId && !rule.LastSpellId) ||
                (spellId >= rule.FirstSpellId &&
                    spellId <= rule.LastSpellId));
    }

    static uint8 GetAuraStacks(Unit const* unit, uint32 spellId)
    {
        if (Aura const* aura = unit->GetAura(spellId))
            return aura->GetStackAmount();
        return 0;
    }

    static void ModifyAuraStacks(Player* player, uint32 spellId, int32 amount)
    {
        if (!amount)
            return;

        if (HandleAscensionReaperResource(player, spellId, amount))
            return;

        if (AscensionPyromancer::Resource(player, spellId, amount))
            return;

        if (AscensionCultist::Resource(player, spellId, amount))
            return;

        if (AscensionVenomancer::Resource(player, spellId, amount))
            return;

        if (AscensionTinker::Resource(player, spellId, amount))
            return;

        if (AscensionSunCleric::Resource(player, spellId, amount))
            return;

        if (spellId == SPELL_PRIMALIST_EARTHSHAPING && amount > 0 &&
            HandleAscensionPrimalistEarthshapingGain(player))
            return;

        if (spellId == 800058 && amount > 0)
            AscensionFelsworn::Generated(player, uint32(amount));

        if (Aura* aura = player->GetAura(spellId))
        {
            bool preserveDuration = amount > 0 &&
                spellId == SPELL_PRIMALIST_EARTHSHAPING;
            int32 remaining = aura->GetDuration();
            aura->ModStackAmount(amount);
            if (preserveDuration)
                aura->SetDuration(remaining);
            return;
        }

        if (amount < 0)
            return;

        if (Aura* aura = player->AddAura(spellId, player))
            if (amount > 1)
                aura->ModStackAmount(amount - 1);
    }

    static bool HarvestTimePreserves(Player const* player, SpellInfo const* spellInfo)
    {
        if (spellInfo->CasterAuraSpell != SPELL_REAPER_SOUL_INFUSION ||
            !player->HasAura(SPELL_REAPER_HARVEST_TIME))
            return false;

        SpellInfo const* harvestTime = sSpellMgr->GetSpellInfo(SPELL_REAPER_HARVEST_TIME);
        if (!harvestTime)
            return false;

        float const preserveChance = std::abs(harvestTime->Effects[EFFECT_1].CalcValue());
        return roll_chance_f(preserveChance);
    }

    static bool WasAvoidedByEveryTarget(Player const* player, Spell* spell)
    {
        bool external = false;
        for (TargetInfo const& hit : *spell->GetUniqueTargetInfo())
        {
            if (hit.targetGUID == player->GetGUID())
                continue;

            if (hit.missCondition != SPELL_MISS_MISS && hit.missCondition != SPELL_MISS_DODGE &&
                hit.missCondition != SPELL_MISS_PARRY)
                return false;

            external = true;
        }
        return external;
    }

    static void ExtendUnshackleOnStaticDepleted(Player* player,
        AscensionCompatData::ResourceCostRule const& rule)
    {
        if (rule.ClassId != CLASS_STORMBRINGER ||
            rule.ResourceSpellId != SPELL_STORMBRINGER_STATIC ||
            !player->HasSpell(SPELL_STORMBRINGER_WRATH_OF_ALAKIR))
            return;

        player->CastSpell(player, SPELL_STORMBRINGER_UNSHACKLE_EXTENSION, true);
    }

    static void ConsumeReaperSouls(Player* player, Spell* spell)
    {
        if (player->getClass() != CLASS_REAPER)
            return;

        SpellInfo const* spellInfo = spell->GetSpellInfo();

        if (HarvestTimePreserves(player, spellInfo))
            return;

        bool const requiresSoulInfusion = spellInfo->CasterAuraSpell == SPELL_REAPER_SOUL_INFUSION &&
            player->HasAura(SPELL_REAPER_SOUL_INFUSION);

        uint32 spellId = spellInfo->Id;
        if (std::find(REAPER_ALL_SOUL_CONSUMERS.begin(),
                REAPER_ALL_SOUL_CONSUMERS.end(), spellId) !=
            REAPER_ALL_SOUL_CONSUMERS.end())
        {
            player->RemoveAurasDueToSpell(SPELL_REAPER_REAPED_SOUL);
            player->RemoveAurasDueToSpell(SPELL_REAPER_SOUL_INFUSION);
            if (requiresSoulInfusion)
                ApplyAscensionReaperSoulInfusionSpent(player);
            return;
        }

        if (requiresSoulInfusion && !WasAvoidedByEveryTarget(player, spell))
        {
            player->CastSpell(player, SPELL_REAPER_SOUL_INFUSION_REMOVER, true);
            ApplyAscensionReaperSoulInfusionSpent(player);
            return;
        }

        for (std::pair<uint32, uint32> const& range :
             REAPER_ONE_SOUL_CONSUMERS)
        {
            if (spellId >= range.first && spellId <= range.second)
            {
                ModifyAuraStacks(player, SPELL_REAPER_REAPED_SOUL, -1);
                return;
            }
        }
    }

    void DecayStatic(Player* player, uint32 diff) const
    {
        ObjectGuid const guid = player->GetGUID();
        uint8 const stacks = GetAuraStacks(player, SPELL_STORMBRINGER_STATIC);
        if (player->getClass() != CLASS_STORMBRINGER || !player->IsAlive() || !stacks || player->IsInCombat())
        {
            _staticDecayTimers.erase(guid);
            return;
        }

        constexpr uint32 graceMs = 5000;
        constexpr uint32 intervalMs = 1000;
        uint32& timer = _staticDecayTimers[guid];
        uint64 const elapsed = uint64(timer) + diff;
        if (elapsed < graceMs + intervalMs)
        {
            timer = uint32(elapsed);
            return;
        }

        uint32 const loss = uint32(std::min<uint64>(stacks, (elapsed - graceMs) / intervalMs));
        timer = graceMs + uint32((elapsed - graceMs) % intervalMs);
        ModifyAuraStacks(player, SPELL_STORMBRINGER_STATIC, -int32(loss));
        if (loss == stacks)
            _staticDecayTimers.erase(guid);
    }

    static void SynchronizeThresholdResources(Player* player)
    {
        for (AscensionCompatData::ResourceThresholdRule const& rule :
             AscensionCompatData::ResourceThresholdRules)
        {
            if (rule.ClassId != player->getClass())
                continue;

            bool meetsThreshold =
                GetAuraStacks(player, rule.ResourceSpellId) >= rule.Amount;
            if (meetsThreshold && !player->HasAura(rule.ThresholdSpellId))
            {
                player->CastSpell(player, rule.ThresholdSpellId, true);
            }
            else if (!meetsThreshold &&
                     player->HasAura(rule.ThresholdSpellId))
            {
                player->RemoveAurasDueToSpell(rule.ThresholdSpellId);
            }
        }

        if (player->getClass() == CLASS_PYROMANCER)
        {
            while (GetAuraStacks(player, SPELL_PYROMANCER_HEAT) >=
                   PYROMANCER_HEAT_PER_EMBER)
            {
                ModifyAuraStacks(player, SPELL_PYROMANCER_HEAT,
                    -PYROMANCER_HEAT_PER_EMBER);
                ModifyAuraStacks(player, SPELL_PYROMANCER_EMBER, 1);
            }
        }

        if (player->getClass() == CLASS_REAPER &&
            GetAuraStacks(player, SPELL_REAPER_SOUL_FRAGMENT) >=
                REAPER_SOUL_FRAGMENT_COST)
        {
            while (GetAuraStacks(player, SPELL_REAPER_SOUL_FRAGMENT) >=
                   REAPER_SOUL_FRAGMENT_COST)
            {
                ModifyAuraStacks(player, SPELL_REAPER_SOUL_FRAGMENT,
                    -REAPER_SOUL_FRAGMENT_COST);
                ModifyAuraStacks(player, SPELL_REAPER_REAPED_SOUL, 1);
            }
        }

        if (player->getClass() == CLASS_REAPER &&
            GetAuraStacks(player, SPELL_REAPER_REAPED_SOUL) >= 3 &&
            !player->HasAura(SPELL_REAPER_SOUL_INFUSION))
        {
            player->CastSpell(player, SPELL_REAPER_SOUL_INFUSION, true);
            ApplyAscensionReaperSoulInfusionGained(player);
        }
    }

    mutable std::unordered_map<ObjectGuid, uint32> _staticDecayTimers;
};

bool SendCollectionCreatureQueryResponse(WorldSession* session, uint32 creatureId);

class AscensionDisplayPatchService {
public:
  static AscensionDisplayPatchService &Instance() {
    static AscensionDisplayPatchService instance;
    return instance;
  }

  void Initialize() {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::SEND_DISPLAY_PATCHES))
      return;

    PreparedPatchRows const &rows = GetPreparedPatchRows();
    LOG_INFO("coa",
             "Prepared {} CreatureModelData, {} CreatureDisplayInfo, {} ItemDisplayInfo, {} Item, "
             "{} Spell, {} SuperTrack, {} SkillLineAbility and {} SpellShapeshiftForm patch rows "
             "for the client stream",
             rows.CreatureModels.size(), rows.CreatureDisplayIds.size(), rows.ItemDisplayInfos.size(),
             rows.Items.size(), rows.Spells.size(), rows.SuperTracks.size(), rows.SkillLineAbilities.size(),
             rows.ShapeshiftForms.size());
    IndexClientSpells();
    IndexClientSpellRanks();
    IndexAdvancementEntryIds();
  }

  void OnPlayerLogin(Player *player) {
    if (!ReceivesPatchRows(player))
      return;

    uint32 const guid = player->GetGUID().GetCounter();
    std::lock_guard lock(_mutex);
    _streamedPlayers.erase(guid);
    _sentItemRows.erase(guid);
    _sentItemSpellRows.erase(guid);
    _onDemandItemRows.erase(guid);
    _lastStreamMs.erase(guid);
    _fallbackTimers[guid] = { DISPLAY_PATCH_FALLBACK_DELAY_MS, false };
    std::lock_guard entries(_swapEntryMutex);
    _sentSwapEntries.erase(guid);
  }

  void OnPlayerLogout(Player *player) {
    uint32 const guid = player->GetGUID().GetCounter();
    PatchRowTally onDemand;
    {
      std::lock_guard lock(_mutex);
      _streamedPlayers.erase(guid);
      _sentItemRows.erase(guid);
      _sentItemSpellRows.erase(guid);
      _fallbackTimers.erase(guid);
      _lastStreamMs.erase(guid);
      if (auto node = _onDemandItemRows.extract(guid))
        onDemand = node.mapped();
    }
    {
      std::lock_guard entries(_swapEntryMutex);
      _sentSwapEntries.erase(guid);
    }

    if (onDemand.Rows || onDemand.SpellRows)
      LOG_INFO("coa", "Streamed {} Item and {} linked Spell patch rows ({} bytes) on demand to {} during the session",
               onDemand.Rows, onDemand.SpellRows, onDemand.Bytes, player->GetName());
  }

    void SendItemRowOnDemand(Player* player, uint32 itemId)
    {
        if (!ReceivesPatchRows(player))
            return;

        PreparedPatchRows const& rows = GetPreparedPatchRows();
        std::optional<ItemPatchRow> const row = FindItemRow(rows, itemId);
        if (!row)
            return;

        PatchRowTally const sent = SendItemRows(player, rows, { *row });
        if (!sent.Rows && !sent.SpellRows)
            return;

        std::lock_guard lock(_mutex);
        _onDemandItemRows[player->GetGUID().GetCounter()].Add(sent);
    }

    void SendSpellNoticeRow(Player* player, uint32 spellId, bool hidden)
    {
        if (!IsAscensionCustomClass(player) || !ReceivesPatchRows(player) || !player->IsInWorld())
            return;

        std::optional<SpellPatchRow> row = ClientSpellRow(player, spellId);
        if (!row || (row->Values[SPELL_ATTRIBUTES_FIELD] & (SPELL_ATTR0_IS_TRADESKILL | SPELL_ATTR0_DO_NOT_DISPLAY)))
            return;

        if (hidden)
            row->Values[SPELL_ATTRIBUTES_FIELD] |= SPELL_ATTR0_DO_NOT_DISPLAY;
        SendSpellRow(player, *row);
    }

    void SendSwapPlacementRow(Player* player, uint32 spellId, bool hold)
    {
        if (player->GetLevel() > CLIENT_AUTOPLACE_MAX_LEVEL || !IsAscensionCustomClass(player) ||
            !ReceivesPatchRows(player) || !player->IsInWorld())
            return;

        std::optional<SpellPatchRow> row = ClientSpellRow(player, spellId);
        if (!row || ClientRankNumber(row->Strings[SPELL_WIRE_RANK]) > 1)
            return;

        if (hold)
            row->Strings[SPELL_WIRE_RANK] = CLIENT_UNPLACED_RANK;
        SendSpellRow(player, *row);
    }

    void SendSwapEntries(Player* player, std::vector<uint32> const& spells)
    {
        if (spells.empty() || !ReceivesPatchRows(player) || !player->IsInWorld())
            return;

        std::vector<uint32> added;
        std::vector<std::pair<uint32, uint32>> rows;
        {
            std::lock_guard lock(_swapEntryMutex);
            std::set<uint32>& sent = _sentSwapEntries[player->GetGUID().GetCounter()];
            for (uint32 spell : spells)
            {
                auto entry = _swapEntryIds.find(spell);
                if (entry == _swapEntryIds.end())
                {
                    if (_freeEntryIds.empty())
                        continue;
                    entry = _swapEntryIds.emplace(spell, _freeEntryIds.back()).first;
                    _freeEntryIds.pop_back();
                    _swapEntrySpells.emplace(entry->second, spell);
                }
                if (sent.insert(entry->second).second)
                    added.push_back(entry->second);
            }
            if (added.empty())
                return;
            for (uint32 id : sent)
                rows.emplace_back(id, _swapEntrySpells.at(id));
        }

        std::unordered_map<uint32, uint32> const spellsById(rows.begin(), rows.end());
        for (uint32 id : added)
            SendSwapEntryRow(player, id, spellsById.at(id));
        for (auto const& [id, spell] : rows)
            SendSwapEntryRow(player, id, spell);
    }

  void OnPlayerUpdate(Player *player, uint32 diff) {
    if (!ReceivesPatchRows(player))
      return;

    uint32 const guid = player->GetGUID().GetCounter();
    bool expired = false;
    bool force = false;
    {
      std::lock_guard lock(_mutex);
      auto const itr = _fallbackTimers.find(guid);
      if (itr != _fallbackTimers.end())
      {
        if (itr->second.DelayMs > diff)
          itr->second.DelayMs -= diff;
        else
        {
          force = itr->second.Force;
          _fallbackTimers.erase(itr);
          expired = true;
        }
      }
    }

    if (expired)
      SendPatchStream(player, force);
  }

  void SendPatchStream(Player *player, bool force = false) {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::SEND_DISPLAY_PATCHES))
      return;

    uint32 const guid = player->GetGUID().GetCounter();
    {
      std::lock_guard entries(_swapEntryMutex);
      _sentSwapEntries.erase(guid);
    }
    PreparedPatchRows const &rows = GetPreparedPatchRows();
    {
      std::lock_guard lock(_mutex);
      if (force)
      {
        auto const last = _lastStreamMs.find(guid);
        if (last != _lastStreamMs.end())
        {
          uint32 const elapsed = GetMSTimeDiffToNow(last->second);
          if (elapsed < DISPLAY_PATCH_RESEND_COOLDOWN_MS)
          {
            _fallbackTimers[guid] = { DISPLAY_PATCH_RESEND_COOLDOWN_MS - elapsed, true };
            return;
          }
        }
        _streamedPlayers.erase(guid);
      }
      if (!_streamedPlayers.insert(guid).second)
        return;
      _fallbackTimers.erase(guid);
      _lastStreamMs[guid] = getMSTime();
    }

    std::vector<ItemPatchRow> itemRows;
    for (uint32 itemId : CollectOwnedItemIds(player))
        if (std::optional<ItemPatchRow> const row = FindItemRow(rows, itemId))
            itemRows.push_back(*row);

    uint32 const startTime = getMSTime();

    std::size_t bytes = SendLoadingScreenRow(player);

    for (CreatureModelPatchRow const &row : rows.CreatureModels)
      bytes += SendCreatureModelRow(player, row);

    uint32 sent = 0;
    for (uint32 displayId : rows.CreatureDisplayIds) {
      if (CreatureDisplayInfoEntry const *entry =
              sCreatureDisplayInfoStore.LookupEntry(displayId)) {
        bytes += SendDisplayInfoRow(player, *entry);
        ++sent;
      }
    }

    for (ItemDisplayInfoPatchRow const &row : rows.ItemDisplayInfos)
      bytes += SendItemDisplayInfoRow(player, row);

    PatchRowTally const sentItems = SendItemRows(player, rows, std::move(itemRows));
    bytes += sentItems.Bytes;

    uint32 sentSpells = sentItems.SpellRows;
    for (SpellPatchRow const& row : rows.Spells)
      if (!row.RequiresRegistration || Ascension::ClientSpellPatches::Instance().Contains(row.Values[0],
          Ascension::ClientSpellPatches::Delivery::Login))
      {
        SpellPatchRow active = row;
        ApplyServerSpellSelectors(active);
        bytes += SendSpellRow(player, active);
        ++sentSpells;
      }

    for (SuperTrackPatchRow const &row : rows.SuperTracks)
      bytes += SendSuperTrackRow(player, row);

    for (SkillLineAbilityPatchRow const& row : rows.SkillLineAbilities)
        bytes += SendSkillLineAbilityRow(player, row);

    for (ShapeshiftFormPatchRow const &row : rows.ShapeshiftForms)
      bytes += SendShapeshiftFormRow(player, row);

    LOG_INFO("coa",
             "Streamed {} CreatureModelData, {} CreatureDisplayInfo, {} ItemDisplayInfo, {} of {} Item, "
             "{} Spell, {} SuperTrack, {} SkillLineAbility and {} SpellShapeshiftForm patch rows "
             "({} bytes) to {} in {} ms",
             rows.CreatureModels.size(), sent, rows.ItemDisplayInfos.size(), sentItems.Rows,
             rows.Items.size(), sentSpells, rows.SuperTracks.size(), rows.SkillLineAbilities.size(),
             rows.ShapeshiftForms.size(), bytes, player->GetName(), GetMSTimeDiffToNow(startTime));
  }

private:
  static bool ReceivesPatchRows(Player const *player) {
    return ascensionCompatConfig.GetConfigValue<bool>(
               AscensionCompatConfig::SEND_DISPLAY_PATCHES) &&
           !player->GetSession()->IsBot();
  }

  static constexpr std::size_t ITEM_DISPLAY_INFO_FIELD_COUNT = 25;
  static constexpr std::array<uint8, 14> ITEM_DISPLAY_INFO_STRING_FIELDS = {
      1, 2, 3, 4, 5, 6, 15, 16, 17, 18, 19, 20, 21, 22};

  struct ItemDisplayInfoPatchRow {
    std::array<uint32, ITEM_DISPLAY_INFO_FIELD_COUNT> Values{};
    std::array<std::string, ITEM_DISPLAY_INFO_STRING_FIELDS.size()> Strings;
  };

  using ItemPatchRow = std::array<uint32, 8>;
  using SuperTrackPatchRow = std::array<uint32, 8>;
    static constexpr uint32 SKILL_LINE_ABILITY_DBC_FIELD_COUNT = 14;
    using SkillLineAbilityPatchRow = std::array<uint32, SKILL_LINE_ABILITY_DBC_FIELD_COUNT>;

  static constexpr uint32 SHAPESHIFT_FORM_DBC_FIELD_COUNT = 35;
  static constexpr uint32 SHAPESHIFT_FORM_NAME_FIELD = 2;
  static constexpr uint32 SHAPESHIFT_FORM_FIRST_NUMERIC_FIELD = 19;

  struct ShapeshiftFormPatchRow {
    std::array<uint32, 18> Values{};
    std::string Name;
  };

  static constexpr uint32 CREATURE_MODEL_DATA_FIELD_COUNT = 28;
  static constexpr uint32 CREATURE_MODEL_DATA_NAME_FIELD = 2;

  struct CreatureModelPatchRow {
    std::array<uint32, CREATURE_MODEL_DATA_FIELD_COUNT> Values{};
    std::string ModelName;
  };

  struct PatchRowTally {
    uint32 Rows = 0;
    uint32 SpellRows = 0;
    std::size_t Bytes = 0;

    void Add(PatchRowTally const &other) {
      Rows += other.Rows;
      SpellRows += other.SpellRows;
      Bytes += other.Bytes;
    }
  };

  static constexpr uint32 SPELL_DBC_FIELD_COUNT = 234;
  static constexpr uint32 SPELL_CLIENT_RECORD_DWORDS = 170;
  static constexpr uint32 LOCALIZED_STRING_DWORDS = 17;
  static constexpr uint32 SPELL_NAME_FIELD = 136;
  static constexpr uint32 SPELL_RANK_FIELD = 153;
  static constexpr uint32 SPELL_DESCRIPTION_FIELD = 170;
  static constexpr uint32 SPELL_TOOLTIP_FIELD = 187;
  static constexpr std::array<uint32, 4> SPELL_WIRE_STRING_FIELDS = {
      SPELL_NAME_FIELD, SPELL_DESCRIPTION_FIELD, SPELL_RANK_FIELD,
      SPELL_TOOLTIP_FIELD};
  static constexpr std::size_t SPELL_WIRE_DESCRIPTION = 1;
  static constexpr std::size_t SPELL_WIRE_TOOLTIP = 3;
  static constexpr uint32 SPELL_CASTER_AURA_SPELL_FIELD = 24;
  static constexpr uint32 SPELL_EXCLUDE_CASTER_AURA_SPELL_FIELD = 26;
  static constexpr uint32 SPELL_CAST_TIME_INDEX_FIELD = 28;
  static constexpr uint32 SPELL_FAMILY_NAME_FIELD = 208;
  static constexpr std::array<uint32, 10> RANGED_PREPARATION_CLIENT_SPELLS = {
      504582, 572343, 572344, 572345, 572383, 680902, 680903, 680904, 680905, 806288};
  static constexpr uint32 SPELL_LEVEL_FIELD = 39;
  struct ClientSpellText {
    std::string Description;
    std::string ToolTip;
  };

  static constexpr std::size_t SPELL_WIRE_SLOT(uint32 field) {
    return field < SPELL_NAME_FIELD
               ? field
               : SPELL_NAME_FIELD + SPELL_WIRE_STRING_FIELDS.size() +
                     (field - (SPELL_TOOLTIP_FIELD + LOCALIZED_STRING_DWORDS));
  }

  struct SpellPatchRow {
    std::array<uint32, SPELL_CLIENT_RECORD_DWORDS> Values{};
    std::array<std::string, SPELL_WIRE_STRING_FIELDS.size()> Strings;
    bool RequiresRegistration = false;
  };

  struct PreparedPatchRows {
    std::vector<uint32> CreatureDisplayIds;
    std::vector<ItemDisplayInfoPatchRow> ItemDisplayInfos;
    std::vector<ItemPatchRow> Items;
    std::vector<std::size_t> ItemCapacityOrder;
    std::unordered_set<uint32> SqlItemIds;
    std::unordered_map<uint32, std::size_t> ItemRowIndexById;
    std::vector<SpellPatchRow> Spells;
    std::unordered_map<uint32, std::size_t> SpellRowIndexById;
    std::vector<SuperTrackPatchRow> SuperTracks;
    std::vector<SkillLineAbilityPatchRow> SkillLineAbilities;
    std::vector<ShapeshiftFormPatchRow> ShapeshiftForms;
    std::vector<CreatureModelPatchRow> CreatureModels;
  };

  static constexpr uint32 SPELL_ATTRIBUTES_FIELD = 4;
  static constexpr std::size_t SWAP_ENTRY_ID_POOL = 4096;
  static constexpr uint8 CLIENT_AUTOPLACE_MAX_LEVEL = 10;
  static constexpr std::size_t SPELL_WIRE_RANK = 2;
  static constexpr char const* CLIENT_UNPLACED_RANK = "Rank 2";

  static uint32 ClientRankNumber(std::string const &text) {
    uint32 rank = 0;
    for (char character : text)
    {
      if (character >= '0' && character <= '9')
        rank = rank * 10 + uint32(character - '0');
      else if (rank)
        break;
    }
    return rank;
  }
  static constexpr uint32 ADVANCEMENT_ENTRY_HIDDEN = 0x1;
  static constexpr std::size_t ADVANCEMENT_ENTRY_SPELLS = 9;

  std::size_t SendSwapEntryRow(Player *player, uint32 id, uint32 spell) {
    std::array<uint32, ADVANCEMENT_ENTRY_SPELLS> spells{};
    std::size_t count = 0;
    for (uint32 rank : { spell, sSpellMgr->GetFirstSpellInChain(spell), ClientFirstRank(spell) })
      if (rank && std::find(spells.begin(), spells.begin() + count, rank) == spells.begin() + count)
        spells[count++] = rank;

    WorldPacket packet(SMSG_PATCH_CHARACTER_ADVANCEMENT, 512);
    auto const words = [&packet](uint32 count) {
      for (uint32 index = 0; index < count; ++index)
        packet << uint32(0);
    };
    auto const bytes = [&packet](uint32 count) {
      for (uint32 index = 0; index < count; ++index)
        packet << uint8(0);
    };
    packet << id;
    bytes(1);
    words(3);
    for (uint32 rank : spells)
      packet << rank;
    words(2);
    bytes(1);
    words(3);
    bytes(1);
    words(3);
    bytes(1);
    words(22);
    bytes(4);
    bytes(2);
    words(4);
    bytes(1);
    words(15);
    bytes(1);
    packet << ADVANCEMENT_ENTRY_HIDDEN;
    bytes(5);
    words(29);
    bytes(3);
    words(19);
    return SendRowPacket(player, packet);
  }

  uint32 ClientFirstRank(uint32 spell) {
    std::lock_guard lock(_clientSpellMutex);
    auto const found = _clientFirstRanks.find(spell);
    return found == _clientFirstRanks.end() ? spell : found->second;
  }

  void IndexAdvancementEntryIds() {
    std::filesystem::path const path =
        std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "CharacterAdvancement.dbc";
    ClientDBC entries;
    if (!entries.Load(path.string(), 1) || !entries.GetRecordCount())
      return;
    std::vector<uint32> ids;
    ids.reserve(entries.GetRecordCount());
    for (uint32 index = 0; index < entries.GetRecordCount(); ++index)
      ids.push_back(entries.GetRecord(index).GetUInt32(0));
    std::sort(ids.begin(), ids.end());
    std::vector<uint32> free;
    for (std::size_t index = 1; index < ids.size() && free.size() < SWAP_ENTRY_ID_POOL; ++index)
      for (uint32 id = ids[index - 1] + 1; id < ids[index] && free.size() < SWAP_ENTRY_ID_POOL; ++id)
        free.push_back(id);
    std::reverse(free.begin(), free.end());
    std::lock_guard lock(_swapEntryMutex);
    _freeEntryIds = std::move(free);
  }

  void IndexClientSpellRanks() {
    std::filesystem::path const path = std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "SpellRank.dbc";
    ClientDBC ranks;
    if (!ranks.Load(path.string(), 3))
      return;
    std::unordered_map<uint32, uint32> firstRanks;
    for (uint32 index = 0; index < ranks.GetRecordCount(); ++index)
    {
      ClientDBC::Record const record = ranks.GetRecord(index);
      firstRanks[record.GetUInt32(2)] = record.GetUInt32(1);
    }
    std::lock_guard lock(_clientSpellMutex);
    _clientFirstRanks = std::move(firstRanks);
  }
  static constexpr std::uint64_t CLIENT_DBC_HEADER_BYTES = 20;

  struct ClientSpellFile {
    std::string Path;
    uint32 RecordSize = 0;
    std::uint64_t StringBlock = 0;
    std::vector<std::pair<uint32, uint32>> Rows;
  };

  template <class Dword, class Text>
  static SpellPatchRow RawSpellRow(Dword const &dword, Text const &text) {
    SpellPatchRow row;
    std::size_t slot = 0;
    for (uint32 field = 0; field < SPELL_DBC_FIELD_COUNT;)
    {
      bool const localized = field >= SPELL_NAME_FIELD && field <= SPELL_TOOLTIP_FIELD;
      row.Values[slot++] = localized ? 0 : dword(field);
      field += localized ? LOCALIZED_STRING_DWORDS : 1;
    }
    for (std::size_t index = 0; index < SPELL_WIRE_STRING_FIELDS.size(); ++index)
      row.Strings[index] = text(SPELL_WIRE_STRING_FIELDS[index]);
    return row;
  }

  std::optional<SpellPatchRow> ReadClientSpellRow(uint32 spellId) const {
    auto const found = std::lower_bound(_clientSpells.Rows.begin(), _clientSpells.Rows.end(),
                                        std::make_pair(spellId, uint32(0)));
    if (found == _clientSpells.Rows.end() || found->first != spellId)
      return std::nullopt;

    std::ifstream file(_clientSpells.Path, std::ios::binary);
    std::vector<char> record(_clientSpells.RecordSize);
    file.seekg(std::streamoff(CLIENT_DBC_HEADER_BYTES + std::uint64_t(found->second) * _clientSpells.RecordSize));
    if (!file.read(record.data(), std::streamsize(record.size())))
      return std::nullopt;

    auto const dword = [&record](uint32 field) {
      uint32 value = 0;
      std::memcpy(&value, record.data() + std::size_t(field) * sizeof(uint32), sizeof(uint32));
      return value;
    };
    auto const text = [&](uint32 field) {
      std::string value;
      file.clear();
      file.seekg(std::streamoff(_clientSpells.StringBlock + dword(field)));
      std::getline(file, value, '\0');
      return value;
    };
    return RawSpellRow(dword, text);
  }

  std::optional<SpellPatchRow> ClientSpellRow(Player *player, uint32 spellId) {
    PreparedPatchRows const &rows = GetPreparedPatchRows();
    if (auto const found = rows.SpellRowIndexById.find(spellId); found != rows.SpellRowIndexById.end())
    {
      SpellPatchRow const &prepared = rows.Spells[found->second];
      bool streamed = !prepared.RequiresRegistration || Ascension::ClientSpellPatches::Instance().Contains(spellId,
          Ascension::ClientSpellPatches::Delivery::Login);
      if (!streamed)
      {
        std::lock_guard lock(_mutex);
        auto const sent = _sentItemSpellRows.find(player->GetGUID().GetCounter());
        streamed = sent != _sentItemSpellRows.end() && sent->second.contains(spellId);
      }
      if (streamed)
      {
        SpellPatchRow row = prepared;
        ApplyServerSpellSelectors(row);
        return row;
      }
    }

    {
      std::lock_guard lock(_clientSpellMutex);
      if (auto const cached = _clientSpellRows.find(spellId); cached != _clientSpellRows.end())
        return cached->second;
    }
    std::optional<SpellPatchRow> row = ReadClientSpellRow(spellId);
    std::lock_guard lock(_clientSpellMutex);
    return _clientSpellRows.emplace(spellId, std::move(row)).first->second;
  }

  void IndexClientSpells() {
    std::filesystem::path const path = std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "Spell.dbc";
    ClientDBC spells;
    if (!spells.Load(path.string(), SPELL_DBC_FIELD_COUNT) || !spells.GetRecordCount())
      return;

    ClientSpellFile file;
    file.Path = path.string();
    file.RecordSize = spells.GetRecordSize();
    file.StringBlock = CLIENT_DBC_HEADER_BYTES + std::uint64_t(spells.GetRecordCount()) * spells.GetRecordSize();
    file.Rows.reserve(spells.GetRecordCount());
    for (uint32 index = 0; index < spells.GetRecordCount(); ++index)
      file.Rows.emplace_back(spells.GetRecord(index).GetUInt32(0), index);
    std::sort(file.Rows.begin(), file.Rows.end());

    std::lock_guard lock(_clientSpellMutex);
    _clientSpells = std::move(file);
    _clientSpellRows.clear();
    for (uint32 index : { uint32(0), spells.GetRecordCount() / 2, spells.GetRecordCount() - 1 })
    {
      ClientDBC::Record const record = spells.GetRecord(index);
      SpellPatchRow const expected = RawSpellRow(
          [&record](uint32 field) { return record.GetUInt32(field); },
          [&record](uint32 field) { return std::string(record.GetString(field)); });
      std::optional<SpellPatchRow> const read = ReadClientSpellRow(record.GetUInt32(0));
      if (!read || read->Values != expected.Values || read->Strings != expected.Strings)
      {
        LOG_ERROR("coa", "Spell rows read from {} differ from the loaded table; temporary spell notices keep "
                  "their chat lines", path.string());
        _clientSpells = {};
        return;
      }
    }
    LOG_INFO("coa", "Indexed {} Spell rows from {} for temporary spell notices", _clientSpells.Rows.size(),
             path.string());
  }

  static std::unordered_set<uint32> CollectOwnedItemIds(Player *player) {
    std::unordered_set<uint32> itemIds;
    auto const addItem = [&itemIds](Item const *item) {
      if (item)
        itemIds.insert(item->GetEntry());
    };
    auto const addBagContents = [&](uint8 firstSlot, uint8 endSlot) {
      for (uint8 slot = firstSlot; slot < endSlot; ++slot)
        if (Bag const *bag = player->GetBagByPos(slot))
          for (uint32 bagSlot = 0; bagSlot < bag->GetBagSize(); ++bagSlot)
            addItem(bag->GetItemByPos(uint8(bagSlot)));
    };

    for (uint8 slot = EQUIPMENT_SLOT_START; slot < BANK_SLOT_BAG_END; ++slot)
      addItem(player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
    for (uint8 slot = KEYRING_SLOT_START; slot < CURRENCYTOKEN_SLOT_END; ++slot)
      addItem(player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
    addBagContents(INVENTORY_SLOT_BAG_START, INVENTORY_SLOT_BAG_END);
    addBagContents(BANK_SLOT_BAG_START, BANK_SLOT_BAG_END);
    return itemIds;
  }

    static std::optional<ItemPatchRow> FindItemRow(PreparedPatchRows const& rows, uint32 itemId)
    {
        if (rows.SqlItemIds.contains(itemId) && !Ascension::ClientItemPatches::Instance().Contains(itemId))
            return std::nullopt;
        if (auto const row = rows.ItemRowIndexById.find(itemId); row != rows.ItemRowIndexById.end())
            return rows.Items[row->second];
        return ItemScaling::ClientRow(itemId);
    }

    PatchRowTally SendItemRows(Player* player, PreparedPatchRows const& rows, std::vector<ItemPatchRow> itemRows)
    {
        PatchRowTally sent;
        std::lock_guard lock(_mutex);
        std::unordered_set<uint32>& sentItemRows = _sentItemRows[player->GetGUID().GetCounter()];
        std::unordered_set<uint32>& sentItemSpellRows = _sentItemSpellRows[player->GetGUID().GetCounter()];
        auto const sendItem = [&](ItemPatchRow const& row)
        {
            if (sentItemRows.insert(row[0]).second)
            {
                sent.Bytes += SendItemRow(player, row);
                ++sent.Rows;
            }
        };
        for (std::size_t index : rows.ItemCapacityOrder)
            if (auto const capacity = FindItemRow(rows, rows.Items[index][0]))
            {
                sendItem(*capacity);
                break;
            }
        for (ItemPatchRow const& row : itemRows)
        {
            if (ItemTemplate const* item = sObjectMgr->GetItemTemplate(row[0]))
                for (auto const& spell : item->Spells)
                    if (spell.SpellId > 0 && Ascension::ClientSpellPatches::Instance().Contains(spell.SpellId,
                        Ascension::ClientSpellPatches::Delivery::Item))
                        if (auto const found = rows.SpellRowIndexById.find(spell.SpellId);
                            found != rows.SpellRowIndexById.end() && sentItemSpellRows.insert(spell.SpellId).second)
                        {
                            SpellPatchRow active = rows.Spells[found->second];
                            ApplyServerSpellSelectors(active);
                            sent.Bytes += SendSpellRow(player, active);
                            ++sent.SpellRows;
                        }
            sendItem(row);
        }
        return sent;
    }

  static std::size_t SendRowPacket(Player *player, WorldPacket const &packet) {
    player->GetSession()->SendPacket(&packet);
    return packet.size();
  }

  static void AppendSizedString(WorldPacket &packet, std::string const &text) {
    packet << uint32(text.size());
    if (!text.empty())
      packet.append(reinterpret_cast<uint8 const *>(text.data()), text.size());
  }

  std::size_t SendLoadingScreenRow(Player *player) const {
    WorldPacket packet(SMSG_PATCH_LOADING_SCREENS, 24);
    uint8 loadingScreenRow[16] = {};
    packet.append(loadingScreenRow, sizeof(loadingScreenRow));
    packet << uint32(0) << uint32(0);
    return SendRowPacket(player, packet);
  }

  std::size_t SendDisplayInfoRow(Player *player,
                                 CreatureDisplayInfoEntry const &entry) const {
    WorldPacket packet(SMSG_PATCH_CREATURE_DISPLAY_INFO, 80);

    uint32 const soundId = 0;
    uint8 displayRow[64] = {};
    std::memcpy(displayRow + 0x00, &entry.Displayid, sizeof(uint32));
    std::memcpy(displayRow + 0x04, &entry.ModelId, sizeof(uint32));
    std::memcpy(displayRow + 0x08, &soundId, sizeof(uint32));
    std::memcpy(displayRow + 0x0C, &entry.ExtendedDisplayInfoID, sizeof(uint32));
    std::memcpy(displayRow + 0x10, &entry.scale, sizeof(float));
    displayRow[0x14] = 255;

    packet.append(displayRow, sizeof(displayRow));
    for (uint8 stringIndex = 0; stringIndex < 4; ++stringIndex)
      packet << uint32(0);

    return SendRowPacket(player, packet);
  }

  std::size_t SendCreatureModelRow(Player *player,
                                   CreatureModelPatchRow const &row) const {
    WorldPacket packet(SMSG_PATCH_CREATURE_MODEL_DATA,
                       row.Values.size() * sizeof(uint32) + sizeof(uint32) + row.ModelName.size());
    for (uint32 value : row.Values)
      packet << value;
    AppendSizedString(packet, row.ModelName);
    return SendRowPacket(player, packet);
  }

  std::size_t SendItemDisplayInfoRow(Player *player,
                                     ItemDisplayInfoPatchRow const &row) const {
    WorldPacket packet(SMSG_PATCH_ITEM_DISPLAY_INFO, 160);
    for (uint32 value : row.Values)
      packet << value;
    for (std::string const &text : row.Strings)
      AppendSizedString(packet, text);
    return SendRowPacket(player, packet);
  }

  std::size_t SendItemRow(Player *player, ItemPatchRow const &row) const {
    WorldPacket packet(SMSG_PATCH_ITEM, row.size() * sizeof(uint32));
    for (uint32 value : row)
      packet << value;
    return SendRowPacket(player, packet);
  }

  std::size_t SendSpellRow(Player *player, SpellPatchRow const &row) const {
    WorldPacket packet(SMSG_PATCH_SPELL,
                       row.Values.size() * sizeof(uint32) + 1024);
    for (uint32 value : row.Values)
      packet << value;
    for (std::string const &text : row.Strings)
      AppendSizedString(packet, text);
    return SendRowPacket(player, packet);
  }

  std::size_t SendSuperTrackRow(Player *player,
                                SuperTrackPatchRow const &row) const {
    WorldPacket packet(SMSG_PATCH_SUPER_TRACK, row.size() * sizeof(uint32));
    for (uint32 value : row)
      packet << value;
    return SendRowPacket(player, packet);
  }

    static std::size_t SendSkillLineAbilityRow(Player* player, SkillLineAbilityPatchRow const& row)
    {
        WorldPacket packet(SMSG_PATCH_SKILL_LINE_ABILITY, row.size() * sizeof(uint32));
        for (uint32 value : row)
            packet << value;
        return SendRowPacket(player, packet);
    }

    static std::vector<SkillLineAbilityPatchRow> LoadSkillLineAbilityPatchRows()
    {
        std::vector<SkillLineAbilityPatchRow> rows;
        PreparedQueryResult result = WorldDatabase.Query(
            WorldDatabase.GetPreparedStatement(WORLD_SEL_CLIENT_SKILL_LINE_ABILITIES));
        if (!result)
            return rows;

        std::map<uint32, uint32> skillLines;
        do
        {
            Field const* fields = result->Fetch();
            uint32 const id = fields[0].Get<uint32>();
            uint32 const skillLine = fields[1].Get<uint32>();
            if (sSkillLineStore.LookupEntry(skillLine))
                skillLines[id] = skillLine;
            else
                LOG_ERROR("coa", "coa_client_skill_line_ability {} has unknown SkillLine {}", id, skillLine);
        } while (result->NextRow());

        ClientDBC abilities;
        std::filesystem::path const serverDbc =
            std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "SkillLineAbility.dbc";
        if (!abilities.Load(serverDbc.string(), SKILL_LINE_ABILITY_DBC_FIELD_COUNT))
        {
            LOG_ERROR("coa", "Cannot read {}; skill line ability patches are not streamed", serverDbc.generic_string());
            return rows;
        }

        for (uint32 index = 0; index < abilities.GetRecordCount(); ++index)
        {
            ClientDBC::Record const record = abilities.GetRecord(index);
            auto const skillLine = skillLines.find(record.GetUInt32(0));
            if (skillLine == skillLines.end())
                continue;

            SkillLineAbilityPatchRow& row = rows.emplace_back();
            for (uint32 field = 0; field < row.size(); ++field)
                row[field] = record.GetUInt32(field);
            row[1] = skillLine->second;
            skillLines.erase(skillLine);
        }

        for (auto const& [id, skillLine] : skillLines)
            LOG_ERROR("coa", "coa_client_skill_line_ability {} has no SkillLineAbility.dbc row", id);
        return rows;
    }

  std::size_t SendShapeshiftFormRow(Player *player,
                                   ShapeshiftFormPatchRow const &row) const {
    WorldPacket packet(SMSG_PATCH_SPELL_SHAPESHIFT_FORM,
                       row.Values.size() * sizeof(uint32) + sizeof(uint32) + row.Name.size());
    for (uint32 value : row.Values)
      packet << value;
    AppendSizedString(packet, row.Name);
    return SendRowPacket(player, packet);
  }

  static std::vector<ShapeshiftFormPatchRow> LoadShapeshiftFormPatchRows() {
    std::vector<ShapeshiftFormPatchRow> rows;
    QueryResult result = WorldDatabase.Query(
        "SELECT `ID`, `BonusActionBar` FROM `coa_client_shapeshift_form` ORDER BY `ID`");
    if (!result)
      return rows;

    std::map<uint32, uint32> bonusBars;
    do {
      Field const *fields = result->Fetch();
      bonusBars[fields[0].Get<uint32>()] = fields[1].Get<uint32>();
    } while (result->NextRow());

    ClientDBC forms;
    std::filesystem::path const serverDbc =
        std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "SpellShapeshiftForm.dbc";
    if (!forms.Load(serverDbc.string(), SHAPESHIFT_FORM_DBC_FIELD_COUNT))
    {
      LOG_ERROR("coa", "Cannot read {}; coa_client_shapeshift_form rows are not streamed", serverDbc.generic_string());
      return rows;
    }

    for (uint32 index = 0; index < forms.GetRecordCount(); ++index)
    {
      ClientDBC::Record const record = forms.GetRecord(index);
      auto const bonusBar = bonusBars.find(record.GetUInt32(0));
      if (bonusBar == bonusBars.end())
        continue;

      ShapeshiftFormPatchRow &row = rows.emplace_back();
      row.Values[0] = bonusBar->first;
      row.Values[1] = bonusBar->second;
      for (uint32 slot = 2; slot < row.Values.size(); ++slot)
        row.Values[slot] = record.GetUInt32(SHAPESHIFT_FORM_FIRST_NUMERIC_FIELD + slot - 2);
      row.Name = std::string(record.GetString(SHAPESHIFT_FORM_NAME_FIELD));
      bonusBars.erase(bonusBar);
    }

    for (auto const &[form, bonusBar] : bonusBars)
      LOG_ERROR("coa", "coa_client_shapeshift_form {} has no SpellShapeshiftForm.dbc row", form);
    return rows;
  }

  static std::vector<SuperTrackPatchRow> LoadSuperTrackPatchRows() {
    std::vector<SuperTrackPatchRow> rows;
    QueryResult result = WorldDatabase.Query(
        "SELECT `ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, "
        "`Radius`, `NextID`, `Flags` FROM `coa_client_super_track` ORDER BY `ID`");
    if (!result)
      return rows;

    do {
      Field const *fields = result->Fetch();
      SuperTrackPatchRow &row = rows.emplace_back();
      row[0] = fields[0].Get<uint32>();
      row[1] = fields[1].Get<uint32>();
      for (uint8 index = 2; index < 6; ++index)
        row[index] = std::bit_cast<uint32>(fields[index].Get<float>());
      row[6] = fields[6].Get<uint32>();
      row[7] = fields[7].Get<uint32>();
    } while (result->NextRow());

    return rows;
  }

  PreparedPatchRows const &GetPreparedPatchRows() {
    std::lock_guard lock(_cacheMutex);
    if (!_rowsPrepared)
    {
      std::filesystem::path const clientDbcDirectory =
          ResolveClientDbcDirectory();
      _rows.CreatureDisplayIds = BuildDisplayPatchRows(clientDbcDirectory);
      _rows.ItemDisplayInfos =
          BuildItemDisplayInfoPatchRows(clientDbcDirectory);
      _rows.Items = BuildItemPatchRows(clientDbcDirectory, _rows.SqlItemIds);
      for (std::size_t index = 0; index < _rows.Items.size(); ++index)
      {
        _rows.ItemRowIndexById.emplace(_rows.Items[index][0], index);
        _rows.ItemCapacityOrder.push_back(index);
      }
      std::sort(_rows.ItemCapacityOrder.begin(), _rows.ItemCapacityOrder.end(),
          [this](std::size_t left, std::size_t right) { return _rows.Items[left][0] > _rows.Items[right][0]; });
      _rows.Spells = BuildSpellPatchRows();
      for (std::size_t index = 0; index < _rows.Spells.size(); ++index)
        _rows.SpellRowIndexById.emplace(_rows.Spells[index].Values[0], index);
      _rows.SuperTracks = LoadSuperTrackPatchRows();
      _rows.SkillLineAbilities = LoadSkillLineAbilityPatchRows();
      _rows.ShapeshiftForms = LoadShapeshiftFormPatchRows();
      _rows.CreatureModels = BuildCreatureModelPatchRows();
      _rowsPrepared = true;
    }
    return _rows;
  }

  static std::filesystem::path ResolveClientDbcDirectory() {
    std::string const configuredDirectory(
        ascensionCompatConfig.GetConfigValue<std::string>(
            AscensionCompatConfig::CLIENT_DBC_DIRECTORY));
    if (!configuredDirectory.empty())
      return configuredDirectory;
    return std::filesystem::path(sWorld->GetDataPath()) / "dbc_clientset";
  }

  static std::optional<std::unordered_set<uint32>>
  LoadDbcIds(std::filesystem::path const &path, uint32 minimumDWords) {
    ClientDBC file;
    if (!file.Load(path.string(), minimumDWords))
      return std::nullopt;

    std::unordered_set<uint32> ids;
    ids.reserve(file.GetRecordCount());
    for (uint32 row = 0; row < file.GetRecordCount(); ++row)
      ids.insert(file.GetRecord(row).GetUInt32(0));
    return ids;
  }

  static bool IsItemDisplayInfoStringField(uint8 field) {
    return std::ranges::find(ITEM_DISPLAY_INFO_STRING_FIELDS, field) !=
           ITEM_DISPLAY_INFO_STRING_FIELDS.end();
  }

  static std::vector<ItemDisplayInfoPatchRow>
  BuildItemDisplayInfoPatchRows(std::filesystem::path const &clientDbcDirectory) {
    std::vector<ItemDisplayInfoPatchRow> rows = LoadItemDisplayInfoPatchRows();

    std::filesystem::path const clientDbc =
        clientDbcDirectory / "ItemDisplayInfo.dbc";
    std::optional<std::unordered_set<uint32>> const clientIds =
        LoadDbcIds(clientDbc, ITEM_DISPLAY_INFO_FIELD_COUNT);
    if (!clientIds)
    {
      LOG_WARN("coa",
               "Client DBC copy {} is unavailable; streaming only the "
               "itemdisplayinfo_dbc rows",
               clientDbc.generic_string());
      return rows;
    }

    std::unordered_set<uint32> overriddenIds;
    for (ItemDisplayInfoPatchRow const &row : rows)
      overriddenIds.insert(row.Values[0]);

    ClientDBC serverDisplays;
    std::filesystem::path const serverDbc =
        std::filesystem::path(sWorld->GetDataPath()) / "dbc" /
        "ItemDisplayInfo.dbc";
    if (!serverDisplays.Load(serverDbc.string(), ITEM_DISPLAY_INFO_FIELD_COUNT))
      return rows;

    for (uint32 index = 0; index < serverDisplays.GetRecordCount(); ++index) {
      ClientDBC::Record const record = serverDisplays.GetRecord(index);
      uint32 const displayId = record.GetUInt32(0);
      if (clientIds->contains(displayId) || overriddenIds.contains(displayId))
        continue;

      ItemDisplayInfoPatchRow &row = rows.emplace_back();
      std::size_t stringIndex = 0;
      for (uint8 field = 0; field < ITEM_DISPLAY_INFO_FIELD_COUNT; ++field) {
        if (IsItemDisplayInfoStringField(field))
          row.Strings[stringIndex++] = std::string(record.GetString(field));
        else
          row.Values[field] = record.GetUInt32(field);
      }
    }

    return rows;
  }

  static std::vector<CreatureModelPatchRow> BuildCreatureModelPatchRows() {
    std::vector<CreatureModelPatchRow> rows;
    ClientDBC clientModels;
    std::filesystem::path const clientDbc =
        std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "CreatureModelData.dbc";
    if (!clientModels.Load(clientDbc.string(), CREATURE_MODEL_DATA_FIELD_COUNT))
      return rows;

    for (uint32 index = 0; index < clientModels.GetRecordCount(); ++index) {
      ClientDBC::Record const record = clientModels.GetRecord(index);
      CreatureModelDataEntry const *entry =
          sCreatureModelDataStore.LookupEntry(record.GetUInt32(0));
      if (!entry)
        continue;

      std::array<std::pair<uint32, uint32>, 5> const serverFields = {{
          {1, entry->Flags},
          {4, std::bit_cast<uint32>(entry->Scale)},
          {14, std::bit_cast<uint32>(entry->CollisionWidth)},
          {15, std::bit_cast<uint32>(entry->CollisionHeight)},
          {16, std::bit_cast<uint32>(entry->MountHeight)}}};
      auto const matchesClient = [&record](auto const &field) {
        return record.GetUInt32(field.first) == field.second;
      };
      if (std::ranges::all_of(serverFields, matchesClient))
        continue;

      CreatureModelPatchRow &row = rows.emplace_back();
      for (uint32 field = 0; field < CREATURE_MODEL_DATA_FIELD_COUNT; ++field)
        if (field != CREATURE_MODEL_DATA_NAME_FIELD)
          row.Values[field] = record.GetUInt32(field);
      for (auto const &[field, value] : serverFields)
        row.Values[field] = value;
      row.ModelName = std::string(record.GetString(CREATURE_MODEL_DATA_NAME_FIELD));
    }

    return rows;
  }

  static std::vector<ItemPatchRow>
  BuildItemPatchRows(std::filesystem::path const &clientDbcDirectory, std::unordered_set<uint32>& sqlIds) {
    std::vector<ItemPatchRow> rows = LoadItemPatchRows(sqlIds);

    std::filesystem::path const clientDbc = clientDbcDirectory / "Item.dbc";
    std::optional<std::unordered_set<uint32>> const clientIds =
        LoadDbcIds(clientDbc, std::tuple_size_v<ItemPatchRow>);
    if (!clientIds)
    {
      LOG_WARN("coa",
               "Client DBC copy {} is unavailable; streaming only the item_dbc "
               "rows",
               clientDbc.generic_string());
      return rows;
    }

    std::unordered_set<uint32> overriddenIds;
    for (ItemPatchRow const &row : rows)
      overriddenIds.insert(row[0]);

    for (uint32 itemId = 0; itemId < sItemStore.GetNumRows(); ++itemId) {
      ItemEntry const *entry = sItemStore.LookupEntry(itemId);
      if (!entry || clientIds->contains(itemId) ||
          overriddenIds.contains(itemId) || sqlIds.contains(itemId))
        continue;

      rows.push_back({entry->ID, entry->ClassID, entry->SubclassID,
                      static_cast<uint32>(entry->SoundOverrideSubclassID),
                      static_cast<uint32>(entry->Material),
                      entry->DisplayInfoID, entry->InventoryType,
                      entry->SheatheType});
    }

    return rows;
  }

  static uint32 RangedPreparationCastTimeIndex(int32 base) {
    static std::unordered_map<int32, uint32> const rows = [] {
      std::unordered_map<int32, uint32> found;
      for (uint32 id = 0; id < 4096; ++id)
        if (SpellCastTimesEntry const *entry = sSpellCastTimesStore.LookupEntry(id))
          if (entry->CastTime > 0)
            found.emplace(entry->CastTime, id);
      return found;
    }();
    auto const row = rows.find(base + 500);
    return row == rows.end() ? 0 : row->second;
  }

  static void ApplyServerSpellSelectors(SpellPatchRow &row) {
    SpellInfo const *info = sSpellMgr->GetSpellInfo(row.Values[0]);
    if (!info)
      return;

    if (info->Id == AscensionSunCleric::DawnCast)
    {
      row.Values[SPELL_WIRE_SLOT(SPELL_CASTER_AURA_SPELL_FIELD)] = info->CasterAuraSpell;
      row.Values[SPELL_WIRE_SLOT(SPELL_EXCLUDE_CASTER_AURA_SPELL_FIELD)] = info->ExcludeCasterAuraSpell;
    }
    if (info->Id == AscensionSunCleric::Dawn)
      row.Values[4] = info->Attributes;

    if ((info->Attributes & SPELL_ATTR0_USES_RANGED_SLOT) && !info->IsAutoRepeatRangedSpell() &&
        info->CastTimeEntry && (info->CastTimeEntry->CastTime > 0 || !info->IsChanneled()))
      if (uint32 const prepared = RangedPreparationCastTimeIndex(info->CastTimeEntry->CastTime))
        row.Values[SPELL_CAST_TIME_INDEX_FIELD] = prepared;

    row.Values[144] = info->SpellFamilyName;
    row.Values[12] = info->Stances;
    row.Values[14] = info->StancesNot;
    Ascension::ClientSpellPatches::Selector const selector =
        Ascension::ClientSpellPatches::Instance().GetSelector(info->Id);
    for (uint32 index = 0; index < 3; ++index)
    {
      row.Values[145 + index] = info->SpellFamilyFlags[index] | selector[index];
      for (uint32 effect = 0; effect < MAX_SPELL_EFFECTS; ++effect)
        row.Values[122 + effect * 3 + index] =
            info->Effects[effect].SpellClassMask[index];
    }
  }

  static std::vector<SpellPatchRow> LoadSqlSpellPatchRows(std::unordered_set<uint32> const& requested) {
    std::vector<SpellPatchRow> rows;
    std::vector<uint32> ordered(requested.begin(), requested.end());
    std::sort(ordered.begin(), ordered.end());
    for (uint32 id : ordered)
    {
      WorldDatabasePreparedStatement* statement = WorldDatabase.GetPreparedStatement(WORLD_SEL_CLIENT_SPELL_PATCHES);
      statement->SetData(0, id);
      PreparedQueryResult result = WorldDatabase.Query(statement);
      if (!result)
        continue;
      if (result->GetFieldCount() != SPELL_DBC_FIELD_COUNT)
      {
        LOG_ERROR("coa", "spell_dbc has {} columns; the spell patch stream requires {}",
                  result->GetFieldCount(), SPELL_DBC_FIELD_COUNT);
        return {};
      }

      static_assert(sizeof(SpellEntryfmt) - 1 == SPELL_DBC_FIELD_COUNT);
      Field const *fields = result->Fetch();
      SpellPatchRow &row = rows.emplace_back();
      std::size_t slot = 0;
      for (uint32 field = 0; field < SPELL_DBC_FIELD_COUNT;)
      {
        bool const localized =
            field >= SPELL_NAME_FIELD && field <= SPELL_TOOLTIP_FIELD;
        if (localized)
          row.Values[slot] = 0;
        else if (SpellEntryfmt[field] == 'f')
          row.Values[slot] = std::bit_cast<uint32>(fields[field].Get<float>());
        else if (field == 12 || field == 14)
          row.Values[slot] = static_cast<uint32>(fields[field].Get<uint64>());
        else
          row.Values[slot] = fields[field].Get<uint32>();
        ++slot;
        field += localized ? LOCALIZED_STRING_DWORDS : 1;
      }
      for (std::size_t text = 0; text < SPELL_WIRE_STRING_FIELDS.size(); ++text)
        row.Strings[text] = fields[SPELL_WIRE_STRING_FIELDS[text]].Get<std::string>();
      ApplyServerSpellSelectors(row);
    }
    return rows;
  }

  static std::vector<SpellPatchRow> BuildSpellPatchRows() {
    std::unordered_map<uint32, ClientSpellText> descriptions =
        LoadClientSpellDescriptions();
    std::unordered_set<uint32> descriptionIds;
    for (uint32 const spellId : RANGED_PREPARATION_CLIENT_SPELLS)
      Ascension::ClientSpellPatches::Instance().Register(spellId);
    std::unordered_set<uint32> requested = Ascension::ClientSpellPatches::Instance().GetIds(true);
    for (auto const& [id, description] : descriptions)
    {
      requested.insert(id);
      descriptionIds.insert(id);
    }
    std::vector<SpellPatchRow> rows = LoadSqlSpellPatchRows(requested);
    std::unordered_map<uint32, std::size_t> overridden;
    for (std::size_t index = 0; index < rows.size(); ++index)
    {
      overridden.emplace(rows[index].Values[0], index);
      requested.erase(rows[index].Values[0]);
    }

    std::unordered_map<uint32, uint32> rankTrainingLevels;
    for (AscensionProgression::Rank const& rank : AscensionProgression::Ranks)
      rankTrainingLevels.emplace(rank.SpellId, rank.RequiredLevel);

    ClientDBC spells;
    std::filesystem::path const serverDbc =
        std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "Spell.dbc";
    if (spells.Load(serverDbc.string(), SPELL_DBC_FIELD_COUNT))
    {
      for (uint32 index = 0; index < spells.GetRecordCount(); ++index)
      {
        ClientDBC::Record const record = spells.GetRecord(index);
        uint32 const id = record.GetUInt32(0);
        uint32 const excludedAura =
            record.GetUInt32(SPELL_EXCLUDE_CASTER_AURA_SPELL_FIELD);
        uint32 const clientExcludedAura =
            AscensionBloodmage::RuntimeExcludeCasterAuraSpell(
                record.GetUInt32(SPELL_FAMILY_NAME_FIELD), excludedAura);
        bool const redirectsExclusion = clientExcludedAura != excludedAura;
        bool const restrictingFormGated =
            clientExcludedAura == AscensionBloodmage::CursedForm;
        auto const trainingLevel = rankTrainingLevels.find(id);
        bool const raisesRankLevel =
            trainingLevel != rankTrainingLevels.end() &&
            record.GetUInt32(SPELL_LEVEL_FIELD) < trainingLevel->second;

        auto const overlay = overridden.find(id);
        auto const description = descriptions.find(id);
        if (overlay == overridden.end() && description == descriptions.end() &&
            !requested.contains(id) && !redirectsExclusion &&
            !restrictingFormGated && !raisesRankLevel)
          continue;

        std::size_t const rowIndex = overlay == overridden.end() ? rows.size() : overlay->second;
        if (overlay == overridden.end())
        {
          SpellPatchRow &row = rows.emplace_back();
          std::size_t slot = 0;
          for (uint32 field = 0; field < SPELL_DBC_FIELD_COUNT;)
          {
            bool const localized =
                field >= SPELL_NAME_FIELD && field <= SPELL_TOOLTIP_FIELD;
            row.Values[slot++] = localized ? 0 : record.GetUInt32(field);
            field += localized ? LOCALIZED_STRING_DWORDS : 1;
          }
          ApplyServerSpellSelectors(row);
        }

        SpellPatchRow &row = rows[rowIndex];
        for (std::size_t text = 0; text < SPELL_WIRE_STRING_FIELDS.size(); ++text)
          if (row.Strings[text].empty())
            row.Strings[text] = std::string(record.GetString(SPELL_WIRE_STRING_FIELDS[text]));
        if (description != descriptions.end())
        {
          row.Strings[SPELL_WIRE_DESCRIPTION] = description->second.Description;
          if (!description->second.ToolTip.empty())
            row.Strings[SPELL_WIRE_TOOLTIP] = description->second.ToolTip;
          descriptions.erase(description);
        }
        if (redirectsExclusion)
          row.Values[SPELL_WIRE_SLOT(SPELL_EXCLUDE_CASTER_AURA_SPELL_FIELD)] =
              clientExcludedAura;
        if (restrictingFormGated)
        {
          RedirectCursedFormCheck(row.Strings[SPELL_WIRE_DESCRIPTION]);
          RedirectCursedFormCheck(row.Strings[SPELL_WIRE_TOOLTIP]);
          Ascension::ClientSpellPatches::Instance().Register(id);
        }
        if (raisesRankLevel)
        {
          row.Values[SPELL_WIRE_SLOT(SPELL_LEVEL_FIELD)] = trainingLevel->second;
          Ascension::ClientSpellPatches::Instance().Register(id);
        }
        requested.erase(id);
      }
    }

    for (auto const &[id, index] : overridden)
    {
      auto const description = descriptions.find(id);
      if (description != descriptions.end())
      {
        rows[index].Strings[SPELL_WIRE_DESCRIPTION] = description->second.Description;
        if (!description->second.ToolTip.empty())
          rows[index].Strings[SPELL_WIRE_TOOLTIP] = description->second.ToolTip;
        descriptions.erase(description);
      }
    }
    for (auto const &[spellId, text] : descriptions)
      LOG_ERROR("coa", "coa_client_spell_description {} has no physical or SQL Spell record", spellId);
    for (uint32 spellId : requested)
      LOG_ERROR("coa", "Requested client Spell patch {} has no physical or SQL record", spellId);

    for (SpellPatchRow& row : rows)
      row.RequiresRegistration = !descriptionIds.contains(row.Values[0]);
    return rows;
  }

  static void RedirectCursedFormCheck(std::string &text) {
    std::string const from =
        "$?a" + std::to_string(AscensionBloodmage::CursedFormCheck);
    std::string const to =
        "$?a" + std::to_string(AscensionBloodmage::CursedForm);
    for (std::size_t pos = text.find(from); pos != std::string::npos;
         pos = text.find(from, pos + to.size()))
      text.replace(pos, from.size(), to);
  }

  static std::unordered_map<uint32, ClientSpellText> LoadClientSpellDescriptions() {
    std::unordered_map<uint32, ClientSpellText> descriptions;
    PreparedQueryResult result = WorldDatabase.Query(
        WorldDatabase.GetPreparedStatement(WORLD_SEL_CLIENT_SPELL_DESCRIPTIONS));
    if (!result)
      return descriptions;

    do {
      Field const *fields = result->Fetch();
      ClientSpellText &text = descriptions[fields[0].Get<uint32>()];
      text.Description = fields[1].Get<std::string>();
      if (!fields[2].IsNull())
        text.ToolTip = fields[2].Get<std::string>();
    } while (result->NextRow());

    return descriptions;
  }

  static std::vector<ItemDisplayInfoPatchRow> LoadItemDisplayInfoPatchRows() {
    std::vector<ItemDisplayInfoPatchRow> rows;
    QueryResult result = WorldDatabase.Query(
        "SELECT `ID`, `ModelName_1`, `ModelName_2`, `ModelTexture_1`, "
        "`ModelTexture_2`, `InventoryIcon_1`, `InventoryIcon_2`, "
        "`GeosetGroup_1`, `GeosetGroup_2`, `GeosetGroup_3`, `Flags`, "
        "`SpellVisualID`, `GroupSoundIndex`, `HelmetGeosetVis_1`, "
        "`HelmetGeosetVis_2`, `Texture_1`, `Texture_2`, `Texture_3`, "
        "`Texture_4`, `Texture_5`, `Texture_6`, `Texture_7`, `Texture_8`, "
        "`ItemVisual`, `ParticleColorID` FROM `itemdisplayinfo_dbc` "
        "ORDER BY `ID`");
    if (!result)
      return rows;

    do {
      Field const *fields = result->Fetch();
      ItemDisplayInfoPatchRow &row = rows.emplace_back();
      std::size_t stringIndex = 0;
      for (uint8 field = 0; field < ITEM_DISPLAY_INFO_FIELD_COUNT; ++field) {
        if (IsItemDisplayInfoStringField(field))
          row.Strings[stringIndex++] = fields[field].Get<std::string>();
        else
          row.Values[field] = static_cast<uint32>(fields[field].Get<int32>());
      }
    } while (result->NextRow());

    return rows;
  }

  static std::vector<ItemPatchRow> LoadItemPatchRows(std::unordered_set<uint32>& sqlIds) {
    std::vector<ItemPatchRow> rows;
    std::unordered_set<uint32> const requested = Ascension::ClientItemPatches::Instance().GetIds(true);
    QueryResult result = WorldDatabase.Query(
        "SELECT `ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, "
        "`Material`, `DisplayInfoID`, `InventoryType`, `SheatheType` "
        "FROM `item_dbc` ORDER BY `ID`");
    if (!result)
      return rows;

    do {
      Field const *fields = result->Fetch();
      uint32 const id = fields[0].Get<uint32>();
      sqlIds.insert(id);
      if (!requested.contains(id))
        continue;
      ItemPatchRow &row = rows.emplace_back();
      for (std::size_t field = 0; field < row.size(); ++field)
        row[field] = static_cast<uint32>(fields[field].Get<int32>());
    } while (result->NextRow());

    return rows;
  }

  std::vector<uint32>
  BuildDisplayPatchRows(std::filesystem::path const &clientDbcDirectory) const {
    std::filesystem::path const clientDbc =
        clientDbcDirectory / "CreatureDisplayInfo.dbc";
    std::optional<std::unordered_set<uint32>> const clientDisplayIds =
        LoadDbcIds(clientDbc, 16);
    bool const haveClientSet = clientDisplayIds.has_value();
    if (!haveClientSet)
    {
      LOG_WARN("coa",
               "Client DBC copy {} is unavailable; streaming every display id "
               "at or above {} instead of the exact missing set",
               clientDbc.generic_string(), CUSTOM_DISPLAY_ID_FALLBACK_MIN);
    }

    std::vector<uint32> rows;
    for (uint32 displayId = 0;
         displayId < sCreatureDisplayInfoStore.GetNumRows(); ++displayId) {
      if (!sCreatureDisplayInfoStore.LookupEntry(displayId))
        continue;

      if (haveClientSet)
      {
        if (clientDisplayIds->contains(displayId))
          continue;
      }
      else if (displayId < CUSTOM_DISPLAY_ID_FALLBACK_MIN)
      {
        continue;
      }

      rows.push_back(displayId);
    }

    return rows;
  }

  std::mutex _mutex;
  std::unordered_set<uint32> _streamedPlayers;
  std::unordered_map<uint32, std::unordered_set<uint32>> _sentItemRows;
  std::unordered_map<uint32, std::unordered_set<uint32>> _sentItemSpellRows;
  std::unordered_map<uint32, PatchRowTally> _onDemandItemRows;
  struct FallbackResend
  {
    uint32 DelayMs;
    bool Force;
  };

  std::unordered_map<uint32, FallbackResend> _fallbackTimers;
  std::unordered_map<uint32, uint32> _lastStreamMs;

  std::mutex _cacheMutex;
  bool _rowsPrepared = false;
  PreparedPatchRows _rows;

  std::mutex _clientSpellMutex;
  ClientSpellFile _clientSpells;
  std::unordered_map<uint32, std::optional<SpellPatchRow>> _clientSpellRows;
  std::unordered_map<uint32, uint32> _clientFirstRanks;

  std::mutex _swapEntryMutex;
  std::unordered_map<uint32, uint32> _swapEntryIds;
  std::unordered_map<uint32, uint32> _swapEntrySpells;
  std::unordered_map<uint32, std::set<uint32>> _sentSwapEntries;
  std::vector<uint32> _freeEntryIds;
};

class AscensionCollectionService {
public:
    static bool IsCosmeticCategory(uint32 category)
    {
        return category >= 56 && category <= 58;
    }

    static uint32 ResolveCosmeticSpell(uint32 appearance, uint32 display, uint32 alternate)
    {
        if (appearance == 2992 || appearance == 51444 || appearance == 52428)
            return 0;
        if (appearance == 2714)
            display = 985235;
        if (appearance == 42965)
            display = 935566;
        if (!sSpellMgr->GetSpellInfo(display))
            display = alternate;

        std::unordered_set<uint32> visited;
        while (display && visited.insert(display).second && visited.size() <= 8)
        {
            SpellInfo const* spell = sSpellMgr->GetSpellInfo(display);
            if (!spell || spell->Effects[EFFECT_1].Effect || spell->Effects[EFFECT_2].Effect)
                return 0;
            SpellEffectInfo const& effect = spell->Effects[EFFECT_0];
            if (effect.Effect == SPELL_EFFECT_TRIGGER_SPELL)
            {
                display = effect.TriggerSpell;
                continue;
            }
            if (effect.IsAura() && (effect.ApplyAuraName == SPELL_AURA_DUMMY ||
                effect.ApplyAuraName == SPELL_AURA_MOD_SCALE ||
                (display == 1985213 && effect.ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL)))
                return display;
            return 0;
        }
        return 0;
    }

    static uint32 ResolveShadowhoundDisplay(uint32 creatureId)
    {
        auto const* model = FindCollectionModel(creatureId);
        return model && sCreatureDisplayInfoStore.LookupEntry(model->DisplayId) ? model->DisplayId : 0;
    }

  static AscensionCollectionService &Instance() {
    static AscensionCollectionService instance;
    return instance;
  }

  bool LoadClientData() {
    _appearances.clear();
    _itemAppearances.clear();
    _itemSetItems.clear();
    _vanityItems.clear();
    _allAppearanceIds.clear();
    _allVanityItemIds.clear();
    _woodworkingAppearancePatches.clear();
    _woodworkingItemAppearancePatches.clear();

    ClientDBC appearances;
    bool appearancesLoaded =
        appearances.Load(GetClientDBCPath("Appearances.dbc"), 9);
    for (uint32 row = 0; row < appearances.GetRecordCount(); ++row) {
      ClientDBC::Record record = appearances.GetRecord(row);
      uint32 appearanceId = record.GetUInt32(0);
      if (!appearanceId)
        continue;

      uint32 displayId = record.GetUInt32(3);
      _appearances[appearanceId] =
          AppearanceInfo{displayId, record.GetUInt32(5), record.GetUInt32(6),
                         record.GetUInt32(7), displayId};
      AppearanceInfo& appearance = _appearances[appearanceId];
      if (IsCosmeticCategory(appearance.PrimaryCategory))
        appearance.CosmeticSpell = ResolveCosmeticSpell(appearanceId,
            displayId, record.GetUInt32(8));
      if (appearance.PrimaryCategory == APPEARANCE_CATEGORY_SHADOWHOUND)
        appearance.CreatureDisplay = ResolveShadowhoundDisplay(displayId);
      if (appearance.PrimaryCategory == APPEARANCE_CATEGORY_TAMED_BEAST)
        appearance.CreatureEntry = record.GetUInt32(8);
      _allAppearanceIds.push_back(appearanceId);
    }

    ClientDBC itemAppearances;
    bool itemAppearancesLoaded =
        itemAppearances.Load(GetClientDBCPath("ItemAppearances.dbc"), 3);
    uint32 lastItemAppearanceRecordId = 0;
    for (uint32 row = 0; row < itemAppearances.GetRecordCount(); ++row) {
      ClientDBC::Record record = itemAppearances.GetRecord(row);
      lastItemAppearanceRecordId = std::max(lastItemAppearanceRecordId, record.GetUInt32(0));
      uint32 itemId = record.GetUInt32(1);
      uint32 appearanceId = record.GetUInt32(2);
      if (itemId && appearanceId)
        _itemAppearances[itemId] = appearanceId;
    }
    if (appearancesLoaded && itemAppearancesLoaded)
        LoadWoodworkingAppearances(lastItemAppearanceRecordId);

    std::unordered_map<uint32, uint32> equipmentAppearances;
    for (auto const& [id, appearance] : _appearances)
      if (IsEquipmentAppearance(appearance))
        equipmentAppearances.emplace(id, appearance.SourceItem);
    AscensionItemAppearanceAliases::AddAliases(_itemAppearances, equipmentAppearances);

    ClientDBC itemSets;
    bool itemSetsLoaded = itemSets.Load(GetClientDBCPath("ItemSet.dbc"), 35);
    for (uint32 row = 0; row < itemSets.GetRecordCount(); ++row) {
      ClientDBC::Record record = itemSets.GetRecord(row);
      uint32 itemSetId = record.GetUInt32(0);
      if (!itemSetId)
        continue;

      std::vector<uint32> &items = _itemSetItems[itemSetId];
      for (uint32 field = 18; field <= 34; ++field) {
        uint32 itemId = record.GetUInt32(field);
        if (itemId)
          items.push_back(itemId);
      }
    }

    ClientDBC vanity;
    bool vanityLoaded =
        vanity.Load(GetClientDBCPath("VanityCollection.dbc"), 77);
    for (uint32 row = 0; row < vanity.GetRecordCount(); ++row) {
      ClientDBC::Record record = vanity.GetRecord(row);
      uint32 itemId = record.GetUInt32(1);
      if (!itemId)
        continue;

      VanityInfo info{
          record.GetUInt32(76), record.GetUInt32(12), record.GetUInt32(2)};

      _vanityItems[itemId] = info;
      _allVanityItemIds.push_back(itemId);
    }

    std::sort(_allAppearanceIds.begin(), _allAppearanceIds.end());
    _allAppearanceIds.erase(
        std::unique(_allAppearanceIds.begin(), _allAppearanceIds.end()),
        _allAppearanceIds.end());

    LOG_INFO("coa",
             "Loaded Ascension collection data: {} appearances, {} item "
             "mappings, {} item sets, {} vanity entries",
             _appearances.size(), _itemAppearances.size(),
             _itemSetItems.size(), _vanityItems.size());

    if (!itemSetsLoaded)
      LOG_WARN("coa",
               "Ascension item-set expansion is unavailable; individual "
               "appearance categories remain usable");

    _clientDataLoaded =
        appearancesLoaded && itemAppearancesLoaded && vanityLoaded;
    return _clientDataLoaded;
  }

  void QueueClientPacket(uint32 accountId, WorldPacket const &packet) {
    std::lock_guard lock(_packetMutex);
    std::deque<WorldPacket> &queue = _pendingPackets[accountId];
    auto const isWorldEntryNotice = [](WorldPacket const& queued)
    {
      return queued.GetOpcode() == CMSG_EXTENSION_INITIALIZED;
    };
    if (isWorldEntryNotice(packet))
      queue.erase(std::remove_if(queue.begin(), queue.end(), isWorldEntryNotice), queue.end());

    if (queue.size() >= MAX_QUEUED_EXTENSION_PACKETS)
    {
      RejectClientPacket(accountId, packet, "its queue is full");
      return;
    }

    if (isWorldEntryNotice(packet))
      queue.emplace_front(packet);
    else
      queue.emplace_back(packet);
  }

  void RejectClientPacket(uint32 accountId, WorldPacket const& packet, std::string_view reason)
  {
    std::lock_guard lock(_rejectedPacketMutex);
    uint32 const rejected = ++_rejectedPackets[accountId];
    if (std::has_single_bit(rejected))
      LOG_WARN("coa", "Rejected Ascension extension packet 0x{:04X} ({} bytes) from account {}: {}; {} rejected so far",
          packet.GetOpcode(), packet.size(), accountId, reason, rejected);
  }

  static bool LoadsCollectionsForBot(Player *player) {
    uint32 const mode = ascensionCompatConfig.GetConfigValue<uint32>(
        AscensionCompatConfig::COLLECTIONS_FOR_BOTS);
    if (mode != 1)
      return mode >= 2;
    uint32 const accountId = player->GetSession()->GetAccountId();
    std::string const prefix = ascensionCompatConfig.GetConfigValue<std::string>(
        AscensionCompatConfig::RANDOM_BOT_ACCOUNT_PREFIX);
    static std::mutex cacheMutex;
    static std::string cachedPrefix;
    static std::unordered_map<uint32, bool> playerAccounts;
    {
      std::lock_guard lock(cacheMutex);
      if (cachedPrefix != prefix)
      {
        playerAccounts.clear();
        cachedPrefix = prefix;
      }
      if (auto const found = playerAccounts.find(accountId); found != playerAccounts.end())
        return found->second;
    }
    std::string account;
    if (!AccountMgr::GetName(accountId, account))
      return false;
    bool const playerAccount = prefix.empty() || !StringStartsWithI(account, prefix);
    std::lock_guard lock(cacheMutex);
    if (cachedPrefix == prefix)
      playerAccounts[accountId] = playerAccount;
    return playerAccount;
  }

  void OnPlayerLogin(Player *player) {
    if (!_clientDataLoaded)
    {
      ChatHandler(player->GetSession())
          .SendSysMessage("Ascension collection data is unavailable; transmog "
                          "and vanity are disabled.");
      return;
    }

    if (player->GetSession()->IsBot() && !LoadsCollectionsForBot(player))
    {
      TakeLoginState(player);
      InitializeRiding(player);
      return;
    }

    SendWoodworkingAppearanceCatalog(player);

    std::shared_ptr<PlayerCollectionState> state = TakeLoginState(player);
    if (!state)
      state = LoadCollectionState(player);

    UnlockLocalAppearanceCatalog(player, *state);

    {
      std::lock_guard lock(_stateMutex);
      _playerStates[player->GetGUID().GetCounter()] = state;
    }

    if (ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::AUTO_COLLECT_APPEARANCES))
      ScanPlayerInventory(player, *state);

    BeginAppearanceCollectionSync(player, *state);
    state->LoginResyncTimer = APPEARANCE_LOGIN_RESYNC_DELAY_MS;
    SendActiveAppearances(player, *state);
    SendOutfitCollection(player, *state);
    SendAppearanceVisibility(player, *state);
    SendRealmInfo(player);
    SendGameModeState(player);
    SendVanityCollection(player, *state);
    RefreshVisibleItems(player);
    for (auto const& [id, appearance] : _appearances)
        if (appearance.CosmeticSpell)
            player->RemoveAurasDueToSpell(appearance.CosmeticSpell, player->GetGUID());
    RefreshCosmetics(player, *state);
    InitializeRiding(player);
    QueueOwnedCompanionSpells(player, *state);

    LOG_INFO("coa",
             "Synchronized Ascension collections for {}: {} appearances, {} "
             "saved vanity items",
             player->GetName(), state->CollectedAppearances.size(),
             state->OwnedVanityItems.size());
  }

  void OnPlayerLogout(Player *player) {
    {
      std::lock_guard lock(_stateMutex);
      _playerStates.erase(player->GetGUID().GetCounter());
      _loginStates.erase(player->GetGUID().GetCounter());
    }

    if (!ReceivesClientRequests(player))
      return;

    {
      std::lock_guard lock(_rejectedPacketMutex);
      _rejectedPackets.erase(player->GetSession()->GetAccountId());
    }

    std::lock_guard lock(_packetMutex);
    _pendingPackets.erase(player->GetSession()->GetAccountId());
  }

  [[nodiscard]] std::vector<WorldPacket> TakeClientPackets(uint32 accountId, bool outfitPending = false)
  {
    std::vector<WorldPacket> packets;
    std::lock_guard lock(_packetMutex);
    auto itr = _pendingPackets.find(accountId);
    if (itr == _pendingPackets.end())
      return packets;

    std::deque<WorldPacket> &queue = itr->second;
    std::size_t budget = MAX_EXTENSION_REPLIES_PER_UPDATE;
    while (!queue.empty())
    {
      uint16 const opcode = queue.front().GetOpcode();
      bool const outfit = opcode == CMSG_SAVE_APPEARANCE_OUTFIT || opcode == CMSG_DELETE_APPEARANCE_OUTFIT;
      if (outfit && outfitPending)
        break;

      std::size_t const replies = ExpectedReplies(queue.front());
      if (replies > budget)
        break;

      budget -= replies;
      packets.push_back(std::move(queue.front()));
      queue.pop_front();
      outfitPending |= outfit;
    }

    if (queue.empty())
      _pendingPackets.erase(itr);
    return packets;
  }

  void OnPlayerUpdate(Player *player, uint32 diff) {
    if (ReceivesClientRequests(player))
    {
      for (WorldPacket &packet : TakeClientPackets(player->GetSession()->GetAccountId(), HasPendingOutfitCommit(player->GetGUID())))
        HandleClientPacket(player, packet);
    }

    ProcessPendingAppearanceAdds(player, diff);
    ProcessPendingCompanionSpells(player, diff);
    ProcessCompanionLoot(player, diff);
    ProcessCompanionLoot(player, diff, true);
    if (auto state = GetState(player))
    {
        if (state->CosmeticTimer <= diff)
        {
            state->CosmeticTimer = 1000;
            RefreshCosmetics(player, *state);
        }
        else
            state->CosmeticTimer -= diff;
    }
  }

  bool HasPendingOutfitCommit(ObjectGuid guid)
  {
    std::lock_guard lock(_outfitMutex);
    return _pendingOutfitCommits.contains(guid.GetCounter());
  }

  void ProcessOutfitCallbacks()
  {
    std::lock_guard lock(_outfitMutex);
    _outfitCallbacks.ProcessReadyCallbacks();
  }

    void OnCosmeticCancelled(Player* player, uint32 spellId)
    {
        auto state = GetState(player);
        if (!state || !state->AppliedCosmeticSpells.contains(spellId))
            return;

        for (uint32 category = 56; category <= 58; ++category)
        {
            auto itr = _appearances.find(state->ActiveAppearances[category]);
            if (itr != _appearances.end() && itr->second.CosmeticSpell == spellId)
                state->ActiveAppearances[category] = 0;
        }
        state->AppliedCosmeticSpells.erase(spellId);
        SaveActiveAppearances(player, *state);
        SendActiveAppearances(player, *state);
    }

    void ProcessCompanionLoot(Player* player, uint32 diff, bool skin = false)
    {
        constexpr uint32 CREATURE_LOOTBOT_3000 = 44022;
        uint32 const category = skin ? APPEARANCE_CATEGORY_COMPANION_SKINNING : APPEARANCE_CATEGORY_COMPANION_LOOT;
        uint32 const appearance = skin ? APPEARANCE_SKIN_PEELER : APPEARANCE_LOOT_TRANSFIGURATOR;
        auto state = GetState(player);
        if (!state)
            return;

        bool const hasAppearance = state->ActiveAppearances[category] == appearance &&
            state->CollectedAppearances.contains(appearance);

        bool isLootbot = false;
        if (!skin && !hasAppearance)
        {
            Creature* c = player->GetMap()->GetCreature(player->GetCritterGUID());
            isLootbot = c && c->IsAlive() && c->GetOwnerGUID() == player->GetGUID() &&
                        c->GetEntry() == CREATURE_LOOTBOT_3000;
        }

        if (!hasAppearance && !isLootbot)
            return;

        uint32& timer = skin ? state->CompanionSkinningTimer : state->CompanionLootTimer;
        if (timer > diff)
        {
            timer -= diff;
            return;
        }
        SpellInfo const* spell = sSpellMgr->GetSpellInfo(skin ? SPELL_SKIN_PEELER : SPELL_LOOT_TRANSFIGURATOR);
        if (!spell || !spell->Effects[EFFECT_0].Amplitude)
            return;
        timer = spell->Effects[EFFECT_0].Amplitude;
        Creature* companion = player->GetMap()->GetCreature(player->GetCritterGUID());
        if (!companion || !companion->IsAlive() || companion->GetOwnerGUID() != player->GetGUID())
            return;
        float const radius = spell->Effects[EFFECT_0].CalcRadius(player);
        if (radius <= 0.0f)
            return;
        std::list<Creature*> corpses;
        companion->GetDeadCreatureListInGrid(corpses, radius, true);
        for (Creature* creature : corpses)
            player->LootCreatureWithCompanion(creature, radius, skin);
    }

    void InitializeRiding(Player* player) const
    {
        if (!ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::MAX_RIDING_FROM_START))
            return;

        for (uint32 spellId : {SPELL_RIDING_APPRENTICE, SPELL_RIDING_JOURNEYMAN,
            SPELL_RIDING_EXPERT, SPELL_RIDING_ARTISAN, SPELL_COLD_WEATHER_FLYING})
            if (sSpellMgr->GetSpellInfo(spellId) && !player->HasSpell(spellId))
                player->learnSpell(spellId, false);

        player->SetSkill(SKILL_RIDING, 4, 300, 300);
    }

    void PrepareOwnedCompanionsBeforeMap(Player* player)
    {
        if (!_clientDataLoaded || player->GetSession()->IsBot() || player->IsInWorld() || !player->GetSession()->PlayerLoading() ||
            !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::LEARN_OWNED_COMPANIONS))
            return;

        std::shared_ptr<PlayerCollectionState const> const state = LoginState(player);
        std::vector<uint32> const spells = GetMissingOwnedCompanionSpells(player, *state);
        std::size_t learned = 0;
        for (uint32 spellId : spells)
        {
            player->learnSpell(spellId, false);
            if (!player->HasSpell(spellId))
                continue;

            player->MarkSpellForSave(spellId);
            ++learned;
        }

        if (learned)
        {
            player->SendInitialSpells();
            LOG_INFO("coa", "Prepared {} account mount/companion spells for {} before entering the world",
                learned, player->GetName());
        }
    }

    static constexpr std::array<uint32, 4> BankVanityItems = { 110000, 134985, 509892, 1180097 };

    [[nodiscard]] static bool IsBankVanityItem(uint32 itemId)
    {
        return std::find(BankVanityItems.begin(), BankVanityItems.end(), itemId) != BankVanityItems.end();
    }

    static constexpr std::array<uint32, 17> MysticAltarVanityItems = {
        406, 203954, 203955, 503515, 1903513, 2903513, 8210192, 8210195, 8210196,
        8210197, 8210198, 8210199, 8210200, 8210201, 8210202, 8210203, 8210250 };

    [[nodiscard]] static bool IsWithheldVanityItem(uint32 itemId)
    {
        return !AscensionFreepick::RealmOffersMysticAltars() &&
            std::find(MysticAltarVanityItems.begin(), MysticAltarVanityItems.end(), itemId) != MysticAltarVanityItems.end();
    }

    [[nodiscard]] bool OwnsBankVanityItem(Player* player, PlayerCollectionState const& state, uint32 itemId) const
    {
        if (state.OwnedVanityItems.contains(itemId) || player->HasItemCount(itemId))
            return true;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
        if (!proto)
            return false;

        for (uint8 slot = 0; slot < MAX_ITEM_PROTO_SPELLS; ++slot)
        {
            uint32 const spellId = uint32(std::max<int32>(proto->Spells[slot].SpellId, 0));
            if (spellId && player->HasSpell(spellId))
                return true;
        }

        return false;
    }

    std::vector<uint32> GetMissingBankSpells(Player* player, PlayerCollectionState const& state) const
    {
        std::vector<uint32> spells;

        for (uint32 itemId : BankVanityItems)
        {
            if (!OwnsBankVanityItem(player, state, itemId))
                continue;

            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
            if (!proto)
                continue;

            for (uint8 slot = 0; slot < MAX_ITEM_PROTO_SPELLS; ++slot)
            {
                uint32 const spellId = uint32(std::max<int32>(proto->Spells[slot].SpellId, 0));
                if (!spellId || player->HasSpell(spellId) || !sSpellMgr->GetSpellInfo(spellId))
                    continue;

                spells.push_back(spellId);
            }
        }

        std::sort(spells.begin(), spells.end());
        spells.erase(std::unique(spells.begin(), spells.end()), spells.end());
        return spells;
    }

    void LearnOwnedBankSpells(Player* player, PlayerCollectionState const& state, bool beforeMap) const
    {
        std::size_t learned = 0;
        for (uint32 spellId : GetMissingBankSpells(player, state))
        {
            player->learnSpell(spellId, false);
            if (player->HasSpell(spellId))
                ++learned;
        }

        if (!learned)
            return;

        if (beforeMap)
            player->SendInitialSpells();

        LOG_INFO("coa", "Learned {} owned bank spell(s) for {}",
                 learned, player->GetName());
    }

    void PrepareOwnedBankSpellsBeforeMap(Player* player)
    {
        if (!_clientDataLoaded || player->IsInWorld() || !player->GetSession()->PlayerLoading())
            return;

        LearnOwnedBankSpells(player, *LoginState(player), true);
    }

    std::vector<uint32> GetMissingOwnedCompanionSpells(Player* player, PlayerCollectionState const& state) const
    {
        std::vector<uint32> spells;
        if (!ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::LEARN_OWNED_COMPANIONS))
            return spells;

        bool const unlockAll = ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::UNLOCK_ALL_VANITY);
        for (auto const& [itemId, vanity] : _vanityItems)
        {
            bool const utilityCompanion = itemId == ITEM_WONDROUS_WISDOMBALL || itemId == ITEM_FIX_O_TRON_5000;
            if (!(vanity.CategoryMask & (VANITY_CATEGORY_MOUNTS | VANITY_CATEGORY_COMPANIONS)) && !utilityCompanion)
                continue;
            if ((!unlockAll && !state.OwnedVanityItems.contains(itemId)) ||
                (std::binary_search(AscensionCollectibles::SigilSpells.begin(),
                    AscensionCollectibles::SigilSpells.end(), vanity.LearnedSpell) &&
                    !state.OwnedVanityItems.contains(itemId)) ||
                !vanity.LearnedSpell || player->HasSpell(vanity.LearnedSpell) ||
                !sSpellMgr->GetSpellInfo(vanity.LearnedSpell))
                continue;

            spells.push_back(vanity.LearnedSpell);
        }

        std::sort(spells.begin(), spells.end());
        spells.erase(std::unique(spells.begin(), spells.end()), spells.end());
        return spells;
    }

    void QueueOwnedCompanionSpells(Player* player, PlayerCollectionState& state) const
    {
        state.PendingCompanionSpells = GetMissingOwnedCompanionSpells(player, state);
        state.CompanionSpellTimer = 5000;
        if (!state.PendingCompanionSpells.empty())
            LOG_INFO("coa", "Queued {} owned mount/companion spells for {} (4 per 200 ms)",
                state.PendingCompanionSpells.size(), player->GetName());
    }

    void ProcessPendingCompanionSpells(Player* player, uint32 diff)
    {
        auto state = GetState(player);
        if (!state || state->PendingCompanionSpells.empty())
            return;

        if (state->CompanionSpellTimer > diff)
        {
            state->CompanionSpellTimer -= diff;
            return;
        }

        state->CompanionSpellTimer = COMPANION_SPELL_BATCH_INTERVAL_MS;
        std::size_t const end = std::min(state->NextCompanionSpell + COMPANION_SPELLS_PER_BATCH,
            state->PendingCompanionSpells.size());
        while (state->NextCompanionSpell < end)
        {
            uint32 const spellId = state->PendingCompanionSpells[state->NextCompanionSpell++];
            if (!player->HasSpell(spellId))
                player->learnSpell(spellId, false);
        }

        if (state->NextCompanionSpell == state->PendingCompanionSpells.size())
        {
            LOG_INFO("coa", "Completed owned mount/companion spell synchronization for {}", player->GetName());
            state->PendingCompanionSpells.clear();
            state->NextCompanionSpell = 0;
        }
    }

    void OnMailItemObtained(Player* player, uint32 itemId)
    {
        if (auto state = GetState(player))
            CollectItem(player, *state, itemId, true, false);
    }

  void OnItemObtained(Player *player, Item *item) {
    if (!item)
      return;

    std::shared_ptr<PlayerCollectionState> state = GetState(player);
    if (!state)
      return;

    CollectItem(player, *state, item->GetEntry(), true, item->IsSoulBound());
  }

    void OnQuestRewarded(Player* player, Quest const* quest)
    {
        if (!quest)
            return;

        auto state = GetState(player);
        if (!state)
            return;

        for (uint32 index = 0; index < QUEST_REWARDS_COUNT; ++index)
            if (quest->RewardItemId[index] && quest->RewardItemIdCount[index])
                CollectItemAppearance(player, *state, quest->RewardItemId[index], true, true);

        for (uint32 index = 0; index < QUEST_REWARD_CHOICES_COUNT; ++index)
            if (quest->RewardChoiceItemId[index] && quest->RewardChoiceItemCount[index])
                CollectItemAppearance(player, *state, quest->RewardChoiceItemId[index], true, true);
    }

    void OnLootRollStart(Roll const& roll, Loot const& loot, LootItem const& item)
    {
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(item.itemid);
        if (!proto || proto->Quality >= ITEM_QUALITY_EPIC)
            return;

        for (auto const& [guid, vote] : roll.playerVote)
        {
            if (vote == NOT_VALID)
                continue;

            Player* player = ObjectAccessor::FindConnectedPlayer(guid);
            if (!player || !player->GetSession() || player->GetSession()->IsBot() ||
                !item.AllowedForPlayer(player, loot.sourceWorldObjectGUID))
                continue;

            auto state = GetState(player);
            if (state)
                CollectItemAppearance(player, *state, item.itemid, true, true);
        }
    }

  void OnVisibleItemSet(Player *player, uint8 slot, Item *item) {
    if (!item)
      return;

    std::shared_ptr<PlayerCollectionState> state = GetState(player);
    if (!state)
      return;

    uint8 itemCategoryId = AppearanceCategoryForEquipmentSlot(slot);
    if (itemCategoryId && state->CanSeeItemAppearances)
    {
      uint32 appearanceId = state->ActiveAppearances[itemCategoryId];
      auto appearanceItr = _appearances.find(appearanceId);
      if (appearanceItr != _appearances.end() &&
          appearanceItr->second.SourceItem) {
        player->SetUInt32Value(PLAYER_VISIBLE_ITEM_1_ENTRYID + slot * 2,
                               appearanceItr->second.SourceItem);
        if (state->CollectedAppearances.contains(appearanceId) &&
            appearanceItr->second.SourceItem != item->GetEntry())
          sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::Transmogrified, appearanceId);
      }
    }

    uint8 effectCategoryId = WeaponEffectCategoryForEquipmentSlot(slot);
    if (!effectCategoryId || !state->CanSeeSpellAppearances)
      return;

    uint32 effectAppearanceId = state->ActiveAppearances[effectCategoryId];
    auto effectItr = _appearances.find(effectAppearanceId);
    if (effectItr == _appearances.end() || !effectItr->second.EnchantId)
      return;

    player->SetUInt16Value(
        PLAYER_VISIBLE_ITEM_1_ENCHANTMENT + slot * 2, 0,
        static_cast<uint16>(effectItr->second.EnchantId));
  }

    uint32 GetAmmunitionDisplay(Player* player)
    {
        auto state = GetState(player);
        if (!state || !state->CanSeeSpellAppearances)
            return 0;

        uint32 const appearanceId = state->ActiveAppearances[APPEARANCE_CATEGORY_AMMUNITION];
        if (!state->CollectedAppearances.contains(appearanceId))
            return 0;

        auto const entry = std::lower_bound(AscensionAmmunition::Entries.begin(), AscensionAmmunition::Entries.end(),
            appearanceId, [](AscensionAmmunition::Entry const& row, uint32 id) { return row.AppearanceId < id; });
        return entry != AscensionAmmunition::Entries.end() && entry->AppearanceId == appearanceId ?
            entry->ItemDisplayId : 0;
    }

    uint32 GetShadowhoundDisplay(Player* player)
    {
        if (!player || player->getClass() != CLASS_WITCH_HUNTER ||
            !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
            return 0;

        auto state = GetState(player);
        if (!state || !state->CanSeeSpellAppearances)
            return 0;

        uint32 const appearanceId = state->ActiveAppearances[APPEARANCE_CATEGORY_SHADOWHOUND];
        if (!state->CollectedAppearances.contains(appearanceId))
            return 0;

        auto const appearance = _appearances.find(appearanceId);
        return appearance != _appearances.end() ? appearance->second.CreatureDisplay : 0;
    }

  void DeliverVanityItem(Player *player, uint32 itemId) {
    std::shared_ptr<PlayerCollectionState> state = GetState(player);
    if (!state)
      return;

    auto vanityItr = _vanityItems.find(itemId);
    if (vanityItr == _vanityItems.end())
    {
      ChatHandler(player->GetSession())
          .PSendSysMessage(
              "Vanity item {} is not present in this client build.", itemId);
      return;
    }

    if (IsWithheldVanityItem(itemId))
    {
      ChatHandler(player->GetSession())
          .SendSysMessage("Mystic Enchanting altars are not available on this realm.");
      return;
    }

    bool unlockAll = ascensionCompatConfig.GetConfigValue<bool>(
        AscensionCompatConfig::UNLOCK_ALL_VANITY);

    bool const entitled =
        IsBankVanityItem(itemId)
            ? OwnsBankVanityItem(player, *state, itemId)
            : (unlockAll || state->OwnedVanityItems.contains(itemId));
    if (!entitled)
    {
      ChatHandler(player->GetSession())
          .SendSysMessage(IsBankVanityItem(itemId)
              ? "That bank is not unlocked on this account."
              : "That vanity item is not unlocked on this account.");
      return;
    }

    if (std::binary_search(AscensionCollectibles::SigilVanityItems.begin(),
        AscensionCollectibles::SigilVanityItems.end(), itemId) &&
        !state->OwnedVanityItems.contains(itemId))
    {
        ChatHandler(player->GetSession()).SendSysMessage("That sigil companion is not unlocked on this account.");
        return;
    }

    if (sObjectMgr->GetItemTemplate(itemId))
    {
      ItemPosCountVec destinations;
      InventoryResult result =
          player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destinations, itemId, 1);
      if (result != EQUIP_ERR_OK)
      {
        player->SendEquipError(result, nullptr, nullptr, itemId);
        return;
      }

      if (Item* delivered = player->StoreNewItem(destinations, itemId, true))
      {
        player->SendNewItem(delivered, 1, true, false);
        sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::VanityDelivered, itemId);
      }

      if (IsBankVanityItem(itemId))
        LearnOwnedBankSpells(player, *state, false);

      return;
    }

    uint32 learnedSpell = vanityItr->second.LearnedSpell;
    if (learnedSpell &&
        ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ALLOW_LEARNED_SPELL_DELIVERY) &&
        sSpellMgr->GetSpellInfo(learnedSpell)) {
      player->learnSpell(learnedSpell);
      if (player->HasSpell(learnedSpell))
        sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::VanityDelivered, itemId);
      ChatHandler(player->GetSession())
          .PSendSysMessage("Learned vanity spell {} because item {} has no "
                           "local server template.",
                           learnedSpell, itemId);
      return;
    }

    ChatHandler(player->GetSession())
        .PSendSysMessage("Vanity item {} exists in the Ascension client but "
                         "has no AzerothCore item template yet.",
                         itemId);
  }

private:
    void LoadWoodworkingAppearances(uint32 lastMappingId)
    {
        using VisualKey = std::tuple<uint32, uint32, uint32, uint32>;
        auto const visualKey = [](ItemTemplate const& item)
        {
            return VisualKey{item.DisplayInfoID, item.Class, item.SubClass, item.InventoryType};
        };
        std::map<VisualKey, uint32> visualAppearances;
        for (auto const& [id, appearance] : _appearances)
        {
            ItemTemplate const* item = sObjectMgr->GetItemTemplate(appearance.SourceItem);
            if (!item || !IsEquipmentAppearance(appearance))
                continue;
            auto [mapping, inserted] = visualAppearances.try_emplace(visualKey(*item), id);
            if (!inserted)
                mapping->second = std::min(mapping->second, id);
        }

        std::set<uint32> craftedItems;
        for (SkillLineAbilityEntry const* ability : GetSkillLineAbilitiesBySkillLine(SKILL_WOODWORKING))
        {
            SpellInfo const* spell = ability ? sSpellMgr->GetSpellInfo(ability->Spell) : nullptr;
            if (!spell)
                continue;
            for (SpellEffectInfo const& effect : spell->Effects)
                if (effect.Effect == SPELL_EFFECT_CREATE_ITEM || effect.Effect == SPELL_EFFECT_CREATE_ITEM_2)
                    craftedItems.insert(effect.ItemType);
        }

        for (uint32 itemId : craftedItems)
        {
            ItemTemplate const* item = sObjectMgr->GetItemTemplate(itemId);
            if (!item || _itemAppearances.contains(itemId) ||
                (item->Class != ITEM_CLASS_WEAPON && item->Class != ITEM_CLASS_ARMOR))
                continue;

            uint32 primaryCategory = 0;
            uint32 secondaryCategory = 0;
            switch (item->InventoryType)
            {
                case INVTYPE_HEAD:
                    primaryCategory = 1;
                    break;
                case INVTYPE_RANGED:
                case INVTYPE_RANGEDRIGHT:
                case INVTYPE_THROWN:
                    primaryCategory = 12;
                    break;
                case INVTYPE_2HWEAPON:
                case INVTYPE_WEAPON:
                    primaryCategory = 13;
                    secondaryCategory = 14;
                    break;
                case INVTYPE_SHIELD:
                case INVTYPE_HOLDABLE:
                    primaryCategory = 14;
                    break;
                default:
                    continue;
            }

            if (lastMappingId == std::numeric_limits<uint32>::max())
                break;

            auto const key = visualKey(*item);
            auto visual = visualAppearances.find(key);
            uint32 appearanceId = 0;
            if (visual != visualAppearances.end())
                appearanceId = visual->second;
            else
            {
                if (_appearances.contains(itemId))
                {
                    LOG_WARN("coa", "Woodworking item {} cannot use an existing unrelated appearance ID", itemId);
                    continue;
                }
                appearanceId = itemId;
                _appearances.emplace(appearanceId, AppearanceInfo{itemId, primaryCategory, secondaryCategory});
                _allAppearanceIds.push_back(appearanceId);
                visualAppearances.emplace(key, appearanceId);
                _woodworkingAppearancePatches.push_back({appearanceId, itemId, 0, itemId, 0,
                    primaryCategory, secondaryCategory, 0, itemId, 0, 0, 100, 1, 1, 1, 1, 1});
            }

            _itemAppearances.emplace(itemId, appearanceId);
            _woodworkingItemAppearancePatches.push_back({++lastMappingId, itemId, appearanceId});
        }
    }

    void SendWoodworkingAppearanceCatalog(Player* player)
    {
        for (auto const& row : _woodworkingAppearancePatches)
        {
            WorldPacket packet(SMSG_PATCH_APPEARANCES, 17 * sizeof(uint32) + sizeof("APPEARANCE_DISPLAY_TYPE_ITEM"));
            for (uint32 field : row)
                packet << field;
            packet << "APPEARANCE_DISPLAY_TYPE_ITEM";
            player->GetSession()->SendPacket(&packet);
        }
        for (auto const& row : _woodworkingItemAppearancePatches)
        {
            WorldPacket packet(SMSG_PATCH_ITEM_APPEARANCES, 3 * sizeof(uint32));
            for (uint32 field : row)
                packet << field;
            player->GetSession()->SendPacket(&packet);
        }
    }

  void UnlockLocalAppearanceCatalog(Player *player,
                                    PlayerCollectionState &state) {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::UNLOCK_LOCAL_APPEARANCE_CATALOG))
      return;

    std::size_t before = state.CollectedAppearances.size();
    for (uint32 appearanceId : _allAppearanceIds)
      state.CollectedAppearances.insert(appearanceId);

    LOG_INFO("coa",
             "Unlocked {} local wardrobe appearances for {} ({} total)",
             state.CollectedAppearances.size() - before, player->GetName(),
             state.CollectedAppearances.size());
  }

  void BeginAppearanceCollectionSync(Player *player,
                                     PlayerCollectionState &state) {
    std::vector<uint32> appearances(state.CollectedAppearances.begin(),
                                    state.CollectedAppearances.end());
    std::sort(appearances.begin(), appearances.end());

    if (appearances.size() <= MAX_APPEARANCE_SNAPSHOT_ENTRIES)
    {
      SendAppearanceCollection(player, appearances);
      LOG_INFO("coa", "Sent complete wardrobe snapshot for {}: {} appearances, no per-item login notifications",
          player->GetName(), appearances.size());
      return;
    }

    uint32 perCategory = ascensionCompatConfig.GetConfigValue<uint32>(
        AscensionCompatConfig::APPEARANCE_CATALOG_PER_CATEGORY);
    std::array<uint32, APPEARANCE_CATEGORY_COUNT> categoryCounts{};
    std::vector<uint32> snapshot;
    snapshot.reserve(MAX_APPEARANCE_SNAPSHOT_ENTRIES);
    std::unordered_set<uint32> snapshotIds;
    snapshotIds.reserve(MAX_APPEARANCE_SNAPSHOT_ENTRIES);

    if (perCategory)
    {
      for (uint32 appearanceId : appearances) {
        if (snapshot.size() >= MAX_APPEARANCE_SNAPSHOT_ENTRIES)
          break;

        auto itr = _appearances.find(appearanceId);
        if (itr == _appearances.end())
          continue;

        AppearanceInfo const &appearance = itr->second;
        uint32 categoryId = appearance.PrimaryCategory;
        if (!categoryId || categoryId > 14 ||
            categoryCounts[categoryId] >= perCategory ||
            !appearance.SourceItem ||
            !sObjectMgr->GetItemTemplate(appearance.SourceItem))
          continue;

        snapshot.push_back(appearanceId);
        snapshotIds.insert(appearanceId);
        ++categoryCounts[categoryId];
      }
    }

    for (uint32 appearanceId : appearances) {
      if (snapshot.size() >= MAX_APPEARANCE_SNAPSHOT_ENTRIES)
        break;

      if (snapshotIds.insert(appearanceId).second)
        snapshot.push_back(appearanceId);
    }

    state.PendingAppearanceAdds.clear();
    state.PendingAppearanceAdds.reserve(appearances.size() - snapshot.size());
    for (uint32 appearanceId : appearances) {
      if (!snapshotIds.contains(appearanceId))
        state.PendingAppearanceAdds.push_back(appearanceId);
    }

    state.NextPendingAppearanceAdd = 0;
    state.AppearanceAddTimer = APPEARANCE_ADD_INITIAL_DELAY_MS;
    SendAppearanceCollection(player, snapshot);

    LOG_INFO("coa",
             "Started full wardrobe sync for {}: {} snapshot entries and {} "
             "streamed entries",
             player->GetName(), snapshot.size(),
             state.PendingAppearanceAdds.size());
  }

  void ProcessPendingAppearanceAdds(Player *player, uint32 diff) {
    std::shared_ptr<PlayerCollectionState> state = GetState(player);
    if (!state)
      return;

    if (state->LoginResyncTimer)
    {
      if (state->LoginResyncTimer > diff)
      {
        state->LoginResyncTimer -= diff;
        return;
      }

      state->LoginResyncTimer = 0;
      SendActiveAppearances(player, *state);
      SendOutfitCollection(player, *state);
      SendAppearanceVisibility(player, *state);
      SendVanityCollection(player, *state);
    }

    if (state->PendingAppearanceAdds.empty())
      return;

    if (state->AppearanceAddTimer > diff)
    {
      state->AppearanceAddTimer -= diff;
      return;
    }

    state->AppearanceAddTimer = APPEARANCE_ADD_BATCH_INTERVAL_MS;
    std::size_t end = std::min(
        state->NextPendingAppearanceAdd + APPEARANCE_ADDS_PER_BATCH,
        state->PendingAppearanceAdds.size());
    for (; state->NextPendingAppearanceAdd < end;
         ++state->NextPendingAppearanceAdd) {
      uint32 appearanceId =
          state->PendingAppearanceAdds[state->NextPendingAppearanceAdd];
      auto itr = _appearances.find(appearanceId);
      SendAppearanceAdded(
          player, appearanceId,
          itr != _appearances.end() ? itr->second.SourceItem : 0);
    }

    if (state->NextPendingAppearanceAdd < state->PendingAppearanceAdds.size())
      return;

    std::size_t total = state->CollectedAppearances.size();
    std::vector<uint32>().swap(state->PendingAppearanceAdds);
    state->NextPendingAppearanceAdd = 0;
    state->AppearanceAddTimer = 0;
    SendOutfitCollection(player, *state);
    ChatHandler(player->GetSession())
        .PSendSysMessage("Unlocked all {} local wardrobe appearances.", total);

    LOG_INFO("coa",
             "Completed full wardrobe sync for {}: {} appearances",
             player->GetName(), total);
  }

  std::shared_ptr<PlayerCollectionState> GetState(Player const *player) {
    std::lock_guard lock(_stateMutex);
    auto itr = _playerStates.find(player->GetGUID().GetCounter());
    return itr != _playerStates.end() ? itr->second : nullptr;
  }

  std::shared_ptr<PlayerCollectionState> LoadCollectionState(Player *player) {
    auto state = std::make_shared<PlayerCollectionState>();
    state->AccountId = player->GetSession()->GetAccountId();
    LoadPlayerState(player, *state);
    return state;
  }

  std::shared_ptr<PlayerCollectionState> LoginState(Player *player) {
    uint32 const guid = player->GetGUID().GetCounter();
    {
      std::lock_guard lock(_stateMutex);
      if (auto itr = _loginStates.find(guid); itr != _loginStates.end())
        return itr->second;
    }

    std::shared_ptr<PlayerCollectionState> state = LoadCollectionState(player);
    std::lock_guard lock(_stateMutex);
    return _loginStates.try_emplace(guid, state).first->second;
  }

  std::shared_ptr<PlayerCollectionState> TakeLoginState(Player *player) {
    std::lock_guard lock(_stateMutex);
    auto node = _loginStates.extract(player->GetGUID().GetCounter());
    return node.empty() ? nullptr : std::move(node.mapped());
  }

  void LoadPlayerState(Player *player, PlayerCollectionState &state) {
    uint32 accountId = state.AccountId;
    uint32 characterGuid = player->GetGUID().GetCounter();

    if (QueryResult result = CharacterDatabase.Query(
            "SELECT `appearance_id` FROM `account_appearance_collection` WHERE "
            "`account_id` = {}",
            accountId)) {
      do {
        state.CollectedAppearances.insert(result->Fetch()[0].Get<uint32>());
      } while (result->NextRow());
    }

    if (QueryResult result = CharacterDatabase.Query(
            "SELECT `category_id`, `appearance_id` FROM `character_appearance` "
            "WHERE `guid` = {}",
            characterGuid)) {
      do {
        Field *fields = result->Fetch();
        uint32 categoryId = fields[0].Get<uint32>();
        if (categoryId < APPEARANCE_CATEGORY_COUNT)
          state.ActiveAppearances[categoryId] = fields[1].Get<uint32>();
      } while (result->NextRow());
    }

    if (QueryResult result = CharacterDatabase.Query(
            "SELECT `name`, `appearances` FROM `character_appearance_outfit` "
            "WHERE `guid` = {}",
            characterGuid)) {
      do {
        Field *fields = result->Fetch();
        std::vector<uint32> &outfit = state.Outfits[fields[0].Get<std::string>()];
        std::string const appearances = fields[1].Get<std::string>();
        for (std::string_view token : Acore::Tokenize(appearances, ' ', false))
          outfit.push_back(Acore::StringTo<uint32>(token).value_or(0));
      } while (result->NextRow());
    }

    if (QueryResult result = CharacterDatabase.Query(
            "SELECT `can_see_item`, `can_see_spell` FROM "
            "`character_appearance_settings` WHERE `guid` = {}",
            characterGuid)) {
      Field *fields = result->Fetch();
      state.CanSeeItemAppearances = fields[0].Get<uint8>() != 0;
      state.CanSeeSpellAppearances = fields[1].Get<uint8>() != 0;
    }

    if (QueryResult result = CharacterDatabase.Query(
            "SELECT `item_id` FROM `account_vanity_collection` WHERE "
            "`account_id` = {}",
            accountId)) {
      do {
        state.OwnedVanityItems.insert(result->Fetch()[0].Get<uint32>());
      } while (result->NextRow());
    }
  }

  void ScanPlayerInventory(Player *player, PlayerCollectionState &state) {
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < INVENTORY_SLOT_ITEM_END;
         ++slot) {
      if (Item *item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
        CollectItem(player, state, item->GetEntry(), false, item->IsSoulBound());
    }

    for (uint8 bagSlot = INVENTORY_SLOT_BAG_START;
         bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot) {
      Bag *bag = player->GetBagByPos(bagSlot);
      if (!bag)
        continue;

      for (uint32 slot = 0; slot < bag->GetBagSize(); ++slot) {
        if (Item *item = bag->GetItemByPos(slot))
          CollectItem(player, state, item->GetEntry(), false, item->IsSoulBound());
      }
    }
  }

  static bool IsEquipmentAppearance(AppearanceInfo const& appearance)
  {
    for (uint32 category : {appearance.PrimaryCategory, appearance.SecondaryCategory,
             appearance.TertiaryCategory})
      if (category >= 1 && category <= 14)
        return true;
    return false;
  }

    void CollectItemAppearance(Player* player, PlayerCollectionState& state, uint32 itemId,
        bool notifyClient, bool equipmentOnly = false)
    {
        auto mapping = _itemAppearances.find(itemId);
        if (mapping == _itemAppearances.end())
            mapping = _itemAppearances.find(ItemScaling::BaseEntry(itemId));
        if (mapping == _itemAppearances.end())
            return;

        uint32 const appearanceId = mapping->second;
        auto const appearance = _appearances.find(appearanceId);
        if (appearance == _appearances.end() || (equipmentOnly && !IsEquipmentAppearance(appearance->second)))
            return;

        if (IsEquipmentAppearance(appearance->second))
            sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::AppearanceCollected, appearanceId);

        if (!state.CollectedAppearances.insert(appearanceId).second)
            return;

        CharacterDatabase.Execute(
            "INSERT IGNORE INTO `account_appearance_collection` (`account_id`, "
            "`appearance_id`, `source_item`) "
            "VALUES ({}, {}, {})",
            state.AccountId, appearanceId, itemId);
        if (notifyClient)
            SendAppearanceAdded(player, appearanceId, itemId);
    }

  void CollectItem(Player *player, PlayerCollectionState &state, uint32 itemId,
                   bool notifyClient, bool bound) {
    CollectItemAppearance(player, state, itemId, notifyClient);

    if (bound && _vanityItems.contains(itemId))
      sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::VanityCollected, itemId);

    if (bound && (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::UNLOCK_ALL_VANITY) ||
        std::binary_search(AscensionCollectibles::SigilVanityItems.begin(),
            AscensionCollectibles::SigilVanityItems.end(), itemId)) &&
        _vanityItems.contains(itemId) &&
        state.OwnedVanityItems.insert(itemId).second) {
      CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_ACCOUNT_VANITY_COLLECTION);
      stmt->SetData(0, state.AccountId);
      stmt->SetData(1, itemId);
      CharacterDatabase.Execute(stmt);

      if (notifyClient)
      {
        WorldPacket packet(SMSG_VANITY_COLLECTION_ADDED, sizeof(uint32));
        packet << itemId;
        player->GetSession()->SendPacket(&packet);
      }
    }

    if (IsBankVanityItem(itemId) && state.OwnedVanityItems.insert(itemId).second)
    {
      CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_ACCOUNT_VANITY_COLLECTION);
      stmt->SetData(0, state.AccountId);
      stmt->SetData(1, itemId);
      CharacterDatabase.Execute(stmt);

      if (notifyClient)
      {
        WorldPacket packet(SMSG_VANITY_COLLECTION_ADDED, sizeof(uint32));
        packet << itemId;
        player->GetSession()->SendPacket(&packet);
      }

      LearnOwnedBankSpells(player, state, !player->IsInWorld());
      LOG_INFO("coa", "Account {} acquired the bank item {} through {}",
               state.AccountId, itemId, player->GetName());
    }
  }

  void HandleClientPacket(Player *player, WorldPacket &packet) {
    packet.rpos(0);
    try {
      switch (packet.GetOpcode()) {
      case CMSG_APPLY_APPEARANCES:
        HandleApplyAppearances(player, packet);
        break;
      case CMSG_SET_CAN_SEE_APPEARANCES:
        HandleSetAppearanceVisibility(player, packet);
        break;
      case CMSG_SAVE_APPEARANCE_OUTFIT:
        HandleSaveOutfit(player, packet);
        break;
      case CMSG_DELETE_APPEARANCE_OUTFIT:
        HandleDeleteOutfit(player, packet);
        break;
      case CMSG_INSPECT_CHARACTER_ADVANCEMENT:
        AscensionClassService::Instance().SendInspectResult(player, ObjectGuid(packet.read<uint64>()));
        break;
      case CMSG_EXTENSION_INITIALIZED:
        SendSecureAddonList(player->GetSession());
        player->SendAllSpellChargeStates();
        SendAscensionRunemasterEchoesCooldown(player);
        AscensionDisplayPatchService::Instance().SendPatchStream(player, true);
        LOG_DEBUG("coa", "Resent spell charge state to {} after client world entry",
                  player->GetName());
        break;
      case CMSG_ITEM_QUERY_BULK:
        for (uint32 entry : ReadBulkQueryEntries(packet, MAX_ITEM_QUERY_BULK_ENTRIES))
          player->GetSession()->SendItemQuerySingleResponse(entry);
        break;
      case CMSG_ITEM_STAT_QUERY:
        ItemScaling::HandleStatQuery(player->GetSession(), packet);
        break;
      case CMSG_CREATURE_QUERY_BULK:
        for (uint32 entry : ReadBulkQueryEntries(packet, MAX_CREATURE_QUERY_BULK_ENTRIES))
          SendCollectionCreatureQueryResponse(player->GetSession(), entry);
        break;
      case CMSG_CUSTOM_ASCENSION_POINT_SPEND_REQUEST:
        HandlePointSpendRequest(player, packet);
        break;
      case CMSG_QUERY_CUSTOM_STORE:
      case CMSG_PURCHASE_CUSTOM_STORE_ITEM:
        if (!AscensionCompatOpcodes::Dispatch(player->GetSession(), packet) &&
            packet.GetOpcode() == CMSG_QUERY_CUSTOM_STORE)
        {
          WorldPacket empty(SMSG_QUERY_CUSTOM_STORE_RESULT, 32);
          empty << "QUERY_CUSTOM_STORE_OK";
          empty << uint32(0);
          player->GetSession()->SendPacket(&empty);
        }
        break;
      default:
        break;
      }
    } catch (ByteBufferException const &) {
      RejectClientPacket(player->GetSession()->GetAccountId(), packet, "malformed payload");
    }
  }

  void HandleApplyAppearances(Player *player, WorldPacket &packet) {
    std::shared_ptr<PlayerCollectionState> state = GetState(player);
    if (!state)
      return;

    uint32 count = 0;
    packet >> count;
    if (!count || count > 256)
    {
      SendApplyResult(player, "APPLY_APPEARANCES_INVALID_SELECTION");
      return;
    }

    std::array<uint32, APPEARANCE_CATEGORY_COUNT> requested{};
    for (uint32 index = 0; index < count; ++index) {
      uint32 appearanceId = 0;
      packet >> appearanceId;
      if (index < requested.size())
        requested[index] = appearanceId;
    }

    for (uint32 categoryId = 1; categoryId < requested.size(); ++categoryId) {
      uint32 appearanceId = requested[categoryId];
      if (!appearanceId)
        continue;

      if (!state->CollectedAppearances.contains(appearanceId))
      {
        SendApplyResult(player, "APPLY_APPEARANCES_NOT_COLLECTED");
        return;
      }

      auto appearanceItr = _appearances.find(appearanceId);
      if (appearanceItr == _appearances.end())
      {
        SendApplyResult(player, "APPLY_APPEARANCES_INVALID_SELECTION");
        return;
      }

      AppearanceInfo const &appearance = appearanceItr->second;
      if ((categoryId <= 14 || categoryId == APPEARANCE_CATEGORY_AMMUNITION ||
          categoryId == APPEARANCE_CATEGORY_SHADOWHOUND ||
          IsCosmeticCategory(categoryId)) &&
          appearance.PrimaryCategory != categoryId &&
          appearance.SecondaryCategory != categoryId &&
          appearance.TertiaryCategory != categoryId) {
        SendApplyResult(player, "APPLY_APPEARANCES_INVALID_CATEGORY");
        return;
      }
      if ((IsCosmeticCategory(categoryId) && !appearance.CosmeticSpell) ||
          (categoryId == APPEARANCE_CATEGORY_SHADOWHOUND && !appearance.CreatureDisplay))
      {
        SendApplyResult(player, "APPLY_APPEARANCES_INVALID_SELECTION");
        return;
      }
    }

    if (requested[55] && !ExpandItemSetAppearance(requested, requested[55]))
    {
      SendApplyResult(player, "APPLY_APPEARANCES_INVALID_SELECTION");
      return;
    }

    uint32 const whistle = requested[APPEARANCE_CATEGORY_TAMED_BEAST];
    if (whistle && whistle != state->ActiveAppearances[APPEARANCE_CATEGORY_TAMED_BEAST])
    {
      if (char const* refused = ReplaceTamedBeast(player, _appearances.at(whistle).CreatureEntry))
      {
        SendApplyResult(player, refused);
        return;
      }
    }

    state->ActiveAppearances = requested;
    SaveActiveAppearances(player, *state);
    RefreshCosmetics(player, *state);
    RefreshVisibleItems(player);
    SendApplyResult(player, "APPLY_APPEARANCES_OK");
  }

  static char const* ReplaceTamedBeast(Player* player, uint32 entry) {
    CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(entry);
    if (!creature || !creature->family)
      return "APPLY_APPEARANCES_BAD_CREATURE_ENTRY";
    if (player->IsInCombat())
      return "APPLY_APPEARANCES_COSMETIC_PET_IN_COMBAT";
    if (std::none_of(CALL_PET_SPELLS.begin(), CALL_PET_SPELLS.end(),
          [player](uint32 spell) { return player->HasSpell(spell); }))
      return "APPLY_APPEARANCES_PET_SUMMON_SPELL_NOT_LEARNED";

    Pet* current = player->GetPet();
    if (current && current->getPetType() != HUNTER_PET)
      return "APPLY_APPEARANCES_PET_TYPE_NOT_FOUND";
    if (current && !current->IsAlive() && !player->HasPlayerFlag(PLAYER_FLAGS_RESTING))
      return "APPLY_APPEARANCES_PET_DEAD_NON_SAFE_ZONE";

    if (current)
      player->RemovePet(current, PET_SAVE_AS_DELETED);
    else if (PetStable* stable = player->GetPetStable())
    {
      if (stable->CurrentPet)
      {
        Pet::DeleteFromDB(stable->CurrentPet->PetNumber);
        stable->CurrentPet.reset();
      }
      else if (PetStable::PetInfo const* dismissed = stable->GetUnslottedHunterPet())
      {
        Pet::DeleteFromDB(dismissed->PetNumber);
        stable->UnslottedPets.clear();
      }
    }

    Pet* pet = player->CreateTamedPetFrom(entry, TAME_BEAST_SPELL);
    if (!pet)
      return "APPLY_APPEARANCES_BAD_CREATURE_ENTRY";
    uint8 const level = player->GetLevel();
    pet->SetUInt32Value(UNIT_FIELD_LEVEL, level > 1 ? level - 1 : level);
    pet->GetMap()->AddToMap(pet->ToCreature(), true);
    pet->SetUInt32Value(UNIT_FIELD_LEVEL, level);
    player->SetMinion(pet, true);
    pet->InitTalentForLevel();
    pet->SavePetToDB(PET_SAVE_AS_CURRENT);
    player->PetSpellInitialize();
    return nullptr;
  }

  void HandleSetAppearanceVisibility(Player *player, WorldPacket &packet) {
    std::shared_ptr<PlayerCollectionState> state = GetState(player);
    if (!state)
      return;

    uint8 canSeeItem = 0;
    uint8 canSeeSpell = 0;
    packet >> canSeeItem >> canSeeSpell;
    state->CanSeeItemAppearances = canSeeItem != 0;
    state->CanSeeSpellAppearances = canSeeSpell != 0;

    CharacterDatabase.Execute("REPLACE INTO `character_appearance_settings` "
                              "(`guid`, `can_see_item`, `can_see_spell`) "
                              "VALUES ({}, {}, {})",
                              player->GetGUID().GetCounter(),
                              canSeeItem ? 1 : 0, canSeeSpell ? 1 : 0);

    RefreshVisibleItems(player);
    SendAppearanceVisibility(player, *state);
  }

    void HandlePointSpendRequest(Player* player, WorldPacket& packet)
    {
        if (packet.size() != POINT_SPEND_REQUEST_SIZE)
        {
            RejectClientPacket(player->GetSession()->GetAccountId(), packet, "malformed point spend request");
            return;
        }

        uint8 currency = 0;
        uint32 itemId = 0;
        packet >> currency >> itemId;
        if (currency != VANITY_CURRENCY_DONATION_POINTS)
        {
            LOG_DEBUG("coa", "Ignored Ascension point spend request in vanity currency {} for {} from {}",
                currency, itemId, player->GetName());
            return;
        }

        DeliverVanityItem(player, itemId);
    }

  void SaveActiveAppearances(Player *player,
                             PlayerCollectionState const &state) {
    uint32 characterGuid = player->GetGUID().GetCounter();
    CharacterDatabaseTransaction transaction =
        CharacterDatabase.BeginTransaction();
    transaction->Append("DELETE FROM `character_appearance` WHERE `guid` = {}",
                        characterGuid);

    for (uint32 categoryId = 1; categoryId < state.ActiveAppearances.size();
         ++categoryId) {
      uint32 appearanceId = state.ActiveAppearances[categoryId];
      if (!appearanceId)
        continue;

      transaction->Append("INSERT INTO `character_appearance` (`guid`, "
                          "`category_id`, `appearance_id`) VALUES ({}, {}, {})",
                          characterGuid, categoryId, appearanceId);
    }

    CharacterDatabase.CommitTransaction(transaction);
  }

  void SendAppearanceCollection(Player *player,
                                std::vector<uint32> const &appearances) {
    WorldPacket packet(SMSG_APPEARANCE_COLLECTION_INFO,
                       sizeof(uint32) +
                           appearances.size() * sizeof(uint32) * 2);
    packet << static_cast<uint32>(appearances.size());
    for (uint32 appearanceId : appearances) {
      packet << appearanceId;
      auto itr = _appearances.find(appearanceId);
      packet << (itr != _appearances.end() ? itr->second.SourceItem : 0);
    }

    player->GetSession()->SendPacket(&packet);
  }

  void SendActiveAppearances(Player *player,
                             PlayerCollectionState const &state) {
    WorldPacket packet(SMSG_APPEARANCE_ACTIVE_INFO,
                       sizeof(uint32) +
                           state.ActiveAppearances.size() * sizeof(uint32));
    packet << static_cast<uint32>(state.ActiveAppearances.size());
    for (uint32 appearanceId : state.ActiveAppearances)
      packet << appearanceId;

    player->GetSession()->SendPacket(&packet);
  }

  void SendAppearanceAdded(Player *player, uint32 appearanceId,
                           uint32 sourceItem) {
    WorldPacket packet(SMSG_APPEARANCE_ADDED, sizeof(uint32) * 2);
    packet << appearanceId << sourceItem;
    player->GetSession()->SendPacket(&packet);
  }

public:
  void SendRealmInfo(Player *player) {
    if (player && player->GetSession())
      SendRealmInfo(player->GetSession(), player->GetName());
  }

  void SendRealmInfo(WorldSession *session, std::string const &who = "char-select") {
    if (!session)
      return;

    std::string const art = ascensionCompatConfig.GetConfigValue<std::string>(
        AscensionCompatConfig::REALM_TYPE);

    uint8 flags[8] = {0, 0, 0, 0, 0, 0, 0, 0};
    for (std::string_view type : Acore::Tokenize(art, ' ', false)) {
      if (type == "live")             flags[0] = 1;
      else if (type == "seasonal")    flags[1] = 1;
      else if (type == "league")      flags[2] = 1;
      else if (type == "ptr")         flags[3] = 1;
      else if (type == "development") flags[4] = 1;
    }
    if (std::none_of(flags, flags + 5, [](uint8 flag) { return flag != 0; }))
      flags[0] = 1;

    std::string const model = ascensionCompatConfig.GetConfigValue<std::string>(
        AscensionCompatConfig::CLASS_MODEL);
    if (model == "coa")
      flags[REALM_CREATION_FLAG_CONQUEST_OF_AZEROTH] = 1;
    else if (model == "wcr")
      flags[REALM_CREATION_FLAG_WARCRAFT_REBORN] = 1;

    uint32 const maxLevel = sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);
    uint32 const ruleset = maxLevel <= 60 ? EXPANSION_CLASSIC
        : maxLevel <= 70 ? EXPANSION_THE_BURNING_CRUSADE : EXPANSION_WRATH_OF_THE_LICH_KING;

    WorldPacket p(SMSG_REALM_INFO, 64);
    p << static_cast<uint32>(realm.Id.Realm);
    p << ruleset;
    p << 0.0f << 0.0f << 0.0f;
    p << static_cast<uint32>(0);
    p << 0.0f << 0.0f;
    p << static_cast<uint32>(0);
    for (uint8 f : flags)
      p << f;
    p << "";
    p << realm.Name;
    p << REALM_INFO_ADDONS_ALLOWED;

    session->SendPacket(&p);

    LOG_INFO("coa",
             "Realm info sent to {}: type {}, class model {}, ruleset {}, realm {} ({}).",
             who, art, model, ruleset, realm.Id.Realm, realm.Name);
  }

  void SendGameModeState(Player *player) {
    if (!player || !player->GetSession())
      return;

    uint32 const mask = ascensionCompatConfig.GetConfigValue<uint32>(
        AscensionCompatConfig::GAME_MODE_MASK);
    WorldPacket p(SMSG_GAME_MODE_STATE, sizeof(uint32));
    p << mask;
    player->GetSession()->SendPacket(&p);
  }

    void SendSecureAddonList(WorldSession* session)
    {
        if (!session)
            return;

        static constexpr std::array<std::string_view, 33> ascensionAddons = {
            "AscensionResources", "AscensionUI", "Ascension_AddonPanel", "Ascension_AppearanceUI",
            "Ascension_BuildCreator", "Ascension_ChallengesUI", "Ascension_CharacterAdvancement",
            "Ascension_CharacterAdvancementSeason9", "Ascension_CoATalents", "Ascension_Collections",
            "Ascension_CompactRaidFrames", "Ascension_Draft", "Ascension_EnchantCollection",
            "Ascension_ForcedPrimaryStat", "Ascension_HelpUI", "Ascension_InspectUI", "Ascension_Manastorm",
            "Ascension_MythicPlus", "Ascension_NamePlates", "Ascension_NewPlayerExperience",
            "Ascension_PTRFeedback", "Ascension_PathToAscension", "Ascension_Poll",
            "Ascension_RandomModeShared", "Ascension_SeasonCollection", "Ascension_SkillCards",
            "Ascension_TalentUI", "Ascension_TicketUI", "Ascension_UIDevelopmentTools",
            "Ascension_VanityCollection", "Ascension_Warmode", "Ascension_WarmodeLegacy", "Ascension_WildCard",
        };

        static std::unordered_set<std::string_view> const secureAscensionAddons = {
            "AscensionUI", "Ascension_CompactRaidFrames", "Ascension_EnchantCollection", "Ascension_HelpUI",
            "Ascension_InspectUI", "Ascension_MythicPlus", "Ascension_SeasonCollection", "Ascension_TicketUI",
            "Ascension_UIDevelopmentTools", "Ascension_WildCard",
        };

        std::vector<std::string> names = session->GetClientAddonNames();
        for (std::string_view addon : ascensionAddons)
            if (std::find(names.begin(), names.end(), addon) == names.end())
                names.emplace_back(addon);

        WorldPacket packet(SMSG_ASCENSION_SECURE_ADDONS, sizeof(uint32) + names.size() * 32);
        packet << uint32(names.size());
        for (std::string const& name : names)
        {
            packet << name;
            packet << uint8(name.starts_with("Blizzard_") || secureAscensionAddons.contains(name));
        }
        session->SendPacket(&packet);
    }

private:
  void SendOutfitCollection(Player *player, PlayerCollectionState const &state)
  {
    WorldPacket packet(SMSG_APPEARANCE_OUTFIT_INFO, sizeof(uint32) + state.Outfits.size() * 32);
    packet << static_cast<uint32>(state.Outfits.size());
    for (auto const &[name, appearances] : state.Outfits)
    {
      packet << name;
      packet << static_cast<uint32>(appearances.size());
      for (uint32 appearanceId : appearances)
        packet << appearanceId;
    }
    player->GetSession()->SendPacket(&packet);
  }

  static void SendOutfitResult(Player *player, uint16 opcode, char const *result)
  {
    WorldPacket packet(opcode, 40);
    packet << result;
    player->GetSession()->SendPacket(&packet);
  }

  static bool ValidOutfitName(std::string const &name)
  {
    return !name.empty() && name.size() <= MAX_APPEARANCE_OUTFIT_NAME_BYTES &&
           std::none_of(name.begin(), name.end(), [](char c) { return static_cast<unsigned char>(c) < 0x20; });
  }

  void HandleSaveOutfit(Player *player, WorldPacket &packet)
  {
    std::shared_ptr<PlayerCollectionState> state = GetState(player);
    if (!state)
      return;

    std::string name;
    uint32 count = 0;
    packet >> name >> count;
    bool valid = ValidOutfitName(name) && count <= APPEARANCE_CATEGORY_COUNT &&
                 (state->Outfits.contains(name) || state->Outfits.size() < MAX_APPEARANCE_OUTFITS);
    std::vector<uint32> appearances;
    for (uint32 index = 0; valid && index < count; ++index)
    {
      uint32 appearanceId = 0;
      packet >> appearanceId;
      valid = !appearanceId || state->CollectedAppearances.contains(appearanceId);
      appearances.push_back(appearanceId);
    }
    if (!valid)
    {
      SendOutfitResult(player, SMSG_SAVE_APPEARANCE_OUTFIT_RESULT, "SAVE_APPEARANCE_OUTFIT_UNKNOWN");
      return;
    }

    std::string serialized;
    for (uint32 appearanceId : appearances)
      serialized += (serialized.empty() ? "" : " ") + std::to_string(appearanceId);
    CharacterDatabasePreparedStatement* statement =
        CharacterDatabase.GetPreparedStatement(CHAR_REP_APPEARANCE_OUTFIT);
    statement->SetData(0, player->GetGUID().GetCounter());
    statement->SetData(1, name);
    statement->SetData(2, serialized);
    CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
    transaction->Append(statement);
    ObjectGuid const guid = player->GetGUID();
    std::lock_guard lock(_outfitMutex);
    _pendingOutfitCommits.insert(guid.GetCounter());
    _outfitCallbacks.AddCallback(CharacterDatabase.AsyncCommitTransaction(transaction)).AfterComplete(
        [this, guid, state, name = std::move(name), appearances = std::move(appearances)](bool success) mutable
        {
            _pendingOutfitCommits.erase(guid.GetCounter());
            Player* current = ObjectAccessor::FindConnectedPlayer(guid);
            std::shared_ptr<PlayerCollectionState> currentState = current ? GetState(current) : nullptr;
            if (!currentState)
                return;

            if (success)
                currentState->Outfits[name] = std::move(appearances);
            if (currentState == state)
                SendOutfitResult(current, SMSG_SAVE_APPEARANCE_OUTFIT_RESULT,
                    success ? "SAVE_APPEARANCE_OUTFIT_OK" : "SAVE_APPEARANCE_OUTFIT_UNKNOWN");
            else if (success)
                SendOutfitCollection(current, *currentState);
        });
  }

  void HandleDeleteOutfit(Player *player, WorldPacket &packet)
  {
    std::shared_ptr<PlayerCollectionState> state = GetState(player);
    if (!state)
      return;

    std::string name;
    packet >> name;
    if (!state->Outfits.contains(name))
    {
      SendOutfitResult(player, SMSG_DELETE_APPEARANCE_OUTFIT_RESULT, "DELETE_APPEARANCE_OUTFIT_UNKNOWN");
      return;
    }

    CharacterDatabasePreparedStatement* statement =
        CharacterDatabase.GetPreparedStatement(CHAR_DEL_APPEARANCE_OUTFIT);
    statement->SetData(0, player->GetGUID().GetCounter());
    statement->SetData(1, name);
    CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
    transaction->Append(statement);
    ObjectGuid const guid = player->GetGUID();
    std::lock_guard lock(_outfitMutex);
    _pendingOutfitCommits.insert(guid.GetCounter());
    _outfitCallbacks.AddCallback(CharacterDatabase.AsyncCommitTransaction(transaction)).AfterComplete(
        [this, guid, state, name = std::move(name)](bool success)
        {
            _pendingOutfitCommits.erase(guid.GetCounter());
            Player* current = ObjectAccessor::FindConnectedPlayer(guid);
            std::shared_ptr<PlayerCollectionState> currentState = current ? GetState(current) : nullptr;
            if (!currentState)
                return;

            if (success)
                currentState->Outfits.erase(name);
            if (currentState == state)
                SendOutfitResult(current, SMSG_DELETE_APPEARANCE_OUTFIT_RESULT,
                    success ? "DELETE_APPEARANCE_OUTFIT_OK" : "DELETE_APPEARANCE_OUTFIT_UNKNOWN");
            else if (success)
                SendOutfitCollection(current, *currentState);
        });
  }

  void SendAppearanceVisibility(Player *player,
                                PlayerCollectionState const &state) {
    WorldPacket packet(SMSG_CAN_SEE_APPEARANCES_INFO, 2);
    packet << static_cast<uint8>(state.CanSeeItemAppearances ? 1 : 0);
    packet << static_cast<uint8>(state.CanSeeSpellAppearances ? 1 : 0);
    player->GetSession()->SendPacket(&packet);
  }

  void SendVanityCollection(Player *player,
                            PlayerCollectionState const &state) {
    bool unlockAll = ascensionCompatConfig.GetConfigValue<bool>(
        AscensionCompatConfig::UNLOCK_ALL_VANITY);
    std::vector<uint32> vanityItems;
    if (unlockAll)
    {
      vanityItems = _allVanityItemIds;

      vanityItems.erase(
          std::remove_if(vanityItems.begin(), vanityItems.end(),
                         [](uint32 itemId) { return IsBankVanityItem(itemId); }),
          vanityItems.end());

      for (uint32 itemId : state.OwnedVanityItems)
        if (IsBankVanityItem(itemId))
          vanityItems.push_back(itemId);
    }
    else
      vanityItems.assign(state.OwnedVanityItems.begin(),
                         state.OwnedVanityItems.end());

    vanityItems.erase(std::remove_if(vanityItems.begin(), vanityItems.end(), IsWithheldVanityItem), vanityItems.end());
    std::sort(vanityItems.begin(), vanityItems.end());
    vanityItems.erase(std::unique(vanityItems.begin(), vanityItems.end()), vanityItems.end());
    WorldPacket packet(SMSG_VANITY_COLLECTION_INFO,
                       sizeof(uint32) + vanityItems.size() * sizeof(uint32));
    packet << static_cast<uint32>(vanityItems.size());
    for (uint32 itemId : vanityItems)
      packet << itemId;

    player->GetSession()->SendPacket(&packet);
  }

  void SendApplyResult(Player *player, char const *result) {
    WorldPacket packet(SMSG_APPLY_APPEARANCES_RESULT, std::strlen(result) + 1);
    packet << result;
    player->GetSession()->SendPacket(&packet);
  }

    void RefreshCosmetics(Player* player, PlayerCollectionState& state)
    {
        std::unordered_set<uint32> desired;
        for (uint32 category = 56; category <= 58; ++category)
        {
            uint32 id = state.ActiveAppearances[category];
            auto itr = _appearances.find(id);
            if (state.CollectedAppearances.contains(id) && itr != _appearances.end() &&
                itr->second.CosmeticSpell)
                desired.insert(itr->second.CosmeticSpell);
        }
        for (uint32 spell : state.AppliedCosmeticSpells)
            if (!desired.contains(spell))
                player->RemoveAurasDueToSpell(spell, player->GetGUID());
        state.AppliedCosmeticSpells = std::move(desired);
        if (!player->IsAlive())
            return;
        for (uint32 spell : state.AppliedCosmeticSpells)
        {
            if (!player->HasAura(spell, player->GetGUID()))
                if (Aura* aura = player->AddAura(spell, player))
                {
                    aura->SetMaxDuration(-1);
                    aura->SetDuration(-1);
                }
        }
    }

  void RefreshVisibleItems(Player *player) {
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
      player->SetVisibleItemSlot(
          slot, player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
  }

  bool ExpandItemSetAppearance(
      std::array<uint32, APPEARANCE_CATEGORY_COUNT> &activeAppearances,
      uint32 setAppearanceId) const {
    auto setAppearanceItr = _appearances.find(setAppearanceId);
    if (setAppearanceItr == _appearances.end())
      return false;

    uint32 itemSetId = setAppearanceItr->second.SourceItem;
    auto itemSetItr = _itemSetItems.find(itemSetId);
    if (itemSetItr == _itemSetItems.end())
      return false;

    bool expanded = false;
    for (uint32 itemId : itemSetItr->second) {
      auto itemAppearanceItr = _itemAppearances.find(itemId);
      if (itemAppearanceItr == _itemAppearances.end())
        continue;

      auto appearanceItr = _appearances.find(itemAppearanceItr->second);
      if (appearanceItr == _appearances.end())
        continue;

      AppearanceInfo const &appearance = appearanceItr->second;
      std::array<uint32, 3> const categories = {
          appearance.PrimaryCategory, appearance.SecondaryCategory,
          appearance.TertiaryCategory};
      auto categoryItr = std::find_if(
          categories.begin(), categories.end(), [](uint32 categoryId) {
            return categoryId >= 1 && categoryId <= 14;
          });
      if (categoryItr == categories.end())
        continue;

      activeAppearances[*categoryItr] = itemAppearanceItr->second;
      expanded = true;
    }

    return expanded;
  }

  bool _clientDataLoaded = false;
  std::unordered_map<uint32, AppearanceInfo> _appearances;
  std::unordered_map<uint32, uint32> _itemAppearances;
  std::unordered_map<uint32, std::vector<uint32>> _itemSetItems;
  std::unordered_map<uint32, VanityInfo> _vanityItems;
  std::vector<uint32> _allAppearanceIds;
  std::vector<uint32> _allVanityItemIds;
    std::vector<std::array<uint32, 17>> _woodworkingAppearancePatches;
    std::vector<std::array<uint32, 3>> _woodworkingItemAppearancePatches;

  std::mutex _packetMutex;
  std::unordered_map<uint32, std::deque<WorldPacket>> _pendingPackets;
  std::mutex _rejectedPacketMutex;
  std::unordered_map<uint32, uint32> _rejectedPackets;

  std::mutex _outfitMutex;
  std::unordered_set<uint32> _pendingOutfitCommits;
  AsyncCallbackProcessor<TransactionCallback> _outfitCallbacks;

  std::mutex _stateMutex;
  std::unordered_map<uint32, std::shared_ptr<PlayerCollectionState>>
      _playerStates;
  std::unordered_map<uint32, std::shared_ptr<PlayerCollectionState>>
      _loginStates;
};

AscensionCollectionModels::Entry const* FindCollectionModel(uint32 creatureId)
{
    auto const& models = AscensionCollectionModels::Entries;
    auto const itr = std::lower_bound(models.begin(), models.end(), creatureId,
        [](AscensionCollectionModels::Entry const& model, uint32 value)
        {
            return model.CreatureId < value;
        });
    return itr != models.end() && itr->CreatureId == creatureId ? &*itr : nullptr;
}

bool SendCollectionCreatureQueryResponse(WorldSession* session, uint32 creatureId)
{
    AscensionCollectionModels::Entry const* model = FindCollectionModel(creatureId);
    if (!session || !model)
        return false;

    WorldPacket response(SMSG_CREATURE_QUERY_RESPONSE, 100);
    response << creatureId << std::string(model->Name);
    for (uint8 i = 0; i < 5; ++i)
        response << uint8(0);
    response << uint32(0) << uint32(CREATURE_TYPE_CRITTER) << uint32(0);
    response << uint32(0) << uint32(0) << uint32(0);
    response << model->DisplayId << uint32(0) << uint32(0) << uint32(0);
    response << float(1.0f) << float(1.0f) << uint8(0);
    for (uint8 i = 0; i < 6; ++i)
        response << uint32(0);
    response << uint32(0);
    session->SendPacket(&response);
    return true;
}

enum PersonalBankKind : uint8
{
    PERSONAL_BANK_PERSONAL = 0,
    PERSONAL_BANK_REALM = 1
};

enum PersonalBankSpell : uint32
{
    SPELL_PERSONAL_BANK = 100702,
    SPELL_CELESTIAL_PERSONAL_BANK = 93416,
    SPELL_REALM_BANK = 92078
};

enum PersonalBankObject : uint32
{
    BANK_OBJECT_PERSONAL_ALLIANCE = 475001,
    BANK_OBJECT_PERSONAL_HORDE = 475002,
    BANK_OBJECT_CELESTIAL = 80782,
    BANK_OBJECT_REALM_ALLIANCE = 80159,
    BANK_OBJECT_REALM_HORDE = 80160
};

constexpr uint32 BANK_VAULT_DURATION = 10 * 60;

[[nodiscard]] uint32 BankObjectEntry(uint32 spellId, TeamId team)
{
    bool const alliance = team == TEAM_ALLIANCE;
    if (spellId == SPELL_REALM_BANK)
        return alliance ? BANK_OBJECT_REALM_ALLIANCE : BANK_OBJECT_REALM_HORDE;
    if (spellId == SPELL_CELESTIAL_PERSONAL_BANK)
        return BANK_OBJECT_CELESTIAL;
    return alliance ? BANK_OBJECT_PERSONAL_ALLIANCE : BANK_OBJECT_PERSONAL_HORDE;
}

struct PersonalBankVault
{
    ObjectGuid Owner;
    uint8 Kind = PERSONAL_BANK_PERSONAL;
};

std::unordered_map<ObjectGuid::LowType, PersonalBankVault> personalBankVaults;

void SendBankPermissions(Player* player, uint8 kind)
{
    AscensionPersonalBank::SendKindHint(player, uint8(kind));
}

[[nodiscard]] float AverageEquippedItemLevel(Player* player, uint8 emptiedSlot)
{
    float sum = 0.0f;
    uint32 count = 0;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        if (slot == EQUIPMENT_SLOT_TABARD || slot == EQUIPMENT_SLOT_RANGED || slot == EQUIPMENT_SLOT_OFFHAND ||
            slot == EQUIPMENT_SLOT_BODY)
            continue;

        ++count;
        if (Item* item = slot == emptiedSlot ? nullptr : player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            sum += item->GetTemplate()->Quality == ITEM_QUALITY_HEIRLOOM ? player->GetLevel()
                                                                        : item->GetTemplate()->ItemLevel;
    }
    return sum / count;
}

[[nodiscard]] WorldPacket BuildAverageItemLevel(Player* player, uint8 emptiedSlot = EQUIPMENT_SLOT_END)
{
    WorldPacket data(SMSG_UPDATE_OBJECT_ADDON, 16);
    data << player->GetGUID() << PLAYER_ADDON_FIELD_AVERAGE_ITEM_LEVEL
         << AverageEquippedItemLevel(player, emptiedSlot);
    return data;
}

void SendAverageItemLevel(Player* player, uint8 emptiedSlot = EQUIPMENT_SLOT_END)
{
    WorldPacket data = BuildAverageItemLevel(player, emptiedSlot);
    player->SendMessageToSet(&data, true);
}

[[nodiscard]] bool OwnsPlacedBank(Player* player, uint8 kind)
{
    static std::array<PersonalBankSpell, 2> const personalSpells =
        { SPELL_PERSONAL_BANK, SPELL_CELESTIAL_PERSONAL_BANK };
    static std::array<uint32, 3> const personalItems = { 110000, 134985, 509892 };

    if (kind == PERSONAL_BANK_REALM)
        return player->HasSpell(SPELL_REALM_BANK) || player->HasItemCount(1180097);

    for (PersonalBankSpell spell : personalSpells)
        if (player->HasSpell(spell))
            return true;

    for (uint32 item : personalItems)
        if (player->HasItemCount(item))
            return true;

    return false;
}

bool HandlePersonalBankActivate(Player* player, WorldPacket const& packet)
{
    ObjectGuid banker;
    bool fullUpdate = false;
    try
    {
        WorldPacket copy(packet);
        WorldPackets::Guild::GuildBankActivate activate(std::move(copy));
        activate.Read();
        banker = activate.Banker;
        fullUpdate = activate.FullUpdate;
    }
    catch (...)
    {
        return false;
    }

    auto itr = personalBankVaults.find(banker.GetCounter());
    if (itr == personalBankVaults.end())
        return false;

    if (!OwnsPlacedBank(player, itr->second.Kind))
    {
        ChatHandler(player->GetSession())
            .PSendSysMessage("You do not own a {} bank.",
                             itr->second.Kind == PERSONAL_BANK_REALM ? "Realm" : "Personal");
        LOG_INFO("coa",
                 "{} touched a {} bank placed by {} (vault {}) without owning one",
                 player->GetName(),
                 itr->second.Kind == PERSONAL_BANK_REALM ? "realm" : "personal",
                 itr->second.Owner.ToString(), banker.ToString());
        return true;
    }

    SendBankPermissions(player, itr->second.Kind);
    AscensionPersonalBank::Opened(player, itr->second.Kind, banker);

    LOG_INFO("coa",
             "Personal bank opened for {} (kind {}, vault {}, full update {})",
             player->GetName(), uint32(itr->second.Kind), banker.ToString(),
             fullUpdate);
    return true;
}

static float GroundHeightBeneath(Map* map, float x, float y, float feetZ)
{
    constexpr float PROBE_ABOVE_FEET = 0.3f;
    constexpr float STEP = 0.5f;

    float const height = map->GetHeight(x, y, feetZ + PROBE_ABOVE_FEET, true, STEP);
    if (height > INVALID_HEIGHT && height <= feetZ + STEP && height >= feetZ - STEP)
        return height;

    return feetZ;
}

class spell_ascension_personal_bank : public SpellScript
{
    PrepareSpellScript(spell_ascension_personal_bank);

    void SummonBankVault()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || !player->IsInWorld())
            return;

        uint8 kind = PERSONAL_BANK_PERSONAL;
        if (GetSpellInfo()->Id == SPELL_REALM_BANK)
            kind = PERSONAL_BANK_REALM;

        uint32 const entry = BankObjectEntry(GetSpellInfo()->Id, player->GetTeamId());

        float x, y, z;
        player->GetClosePoint(x, y, z, player->GetCombatReach(), 2.0f);

        z = GroundHeightBeneath(player->GetMap(), x, y, player->GetPositionZ());

        GameObject* vault = player->GetMap()->SummonGameObject(
            entry, x, y, z, player->GetOrientation(), 0.0f, 0.0f, 0.0f,
            0.0f, BANK_VAULT_DURATION, true);
        if (vault)
            vault->SetPhaseMask(player->GetPhaseMask(), true);

        if (!vault)
        {
            LOG_ERROR("coa",
                      "Could not summon bank object {} for {} (spell {})",
                      entry, player->GetName(), GetSpellInfo()->Id);
            return;
        }

        personalBankVaults[vault->GetGUID().GetCounter()] = {player->GetGUID(), kind};

        player->AddSpellCooldown(GetSpellInfo()->Id, 0, BANK_VAULT_DURATION * IN_MILLISECONDS, true);

        LOG_INFO("coa",
                 "Summoned bank object {} (kind {}, entry {}, spell {}) for {} at "
                 "{:.2f} {:.2f} {:.2f} (caster feet {:.2f})",
                 vault->GetGUID().ToString(), uint32(kind), entry,
                 GetSpellInfo()->Id, player->GetName(), x, y, z,
                 player->GetPositionZ());
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_personal_bank::SummonBankVault);
    }
};

bool QueueAscensionDungeonDifficulty(WorldSession* session, WorldPacket const& packet)
{
    if (packet.GetOpcode() != CMSG_COA_SET_DUNGEON_DIFFICULTY)
        return false;
    if (!session || packet.size() != sizeof(uint8))
        return true;
    uint8 const difficulty = packet.read<uint8>(0);
    if (difficulty >= MAX_DUNGEON_DIFFICULTY)
        return true;
    WorldPacket* request = new WorldPacket(MSG_SET_DUNGEON_DIFFICULTY, sizeof(uint32));
    *request << uint32(difficulty);
    session->QueuePacket(request);
    return true;
}

class AscensionCompatServerScript : public ServerScript {
public:
  AscensionCompatServerScript()
      : ServerScript("AscensionCompatServerScript",
                     {SERVERHOOK_CAN_PACKET_RECEIVE_EARLY, SERVERHOOK_CAN_PACKET_RECEIVE,
                         SERVERHOOK_CAN_PACKET_SEND})
  {
  }

    bool CanPacketSend(WorldSession* session, WorldPacket const& packet) override
    {
        if (packet.GetOpcode() != SMSG_ITEM_QUERY_SINGLE_RESPONSE || packet.size() < sizeof(uint32))
            return true;

        Player* player = session ? session->GetPlayer() : nullptr;
        if (player && player->IsInWorld() &&
            ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
            AscensionDisplayPatchService::Instance().SendItemRowOnDemand(player, packet.read<uint32>(0));
        return true;
    }

    [[nodiscard]] bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (session && session->GetPlayer())
        {
            Player* player = session->GetPlayer();

            if (packet.GetOpcode() == CMSG_GUILD_BANKER_ACTIVATE)
            {
                if (HandlePersonalBankActivate(player, packet))
                    return false;
            }
            else if (AscensionPersonalBank::IsOpen(player) &&
                     AscensionPersonalBank::HandlePacket(player, packet))
                return false;
        }

        if (!session || !session->GetPlayer() ||
            !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
            return true;

        if (packet.GetOpcode() == CMSG_SET_ACTIVE_MOVER)
            AscensionClassService::Instance().OnPlayerActiveMover(session->GetPlayer());

        if (packet.GetOpcode() == CMSG_INSPECT && packet.size() >= sizeof(uint64))
        {
            if (Player* target = ObjectAccessor::GetPlayer(*session->GetPlayer(), packet.read<ObjectGuid>(0)))
            {
                WorldPacket data = BuildAverageItemLevel(target);
                session->SendPacket(&data);
            }
            return true;
        }

        if (packet.GetOpcode() == CMSG_GET_MIRRORIMAGE_DATA && packet.size() >= sizeof(uint64))
        {
            ObjectGuid guid = packet.read<ObjectGuid>(0);
            CreatureDisplayPreset const* preset = nullptr;
            uint32 unitDisplayId = 0;

            if (guid.IsCreatureOrVehicle())
            {
                if (Creature const* creature = session->GetPlayer()->GetMap()->GetCreature(guid))
                    unitDisplayId = creature->GetDisplayId();

                preset = sAscensionPresets->GetPreset(guid.GetEntry(), unitDisplayId);
            }

            if (!preset)
            {
                preset = sAscensionPresets->GetActivePresetOverride(guid);
            }

            if (preset)
            {
                WorldPacket response(SMSG_MIRRORIMAGE_DATA, 68);
                response << guid;
                response << uint32(unitDisplayId != 0 ? unitDisplayId : preset->display_id);
                response << uint8(preset->race);
                response << uint8(preset->gender);
                response << uint8(preset->class_id);
                response << uint8(preset->skin);
                response << uint8(preset->face);
                response << uint8(preset->hair);
                response << uint8(preset->haircolor);
                response << uint8(preset->facialhair);
                response << uint32(preset->guild_id);
                for (uint32 item : preset->items)
                    response << uint32(item);

                session->SendPacket(&response);
                return false;
            }
            return true;
        }

        if (packet.GetOpcode() != CMSG_CREATURE_QUERY || packet.size() < sizeof(uint32))
            return true;

        uint32 const entry = packet.read<uint32>(0);
        if (sObjectMgr->GetCreatureTemplate(entry))
            return true;

        AscensionCollectionModels::Entry const* model = FindCollectionModel(entry);
        if (!model)
            return true;

        SendCollectionCreatureQueryResponse(session, entry);
        LOG_DEBUG("coa", "Answered local creature preview query: entry {}, display {}, payload {}",
            entry, model->DisplayId, packet.size());
        return false;
    }

  [[nodiscard]] bool CanPacketReceiveEarly(WorldSession *session,
                                           WorldPacket const &packet) override {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED))
      return true;

    if (QueueAscensionDungeonDifficulty(session, packet))
      return false;

    uint32 opcode = packet.GetOpcode();

    if (opcode == CMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES)
    {
      if (session)
        AscensionClassService::Instance().QueueKnownEntriesUpload(session->GetAccountId(), packet);
      return false;
    }

    if (opcode == CMSG_UNLEARN_TALENTS)
    {
      if (session)
        AscensionClassService::Instance().QueueTalentReset(session->GetAccountId());
      return false;
    }

    if (IsAscensionCharacterSelectionOpcode(static_cast<uint16>(opcode)))
    {
      if (HandleAscensionCharacterSelectionPacket(session, packet))
        return false;
    }
    else if (opcode == CMSG_CHAR_ENUM)
    {
      SendAscensionCharacterListInfo(session);
      AscensionCollectionService& service = AscensionCollectionService::Instance();
      service.SendRealmInfo(session);
      service.SendSecureAddonList(session);
    }

    uint32 firstOpcode = ascensionCompatConfig.GetConfigValue<uint32>(
        AscensionCompatConfig::FIRST_EXTENSION_OPCODE);
    uint32 lastOpcode = ascensionCompatConfig.GetConfigValue<uint32>(
        AscensionCompatConfig::LAST_EXTENSION_OPCODE);

    if (opcode < firstOpcode || opcode > lastOpcode)
      return true;

    if (opcode == CMSG_ANTICHEAT_ALERT)
      return true;

    if (std::find(CORE_EXTENSION_OPCODES.begin(), CORE_EXTENSION_OPCODES.end(), opcode) !=
        CORE_EXTENSION_OPCODES.end())
      return true;

    if (opcode == CMSG_CREATURE_QUERY_BULK || opcode == CMSG_ITEM_QUERY_BULK)
    {
        AscensionCollectionService& service = AscensionCollectionService::Instance();
        uint32 const maxEntries = opcode == CMSG_ITEM_QUERY_BULK ? MAX_ITEM_QUERY_BULK_ENTRIES :
            MAX_CREATURE_QUERY_BULK_ENTRIES;
        if (ReadBulkQueryEntries(packet, maxEntries).empty())
            service.RejectClientPacket(session->GetAccountId(), packet, "malformed bulk query");
        else
            service.QueueClientPacket(session->GetAccountId(), packet);
        return false;
    }

    static constexpr std::array<uint32, 13> kChallengeCmsgs = {
        CMSG_COA_START_CHALLENGE,
        CMSG_COA_STOP_CHALLENGE,
        CMSG_COA_QUERY_FAILURES,
        CMSG_COA_SYNC_RESPONSE,
        CMSG_COA_QUERY_COMPLETIONS,
        CMSG_COA_SAVE_TRIAL,
        CMSG_COA_DELETE_TRIAL,
        CMSG_COA_QUERY_TRIALS,
        CMSG_COA_ACTIVATE_TRIAL,
        CMSG_COA_DEACTIVATE_TRIAL,
        CMSG_COA_RATE_TRIAL,
        CMSG_COA_QUERY_TRIAL_COMPLETIONS,
        CMSG_COA_TOGGLE_GAME_MODE,
    };
    if (std::find(kChallengeCmsgs.begin(), kChallengeCmsgs.end(), opcode) !=
        kChallengeCmsgs.end())
      return true;

    if (std::find(MODULE_EXTENSION_OPCODES.begin(), MODULE_EXTENSION_OPCODES.end(), opcode) !=
        MODULE_EXTENSION_OPCODES.end())
      return true;

    if (QueueAscensionManastormPacket(session, packet))
      return false;

    if (opcode == CMSG_QUERY_CUSTOM_STORE || opcode == CMSG_PURCHASE_CUSTOM_STORE_ITEM)
    {
      if (!session->GetPlayer())
      {
        if (opcode == CMSG_QUERY_CUSTOM_STORE)
        {
          WorldPacket empty(SMSG_QUERY_CUSTOM_STORE_RESULT, 32);
          empty << "QUERY_CUSTOM_STORE_OK";
          empty << uint32(0);
          session->SendPacket(&empty);
        }
        return false;
      }

      AscensionCollectionService::Instance().QueueClientPacket(session->GetAccountId(), packet);
      return false;
    }

    if (std::find(QUEUED_EXTENSION_OPCODES.begin(), QUEUED_EXTENSION_OPCODES.end(), opcode) !=
        QUEUED_EXTENSION_OPCODES.end())
        AscensionCollectionService::Instance().QueueClientPacket(session->GetAccountId(), packet);

    if (opcode == CMSG_MISSILE_FIRE_POSITION)
    {
      if (ascensionCompatConfig.GetConfigValue<bool>(
              AscensionCompatConfig::LOG_CONSUMED_PACKETS))
      {
        LOG_INFO("coa",
                 "Consumed Ascension missile-position packet payload={} bytes [{}]",
                 packet.size(), DescribePacketPayload(packet));
      }

      return false;
    }

    if (AscensionCompatOpcodes::Dispatch(session, packet))
      return false;

    if (ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::LOG_CONSUMED_PACKETS)) {
      char const *name = ExtensionOpcodeName(uint16(opcode));
      LOG_INFO("coa",
               "Consumed Ascension extension packet opcode=0x{:04X} ({}) "
               "payload={} bytes [{}]",
               opcode, name ? name : "unknown", packet.size(),
               DescribePacketPayload(packet));
    }

    return false;
  }
};

class AscensionCompatCommandScript : public CommandScript {
public:
  AscensionCompatCommandScript()
      : CommandScript("AscensionCompatCommandScript") {}

  ChatCommandTable GetCommands() const override {
    static ChatCommandTable spellChargesCommandTable = {
        {"reset", HandleSpellChargesResetCommand, SEC_PLAYER, Console::No},
        {"resync", HandleSpellChargesResyncCommand, SEC_PLAYER, Console::No}};

    static ChatCommandTable commandTable = {
        {"localfreshcheck", HandleAscensionFreshCharacterCheck, SEC_ADMINISTRATOR, Console::Yes},
        {"localreloadpresets", HandleLocalReloadPresetsCommand, SEC_ADMINISTRATOR, Console::Yes},
        {"morphpreset", HandleMorphPresetCommand, SEC_ADMINISTRATOR, Console::No},
        {"demorphpreset", HandleDemorphPresetCommand, SEC_ADMINISTRATOR, Console::No},
        {"localreloadoutfits", HandleLocalReloadPresetsCommand, SEC_ADMINISTRATOR, Console::Yes},
        {"morphoutfit", HandleMorphPresetCommand, SEC_ADMINISTRATOR, Console::No},
        {"localresource", HandleLocalResourceCommand, SEC_PLAYER,
         Console::No},
        {"localtime", HandleLocalTimeCommand, SEC_GAMEMASTER, Console::No},
        {"spellcharges", spellChargesCommandTable},
        {"localclassrepair", HandleLocalClassRepairCommand, SEC_PLAYER,
         Console::No},
        {"bankground", HandleBankGroundCommand, SEC_ADMINISTRATOR, Console::No}};
    return commandTable;
  }

  static bool HandleBankGroundCommand(ChatHandler *handler) {
    Player *player = handler->GetPlayer();
    if (!player)
      return false;

    float x, y, z;
    player->GetClosePoint(x, y, z, player->GetCombatReach(), 2.0f);
    float const feetZ = player->GetPositionZ();
    Map *map = player->GetMap();

    handler->PSendSysMessage("feet {:.2f} on map {} at {:.2f} {:.2f}", feetZ,
                             player->GetMapId(), player->GetPositionX(),
                             player->GetPositionY());
    handler->PSendSysMessage("spot {:.2f} {:.2f} (2 yards {:.2f} rad ahead)", x,
                             y, player->GetOrientation());
    for (float start : {feetZ + 0.3f, feetZ + 2.5f, feetZ + 10.0f}) {
      handler->PSendSysMessage(
          "  probe from {:.2f}: terrain {:.2f} | terrain+vmap {:.2f}", start,
          map->GetHeight(x, y, start, false, 3.0f),
          map->GetHeight(x, y, start, true, 3.0f));
    }
    handler->PSendSysMessage("  summon would ground at {:.2f} (riser {:.2f})",
                             GroundHeightBeneath(map, x, y, feetZ),
                             GroundHeightBeneath(map, x, y, feetZ) - feetZ);
    LOG_INFO("coa",
             "Bank ground probe for {}: feet {:.2f}, spot {:.2f} {:.2f}, "
             "terrain {:.2f}, terrain+vmap {:.2f}, chosen {:.2f}",
             player->GetName(), feetZ, x, y,
             map->GetHeight(x, y, feetZ + 0.3f, false, 3.0f),
             map->GetHeight(x, y, feetZ + 0.3f, true, 3.0f),
             GroundHeightBeneath(map, x, y, feetZ));
    return true;
  }

  static constexpr float REAL_TIME_GAME_SPEED = 0.01666667f;

  static time_t SameDayAt(time_t time, uint8 hour, uint8 minute) {
    std::tm local = Acore::Time::TimeBreakdown(time);
    local.tm_hour = hour;
    local.tm_min = minute;
    local.tm_sec = 0;
    local.tm_isdst = -1;
    return std::mktime(&local);
  }

  static bool HandleLocalTimeCommand(ChatHandler *handler, Optional<uint8> hour,
                                     Optional<uint8> minute) {
    Player *player = handler->GetPlayer();
    if (!player)
      return false;

    if ((hour && *hour > 23) || (minute && *minute > 59))
    {
      handler->SendSysMessage("Give an hour from 0 to 23 and an optional minute from 0 to 59, or no "
                              "arguments to follow the server clock again.");
      return true;
    }

    time_t const now = GameTime::GetGameTime().count();
    time_t const shown = hour ? SameDayAt(now, *hour, minute.value_or(0)) : now;
    WorldPacket data(SMSG_LOGIN_SETTIMESPEED, 4 + 4 + 4);
    data.AppendPackedTime(shown);
    data << REAL_TIME_GAME_SPEED;
    data << uint32(0);
    player->SendDirectMessage(&data);

    std::tm const clock = Acore::Time::TimeBreakdown(shown);
    handler->PSendSysMessage("Your client's clock now reads {:02}:{:02}.", clock.tm_hour, clock.tm_min);
    return true;
  }

  static bool HandleLocalClassRepairCommand(ChatHandler *handler) {
    Player *player = handler->GetPlayer();
    if (!player)
      return false;

    AscensionClassService::Instance().SynchronizeProgression(player);
    AscensionClassService::Instance().SynchronizeProficiencies(player);
    bool repaired =
        AscensionClassService::Instance().RepairStarterKit(player, true);
    if (!repaired)
      handler->SendSysMessage("Your custom-class starter kit is complete.");
    return true;
  }

  static bool HandleLocalResourceCommand(ChatHandler *handler) {
    AscensionResourceService::Instance().SendStatus(handler);
    return true;
  }

  static bool HandleSpellChargesResetCommand(ChatHandler* handler)
  {
    Player* player = handler->GetPlayer();
    if (!player)
      return false;

    player->RestoreAllSpellCharges();
    player->SendAllSpellChargeStates();
    handler->SendSysMessage("All spell-charge pools reset to full.");
    return true;
  }

  static bool HandleSpellChargesResyncCommand(ChatHandler* handler)
  {
    Player* player = handler->GetPlayer();
    if (!player)
      return false;

    player->SendAllSpellChargeStates();
    SendAscensionRunemasterEchoesCooldown(player);
    handler->SendSysMessage("Spell-charge state resent to the client.");
    return true;
  }

  static bool HandleLocalReloadPresetsCommand(ChatHandler* handler) {
    sAscensionPresets->LoadFromDB();
    handler->PSendSysMessage("Reloaded %u creature display presets into cache.", uint32(sAscensionPresets->GetPresetCount()));
    return true;
  }

  static bool HandleMorphPresetCommand(ChatHandler* handler, uint32 entry, Optional<uint32> displayIdOpt) {
    Unit* target = handler->getSelectedUnit();
    if (!target)
      target = handler->GetPlayer();
    if (!target)
      return false;

    uint32 displayId = displayIdOpt ? *displayIdOpt : 0;
    CreatureDisplayPreset const* preset = nullptr;

    if (displayId != 0)
    {
      preset = sAscensionPresets->GetPreset(entry, displayId);
    }
    else if (Player* targetPlayer = target->ToPlayer())
    {
      preset = sAscensionPresets->GetPresetByGender(entry, targetPlayer->getGender());
    }
    else
    {
      preset = sAscensionPresets->GetPreset(entry);
    }

    if (!preset)
    {
      handler->PSendSysMessage("No creature display preset found for entry %u.", entry);
      return false;
    }

    sAscensionPresets->SetActivePresetOverride(target->GetGUID(), entry, preset->display_id);
    target->SetDisplayId(preset->display_id);
    target->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);

    WorldPacket response(SMSG_MIRRORIMAGE_DATA, 68);
    response << target->GetGUID();
    response << uint32(preset->display_id);
    response << uint8(preset->race);
    response << uint8(preset->gender);
    response << uint8(preset->class_id);
    response << uint8(preset->skin);
    response << uint8(preset->face);
    response << uint8(preset->hair);
    response << uint8(preset->haircolor);
    response << uint8(preset->facialhair);
    response << uint32(preset->guild_id);
    for (uint32 item : preset->items)
      response << uint32(item);

    target->SendMessageToSet(&response, true);
    handler->PSendSysMessage("Morphed into creature display preset for entry %u (display %u, %s).",
        entry, preset->display_id, preset->gender == 1 ? "Female" : "Male");
    return true;
  }

  static bool HandleDemorphPresetCommand(ChatHandler* handler) {
    Unit* target = handler->getSelectedUnit();
    if (!target)
      target = handler->GetPlayer();
    if (!target)
      return false;

    sAscensionPresets->ClearActivePresetOverride(target->GetGUID());
    if (Player* player = target->ToPlayer())
    {
      player->RemoveUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      player->InitDisplayIds();
    }
    else if (Creature* creature = target->ToCreature())
    {
      if (CreatureTemplate const* cinfo = creature->GetCreatureTemplate())
      {
        if (CreatureModel const* model = ObjectMgr::ChooseDisplayId(cinfo, creature->GetCreatureData()))
        {
          creature->SetDisplayId(model->CreatureDisplayID, model->DisplayScale);
          creature->SetNativeDisplayId(model->CreatureDisplayID);
        }
      }
      if (sAscensionPresets->HasPreset(creature->GetEntry()))
      {
        creature->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      }
      else
      {
        creature->RemoveUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      }
    }
    else
    {
      target->RemoveUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      target->DeMorph();
    }

    handler->PSendSysMessage("Demorphed creature display preset.");
    return true;
  }
};

class AscensionCompatPlayerScript : public PlayerScript {
    std::mutex _pendingEquipmentLock;
    std::unordered_map<ObjectGuid, std::vector<ObjectGuid>> _pendingEquipment;

    void EquipNewItems(Player* player)
    {
        std::vector<ObjectGuid> items;
        {
            std::lock_guard<std::mutex> lock(_pendingEquipmentLock);
            auto itr = _pendingEquipment.find(player->GetGUID());
            if (itr == _pendingEquipment.end())
                return;

            items = std::move(itr->second);
            _pendingEquipment.erase(itr);
        }

        for (ObjectGuid guid : items)
        {
            Item* item = player->GetItemByGuid(guid);
            if (!item || item->IsInTrade() || !Player::IsInventoryPos(item->GetPos()))
                continue;

            uint16 dest = 0;
            if (player->CanEquipItem(NULL_SLOT, dest, item, false) != EQUIP_ERR_OK ||
                !Player::IsEquipmentPos(dest) || player->GetItemByPos(dest))
                continue;

            Item* offhand = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
            ItemTemplate const* proto = item->GetTemplate();
            if (uint8(dest) == EQUIPMENT_SLOT_MAINHAND && proto->InventoryType == INVTYPE_2HWEAPON &&
                offhand && !player->CanTitanGrip(proto) &&
                !player->CanUseTwoHandWithShield(proto, offhand->GetTemplate()))
                continue;

            player->SwapItem(item->GetPos(), dest);
        }
    }

public:
  AscensionCompatPlayerScript()
      : PlayerScript(
            "AscensionCompatPlayerScript",
            {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_SAVE,
             PLAYERHOOK_ON_AFTER_SET_VISIBLE_ITEM_SLOT, PLAYERHOOK_ON_EQUIP, PLAYERHOOK_ON_DELETE,
             PLAYERHOOK_ON_TAKE_MAIL_ITEM, PLAYERHOOK_CAN_CAST_ITEM_USE_SPELL,
             PLAYERHOOK_ON_STORE_NEW_ITEM, PLAYERHOOK_ON_CREATE_ITEM,
             PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST,
             PLAYERHOOK_ON_PLAYER_IS_CLASS, PLAYERHOOK_ON_LEVEL_CHANGED,
             PLAYERHOOK_ON_LEARN_SPELL, PLAYERHOOK_ON_LEARN_TRAINER_SPELL, PLAYERHOOK_ON_FORGOT_SPELL,
             PLAYERHOOK_ON_AFTER_SPEC_SLOT_CHANGED,
             PLAYERHOOK_ON_CREATE_INITIAL_ITEMS,
             PLAYERHOOK_ON_GET_AMMO_DISPLAY,
             PLAYERHOOK_ON_AFTER_UPDATE_ATTACK_POWER_AND_DAMAGE,
             PLAYERHOOK_ON_SEND_INITIAL_PACKETS_BEFORE_ADD_TO_MAP,
             PLAYERHOOK_CAN_USE_ITEM,
             PLAYERHOOK_CHECK_ITEM_IN_SLOT_AT_LOAD_INVENTORY,
             PLAYERHOOK_ON_TEMPORARY_SPELL_REMOVE_NOTICE,
             PLAYERHOOK_ON_TEMPORARY_SPELL_REPLACEMENT_NOTICE}) {}

    void OnPlayerTemporarySpellRemoveNotice(Player* player, uint32 spellId, bool sent) override
    {
        AscensionDisplayPatchService::Instance().SendSpellNoticeRow(player, spellId, !sent);
    }

    void OnPlayerTemporarySpellReplacementNotice(Player* player, uint32 previous, uint32 replacement,
        bool sent) override
    {
        AscensionDisplayPatchService& patches = AscensionDisplayPatchService::Instance();
        patches.SendSwapPlacementRow(player, replacement, !sent);
        if (sent)
            return;
        std::vector<uint32> standIns;
        for (uint32 spell : { previous, replacement })
            if (player->IsTemporarySpellReplacementStandIn(spell))
                standIns.push_back(spell);
        patches.SendSwapEntries(player, standIns);
    }

    bool OnPlayerCanUseItem(Player* player, ItemTemplate const* item, InventoryResult& result) override
    {
        if (!ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) ||
            item->Spells[0].SpellId != 55884)
            return true;
        uint32 const learned = item->Spells[1].SpellId;
        auto const& spells = AscensionWildcard::SPECIALIZATION_SWAP_SPELLS;
        if (!player->HasSpell(learned) || std::find(spells.begin(), spells.end(), learned) == spells.end())
            return true;
        result = EQUIP_ERR_CANT_DO_RIGHT_NOW;
        ChatHandler(player->GetSession()).SendSysMessage("That specialization slot is already unlocked.");
        return false;
    }

    void OnPlayerGetAmmoDisplay(Player* player, SpellInfo const* spellInfo,
        uint32& displayId, uint32& inventoryType) override
    {
        if (!player || !spellInfo || !spellInfo->IsAutoRepeatRangedSpell())
            return;

        Item const* weapon = player->GetWeaponForAttack(RANGED_ATTACK);
        if (!weapon)
            return;

        ItemTemplate const* item = weapon->GetTemplate();
        if (item->Class != ITEM_CLASS_WEAPON ||
            (item->SubClass != ITEM_SUBCLASS_WEAPON_BOW && item->SubClass != ITEM_SUBCLASS_WEAPON_GUN &&
             item->SubClass != ITEM_SUBCLASS_WEAPON_CROSSBOW))
            return;

        if (uint32 const appearance = AscensionCollectionService::Instance().GetAmmunitionDisplay(player))
        {
            displayId = appearance;
            inventoryType = INVTYPE_AMMO;
        }
    }

    void OnPlayerAfterUpdateAttackPowerAndDamage(Player* player, float&, float&,
        float& modifier, float&, bool ranged) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
            HandleAscensionBarbarianAttackPower(player, modifier, ranged);
    }

    void OnPlayerSendInitialPacketsBeforeAddToMap(Player* player, WorldPacket&) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
        {
            SendAscensionCoAConfig(player->GetSession());
            AscensionCollectionService::Instance().PrepareOwnedCompanionsBeforeMap(player);
            AscensionCollectionService::Instance().PrepareOwnedBankSpellsBeforeMap(player);
            AscensionClassService::Instance().PrepareTaughtAbilitiesBeforeMap(player);
            AscensionClassService::Instance().QueueCharacterAdvancementState(player);
        }
    }

  bool OnPlayerCreateInitialItems(Player* player, bool& handled) override
  {
    if (handled || !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) ||
        !IsAscensionCustomClass(player))
      return true;

    handled = true;
    if (!AscensionClassService::Instance().InitializeLiveBaseline(player))
      return false;

    PlaceStartingActionButtons(player);
    return AscensionClassService::Instance().InitializeLiveStarterKit(player);
  }

  static void PlaceStartingActionButtons(Player* player)
  {
    PlayerInfo const* info = sObjectMgr->GetPlayerInfo(player->getRace(true), player->getClass());
    if (!info)
      return;

    for (PlayerCreateInfoAction const& action : info->action)
      if (!player->GetActionButton(action.button))
        player->addActionButton(action.button, action.action, action.type);
  }

  bool OnPlayerCheckItemInSlotAtLoadInventory(Player* player, Item* item, uint8 slot,
      uint8& err, uint16& dest) override
  {
      if (!ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) ||
          slot != EQUIPMENT_SLOT_OFFHAND || player->getClass() != CLASS_SON_OF_ARUGAL)
          return true;

      uint8 result = player->CanEquipItem(slot, dest, item, false, false);
      if (result == EQUIP_ERR_OK || player->CanDualWield())
      {
          err = result;
          return false;
      }

      player->SetCanDualWield(true);
      uint16 dualWieldDest = 0;
      uint8 const dualWieldResult = player->CanEquipItem(slot, dualWieldDest, item, false, false);
      if (dualWieldResult != EQUIP_ERR_OK)
      {
          player->SetCanDualWield(false);
          err = result;
          return false;
      }

      dest = dualWieldDest;
      err = EQUIP_ERR_OK;
      return false;
  }

  static void RefreshScaledQuestQueries(Player *player) {
    if (!LocalLevelScaling::QuestEnabled.load(std::memory_order_relaxed))
      return;

    for (auto const& [questId, status] : player->getQuestStatusMap())
    {
      if (status.Status != QUEST_STATUS_INCOMPLETE &&
          status.Status != QUEST_STATUS_COMPLETE &&
          status.Status != QUEST_STATUS_FAILED)
        continue;

      if (Quest const* quest = sObjectMgr->GetQuestTemplate(questId))
        player->PlayerTalkClass->SendQuestQueryResponse(quest);
    }
  }

  void OnPlayerLogin(Player *player) override {
    if (ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED)) {
      AscensionClassService::Instance().OnPlayerLogin(player);
      RemoveLegacyQuestSpells(player);
      SynchronizeAscensionClassMechanics(player);
      AscensionResourceService::Instance().OnPlayerLogin(player);
      AscensionCollectionService::Instance().OnPlayerLogin(player);
      AscensionDisplayPatchService::Instance().OnPlayerLogin(player);
      RefreshScaledQuestQueries(player);
      SendAverageItemLevel(player);
    }
  }

    void OnPlayerSave(Player* player) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
            AscensionClassService::Instance().SaveSlot(player);
    }

  void OnPlayerLevelChanged(Player *player, uint8) override {
    if (ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED))
    {
      SendAverageItemLevel(player);
      AscensionFreepick::Synchronize(player);
      AscensionClassService::Instance().SynchronizeProgression(player);
      AscensionClassService::Instance().SynchronizeProficiencies(player);
      AscensionClassService::Instance().SendCharacterAdvancementKnownEntries(player);

      RefreshScaledQuestQueries(player);
    }
  }

  void OnPlayerLearnSpell(Player *player, uint32 spellId) override {
    if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
        IsAscensionCustomClass(player) && !AscensionWildcard::IsWildcardHero(player) &&
        std::find(AscensionWildcard::SPECIALIZATION_SWAP_SPELLS.begin(),
                  AscensionWildcard::SPECIALIZATION_SWAP_SPELLS.end(), spellId) !=
            AscensionWildcard::SPECIALIZATION_SWAP_SPELLS.end())
      AscensionClassService::Instance().SendActiveSlot(player);

    if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
        (spellId == 712325 || spellId == 712389 || spellId == 521211))
      SynchronizeAscensionRunemasterEchoes(player,
          AscensionClassService::Instance().GetActiveSpecialization(player));

    if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
        AscensionClassService::Instance().AffectsTaughtAbilities(spellId))
      AscensionClassService::Instance().SynchronizeTaughtAbilities(player);

    if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
        AscensionClassService::Instance().AffectsTalentReplacements(spellId))
      AscensionClassService::Instance().SynchronizeTalentReplacements(player);

    if (ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED) &&
        AscensionClassService::Instance().AffectsProficiencies(spellId))
      AscensionClassService::Instance().SynchronizeProficiencies(player);
  }

    void OnPlayerLearnTrainerSpell(Player* player, Creature*, uint32 spellId) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
            AscensionClassService::Instance().AffectsTalentReplacements(spellId))
            AscensionClassService::Instance().SynchronizeTalentReplacements(player);
    }

  void OnPlayerForgotSpell(Player *player, uint32 spellId) override {
    if (spellId == 537218)
      RemoveAscensionPrimalistWeapons(player);
    if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) && spellId == 712325)
      AscensionClassService::ReconcileRunemasterFists(player,
          AscensionClassService::Instance().GetActiveSpecialization(player));

    if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
        (spellId == 712325 || spellId == 712389 || spellId == 521211))
      SynchronizeAscensionRunemasterEchoes(player,
          AscensionClassService::Instance().GetActiveSpecialization(player));

    if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
        AscensionClassService::Instance().AffectsTaughtAbilities(spellId))
      AscensionClassService::Instance().SynchronizeTaughtAbilities(player);

    if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
        AscensionClassService::Instance().AffectsTalentReplacements(spellId))
    {
      player->SetTemporarySpellReplacement(spellId, 0);
      AscensionClassService::Instance().SynchronizeTalentReplacements(player);
    }

    if (ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED) &&
        AscensionClassService::Instance().AffectsProficiencies(spellId))
      AscensionClassService::Instance().SynchronizeProficiencies(player);
  }

    void OnPlayerAfterSpecSlotChanged(Player* player, uint8) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
        {
            AscensionClassService::ReconcileRunemasterFists(player,
                AscensionClassService::Instance().GetActiveSpecialization(player));
            AscensionClassService::Instance().SynchronizeTaughtAbilities(player);
            AscensionClassService::Instance().SynchronizeTalentReplacements(player);
            RemoveAscensionPrimalistWeapons(player);
        }
    }

  void OnPlayerDelete(ObjectGuid guid, uint32) override {
    CharacterDatabase.Execute("DELETE FROM `character_appearance_outfit` WHERE `guid` = {}", guid.GetCounter());
  }

  void OnPlayerLogout(Player *player) override {
    {
      std::lock_guard<std::mutex> lock(_pendingEquipmentLock);
      _pendingEquipment.erase(player->GetGUID());
    }
    AscensionClassService::Instance().OnPlayerLogout(player);
    AscensionResourceService::Instance().OnPlayerLogout(player);
    AscensionCollectionService::Instance().OnPlayerLogout(player);
    AscensionDisplayPatchService::Instance().OnPlayerLogout(player);
  }

  void OnPlayerUpdate(Player *player, uint32 diff) override {
    if (ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED)) {
      AscensionClassService::Instance().ProcessTalentRequests(player);
      AscensionClassService::Instance().UpdateClassTuning(player, diff);
      AscensionResourceService::Instance().OnPlayerUpdate(player, diff);
      AscensionCollectionService::Instance().OnPlayerUpdate(player, diff);
      AscensionDisplayPatchService::Instance().OnPlayerUpdate(player, diff);
      EquipNewItems(player);
      if (sAscensionPresets->GetActivePresetOverride(player->GetGUID()))
      {
        if (!player->HasUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE))
          player->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      }
    }
  }

  void OnPlayerAfterSetVisibleItemSlot(Player *player, uint8 slot,
                                       Item *item) override {
    AscensionCollectionService::Instance().OnVisibleItemSet(player, slot, item);
    if (player->IsInWorld() && ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
      SendAverageItemLevel(player, item ? EQUIPMENT_SLOT_END : slot);
  }

  void OnPlayerEquip(Player *player, Item *item, uint8, uint8,
                     bool) override {
    AscensionCollectionService::Instance().OnItemObtained(player, item);
  }

  bool OnPlayerCanCastItemUseSpell(Player *player, Item *item, SpellCastTargets const &, uint8, uint32) override {
    AscensionCollectionService::Instance().OnItemObtained(player, item);
    return true;
  }

    void OnPlayerCompleteQuest(Player* player, Quest const* quest) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
            AscensionCollectionService::Instance().OnQuestRewarded(player, quest);
    }

    void OnPlayerTakeMailItem(Player* player, Mail const*, uint32 itemEntry) override
    {
        AscensionCollectionService::Instance().OnMailItemObtained(player, itemEntry);
    }

  void OnPlayerStoreNewItem(Player *player, Item *item,
                            uint32) override {
    AscensionCollectionService::Instance().OnItemObtained(player, item);
    SendObtainedItemPatchRow(player, item);
    if (item && player->IsInWorld() &&
        ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
    {
        std::lock_guard<std::mutex> lock(_pendingEquipmentLock);
        _pendingEquipment[player->GetGUID()].push_back(item->GetGUID());
    }
  }

  void OnPlayerCreateItem(Player *player, Item *item,
                           uint32) override {
    AscensionCollectionService::Instance().OnItemObtained(player, item);
    SendObtainedItemPatchRow(player, item);
  }

  static void SendObtainedItemPatchRow(Player *player, Item const *item) {
    if (item && player->IsInWorld() &&
        ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
      AscensionDisplayPatchService::Instance().SendItemRowOnDemand(player, item->GetEntry());
  }

  Optional<bool> OnPlayerIsClass(Player const *player, Classes playerClass,
                                 ClassContext context) override {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED))
      return std::nullopt;

    Classes actualClass = Classes(player->getClass());
    if (actualClass == playerClass)
      return true;

    if (actualClass < CLASS_BARBARIAN || actualClass > CLASS_SPIRIT_MAGE)
      return std::nullopt;

    if (context == CLASS_CONTEXT_PET && playerClass == CLASS_HUNTER &&
        HasAscensionPrimalistHunterPetContext(player))
      return true;

    switch (context) {
    case CLASS_CONTEXT_STATS:
    case CLASS_CONTEXT_SKILL:
    case CLASS_CONTEXT_EQUIP_RELIC:
    case CLASS_CONTEXT_EQUIP_SHIELDS:
    case CLASS_CONTEXT_EQUIP_ARMOR_CLASS:
    case CLASS_CONTEXT_WEAPON_SWAP:
      return GetLegacyClassForCustomClass(actualClass) == playerClass;
    default:
      return std::nullopt;
    }
  }
};

class AscensionCompatAllSpellScript : public AllSpellScript
{
public:
    AscensionCompatAllSpellScript()
        : AllSpellScript("AscensionCompatAllSpellScript",
              {ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_CAN_PREPARE,
                  ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_BEFORE_EFFECTS,
                  ALLSPELLHOOK_ON_CALCULATED_TARGET,
                  ALLSPELLHOOK_ON_HIT_RESULT,
                  ALLSPELLHOOK_ON_SUCCESSFUL_INTERRUPT})
    {
    }

    void OnSpellCheckCast(Spell* spell, bool,
        SpellCastResult& result) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(
                AscensionCompatConfig::ENABLED))
            AscensionResourceService::Instance().CheckCast(spell, result);
    }

    [[nodiscard]] bool CanPrepare(Spell* spell,
        SpellCastTargets const*,
        AuraEffect const*) override
    {
        if (!ascensionCompatConfig.GetConfigValue<bool>(
                AscensionCompatConfig::ENABLED))
            return true;

        return CanPrepareAscensionClassMechanics19To25(spell) &&
            AscensionResourceService::Instance().CanPrepare(spell);
    }

    void OnSpellCast(Spell* spell, Unit*,
        SpellInfo const*, bool) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(
                AscensionCompatConfig::ENABLED))
        {
            AscensionResourceService::Instance().OnSpellCast(spell);
            HandleAscensionClassMechanicsCast(spell);
        }
    }

    void OnSpellBeforeEffects(Spell* spell, Unit*,
        SpellInfo const*) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(
                AscensionCompatConfig::ENABLED))
        {
            PrepareAscensionClassMechanicsCast(spell);
            PrepareAscensionBarbarianScaling(spell);
        }
    }

    void OnSpellCalculatedTarget(Spell* spell, Unit* target,
        TargetInfo& targetInfo) override
    {
        if (!ascensionCompatConfig.GetConfigValue<bool>(
                AscensionCompatConfig::ENABLED) || !spell)
            return;

        if (Player* player = spell->GetCaster()->ToPlayer())
            HandleAscensionClassMechanicsCalculatedTarget(spell, player, target,
                targetInfo);
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 missInfo,
        uint32 damage, uint32 healing, bool critical) override
    {
        if (!ascensionCompatConfig.GetConfigValue<bool>(
                AscensionCompatConfig::ENABLED) || !spell)
            return;

        if (Player* player = spell->GetCaster()->ToPlayer())
        {
            AscensionResourceService::Instance().OnSpellHitResult(spell,
                target, missInfo, damage, critical);
            HandleAscensionClassMechanicsHit(spell, player, target, missInfo,
                damage, healing, critical);
            HandleAscensionReaperSoulStrikeHit(spell, player, target, missInfo);
            HandleAscensionReaperPainmailHit(spell, player, target, missInfo, damage);
        }
    }

    void OnSpellSuccessfulInterrupt(Spell* spell, Unit*) override
    {
        if (!ascensionCompatConfig.GetConfigValue<bool>(
                AscensionCompatConfig::ENABLED) || !spell)
            return;

        if (Player* player = spell->GetCaster()->ToPlayer())
            HandleAscensionClassMechanics26To32SuccessfulInterrupt(spell,
                player);
    }
};

class AscensionCompatUnitScript : public UnitScript {
public:
  AscensionCompatUnitScript()
      : UnitScript("AscensionCompatUnitScript", true,
            {UNITHOOK_ON_BLOCK,
             UNITHOOK_ON_PERIODIC_DAMAGE_RESULT,
             UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE,
             UNITHOOK_ON_SEND_AURA_UPDATE}) {}

    void OnSendAuraUpdate(Unit* target, Player* receiver,
        AuraApplication const* application, bool remove) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
            SendAscensionAuraAmounts(target, receiver, application, remove);
    }

  void OnBlock(Unit *victim, Unit *) override {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED) ||
        !victim || !victim->IsPlayer())
      return;

    Player* player = victim->ToPlayer();
    AscensionResourceService::Instance().OnBlock(player);
    HandleAscensionClassMechanicsBlock(player);
  }

  void OnPeriodicDamageResult(Unit* target, Unit* attacker,
      uint32 damage, SpellInfo const* spellInfo) override {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED))
      return;

    AscensionResourceService::Instance().OnPeriodicDamageTick(target,
        attacker, damage, spellInfo);
  }

  void OnAuraApply(Unit* unit, Aura* aura) override {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED) ||
        !unit || !unit->IsPlayer() || !aura)
      return;

    HandleAscensionClassMechanicsAuraApply(unit->ToPlayer(), aura->GetId());
  }

  void OnAuraRemove(Unit* unit, AuraApplication* aurApp,
                    AuraRemoveMode mode) override {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED) ||
        !unit || !unit->IsPlayer() || !aurApp || !aurApp->GetBase())
      return;

    HandleAscensionClassMechanicsAuraRemove(unit->ToPlayer(),
        aurApp->GetBase()->GetId(), mode == AURA_REMOVE_BY_DEATH);
    if (mode == AURA_REMOVE_BY_CANCEL)
      AscensionCollectionService::Instance().OnCosmeticCancelled(
          unit->ToPlayer(), aurApp->GetBase()->GetId());
  }
};

static bool IsAdventureModeTierAura(uint32 spellId)
{
    return spellId == 302053 || (spellId >= 302059 && spellId <= 302068 && (spellId - 302059) % 3 == 0) ||
        (spellId >= 302600 && spellId <= 302882 && (spellId - 302600) % 3 == 0);
}

static bool IsAdventureModeMagicDifficultyAura(uint32 spellId)
{
    return spellId > 302055 && IsAdventureModeTierAura(spellId - 2);
}

static void ApplyAdventureModeDifficultyContracts(SpellInfo* info)
{
    if (!info || !IsAdventureModeMagicDifficultyAura(info->Id))
        return;

    for (SpellEffectInfo& effect : info->Effects)
        if (effect.ApplyAuraName == SPELL_AURA_MOD_HEALING_DONE)
            effect.ApplyAuraName = SPELL_AURA_MOD_HEALING_DONE_PERCENT;
}

void ApplyAscensionExperienceContracts(SpellInfo* info)
{
    if (!info)
        return;

    if (IsAdventureModeTierAura(info->Id))
    {
        uint32 const creatureKills = 1;
        uint32 const quests = 2;
        for (SpellEffectInfo& effect : info->Effects)
            if (effect.ApplyAuraName == SPELL_AURA_MOD_XP_PCT && (effect.MiscValue & quests) &&
                !(effect.MiscValue & creatureKills))
                effect.ApplyAuraName = SPELL_AURA_MOD_XP_QUEST_PCT;
        return;
    }

    switch (info->Id)
    {
        case 57353:
        case 71354:
        case 157353:
        case 818046:
        case 819046:
        case 993943:
            for (SpellEffectInfo& effect : info->Effects)
                if (effect.ApplyAuraName == SPELL_AURA_MOD_XP_PCT &&
                    (effect.MiscValue == 2 || effect.MiscValue == 8))
                    effect.ApplyAuraName = SPELL_AURA_MOD_XP_QUEST_PCT;
            break;
        case 818059:
        {
            SpellEffectInfo& kills = info->Effects[EFFECT_1];
            SpellEffectInfo& quests = info->Effects[EFFECT_2];
            if (kills.Effect != SPELL_EFFECT_APPLY_AREA_AURA_PARTY ||
                kills.ApplyAuraName != SPELL_AURA_MOD_XP_PCT || kills.MiscValue != 63 || quests.Effect)
                break;
            kills.BasePoints = 49;
            kills.DieSides = 1;
            quests.Effect = kills.Effect;
            quests.ApplyAuraName = SPELL_AURA_MOD_XP_QUEST_PCT;
            quests.BasePoints = kills.BasePoints;
            quests.DieSides = kills.DieSides;
            quests.TargetA = kills.TargetA;
            quests.TargetB = kills.TargetB;
            quests.RadiusEntry = kills.RadiusEntry;
            break;
        }
        default:
            break;
    }
}

class AscensionCompatChangelogScript : public GlobalScript
{
public:
    AscensionCompatChangelogScript()
        : GlobalScript("AscensionCompatChangelogScript", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* spellInfo) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
        {
            ApplyAscensionChangelogSpellChanges(spellInfo);
            ApplyAscensionExperienceContracts(spellInfo);
            ApplyAdventureModeDifficultyContracts(spellInfo);
            AscensionClassTuning::DisablePvpHealingTuning(spellInfo);
            switch (spellInfo->Id)
            {
                case 19743:
                case 19782:
                    if (spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_APPLY_AURA &&
                        spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_MOD_STAT &&
                        spellInfo->Effects[EFFECT_0].MiscValue == STAT_SPIRIT)
                        spellInfo->Effects[EFFECT_0].MiscValue = STAT_STAMINA;
                    break;
                case 83328: case 83329: case 83330: case 83331: case 83332:
                case 83334: case 83335: case 83336: case 103921:
                    if (spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_APPLY_AURA &&
                        spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_NONE)
                        spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
                    break;
                case 91616: case 91617: case 91618: case 91619:
                    if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_MOUNTED &&
                        spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_MOD_INCREASE_MOUNTED_SPEED &&
                        spellInfo->Effects[EFFECT_2].Effect == SPELL_EFFECT_APPLY_AURA &&
                        spellInfo->Effects[EFFECT_2].ApplyAuraName == SPELL_AURA_MOD_INCREASE_MOUNTED_FLIGHT_SPEED &&
                        !spellInfo->HasAttribute(SPELL_ATTR4_ONLY_FLYING_AREAS))
                    {
                        spellInfo->Effects[EFFECT_2].Effect = 0;
                        spellInfo->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_NONE;
                        spellInfo->Effects[EFFECT_2].BasePoints = 0;
                    }
                    break;
                default:
                    break;
            }
            ApplyAscensionClassMechanics(spellInfo);
            ApplyAscensionStockScriptShapes(spellInfo);
            ApplyAscensionPathPassiveContract(spellInfo);
            ApplyAscensionPrimalistEarthquakeContract(spellInfo);
            ApplyAscensionPrimalistEarthshapingContracts(spellInfo);
            ApplyAscensionPrimalistSpiritBeastContract(spellInfo);
            ApplyAscensionPrimalistWeaponsContract(spellInfo);
            ApplyAscensionRunemasterTalentContracts(spellInfo);
            ApplyAscensionManuscriptionContracts(spellInfo);
            ApplyAscensionRunemasterTravelContracts(spellInfo);
            ApplyAscensionRangerTalentContracts(spellInfo);
            ApplyAscensionChronomancerTalentContracts(spellInfo);
            ApplyAscensionVenomancerCatalystContract(spellInfo);
            ApplyAscensionReaperDeathwindContracts(spellInfo);
            ApplyAscensionReaperScytheRushContracts(spellInfo);
            ApplyAscensionBloodmageHemoglobeContract(spellInfo);
        }
    }
};

class AscensionCompatWorldScript : public WorldScript {
public:
  AscensionCompatWorldScript()
      : WorldScript("AscensionCompatWorldScript",
                    {WORLDHOOK_ON_BEFORE_CONFIG_LOAD, WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP,
                     WORLDHOOK_ON_LOAD_CUSTOM_DATABASE_TABLE, WORLDHOOK_ON_UPDATE}) {}

  void OnUpdate(uint32) override
  {
    AscensionCollectionService::Instance().ProcessOutfitCallbacks();
  }

  void OnBeforeConfigLoad(bool reload) override {
    ascensionCompatConfig.Initialize(reload);
    bool enabled = ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED);
    LocalLevelScaling::QuestEnabled.store(enabled && ascensionCompatConfig.GetConfigValue<bool>(
        AscensionCompatConfig::QUEST_LEVEL_SCALING), std::memory_order_relaxed);
  }

  void OnAfterConfigLoad(bool reload) override {
    ReportRenamedConfiguration();
    if (!reload || !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
      return;

    for (auto const& [accountId, session] : sWorldSessionMgr->GetAllSessions())
      if (session && session->GetPlayer() && session->GetPlayer()->IsInWorld())
        SendAscensionCoAConfig(session);
  }

  void OnLoadCustomDatabaseTable() override {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED))
      return;

    sAscensionPresets->LoadFromDB();
  }

  void OnStartup() override {
    ReportLegacyItemTemplateTable();
    AscensionCompatData::LoadCoATalentData();
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED))
      return;

    uint32 firstOpcode = ascensionCompatConfig.GetConfigValue<uint32>(
        AscensionCompatConfig::FIRST_EXTENSION_OPCODE);
    uint32 lastOpcode = ascensionCompatConfig.GetConfigValue<uint32>(
        AscensionCompatConfig::LAST_EXTENSION_OPCODE);
    bool dataLoaded =
        AscensionCollectionService::Instance().LoadClientData();
    AscensionDisplayPatchService::Instance().Initialize();
    AscensionResourceService::Instance().ValidateDefinitions();
    LOG_INFO("coa",
             "Ascension compatibility enabled; consuming extension opcodes "
             "0x{:04X}-0x{:04X}; collection data {}",
             firstOpcode, lastOpcode, dataLoaded ? "ready" : "unavailable");
  }

private:
  static char** EnvironmentVariables() {
#ifdef _WIN32
    return _environ;
#else
    return environ;
#endif
  }

  static void ReportRenamedConfiguration() {
    std::filesystem::path const modules = std::filesystem::path(sConfigMgr->GetConfigPath()) / "modules";
    std::error_code error;
    if (std::filesystem::exists(modules / "mod_ascension_compat.conf", error))
      LOG_ERROR("coa", "{} is no longer read: move its settings into coa.conf as CoA.* keys, then delete it",
                (modules / "mod_ascension_compat.conf").generic_string());
    if (std::filesystem::exists(modules / "mod_ascension_compat.conf.dist", error))
      LOG_ERROR("coa", "{} is obsolete: delete it, or acore.sh copies it back to mod_ascension_compat.conf",
                (modules / "mod_ascension_compat.conf.dist").generic_string());

    constexpr std::string_view legacyPrefix = "AscensionCompat.";
    for (std::string const& key : sConfigMgr->GetKeysByString(std::string(legacyPrefix)))
      LOG_ERROR("coa", "Config key {} is no longer read: rename it to CoA.{}", key, key.substr(legacyPrefix.size()));

    constexpr std::string_view legacyEnvironmentPrefix = "AC_ASCENSION_COMPAT_";
    for (char** entry = EnvironmentVariables(); entry && *entry; ++entry) {
      std::string_view const variable(*entry);
      if (!variable.starts_with(legacyEnvironmentPrefix))
        continue;
      std::string_view const name = variable.substr(0, variable.find('='));
      LOG_ERROR("coa", "Environment variable {} is no longer read: rename it to AC_CO_A_{}", name,
                name.substr(legacyEnvironmentPrefix.size()));
    }

    constexpr std::array<std::pair<std::string_view, std::string_view>, 3> legacyLoggers = {{
        {"Logger.module.ascension_compat", "Logger.coa"},
        {"Logger.module.gameplay_test", "Logger.coa.gameplay_test"},
        {"Logger.module.highrisk", "Logger.coa.highrisk"}}};
    for (auto const& [legacy, current] : legacyLoggers)
      if (!sConfigMgr->GetKeysByString(std::string(legacy)).empty())
        LOG_ERROR("coa", "{} is no longer used: rename it to {}", legacy, current);
    if (sConfigMgr->GetKeysByString("Logger.coa").empty() && !sConfigMgr->GetKeysByString("Logger.module").empty())
      LOG_ERROR("coa", "worldserver.conf has no Logger.coa line, so CoA logs only errors: "
                "add Logger.coa=4,Console Server");
  }

  static void ReportLegacyItemTemplateTable() {
    auto tableExists = [](std::string_view table) {
      return WorldDatabase.Query("SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() "
                                 "AND TABLE_NAME = '{}'", table) != nullptr;
    };
    if (!tableExists("item_template_ascension_compat"))
      return;
    if (tableExists("item_template_coa"))
      LOG_ERROR("coa", "World table item_template_ascension_compat exists again next to item_template_coa, as "
                "happens when its creating migration is re-applied: run INSERT IGNORE INTO item_template_coa "
                "SELECT * FROM item_template_ascension_compat, then DROP TABLE item_template_ascension_compat");
    else
      LOG_ERROR("coa", "World table item_template_ascension_compat has not been renamed: apply the pending "
                "world update rev_20260923_00_coa_item_template_table.sql");
  }
};

struct ScrollProfession
{
    uint32 skillId;
    char const* name;
};

constexpr ScrollProfession kProfessions[] = {
    { 171, "Alchemy" },        { 164, "Blacksmithing" }, { 333, "Enchanting" },
    { 202, "Engineering" },    { 773, "Inscription" },   { 755, "Jewelcrafting" },
    { 165, "Leatherworking" }, { 197, "Tailoring" },
    { 182, "Herbalism" },      { 186, "Mining" },        { 393, "Skinning" },
    { 185, "Cooking" },        { 129, "First Aid" },     { 356, "Fishing" },
    { 633, "Lockpicking" },    { 732, "Woodcutting" },   { 757, "Woodworking" },
};

constexpr uint32 kGossipTextId = 1;
constexpr uint32 kSenderScroll = 0xA5C0;

enum StoreTitleContract : uint32
{
    ITEM_BLOODFORGED_CONTRACT = 977220,
    ITEM_FOUNDERS_CHARTER = 134988,
    TITLE_THE_BLOODY = 230,
    TITLE_FOUNDER = 210
};

class item_coa_title_contract : public AllItemScript
{
public:
    item_coa_title_contract() : AllItemScript("item_coa_title_contract") { }

    bool CanItemUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (!player || !item)
            return false;

        uint32 titleId = 0;
        switch (item->GetEntry())
        {
            case ITEM_BLOODFORGED_CONTRACT:
                titleId = TITLE_THE_BLOODY;
                break;
            case ITEM_FOUNDERS_CHARTER:
                titleId = TITLE_FOUNDER;
                break;
            default:
                return false;
        }

        if (CharTitlesEntry const* title = sCharTitlesStore.LookupEntry(titleId))
            player->SetTitle(title);
        return false;
    }
};

class AscensionTradesmanScroll : public ItemScript
{
public:
    AscensionTradesmanScroll() : ItemScript("ascension_tradesman_scroll") { }

    static std::vector<uint32> MissingRankSpells(Player const* player, uint32 skillId)
    {
        uint16 const currentStep = player->GetSkillStep(skillId);
        uint16 const maxStep = GetMaxProfessionSkillStep(player->GetSession()->Expansion());
        std::vector<uint32> missing;
        for (uint32 rankSpell : sSpellMgr->GetSkillRankSpells(skillId))
        {
            uint16 const step = sSpellMgr->GetSpellLearnSkill(rankSpell)->step;
            if (step > currentStep && step <= maxStep && !player->HasSpell(rankSpell))
                missing.push_back(rankSpell);
        }
        return missing;
    }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (!player || !item)
            return false;

        ClearGossipMenuFor(player);
        for (uint32 i = 0; i < std::extent<decltype(kProfessions)>::value; ++i)
        {
            ScrollProfession const& prof = kProfessions[i];
            std::string label = prof.name;
            if (!player->HasSkill(prof.skillId))
                label += " (not learned)";
            else if (MissingRankSpells(player, prof.skillId).empty() &&
                     player->GetSkillValue(prof.skillId) >= player->GetPureMaxSkillValue(prof.skillId))
                label += " (already maxed)";

            AddGossipItemFor(player, GOSSIP_ICON_TRAINER, label, kSenderScroll, i);
        }

        SendGossipMenuFor(player, kGossipTextId, item->GetGUID());
        return true;
    }

    void OnGossipSelect(Player* player, Item* item, uint32 sender, uint32 action) override
    {
        if (!player || !item || sender != kSenderScroll)
            return;

        CloseGossipMenuFor(player);

        if (action >= std::extent<decltype(kProfessions)>::value)
            return;

        ScrollProfession const& prof = kProfessions[action];

        if (!player->HasSkill(prof.skillId))
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "You must learn {} before the scroll can raise it.", prof.name);
            return;
        }

        for (uint32 rankSpell : MissingRankSpells(player, prof.skillId))
            player->learnSpell(rankSpell);

        uint16 const cap = player->GetPureMaxSkillValue(prof.skillId);
        if (!cap)
            return;

        if (player->GetSkillValue(prof.skillId) >= cap)
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "Your {} is already at its maximum of {}.", prof.name, cap);
            return;
        }

        player->SetSkill(prof.skillId, player->GetSkillStep(prof.skillId), cap, cap);
        ChatHandler(player->GetSession()).PSendSysMessage(
            "{} raised to {}.", prof.name, cap);

        LOG_DEBUG("coa",
                  "Tradesman's Scroll: player {} set {} to {}",
                  player->GetName(), prof.name, cap);

        player->DestroyItemCount(item->GetEntry(), 1, true);
    }
};

class spell_ascension_legacy_quest_reward : public SpellScript
{
    PrepareSpellScript(spell_ascension_legacy_quest_reward);

    bool Validate(SpellInfo const* info) override
    {
        LegacyQuestReward const* reward = GetLegacyQuestReward(info->Id);
        if (!reward)
            return false;

        for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
            if (reward->Spells[index] && (info->Effects[index].Effect != SPELL_EFFECT_LEARN_SPELL ||
                info->Effects[index].TriggerSpell != reward->Spells[index]))
                return false;
        return true;
    }

    bool Load() override
    {
        return ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED);
    }

    void HandleLearn(SpellEffIndex effect)
    {
        LegacyQuestReward const* reward = GetLegacyQuestReward(GetSpellInfo()->Id);
        if (!reward || !reward->Spells[effect])
            return;

        if (Player* player = GetHitPlayer())
            if (IsAscensionCustomClass(player))
                PreventHitDefaultEffect(effect);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_legacy_quest_reward::HandleLearn,
            EFFECT_ALL, SPELL_EFFECT_LEARN_SPELL);
    }
};

class spell_ascension_jailers_bargain : public AuraScript
{
    PrepareAuraScript(spell_ascension_jailers_bargain);

    static constexpr uint8 AbsorbPercent = 30;

    bool Load() override
    {
        return ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
            GetUnitOwner() && GetUnitOwner()->IsPlayer();
    }

    void CalculateAmount(AuraEffect const*, int32& amount, bool& canBeRecalculated)
    {
        if (Unit* owner = GetUnitOwner())
            amount = int32(owner->GetMaxHealth() * AbsorbPercent / 100);

        canBeRecalculated = false;
    }

    void ApplySleepImmunity(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_SLEEP, true);
    }

    void RemoveSleepImmunity(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_SLEEP, false);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_jailers_bargain::CalculateAmount,
            EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        AfterEffectApply += AuraEffectApplyFn(spell_ascension_jailers_bargain::ApplySleepImmunity,
            EFFECT_2, SPELL_AURA_MECHANIC_IMMUNITY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_jailers_bargain::RemoveSleepImmunity,
            EFFECT_2, SPELL_AURA_MECHANIC_IMMUNITY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_reaper_extinction : public AuraScript
{
    PrepareAuraScript(spell_ascension_reaper_extinction);

    static constexpr uint32 BaseChance = 5;
    static constexpr uint32 ChancePerSoul = 10;

    bool Load() override
    {
        return ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
            GetUnitOwner() && GetUnitOwner()->IsPlayer();
    }

    bool CheckProc(ProcEventInfo&)
    {
        Unit* owner = GetUnitOwner();
        if (!owner)
            return false;

        uint32 souls = 0;
        if (Aura* reapedSouls = owner->GetAura(SPELL_REAPER_REAPED_SOUL))
            souls = reapedSouls->GetStackAmount();

        return roll_chance_i(int32(BaseChance + ChancePerSoul * souls));
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reaper_extinction::CheckProc);
    }
};

class spell_ascension_reaper_extinction_buff : public AuraScript
{
    PrepareAuraScript(spell_ascension_reaper_extinction_buff);

    static constexpr std::array<uint32, 7> SlaughterRanks =
        {{500373, 500429, 500430, 500431, 500432, 500433, 500434}};

    bool Load() override
    {
        return ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        return spellInfo && std::find(SlaughterRanks.begin(), SlaughterRanks.end(), spellInfo->Id) !=
            SlaughterRanks.end();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reaper_extinction_buff::CheckProc);
    }
};

class spell_ascension_reaper_ruin : public AuraScript
{
    PrepareAuraScript(spell_ascension_reaper_ruin);

    static constexpr std::array<uint32, 13> RuinTriggers =
        {{572382, 578261, 578262, 801322, 805708,
          500376, 502679, 502680, 502681, 502682, 502683, 502684, 504622}};

    bool Load() override
    {
        return ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        return spellInfo && std::find(RuinTriggers.begin(), RuinTriggers.end(), spellInfo->Id) !=
            RuinTriggers.end();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reaper_ruin::CheckProc);
    }
};

class spell_ascension_reaper_redshade : public AuraScript
{
    PrepareAuraScript(spell_ascension_reaper_redshade);

    static constexpr std::array<uint32, 10> Reap =
        {{354319, 500357, 504056, 504057, 504058, 504557, 505151, 573302, 573303, 801327}};

    bool Load() override
    {
        return ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        return spellInfo && std::find(Reap.begin(), Reap.end(), spellInfo->Id) != Reap.end();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reaper_redshade::CheckProc);
    }
};

class spell_ascension_specialization_slot : public SpellScript
{
    PrepareSpellScript(spell_ascension_specialization_slot);

    uint32 _slot = 0;

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        auto const& spells = AscensionWildcard::SPECIALIZATION_SWAP_SPELLS;
        auto const found = std::find(spells.begin(), spells.end(), GetSpellInfo()->Id);
        if (!player || !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) ||
            !IsAscensionCustomClass(player) || AscensionWildcard::IsWildcardHero(player) || found == spells.end())
            return false;
        _slot = uint32(found - spells.begin());
        return true;
    }

    SpellCastResult CheckSlot()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player->HasSpell(AscensionWildcard::SPECIALIZATION_SWAP_SPELLS[_slot]))
            return SPELL_FAILED_NOT_KNOWN;
        if (player->IsInCombat())
            return SPELL_FAILED_AFFECTING_COMBAT;
        return SPELL_CAST_OK;
    }

    void SwitchSlot(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        std::string error;
        if (!AscensionClassService::Instance().SwitchSlot(player, _slot, error))
        {
            ChatHandler(player->GetSession()).SendSysMessage(error);
            AscensionClassService::Instance().SendActiveSlot(player);
        }
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_specialization_slot::CheckSlot);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_specialization_slot::SwitchSlot, EFFECT_0,
            SPELL_EFFECT_TALENT_SPEC_SELECT);
    }
};

class spell_ascension_local_mount : public SpellScript
{
    PrepareSpellScript(spell_ascension_local_mount);

    AscensionCollectibles::MountWrapper const* _mount = nullptr;

    bool Validate(SpellInfo const* spellInfo) override
    {
        auto const& entries = AscensionCollectibles::MountWrappers;
        auto itr = std::lower_bound(entries.begin(), entries.end(), spellInfo->Id,
            [](AscensionCollectibles::MountWrapper const& entry, uint32 id)
            {
                return entry.SpellId < id;
            });
        if (itr == entries.end() || itr->SpellId != spellInfo->Id)
            return false;

        _mount = &*itr;
        for (uint32 spellId : {_mount->Ground60, _mount->Ground100, _mount->Flying150,
            _mount->Flying280, _mount->Flying310})
            if (spellId && !sSpellMgr->GetSpellInfo(spellId))
                return false;

        return true;
    }

    bool Load() override
    {
        return ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
            GetCaster()->IsPlayer() && Validate(GetSpellInfo());
    }

    void HandleMount(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Player* player = GetHitPlayer();
        if (!player || !_mount)
            return;

        uint16 riding = player->GetBaseSkillValue(SKILL_RIDING);
        if (riding < 75)
        {
            PreventHitAura();
            return;
        }
        uint32 selected = riding >= 150 ? _mount->Ground100 : _mount->Ground60;
        uint32 map = GetVirtualMapForMapAndZone(player->GetMapId(), player->GetZoneId());
        bool canFly = map == MAP_OUTLAND || (map == MAP_NORTHREND && player->HasSpell(SPELL_COLD_WEATHER_FLYING));
        AreaTableEntry const* area = sAreaTableStore.LookupEntry(player->GetAreaId());
        Battlefield* battlefield = sBattlefieldMgr->GetBattlefieldToZoneId(player->GetZoneId());
        if ((area && (area->flags & AREA_FLAG_NO_FLY_ZONE)) || (battlefield && !battlefield->CanFlyIn()) ||
            player->InBattleground())
            canFly = false;

        if (canFly && riding >= 225)
        {
            uint32 flying = riding >= 300 ? (_mount->Flying310 ? _mount->Flying310 : _mount->Flying280) :
                _mount->Flying150;
            if (!flying)
                flying = _mount->Flying150;
            SpellInfo const* spell = flying ? sSpellMgr->GetSpellInfo(flying) : nullptr;
            if (spell && spell->CheckLocation(player->GetMapId(), player->GetZoneId(),
                player->GetAreaId(), player) == SPELL_CAST_OK &&
                player->canFlyInZone(player->GetMapId(), player->GetZoneId(), spell))
                selected = flying;
        }

        if (!selected)
            return;

        uint32 petNumber = player->GetTemporaryUnsummonedPetNumber();
        player->SetTemporaryUnsummonedPetNumber(0);
        player->RemoveAurasByType(SPELL_AURA_MOUNTED, ObjectGuid::Empty, GetHitAura());
        PreventHitAura();
        player->CastSpell(player, selected, true);
        if (petNumber)
            player->SetTemporaryUnsummonedPetNumber(petNumber);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_local_mount::HandleMount, EFFECT_2, SPELL_EFFECT_SCRIPT_EFFECT);
    }
};

class spell_ascension_wildcard_mount : public SpellScript
{
    PrepareSpellScript(spell_ascension_wildcard_mount);

    bool Load() override
    {
        return ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
            GetCaster()->IsPlayer();
    }

    void HandleDummy(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Player* player = GetHitPlayer();
        if (!player)
            return;

        std::vector<uint32> known;
        for (AscensionCollectibles::MountWrapper const& entry : AscensionCollectibles::MountWrappers)
            if (player->HasSpell(entry.SpellId))
                known.push_back(entry.SpellId);

        if (known.empty())
            return;

        player->CastSpell(player, known[urand(0, uint32(known.size()) - 1)], true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_wildcard_mount::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class npc_ascension_training_book : public CreatureScript
{
public:
    npc_ascension_training_book() : CreatureScript("npc_ascension_training_book") { }

    enum BookGossip : uint32
    {
        TextTraining = 900370,
        ActionRestoreAbilities = GOSSIP_ACTION_INFO_DEF + 1
    };

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
            IsAscensionCustomClass(player))
            AddGossipItemFor(player, GOSSIP_ICON_TRAINER, "Restore my available class abilities.",
                GOSSIP_SENDER_MAIN, ActionRestoreAbilities);
        SendGossipMenuFor(player, TextTraining, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature*, uint32 sender, uint32 action) override
    {
        ClearGossipMenuFor(player);
        CloseGossipMenuFor(player);
        if (sender != GOSSIP_SENDER_MAIN || action != ActionRestoreAbilities ||
            !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) ||
            !IsAscensionCustomClass(player))
            return true;

        if (!AscensionClassService::Instance().SynchronizeProgression(player, true))
            ChatHandler(player->GetSession()).SendSysMessage("Your available class abilities are already up to date.");
        return true;
    }
};

class spell_ascension_experience_potion : public SpellScript
{
    PrepareSpellScript(spell_ascension_experience_potion);

    int32 _remaining = 0;

    bool Load() override
    {
        return ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) && GetCaster()->IsPlayer();
    }

    void SnapshotDuration(SpellMissInfo missInfo)
    {
        _remaining = 0;
        if (missInfo == SPELL_MISS_NONE)
            if (Unit* target = GetHitUnit())
                if (Aura* aura = target->GetAura(GetSpellInfo()->Id, GetCaster()->GetGUID()))
                    _remaining = std::max(0, aura->GetDuration());
    }

    void ExtendDuration()
    {
        if (_remaining > 0)
            if (Aura* aura = GetHitAura())
            {
                int32 const duration = int32(std::min<int64>(int64(aura->GetDuration()) + _remaining,
                    std::numeric_limits<int32>::max()));
                aura->SetMaxDuration(duration);
                aura->SetDuration(duration);
            }
    }

    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(spell_ascension_experience_potion::SnapshotDuration);
        AfterHit += SpellHitFn(spell_ascension_experience_potion::ExtendDuration);
    }
};

}

bool IsAscensionPrimalistTameEligible(Player const* player)
{
    return player && ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
        player->getClass() == CLASS_WILDWALKER && player->GetLevel() >= 10 && player->HasSpell(92148) &&
        AscensionClassService::Instance().GetActiveSpecialization(player) == 59;
}

bool IsAscensionPrimalistWeaponsEligible(Player const* player, bool allowUnconfirmed)
{
    return player && ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
        player->getClass() == CLASS_WILDWALKER && player->GetLevel() >= 20 && player->HasSpell(537218) &&
        (AscensionClassService::Instance().GetActiveSpecialization(player) == 59 ||
            (allowUnconfirmed && !AscensionClassService::Instance().GetActiveSpecialization(player)));
}

uint32 GetAscensionActiveSpecialization(Player const* player)
{
    if (!player || !IsAscensionCustomClass(player))
        return 0;

    if (uint32 const active = AscensionClassService::Instance().GetActiveSpecialization(player))
        return active;

    return const_cast<Player*>(player)->GetPlayerSetting(ASCENSION_ACTIVE_SPEC_SETTING, 0).value;
}

uint32 AscensionWitchHunter::GetShadowhoundDisplay(Player* player)
{
    return AscensionCollectionService::Instance().GetShadowhoundDisplay(player);
}

bool SwitchAscensionSpecialization(Player* player, uint32 specializationId)
{
    return player && ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
        AscensionClassService::Instance().SwitchSpecialization(player, specializationId);
}

void AddAscensionSpecializationSwitchGuard(AscensionSpecializationSwitchGuard guard)
{
    if (guard)
        SpecializationSwitchGuards().push_back(std::move(guard));
}

std::string AscensionSpecializationSwitchRefusal(Player* player, uint32 activeSpecializationId,
    uint32 requestedSpecializationId)
{
    return SpecializationSwitchRefusal(player, activeSpecializationId, requestedSpecializationId);
}

void ClearAscensionSpecializationSlots(Player* player)
{
    if (player)
        AscensionClassService::Instance().ClearSlots(player);
}

uint32 ForgetAscensionClassTalents(Player* player)
{
    if (!player || !IsAscensionCustomClass(player))
        return 0;

    uint32 removed = 0;
    for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
    {
        if (entry.ClassId != player->getClass())
            continue;

        for (uint32 spellId : entry.SpellIds)
            if (spellId && player->HasSpell(spellId))
            {
                player->removeSpell(spellId, SPEC_MASK_ALL, false);
                ++removed;
            }
    }

    for (uint32 const tree : { uint32(0), GetAscensionActiveSpecialization(player) })
        if (player->FindPlayerSettings(AscensionClassService::BuildSetting(player, tree)))
            AscensionClassService::StoreBuild(player, tree, {});
    return removed;
}

static AscensionCompatData::CoATalentEntry const* FindAscensionTalentEntry(uint32 entryId)
{
    auto const& entries = AscensionCompatData::CoATalentEntries;
    auto itr = std::lower_bound(entries.begin(), entries.end(), entryId,
        [](AscensionCompatData::CoATalentEntry const& entry, uint32 id) { return entry.EntryId < id; });
    return itr != entries.end() && itr->EntryId == entryId ? &*itr : nullptr;
}

uint32 GetAscensionTalentRank(Player const* player, uint32 entryId)
{
    AscensionCompatData::CoATalentEntry const* entry = FindAscensionTalentEntry(entryId);
    if (!player || !entry)
        return 0;

    return AscensionClassService::KnownRank(player, *entry);
}

bool RestoreAscensionSpecializationSignature(Player* player)
{
    if (!player || player->GetLevel() < 10 || !IsAscensionCustomClass(player) ||
        AscensionWildcard::IsWildcardHero(player))
        return false;

    uint32 const active = GetAscensionActiveSpecialization(player);
    auto const specialization = std::find_if(AscensionCompatData::CoASpecializations.begin(),
        AscensionCompatData::CoASpecializations.end(), [player, active](auto const& row)
        {
            return row.ClassId == player->getClass() && row.SpecId == active;
        });
    if (specialization == AscensionCompatData::CoASpecializations.end())
        return false;

    auto const* identity = FindAscensionTalentEntry(specialization->IdentityEntryId);
    if (!identity || !AscensionClassService::KnownRank(player, *identity))
        return false;

    auto const* signature = FindAscensionTalentEntry(specialization->SignatureEntryId);
    if (!signature)
        return false;
    if (AscensionClassService::KnownRank(player, *signature))
        return true;

    auto known = AscensionClassService::KnownTalentEntries(player);
    known.push_back({signature->EntryId, 1});
    UpdateEntriesRefusal refusal;
    auto& service = AscensionClassService::Instance();
    if (!service.ApplyKnownEntriesUpload(player, known, refusal, active))
        return false;

    service.SaveSlot(player);
    service.SendCharacterAdvancementKnownEntries(player);
    return true;
}

std::vector<AscensionCoATalentState::KnownEntry> GetAscensionKnownTalentEntries(Player const* player)
{
    return player ? AscensionClassService::KnownTalentEntries(player) :
        std::vector<AscensionCoATalentState::KnownEntry>{};
}

uint32 SynchronizeAscensionTalentReplacements(Player* player)
{
    return player ? AscensionClassService::Instance().SynchronizeTalentReplacements(player) : 0;
}

bool SetAscensionTalentRank(Player* player, uint32 entryId, uint32 rank)
{
    AscensionCompatData::CoATalentEntry const* entry = FindAscensionTalentEntry(entryId);
    if (!player || !entry || !IsAscensionCustomClass(player) || entry->ClassId != player->getClass() ||
        rank > entry->SpellCount)
        return false;

    uint32 const freeChoiceGroup = AscensionClassService::GetSelectableFreeGroup(entryId);
    if (entry->AECost == 0 && entry->TECost == 0 && !freeChoiceGroup)
        return false;

    if (rank > 0 && entry->SpecId != 0 && entry->SpecId != GetAscensionActiveSpecialization(player))
        return false;

    uint32 const selectedSpellId = rank > 0 ? entry->SpellIds[rank - 1] : 0;
    if (rank > 0 && (!selectedSpellId || !sSpellMgr->GetSpellInfo(selectedSpellId)))
        return false;

    if (rank > 0 && freeChoiceGroup)
        for (auto const& other : AscensionCompatData::CoATalentEntries)
            if (other.ClassId == player->getClass() && other.SpecId == entry->SpecId && other.EntryId != entryId &&
                AscensionClassService::GetSelectableFreeGroup(other.EntryId) == freeChoiceGroup)
                for (uint32 spellId : other.SpellIds)
                    if (spellId && player->HasSpell(spellId))
                        player->removeSpell(spellId, SPEC_MASK_ALL, false);

    AscensionClassService::SelectSharedEntryRank(player, *entry, rank);
    for (uint32 spellId : entry->SpellIds)
        if (spellId && player->HasSpell(spellId) &&
            !AscensionClassService::SharedSpellStillSelected(player, *entry, spellId))
            player->removeSpell(spellId, SPEC_MASK_ALL, false);

    if (rank > 0)
        player->learnSpell(selectedSpellId, false);

    AscensionClassService::Instance().SynchronizeProgression(player);
    return true;
}

bool IsAscensionCustomClassId(uint8 classId)
{
    return classId >= CLASS_BARBARIAN && classId <= CLASS_SPIRIT_MAGE;
}

std::vector<AscensionClassAbility> GetAscensionClassAbilities(uint8 classId)
{
    std::vector<AscensionClassAbility> abilities;
    if (!IsAscensionCustomClassId(classId))
        return abilities;

    for (auto const& grant : AscensionCompatData::ClassSpells)
        if (grant.ClassId == classId)
            abilities.push_back({ grant.SpellId, grant.SpellId, 0, grant.RequiredLevel });

    std::unordered_map<uint32, uint16> specializationOf;
    for (auto const& entry : AscensionCompatData::CoATalentEntries)
    {
        if (entry.ClassId != classId || !entry.SpellIds[0])
            continue;

        for (uint32 spellId : entry.SpellIds)
        {
            if (!spellId)
                continue;

            abilities.push_back({ spellId, entry.SpellIds[0], entry.SpecId, entry.RequiredLevel });
            specializationOf.emplace(spellId, entry.SpecId);
        }
    }

    for (auto const& rank : AscensionProgression::Ranks)
    {
        if (rank.ClassId != classId)
            continue;

        auto const specialization = specializationOf.find(rank.FirstSpellId);
        uint16 const specId = specialization != specializationOf.end() ? specialization->second : 0;
        abilities.push_back({ rank.SpellId, rank.FirstSpellId, specId, rank.RequiredLevel });
    }

    return abilities;
}

class AscensionCompatGroupScript : public GroupScript
{
public:
    AscensionCompatGroupScript()
        : GroupScript("AscensionCompatGroupScript", {GROUPHOOK_ON_LOOT_ROLL_START}) { }

    void OnLootRollStart(Group*, Roll const& roll, Loot const& loot, LootItem const& item) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
            AscensionCollectionService::Instance().OnLootRollStart(roll, loot, item);
    }
};

class AscensionCompatAllCreatureScript : public AllCreatureScript {
public:
  AscensionCompatAllCreatureScript()
      : AllCreatureScript("AscensionCompatAllCreatureScript") {}

  void OnCreatureAddWorld(Creature* creature) override {
    if (!creature || !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
      return;
    if (sAscensionPresets->HasPreset(creature->GetEntry()))
    {
      creature->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
    }
  }

  void OnAllCreatureUpdate(Creature* creature, uint32) override {
    if (!creature || !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
      return;
    if (sAscensionPresets->HasPreset(creature->GetEntry()))
    {
      if (!creature->HasUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE))
      {
        creature->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      }
    }
  }
};

void AppendConfiguredClientConfigs(AscensionClientConfig& config) {
  AppendAscensionClientConfigList(ascensionCompatConfig.GetConfigValue<std::string>(
                                      AscensionCompatConfig::CLIENT_BOOLEAN_CONFIGS),
                                  config.Booleans);
  AppendAscensionClientConfigList(ascensionCompatConfig.GetConfigValue<std::string>(
                                      AscensionCompatConfig::CLIENT_INTEGER_CONFIGS),
                                  config.Integers);
}

void AddAscensionCompatScripts() {
  Ascension::ClientItemPatches::Instance().Register(ITEM_HEARTWOOD_KEY);
  RegisterAscensionClientConfig([](AscensionClientConfig& config) {
    config.Booleans.emplace_back("CONFIG_CHARACTER_ADVANCEMENT_BUILD_INSPECT_ENABLED", true);
  });
  RegisterAscensionClientConfig(AppendConfiguredClientConfigs);
  new npc_ascension_training_book();
  RegisterSpellScript(spell_ascension_personal_bank);
  RegisterSpellScript(spell_ascension_experience_potion);
  RegisterSpellScript(spell_ascension_local_mount);
  RegisterSpellScript(spell_ascension_specialization_slot);
  RegisterSpellScript(spell_ascension_jailers_bargain);
  RegisterSpellScript(spell_ascension_reaper_extinction);
  RegisterSpellScript(spell_ascension_reaper_extinction_buff);
  RegisterSpellScript(spell_ascension_reaper_ruin);
  RegisterSpellScript(spell_ascension_reaper_redshade);
  RegisterSpellScript(spell_ascension_wildcard_mount);
  RegisterSpellScript(spell_ascension_legacy_quest_reward);
  new AscensionTradesmanScroll();
  new item_coa_title_contract();
  new AscensionCompatServerScript();
  new AscensionCompatCommandScript();
  new AscensionCompatPlayerScript();
  new AscensionCompatGroupScript();
  new AscensionCompatAllSpellScript();
  new AscensionCompatUnitScript();
  new AscensionCompatChangelogScript();
  new AscensionCompatWorldScript();
  new AscensionCompatAllCreatureScript();
}
