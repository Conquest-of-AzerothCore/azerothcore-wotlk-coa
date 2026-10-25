/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionCoAConfig.h"
#include "AscensionCompatOpcodes.h"
#include "AscensionFreepick.h"
#include "AscensionMysticEnchant.h"
#include "AscensionMysticEnchantRules.h"
#include "Chat.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "Item.h"
#include "Log.h"
#include "LootMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <deque>
#include <mutex>
#include <unordered_map>
#include <unordered_set>

namespace AscensionMysticEnchant
{
namespace
{
constexpr uint16 SMSG_UPDATE_KNOWN_RANDOM_ENCHANTS = 0x05F9;
constexpr uint16 SMSG_ADD_KNOWN_RANDOM_ENCHANT = 0x05FA;
constexpr uint16 SMSG_UPDATE_RANDOM_ENCHANT_DATA = 0x05FC;
constexpr uint16 SMSG_UPDATE_RANDOM_ENCHANT_SLOTS = 0x05FD;
constexpr uint16 SMSG_UPDATE_RANDOM_ENCHANT_SLOT = 0x05FE;
constexpr uint16 SMSG_UPDATE_RANDOM_ENCHANT_PRESET_DATA = 0x05FF;
constexpr uint16 SMSG_UPDATE_ACTIVE_RANDOM_ENCHANT_PRESET = 0x0600;
constexpr uint16 SMSG_SAVE_RANDOM_ENCHANT_PRESET_RESULT = 0x0602;
constexpr uint16 CMSG_REFORGE_RANDOM_ENCHANT_ITEM = 0x0603;
constexpr uint16 SMSG_REFORGE_RANDOM_ENCHANT_RESULT = 0x0604;
constexpr uint16 CMSG_COLLECTION_REFORGE_RANDOM_ENCHANT_ITEM = 0x0605;
constexpr uint16 SMSG_COLLECTION_REFORGE_RANDOM_ENCHANT_RESULT = 0x0606;
constexpr uint16 CMSG_DISENCHANT_RANDOM_ENCHANT_ITEM = 0x0607;
constexpr uint16 CMSG_DISENCHANT_RANDOM_ENCHANT_SLOT = 0x0608;
constexpr uint16 SMSG_DISENCHANT_RANDOM_ENCHANT_RESULT = 0x0609;
constexpr uint16 SMSG_APPLY_RANDOM_ENCHANT_RESULT = 0x060B;
constexpr uint16 CMSG_SET_ACTIVE_RANDOM_ENCHANT_PRESET = 0x060C;
constexpr uint16 SMSG_SET_ACTIVE_RANDOM_ENCHANT_PRESET_RESULT = 0x060D;
constexpr uint16 CMSG_COLLECTION_REFORGE_RANDOM_ENCHANT_SLOT = 0x060F;
constexpr uint16 CMSG_APPLY_RANDOM_ENCHANT_SLOT = 0x0610;
constexpr uint16 CMSG_PURCHASE_MYSTIC_SCROLL = 0x0611;
constexpr uint16 SMSG_PURCHASE_MYSTIC_SCROLL_RESULT = 0x0612;
constexpr uint16 CMSG_INSPECT_RANDOM_ENCHANTS = 0x0613;
constexpr uint16 SMSG_INSPECT_RANDOM_ENCHANTS_RESULT = 0x0614;
constexpr uint16 CMSG_UNLOCK_RANDOM_ENCHANT_PRESET = 0x0615;
constexpr uint16 SMSG_UNLOCK_RANDOM_ENCHANT_PRESET_RESULT = 0x0616;
constexpr uint16 CMSG_DESTROY_RANDOM_ENCHANT_SLOT = 0x0617;
constexpr uint16 SMSG_DESTROY_RANDOM_ENCHANT_SLOT_RESULT = 0x0618;
constexpr uint16 CMSG_PURCHASE_MYSTIC_EXTRACT = 0x0733;
constexpr uint16 SMSG_PURCHASE_MYSTIC_EXTRACT_RESULT = 0x0734;
constexpr uint16 SMSG_UPDATE_SPECIALIZATION_MYSTIC_ENCHANT_PRESET_ID = 0x0737;
constexpr uint16 CMSG_SET_SPECIALIZATION_MYSTIC_ENCHANT_PRESET_ID = 0x0739;
constexpr char SPECIALIZATION_PRESET_SETTING[] = "core.mystic.spec_preset";

constexpr std::array<uint16, 13> CLIENT_OPCODES = {
    CMSG_SET_SPECIALIZATION_MYSTIC_ENCHANT_PRESET_ID, CMSG_SET_ACTIVE_RANDOM_ENCHANT_PRESET,
    CMSG_APPLY_RANDOM_ENCHANT_SLOT, CMSG_PURCHASE_MYSTIC_SCROLL, CMSG_INSPECT_RANDOM_ENCHANTS,
    CMSG_UNLOCK_RANDOM_ENCHANT_PRESET, CMSG_DESTROY_RANDOM_ENCHANT_SLOT, CMSG_REFORGE_RANDOM_ENCHANT_ITEM,
    CMSG_COLLECTION_REFORGE_RANDOM_ENCHANT_ITEM, CMSG_DISENCHANT_RANDOM_ENCHANT_ITEM,
    CMSG_DISENCHANT_RANDOM_ENCHANT_SLOT, CMSG_COLLECTION_REFORGE_RANDOM_ENCHANT_SLOT, CMSG_PURCHASE_MYSTIC_EXTRACT };

constexpr uint32 REFORGE_SPELL = 93235;
constexpr uint32 REFORGE_COOLDOWN = 1100;
constexpr std::array<uint32, 2> PROGRESS_AURAS = { 85856, 85857 };
constexpr std::array<char const*, 5> EXTRACT_COST_CONFIGS = { "CONFIG_MYSTIC_ENCHANT_EXTRACT_UNCOMMON_TOKEN_COST",
    "CONFIG_MYSTIC_ENCHANT_EXTRACT_RARE_TOKEN_COST", "CONFIG_MYSTIC_ENCHANT_EXTRACT_EPIC_TOKEN_COST",
    "CONFIG_MYSTIC_ENCHANT_EXTRACT_LEGENDARY_TOKEN_COST", "CONFIG_MYSTIC_ENCHANT_EXTRACT_ARTIFACT_TOKEN_COST" };

constexpr std::array<uint32, 24> ALTARS = { 48, 80148, 176522, 176523, 176525, 245006, 357264, 800079, 1000079,
    1903512, 1903513, 3241144, 3244734, 3245004, 3245006, 3245037, 3245726, 3246320, 3249516, 3252409, 7100000,
    8000051, 8000052, 8666999 };
constexpr float ALTAR_RANGE = 10.0f;
constexpr std::size_t MAX_QUEUED_REQUESTS = 16;
constexpr uint32 MAX_STAGED_APPLIES = 64;

struct State
{
    uint64 Progress = 1;
    uint32 Level = 1;
    uint32 ActivePreset = 0;
    std::vector<Slots> Presets = std::vector<Slots>(1, Slots{});
    std::vector<uint32> Known;
    std::unordered_map<uint32, uint32> Auras;

    Slots& Active() { return Presets[ActivePreset]; }
};

Catalog Loaded;
bool Ready = false;
std::unordered_map<ObjectGuid::LowType, State> States;
std::mutex PendingLock;
std::unordered_map<uint32, std::deque<WorldPacket>> PendingRequests;
std::atomic<bool> AnyPending = false;

ClientConfig CurrentClientConfig()
{
    AscensionClientConfig const collected = CollectAscensionClientConfig();
    ClientConfig config;
    for (auto const& [name, value] : collected.Integers)
        config.Integers[name] = value;
    for (auto const& [name, value] : collected.Booleans)
        config.Booleans[name] = value;
    return config;
}

bool AltarNearby(Player const* player)
{
    return std::any_of(ALTARS.begin(), ALTARS.end(),
        [player](uint32 entry) { return player->FindNearestGameObject(entry, ALTAR_RANGE, true) != nullptr; });
}

Character Describe(Player const* player, ClientConfig const& config)
{
    Character character;
    character.Class = player->getClass();
    character.Level = player->GetLevel();
    character.Money = player->GetMoney();
    character.GameModes = sConfigMgr->GetOption<uint32>("CoA.GameModeMask", 0);
    character.Casting = player->IsNonMeleeSpellCast(false);
    character.UnlockTokens = player->GetItemCount(PRESET_UNLOCK_TOKEN, false);
    character.Runes = player->GetItemCount(RUNE_OF_ASCENSION, false);
    character.Extracts = player->GetItemCount(MYSTIC_EXTRACT, false);
    character.AltarNearby = AltarNearby(player);
    character.RealmGates = AscensionFreepick::RealmGates();
    character.Config = &config;
    character.Invested = [player](uint32 classType, uint32 tab, bool talent)
    {
        return AscensionFreepick::InvestedEssence(player, classType, tab, talent);
    };
    character.StackLimit = [](uint32 spell) -> uint32
    {
        SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
        return info ? std::max<uint32>(1, info->StackAmount) : 0;
    };
    return character;
}

State& Load(Player const* player)
{
    ObjectGuid::LowType const guid = player->GetGUID().GetCounter();
    State state;
    if (QueryResult result = CharacterDatabase.Query(
        "SELECT progress, level, active_preset, preset_count FROM coa_mystic_enchant WHERE guid = {}", guid))
    {
        Field* fields = result->Fetch();
        state.Progress = fields[0].Get<uint64>();
        state.Level = fields[1].Get<uint32>();
        state.Presets.assign(std::clamp<uint32>(fields[3].Get<uint8>(), 1, MAX_PRESETS), Slots{});
        state.ActivePreset = std::min<uint32>(fields[2].Get<uint8>(), uint32(state.Presets.size()) - 1);
    }
    if (QueryResult result = CharacterDatabase.Query("SELECT spell FROM coa_mystic_enchant_known WHERE guid = {}",
        guid))
    {
        do
            state.Known.push_back(result->Fetch()[0].Get<uint32>());
        while (result->NextRow());
    }
    if (QueryResult result = CharacterDatabase.Query(
        "SELECT preset, slot, spell FROM coa_mystic_enchant_slot WHERE guid = {}", guid))
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 const preset = fields[0].Get<uint8>();
            uint32 const slot = fields[1].Get<uint8>();
            if (preset < state.Presets.size() && slot < SLOT_COUNT)
                state.Presets[preset][slot] = fields[2].Get<uint32>();
        } while (result->NextRow());
    }
    return States[guid] = std::move(state);
}

State* Find(Player const* player)
{
    auto const itr = States.find(player->GetGUID().GetCounter());
    return itr == States.end() ? nullptr : &itr->second;
}

void SaveHeader(Player const* player, State const& state)
{
    CharacterDatabase.Execute("REPLACE INTO coa_mystic_enchant (guid, progress, level, active_preset, preset_count) "
        "VALUES ({}, {}, {}, {}, {})", player->GetGUID().GetCounter(), state.Progress, state.Level, state.ActivePreset,
        state.Presets.size());
}

void SaveSlot(Player const* player, uint32 preset, uint32 slot, uint32 spell)
{
    if (spell)
        CharacterDatabase.Execute("REPLACE INTO coa_mystic_enchant_slot (guid, preset, slot, spell) VALUES "
            "({}, {}, {}, {})", player->GetGUID().GetCounter(), preset, slot, spell);
    else
        CharacterDatabase.Execute("DELETE FROM coa_mystic_enchant_slot WHERE guid = {} AND preset = {} AND slot = {}",
            player->GetGUID().GetCounter(), preset, slot);
}

void SyncAuras(Player* player, State& state)
{
    std::unordered_map<uint32, uint32> wanted;
    for (uint32 spell : state.Active())
        if (spell)
            ++wanted[spell];
    for (auto const& [spell, stacks] : state.Auras)
        if (!wanted.contains(spell))
        {
            player->RemoveAurasDueToSpell(spell);
            if (Enchant const* enchant = Loaded.FindSpell(spell); enchant && enchant->Taught)
                player->removeSpell(enchant->Taught, SPEC_MASK_ALL, true);
        }
    for (auto const& [spell, stacks] : wanted)
    {
        if (Enchant const* enchant = Loaded.FindSpell(spell); enchant && enchant->Taught && !player->HasSpell(enchant->Taught))
            player->learnSpell(enchant->Taught, true);
        Aura* aura = player->GetAura(spell);
        if (!aura)
            aura = player->AddAura(spell, player);
        if (aura && aura->GetStackAmount() != stacks)
            aura->SetStackAmount(uint8(std::min<uint32>(stacks, 255)));
    }
    state.Auras = std::move(wanted);
}

void SendResult(Player* player, uint16 opcode, char const* result)
{
    WorldPacket packet(opcode, 48);
    packet << result;
    player->SendDirectMessage(&packet);
}

void SendSlot(Player* player, uint32 slot, uint32 spell)
{
    WorldPacket packet(SMSG_UPDATE_RANDOM_ENCHANT_SLOT, 8);
    packet << uint32(slot) << uint32(spell);
    player->SendDirectMessage(&packet);
}

void SendChangedSlots(Player* player, Slots const& before, Slots const& after)
{
    for (uint32 slot = 0; slot < SLOT_COUNT; ++slot)
        if (before[slot] != after[slot])
            SendSlot(player, slot, after[slot]);
}

void AppendSlots(WorldPacket& packet, Slots const& slots)
{
    packet << uint32(SLOT_COUNT);
    for (uint32 spell : slots)
        packet << uint32(spell);
}

void SendState(Player* player, State const& state)
{
    WorldPacket known(SMSG_UPDATE_KNOWN_RANDOM_ENCHANTS, 4 + 4 * state.Known.size());
    known << uint32(state.Known.size());
    for (uint32 spell : state.Known)
        known << uint32(spell);
    player->SendDirectMessage(&known);

    WorldPacket data(SMSG_UPDATE_RANDOM_ENCHANT_DATA, 12);
    data << uint64(state.Progress) << uint32(state.Level);
    player->SendDirectMessage(&data);

    WorldPacket slots(SMSG_UPDATE_RANDOM_ENCHANT_SLOTS, 4 + 4 * SLOT_COUNT);
    AppendSlots(slots, state.Presets[state.ActivePreset]);
    player->SendDirectMessage(&slots);

    WorldPacket presets(SMSG_UPDATE_RANDOM_ENCHANT_PRESET_DATA, 4 + state.Presets.size() * (4 + 4 * SLOT_COUNT));
    presets << uint32(state.Presets.size());
    for (Slots const& preset : state.Presets)
        AppendSlots(presets, preset);
    player->SendDirectMessage(&presets);

    WorldPacket active(SMSG_UPDATE_ACTIVE_RANDOM_ENCHANT_PRESET, 4);
    active << uint32(state.ActivePreset);
    player->SendDirectMessage(&active);
}

void SavePreset(Player* player, Character const& character)
{
    SendResult(player, SMSG_SAVE_RANDOM_ENCHANT_PRESET_RESULT, PRESET_SAVE_RESULTS[CheckPresetSave(character)]);
}

ScrollItem Locate(Player* player, uint8 bag, uint8 slot, Item*& item)
{
    item = player->GetItemByPos(bag, slot);
    return { item != nullptr, item ? item->GetEntry() : 0 };
}

Item* ReplaceScroll(Player* player, Item* scroll, uint32 entry)
{
    uint8 const bag = scroll->GetBagSlot();
    uint8 const slot = scroll->GetSlot();
    ItemPosCountVec destination;
    if (scroll->GetCount() > 1)
    {
        if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, entry, 1) != EQUIP_ERR_OK)
            return nullptr;
        uint32 one = 1;
        player->DestroyItemCount(scroll, one, true);
    }
    else
    {
        player->DestroyItem(bag, slot, true);
        if (player->CanStoreNewItem(bag, slot, destination, entry, 1) != EQUIP_ERR_OK &&
            player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, entry, 1) != EQUIP_ERR_OK)
            return nullptr;
    }
    Item* created = player->StoreNewItem(destination, entry, true);
    if (created)
        player->SendNewItem(created, 1, true, false);
    return created;
}

void ApplyCharge(Player* player, AscensionMysticEnchant::Charge const& charge)
{
    if (charge.Runes)
        player->DestroyItemCount(RUNE_OF_ASCENSION, charge.Runes, true);
    if (charge.Money)
        player->ModifyMoney(-int32(charge.Money));
}

void Learn(Player* player, State& state, uint32 spell)
{
    if (std::find(state.Known.begin(), state.Known.end(), spell) != state.Known.end())
        return;
    state.Known.push_back(spell);
    CharacterDatabase.Execute("INSERT IGNORE INTO coa_mystic_enchant_known (guid, spell) VALUES ({}, {})",
        player->GetGUID().GetCounter(), spell);
    WorldPacket packet(SMSG_ADD_KNOWN_RANDOM_ENCHANT, 5);
    packet << uint32(spell) << uint8(0);
    player->SendDirectMessage(&packet);
}

void GrantReforgeProgress(Player* player, State& state, Enchant const& rolled)
{
    uint64 gain = ReforgeProgressGain(rolled, 1.0);
    for (uint32 auraId : PROGRESS_AURAS)
    {
        SpellInfo const* info = sSpellMgr->GetSpellInfo(auraId);
        if (info && player->HasAura(auraId))
            gain = uint64(float(int64(gain)) * (float(info->Effects[EFFECT_1].BasePoints + 1) / 100.0f + 1.0f));
    }
    Progress progress{ state.Progress, state.Level };
    uint32 const levels = AddProgress(progress, gain);
    state.Progress = progress.Points;
    state.Level = progress.Level;
    SaveHeader(player, state);
    if (levels && player->AddItem(MYSTIC_EXTRACT, levels))
        sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::MysticExtractEarned, levels);
}

void HandleReforgeItem(Player* player, State& state, WorldPacket& packet)
{
    uint8 const bag = packet.read<uint8>();
    uint8 const slot = packet.read<uint8>();
    Item* item = nullptr;
    ScrollItem const scroll = Locate(player, bag, slot, item);
    ClientConfig const config = CurrentClientConfig();
    Character const character = Describe(player, config);
    uint32 result = CheckReforgeItem(Loaded, character, scroll);
    Enchant const* rolled = nullptr;
    if (result == REFORGE_OK)
    {
        rolled = Roll(ReforgePool(Loaded, character,
            [](uint32 entry) { return sObjectMgr->GetItemTemplate(entry) != nullptr; }), rand_norm());
        if (!rolled || !ReplaceScroll(player, item, rolled->Item))
            result = REFORGE_UNKNOWN;
    }
    if (result == REFORGE_OK)
    {
        ApplyCharge(player, ReforgeCharge(character));
        GrantReforgeProgress(player, state, *rolled);
        player->AddSpellCooldown(REFORGE_SPELL, 0, REFORGE_COOLDOWN, true);
        sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::MysticScrollReforged, rolled->Spell);
    }
    WorldPacket response(SMSG_REFORGE_RANDOM_ENCHANT_RESULT, 40);
    response << REFORGE_RESULTS[result] << uint32(rolled && result == REFORGE_OK ? rolled->Spell : 0);
    player->SendDirectMessage(&response);
}

void HandleCollectionReforgeItem(Player* player, State& state, WorldPacket& packet)
{
    uint8 const bag = packet.read<uint8>();
    uint8 const slot = packet.read<uint8>();
    uint32 const spell = packet.read<uint32>();
    Item* item = nullptr;
    ScrollItem const scroll = Locate(player, bag, slot, item);
    ClientConfig const config = CurrentClientConfig();
    Character character = Describe(player, config);
    character.Known = &state.Known;
    uint32 result = CheckCollectionReforgeItem(Loaded, character, scroll, spell);
    Enchant const* target = Loaded.FindSpell(spell);
    if (result == COLLECTION_REFORGE_OK)
    {
        AscensionMysticEnchant::Charge const charge = CollectionReforgeCharge(character, { target }, false);
        if (ReplaceScroll(player, item, target->Item))
            ApplyCharge(player, charge);
        else
            result = COLLECTION_REFORGE_UNKNOWN;
    }
    SendResult(player, SMSG_COLLECTION_REFORGE_RANDOM_ENCHANT_RESULT, COLLECTION_REFORGE_RESULTS[result]);
}

void HandleSaveCollectionReforge(Player* player, State& state, WorldPacket& packet)
{
    uint32 const count = packet.read<uint32>();
    if (count > MAX_STAGED_APPLIES)
    {
        SendResult(player, SMSG_COLLECTION_REFORGE_RANDOM_ENCHANT_RESULT,
            COLLECTION_REFORGE_RESULTS[COLLECTION_REFORGE_UNKNOWN]);
        return;
    }
    std::vector<StagedReforge> staged;
    for (uint32 index = 0; index < count; ++index)
    {
        StagedReforge entry;
        entry.Slot = packet.read<uint32>();
        entry.Spell = packet.read<uint32>();
        staged.push_back(entry);
    }
    ClientConfig const config = CurrentClientConfig();
    Character character = Describe(player, config);
    character.Known = &state.Known;
    uint32 const result = CheckSaveCollectionReforge(Loaded, character, state.Active(), staged);
    if (result != COLLECTION_REFORGE_OK)
    {
        SendResult(player, SMSG_COLLECTION_REFORGE_RANDOM_ENCHANT_RESULT, COLLECTION_REFORGE_RESULTS[result]);
        return;
    }
    std::vector<Enchant const*> targets;
    for (StagedReforge const& entry : staged)
        targets.push_back(Loaded.FindSpell(entry.Spell));
    ApplyCharge(player, CollectionReforgeCharge(character, targets, true));
    Slots const before = state.Active();
    for (StagedReforge const& entry : staged)
        state.Active()[entry.Slot] = entry.Spell;
    for (uint32 slot = 0; slot < SLOT_COUNT; ++slot)
        if (before[slot] != state.Active()[slot])
            SaveSlot(player, state.ActivePreset, slot, state.Active()[slot]);
    SyncAuras(player, state);
    SendChangedSlots(player, before, state.Active());
    SendResult(player, SMSG_COLLECTION_REFORGE_RANDOM_ENCHANT_RESULT,
        COLLECTION_REFORGE_RESULTS[COLLECTION_REFORGE_OK]);
    SavePreset(player, character);
    sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::MysticCollectionApplied, uint32(staged.size()));
}

void CompleteDisenchant(Player* player, State& state, Character const& character, uint32 spell, uint32 bought)
{
    if (bought)
        player->DestroyItemCount(RUNE_OF_ASCENSION, ExtractPurchaseCost(state.Level), true);
    if (Enchant const* enchant = Loaded.FindSpell(spell))
        if (uint32 const held = ExtractCost(character, *enchant) - std::min(bought, ExtractCost(character, *enchant)))
            player->DestroyItemCount(MYSTIC_EXTRACT, held, true);
    Learn(player, state, spell);
    sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::MysticEnchantExtracted, spell);
}

void HandleDisenchantItem(Player* player, State& state, WorldPacket& packet)
{
    bool const buyExtract = packet.read<uint8>() != 0;
    uint8 const bag = packet.read<uint8>();
    uint8 const slot = packet.read<uint8>();
    Item* item = nullptr;
    ScrollItem const scroll = Locate(player, bag, slot, item);
    ClientConfig const config = CurrentClientConfig();
    Character character = Describe(player, config);
    character.Known = &state.Known;
    uint32 const bought = ExtractsBoughtWithSave(character, state.Level, buyExtract);
    character.Extracts += bought;
    uint32 const result = CheckDisenchantItem(Loaded, character, scroll);
    if (result == DISENCHANT_OK)
    {
        uint32 const spell = Loaded.FindItem(scroll.Entry)->Spell;
        uint32 one = 1;
        player->DestroyItemCount(item, one, true);
        CompleteDisenchant(player, state, character, spell, bought);
    }
    SendResult(player, SMSG_DISENCHANT_RANDOM_ENCHANT_RESULT, DISENCHANT_RESULTS[result]);
}

void HandleDisenchantSlot(Player* player, State& state, WorldPacket& packet)
{
    bool const buyExtract = packet.read<uint8>() != 0;
    uint32 const slot = packet.read<uint32>();
    ClientConfig const config = CurrentClientConfig();
    Character character = Describe(player, config);
    character.Known = &state.Known;
    uint32 const bought = ExtractsBoughtWithSave(character, state.Level, buyExtract);
    character.Extracts += bought;
    uint32 const result = CheckDisenchantSlot(Loaded, character, state.Active(), slot);
    if (result == DISENCHANT_OK)
        CompleteDisenchant(player, state, character, state.Active()[slot], bought);
    SendResult(player, SMSG_DISENCHANT_RANDOM_ENCHANT_RESULT, DISENCHANT_RESULTS[result]);
}

void HandlePurchaseExtract(Player* player, State const& state)
{
    ClientConfig const config = CurrentClientConfig();
    uint32 result = CheckExtractPurchase(Describe(player, config), state.Level);
    if (result == EXTRACT_PURCHASE_OK)
    {
        if (player->AddItem(MYSTIC_EXTRACT, 1))
            player->DestroyItemCount(RUNE_OF_ASCENSION, ExtractPurchaseCost(state.Level), true);
        else
            result = EXTRACT_PURCHASE_UNKNOWN;
    }
    SendResult(player, SMSG_PURCHASE_MYSTIC_EXTRACT_RESULT, EXTRACT_PURCHASE_RESULTS[result]);
}

void AppendExtractCosts(AscensionClientConfig& config)
{
    for (char const* name : EXTRACT_COST_CONFIGS)
        if (std::none_of(config.Integers.begin(), config.Integers.end(),
            [name](std::pair<std::string, int32> const& entry) { return entry.first == name; }))
            config.Integers.emplace_back(name, 1);
}

void SendSpecializationLink(Player* player, uint32 specialization, uint32 preset)
{
    WorldPacket packet(SMSG_UPDATE_SPECIALIZATION_MYSTIC_ENCHANT_PRESET_ID, 9);
    packet << uint32(specialization) << uint8(preset ? 1 : 0);
    if (preset)
        packet << uint32(preset);
    player->SendDirectMessage(&packet);
}

uint32 SpecializationLink(Player const* player, uint32 specialization)
{
    PlayerSettingVector const* stored = player->FindPlayerSettings(SPECIALIZATION_PRESET_SETTING);
    return stored && specialization < stored->size() ? (*stored)[specialization].value : 0;
}

void SendSpecializationLinks(Player* player)
{
    for (uint32 specialization = 0; specialization < SPECIALIZATION_COUNT; ++specialization)
        if (uint32 const preset = SpecializationLink(player, specialization))
            SendSpecializationLink(player, specialization, preset);
}

void HandleSpecializationLink(Player* player, State const& state, WorldPacket& packet)
{
    uint32 const specialization = packet.read<uint32>();
    bool const linked = packet.read<uint8>() != 0;
    uint32 const preset = linked ? packet.read<uint32>() : 0;
    if (!ValidSpecializationLink(specialization, linked, preset, uint32(state.Presets.size())))
    {
        SendSpecializationLink(player, specialization < SPECIALIZATION_COUNT ? specialization : 0,
            specialization < SPECIALIZATION_COUNT ? SpecializationLink(player, specialization) : 0);
        return;
    }
    player->UpdatePlayerSetting(SPECIALIZATION_PRESET_SETTING, specialization, preset);
    SendSpecializationLink(player, specialization, preset);
}

void HandleSaveApply(Player* player, State& state, WorldPacket& packet)
{
    uint32 const count = packet.read<uint32>();
    if (count > MAX_STAGED_APPLIES)
    {
        SendResult(player, SMSG_APPLY_RANDOM_ENCHANT_RESULT, APPLY_RESULTS[APPLY_UNKNOWN]);
        return;
    }
    std::vector<StagedApply> staged;
    std::vector<Item*> items;
    for (uint32 index = 0; index < count; ++index)
    {
        StagedApply entry;
        entry.Slot = packet.read<uint32>();
        uint8 const bag = packet.read<uint8>();
        uint8 const slot = packet.read<uint8>();
        Item* item = player->GetItemByPos(bag, slot);
        entry.ItemFound = item != nullptr;
        entry.ItemEntry = item ? item->GetEntry() : 0;
        entry.ItemKey = item ? item->GetGUID().GetCounter() : 0x80000000u | (uint32(bag) << 8) | slot;
        staged.push_back(entry);
        items.push_back(item);
    }

    ClientConfig const config = CurrentClientConfig();
    Character const character = Describe(player, config);
    uint32 const result = CheckSaveApply(Loaded, character, state.Active(), staged);
    if (result != APPLY_OK)
    {
        SendResult(player, SMSG_APPLY_RANDOM_ENCHANT_RESULT, APPLY_RESULTS[result]);
        return;
    }

    Slots const before = state.Active();
    std::vector<uint32> consumed;
    for (std::size_t index = 0; index < staged.size(); ++index)
    {
        state.Active()[staged[index].Slot] = Loaded.FindItem(staged[index].ItemEntry)->Spell;
        if (std::find(consumed.begin(), consumed.end(), staged[index].ItemKey) != consumed.end())
            continue;
        consumed.push_back(staged[index].ItemKey);
        uint32 one = 1;
        player->DestroyItemCount(items[index], one, true);
    }
    for (uint32 slot = 0; slot < SLOT_COUNT; ++slot)
        if (before[slot] != state.Active()[slot])
            SaveSlot(player, state.ActivePreset, slot, state.Active()[slot]);
    SyncAuras(player, state);
    SendChangedSlots(player, before, state.Active());
    SendResult(player, SMSG_APPLY_RANDOM_ENCHANT_RESULT, APPLY_RESULTS[APPLY_OK]);
    SavePreset(player, character);
    LOG_INFO("coa", "{} applied {} mystic scroll(s)", player->GetName(), consumed.size());
    sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::MysticScrollApplied, uint32(consumed.size()));
}

void HandleDestroy(Player* player, State& state, WorldPacket& packet)
{
    uint32 const slot = packet.read<uint32>();
    ClientConfig const config = CurrentClientConfig();
    Character const character = Describe(player, config);
    uint32 const result = CheckDestroy(character, state.Active(), slot);
    if (result == DESTROY_OK)
    {
        state.Active()[slot] = 0;
        SaveSlot(player, state.ActivePreset, slot, 0);
        SyncAuras(player, state);
        SendSlot(player, slot, 0);
    }
    SendResult(player, SMSG_DESTROY_RANDOM_ENCHANT_SLOT_RESULT, DESTROY_RESULTS[result]);
    if (result == DESTROY_OK)
        SavePreset(player, character);
}

void HandlePurchaseScroll(Player* player)
{
    ClientConfig const config = CurrentClientConfig();
    Character character = Describe(player, config);
    ItemTemplate const* scroll = sObjectMgr->GetItemTemplate(UNTARNISHED_MYSTIC_SCROLL);
    ItemPosCountVec destination;
    character.BagSpace = scroll &&
        player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, UNTARNISHED_MYSTIC_SCROLL, 1) == EQUIP_ERR_OK;
    character.AltarNearby = AltarNearby(player);
    uint32 const price = scroll ? scroll->BuyPrice : 0;
    uint32 const result = CheckPurchaseScroll(character, scroll != nullptr, price);
    if (result == PURCHASE_OK)
    {
        player->ModifyMoney(-int32(price));
        if (Item* item = player->StoreNewItem(destination, UNTARNISHED_MYSTIC_SCROLL, true))
        {
            player->SendNewItem(item, 1, true, false);
            sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::MysticScrollPurchased,
                UNTARNISHED_MYSTIC_SCROLL);
        }
    }
    SendResult(player, SMSG_PURCHASE_MYSTIC_SCROLL_RESULT, PURCHASE_RESULTS[result]);
}

void HandleInspect(Player* player, WorldPacket& packet)
{
    ObjectGuid const guid(packet.read<uint64>());
    Player* target = ObjectAccessor::FindPlayer(guid);
    State const* state = target ? Find(target) : nullptr;
    uint32 const result = CheckInspect(target && state, target && target->GetMap() == player->GetMap(),
        target ? target->getClass() : 0);

    WorldPacket response(SMSG_INSPECT_RANDOM_ENCHANTS_RESULT, 64);
    response << INSPECT_RESULTS[result];
    if (result != INSPECT_OK)
    {
        response << uint64(0) << uint32(0) << uint32(0) << uint32(0);
        player->SendDirectMessage(&response);
        return;
    }
    response << uint64(state->Progress) << uint32(state->Level);
    AppendSlots(response, state->Presets[state->ActivePreset]);
    response << uint32(state->Known.size());
    for (uint32 spell : state->Known)
        response << uint32(spell);
    player->SendDirectMessage(&response);
}

void HandleActivatePreset(Player* player, State& state, WorldPacket& packet)
{
    uint32 const preset = packet.read<uint32>();
    ClientConfig const config = CurrentClientConfig();
    uint32 const result = CheckPresetActivate(Describe(player, config), preset, uint32(state.Presets.size()));
    uint32 const previous = state.ActivePreset;
    if (result == PRESET_SET_ACTIVE_OK)
    {
        Slots const before = state.Active();
        state.ActivePreset = preset;
        SaveHeader(player, state);
        SyncAuras(player, state);
        SendChangedSlots(player, before, state.Active());
    }
    SendResult(player, SMSG_SET_ACTIVE_RANDOM_ENCHANT_PRESET_RESULT, PRESET_SET_ACTIVE_RESULTS[result]);
    if (result == PRESET_SET_ACTIVE_OK && preset != previous)
        sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::MysticPresetActivated, preset);
}

void HandleUnlockPreset(Player* player, State& state)
{
    ClientConfig const config = CurrentClientConfig();
    uint32 const result = CheckPresetUnlock(Describe(player, config), uint32(state.Presets.size()));
    if (result == PRESET_UNLOCK_OK)
    {
        player->DestroyItemCount(PRESET_UNLOCK_TOKEN, 1, true);
        state.Presets.emplace_back();
        SaveHeader(player, state);
    }
    SendResult(player, SMSG_UNLOCK_RANDOM_ENCHANT_PRESET_RESULT, PRESET_UNLOCK_RESULTS[result]);
}

void Handle(Player* player, WorldPacket& packet)
{
    State* state = Find(player);
    if (!state)
        return;
    packet.rpos(0);
    switch (packet.GetOpcode())
    {
        case CMSG_APPLY_RANDOM_ENCHANT_SLOT: HandleSaveApply(player, *state, packet); break;
        case CMSG_DESTROY_RANDOM_ENCHANT_SLOT: HandleDestroy(player, *state, packet); break;
        case CMSG_PURCHASE_MYSTIC_SCROLL: HandlePurchaseScroll(player); break;
        case CMSG_INSPECT_RANDOM_ENCHANTS: HandleInspect(player, packet); break;
        case CMSG_SET_ACTIVE_RANDOM_ENCHANT_PRESET: HandleActivatePreset(player, *state, packet); break;
        case CMSG_UNLOCK_RANDOM_ENCHANT_PRESET: HandleUnlockPreset(player, *state); break;
        case CMSG_REFORGE_RANDOM_ENCHANT_ITEM: HandleReforgeItem(player, *state, packet); break;
        case CMSG_COLLECTION_REFORGE_RANDOM_ENCHANT_ITEM: HandleCollectionReforgeItem(player, *state, packet); break;
        case CMSG_COLLECTION_REFORGE_RANDOM_ENCHANT_SLOT: HandleSaveCollectionReforge(player, *state, packet); break;
        case CMSG_DISENCHANT_RANDOM_ENCHANT_ITEM: HandleDisenchantItem(player, *state, packet); break;
        case CMSG_DISENCHANT_RANDOM_ENCHANT_SLOT: HandleDisenchantSlot(player, *state, packet); break;
        case CMSG_PURCHASE_MYSTIC_EXTRACT: HandlePurchaseExtract(player, *state); break;
        case CMSG_SET_SPECIALIZATION_MYSTIC_ENCHANT_PRESET_ID:
            HandleSpecializationLink(player, *state, packet);
            break;
        default: break;
    }
}

bool QueueRequest(WorldSession* session, WorldPacket const& packet)
{
    if (!session)
        return true;
    std::lock_guard<std::mutex> lock(PendingLock);
    std::deque<WorldPacket>& queue = PendingRequests[session->GetAccountId()];
    if (queue.size() < MAX_QUEUED_REQUESTS)
        queue.push_back(packet);
    AnyPending = true;
    return true;
}

class AscensionMysticEnchantPlayer final : public PlayerScript
{
public:
    AscensionMysticEnchantPlayer() : PlayerScript("AscensionMysticEnchantPlayer", { PLAYERHOOK_ON_LOGIN,
        PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_DELETE_FROM_DB }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!Ready)
            return;
        State& state = Load(player);
        SyncAuras(player, state);
        SendState(player, state);
        SendSpecializationLinks(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        States.erase(player->GetGUID().GetCounter());
        std::lock_guard<std::mutex> lock(PendingLock);
        PendingRequests.erase(player->GetSession()->GetAccountId());
        AnyPending = !PendingRequests.empty();
    }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        if (!AnyPending)
            return;
        std::deque<WorldPacket> requests;
        {
            std::lock_guard<std::mutex> lock(PendingLock);
            auto itr = PendingRequests.find(player->GetSession()->GetAccountId());
            if (itr == PendingRequests.end())
                return;
            requests = std::move(itr->second);
            PendingRequests.erase(itr);
            AnyPending = !PendingRequests.empty();
        }
        for (WorldPacket& packet : requests)
        {
            try
            {
                Handle(player, packet);
            }
            catch (ByteBufferException const&)
            {
                LOG_INFO("coa", "Dropped a malformed mystic enchant request 0x{:04X} from {}", packet.GetOpcode(),
                    player->GetName());
            }
        }
    }

    void OnPlayerDeleteFromDB(CharacterDatabaseTransaction transaction, uint32 guid) override
    {
        transaction->Append("DELETE FROM coa_mystic_enchant WHERE guid = {}", guid);
        transaction->Append("DELETE FROM coa_mystic_enchant_known WHERE guid = {}", guid);
        transaction->Append("DELETE FROM coa_mystic_enchant_slot WHERE guid = {}", guid);
    }
};

bool IsMysticScroll(uint32 item)
{
    return item == UNTARNISHED_MYSTIC_SCROLL || (Ready && Loaded.FindItem(item));
}

class AscensionMysticEnchantLoot final : public GlobalScript
{
public:
    AscensionMysticEnchantLoot() : GlobalScript("AscensionMysticEnchantLoot", { GLOBALHOOK_ON_ITEM_ROLL }) { }

    bool OnItemRoll(Player const*, LootStoreItem const* item, float& chance, Loot&, LootStore const&) override
    {
        if (!item->reference && !AscensionFreepick::RealmOffersMysticAltars() && IsMysticScroll(item->itemid))
            chance = 0.0f;
        return true;
    }
};

struct SpellLink
{
    std::vector<std::pair<uint32, flag96>> Masks;
    std::vector<int32> Targets;
};

std::unordered_map<uint32, SpellLink> Links;

void AddLinks(SpellLink& link, uint32 spellId, std::unordered_map<uint32, std::vector<int32>> const& affects, uint32 depth)
{
    SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
    if (!spell)
        return;
    if (auto const named = affects.find(spellId); named != affects.end())
        link.Targets.insert(link.Targets.end(), named->second.begin(), named->second.end());
    for (SpellEffectInfo const& effect : spell->GetEffects())
    {
        if (effect.SpellClassMask)
            link.Masks.emplace_back(spell->SpellFamilyName, effect.SpellClassMask);
        if (effect.TriggerSpell && depth < 2)
            AddLinks(link, effect.TriggerSpell, affects, depth + 1);
    }
}

void LoadLinks()
{
    std::unordered_map<uint32, std::vector<int32>> affects;
    for (SpellAffectEntry const* entry : sSpellAffectStore)
        affects[entry->ModifierSpellID].push_back(int32(entry->AffectedSpellID));
    Links.clear();
    for (Enchant const& enchant : Loaded.Rows)
    {
        SpellLink link;
        AddLinks(link, enchant.Spell, affects, 0);
        if (!link.Masks.empty() || !link.Targets.empty())
            Links.emplace(enchant.Spell, std::move(link));
    }
}

struct KnownSpells
{
    std::unordered_map<uint32, flag96> Families;
    std::unordered_set<uint32> Chains;
};

KnownSpells Known(Player const* player)
{
    KnownSpells known;
    for (auto const& [spellId, state] : player->GetSpellMap())
    {
        if (state->State == PLAYERSPELL_REMOVED || !player->HasSpell(spellId))
            continue;
        SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
        if (!spell)
            continue;
        known.Families[spell->SpellFamilyName] |= spell->SpellFamilyFlags;
        known.Chains.insert(spellId);
        known.Chains.insert(sSpellMgr->GetFirstSpellInChain(spellId));
    }
    return known;
}

bool AffectsKnownSpell(KnownSpells const& known, Enchant const& enchant)
{
    auto const link = Links.find(enchant.Spell);
    if (link == Links.end())
        return false;
    for (auto const& [family, mask] : link->second.Masks)
        if (auto const flags = known.Families.find(family); flags != known.Families.end() && (flags->second & mask))
            return true;
    for (int32 target : link->second.Targets)
        if (known.Chains.contains(uint32(target < 0 ? -target : target)))
            return true;
    return false;
}

Enchant const* RevealScroll(Player* player)
{
    Character const character = Describe(player, CurrentClientConfig());
    auto const exists = [](uint32 entry) { return sObjectMgr->GetItemTemplate(entry) != nullptr; };
    if (IsStockClass(character.Class))
        return RollReveal(Loaded, character, exists,
            [&character](Enchant const& enchant) { return ClassAllowed(enchant, character.Class); },
            rand_norm(), rand_norm(), rand_norm());
    KnownSpells const known = Known(player);
    return RollReveal(Loaded, character, exists,
        [&known](Enchant const& enchant) { return AffectsKnownSpell(known, enchant); }, rand_norm(), rand_norm(), rand_norm());
}

class spell_ascension_unidentified_mystic_scroll : public SpellScript
{
    PrepareSpellScript(spell_ascension_unidentified_mystic_scroll);

    SpellCastResult CheckReveal()
    {
        Player* player = GetCaster()->ToPlayer();
        Item* scroll = GetCastItem();
        if (!player || !scroll || scroll->GetEntry() != UNIDENTIFIED_MYSTIC_SCROLL)
            return SPELL_FAILED_DONT_REPORT;
        if (!Ready || !AscensionFreepick::RealmOffersMysticAltars() || IsConquestOfAzerothClass(player->getClass()))
        {
            ChatHandler(player->GetSession()).SendSysMessage("Mystic Enchants are not available on this realm.");
            return SPELL_FAILED_DONT_REPORT;
        }
        if (!player->GetFreeInventorySpace())
        {
            player->SendEquipError(EQUIP_ERR_INVENTORY_FULL, nullptr);
            return SPELL_FAILED_DONT_REPORT;
        }
        return SPELL_CAST_OK;
    }

    void Reveal(SpellEffIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player)
            return;
        Enchant const* enchant = RevealScroll(player);
        ItemPosCountVec destination;
        if (!enchant || player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, enchant->Item, 1) != EQUIP_ERR_OK)
            return;
        if (Item* item = player->StoreNewItem(destination, enchant->Item, true))
            player->SendNewItem(item, 1, true, false);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_unidentified_mystic_scroll::CheckReveal);
        OnEffectHit += SpellEffectFn(spell_ascension_unidentified_mystic_scroll::Reveal, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

constexpr float SCROLL_DROP_CHANCE = 4.0f;
constexpr uint8 SCROLL_DROP_MIN_LEVEL = 10;

class AscensionMysticEnchantScrollDrops final : public MiscScript
{
public:
    AscensionMysticEnchantScrollDrops() : MiscScript("AscensionMysticEnchantScrollDrops",
        { MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS }) { }

    void OnAfterLootTemplateProcess(Loot* loot, LootTemplate const*, LootStore const& store, Player* owner, bool personal,
        bool, uint16 lootMode) override
    {
        if (!loot || !owner || personal || &store != &LootTemplates_Creature || !(lootMode & LOOT_MODE_DEFAULT) ||
            !AscensionFreepick::RealmOffersMysticAltars() || !owner->GetMap() || loot->items.size() >= MAX_NR_LOOT_ITEMS)
            return;
        Creature const* creature = owner->GetMap()->GetCreature(loot->sourceWorldObjectGUID);
        if (!creature || creature->IsPet() || creature->GetCharmerOrOwnerGUID() ||
            creature->GetCreatureType() == CREATURE_TYPE_CRITTER)
            return;
        CreatureTemplate const* creatureTemplate = creature->GetCreatureTemplate();
        if (!creatureTemplate->lootid || !LootTemplates_Creature.HaveLootFor(creatureTemplate->lootid))
            return;

        uint32 const level = creatureTemplate->minlevel;
        uint32 count = 0;
        if (creature->IsDungeonBoss() || creatureTemplate->rank == CREATURE_ELITE_WORLDBOSS)
            count = std::max<uint32>(1, level / 10);
        else if (level > SCROLL_DROP_MIN_LEVEL && roll_chance_f(SCROLL_DROP_CHANCE))
            count = 1;
        if (count)
            loot->AddItem(LootStoreItem(UNIDENTIFIED_MYSTIC_SCROLL, 0, 100.0f, false, LOOT_MODE_DEFAULT, 0, count, count));
    }
};

class AscensionMysticEnchantWorld final : public WorldScript
{
public:
    AscensionMysticEnchantWorld() : WorldScript("AscensionMysticEnchantWorld", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        Ready = LoadCatalog(Loaded);
        if (Ready)
            LoadLinks();
        if (!Ready)
            LOG_ERROR("coa", "Mystic enchants are unavailable: MysticEnchant.dbc did not load");
    }
};
}

bool ApplyGuide(Player* player, std::vector<GuideEnchant> const& guide, bool learnMissing)
{
    State* state = Ready ? Find(player) : nullptr;
    if (!state || guide.empty())
        return false;
    ClientConfig const config = CurrentClientConfig();
    Character character = Describe(player, config);
    character.Known = &state->Known;
    if (learnMissing)
        for (uint32 spell : GuideLessons(Loaded, character, guide))
            Learn(player, *state, spell);
    Slots const before = state->Active();
    Slots const after = GuideSlots(Loaded, character, before, guide);
    if (after == before)
        return false;
    state->Active() = after;
    for (uint32 slot = 0; slot < SLOT_COUNT; ++slot)
        if (before[slot] != after[slot])
            SaveSlot(player, state->ActivePreset, slot, after[slot]);
    SyncAuras(player, *state);
    SendChangedSlots(player, before, after);
    return true;
}

uint32 ClearActivePreset(Player* player)
{
    State* state = Ready ? Find(player) : nullptr;
    if (!state)
        return 0;
    Slots const before = state->Active();
    uint32 cleared = 0;
    for (uint32 slot = 0; slot < SLOT_COUNT; ++slot)
        if (before[slot])
        {
            state->Active()[slot] = 0;
            SaveSlot(player, state->ActivePreset, slot, 0);
            ++cleared;
        }
    if (cleared)
    {
        SyncAuras(player, *state);
        SendChangedSlots(player, before, state->Active());
    }
    return cleared;
}

std::optional<Collection> Summarize(Player const* player)
{
    State const* state = Ready ? Find(player) : nullptr;
    if (!state)
        return std::nullopt;
    uint32 const classId = player->getClass();
    std::array<bool, REALM_COUNT> const gates = AscensionFreepick::RealmGates();
    auto const quality = [classId](Enchant const& enchant)
    {
        return std::min<uint32>(QualityOf(enchant, classId), QUALITY_MAX - 1);
    };
    Collection collection;
    for (Enchant const& enchant : Loaded.Rows)
        if (enchant.Item && ClassAllowed(enchant, classId) && RealmAllows(enchant, gates))
            collection.Offered[quality(enchant)] = true;
    for (uint32 spell : state->Known)
        if (Enchant const* enchant = Loaded.FindSpell(spell))
        {
            ++collection.Known[quality(*enchant)];
            collection.KnownWorldforged += enchant->Worldforged ? 1 : 0;
        }
    collection.KnownTotal = uint32(state->Known.size());
    ClientConfig const config = CurrentClientConfig();
    bool const fusion = Describe(player, config).Fusion();
    Slots const& active = state->Presets[state->ActivePreset];
    for (uint32 slot = 0; slot < SLOT_COUNT; ++slot)
    {
        if (!SlotValid(slot, fusion))
            continue;
        ++collection.OpenSlots;
        if (!active[slot])
            continue;
        ++collection.FilledSlots;
        if (Enchant const* enchant = Loaded.FindSpell(active[slot]))
            ++collection.Active[quality(*enchant)];
    }
    return collection;
}
}

void AddAscensionMysticEnchantScripts()
{
    for (uint16 opcode : AscensionMysticEnchant::CLIENT_OPCODES)
        AscensionCompatOpcodes::Claim(opcode, &AscensionMysticEnchant::QueueRequest);
    RegisterAscensionClientConfig(&AscensionMysticEnchant::AppendExtractCosts);
    new AscensionMysticEnchant::AscensionMysticEnchantPlayer();
    new AscensionMysticEnchant::AscensionMysticEnchantWorld();
    new AscensionMysticEnchant::AscensionMysticEnchantLoot();
    new AscensionMysticEnchant::AscensionMysticEnchantScrollDrops();
    RegisterSpellScriptWithArgs(AscensionMysticEnchant::spell_ascension_unidentified_mystic_scroll,
        "spell_ascension_unidentified_mystic_scroll");
}
