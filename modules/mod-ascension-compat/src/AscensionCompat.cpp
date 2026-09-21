/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU
 * AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionFelsworn.h"
#include "AscensionPyromancer.h"
#include "AscensionCultist.h"
#include "AscensionVenomancer.h"
#include "AscensionTinker.h"
#include "AscensionSunCleric.h"
#include "AllCreatureScript.h"
#include "AllSpellScript.h"
#include "AscensionChangelogCompat.h"
#include "AscensionCharacterSelection.h"
#include "AscensionClassMechanics.h"
#include "AscensionClassMechanics19To25.h"
#include "AscensionClassMechanics26To32.h"
#include "AscensionCoATalentData.h"
#include "AscensionCoATalentState.h"
#include "AscensionRunemasterEchoes.h"
#include "AscensionCollectionModelData.h"
#include "AscensionAmmunitionData.h"
#include "AscensionPersonalBank.h"
#include "AscensionCollectibleSpellData.h"
#include "AscensionCustomClassData.h"
#include "AscensionAuraAmounts.h"
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
#include "AscensionReaperPainmail.h"
#include "AscensionReaperScytheRush.h"
#include "AscensionVenomancerCatalyst.h"
#include "AscensionSpecialization.h"
#include "AscensionSpellProgressionData.h"
#include "AscensionTalentReplacementData.h"
#include "AscensionTaughtAbilityData.h"
#include "AscensionCreaturePreset.h"
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
#include "GossipDef.h"
#include "GlobalScript.h"
#include "GridTerrainData.h"
#include "GuildPackets.h"
#include "Item.h"
#include "ItemScript.h"
#include "LocalLevelScaling.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "QuestDef.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cstring>
#include <type_traits>
#include <deque>
#include <limits>
#include <list>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <set>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

using namespace Acore::ChatCommands;

namespace {
constexpr uint16 CMSG_ANTICHEAT_ALERT = 0x051F;
// The Character Advancement point purchase. Never observed on this realm: the patch-B
// Lua shim overrides AddByEntryID/ApplyPendingBuild and sends ".localtalent" instead,
// so the client never reaches the native send. Answering this opcode is what retires
// that shim; until then it is listed only so the packet log names it correctly.
constexpr uint16 CMSG_CUSTOM_ASCENSION_POINT_SPEND_REQUEST = 0x0523;
constexpr uint16 CMSG_CREATURE_QUERY_BULK = 0x061A;
constexpr uint16 CMSG_APPLY_APPEARANCES = 0x0697;
constexpr uint16 SMSG_APPLY_APPEARANCES_RESULT = 0x0698;
constexpr uint16 SMSG_APPEARANCE_COLLECTION_INFO = 0x0699;
constexpr uint16 SMSG_APPEARANCE_ACTIVE_INFO = 0x069A;
constexpr uint16 SMSG_APPEARANCE_ADDED = 0x069B;
constexpr uint16 SMSG_APPEARANCE_OUTFIT_INFO = 0x069D;
constexpr uint16 SMSG_CAN_SEE_APPEARANCES_INFO = 0x06A2;
constexpr uint16 CMSG_SET_CAN_SEE_APPEARANCES = 0x06A3;
constexpr uint16 SMSG_VANITY_COLLECTION_INFO = 0x06F7;
constexpr uint16 SMSG_VANITY_COLLECTION_ADDED = 0x06F8;

// A store record, as the client's own handler reads it for this opcode: a result code, a count,
// and that many fixed records. One record is the catalogue row's first sixteen columns, costs
// included. The module sends them alongside the ownership list; nothing on this realm acts on
// what comes back.
constexpr uint16 SMSG_QUERY_CUSTOM_STORE_RESULT = 0x06BA;
constexpr std::size_t VANITY_STORE_RECORD_DWORDS = 16;
// The client's character-advancement service (Extensions.dll). The active-specialization packet also
// bootstraps the per-character state on its first arrival, so it always goes out before the known-entries
// packet, whose handler otherwise stores nothing. The client answers a native learn or unlearn with the
// upload of its complete known set.
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_ACTIVE_SPEC = 0x0725;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES = 0x0726;
constexpr uint16 CMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES = 0x0727;
constexpr uint16 CMSG_MISSILE_FIRE_POSITION = 0x09C7;

// The client carries a personal-bank mode on top of the guild vault window. It is
// switched on by this packet, not by the item's spell: clicking the summoned
// guild-vault object sends the ordinary CMSG_GUILD_BANKER_ACTIVATE, and the
// server answers with SMSG_BANK_PERMISSIONS so the frame presents itself as the
// character's own bank (purchasable tabs, depositable soulbound items) instead of
// a guild's. The id comes from the client's own opcode table in Extensions.dll: an
// array of `mov eax, <name>; ret` stubs at file 0x2c3ea6, indexed by the pointer
// array at file 0x2c6ef0, where the opcode id is the 0-based index into that array.
// Decoded in .agents/plans/coa-cad-protocol/; it reproduces every opcode seen in this
// realm's packet log exactly (0x0741 = CMSG_GOSSIP_CLOSE, 0x061B = CMSG_ITEM_QUERY_BULK).
constexpr uint16 SMSG_BANK_PERMISSIONS = 0x0769;

struct ExtensionOpcodeIdentity {
  uint16 Opcode;
  char const *Name;
};

constexpr ExtensionOpcodeIdentity EXTENSION_OPCODES[] = {
    {CMSG_ANTICHEAT_ALERT, "CMSG_ANTICHEAT_ALERT"},
    {CMSG_CUSTOM_ASCENSION_POINT_SPEND_REQUEST, "CMSG_CUSTOM_ASCENSION_POINT_SPEND_REQUEST"},
    {0x053B, "CMSG_ASCENSIONGM_TICKET_LIST_REQUEST"},
    {0x0561, "CMSG_EXTENSION_INITIALIZED"},
    {0x05A1, "CMSG_CHALLENGE_QUERY_FAILURE"},
    {0x061B, "CMSG_ITEM_QUERY_BULK"},
    {0x0667, "CMSG_SET_LEVEL_SCALING"},
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
    {0x06FD, "CMSG_QUERY_INSTANCE_BINDS"},
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

/// First bytes of a packet, for protocol work: the compatibility log has to be
/// able to say what an unknown extension packet carried, not just how long it was.
[[nodiscard]] std::string DescribePacketPayload(WorldPacket const &packet,
                                                std::size_t limit = 64) {
  // ByteBuffer::contents() throws ByteBufferException on an empty buffer - the
  // core relies on that (WorldSocket's addon-info read says so). A log line must
  // never be the reason a packet kills the process, so read the size first and
  // keep the call guarded: an empty extension packet is now described as empty
  // instead of throwing out of the network thread.
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

constexpr uint32 SPELL_PYROMANCER_HEAT = 807389;
constexpr uint32 SPELL_PYROMANCER_EMBER = 807533;
constexpr uint32 SPELL_PRIMALIST_EARTHSHAPING = 680441;
constexpr uint32 SPELL_STORMBRINGER_STATIC = 803102;
constexpr uint32 SPELL_STORMBRINGER_CHARGED_CONDUIT = 803790;
constexpr uint32 SPELL_REAPER_REAPED_SOUL = 500363;
constexpr uint32 SPELL_REAPER_SOUL_INFUSION = 803031;
// Removes Reaped Souls, Soul Infusion and Soul Fragments; Soul Infusion's own proc trigger points to it.
constexpr uint32 SPELL_REAPER_SOUL_INFUSION_REMOVER = 561290;
constexpr uint32 SPELL_REAPER_SOUL_FRAGMENT = 805077;
constexpr uint32 SPELL_REAPER_GENERATE_SOUL = 805078;
constexpr uint32 SPELL_REAPER_SCYTHE_RUSH = 500359;
// The 20 second per-target marker Scythe Rush's hit adapter applies through helper 805339.
constexpr uint32 SPELL_REAPER_SCYTHE_RUSH_MARKER = 500377;
// Harvest Time. Its tooltip promises "a $s2% [chance] to not consume" Soul Infusion, and the
// effect behind that line is SPELL_AURA_ADD_FLAT_MODIFIER with SPELLMOD_CHANCE_OF_SUCCESS -50
// restricted to SpellFamilyName 36. This core only reads that modifier for proc and hit chance,
// never for a resource cost, so nothing implemented the line and the window spent Soul Infusion
// at the usual rate.
constexpr uint32 SPELL_REAPER_HARVEST_TIME = 803995;
constexpr char ASCENSION_LOCAL_RESOURCE_PREFIX[] = "ASC_LOCAL_RESOURCE";
constexpr char ASCENSION_ACTIVE_SPEC_SETTING[] = "core.ascension_active_spec";
// A stored talent build per tree, "core.ascension_build.<spec>" with 0 for the class tree.
constexpr char ASCENSION_TALENT_BUILD_SETTING_PREFIX[] = "core.ascension_build.";

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
    500483, // Tormented Souls
    500484, // Spectral Scythe
    500576, // Spectral Scythe (Soul Infusion variant)
    500631, // Reliquary of the Lost
    // Soulrend ranks. Every rank requires Soul Infusion (casterAuraSpell 803031)
    // and retained live logs removed the caster's Reaped Souls and Soul
    // Infusion within 0.5 s of the cast in 278 of 285 casts; the exceptions
    // include logged misses, which live refunded (2026-07-31 changelog).
    // Consumption here happens on cast like the other consumers.
    572341, 572342, 573316, 573317, 573318, 573319, 573321, 573322
}};

constexpr std::array<std::pair<uint32, uint32>, 1> REAPER_ONE_SOUL_CONSUMERS =
{{
    // Lament's datamined rank IDs are absent from the live local Spell.dbc.
    {500361, 500361} // Sanguine Orb
}};

constexpr std::size_t APPEARANCE_CATEGORY_COUNT = 69;
constexpr uint32 APPEARANCE_CATEGORY_AMMUNITION = 32;
// The copied 3.3.5 client supports the 23-bit extended world-packet header.
// Bound this snapshot to 512 KiB of entries (1 MiB in its native vector), not
// the former, incorrect 64 KiB transport assumption. The full local catalog fits.
constexpr std::size_t MAX_APPEARANCE_SNAPSHOT_ENTRIES = 65536;
constexpr std::size_t APPEARANCE_ADDS_PER_BATCH = 16;
constexpr uint32 APPEARANCE_ADD_BATCH_INTERVAL_MS = 100;
constexpr uint32 APPEARANCE_ADD_INITIAL_DELAY_MS = 500;
constexpr uint32 APPEARANCE_LOGIN_RESYNC_DELAY_MS = 3000;
constexpr std::size_t MAX_QUEUED_EXTENSION_PACKETS = 64;
constexpr uint32 VANITY_CATEGORY_MOUNTS = 0x04000000;
constexpr uint32 VANITY_CATEGORY_COMPANIONS = 0x08000000;
constexpr std::size_t COMPANION_SPELLS_PER_BATCH = 4;
constexpr uint32 COMPANION_SPELL_BATCH_INTERVAL_MS = 200;

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
  ALLOW_LEARNED_SPELL_DELIVERY,
  LEARN_OWNED_COMPANIONS,
  MAX_RIDING_FROM_START,
  LEVEL_SCALING,
  QUEST_LEVEL_SCALING,

  NUM_CONFIGS,
};

class AscensionCompatConfigData
    : public ConfigValueCache<AscensionCompatConfig> {
public:
  AscensionCompatConfigData()
      : ConfigValueCache(AscensionCompatConfig::NUM_CONFIGS) {}

  void BuildConfigCache() override {
    SetConfigValue<bool>(AscensionCompatConfig::ENABLED,
                         "AscensionCompat.Enable", true);
    SetConfigValue<bool>(AscensionCompatConfig::LOG_CONSUMED_PACKETS,
                         "AscensionCompat.LogConsumedPackets", true);
    SetConfigValue<uint32>(AscensionCompatConfig::FIRST_EXTENSION_OPCODE,
                           "AscensionCompat.FirstExtensionOpcode", 0x051F);
    SetConfigValue<uint32>(AscensionCompatConfig::LAST_EXTENSION_OPCODE,
                           "AscensionCompat.LastExtensionOpcode", 0x09D3);
    SetConfigValue<bool>(AscensionCompatConfig::AUTO_COLLECT_APPEARANCES,
                         "AscensionCompat.AutoCollectAppearances", true);
    SetConfigValue<bool>(
        AscensionCompatConfig::UNLOCK_LOCAL_APPEARANCE_CATALOG,
        "AscensionCompat.UnlockLocalAppearanceCatalog", true);
    SetConfigValue<uint32>(
        AscensionCompatConfig::APPEARANCE_CATALOG_PER_CATEGORY,
        "AscensionCompat.AppearanceCatalogPerCategory", 500);
    SetConfigValue<bool>(AscensionCompatConfig::UNLOCK_ALL_VANITY,
                         "AscensionCompat.UnlockAllVanity", true);
    SetConfigValue<bool>(AscensionCompatConfig::ALLOW_LEARNED_SPELL_DELIVERY,
                         "AscensionCompat.AllowLearnedSpellDelivery", true);
    SetConfigValue<bool>(AscensionCompatConfig::LEARN_OWNED_COMPANIONS,
                         "AscensionCompat.LearnOwnedCompanions", true);
    SetConfigValue<bool>(AscensionCompatConfig::MAX_RIDING_FROM_START,
                         "AscensionCompat.MaxRidingFromStart", true);
    SetConfigValue<bool>(AscensionCompatConfig::LEVEL_SCALING,
                         "AscensionCompat.LevelScaling", true);
    SetConfigValue<bool>(AscensionCompatConfig::QUEST_LEVEL_SCALING,
                         "AscensionCompat.QuestLevelScaling", true);
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
};

struct VanityInfo {
  uint32 LearnedSpell = 0;
  uint32 Flags = 0;
  uint32 CategoryMask = 0;
  /// The catalogue row's first sixteen columns, which is the shape of one store record: the item
  /// id, its flags, its group and the three costs.
  std::array<uint32, VANITY_STORE_RECORD_DWORDS> StoreRecord{};
};

struct PlayerCollectionState {
  uint32 AccountId = 0;
  std::unordered_set<uint32> CollectedAppearances;
  std::unordered_set<uint32> OwnedVanityItems;
  std::array<uint32, APPEARANCE_CATEGORY_COUNT> ActiveAppearances{};
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

enum LegacyQuestSpells : uint32
{
    QuestStoneskinTotem = 8073,
    QuestPathOfDefense = 8121,
    LegacyDefensiveStance = 1100071,
    LegacyTaunt = 1100355,
    LegacySunderArmor = 1107386,
    LegacyStoneskinTotem = 1108071
};

struct LegacyQuestReward
{
    uint32 Wrapper;
    std::array<uint32, MAX_SPELL_EFFECTS> Spells;
};

constexpr std::array<LegacyQuestReward, 2> LegacyQuestRewards = {{
    {QuestStoneskinTotem, {LegacyStoneskinTotem, 0, 0}},
    {QuestPathOfDefense, {LegacyDefensiveStance, LegacySunderArmor, LegacyTaunt}}
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

    // Only repair the known class-quest grants, with evidence of the corresponding rewarded quest.
    // Do not infer ownership from absence in the generated custom-class spell catalogs.
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

// The generated class grants only hold the Alliance capital Fel Rifts (Stormwind 26, Ironforge 30, Darnassus 36).
// These are their Horde counterparts, at their Spell.dbc SpellLevel.
constexpr std::array<FelswornRiftGrant, 3> FelswornHordeCapitalRifts =
{{
    {535598, 26}, // Orgrimmar
    {535599, 30}, // Thunder Bluff
    {535600, 36}  // Undercity
}};

// SkillLineAbility.dbc gives the Alliance capital rifts RaceMask 1101 and the Horde ones RaceMask 690.
constexpr std::array<uint32, 6> FelswornCapitalRifts = {535595, 535596, 535597, 535598, 535599, 535600};

bool CanGrantAscensionRacialSpell(Player const* player, uint32 spellId)
{
    bool racial = false;
    auto const bounds = sSpellMgr->GetSkillLineAbilityMapBounds(spellId);
    if (std::find(FelswornCapitalRifts.begin(), FelswornCapitalRifts.end(), spellId) != FelswornCapitalRifts.end())
        for (auto itr = bounds.first; itr != bounds.second; ++itr)
            if (itr->second->RaceMask && !(itr->second->RaceMask & player->getRaceMask()))
                return false;
    for (auto itr = bounds.first; itr != bounds.second; ++itr)
        if (AscensionRacialAbilities::GetRace(itr->second->SkillLine))
        {
            racial = true;
            if (AscensionRacialAbilities::CanLearn(*itr->second, player->getRace(), player->getClass()))
                return true;
        }
    return !racial;
}

class AscensionClassService {
public:
  static AscensionClassService &Instance() {
    static AscensionClassService instance;
    return instance;
  }

  uint32 SynchronizeProgression(Player *player) {
    if (!IsAscensionCustomClass(player))
      return 0;

    // Explicitly authorized 2026-09-03: reconcile only generator-owned class
    // grants. Do not scan arbitrary quest, collection or purchased spells for
    // absence from a level-one snapshot. Valid selected talents are independent.
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
      // Older local talent choices were persisted only as learned spell IDs.
      // A colliding paid talent therefore remains protected until the client
      // supplies its selection, rather than treating catalog absence as proof.
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
    if (removed)
      LOG_INFO("module.ascension_compat", "Reconciled {} proven class grants for {} against live level {}",
          removed, player->GetName(), uint32(player->GetLevel()));
    uint32 learned = 0;
    // The live baseline sampled one race per class. Repair every race from its own DBC skill line.
    for (uint32 spellId : racialSpells)
        if (!player->HasSpell(spellId) && sSpellMgr->GetSpellInfo(spellId))
        {
            player->learnSpell(spellId, false);
            ++learned;
        }
    for (auto const& entry : AscensionLiveBaseline::Spells)
      if (entry.ClassId == player->getClass() && (!entry.RaceId || entry.RaceId == player->getRace()) &&
          CanGrantAscensionRacialSpell(player, entry.SpellId) &&
          !player->HasSpell(entry.SpellId) && sSpellMgr->GetSpellInfo(entry.SpellId))
      {
        player->learnSpell(entry.SpellId, false);
        ++learned;
      }
    for (AscensionCompatData::ClassSpell const &progressionSpell :
         AscensionCompatData::ClassSpells) {
      if (progressionSpell.ClassId != player->getClass() ||
          progressionSpell.RequiredLevel > player->GetLevel() ||
          !CanGrantAscensionRacialSpell(player, progressionSpell.SpellId) ||
          player->HasSpell(progressionSpell.SpellId))
        continue;

      if (!sSpellMgr->GetSpellInfo(progressionSpell.SpellId))
      {
        LOG_ERROR("module.ascension_compat",
                  "Cannot teach missing Ascension class spell {} to {}",
                  progressionSpell.SpellId, player->GetName());
        continue;
      }

      player->learnSpell(progressionSpell.SpellId, false);
      ++learned;
    }
    if (player->getClass() == CLASS_DEMON_HUNTER)
      for (FelswornRiftGrant const& rift : FelswornHordeCapitalRifts)
        if (rift.RequiredLevel <= player->GetLevel() && CanGrantAscensionRacialSpell(player, rift.SpellId) &&
            !player->HasSpell(rift.SpellId) && sSpellMgr->GetSpellInfo(rift.SpellId))
        {
          player->learnSpell(rift.SpellId, false);
          ++learned;
        }

    ReconcileRunemasterFists(player, activeSpec);
    learned += SynchronizeAutomaticTalents(player, GetActiveSpecialization(player));
    // Rank upgrades are conditional on already owning the root. They cannot
    // spend talent points, pick an unselected ability, or leak an old spec.
    for (AscensionProgression::Rank const& rank : AscensionProgression::Ranks)
    {
        if (rank.ClassId != player->getClass() || rank.RequiredLevel > player->GetLevel() ||
            !player->HasSpell(rank.FirstSpellId) || player->HasSpell(rank.SpellId))
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
      LOG_INFO("module.ascension_compat",
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

            // Wait for CAD's confirmed specialization after login. A persisted
            // parent alone must not teach an ability from the previous spec.
            bool const allowed = specializationId == entry.SpecId &&
                player->GetLevel() >= entry.RequiredLevel && player->HasSpell(entry.ParentSpellId);
            if (!allowed)
            {
                player->removeSpell(entry.SpellId, SPEC_MASK_ALL, true);
                continue;
            }

            // Preserve independent permanent ownership, other native specs and
            // pending deletion records. Native _addSpell would resurrect a
            // tombstone as CHANGED even when requested as temporary.
            auto const& spells = player->GetSpellMap();
            if (spells.find(entry.SpellId) != spells.end() || !sSpellMgr->GetSpellInfo(entry.SpellId))
                continue;

            player->learnSpell(entry.SpellId, true);
            if (player->HasSpell(entry.SpellId))
                ++learned;
        }
        if (!beforeMap && player->getClass() == CLASS_SON_OF_ARUGAL)
        {
            // Native spec changes reconcile this flag, but removing a temporary
            // spell during a CAD refund does not. Preserve independently owned 674.
            // The before-map pass leaves this to the OnPlayerLogin one: the saved
            // inventory has already been validated by then, and unequipping an
            // offhand before the player is in the world is a separate contract.
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
            bool const allowed = specializationId == entry.SpecId && player->HasSpell(entry.ParentSpellId);
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
                // Several mutually exclusive specs can transform the same root.
                // An ineligible row must not erase another row's valid choice.
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
            // Restore the old button before its temporary spell disappears.
            if (player->GetTemporarySpellReplacement(id) != replacement)
                player->SetTemporarySpellReplacement(id, 0);
        }

        for (uint32 id : candidates)
        {
            if (desired.count(id))
                continue;
            // Native removal recursively removes higher ranks. A lower rank may
            // need to remain while a desired higher rank is still owned.
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
            // Preserve permanent/other-spec ownership and pending deletions, as
            // with ordinary taught abilities. Child IDs cannot re-enter this hook.
            if (player->GetSpellMap().find(id) == player->GetSpellMap().end())
            {
                player->learnSpell(id, true);
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
            LOG_ERROR("module.ascension_compat",
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

      // Bounded to the known proficiency catalog, not arbitrary learned spells.
      if (player->HasSpell(definition.SpellId))
      {
        player->removeSpell(definition.SpellId, SPEC_MASK_ALL, false);
        ++removed;
      }
      if (player->HasSkill(definition.SkillId))
        player->SetSkill(definition.SkillId, 0, 0, 0);
    }

    // Defense and Unarmed are intrinsic combat skills, absent from the equipment proficiency catalog.
    // Keep their current value and cap in step with the weapon skills on login and every level change.
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
      LOG_INFO("module.ascension_compat",
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

    // Called only inside Player::Create, never while loading an existing player.
    // Hidden proficiency spells are separate from the visible spellbook roots.
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
        // Earlier creation SQL also classified Gemcutting as a class-wide grant.
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
      // Weapon display ranks need a separate compatibility review: preserve
      // native level-scaled combat skill for now, and record this deviation.
      bool const weapon = std::any_of(AscensionCompatData::ProficiencyDefinitions.begin(),
          AscensionCompatData::ProficiencyDefinitions.end(), [&entry](auto const& definition)
          { return definition.SkillId == entry.SkillId && definition.ScalesWithLevel; });
      // Unlike our explicitly maximized weapon proficiencies, Unarmed keeps
      // native current/cap (normally 1/5 here). A max of 1 prevents future growth.
      if (entry.SkillId == SKILL_UNARMED)
        continue;
      uint16 const maximum = weapon ? player->GetMaxSkillValueForLevel() : entry.Maximum;
      uint16 const value = weapon ? maximum : entry.Rank;
      player->SetSkill(entry.SkillId, 0, value, maximum);
    }
    return true;
  }

  // Creation-only entry point. The caller must abort Player::Create on false
  // and skip both legacy starter placement and the later bag auto-equip pass.
  // Login/repair paths deliberately never call this function.
  bool InitializeLiveStarterKit(Player* player)
  {
    if (!IsAscensionCustomClass(player) || player->IsInWorld())
      return false;

    constexpr uint32 liveStarterRevision = 20260903;
    char const* const liveSetting = "core.ascension_starter_live";
    if (player->GetPlayerSetting(liveSetting, 0).value == liveStarterRevision)
      return true;

    // Do not replace, relocate, delete, or top up any pre-existing inventory.
    // An empty, newly constructed Player is the only supported input.
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
      if (player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
      {
        LOG_ERROR("module.ascension_compat", "Refused non-empty live starter initialization for class {}", uint32(player->getClass()));
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
        LOG_ERROR("module.ascension_compat", "Invalid live starter class {} item {} slot {} count {}", uint32(entry.ClassId), entry.ItemId, uint32(entry.Slot), entry.Count);
        return false;
      }

      if (equipped)
      {
        uint16 destination = 0;
        InventoryResult const result = player->CanEquipNewItem(entry.Slot, destination, entry.ItemId, false);
        if (result != EQUIP_ERR_OK || destination != position)
        {
          LOG_ERROR("module.ascension_compat", "Cannot equip live starter class {} item {} in slot {}: {}", uint32(entry.ClassId), entry.ItemId, uint32(entry.Slot), uint32(result));
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
          LOG_ERROR("module.ascension_compat", "Cannot store live starter class {} item {} in slot {}: {}", uint32(entry.ClassId), entry.ItemId, uint32(entry.Slot), uint32(result));
          return false;
        }
      }
      ++entries;
    }
    if (!entries)
      return false;

    // The generated order is equipment first (main hand before off hand), then
    // backpack positions. Equal item IDs in different slots remain distinct.
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
        LOG_ERROR("module.ascension_compat", "Failed exact live starter placement for class {} item {} slot {}", uint32(entry.ClassId), entry.ItemId, uint32(entry.Slot));
        return false;
      }
    }

    // Saved with the initial character transaction, not after the create
    // callback. This also prevents the legacy login repair from adding old gear.
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

    // A hearthstone or one surviving starter item does not prove the kit is
    // complete. Repair each character once; never replace gear already worn.
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
        LOG_ERROR("module.ascension_compat", "Missing starter item template {}", itemId);
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
        LOG_ERROR("module.ascension_compat", "Unsupported starter item inventory type for {}", itemId);
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
      LOG_INFO("module.ascension_compat",
               "Restored {} starter items for {} (class {})", restored,
               player->GetName(), uint32(player->getClass()));
    }

    return restored != 0;
  }

  void OnPlayerLogin(Player *player) {
    if (!IsAscensionCustomClass(player))
      return;

    uint32 const specializationId = player->GetPlayerSetting(ASCENSION_ACTIVE_SPEC_SETTING, 0).value;
    if (specializationId)
    {
        std::lock_guard<std::mutex> lock(_stateLock);
        _activeSpecializations[player->GetGUID().GetCounter()] = specializationId;
    }

    SynchronizeProgression(player);
    SynchronizeProficiencies(player);
    RepairStarterKit(player, false);
    QueueCharacterAdvancementState(player);
    SendCharacterAdvancementBridge(player);
    SendLocalTalentState(player);

    // Taught abilities (e.g. Eternal Curse 800157, AscensionTaughtAbilityData.h)
    // are temporary spells and are never saved to character_spell, so
    // Player::_LoadActions - which runs inside Player::LoadFromDB, before both
    // PrepareTaughtAbilitiesBeforeMap and this hook - found them unknown and
    // pruned their action bar slots for this login. Now that the grant has
    // landed, reload the saved bar the same way Player::ActivateSpec does after
    // a spec switch, so a still-eligible taught ability does not appear to fall
    // off the action bar on every relog.
    CharacterDatabasePreparedStatement* actionsStmt =
        CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHARACTER_ACTIONS_SPEC);
    actionsStmt->SetData(0, player->GetGUID().GetRawValue());
    actionsStmt->SetData(1, player->GetActiveSpec());

    // That statement is prepared on asynchronous connections only, so a
    // synchronous Query() asserts on a null MySQLPreparedStatement. The player
    // can also leave before the response arrives, which is why the session -
    // which owns this callback - resolves them instead of a captured pointer.
    WorldSession* session = player->GetSession();
    session->GetQueryProcessor().AddCallback(CharacterDatabase.AsyncQuery(actionsStmt)
        .WithPreparedCallback([session](PreparedQueryResult result)
        {
            if (Player* owner = session->GetPlayer())
                owner->LoadActions(result);
        }));
  }

  /// Grant the taught abilities before the client's spell list goes out, the same
  /// place and for the same reason the collection service prepares owned companions.
  ///
  /// They are granted as temporary spells, so they are never saved and have to be
  /// granted again on every login. Doing that from OnPlayerLogin means the player is
  /// already in the world, where Player::_addSpell announces the grant, and the client
  /// reports learning them again on each relog although nothing changed. Outside the
  /// world no such packet is sent and the replaced snapshot carries them instead.
  ///
  /// The OnPlayerLogin pass stays as it is: it skips whatever is already owned, and it
  /// still covers a parent that is only granted once that later pass has run.
  void PrepareTaughtAbilitiesBeforeMap(Player* player)
  {
    // This hook also runs on ordinary map changes, where the spellbook is already live.
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
        LOG_INFO("module.ascension_compat",
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

  /// The catalog entries the character holds, at the rank its spellbook proves.
  static std::vector<AscensionCoATalentState::KnownEntry> KnownTalentEntries(Player const* player)
  {
    return AscensionCoATalentState::KnownEntries(player->getClass(), SpellbookOf(player));
  }

  /// The client's character-advancement service keys its state off the local player object, which the
  /// loading screen has not created yet while OnPlayerLogin runs: state sent then reaches no character.
  /// CMSG_SET_ACTIVE_MOVER is the client saying that object now exists, so the state waits for the first one.
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

  /// The active specialization first: its handler builds the per-character container that the known-entries
  /// handler refuses to fill without. The character's local specialization occupies the single slot 0, which
  /// the client reports as specialization 1; the specialization id itself stays with the local UI.
  void SendCharacterAdvancementState(Player* player)
  {
    WorldPacket packet(SMSG_CHARACTER_ADVANCEMENT_ACTIVE_SPEC, sizeof(uint32) * 2);
    packet << uint32(0) << uint32(1);
    player->GetSession()->SendPacket(&packet);

    uint32 const sent = SendKnownTalentEntries(player);
    LOG_INFO("module.ascension_compat",
             "Initialized Character Advancement for {} (class {}, level {}) with {} known entries",
             player->GetName(), uint32(player->getClass()), uint32(player->GetLevel()), sent);
  }

  /// After a talent change: the complete set again, which the client diffs against what it holds, and the
  /// bridge snapshot for the local layer. The native packet waits for the initial state, whose container
  /// the known-entries handler needs.
  void SendCharacterAdvancementKnownEntries(Player* player)
  {
    SendCharacterAdvancementBridge(player);
    SendLocalTalentState(player);
    {
      std::lock_guard<std::mutex> lock(_stateLock);
      if (!_advancementSent.count(player->GetGUID().GetCounter()))
        return;
    }
    SendKnownTalentEntries(player);
  }

  /// The local Character Advancement layer in patch-B keeps the active specialization in a per-character
  /// SavedVariable and rebuilds paid ranks from the spellbook, which cannot see hidden rank spells. The
  /// server knows both, so it sends both as an addon-channel whisper from the character to itself, the
  /// transport of the Runemaster Echoes bridge: the client delivers it to Lua as CHAT_MSG_ADDON and no one
  /// else sees it. One chat packet carries a bounded payload, so the ranks are chunked; the sequence is
  /// one-based and every chunk repeats the total, so a client that missed one knows its picture is
  /// incomplete rather than reading a short list as missing ranks. Format and client half from #4030.
  void SendCharacterAdvancementBridge(Player* player)
  {
    if (!player->GetSession())
      return;

    uint32 const specializationId = GetActiveSpecialization(player);
    std::vector<std::string> ranks;
    for (AscensionCoATalentState::KnownEntry const& known : KnownTalentEntries(player))
      ranks.push_back(std::to_string(known.EntryId) + "," + std::to_string(known.Rank));

    constexpr std::size_t maxPayload = 180;
    std::vector<std::string> chunks;
    std::string current;
    for (std::string const& rank : ranks)
    {
      if (!current.empty() && current.size() + rank.size() + 1 > maxPayload)
      {
        chunks.push_back(current);
        current.clear();
      }
      if (!current.empty())
        current += ';';
      current += rank;
    }
    if (!current.empty() || chunks.empty())
      chunks.push_back(current);

    for (std::size_t index = 0; index < chunks.size(); ++index)
    {
      std::string const message = "ASC_LOCAL_CAD\t1:" + std::to_string(specializationId) + ":" +
          std::to_string(index + 1) + ":" + std::to_string(chunks.size()) + ":" + chunks[index];
      WorldPacket packet;
      ChatHandler::BuildChatPacket(packet, CHAT_MSG_WHISPER, LANG_ADDON, player->GetGUID(), player->GetGUID(),
          message, 0, player->GetName(), player->GetName(), 0, false);
      player->GetSession()->SendPacket(&packet);
    }

    LOG_DEBUG("module.ascension_compat",
              "Sent Character Advancement bridge to {}: specialization {}, {} entries in {} message(s)",
              player->GetName(), specializationId, uint32(ranks.size()), uint32(chunks.size()));
  }

  /// The same state in the three-message form the #4031 client half reads: ASC_LOCAL_SPEC (the active
  /// specialization), ASC_LOCAL_RECORDS (whether a record exists per tree: here the server always has one,
  /// an empty list meaning an empty tree) and ASC_LOCAL_TALENTS, one message of "entry:rank" pairs that the
  /// client adopts whole, so it is never split. Automatic entries are left out: that client skips them, and
  /// the message stays short. Either client half keeps working; one of the two forms retires with the client
  /// patch that ships.
  void SendLocalTalentState(Player* player)
  {
    if (!player->GetSession())
      return;

    auto send = [player](char const* prefix, std::string const& body)
    {
      std::string message = prefix;
      message += '\t';
      message += body;
      WorldPacket packet;
      ChatHandler::BuildChatPacket(packet, CHAT_MSG_WHISPER, LANG_ADDON, player->GetGUID(), player->GetGUID(),
          message, 0, player->GetName(), player->GetName(), 0, false);
      player->GetSession()->SendPacket(&packet);
    };

    std::string ranks;
    for (AscensionCoATalentState::KnownEntry const& known : KnownTalentEntries(player))
    {
      AscensionCompatData::CoATalentEntry const* entry = FindTalentEntry(known.EntryId);
      if (!entry || (!entry->AECost && !entry->TECost && !GetSelectableFreeGroup(entry->EntryId)))
        continue;
      if (!ranks.empty())
        ranks += ' ';
      ranks += std::to_string(known.EntryId) + ":" + std::to_string(known.Rank);
    }

    send("ASC_LOCAL_SPEC", std::to_string(GetActiveSpecialization(player)));
    send("ASC_LOCAL_RECORDS", "1 1");
    send("ASC_LOCAL_TALENTS", ranks);
  }

  uint32 SendKnownTalentEntries(Player* player)
  {
    std::vector<AscensionCoATalentState::KnownEntry> const known = KnownTalentEntries(player);
    std::vector<uint8> const body = AscensionCoATalentState::KnownEntriesPayload(known);
    WorldPacket packet(SMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES, body.size());
    packet.append(body.data(), body.size());
    player->GetSession()->SendPacket(&packet);
    return uint32(known.size());
  }

  /// One owner for every rule a talent change obeys, whether it arrives as .localtalent or inside the client's
  /// known-entries upload. False with the reason when the change is refused; the spellbook is then unchanged.
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
          "Talent entry {} belongs to specialization {}, but your active local specialization is {}.",
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
      // A UI synchronization request cannot bypass automatic prerequisites.
      // Automatic ranks are immutable; paid talent choices remain below.
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

    // A rank above the one the spellbook proves costs points the tree may not have left. Removals and lower
    // ranks always go through, so an over-budget character can always come back under it.
    // A known-entries upload prices its whole set before applying it and skips this check per entry.
    uint32 const currentRank = AscensionCoATalentState::KnownRank(entry, SpellbookOf(player));
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
      // An explicit player selection resolves a group. Login must not choose
      // between alternatives previously double-granted by the old free rule.
      for (auto const& other : AscensionCompatData::CoATalentEntries)
        if (other.ClassId == player->getClass() && other.SpecId == entry.SpecId && other.EntryId != entryId &&
            GetSelectableFreeGroup(other.EntryId) == freeChoiceGroup)
          for (uint32 spellId : other.SpellIds)
            if (spellId && player->HasSpell(spellId))
              player->removeSpell(spellId, SPEC_MASK_ALL, false);
    }

    for (uint32 spellId : entry.SpellIds)
      if (spellId && player->HasSpell(spellId))
        player->removeSpell(spellId, SPEC_MASK_ALL, false);

    if (rank > 0)
      player->learnSpell(selectedSpellId, false);

    SynchronizeProgression(player);

    LOG_INFO("module.ascension_compat", "Set local CoA talent entry {} to rank {} for {} (class {})", entryId, rank,
             player->GetName(), uint32(player->getClass()));
    return true;
  }

  /// Reset Trees on the server: every paid rank of the class goes, automatic grants and the specialization
  /// stay, and the progression pass restores whatever the remaining state entitles the character to.
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
    LOG_INFO("module.ascension_compat", "Reset {} paid CoA talent rank(s) for {} (class {})", removed,
             player->GetName(), uint32(player->getClass()));
    return removed;
  }

  /// The character's point budget, refused rather than assumed when the essence table has no row.
  bool TalentBudget(Player const* player, uint32& classBudget, uint32& specializationBudget, std::string& error)
  {
    if (AscensionCompatData::GetCoATalentBudget(player->getClass(), player->GetLevel(), classBudget,
                                                specializationBudget))
      return true;

    LOG_ERROR("module.ascension_compat", "No CoA talent budget row for class {} at level {} ({})",
              uint32(player->getClass()), uint32(player->GetLevel()), player->GetName());
    error = Acore::StringFormat("No talent budget is known for class {} at level {}; no rank can be raised.",
                                uint32(player->getClass()), uint32(player->GetLevel()));
    return false;
  }

  /// The rank the progression pass hands an entry back after its spells are removed: the highest rank whose
  /// spell is also a class grant at the character's level. Such an entry stays held whatever the client
  /// uploads, so an upload is priced with it.
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

  /// The client's complete known set after a native learn or unlearn. Automatic entries are the server's to
  /// grant and are ignored; every paid or free-choice entry is checked and the state the set leads to is priced
  /// before any change lands, so a refused upload changes nothing. The resend of the server's state that
  /// follows either outcome puts the client right.
  bool ApplyKnownEntriesUpload(Player* player, std::vector<AscensionCoATalentState::KnownEntry> const& upload,
                               std::string& error)
  {
    uint32 activeSpecialization = GetActiveSpecialization(player);
    uint32 uploadedSpecialization = 0;
    // A repeated entry keeps its last record, as the client's own store would.
    std::unordered_map<uint32, uint32> wanted;
    for (AscensionCoATalentState::KnownEntry const& item : upload)
    {
      AscensionCompatData::CoATalentEntry const* entry = FindTalentEntry(item.EntryId);
      if (!entry || entry->ClassId != player->getClass())
      {
        error = Acore::StringFormat("Talent entry {} does not belong to your custom class.", item.EntryId);
        return false;
      }
      if (!entry->AECost && !entry->TECost && !GetSelectableFreeGroup(entry->EntryId))
        continue;
      if (item.Rank > entry->SpellCount)
      {
        error = Acore::StringFormat("Talent entry {} only has {} rank(s).", entry->EntryId,
                                    uint32(entry->SpellCount));
        return false;
      }
      if (item.Rank > 0)
      {
        if (player->GetLevel() < entry->RequiredLevel)
        {
          error = Acore::StringFormat("Talent entry {} requires level {}.", entry->EntryId,
                                      uint32(entry->RequiredLevel));
          return false;
        }
        if (!sSpellMgr->GetSpellInfo(entry->SpellIds[item.Rank - 1]))
        {
          error = Acore::StringFormat("Talent entry {} rank {} references a missing server spell.",
                                      entry->EntryId, item.Rank);
          return false;
        }
        // Without an active specialization the upload selects one, as the first .localtalent does; it
        // cannot select two.
        if (entry->SpecId && activeSpecialization && entry->SpecId != activeSpecialization)
        {
          error = Acore::StringFormat(
              "Talent entry {} belongs to specialization {}, but your active local specialization is {}.",
              entry->EntryId, uint32(entry->SpecId), activeSpecialization);
          return false;
        }
        if (entry->SpecId && !activeSpecialization)
        {
          if (uploadedSpecialization && uploadedSpecialization != entry->SpecId)
          {
            error = Acore::StringFormat("The uploaded build mixes specializations {} and {}.",
                                        uploadedSpecialization, uint32(entry->SpecId));
            return false;
          }
          uploadedSpecialization = entry->SpecId;
        }
      }
      wanted[entry->EntryId] = item.Rank;
    }

    // Price the state the upload leads to: its own ranks, and for every other paid entry the rank the
    // progression pass hands back once the upload has removed it.
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

    uint32 classBudget = 0;
    uint32 specializationBudget = 0;
    if (!TalentBudget(player, classBudget, specializationBudget, error))
      return false;
    AscensionCoATalentState::SpentPoints const spent = AscensionCoATalentState::Spent(priced);
    if (spent.AE > classBudget || spent.TE > specializationBudget)
    {
      error = Acore::StringFormat(
          "That build spends {} class and {} specialization point(s); level {} has {} and {}.", spent.AE,
          spent.TE, uint32(player->GetLevel()), classBudget, specializationBudget);
      return false;
    }

    if (uploadedSpecialization && !SwitchSpecialization(player, uploadedSpecialization))
    {
      error = Acore::StringFormat("Specialization {} is not valid for your custom class.",
                                  uploadedSpecialization);
      return false;
    }

    // Removals first, so a swap never holds both talents at once.
    std::vector<std::pair<AscensionCompatData::CoATalentEntry const*, uint32>> changes;
    for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
    {
      if (entry.ClassId != player->getClass() ||
          (!entry.AECost && !entry.TECost && !GetSelectableFreeGroup(entry.EntryId)))
        continue;
      auto itr = wanted.find(entry.EntryId);
      uint32 const rank = itr == wanted.end() ? 0 : itr->second;
      if (rank != AscensionCoATalentState::KnownRank(entry, SpellbookOf(player)))
        changes.emplace_back(&entry, rank);
    }
    std::stable_sort(changes.begin(), changes.end(),
                     [](auto const& left, auto const& right) { return (left.second == 0) > (right.second == 0); });
    for (auto const& [entry, rank] : changes)
      if (!SetTalentRank(player, *entry, rank, error, false))
      {
        // Every rule was checked above; the state resend covers whatever changed before this.
        LOG_ERROR("module.ascension_compat",
                  "Known-entries upload for {} failed after validation at entry {} rank {}: {}", player->GetName(),
                  entry->EntryId, rank, error);
        return false;
      }
    return true;
  }

  /// CanPacketReceiveEarly runs on the network thread, so the upload is copied and waits for the player's
  /// own update before it touches the spellbook. Keyed by account: the player may be gone by then.
  void QueueKnownEntriesUpload(uint32 accountId, WorldPacket const& packet)
  {
    std::lock_guard<std::mutex> lock(_stateLock);
    std::deque<std::vector<uint8>>& queue = _pendingUploads[accountId];
    if (queue.size() >= MAX_QUEUED_KNOWN_ENTRIES_UPLOADS)
    {
      LOG_WARN("module.ascension_compat", "Dropping known-entries upload for account {}: its queue is full",
               accountId);
      return;
    }

    std::vector<uint8> body;
    if (packet.size())
      body.assign(packet.contents(), packet.contents() + packet.size());
    queue.push_back(std::move(body));
  }

  void ProcessKnownEntriesUploads(Player* player)
  {
    std::deque<std::vector<uint8>> uploads;
    {
      std::lock_guard<std::mutex> lock(_stateLock);
      auto itr = _pendingUploads.find(player->GetSession()->GetAccountId());
      if (itr == _pendingUploads.end())
        return;
      uploads = std::move(itr->second);
      _pendingUploads.erase(itr);
    }

    if (!IsAscensionCustomClass(player))
      return;
    for (std::vector<uint8> const& body : uploads)
      HandleKnownEntriesUpload(player, body);
  }

  void HandleKnownEntriesUpload(Player* player, std::vector<uint8> const& body)
  {
    std::vector<AscensionCoATalentState::KnownEntry> upload;
    if (!AscensionCoATalentState::ParseKnownEntriesUpload(body.data(), body.size(), upload))
    {
      LOG_WARN("module.ascension_compat", "Malformed Ascension known-entries upload from {} payload={} bytes",
               player->GetName(), body.size());
    }
    else
    {
      std::string error;
      if (!ApplyKnownEntriesUpload(player, upload, error))
      {
        ChatHandler(player->GetSession()).SendSysMessage(error);
        LOG_INFO("module.ascension_compat", "Refused known-entries upload of {} record(s) from {}: {}",
                 upload.size(), player->GetName(), error);
      }
    }
    SendCharacterAdvancementKnownEntries(player);
  }

  uint32 GetActiveSpecialization(Player const *player) const {
    std::lock_guard<std::mutex> lock(_stateLock);
    auto itr = _activeSpecializations.find(player->GetGUID().GetCounter());
    return itr == _activeSpecializations.end() ? 0 : itr->second;
  }

  // --- Stored builds ----------------------------------------------------------
  //
  // Ascension keeps a build per specialization and swaps between them. Here a switch removes every
  // talent spell, so the build being left is written down first and the build of the specialization
  // being entered is put back afterwards: the class tree, which every specialization shares, and the
  // specialization's own tree. The spellbook stays the truth while a specialization is active; the
  // record is only read when one is entered. Player setting "core.ascension_build.<spec>" (0 for the
  // class tree): index 0 holds the count, then entryId * 10 + rank per pick (from #4031).

  static std::string BuildSetting(uint32 specializationId)
  {
    return std::string(ASCENSION_TALENT_BUILD_SETTING_PREFIX) + std::to_string(specializationId);
  }

  /// The paid and free-choice ranks the spellbook holds on one tree, as entryId * 10 + rank.
  static std::vector<uint32> LivePicks(Player const* player, uint32 specializationId)
  {
    std::vector<uint32> picks;
    for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
    {
      if (entry.ClassId != player->getClass() || entry.SpecId != specializationId ||
          (!entry.AECost && !entry.TECost && !GetSelectableFreeGroup(entry.EntryId)))
        continue;
      if (uint32 const rank = AscensionCoATalentState::KnownRank(entry, SpellbookOf(player)))
        picks.push_back(entry.EntryId * 10 + rank);
    }
    return picks;
  }

  /// Writes a tree's picks over the previous record; a shorter build zeroes the old tail.
  static void StoreBuild(Player* player, uint32 specializationId, std::vector<uint32> const& picks)
  {
    std::string const setting = BuildSetting(specializationId);
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
    PlayerSettingVector const* values = player->FindPlayerSettings(BuildSetting(specializationId));
    if (!values || values->empty())
      return picks;

    std::size_t const count = std::min<std::size_t>((*values)[0].value, values->size() - 1);
    for (std::size_t index = 1; index <= count; ++index)
      if (uint32 const pick = (*values)[index].value)
        picks.push_back(pick);
    return picks;
  }

  /// Writes down the class tree and the tree of the specialization being left.
  void StoreBuilds(Player* player, uint32 specializationId)
  {
    StoreBuild(player, 0, LivePicks(player, 0));
    StoreBuild(player, specializationId, LivePicks(player, specializationId));
  }

  /// Puts back the class tree and the entered specialization's tree, each rank through the rules of a
  /// purchase, so a stored rank the character can no longer afford is skipped rather than granted.
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
        if (AscensionCoATalentState::KnownRank(*entry, SpellbookOf(player)) >= rank)
          continue;

        std::string error;
        if (SetTalentRank(player, *entry, rank, error))
          ++restored;
        else
          LOG_INFO("module.ascension_compat", "Stored talent entry {} rank {} not restored for {}: {}",
                   entry->EntryId, rank, player->GetName(), error);
      }
    return restored;
  }

  bool SwitchSpecialization(Player *player, uint32 specializationId) {
    if (!IsAscensionCustomClass(player) || !specializationId)
      return false;

    bool validSpecialization = std::any_of(
        AscensionCompatData::CoATalentEntries.begin(),
        AscensionCompatData::CoATalentEntries.end(),
        [player, specializationId](
            AscensionCompatData::CoATalentEntry const &entry) {
          return entry.ClassId == player->getClass() &&
                 entry.SpecId == specializationId;
        });
    if (!validSpecialization)
      return false;

    uint32 const previousSpecialization = GetActiveSpecialization(player);
    if (!previousSpecialization || previousSpecialization == specializationId)
    {
      {
        std::lock_guard<std::mutex> lock(_stateLock);
        _activeSpecializations[player->GetGUID().GetCounter()] = specializationId;
      }
      player->UpdatePlayerSetting(ASCENSION_ACTIVE_SPEC_SETTING, 0, specializationId);

      uint32 const restored = previousSpecialization ? 0 : RestoreBuilds(player, specializationId);
      uint32 granted = SynchronizeProgression(player);
      LOG_INFO("module.ascension_compat",
               "Synchronized {} (class {}) with local specialization {}, restored {} stored rank(s) and "
               "granted {} missing automatic spells",
               player->GetName(), uint32(player->getClass()), specializationId, restored, granted);
      return true;
    }

    // The build being left survives only as a record: write it before its spells go.
    StoreBuilds(player, previousSpecialization);

    // Like Player::ActivateSpec, dismiss the pet summoned under the old specialization.
    if (Pet* pet = player->GetPet())
      player->RemovePet(pet, PET_SAVE_NOT_IN_SLOT);

    std::unordered_set<uint32> visitedSpellIds;
    uint32 removed = 0;
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

    {
      std::lock_guard<std::mutex> lock(_stateLock);
      _activeSpecializations[player->GetGUID().GetCounter()] = specializationId;
    }
    player->UpdatePlayerSetting(ASCENSION_ACTIVE_SPEC_SETTING, 0, specializationId);

    uint32 const restored = RestoreBuilds(player, specializationId);
    uint32 granted = SynchronizeProgression(player);
    ChatHandler(player->GetSession())
        .PSendSysMessage(
            "Activated specialization {}. Stored the build of specialization {}, removed {} old talent "
            "spell(s), restored {} stored rank(s) and granted {} automatic ability/passive spell(s).",
            specializationId, previousSpecialization, removed, restored, granted);
    LOG_INFO("module.ascension_compat",
             "Switched {} (class {}) to local specialization {}: removed {} CoA spells, restored {} "
             "stored ranks and granted {} automatic spells",
             player->GetName(), uint32(player->getClass()), specializationId, removed, restored, granted);
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
    _pendingUploads.erase(player->GetSession()->GetAccountId());
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
        if (entry.ClassId != player->getClass() ||
            (entry.SpecId != 0 && entry.SpecId != specializationId) ||
            entry.AECost != 0 || entry.TECost != 0 ||
            entry.RequiredLevel > player->GetLevel() || !entry.SpellCount || GetSelectableFreeGroup(entry.EntryId))
            return false;

        auto const& dependencies = AscensionCompatData::CoAAutomaticDependencies;
        auto dependency = std::lower_bound(dependencies.begin(), dependencies.end(), entry.EntryId,
            [](AscensionCompatData::CoAAutomaticDependency const& value, uint32 id)
            {
                return value.EntryId < id;
            });
        if (dependency == dependencies.end() || dependency->EntryId != entry.EntryId)
            return true;

        for (uint32 requiredId : dependency->RequiredEntryIds)
        {
            if (!requiredId)
                continue;

            auto const& entries = AscensionCompatData::CoATalentEntries;
            auto required = std::lower_bound(entries.begin(), entries.end(), requiredId,
                [](AscensionCompatData::CoATalentEntry const& value, uint32 id)
                {
                    return value.EntryId < id;
                });
            if (required == entries.end() || required->EntryId != requiredId ||
                required->ClassId != player->getClass() ||
                !std::any_of(required->SpellIds.begin(), required->SpellIds.end(),
                    [player](uint32 spellId) { return spellId && player->HasSpell(spellId); }))
                return false;
        }
        return true;
    }

    static void ReconcileRunemasterFists(Player* player, uint32 specializationId)
    {
        // An unconfirmed custom specialization cannot disprove a saved identity.
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

        // Preserve native HasSpell eligibility, including an inactive Zenith or
        // a temporary prerequisite. Acquisition still uses normal progression.
        if (!CanGrantAutomaticEntry(player, *fists, specializationId) && player->HasSpell(92153))
            player->removeSpell(92153, player->GetActiveSpecMask(), false);
    }

private:
    static uint32 SynchronizeAutomaticTalents(Player* player, uint32 specializationId)
    {
        // At level one the observed spellbook, not empty implicit/CAD responses,
        // defines the baseline. Higher-level dependency-gated talents remain native.
        if (player->GetLevel() == 1)
            return 0;
        uint32 learned = 0;
        bool changed = true;
        // Resolve dependencies even when their entry IDs sort after their children.
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

  // One service for every player, and player updates run on several map threads at once: every
  // access to the three containers below goes through this lock. Without it a concurrent insert
  // corrupts the hash table and a later lookup loops forever, which stops the whole world.
  mutable std::mutex _stateLock;
  std::unordered_map<ObjectGuid, uint32> _tuningUpdates;
  std::unordered_map<uint32, uint32> _activeSpecializations;
  std::unordered_set<uint32> _proficiencySynchronizations;
  // Characters owed the character-advancement state, and those already holding it.
  std::unordered_set<uint32> _advancementPending;
  std::unordered_set<uint32> _advancementSent;
  // Known-entries uploads by account, copied off the network thread for the player's own update.
  static constexpr std::size_t MAX_QUEUED_KNOWN_ENTRIES_UPLOADS = 8;
  std::unordered_map<uint32, std::deque<std::vector<uint8>>> _pendingUploads;
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
                    LOG_ERROR("module.ascension_compat",
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

        for (AscensionCompatData::ResourceGainRule const& rule :
             AscensionCompatData::ResourceGainRules)
        {
            validateResourceSpell(rule.ResourceSpellId);
            validateResourceSpell(rule.RequiredAuraSpellId);
            validateResourceSpell(rule.ForbiddenAuraSpellId);
            if (rule.ChancePercent > 100)
            {
                LOG_ERROR("module.ascension_compat",
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
                    LOG_ERROR("module.ascension_compat",
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
            if (rule.PowerType >= MAX_POWERS)
            {
                LOG_ERROR("module.ascension_compat",
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
                    LOG_ERROR("module.ascension_compat",
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
                LOG_ERROR("module.ascension_compat",
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
                    LOG_ERROR("module.ascension_compat",
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
                LOG_ERROR("module.ascension_compat",
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
                    LOG_ERROR("module.ascension_compat",
                        "Ascension Reaper one-soul consumer spell {} is missing from the server DBC",
                        spellId);
                    ++missingAbilitySpells;
                }
            }
        }

        LOG_INFO("module.ascension_compat",
            "Validated {} custom resource auras and spell helpers; {} resource spells and {} mapped abilities are missing",
            checkedResourceSpells.size(), missingResourceSpells,
            missingAbilitySpells);
    }

    void OnPlayerLogin(Player* player) const
    {
        _lastClientResourceStates.erase(player->GetGUID().GetCounter());
        _staticDecayTimers.erase(player->GetGUID());
        if (IsAscensionCustomClass(player))
        {
            SynchronizeThresholdResources(player);
            SendClientState(player, true);
        }
    }

    void OnPlayerUpdate(Player* player, uint32 diff) const
    {
        if (IsAscensionCustomClass(player))
        {
            DecayStatic(player, diff);
            SynchronizeThresholdResources(player);
            SendClientState(player, false);
        }
    }

    void OnPlayerLogout(Player* player) const
    {
        if (player)
        {
            _lastClientResourceStates.erase(player->GetGUID().GetCounter());
            _staticDecayTimers.erase(player->GetGUID());
        }
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

        // Soul Fragment schedules this helper after every gained fragment.
        // Ascension's private dummy handler only lets the helper continue at
        // three stacks; without this gate every fragment becomes a full soul.
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
            // The copied Ranger records carry the correct Advantage contract,
            // but the proprietary realm also enforced it before the normal
            // cast pipeline. Keep a compatibility-side guard so every rank and
            // talent consumer follows the same requirement.
            result = SPELL_FAILED_CASTER_AURASTATE;
            return;
        }

        if (player->getClass() == CLASS_REAPER && spellId == SPELL_REAPER_SCYTHE_RUSH)
        {
            // "Cannot be used on the same target more than once every 20 sec."
            // 500359's own ExcludeTargetAuraSpell is empty, and the native
            // field would also ignore the aura's caster, locking every other
            // Reaper out of a target one of them has already rushed. Keep the
            // marker's own per-caster scope instead.
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
            }
            else if (rule.Consumption ==
                     AscensionCompatData::ResourceConsumption::All)
            {
                player->RemoveAurasDueToSpell(rule.ResourceSpellId);
            }
            break;
        }

        ConsumeReaperSouls(player, spell);
        SynchronizeThresholdResources(player);
        SendClientState(player, false);
    }

    // Whether this spell is one that deals damage at all.
    //
    // The damage figure this hook receives is what survived the target's mitigation, and a training
    // dummy zeroes it outright - npc_training_dummy::DamageTaken sets damage = 0 on every hit. So a
    // Reaper checking a rotation on a dummy generated no Soul Fragments and no Runic Power from Reap
    // or Wraithblade, while the same casts worked on a real target. Resource generation is a
    // property of the ability, not of what the target did with the damage, so read it off the spell.
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
        // This hook runs after damage. Keep killing blows and neutral/yellow
        // enemies eligible without accepting friendly or self targets.
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

            player->ModifyPower(static_cast<Powers>(rule.PowerType),
                rule.InternalAmount);
            changed = true;
        }

        if (changed)
        {
            SynchronizeThresholdResources(player);
            SendClientState(player, false);
        }
    }

    void OnPeriodicDamageTick(Unit* target, Unit* attacker, uint32 damage,
        SpellInfo const* spellInfo) const
    {
        if (!target || !attacker || !damage || !spellInfo)
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
        {
            SynchronizeThresholdResources(player);
            SendClientState(player, false);
        }
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
        {
            SynchronizeThresholdResources(player);
            SendClientState(player, false);
        }
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

    void SendClientState(Player* player, bool force) const
    {
        if (!player || player->getClass() != CLASS_REAPER ||
            !player->GetSession())
            return;

        uint8 souls = GetAuraStacks(player, SPELL_REAPER_REAPED_SOUL);
        uint8 fragments = GetAuraStacks(player, SPELL_REAPER_SOUL_FRAGMENT);
        bool infused = player->HasAura(SPELL_REAPER_SOUL_INFUSION);
        uint32 runicPower = std::max<int32>(
            0, player->GetPower(POWER_RUNIC_POWER));
        uint32 maximumRunicPower = std::max<int32>(
            0, player->GetMaxPower(POWER_RUNIC_POWER));

        // A packed comparison key keeps the per-tick synchronization silent
        // unless the authoritative server-side resource state changed.
        uint64 packedState = uint64(souls) |
            (uint64(fragments) << 8) |
            (uint64(infused ? 1 : 0) << 16) |
            (uint64(runicPower) << 17) |
            (uint64(maximumRunicPower) << 37);
        uint32 guid = player->GetGUID().GetCounter();
        auto previous = _lastClientResourceStates.find(guid);
        if (!force && previous != _lastClientResourceStates.end() &&
            previous->second == packedState)
            return;

        _lastClientResourceStates[guid] = packedState;

        std::string message = ASCENSION_LOCAL_RESOURCE_PREFIX;
        message += "\tR:" + std::to_string(uint32(souls));
        message += ":" + std::to_string(uint32(fragments));
        message += ":" + std::to_string(infused ? 1 : 0);
        message += ":" + std::to_string(runicPower);
        message += ":" + std::to_string(maximumRunicPower);

        WorldPacket packet;
        // Use the GUID overload explicitly.  The WorldObject overload turns
        // messages sent by a GM account into SMSG_GM_MESSAGECHAT, which does
        // not reach Lua as CHAT_MSG_ADDON on this client.
        ChatHandler::BuildChatPacket(packet, CHAT_MSG_WHISPER, LANG_ADDON,
            player->GetGUID(), player->GetGUID(), message, 0,
            player->GetName(), player->GetName(), 0, false);
        player->GetSession()->SendPacket(&packet);

        LOG_INFO("module.ascension_compat",
            "Sent Reaper resource state to {}: souls={}, fragments={}, infused={}, runic={}/{}",
            player->GetName(), uint32(souls), uint32(fragments), infused,
            runicPower, maximumRunicPower);
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

    // Harvest Time's tooltip is specific: it is about Soul Infusion, the buff its own effect names.
    // Only a spell that requires Soul Infusion (CasterAuraSpell 803031) is therefore exempt. An
    // ability paid for with Reaped Souls alone still pays - Sanguine Orb (500361) and Tormented
    // Souls (500483) both carry CasterAuraSpell 500363, Reaped Soul, so an unscoped exemption made
    // them free for a Reaper holding a single soul and no infusion at all.
    static bool HarvestTimePreserves(Player const* player, SpellInfo const* spellInfo)
    {
        return spellInfo->CasterAuraSpell == SPELL_REAPER_SOUL_INFUSION &&
            player->HasAura(SPELL_REAPER_HARVEST_TIME);
    }

    // True when the spell had at least one target other than the caster and every such target
    // missed, dodged or parried it. Neutral creatures count: hostility is not required to attack.
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

    static void ConsumeReaperSouls(Player* player, Spell* spell)
    {
        if (player->getClass() != CLASS_REAPER)
            return;

        SpellInfo const* spellInfo = spell->GetSpellInfo();

        // Harvest Time preserves the cost outright rather than rolling for it. An eight second
        // window a Reaper can plan a rotation around is what the ability is for; a coin flip per
        // cast is not something the player can act on.
        if (HarvestTimePreserves(player, spellInfo))
            return;

        uint32 spellId = spellInfo->Id;
        if (std::find(REAPER_ALL_SOUL_CONSUMERS.begin(),
                REAPER_ALL_SOUL_CONSUMERS.end(), spellId) !=
            REAPER_ALL_SOUL_CONSUMERS.end())
        {
            player->RemoveAurasDueToSpell(SPELL_REAPER_REAPED_SOUL);
            player->RemoveAurasDueToSpell(SPELL_REAPER_SOUL_INFUSION);
            return;
        }

        // Abilities that require Soul Infusion consume it together with the souls that granted it.
        // The 2026-07-31 changelog refunds the cost when the spell misses, is dodged or parried;
        // target results are already rolled when this runs, so an avoided cast keeps everything.
        if (spellInfo->CasterAuraSpell == SPELL_REAPER_SOUL_INFUSION &&
            player->HasAura(SPELL_REAPER_SOUL_INFUSION) &&
            !WasAvoidedByEveryTarget(player, spell))
        {
            player->CastSpell(player, SPELL_REAPER_SOUL_INFUSION_REMOVER, true);
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

        // Preserve Static for five seconds out of combat, then lose one per second.
        // The rate is a local tuning choice; the archived changelog only establishes the grace period.
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
        }
    }

    mutable std::unordered_map<uint32, uint64> _lastClientResourceStates;
    mutable std::unordered_map<ObjectGuid, uint32> _staticDecayTimers;
};

class AscensionCollectionService {
public:
    static bool IsCosmeticCategory(uint32 category)
    {
        return category >= 56 && category <= 58;
    }

    static uint32 ResolveCosmeticSpell(uint32 appearance, uint32 display, uint32 alternate)
    {
        // These three catalog entries have no usable spell in the supplied client data.
        if (appearance == 2992 || appearance == 51444 || appearance == 52428)
            return 0;
        if (appearance == 2714)
            display = 985235; // Noir Clockwork Steam Engine
        if (appearance == 42965)
            display = 935566; // Scribe's Noble Parchment Pouch
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
            // Follow cosmetic wrappers without casting their gameplay effects or implicit targets.
            if (effect.IsAura() && (effect.ApplyAuraName == SPELL_AURA_DUMMY ||
                effect.ApplyAuraName == SPELL_AURA_MOD_SCALE ||
                (display == 1985213 && effect.ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL)))
                return display;
            return 0;
        }
        return 0;
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
      _allAppearanceIds.push_back(appearanceId);
    }

    ClientDBC itemAppearances;
    bool itemAppearancesLoaded =
        itemAppearances.Load(GetClientDBCPath("ItemAppearances.dbc"), 3);
    for (uint32 row = 0; row < itemAppearances.GetRecordCount(); ++row) {
      ClientDBC::Record record = itemAppearances.GetRecord(row);
      uint32 itemId = record.GetUInt32(1);
      uint32 appearanceId = record.GetUInt32(2);
      if (itemId && appearanceId)
        _itemAppearances[itemId] = appearanceId;
    }

    // The core's ItemSet store keeps ten items; CoA sets list up to seventeen (DWORDs 18-34).
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
          // f44 is an empty locale column. The physical
          // record has 77 DWORDs; f76 is LearnedSpell.
          record.GetUInt32(76), record.GetUInt32(12), record.GetUInt32(2)};

      // The same row is what the client stores as a vanity store record,
      // so the packet is built from it rather than from a second table.
      for (uint32 field = 0; field < VANITY_STORE_RECORD_DWORDS; ++field)
        info.StoreRecord[field] = record.GetUInt32(field);

      _vanityItems[itemId] = info;
      _allVanityItemIds.push_back(itemId);
    }

    std::sort(_allAppearanceIds.begin(), _allAppearanceIds.end());
    _allAppearanceIds.erase(
        std::unique(_allAppearanceIds.begin(), _allAppearanceIds.end()),
        _allAppearanceIds.end());

    LOG_INFO("module.ascension_compat",
             "Loaded Ascension collection data: {} appearances, {} item "
             "mappings, {} item sets, {} vanity entries",
             _appearances.size(), _itemAppearances.size(),
             _itemSetItems.size(), _vanityItems.size());

    if (!itemSetsLoaded)
      LOG_WARN("module.ascension_compat",
               "Ascension item-set expansion is unavailable; individual "
               "appearance categories remain usable");

    _clientDataLoaded =
        appearancesLoaded && itemAppearancesLoaded && vanityLoaded;
    return _clientDataLoaded;
  }

  void QueueClientPacket(uint32 accountId, WorldPacket const &packet) {
    std::lock_guard lock(_packetMutex);
    std::deque<WorldPacket> &queue = _pendingPackets[accountId];
    if (queue.size() >= MAX_QUEUED_EXTENSION_PACKETS)
    {
      LOG_WARN("module.ascension_compat",
               "Dropping Ascension extension packet 0x{:04X} for account {} "
               "because its queue is full",
               packet.GetOpcode(), accountId);
      return;
    }

    queue.emplace_back(packet);
  }

  void OnPlayerLogin(Player *player) {
    if (!_clientDataLoaded)
    {
      ChatHandler(player->GetSession())
          .SendSysMessage("Ascension collection data is unavailable; transmog "
                          "and vanity are disabled.");
      return;
    }

    std::shared_ptr<PlayerCollectionState> state =
        std::make_shared<PlayerCollectionState>();
    state->AccountId = player->GetSession()->GetAccountId();
    LoadPlayerState(player, *state);

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
    SendOutfitCollection(player);
    SendAppearanceVisibility(player, *state);
    SendVanityCollection(player, *state);
    SendOwnedVanityStoreRecords(player, *state);
    RefreshVisibleItems(player);
    // Reconcile any aura saved by an older session against the authoritative wardrobe selection.
    for (auto const& [id, appearance] : _appearances)
        if (appearance.CosmeticSpell)
            player->RemoveAurasDueToSpell(appearance.CosmeticSpell, player->GetGUID());
    RefreshCosmetics(player, *state);
    InitializeRiding(player);
    QueueOwnedCompanionSpells(player, *state);

    LOG_INFO("module.ascension_compat",
             "Synchronized Ascension collections for {}: {} appearances, {} "
             "saved vanity items",
             player->GetName(), state->CollectedAppearances.size(),
             state->OwnedVanityItems.size());
  }

  void OnPlayerLogout(Player *player) {
    {
      std::lock_guard lock(_stateMutex);
      _playerStates.erase(player->GetGUID().GetCounter());
    }

    std::lock_guard lock(_packetMutex);
    _pendingPackets.erase(player->GetSession()->GetAccountId());
  }

  void OnPlayerUpdate(Player *player, uint32 diff) {
    std::deque<WorldPacket> packets;
    uint32 accountId = player->GetSession()->GetAccountId();
    {
      std::lock_guard lock(_packetMutex);
      auto itr = _pendingPackets.find(accountId);
      if (itr != _pendingPackets.end())
      {
        packets = std::move(itr->second);
        _pendingPackets.erase(itr);
      }
    }

    for (WorldPacket &packet : packets)
      HandleClientPacket(player, packet);

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

        // Lootbot 3000 grants auto-loot when summoned without requiring the appearance collected.
        // It does not provide skinning.
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

        // Permanent riding ranks, not profession/weapon skills or talent grants.
        // Learning the ranks also activates the client's riding spellbook entries.
        for (uint32 spellId : {SPELL_RIDING_APPRENTICE, SPELL_RIDING_JOURNEYMAN,
            SPELL_RIDING_EXPERT, SPELL_RIDING_ARTISAN, SPELL_COLD_WEATHER_FLYING})
            if (sSpellMgr->GetSpellInfo(spellId) && !player->HasSpell(spellId))
                player->learnSpell(spellId, false);

        player->SetSkill(SKILL_RIDING, 4, 300, 300);
    }

    // This hook runs after the normal spellbook snapshot but before AddToMap.
    // Replace that snapshot once if necessary; learnSpell does not emit a
    // separate learned-spell packet while the player is outside the world.
    void PrepareOwnedCompanionsBeforeMap(Player* player)
    {
        if (!_clientDataLoaded || player->IsInWorld() || !player->GetSession()->PlayerLoading() ||
            !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::LEARN_OWNED_COMPANIONS))
            return;

        PlayerCollectionState state;
        state.AccountId = player->GetSession()->GetAccountId();
        LoadPlayerState(player, state);
        std::vector<uint32> const spells = GetMissingOwnedCompanionSpells(player, state);
        std::size_t learned = 0;
        for (uint32 spellId : spells)
        {
            player->learnSpell(spellId, false);
            if (!player->HasSpell(spellId))
                continue;

            // The grant lands inside the login window, so Player::_addSpell records it as PLAYERSPELL_UNCHANGED
            // and Player::_SaveSpells skips it. Without a character_spell row the next login validates the saved
            // action buttons before this hook runs, so mount and companion buttons are dropped and deleted.
            player->MarkSpellForSave(spellId);
            ++learned;
        }

        if (learned)
        {
            player->SendInitialSpells();
            LOG_INFO("module.ascension_compat", "Prepared {} account mount/companion spells for {} before entering the world",
                learned, player->GetName());
        }
    }

    /// The bank items this repack ships - the two Personal Bank entries, the Celestial and the
    /// Realm Bank. Their first spell is the summon that places the vault, so the spell is read
    /// from the item template instead of being written out a second time here.
    static constexpr std::array<uint32, 4> BankVanityItems = { 110000, 134985, 509892, 1180097 };

    [[nodiscard]] static bool IsBankVanityItem(uint32 itemId)
    {
        return std::find(BankVanityItems.begin(), BankVanityItems.end(), itemId) != BankVanityItems.end();
    }

    /// Has this character acquired that bank?
    ///
    /// A bank is earned rather than part of the unlock-everything placeholder. Acquiring one -
    /// the purchase on the live realm - writes the account's own collection row, and the character
    /// then also holds it as the summon spell or as the item in a bag. Either way of holding it
    /// counts, so a bank granted by hand (the spell learned, or the item handed over) behaves
    /// exactly like one bought, and AscensionCompat.UnlockAllVanity is deliberately never
    /// consulted here.
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

    /// The summon spells of the banks this character owns, for every one not already learned.
    ///
    /// Learning the spell is the other half of owning a bank: the spell places the same vault the
    /// item does, so a character who has one can summon it without carrying the item, and it is
    /// what the placed-chest entitlement reads.
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

    /// Learns an owned bank's summon spell. Used both on the way into the world and at the moment
    /// a bank item reaches a character.
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

        // Outside the world the learned-spell snapshot has not been sent yet, so it has to be
        // replaced once; in the world learnSpell emits its own learned-spell packet.
        if (beforeMap)
            player->SendInitialSpells();

        LOG_INFO("module.ascension_compat", "Learned {} owned bank spell(s) for {}",
                 learned, player->GetName());
    }

    /// Same place the companion spells are prepared, and for the same reason: the client's spell
    /// list has not been sent yet, so a grant here needs no batching or UI thaw.
    void PrepareOwnedBankSpellsBeforeMap(Player* player)
    {
        if (!_clientDataLoaded || player->IsInWorld() || !player->GetSession()->PlayerLoading())
            return;

        // The account's own list is what says a bank was acquired, so it is always read - this
        // grant, unlike the mount and companion ones, does not follow the unlock-everything
        // placeholder.
        PlayerCollectionState state;
        state.AccountId = player->GetSession()->GetAccountId();
        LoadPlayerState(player, state);

        LearnOwnedBankSpells(player, state, true);
    }

    std::vector<uint32> GetMissingOwnedCompanionSpells(Player* player, PlayerCollectionState const& state) const
    {
        std::vector<uint32> spells;
        if (!ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::LEARN_OWNED_COMPANIONS))
            return spells;

        bool const unlockAll = ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::UNLOCK_ALL_VANITY);
        for (auto const& [itemId, vanity] : _vanityItems)
        {
            if (!(vanity.CategoryMask & (VANITY_CATEGORY_MOUNTS | VANITY_CATEGORY_COMPANIONS)) ||
                (!unlockAll && !state.OwnedVanityItems.contains(itemId)) ||
                std::binary_search(AscensionCollectibles::SigilSpells.begin(),
                    AscensionCollectibles::SigilSpells.end(), vanity.LearnedSpell) ||
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
        // Retain bounded late synchronization for any grant not prepared at login.
        state.PendingCompanionSpells = GetMissingOwnedCompanionSpells(player, state);
        state.CompanionSpellTimer = 5000;
        if (!state.PendingCompanionSpells.empty())
            LOG_INFO("module.ascension_compat", "Queued {} owned mount/companion spells for {} (4 per 200 ms)",
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

        // Never catch up by draining the whole list after a slow server tick.
        // Each learned spell emits client events; a bulk grant can freeze its UI.
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
            LOG_INFO("module.ascension_compat", "Completed owned mount/companion spell synchronization for {}", player->GetName());
            state->PendingCompanionSpells.clear();
            state->NextCompanionSpell = 0;
        }
    }

  void OnItemObtained(Player *player, Item *item) {
    if (!item)
      return;

    std::shared_ptr<PlayerCollectionState> state = GetState(player);
    if (!state)
      return;

    CollectItem(player, *state, item->GetEntry(), true);
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

  void ApplyLocalAppearance(Player *player, uint32 categoryId,
                            uint32 appearanceId) {
    std::shared_ptr<PlayerCollectionState> state = GetState(player);
    if (!state)
      return;

    if (!categoryId || categoryId >= state->ActiveAppearances.size())
    {
      SendApplyResult(player, "APPLY_APPEARANCES_INVALID_CATEGORY");
      return;
    }

    if (appearanceId)
    {
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
          IsCosmeticCategory(categoryId)) &&
          appearance.PrimaryCategory != categoryId &&
          appearance.SecondaryCategory != categoryId &&
          appearance.TertiaryCategory != categoryId) {
        SendApplyResult(player, "APPLY_APPEARANCES_INVALID_CATEGORY");
        return;
      }

      if (IsCosmeticCategory(categoryId) && !appearance.CosmeticSpell)
      {
        SendApplyResult(player, "APPLY_APPEARANCES_INVALID_SELECTION");
        return;
      }

      if (categoryId == 55 &&
          !ExpandItemSetAppearance(state->ActiveAppearances, appearanceId)) {
        SendApplyResult(player, "APPLY_APPEARANCES_INVALID_SELECTION");
        return;
      }
    }

    state->ActiveAppearances[categoryId] = appearanceId;
    SaveActiveAppearances(player, *state);
    RefreshCosmetics(player, *state);
    RefreshVisibleItems(player);
    SendActiveAppearances(player, *state);
    SendApplyResult(player, "APPLY_APPEARANCES_OK");

    LOG_INFO("module.ascension_compat",
             "Applied local appearance {} to category {} for {}",
             appearanceId, categoryId, player->GetName());
  }

  void DeliverLocalVanityItem(Player *player, uint32 itemId) {
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

    bool unlockAll = ascensionCompatConfig.GetConfigValue<bool>(
        AscensionCompatConfig::UNLOCK_ALL_VANITY);

    // A bank has to be acquired before it can be delivered, even while the placeholder unlocks
    // everything else: the item is what an acquisition hands out, not a way to obtain the bank.
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
        AscensionCollectibles::SigilVanityItems.end(), itemId))
    {
        ChatHandler(player->GetSession()).SendSysMessage("Sigil companions are excluded from local grants.");
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

      player->StoreNewItem(destinations, itemId, true);

      // A bank is also owned as a spell, so the spell comes with the item rather than at the next
      // login.
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
  void UnlockLocalAppearanceCatalog(Player *player,
                                    PlayerCollectionState &state) {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::UNLOCK_LOCAL_APPEARANCE_CATALOG))
      return;

    std::size_t before = state.CollectedAppearances.size();
    for (uint32 appearanceId : _allAppearanceIds)
      state.CollectedAppearances.insert(appearanceId);

    LOG_INFO("module.ascension_compat",
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
      LOG_INFO("module.ascension_compat", "Sent complete wardrobe snapshot for {}: {} appearances, no per-item login notifications",
          player->GetName(), appearances.size());
      return;
    }

    // A future catalog exceeding our explicit native allocation bound still
    // uses the throttled fallback. Do not split 0x0699 across packets: each
    // native snapshot replaces the previous collection instead of appending.
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

    LOG_INFO("module.ascension_compat",
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
      SendOutfitCollection(player);
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
    SendOutfitCollection(player);
    ChatHandler(player->GetSession())
        .PSendSysMessage("Unlocked all {} local wardrobe appearances.", total);

    LOG_INFO("module.ascension_compat",
             "Completed full wardrobe sync for {}: {} appearances",
             player->GetName(), total);
  }

  std::shared_ptr<PlayerCollectionState> GetState(Player const *player) {
    std::lock_guard lock(_stateMutex);
    auto itr = _playerStates.find(player->GetGUID().GetCounter());
    return itr != _playerStates.end() ? itr->second : nullptr;
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
        CollectItem(player, state, item->GetEntry(), false);
    }

    for (uint8 bagSlot = INVENTORY_SLOT_BAG_START;
         bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot) {
      Bag *bag = player->GetBagByPos(bagSlot);
      if (!bag)
        continue;

      for (uint32 slot = 0; slot < bag->GetBagSize(); ++slot) {
        if (Item *item = bag->GetItemByPos(slot))
          CollectItem(player, state, item->GetEntry(), false);
      }
    }
  }

  void CollectItem(Player *player, PlayerCollectionState &state, uint32 itemId,
                   bool notifyClient) {
    auto mappingItr = _itemAppearances.find(itemId);
    if (mappingItr != _itemAppearances.end())
    {
      uint32 appearanceId = mappingItr->second;
      if (_appearances.contains(appearanceId) &&
          state.CollectedAppearances.insert(appearanceId).second) {
        CharacterDatabase.Execute(
            "INSERT IGNORE INTO `account_appearance_collection` (`account_id`, "
            "`appearance_id`, `source_item`) "
            "VALUES ({}, {}, {})",
            state.AccountId, appearanceId, itemId);

        if (notifyClient)
          SendAppearanceAdded(player, appearanceId, itemId);
      }
    }

    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::UNLOCK_ALL_VANITY) &&
        _vanityItems.contains(itemId) &&
        state.OwnedVanityItems.insert(itemId).second) {
      CharacterDatabase.Execute(
          "INSERT IGNORE INTO `account_vanity_collection` (`account_id`, "
          "`item_id`) VALUES ({}, {})",
          state.AccountId, itemId);

      if (notifyClient)
      {
        WorldPacket packet(SMSG_VANITY_COLLECTION_ADDED, sizeof(uint32));
        packet << itemId;
        player->GetSession()->SendPacket(&packet);
      }
    }

    // Banks are acquired rather than covered by the placeholder, so their account record is
    // written whatever UnlockAllVanity says. This is the record a purchase leaves, and it is what
    // the login grant and the placed-chest entitlement both read - which makes the bank item
    // itself the thing that "learns" the bank: handing 134985, 509892 or 1180097 to a character
    // is the acquisition, and the spell follows immediately rather than at the next login.
    if (IsBankVanityItem(itemId) && state.OwnedVanityItems.insert(itemId).second)
    {
      CharacterDatabase.Execute(
          "INSERT IGNORE INTO `account_vanity_collection` (`account_id`, "
          "`item_id`) VALUES ({}, {})",
          state.AccountId, itemId);

      if (notifyClient)
      {
        WorldPacket packet(SMSG_VANITY_COLLECTION_ADDED, sizeof(uint32));
        packet << itemId;
        player->GetSession()->SendPacket(&packet);
      }

      LearnOwnedBankSpells(player, state, !player->IsInWorld());
      SendOwnedVanityStoreRecords(player, state);
      LOG_INFO("module.ascension_compat", "Account {} acquired the bank item {} through {}",
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
      default:
        break;
      }
    } catch (ByteBufferException const &) {
      LOG_WARN("module.ascension_compat",
               "Malformed Ascension extension packet opcode=0x{:04X} from {}",
               packet.GetOpcode(), player->GetName());
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
          IsCosmeticCategory(categoryId)) &&
          appearance.PrimaryCategory != categoryId &&
          appearance.SecondaryCategory != categoryId &&
          appearance.TertiaryCategory != categoryId) {
        SendApplyResult(player, "APPLY_APPEARANCES_INVALID_CATEGORY");
        return;
      }
      if (IsCosmeticCategory(categoryId) && !appearance.CosmeticSpell)
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

    state->ActiveAppearances = requested;
    SaveActiveAppearances(player, *state);
    RefreshCosmetics(player, *state);
    RefreshVisibleItems(player);
    SendApplyResult(player, "APPLY_APPEARANCES_OK");
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

  void SendOutfitCollection(Player *player)
  {
    // The 0x069D handler clears/rebuilds the client's saved-outfit map and,
    // importantly, finalizes the filtered appearance cache by firing
    // VIEWABLE_APPEARANCES_RESET.  The local server does not persist named
    // outfits yet, but it must still send an empty snapshot after collection
    // and active-appearance data or the Wardrobe remains on its pre-login
    // empty page despite showing correct collected/total counts.
    WorldPacket packet(SMSG_APPEARANCE_OUTFIT_INFO, sizeof(uint32));
    packet << static_cast<uint32>(0);
    player->GetSession()->SendPacket(&packet);
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

      // The banks are the exception to the placeholder: each is acquired on its own, so the client
      // is told the account owns a bank only when it really does - nobody is offered a bank the
      // account never acquired.
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

    std::sort(vanityItems.begin(), vanityItems.end());
    vanityItems.erase(std::unique(vanityItems.begin(), vanityItems.end()), vanityItems.end());
    WorldPacket packet(SMSG_VANITY_COLLECTION_INFO,
                       sizeof(uint32) + vanityItems.size() * sizeof(uint32));
    packet << static_cast<uint32>(vanityItems.size());
    for (uint32 itemId : vanityItems)
      packet << itemId;

    player->GetSession()->SendPacket(&packet);
  }

  /// Hands the client the store records for the vanity items the account owns.
  ///
  /// Sent with the ownership list, so the two agree about what the account owns. The records come
  /// from the same catalogue rows the ownership list is built from.
  void SendOwnedVanityStoreRecords(Player *player,
                                   PlayerCollectionState const &state) {
    std::vector<uint32> itemIds;
    for (uint32 itemId : state.OwnedVanityItems)
      if (_vanityItems.contains(itemId))
        itemIds.push_back(itemId);

    std::sort(itemIds.begin(), itemIds.end());
    itemIds.erase(std::unique(itemIds.begin(), itemIds.end()), itemIds.end());

    WorldPacket packet(SMSG_QUERY_CUSTOM_STORE_RESULT,
                       64 + itemIds.size() * VANITY_STORE_RECORD_DWORDS * sizeof(uint32));
    packet << "QUERY_CUSTOM_STORE_OK";
    packet << static_cast<uint32>(itemIds.size());
    for (uint32 itemId : itemIds)
      for (uint32 field : _vanityItems.at(itemId).StoreRecord)
        packet << field;

    player->GetSession()->SendPacket(&packet);

    if (!itemIds.empty())
    {
      std::string owned;
      for (uint32 itemId : itemIds) {
        if (!owned.empty())
          owned += ' ';
        owned += std::to_string(itemId);
      }

      LOG_INFO("module.ascension_compat",
               "Sent {} vanity store record(s) to {} for owned item(s): {}",
               itemIds.size(), player->GetName(), owned);
    }
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
                    // A selected wardrobe cosmetic lasts until removed, including finite source effects.
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

  std::mutex _packetMutex;
  std::unordered_map<uint32, std::deque<WorldPacket>> _pendingPackets;

  std::mutex _stateMutex;
  std::unordered_map<uint32, std::shared_ptr<PlayerCollectionState>>
      _playerStates;
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

    // Normal WotLK creature-query wire layout, mirrored from QueryHandler.
    // This provides preview metadata only; it does not spawn a creature or
    // invent combat stats/loot for an Ascension NPC absent from the world DB.
    WorldPacket response(SMSG_CREATURE_QUERY_RESPONSE, 100);
    response << creatureId << std::string(model->Name);
    for (uint8 i = 0; i < 5; ++i)
        response << uint8(0); // name2/3/4, title, icon
    response << uint32(0) << uint32(CREATURE_TYPE_CRITTER) << uint32(0);
    response << uint32(0) << uint32(0) << uint32(0); // rank, kill credits
    response << model->DisplayId << uint32(0) << uint32(0) << uint32(0);
    response << float(1.0f) << float(1.0f) << uint8(0);
    for (uint8 i = 0; i < 6; ++i)
        response << uint32(0); // quest items
    response << uint32(0); // movementId
    session->SendPacket(&response);
    return true;
}

// ---------------------------------------------------------------------------
// Personal bank, Celestial Personal Bank and Realm Bank.
//
// The three items are ordinary spell items (100702, 93416, 92078) whose spell
// carries a dummy effect - the client shows "Summons your personal bank" and the
// server is expected to do the rest. What it has to do is what the client was
// patched for: the item summons a guild vault object (gameobject type 34), and
// clicking that vault sends the ordinary CMSG_GUILD_BANKER_ACTIVATE. The client's
// Blizzard_GuildBankUI.lua then waits for SMSG_BANK_PERMISSIONS, whose payload
// its BANK_PERMISSIONS_PAYLOAD hook reads as GetBankPermissions() ->
// (isPersonalBank, isRealmBank), and switches the vault frame to the
// PERSONAL_BANK/REALM_BANK presentation: character-owned tabs, tab purchases,
// and soulbound items allowed in.
//
// The stock core answers that activate with ERR_GUILD_PLAYER_NOT_IN_GUILD for a
// character with no guild, so this module answers it instead - but only for the
// vaults its own summon spells placed, which are remembered here for as long as
// they live. Every other guild vault keeps the core's own handler untouched.
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

// The objects CoA itself uses for this feature, captured from its client as type
// 34 (the type the client opens a bank frame for): "Personal Belongings",
// "Celestial Personal Belongings" and "Realm Belongings". Two entries exist per
// faction, and their display ids are chests - 138006 alliancechest_01, 138007
// hordechest_01, and 8691 ul_chest_cosmic for the Celestial one. They are absent
// from this world database, so the module ships them (see this module's
// 2026_09_16_01_ascension_bank_objects.sql).
enum PersonalBankObject : uint32
{
    BANK_OBJECT_PERSONAL_ALLIANCE = 475001, // "Personal Belongings"
    BANK_OBJECT_PERSONAL_HORDE = 475002,    // "Personal Belongings"
    BANK_OBJECT_CELESTIAL = 80782,          // "Celestial Personal Belongings"
    BANK_OBJECT_REALM_ALLIANCE = 80159,     // "Realm Belongings"
    BANK_OBJECT_REALM_HORDE = 80160         // "Realm Belongings"
};

// How long a summoned vault stays in the world, and it is meant to match the items' own
// cooldown (item_template.spellcooldown_1 = 600000 ms): summon it, use it for ten minutes,
// and by the time the vault is gone the item is ready again.
//
// The unit is SECONDS, not milliseconds. `WorldObject::SummonGameObject` hands this straight to
// `GameObject::SetRespawnTime`, which does `m_respawnTime = GameTime::GetGameTime() + respawn`,
// and that second count is in seconds - so the old value of 5 * 60 * 1000 was read as 300000
// seconds, three and a half days, and a vault only ever went away when the worldserver did.
//
// The timer belongs to the map object, not to the session: nothing tears a summoned object down
// when its summoner logs out (the only removals are `GameObject::Delete` itself, spell cleanup
// and duels), so the ten minutes keep running while the character is offline and the vault
// despawns on its own whether or not they are there to see it.
constexpr uint32 BANK_VAULT_DURATION = 10 * 60;

/// The object the item summons: Celestial has its own, Realm and Personal bank
/// differ only by the caster's faction.
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
    // Two flags, read in this order by the client's GetBankPermissions().
    AscensionPersonalBank::SendKindHint(player, uint8(kind));
}

/// Whether this character owns the bank a placed vault stands for.
///
/// A bank is acquired, not part of the unlock-everything placeholder, so what counts is holding
/// it: the summon spell (what acquiring one grants) or the item itself in a bag (what handing the
/// bank item to a character gives them). AscensionCompat.UnlockAllVanity is deliberately not
/// consulted - nobody gets a bank from it. The Celestial item is its own object but a personal
/// bank underneath, so both personal entries count for the personal kind.
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

/// True when the packet was one of our own vaults and has been answered here.
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
        // A malformed activate is the core's problem to answer, with its own
        // error handling - never an exception out of the network thread here.
        return false;
    }

    auto itr = personalBankVaults.find(banker.GetCounter());
    if (itr == personalBankVaults.end())
        return false;

    // A placed bank belongs to whoever walks up to it, which is how CoA's own did it: the vault
    // only says *which* bank it is (its object entry), and the storage behind it is always the
    // interacting character's own - their personal bank, or the single realm-wide one. Someone
    // else's chest therefore opens your bank, not theirs. What entitles you to it is owning the
    // bank, not having placed this particular chest; the summoner is kept only for the record.
    if (!OwnsPlacedBank(player, itr->second.Kind))
    {
        ChatHandler(player->GetSession())
            .PSendSysMessage("You do not own a {} bank.",
                             itr->second.Kind == PERSONAL_BANK_REALM ? "Realm" : "Personal");
        LOG_INFO("module.ascension_compat",
                 "{} touched a {} bank placed by {} (vault {}) without owning one",
                 player->GetName(),
                 itr->second.Kind == PERSONAL_BANK_REALM ? "realm" : "personal",
                 itr->second.Owner.ToString(), banker.ToString());
        return true;
    }

    // The kind decides which bank this is; the storage behind it is the module's own
    // (AscensionPersonalBank.cpp), which sends the rights and the tab list itself.
    SendBankPermissions(player, itr->second.Kind);
    AscensionPersonalBank::Opened(player, itr->second.Kind, banker);

    LOG_INFO("module.ascension_compat",
             "Personal bank opened for {} (kind {}, vault {}, full update {})",
             player->GetName(), uint32(itr->second.Kind), banker.ToString(),
             fullUpdate);
    return true;
}

/// Height to summon the bank at: the caster's feet, snapped to a step within half a yard.
///
/// The map alone cannot be trusted for this. Measured in the inn where the bank kept landing
/// wrong, the caster's feet read 56.3-56.6 across nine summons while the surface under the
/// spot two yards ahead came back anywhere between 56.0 and 58.1 - that is the hillside the
/// building is cut into, not the floor the player is standing on, which is why every summon
/// landed somewhere different. A wider allowance let the hill set the height; a probe that
/// starts above the surface (which is what `WorldObject::GetMapHeight` does, since it adds
/// the object's collision height and Z_OFFSET_FIND_HEIGHT to the Z it is handed) makes it
/// worse, because `Map::GetHeight` then returns whichever surface is nearer the probe.
///
/// So the feet are the reference: probe just above them, and only move the bank when a surface
/// turns up within half a yard - a step, a kerb, a slight slope, which is the most it should
/// ever differ from where the caster is standing. Anything further away is another level of
/// the world (a roof, a cellar, the ground below a balcony) and is ignored.
static float GroundHeightBeneath(Map* map, float x, float y, float feetZ)
{
    constexpr float PROBE_ABOVE_FEET = 0.3f;    // just above the floor the caster stands on
    constexpr float STEP = 0.5f;                // a step away, either direction

    float const height = map->GetHeight(x, y, feetZ + PROBE_ABOVE_FEET, true, STEP);
    if (height > INVALID_HEIGHT && height <= feetZ + STEP && height >= feetZ - STEP)
        return height;

    return feetZ;
}

/// Puts the vault the item "summons" in front of the caster.
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

        // GetClosePoint only places the spot beside the caster: GetNearPoint ends with
        // `z = GetPositionZ()`, so the bank would keep the caster's height even where the
        // ground beside them is a step lower or higher. Ground it on the surface they are
        // standing on (see GroundHeightBeneath for why the probe starts at their feet).
        z = GroundHeightBeneath(player->GetMap(), x, y, player->GetPositionZ());

        // Summoned through the map rather than through the caster, and that is the whole point:
        // `WorldObject::SummonGameObject` files the object under its summoner (`Unit::AddGameObject`),
        // and `Unit::RemoveFromWorld` - which is what a logout runs - calls `RemoveAllGameObjects`
        // and deletes every object filed there. A vault summoned by the player therefore vanished the
        // moment they left the world. A map summon has no owner at all, so nothing tears it down
        // early, and the core still gives it exactly the timed life below: `Map::SummonGameObject`
        // marks it temporary (`SetSpellId(1)` + respawn time), and at expiry `GameObject::Update`
        // sees a summoned object whose timer has run out and deletes it.
        //
        // The phase mask is copied from the caster afterwards, because a map summon is created in
        // PHASEMASK_NORMAL - without this the vault would be invisible to anyone standing in a
        // phase of their own.
        GameObject* vault = player->GetMap()->SummonGameObject(
            entry, x, y, z, player->GetOrientation(), 0.0f, 0.0f, 0.0f,
            0.0f, BANK_VAULT_DURATION, true);
        if (vault)
            vault->SetPhaseMask(player->GetPhaseMask(), true);

        if (!vault)
        {
            LOG_ERROR("module.ascension_compat",
                      "Could not summon bank object {} for {} (spell {})",
                      entry, player->GetName(), GetSpellInfo()->Id);
            return;
        }

        personalBankVaults[vault->GetGUID().GetCounter()] = {player->GetGUID(), kind};

        // Wait the same ten minutes as the vault just placed. The cooldown that a bank item shows
        // comes from the item (`item_template.spellcooldown_1` = 600000 ms) and lives on no spell,
        // so without this, casting the spell on its own would place a vault per keypress. Both
        // routes are the same act: same spell, same vault, same wait.
        player->AddSpellCooldown(GetSpellInfo()->Id, 0, BANK_VAULT_DURATION * IN_MILLISECONDS, true);

        LOG_INFO("module.ascension_compat",
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

class AscensionCompatServerScript : public ServerScript {
public:
  AscensionCompatServerScript()
      : ServerScript("AscensionCompatServerScript",
                     {SERVERHOOK_CAN_PACKET_RECEIVE_EARLY, SERVERHOOK_CAN_PACKET_RECEIVE})
  {
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
            // While one of our windows is open the client's bank conversation belongs to
            // the personal bank, so none of it may reach the core's guild handling.
            else if (AscensionPersonalBank::IsOpen(player) &&
                     AscensionPersonalBank::HandlePacket(player, packet))
                return false;
        }

        if (!session || !session->GetPlayer() ||
            !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
            return true;

        // The core keeps this packet; it only tells the module the client is out of its loading screen.
        if (packet.GetOpcode() == CMSG_SET_ACTIVE_MOVER)
            AscensionClassService::Instance().OnPlayerActiveMover(session->GetPlayer());

        if (packet.GetOpcode() == CMSG_GET_MIRRORIMAGE_DATA && packet.size() >= sizeof(uint64))
        {
            ObjectGuid guid = packet.read<ObjectGuid>(0);
            CreatureDisplayPreset const* preset = nullptr;

            if (guid.IsCreatureOrVehicle())
            {
                uint32 displayId = 0;
                if (Creature const* creature = session->GetPlayer()->GetMap()->GetCreature(guid))
                    displayId = creature->GetDisplayId();

                preset = sAscensionPresets->GetPreset(guid.GetEntry(), displayId);
            }

            if (!preset)
            {
                preset = sAscensionPresets->GetActivePresetOverride(guid);
            }

            if (preset)
            {
                WorldPacket response(SMSG_MIRRORIMAGE_DATA, 68);
                response << guid;
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

                session->SendPacket(&response);
                return false;
            }
            return true;
        }

        if (packet.GetOpcode() != CMSG_CREATURE_QUERY || packet.size() < sizeof(uint32))
            return true;

        uint32 const entry = packet.read<uint32>(0);
        // Existing world creatures retain the normal authoritative query handler.
        // Only missing, evidence-backed collection preview entries get a reply.
        if (sObjectMgr->GetCreatureTemplate(entry))
            return true;

        AscensionCollectionModels::Entry const* model = FindCollectionModel(entry);
        if (!model)
            return true;

        SendCollectionCreatureQueryResponse(session, entry);
        LOG_DEBUG("module.ascension_compat", "Answered local creature preview query: entry {}, display {}, payload {}",
            entry, model->DisplayId, packet.size());
        return false;
    }

  [[nodiscard]] bool CanPacketReceiveEarly(WorldSession *session,
                                           WorldPacket const &packet) override {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED))
      return true;

    uint32 opcode = packet.GetOpcode();

    // This hook runs on the network thread: the upload waits for the player's own update.
    if (opcode == CMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES)
    {
      if (session)
        AscensionClassService::Instance().QueueKnownEntriesUpload(session->GetAccountId(), packet);
      return false;
    }

    // Ascension character-selection protocol: activate/deactivate and the
    // account sort order arrive on the character screen (STATUS_AUTHED, no
    // Player object) and are account-scoped.
    if (IsAscensionCharacterSelectionOpcode(static_cast<uint16>(opcode)))
    {
      if (HandleAscensionCharacterSelectionPacket(session, packet))
        return false;
    }
    else if (opcode == CMSG_CHAR_ENUM)
    {
      // The core still answers SMSG_CHAR_ENUM (and records the account's
      // legit characters); the Ascension list details follow in own packets.
      SendAscensionCharacterListInfo(session);
    }

    uint32 firstOpcode = ascensionCompatConfig.GetConfigValue<uint32>(
        AscensionCompatConfig::FIRST_EXTENSION_OPCODE);
    uint32 lastOpcode = ascensionCompatConfig.GetConfigValue<uint32>(
        AscensionCompatConfig::LAST_EXTENSION_OPCODE);

    if (opcode < firstOpcode || opcode > lastOpcode)
      return true;

    // The Ascension client's anti-tamper layer reports local detections here.
    // Leave the packet to the core's CMSG_ANTICHEAT_ALERT handler instead of
    // consuming it during protocol discovery.
    if (opcode == CMSG_ANTICHEAT_ALERT)
      return true;

    if (opcode == CMSG_CREATURE_QUERY_BULK)
    {
        constexpr uint32 maxCreatureQueries = 256;
        if (!session || packet.size() < sizeof(uint32))
        {
            LOG_WARN("module.ascension_compat",
                "Malformed Ascension creature asset query payload={} bytes", packet.size());
            return false;
        }

        uint32 const count = packet.read<uint32>(0);
        if (!count || count > maxCreatureQueries)
        {
            LOG_WARN("module.ascension_compat",
                "Malformed Ascension creature asset query count={} payload={} bytes", count, packet.size());
            return false;
        }

        std::size_t const expectedSize = sizeof(uint32) + std::size_t(count) * sizeof(uint32);
        if (packet.size() != expectedSize)
        {
            LOG_WARN("module.ascension_compat",
                "Malformed Ascension creature asset query count={} payload={} bytes", count, packet.size());
            return false;
        }

        uint32 answered = 0;
        for (uint32 index = 0; index < count; ++index)
        {
            uint32 const entry = packet.read<uint32>(sizeof(uint32) + std::size_t(index) * sizeof(uint32));
            if (SendCollectionCreatureQueryResponse(session, entry))
                ++answered;
        }

        LOG_DEBUG("module.ascension_compat",
            "Answered Ascension creature asset query: requested {}, answered {}", count, answered);
        return false;
    }

    // -- Challenge / trial CMSGs (owner: mod-coa-challenges) ----------------
    // Challenge-system CMSGs belong to mod-coa-challenges (late
    // CanPacketReceive hook + core Handle_NULL fallback). Pass them through:
    // this Early hook short-circuits the boolean-hook chain, so consuming
    // them here would starve the challenge module of its own packets.
    // Keep this list in sync with the COA CMSG block in Opcodes.h.
    static constexpr std::array<uint32, 13> kChallengeCmsgs = {
        CMSG_COA_START_CHALLENGE,          // 0x592 start challenge
        CMSG_COA_STOP_CHALLENGE,           // 0x594 stop challenge
        CMSG_COA_QUERY_FAILURES,           // 0x5A1 query challenge failures
        CMSG_COA_SYNC_RESPONSE,            // 0x59C group sync response (u8 accept)
        CMSG_COA_QUERY_COMPLETIONS,        // 0x5C6 query challenge completions
        CMSG_COA_SAVE_TRIAL,               // 0x5A7 save custom trial
        CMSG_COA_DELETE_TRIAL,             // 0x5A9 delete custom trial
        CMSG_COA_QUERY_TRIALS,             // 0x5AB query custom-trial list
        CMSG_COA_ACTIVATE_TRIAL,           // 0x5AD activate custom trial
        CMSG_COA_DEACTIVATE_TRIAL,         // 0x5AF deactivate custom trial
        CMSG_COA_RATE_TRIAL,               // 0x5BF rate/vote a trial (str + u8 + u8)
        CMSG_COA_QUERY_TRIAL_COMPLETIONS,  // 0x5C9 query trial leaderboard (str)
        CMSG_COA_TOGGLE_GAME_MODE,         // 0x5A4 toggle custom game mode
    };
    if (std::find(kChallengeCmsgs.begin(), kChallengeCmsgs.end(), opcode) !=
        kChallengeCmsgs.end())
      return true;

    // mod-manastorm-endless exclusively owns Manastorm in this core. Always
    // pass requests to its logged-in world-thread handler, including when its
    // config uses defaults or it is disabled. Never revive the donor service.
    if (opcode == 0x651 || opcode == 0x665 || opcode == 0x689)
      return true;

    if (opcode == CMSG_APPLY_APPEARANCES ||
        opcode == CMSG_SET_CAN_SEE_APPEARANCES) {
      AscensionCollectionService::Instance().QueueClientPacket(
          session->GetAccountId(), packet);
    }

    // Ascension sends this after the regular CMSG_CAST_SPELL packet to carry
    // client projectile rendering coordinates. AzerothCore has already handled
    // the actual cast, so no server-side action is required for local play.
    if (opcode == CMSG_MISSILE_FIRE_POSITION)
    {
      if (ascensionCompatConfig.GetConfigValue<bool>(
              AscensionCompatConfig::LOG_CONSUMED_PACKETS))
      {
        LOG_INFO("module.ascension_compat",
                 "Consumed Ascension missile-position packet payload={} bytes [{}]",
                 packet.size(), DescribePacketPayload(packet));
      }

      return false;
    }

    if (ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::LOG_CONSUMED_PACKETS)) {
      char const *name = ExtensionOpcodeName(uint16(opcode));
      LOG_INFO("module.ascension_compat",
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

    static ChatCommandTable localTalentCommandTable = {
        {"reset", HandleLocalTalentResetCommand, SEC_PLAYER, Console::No},
        {"sync", HandleLocalTalentSyncCommand, SEC_PLAYER, Console::No},
        {"", HandleLocalTalentCommand, SEC_PLAYER, Console::No}};

    static ChatCommandTable commandTable = {
        {"localfreshcheck", HandleAscensionFreshCharacterCheck, SEC_ADMINISTRATOR, Console::Yes},
        {"localreloadpresets", HandleLocalReloadPresetsCommand, SEC_ADMINISTRATOR, Console::Yes},
        {"morphpreset", HandleMorphPresetCommand, SEC_ADMINISTRATOR, Console::No},
        {"demorphpreset", HandleDemorphPresetCommand, SEC_ADMINISTRATOR, Console::No},
        {"localreloadoutfits", HandleLocalReloadPresetsCommand, SEC_ADMINISTRATOR, Console::Yes},
        {"morphoutfit", HandleMorphPresetCommand, SEC_ADMINISTRATOR, Console::No},
        {"localappearance", HandleLocalAppearanceCommand, SEC_PLAYER,
         Console::No},
        {"localvanity", HandleLocalVanityCommand, SEC_PLAYER, Console::No},
        {"localtalent", localTalentCommandTable},
        // The #4031 client half asks for the state under this name.
        {"localspecstate", HandleLocalTalentSyncCommand, SEC_PLAYER, Console::No},
        {"localspec", HandleLocalSpecCommand, SEC_PLAYER, Console::No},
        {"localresource", HandleLocalResourceCommand, SEC_PLAYER,
         Console::No},
        {"localcharges", HandleLocalChargesCommand, SEC_PLAYER, Console::No},
        {"spellcharges", spellChargesCommandTable},
        {"localclassrepair", HandleLocalClassRepairCommand, SEC_PLAYER,
         Console::No},
        // Protocol work only: send one extension packet by id so the matching
        // client build can be asked what it does with it.
        {"extprobe", HandleExtensionProbeCommand, SEC_ADMINISTRATOR,
         Console::No},
        // Placement work only: what the bank summon sees under it here.
        {"bankground", HandleBankGroundCommand, SEC_ADMINISTRATOR, Console::No}};
    return commandTable;
  }

  static uint32 HexNibble(char c) {
    if (c >= '0' && c <= '9')
      return uint32(c - '0');
    if (c >= 'a' && c <= 'f')
      return uint32(c - 'a' + 10);
    if (c >= 'A' && c <= 'F')
      return uint32(c - 'A' + 10);
    return 0xFFFFFFFFu;
  }

  /// "0x0769", "0769" or a name from ExtensionOpcodeName's table.
  static bool ParseExtensionOpcode(std::string const &text, uint32 &opcode) {
    std::string body = text;
    if (body.rfind("0x", 0) == 0 || body.rfind("0X", 0) == 0)
      body = body.substr(2);

    bool allHex = !body.empty();
    for (char c : body)
      if (HexNibble(c) == 0xFFFFFFFFu)
      {
        allHex = false;
        break;
      }
    if (allHex)
    {
      opcode = 0;
      for (char c : body)
        opcode = (opcode << 4) | HexNibble(c);
      return true;
    }

    for (ExtensionOpcodeIdentity const &entry : EXTENSION_OPCODES)
      if (text == entry.Name)
      {
        opcode = entry.Opcode;
        return true;
      }
    return false;
  }

  /// "01 00 00" or "010000" -> {1, 0, 0}.
  static bool ParseHexBytes(std::string const &text, std::vector<uint8> &out) {
    std::string digits;
    for (char c : text) {
      if (c == ' ' || c == ',' || c == '\t')
        continue;
      if (HexNibble(c) == 0xFFFFFFFFu)
        return false;
      digits += c;
    }
    if (digits.empty() || digits.size() % 2 != 0)
      return false;

    for (std::size_t i = 0; i < digits.size(); i += 2)
      out.push_back(uint8((HexNibble(digits[i]) << 4) | HexNibble(digits[i + 1])));
    return true;
  }

  static bool HandleExtensionProbeCommand(ChatHandler *handler,
                                          std::string opcodeText,
                                          Optional<std::string> payloadText) {
    Player *player = handler->GetPlayer();
    if (!player)
      return false;

    uint32 opcode = 0;
    if (!ParseExtensionOpcode(opcodeText, opcode) || opcode > 0xFFFF)
    {
      handler->PSendSysMessage(
          "Unknown opcode '{}'. Give a hex id such as 0x0769, or one of the "
          "names this module knows.",
          std::string(opcodeText));
      return true;
    }

    std::vector<uint8> payload;
    if (payloadText && !ParseHexBytes(*payloadText, payload))
    {
      handler->PSendSysMessage(
          "Payload must be whole hex bytes, for example \"01 00\".");
      return true;
    }

    WorldPacket packet{static_cast<uint16>(opcode)};
    for (uint8 byte : payload)
      packet << byte;

    player->GetSession()->SendPacket(&packet);

    char const *name = ExtensionOpcodeName(uint16(opcode));
    std::string label = name ? std::string(" (") + name + ")" : std::string();
    handler->PSendSysMessage("Sent 0x{:04X}{} with {} payload bytes.",
                             opcode, label, uint32(packet.size()));
    LOG_INFO("module.ascension_compat",
             "Sent extension packet opcode=0x{:04X} ({}) payload={} bytes [{}] "
             "to {}",
             opcode, name ? name : "unknown", packet.size(),
             DescribePacketPayload(packet), player->GetName());
    return true;
  }

  /// Reports every height the bank summon's grounding looks at, so a spot that
  /// places the bank wrong can be measured instead of guessed at.
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
    LOG_INFO("module.ascension_compat",
             "Bank ground probe for {}: feet {:.2f}, spot {:.2f} {:.2f}, "
             "terrain {:.2f}, terrain+vmap {:.2f}, chosen {:.2f}",
             player->GetName(), feetZ, x, y,
             map->GetHeight(x, y, feetZ + 0.3f, false, 3.0f),
             map->GetHeight(x, y, feetZ + 0.3f, true, 3.0f),
             GroundHeightBeneath(map, x, y, feetZ));
    return true;
  }

  static bool HandleLocalAppearanceCommand(ChatHandler *handler,
                                           uint32 categoryId,
                                           uint32 appearanceId) {
    Player *player = handler->GetPlayer();
    if (!player)
      return false;

    AscensionCollectionService::Instance().ApplyLocalAppearance(
        player, categoryId, appearanceId);
    return true;
  }

  static bool HandleLocalVanityCommand(ChatHandler *handler, uint32 itemId) {
    Player *player = handler->GetPlayer();
    if (!player)
      return false;

    AscensionCollectionService::Instance().DeliverLocalVanityItem(player,
                                                                   itemId);
    return true;
  }

  static bool HandleLocalTalentCommand(ChatHandler *handler, uint32 entryId,
                                       uint32 rank) {
    Player *player = handler->GetPlayer();
    if (!player)
      return false;

    AscensionCompatData::CoATalentEntry const* entry = AscensionClassService::FindTalentEntry(entryId);
    if (!entry)
    {
      handler->PSendSysMessage("Talent entry {} is not in the local CoA catalog.", entryId);
      return true;
    }

    std::string error;
    if (!AscensionClassService::Instance().SetTalentRank(player, *entry, rank, error))
    {
      handler->SendSysMessage(error);
      return true;
    }

    AscensionClassService::Instance().SendCharacterAdvancementKnownEntries(player);
    return true;
  }

  /// The state again, for a client whose listener loaded after the login push.
  static bool HandleLocalTalentSyncCommand(ChatHandler* handler)
  {
    Player* player = handler->GetPlayer();
    if (!player)
      return false;

    if (IsAscensionCustomClass(player))
      AscensionClassService::Instance().SendCharacterAdvancementKnownEntries(player);
    return true;
  }

  static bool HandleLocalTalentResetCommand(ChatHandler* handler)
  {
    Player* player = handler->GetPlayer();
    if (!player)
      return false;

    if (!IsAscensionCustomClass(player))
    {
      handler->SendSysMessage("Only a custom class has local CoA talents to reset.");
      return true;
    }

    uint32 const removed = AscensionClassService::Instance().ResetPaidTalents(player);
    handler->PSendSysMessage("Reset {} CoA talent rank(s); every class and specialization point is available again.",
                             removed);
    AscensionClassService::Instance().SendCharacterAdvancementKnownEntries(player);
    return true;
  }

  static bool HandleLocalSpecCommand(ChatHandler *handler,
                                     uint32 specializationId) {
    Player *player = handler->GetPlayer();
    if (!player)
      return false;

    if (!AscensionClassService::Instance().SwitchSpecialization(
            player, specializationId))
      handler->PSendSysMessage(
          "Specialization {} is not valid for your custom class.",
          specializationId);
    else
      AscensionClassService::Instance().SendCharacterAdvancementKnownEntries(player);
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

  static bool HandleLocalChargesCommand(ChatHandler* handler)
  {
    if (Player* player = handler->GetPlayer())
    {
        player->SendAllSpellChargeStates();
        SendAscensionRunemasterEchoesOwnership(player);
    }
    return true;
  }

  // Debug helpers for the native client charge UI (SMSG_SET/SEND_SPELL_CHARGES).
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
    SendAscensionRunemasterEchoesOwnership(player);
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

    if (displayId != 0) {
      preset = sAscensionPresets->GetPreset(entry, displayId);
    } else if (Player* targetPlayer = target->ToPlayer()) {
      preset = sAscensionPresets->GetPresetByGender(entry, targetPlayer->getGender());
    } else {
      preset = sAscensionPresets->GetPreset(entry);
    }

    if (!preset) {
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
    if (Player* player = target->ToPlayer()) {
      player->RemoveUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      player->InitDisplayIds();
    } else if (Creature* creature = target->ToCreature()) {
      if (CreatureTemplate const* cinfo = creature->GetCreatureTemplate()) {
        if (CreatureModel const* model = ObjectMgr::ChooseDisplayId(cinfo, creature->GetCreatureData())) {
          creature->SetDisplayId(model->CreatureDisplayID, model->DisplayScale);
          creature->SetNativeDisplayId(model->CreatureDisplayID);
        }
      }
      if (sAscensionPresets->HasPreset(creature->GetEntry())) {
        creature->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      } else {
        creature->RemoveUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      }
    } else {
      target->RemoveUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      target->DeMorph();
    }

    handler->PSendSysMessage("Demorphed creature display preset.");
    return true;
  }
};

class AscensionCompatPlayerScript : public PlayerScript {
    // One script instance serves every player, and players on different maps update on
    // different map threads: every access to the pending list goes through this lock.
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

            // Finish the acquisition before moving items; its caller still uses the original bag positions.
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

            // An empty main hand must not cause an occupied off hand to be unequipped.
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
            {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE,
             PLAYERHOOK_ON_AFTER_SET_VISIBLE_ITEM_SLOT, PLAYERHOOK_ON_EQUIP,
             PLAYERHOOK_ON_STORE_NEW_ITEM, PLAYERHOOK_ON_CREATE_ITEM,
             PLAYERHOOK_ON_PLAYER_IS_CLASS, PLAYERHOOK_ON_LEVEL_CHANGED,
             PLAYERHOOK_ON_LEARN_SPELL, PLAYERHOOK_ON_FORGOT_SPELL,
             PLAYERHOOK_ON_AFTER_SPEC_SLOT_CHANGED,
             PLAYERHOOK_ON_CREATE_INITIAL_ITEMS,
             PLAYERHOOK_ON_GET_AMMO_DISPLAY,
             PLAYERHOOK_ON_AFTER_UPDATE_ATTACK_POWER_AND_DAMAGE,
             PLAYERHOOK_ON_SEND_INITIAL_PACKETS_BEFORE_ADD_TO_MAP,
             PLAYERHOOK_CHECK_ITEM_IN_SLOT_AT_LOAD_INVENTORY}) {}

    void OnPlayerGetAmmoDisplay(Player* player, SpellInfo const* spellInfo,
        uint32& displayId, uint32& inventoryType) override
    {
        // Only ranged auto-attacks. Authored missiles on abilities, thrown weapons and wands stay native.
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

    void OnPlayerAfterUpdateAttackPowerAndDamage(Player* player, float& /*level*/, float& /*baseAttackPower*/,
        float& modifier, float& /*multiplier*/, bool ranged) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
            HandleAscensionBarbarianAttackPower(player, modifier, ranged);
    }

    void OnPlayerSendInitialPacketsBeforeAddToMap(Player* player, WorldPacket& /*data*/) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
        {
            AscensionCollectionService::Instance().PrepareOwnedCompanionsBeforeMap(player);
            AscensionCollectionService::Instance().PrepareOwnedBankSpellsBeforeMap(player);
            AscensionClassService::Instance().PrepareTaughtAbilitiesBeforeMap(player);
        }
    }

  bool OnPlayerCreateInitialItems(Player* player, bool& handled) override
  {
    if (handled || !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) ||
        !IsAscensionCustomClass(player))
      return true;

    handled = true;
    return AscensionClassService::Instance().InitializeLiveBaseline(player) &&
           AscensionClassService::Instance().InitializeLiveStarterKit(player);
  }

  bool OnPlayerCheckItemInSlotAtLoadInventory(Player* player, Item* item, uint8 slot,
      uint8& err, uint16& dest) override
  {
      if (!ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) ||
          slot != EQUIPMENT_SLOT_OFFHAND || player->getClass() != CLASS_SON_OF_ARUGAL)
          return true;

      // SynchronizeTaughtAbilities grants Dual Wield (674) from OnPlayerLogin, which runs only
      // after inventory is already loaded, so CanDualWield() is still false here even when the
      // player legitimately dual-wielded last session; the saved offhand item would otherwise
      // be rejected and get mailed back on every login. Only paper over that one not-yet-synced
      // flag: SynchronizeTaughtAbilities's own AutoUnequipOffhandIfNeed() unequips it again
      // moments later in the same login if the player is no longer eligible.
      uint8 result = player->CanEquipItem(slot, dest, item, false, false);
      if (result == EQUIP_ERR_OK || player->CanDualWield())
      {
          err = result;
          return false;
      }

      // A one-hand weapon is refused before the dual wield check (EQUIP_ERR_ITEM_CANT_BE_EQUIPPED:
      // FindEquipSlot offers the offhand only with dual wield), an offhand weapon at it
      // (EQUIP_ERR_CANT_DUAL_WIELD). Re-check with the flag the login sync is about to restore.
      player->SetCanDualWield(true);
      uint16 dualWieldDest = 0;
      uint8 const dualWieldResult = player->CanEquipItem(slot, dualWieldDest, item, false, false);
      if (dualWieldResult != EQUIP_ERR_OK)
      {
          player->SetCanDualWield(false);
          err = result;
          return false;
      }

      // Keep the flag: the zone update that adds the player to the map also calls
      // AutoUnequipOffhandIfNeed(), before OnPlayerLogin runs the taught ability sync.
      dest = dualWieldDest;
      err = EQUIP_ERR_OK;
      return false;
  }

  void OnPlayerLogin(Player *player) override {
    if (ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED)) {
      AscensionClassService::Instance().OnPlayerLogin(player);
      RemoveLegacyQuestSpells(player);
      SynchronizeAscensionClassMechanics(player);
      AscensionResourceService::Instance().OnPlayerLogin(player);
      AscensionCollectionService::Instance().OnPlayerLogin(player);
    }
  }

  void OnPlayerLevelChanged(Player *player, uint8 /*oldLevel*/) override {
    if (ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED))
    {
      AscensionClassService::Instance().SynchronizeProgression(player);
      AscensionClassService::Instance().SynchronizeProficiencies(player);
      AscensionClassService::Instance().SendCharacterAdvancementKnownEntries(player);

      // Quest templates are shared globally, so scaling is serialized per
      // player. Refresh accepted quest query data when the player's effective
      // quest level changes; this keeps the quest log in sync without mutating
      // the canonical template for anyone else.
      if (LocalLevelScaling::QuestEnabled.load(std::memory_order_relaxed))
      {
        for (auto const& [questId, status] : player->getQuestStatusMap())
        {
          if (status.Status != QUEST_STATUS_INCOMPLETE &&
              status.Status != QUEST_STATUS_COMPLETE &&
              status.Status != QUEST_STATUS_FAILED)
            continue;

          if (Quest const* quest = sObjectMgr->GetQuestTemplate(questId))
            if (quest->GetQuestLevel() <= 0 || quest->GetQuestLevel() < player->GetLevel())
              player->PlayerTalkClass->SendQuestQueryResponse(quest);
        }
      }
    }
  }

  void OnPlayerLearnSpell(Player *player, uint32 spellId) override {
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

    void OnPlayerAfterSpecSlotChanged(Player* player, uint8 /*newSlot*/) override
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

  void OnPlayerLogout(Player *player) override {
    {
      std::lock_guard<std::mutex> lock(_pendingEquipmentLock);
      _pendingEquipment.erase(player->GetGUID());
    }
    AscensionClassService::Instance().OnPlayerLogout(player);
    AscensionResourceService::Instance().OnPlayerLogout(player);
    AscensionCollectionService::Instance().OnPlayerLogout(player);
  }

  void OnPlayerUpdate(Player *player, uint32 diff) override {
    if (ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED)) {
      AscensionClassService::Instance().ProcessKnownEntriesUploads(player);
      AscensionClassService::Instance().UpdateClassTuning(player, diff);
      AscensionResourceService::Instance().OnPlayerUpdate(player, diff);
      AscensionCollectionService::Instance().OnPlayerUpdate(player, diff);
      EquipNewItems(player);
      if (sAscensionPresets->GetActivePresetOverride(player->GetGUID())) {
        if (!player->HasUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE))
          player->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      }
    }
  }

  void OnPlayerAfterSetVisibleItemSlot(Player *player, uint8 slot,
                                       Item *item) override {
    AscensionCollectionService::Instance().OnVisibleItemSet(player, slot, item);
  }

  void OnPlayerEquip(Player *player, Item *item, uint8 /*bag*/, uint8 /*slot*/,
                     bool /*update*/) override {
    AscensionCollectionService::Instance().OnItemObtained(player, item);
  }

  void OnPlayerStoreNewItem(Player *player, Item *item,
                            uint32 /*count*/) override {
    AscensionCollectionService::Instance().OnItemObtained(player, item);
    if (item && player->IsInWorld() && player->getClass() >= CLASS_BARBARIAN &&
        player->getClass() <= CLASS_SPIRIT_MAGE &&
        ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
    {
        std::lock_guard<std::mutex> lock(_pendingEquipmentLock);
        _pendingEquipment[player->GetGUID()].push_back(item->GetGUID());
    }
  }

  void OnPlayerCreateItem(Player *player, Item *item,
                           uint32 /*count*/) override {
    AscensionCollectionService::Instance().OnItemObtained(player, item);
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

    void OnSpellCheckCast(Spell* spell, bool /*strict*/,
        SpellCastResult& result) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(
                AscensionCompatConfig::ENABLED))
            AscensionResourceService::Instance().CheckCast(spell, result);
    }

    [[nodiscard]] bool CanPrepare(Spell* spell,
        SpellCastTargets const* /*targets*/,
        AuraEffect const* /*triggeredByAura*/) override
    {
        if (!ascensionCompatConfig.GetConfigValue<bool>(
                AscensionCompatConfig::ENABLED))
            return true;

        return CanPrepareAscensionClassMechanics19To25(spell) &&
            AscensionResourceService::Instance().CanPrepare(spell);
    }

    void OnSpellCast(Spell* spell, Unit* /*caster*/,
        SpellInfo const* /*spellInfo*/, bool /*skipCheck*/) override
    {
        if (ascensionCompatConfig.GetConfigValue<bool>(
                AscensionCompatConfig::ENABLED))
        {
            AscensionResourceService::Instance().OnSpellCast(spell);
            HandleAscensionClassMechanicsCast(spell);
        }
    }

    void OnSpellBeforeEffects(Spell* spell, Unit* /*caster*/,
        SpellInfo const* /*spellInfo*/) override
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

    void OnSpellSuccessfulInterrupt(Spell* spell, Unit* /*target*/) override
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

  void OnBlock(Unit *victim, Unit * /*attacker*/) override {
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
  }
};

void ApplyAscensionExperienceContracts(SpellInfo* info)
{
    if (!info)
        return;

    switch (info->Id)
    {
        case 57353: // Heirloom Experience Bonus +10%
        case 71354:
        case 157353: // Heirloom Experience Bonus +20%
        case 818046: // Potion of Experience
        case 819046:
            // Copied source tags 2/8 select quest XP. Native aura 200 only modifies kill XP.
            for (SpellEffectInfo& effect : info->Effects)
                if (effect.ApplyAuraName == SPELL_AURA_MOD_XP_PCT &&
                    (effect.MiscValue == 2 || effect.MiscValue == 8))
                    effect.ApplyAuraName = SPELL_AURA_MOD_XP_QUEST_PCT;
            break;
        case 818059: // Aura of Experience: 50% for kills and quests, shared with the party.
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
            switch (spellInfo->Id)
            {
                // Cosmetic visual spells whose legacy aura type was left empty in the client DBC.
                case 83328: case 83329: case 83330: case 83331: case 83332:
                case 83334: case 83335: case 83336: case 103921:
                    if (spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_APPLY_AURA &&
                        spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_NONE)
                        spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
                    break;
                // Shadowlands "mawhorsespikes" ground horses imported with a mounted-flight effect that the
                // other fourteen mounts of the same import block (91611-91614, 91620-91629) do not carry.
                // The client records leave SPELL_ATTR4_ONLY_FLYING_AREAS clear, so SpellInfo::CheckLocation
                // never runs the continent gate and AuraEffect::HandleAuraModIncreaseFlightSpeed grants
                // CAN_FLY anywhere, including Azeroth at level 1 with no riding skill. Drop the flight
                // effect so these mounts match their ground-only siblings.
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
        }
    }
};

class AscensionCompatLevelScalingScript : public AllCreatureScript
{
public:
  AscensionCompatLevelScalingScript()
      : AllCreatureScript("AscensionCompatLevelScalingScript") {}

  void OnBeforeCreatureSelectLevel(CreatureTemplate const* /*creatureTemplate*/,
                                   Creature* creature, uint8& level) override
  {
    if (!CanScale(creature))
      return;

    uint64 guid = creature->GetGUID().GetRawValue();
    uint8 original = level;
    {
      std::lock_guard<std::mutex> guard(_lock);
      auto [itr, inserted] = _states.try_emplace(guid, State{level, 1000});
      original = itr->second.Original;
      if (inserted)
        itr->second.Original = level;
    }

    level = DesiredLevel(creature, original);
  }

  void OnAllCreatureUpdate(Creature* creature, uint32 diff) override
  {
    if (!CanScale(creature) || creature->IsInCombat() || !creature->IsAlive() ||
        creature->GetHealth() != creature->GetMaxHealth())
      return;

    uint64 guid = creature->GetGUID().GetRawValue();
    uint8 original;
    {
      std::lock_guard<std::mutex> guard(_lock);
      State& state = _states.try_emplace(guid, State{creature->GetLevel(), 1000}).first->second;
      if (state.Timer > diff)
      {
        state.Timer -= diff;
        return;
      }
      state.Timer = 1000;
      original = state.Original;
    }

    if (DesiredLevel(creature, original) == creature->GetLevel())
      return;

    // SelectLevel reuses stock health, mana, attack-power and damage curves. It
    // runs only while full and out of combat, so an active fight never heals or
    // changes level underneath the player.
    creature->SelectLevel();
    if (CreatureTemplate const* creatureTemplate = creature->GetCreatureTemplate())
    {
      CreatureBaseStats const* stats = sObjectMgr->GetCreatureBaseStats(
          creature->GetLevel(), creatureTemplate->unit_class);
      creature->SetStatFlatModifier(UNIT_MOD_ARMOR, BASE_VALUE, stats->GenerateArmor(creatureTemplate));
    }
  }

  void OnCreatureRemoveWorld(Creature* creature) override
  {
    std::lock_guard<std::mutex> guard(_lock);
    _states.erase(creature->GetGUID().GetRawValue());
  }

private:
  struct State
  {
    uint8 Original;
    uint32 Timer;
  };

  static bool CanScale(Creature const* creature)
  {
    return LocalLevelScaling::CreatureEnabled.load(std::memory_order_relaxed) && creature &&
        !creature->GetMap()->IsScriptedPrivateInstance() &&
        !creature->IsPet() && !creature->IsTotem() && !creature->IsTrigger() && !creature->IsCritter() &&
        creature->GetCreatureType() != CREATURE_TYPE_NON_COMBAT_PET && !creature->GetCharmerOrOwner();
  }

  static uint8 DesiredLevel(Creature const* creature, uint8 original)
  {
    Map* map = creature->GetMap();
    if (!map)
      return original;

    uint8 desired = original;
    float range = creature->GetSightRange();
    for (auto const& reference : map->GetPlayers())
    {
      Player* player = reference.GetSource();
      if (!player || !player->IsAlive() || player->IsGameMaster() ||
          !creature->InSamePhase(player) || !creature->IsWithinDistInMap(player, range) ||
          !player->IsValidAttackTarget(creature))
        continue;
      desired = std::max(desired, LocalLevelScaling::ScaleCreatureLevel(original, player->GetLevel(),
          LocalLevelScaling::CreatureOffset.load(std::memory_order_relaxed)));
    }
    return desired;
  }

  std::mutex _lock;
  std::unordered_map<uint64, State> _states;
};

class AscensionCompatWorldScript : public WorldScript {
public:
  AscensionCompatWorldScript()
      : WorldScript("AscensionCompatWorldScript",
                    {WORLDHOOK_ON_BEFORE_CONFIG_LOAD, WORLDHOOK_ON_STARTUP,
                     WORLDHOOK_ON_LOAD_CUSTOM_DATABASE_TABLE}) {}

  void OnBeforeConfigLoad(bool reload) override {
    ascensionCompatConfig.Initialize(reload);
    bool enabled = ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED);
    LocalLevelScaling::CreatureEnabled.store(enabled && ascensionCompatConfig.GetConfigValue<bool>(
        AscensionCompatConfig::LEVEL_SCALING), std::memory_order_relaxed);
    LocalLevelScaling::QuestEnabled.store(enabled && ascensionCompatConfig.GetConfigValue<bool>(
        AscensionCompatConfig::QUEST_LEVEL_SCALING), std::memory_order_relaxed);
  }

  void OnLoadCustomDatabaseTable() override {
    if (!ascensionCompatConfig.GetConfigValue<bool>(
            AscensionCompatConfig::ENABLED))
      return;

    sAscensionPresets->LoadFromDB();
  }

  void OnStartup() override {
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
    AscensionResourceService::Instance().ValidateDefinitions();
    LOG_INFO("module.ascension_compat",
             "Ascension compatibility enabled; consuming extension opcodes "
             "0x{:04X}-0x{:04X}; collection data {}",
             firstOpcode, lastOpcode, dataLoaded ? "ready" : "unavailable");
  }
};

// Tradesman's Scroll.
//
// Ascension's scroll opens a gossip listing fifteen professions and sets the
// chosen one to its maximum skill. Captured from the live realm, its text reads:
//
//   "Select a Profession from the list below to receive Max Skill Level in it.
//    You will still need to train the recipes from items and trainers."
//
// and the item itself says "Maxes out a Profession of your choice. You will need
// to learn the profession as well." Both halves matter: the scroll raises the
// skill VALUE, it does not grant the skill and it does not teach any recipe.
// A player who has not learned the profession gets told so rather than silently
// gaining nothing.
//
// The option list is exactly the fifteen the live scroll offered, in the order
// it offered them -- note that it includes Lockpicking, which the Book of
// Artisans does not train, and excludes Jewelcrafting, Inscription and
// Bushcraft, which it does.
//
// This is an ItemScript rather than a creature: the scroll has no companion NPC
// (unlike the Books, which summon one), and ItemScript exposes both OnUse and
// OnGossipSelect, so the whole interaction lives on the item.

struct ScrollProfession
{
    uint32 skillId;
    char const* name;
};

// Order and membership taken from the captured gossip, not from a profession
// enum -- the scroll's list is its own thing.
constexpr ScrollProfession kProfessions[] = {
    { 171, "Alchemy" },        { 164, "Blacksmithing" }, { 333, "Enchanting" },
    { 202, "Engineering" },    { 165, "Leatherworking" }, { 197, "Tailoring" },
    { 182, "Herbalism" },      { 186, "Mining" },        { 393, "Skinning" },
    { 185, "Cooking" },        { 129, "First Aid" },     { 356, "Fishing" },
    { 633, "Lockpicking" },    { 732, "Woodcutting" },   { 757, "Woodworking" },
};

constexpr uint32 kGossipTextId = 1;      // generic; the options carry the meaning
constexpr uint32 kSenderScroll = 0xA5C0; // distinctive, so stray gossip cannot match

class AscensionTradesmanScroll : public ItemScript
{
public:
    AscensionTradesmanScroll() : ItemScript("ascension_tradesman_scroll") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        if (!player || !item)
            return false;

        ClearGossipMenuFor(player);
        for (uint32 i = 0; i < std::extent<decltype(kProfessions)>::value; ++i)
        {
            ScrollProfession const& prof = kProfessions[i];
            // Show what the player will actually get. A profession they have
            // not learned is still listed -- the live scroll listed all fifteen
            // regardless -- but the label says so up front.
            std::string label = prof.name;
            if (!player->HasSkill(prof.skillId))
                label += " (not learned)";
            else if (player->GetSkillValue(prof.skillId) >= player->GetPureMaxSkillValue(prof.skillId))
                label += " (already maxed)";

            AddGossipItemFor(player, GOSSIP_ICON_TRAINER, label, kSenderScroll, i);
        }

        SendGossipMenuFor(player, kGossipTextId, item->GetGUID());
        // true suppresses the item's own on-use spell: the gossip is the effect.
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

        // The scroll raises a skill; it never grants one. Learning the
        // profession is a separate step, exactly as the item text says.
        if (!player->HasSkill(prof.skillId))
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "You must learn {} before the scroll can raise it.", prof.name);
            return;
        }

        uint16 const cap = player->GetPureMaxSkillValue(prof.skillId);
        if (!cap)
            return;

        if (player->GetSkillValue(prof.skillId) >= cap)
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "Your {} is already at its maximum of {}.", prof.name, cap);
            return;
        }

        // Raise to the cap the player's current rank allows -- an Apprentice is
        // maxed at 75, not 450. Advancing further still means learning the next
        // rank from a trainer, which is what "Max Skill Level" meant on live.
        player->SetSkill(prof.skillId, player->GetSkillStep(prof.skillId), cap, cap);
        ChatHandler(player->GetSession()).PSendSysMessage(
            "{} raised to {}.", prof.name, cap);

        LOG_DEBUG("module.ascension_compat",
                  "Tradesman's Scroll: player {} set {} to {}",
                  player->GetName(), prof.name, cap);

        // Consume one scroll, matching a single-use consumable.
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

// Ascension mount buttons frequently cast a wrapper, not the riding aura.
// Resolve only validated catalog wrappers, using the same zone/riding rules
// as AzerothCore's spell_gen_mount and the matching client spell variants.
// Jailer's Bargain promises "a shield that absorbs damage equal to 30% of your maximum health",
// but its SPELL_AURA_SCHOOL_ABSORB effect carries EffectBasePoints 0 and no scaling, so the aura
// landed at a single point of absorption and popped on the first hit. The DBC cannot express a
// percentage of the caster's maximum health, so compute it here.
class spell_ascension_jailers_bargain : public AuraScript
{
    PrepareAuraScript(spell_ascension_jailers_bargain);

    static constexpr uint8 AbsorbPercent = 30;

    bool Load() override
    {
        return ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
            GetUnitOwner() && GetUnitOwner()->IsPlayer();
    }

    void CalculateAmount(AuraEffect const* /*effect*/, int32& amount, bool& canBeRecalculated)
    {
        if (Unit* owner = GetUnitOwner())
            amount = int32(owner->GetMaxHealth() * AbsorbPercent / 100);

        // Fixed at cast, like every other percentage-of-health shield: a health buff landing
        // mid-duration must not resize what is already absorbing.
        canBeRecalculated = false;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_jailers_bargain::CalculateAmount,
            EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
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
        // Validate runs on the registration instance; bind this cast instance too.
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
        if ((area && (area->flags & AREA_FLAG_NO_FLY_ZONE)) || (battlefield && !battlefield->CanFlyIn()))
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

// Wildcard Mount (91944) is a plain SPELL_EFFECT_DUMMY spell with no built-in behavior of its own;
// summon a random mount the player already owns, then let spell_ascension_local_mount above resolve
// the correct speed/flying variant for it.
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

    bool OnGossipSelect(Player* player, Creature* /*creature*/, uint32 sender, uint32 action) override
    {
        ClearGossipMenuFor(player);
        CloseGossipMenuFor(player);
        if (sender != GOSSIP_SENDER_MAIN || action != ActionRestoreAbilities ||
            !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) ||
            !IsAscensionCustomClass(player))
            return true;

        if (!AscensionClassService::Instance().SynchronizeProgression(player))
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
                // Each potion adds its normal duration to the unexpired time from previous potions.
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

} // namespace

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

    // GetPlayerSetting is not const but only reads the cached settings.
    return const_cast<Player*>(player)->GetPlayerSetting(ASCENSION_ACTIVE_SPEC_SETTING, 0).value;
}

bool SwitchAscensionSpecialization(Player* player, uint32 specializationId)
{
    return player && ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED) &&
        AscensionClassService::Instance().SwitchSpecialization(player, specializationId);
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

    for (uint32 rank = entry->SpellCount; rank > 0; --rank)
        if (entry->SpellIds[rank - 1] && player->HasSpell(entry->SpellIds[rank - 1]))
            return rank;
    return 0;
}

bool SetAscensionTalentRank(Player* player, uint32 entryId, uint32 rank)
{
    AscensionCompatData::CoATalentEntry const* entry = FindAscensionTalentEntry(entryId);
    if (!player || !entry || !IsAscensionCustomClass(player) || entry->ClassId != player->getClass() ||
        rank > entry->SpellCount)
        return false;

    // Automatic entries belong to SynchronizeProgression, never to a purchase.
    uint32 const freeChoiceGroup = AscensionClassService::GetSelectableFreeGroup(entryId);
    if (entry->AECost == 0 && entry->TECost == 0 && !freeChoiceGroup)
        return false;

    if (rank > 0 && entry->SpecId != 0 && entry->SpecId != GetAscensionActiveSpecialization(player))
        return false;

    uint32 const selectedSpellId = rank > 0 ? entry->SpellIds[rank - 1] : 0;
    if (rank > 0 && (!selectedSpellId || !sSpellMgr->GetSpellInfo(selectedSpellId)))
        return false;

    // Same resolution as ".local talent": a selection clears the other options of its free group,
    // then every rank of the entry, before learning the chosen rank.
    if (rank > 0 && freeChoiceGroup)
        for (auto const& other : AscensionCompatData::CoATalentEntries)
            if (other.ClassId == player->getClass() && other.SpecId == entry->SpecId && other.EntryId != entryId &&
                AscensionClassService::GetSelectableFreeGroup(other.EntryId) == freeChoiceGroup)
                for (uint32 spellId : other.SpellIds)
                    if (spellId && player->HasSpell(spellId))
                        player->removeSpell(spellId, SPEC_MASK_ALL, false);

    for (uint32 spellId : entry->SpellIds)
        if (spellId && player->HasSpell(spellId))
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

    // Each rank of a Character Advancement entry; remember which specialization grants it for the ranks below.
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

    // Higher ranks the progression teaches with level.
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

class AscensionCompatAllCreatureScript : public AllCreatureScript {
public:
  AscensionCompatAllCreatureScript()
      : AllCreatureScript("AscensionCompatAllCreatureScript") {}

  void OnCreatureAddWorld(Creature* creature) override {
    if (!creature || !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
      return;
    if (sAscensionPresets->HasPreset(creature->GetEntry())) {
      creature->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
    }
  }

  void OnAllCreatureUpdate(Creature* creature, uint32 /*diff*/) override {
    if (!creature || !ascensionCompatConfig.GetConfigValue<bool>(AscensionCompatConfig::ENABLED))
      return;
    if (sAscensionPresets->HasPreset(creature->GetEntry())) {
      if (!creature->HasUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE)) {
        creature->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
      }
    }
  }
};

void AddAscensionCompatScripts() {
  new npc_ascension_training_book();
  RegisterSpellScript(spell_ascension_personal_bank);
  RegisterSpellScript(spell_ascension_experience_potion);
  RegisterSpellScript(spell_ascension_local_mount);
  RegisterSpellScript(spell_ascension_jailers_bargain);
  RegisterSpellScript(spell_ascension_wildcard_mount);
  RegisterSpellScript(spell_ascension_legacy_quest_reward);
  new AscensionTradesmanScroll();
  new AscensionCompatServerScript();
  new AscensionCompatCommandScript();
  new AscensionCompatPlayerScript();
  new AscensionCompatAllSpellScript();
  new AscensionCompatUnitScript();
  new AscensionCompatChangelogScript();
  new AscensionCompatLevelScalingScript();
  new AscensionCompatWorldScript();
  new AscensionCompatAllCreatureScript();
}
