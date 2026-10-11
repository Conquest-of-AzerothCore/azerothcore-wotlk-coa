/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionFreepick.h"
#include "AscensionFreepickRules.h"
#include "AscensionCoATalentState.h"
#include "AscensionWildcard.h"
#include "Battleground.h"
#include "Chat.h"
#include "Config.h"
#include "GameEventMgr.h"
#include "Item.h"
#include "Log.h"
#include "Map.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "Tokenize.h"
#include "World.h"
#include <algorithm>
#include <unordered_set>

namespace AscensionFreepick
{
Realm ReadRealm()
{
    Realm realm;
    std::string const types = sConfigMgr->GetOption<std::string>("CoA.RealmType", "live");
    for (std::string_view type : Acore::Tokenize(types, ' ', false))
    {
        realm.Live = realm.Live || type == "live";
        realm.Seasonal = realm.Seasonal || type == "seasonal";
        realm.League = realm.League || type == "league";
        realm.Ptr = realm.Ptr || type == "ptr";
        realm.Development = realm.Development || type == "development";
    }
    if (!realm.Live && !realm.Seasonal && !realm.League && !realm.Ptr && !realm.Development)
        realm.Live = true;
    std::string const model = sConfigMgr->GetOption<std::string>("CoA.ClassModel", "coa");
    realm.ConquestOfAzeroth = model == "coa";
    realm.WarcraftReborn = model == "wcr";
    uint32 const maxLevel = sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);
    realm.Ruleset = maxLevel <= 60 ? 0 : maxLevel <= 70 ? 1 : 2;
    return realm;
}

namespace
{
constexpr char BUILD_SETTING[] = "core.freepick";
constexpr std::uint16_t COA_CLASS_TRAINERS_EVENT = 195;
constexpr char ACTIVE_SPECIALIZATION_SETTING[] = "core.ascension_slot.active";
constexpr std::uint32_t RANK_FACTOR = 10;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_ACTIVE_SPEC = 0x0725;
constexpr uint16 SMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES = 0x0726;

Catalog Loaded;
Realm CurrentRealm;
bool Classless = false;
bool MysticAltars = false;
bool Reborn = false;

std::string SpecializationBuildSetting(std::uint32_t index)
{
    return std::string(BUILD_SETTING) + ".build." + std::to_string(index);
}

std::string SpecializationBarSetting(std::uint32_t index)
{
    return std::string(BUILD_SETTING) + ".bar." + std::to_string(index);
}

std::vector<Entry> StoredEntries(Player const* player, std::string const& setting = BUILD_SETTING)
{
    std::vector<Entry> entries;
    PlayerSettingVector const* stored = player->FindPlayerSettings(setting);
    if (!stored || stored->empty())
        return entries;
    std::size_t const count = std::min<std::size_t>((*stored)[0].value, stored->size() - 1);
    for (std::size_t index = 1; index <= count; ++index)
    {
        uint32 const value = (*stored)[index].value;
        Entry const entry{ value / RANK_FACTOR, value % RANK_FACTOR };
        if (entry.Rank && Loaded.Find(entry.EntryId))
            entries.push_back(entry);
    }
    return entries;
}

void Store(Player* player, std::vector<Entry> const& entries, std::string const& setting = BUILD_SETTING)
{
    std::size_t previous = 0;
    if (PlayerSettingVector const* stored = player->FindPlayerSettings(setting))
        previous = stored->size();
    player->UpdatePlayerSetting(setting, 0, uint32(entries.size()));
    for (std::size_t index = 0; index < entries.size(); ++index)
        player->UpdatePlayerSetting(setting, uint32(index + 1),
            entries[index].EntryId * RANK_FACTOR + entries[index].Rank);
    for (std::size_t index = entries.size() + 1; index < previous; ++index)
        player->UpdatePlayerSetting(setting, uint32(index), 0);
}

void StoreActionBars(Player* player, std::uint32_t specialization)
{
    std::string const setting = SpecializationBarSetting(specialization);
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
    {
        ActionButton const* action = player->GetActionButton(button);
        player->UpdatePlayerSetting(setting, button, action ? action->packedData : 0);
    }
}

void RestoreActionBars(Player* player, std::uint32_t specialization)
{
    PlayerSettingVector const* stored = player->FindPlayerSettings(SpecializationBarSetting(specialization));
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
    {
        uint32 const packed = stored && button < stored->size() ? (*stored)[button].value : 0;
        if (packed)
            player->addActionButton(button, ACTION_BUTTON_ACTION(packed), uint8(ACTION_BUTTON_TYPE(packed)));
    }
    player->SendActionButtons(1);
}

void SendSpecializationState(Player* player)
{
    WorldPacket active(SMSG_CHARACTER_ADVANCEMENT_ACTIVE_SPEC, sizeof(uint32) * 2);
    active << ActiveSpecialization(player) << uint32(AscensionWildcard::SPECIALIZATION_COUNT);
    player->SendDirectMessage(&active);
    std::vector<uint8> const body = AscensionCoATalentState::KnownEntriesPayload(KnownEntries(player));
    WorldPacket known(SMSG_CHARACTER_ADVANCEMENT_KNOWN_ENTRIES, body.size());
    known.append(body.data(), body.size());
    player->SendDirectMessage(&known);
}

UnitCheck UnitRules(Player const* player)
{
    return [player](std::uint32_t slot, Row const& row)
    {
        switch (slot)
        {
            case LEARN_NOT_IN_BATTLEGROUNDS:
            {
                if (row.Type == ENTRY_TALENT || !player->GetMap()->IsBattlegroundOrArena())
                    return true;
                if (player->GetMap()->IsBattleArena())
                    return false;
                Battleground const* battleground = player->GetBattleground();
                return !battleground || battleground->GetStatus() != STATUS_IN_PROGRESS;
            }
            case LEARN_NOT_IN_COMBAT:
                return !player->IsInCombat() || (row.Type == ENTRY_TALENT && player->GetMap()->IsDungeon());
            case LEARN_INVULNERABLE:
                return !player->HasAuraType(SPELL_AURA_SCHOOL_IMMUNITY);
            case LEARN_NOT_WHILE_DEAD:
                return player->IsAlive();
            default:
                return true;
        }
    };
}

std::vector<uint32> LearnEffectSpells(uint32 spellId)
{
    std::vector<uint32> spells;
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
    if (!spellInfo)
        return spells;
    for (SpellEffectInfo const& effect : spellInfo->Effects)
        if (effect.Effect == SPELL_EFFECT_LEARN_SPELL && effect.TriggerSpell &&
            !sSpellMgr->IsAdditionalTalentSpell(effect.TriggerSpell))
            spells.push_back(effect.TriggerSpell);
    return spells;
}

std::vector<uint32> RankSpells(uint32 spellId)
{
    return TaughtSpells(spellId, &LearnEffectSpells);
}

std::unordered_set<uint32> GrantedSpells(std::vector<Entry> const& entries)
{
    std::unordered_set<uint32> spells;
    for (Entry const& entry : entries)
        if (Row const* row = Loaded.Find(entry.EntryId); row && entry.Rank && entry.Rank <= row->MaxRank())
            for (uint32 spellId : RankSpells(row->Spells[entry.Rank - 1]))
                spells.insert(spellId);
    return spells;
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

void ClearActionBars(Player* player)
{
    player->SendActionButtons(2);
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
        player->removeActionButton(button);
}

void SyncSpells(Player* player, std::vector<Entry> const& before, std::vector<Entry> const& after,
    bool keepActionBars = true)
{
    std::unordered_set<uint32> const granted = GrantedSpells(after);
    std::unordered_set<uint32> removed;
    for (Entry const& entry : before)
        if (Row const* row = Loaded.Find(entry.EntryId))
            for (std::uint32_t rank = row->MaxRank(); rank > 0; --rank)
                for (uint32 spellId : RankSpells(row->Spells[rank - 1]))
                {
                    if (granted.contains(spellId) || !player->HasSpell(spellId))
                        continue;
                    player->removeSpell(spellId, SPEC_MASK_ALL, false);
                    removed.insert(spellId);
                }
    for (uint32 spellId : granted)
        if (!player->HasSpell(spellId))
            player->learnSpell(spellId);
    if (keepActionBars)
        RemoveFromActionBars(player, removed);
}
}

bool RealmIsClassless()
{
    return Classless;
}

bool RealmOffersMysticAltars()
{
    return MysticAltars;
}

bool IsFreepickHero(Player const* player)
{
    return Classless && player->getClass() == CLASS_HERO && !AscensionWildcard::IsWildcardHero(player);
}

bool IsRebornCharacter(Player const* player)
{
    uint8 const classId = player->getClass();
    return Reborn && classId >= CLASS_WARRIOR && classId <= CLASS_DRUID && classId != CLASS_HERO;
}

bool HasFreepickBuild(Player const* player)
{
    return IsFreepickHero(player) || IsRebornCharacter(player);
}

std::vector<AscensionCoATalentState::KnownEntry> KnownEntries(Player const* player)
{
    std::vector<AscensionCoATalentState::KnownEntry> known;
    std::vector<Entry> const entries = StoredEntries(player);
    for (std::size_t index = 0; index < entries.size(); ++index)
        known.push_back({ entries[index].EntryId, entries[index].Rank, entries[index].Rank, false, uint32(index + 1) });
    return known;
}

UploadResult ApplyUpload(Player* player, std::vector<AscensionCoATalentState::KnownEntry> const& upload)
{
    std::vector<Entry> wanted;
    for (AscensionCoATalentState::KnownEntry const& entry : upload)
        wanted.push_back({ entry.EntryId, entry.Rank });

    Build const base(Loaded, CurrentRealm, player->GetLevel(), StoredEntries(player), player->getClass());
    UnitCheck const unit = UnitRules(player);
    ApplyCheck const check = CheckApply(base, wanted, unit,
        { player->GetMoney(), player->GetItemCount(MARK_OF_ASCENSION_ITEM, false) });
    if (check.Result != UPDATE_OK)
    {
        LOG_INFO("coa", "Refused free-pick upload of {} record(s) from {}: {} {} entry {} rank {}", upload.size(),
            player->GetName(), UPDATE_RESULTS[check.Result], LEARN_RESULTS[check.Learn], check.Failed.EntryId,
            check.Failed.Rank);
        return { UPDATE_RESULTS[check.Result], check.Learn ? LEARN_RESULTS[check.Learn] : "", check.Failed.EntryId,
            check.Failed.Rank };
    }

    Build next(base);
    next.SetEntries(check.Entries);
    next.AutoLearn(unit);
    if (check.Marks)
        player->DestroyItemCount(MARK_OF_ASCENSION_ITEM, check.Marks, true);
    if (check.Money)
        player->ModifyMoney(-int32(check.Money));
    Store(player, next.Entries());
    SyncSpells(player, base.Entries(), next.Entries());
    LOG_INFO("coa", "Applied free-pick build of {}: {} entries, {} AE and {} TE spent, charged {} copper and {} marks",
        player->GetName(), next.Entries().size(), next.GlobalAE(0), next.GlobalTE(0), check.Money, check.Marks);
    return {};
}

std::uint32_t ActiveSpecialization(Player const* player)
{
    PlayerSettingVector const* stored = player->FindPlayerSettings(ACTIVE_SPECIALIZATION_SETTING);
    std::uint32_t const index = stored && !stored->empty() ? (*stored)[0].value : 0;
    return index < AscensionWildcard::SPECIALIZATION_COUNT ? index : 0;
}

bool SwitchSpecialization(Player* player, std::uint32_t index, std::string& error)
{
    if (!IsFreepickHero(player) || index >= AscensionWildcard::SPECIALIZATION_COUNT ||
        !player->HasSpell(AscensionWildcard::SPECIALIZATION_SWAP_SPELLS[index]))
    {
        error = "That specialization slot is not unlocked.";
        return false;
    }
    std::uint32_t const previous = ActiveSpecialization(player);
    if (index == previous)
        return true;

    std::vector<Entry> const before = StoredEntries(player);
    Build next(Loaded, CurrentRealm, player->GetLevel(), StoredEntries(player, SpecializationBuildSetting(index)));
    next.AutoLearn(UnitRules(player));
    Store(player, before, SpecializationBuildSetting(previous));
    StoreActionBars(player, previous);
    if (Pet* pet = player->GetPet())
        player->RemovePet(pet, PET_SAVE_NOT_IN_SLOT);
    player->ClearAllReactives();
    player->UnsummonAllTotems();
    player->RemoveAllControlled();
    ClearActionBars(player);
    Store(player, next.Entries());
    player->UpdatePlayerSetting(ACTIVE_SPECIALIZATION_SETTING, 0, index);
    SyncSpells(player, before, next.Entries(), false);
    RestoreActionBars(player, index);
    player->SaveToDB(false, false);
    SendSpecializationState(player);
    LOG_INFO("coa", "{} switched free-pick specialization {} -> {} ({} entries)", player->GetName(), previous + 1,
        index + 1, next.Entries().size());
    return true;
}

class spell_ascension_freepick_specialization_swap : public SpellScript
{
    PrepareSpellScript(spell_ascension_freepick_specialization_swap);

    std::uint32_t _index = 0;

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        auto const& spells = AscensionWildcard::SPECIALIZATION_SWAP_SPELLS;
        auto const found = std::find(spells.begin(), spells.end(), GetSpellInfo()->Id);
        if (!player || !IsFreepickHero(player) || found == spells.end())
            return false;
        _index = std::uint32_t(found - spells.begin());
        return true;
    }

    SpellCastResult CheckSpecialization()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player->HasSpell(AscensionWildcard::SPECIALIZATION_SWAP_SPELLS[_index]))
            return SPELL_FAILED_NOT_KNOWN;
        if (player->IsInCombat())
            return SPELL_FAILED_AFFECTING_COMBAT;
        return SPELL_CAST_OK;
    }

    void Switch(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Player* player = GetCaster()->ToPlayer();
        std::string error;
        if (!SwitchSpecialization(player, _index, error))
        {
            ChatHandler(player->GetSession()).SendSysMessage(error);
            SendSpecializationState(player);
        }
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_freepick_specialization_swap::CheckSpecialization);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_freepick_specialization_swap::Switch, EFFECT_0,
            SPELL_EFFECT_TALENT_SPEC_SELECT);
    }
};

void Synchronize(Player* player)
{
    if (!HasFreepickBuild(player))
        return;
    if (IsFreepickHero(player))
    {
        if (player->GetActiveSpec())
            player->ActivateSpec(0);
        if (!player->HasSpell(AscensionWildcard::SPECIALIZATION_SWAP_SPELLS[0]))
            player->learnSpell(AscensionWildcard::SPECIALIZATION_SWAP_SPELLS[0]);
    }
    std::vector<Entry> const stored = StoredEntries(player);
    Build build(Loaded, CurrentRealm, player->GetLevel(), stored, player->getClass());
    if (build.AutoLearn(UnitRules(player)))
        Store(player, build.Entries());
    SyncSpells(player, stored, build.Entries());
}

std::array<bool, 5> RealmGates()
{
    return { CurrentRealm.Live, CurrentRealm.Seasonal, CurrentRealm.League, CurrentRealm.Ptr,
        CurrentRealm.Development };
}

std::uint32_t InvestedEssence(Player const* player, std::uint32_t classType, std::uint32_t tab, bool talent)
{
    constexpr std::uint32_t WHOLE = 1;
    if (!HasFreepickBuild(player))
        return 0;
    Build const build(Loaded, CurrentRealm, player->GetLevel(), StoredEntries(player), player->getClass());
    if (classType == WHOLE)
        return talent ? build.GlobalTE(0) : build.GlobalAE(0);
    if (tab == WHOLE)
        return talent ? build.ClassTE(classType, 0) : build.ClassAE(classType, 0);
    return talent ? build.TabTE(classType, tab, 0) : build.TabAE(classType, tab, 0);
}

class AscensionFreepickPlayer final : public PlayerScript
{
public:
    AscensionFreepickPlayer() : PlayerScript("AscensionFreepickPlayer", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        Synchronize(player);
    }
};

class AscensionFreepickWorld final : public WorldScript
{
public:
    AscensionFreepickWorld() : WorldScript("AscensionFreepickWorld", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        CurrentRealm = ReadRealm();
        Classless = sConfigMgr->GetOption<std::string>("CoA.ClassModel", "coa") == "hero";
        Reborn = CurrentRealm.WarcraftReborn;
        MysticAltars = (Classless || Reborn) &&
            !AscensionWildcard::PlaysWildcard(sConfigMgr->GetOption<std::string>("CoAChallenges.GameModes.Realm", ""));
        if (CurrentRealm.ConquestOfAzeroth)
            sGameEventMgr->StartInternalEvent(COA_CLASS_TRAINERS_EVENT);
        if ((Classless || Reborn) && !LoadCatalog(Loaded))
            LOG_ERROR("coa", "Free-pick Character Advancement is unavailable: its client DBCs did not load");
    }
};
}

void ApplyAscensionPathPassiveContract(SpellInfo* spellInfo)
{
    constexpr int32 TWO_HANDED_WEAPONS = 0x1562;
    constexpr int32 ONE_HANDED_MELEE_WEAPONS = 0xA091;
    constexpr uint32 AGILE_STRIKES = 986201;
    switch (spellInfo->Id)
    {
        case 986202: case 986200: case 92839: case 92842: case 129245:
            spellInfo->EquippedItemClass = ITEM_CLASS_WEAPON;
            spellInfo->EquippedItemSubClassMask = TWO_HANDED_WEAPONS;
            break;
        case 986203: case AGILE_STRIKES: case 92840: case 92843: case 129246:
            spellInfo->EquippedItemClass = ITEM_CLASS_WEAPON;
            spellInfo->EquippedItemSubClassMask = ONE_HANDED_MELEE_WEAPONS;
            break;
        default:
            return;
    }
    if (spellInfo->Id != AGILE_STRIKES)
        return;
    SpellEffectInfo& cost = spellInfo->Effects[EFFECT_0];
    if (cost.ApplyAuraName != SPELL_AURA_DUMMY)
    {
        LOG_ERROR("coa", "Skipped unexpected Agile Strikes record {}", spellInfo->Id);
        return;
    }
    cost.ApplyAuraName = SPELL_AURA_MOD_POWER_COST_SCHOOL_PCT;
    cost.MiscValue = SPELL_SCHOOL_MASK_NORMAL;
    cost.BasePoints = -9;
}

namespace
{
class ghostly_strike_contracts : public GlobalScript
{
public:
    ghostly_strike_contracts() : GlobalScript("ghostly_strike_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == 965819 && info->Effects[EFFECT_2].ApplyAuraName == 229)
            info->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_MOD_PARRY_PERCENT;
    }
};

class spell_ascension_ghostly_strike : public SpellScript
{
    PrepareSpellScript(spell_ascension_ghostly_strike);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({965819});
    }

    void Defend(SpellEffIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player)
            return;
        Item const* weapon = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND);
        bool const twoHanded = weapon && weapon->GetTemplate()->InventoryType == INVTYPE_2HWEAPON &&
            !player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
        int32 const amount = sSpellMgr->AssertSpellInfo(965819)->Effects[EFFECT_1].CalcValue(player);
        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_BASE_POINT1, twoHanded ? 0 : amount);
        values.AddSpellMod(SPELLVALUE_BASE_POINT2, twoHanded ? amount : 0);
        player->CastCustomSpell(965819, values, player, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_ghostly_strike::Defend, EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};
}

void AddAscensionFreepickScripts()
{
    new AscensionFreepick::AscensionFreepickPlayer();
    new AscensionFreepick::AscensionFreepickWorld();
    new ghostly_strike_contracts();
    RegisterSpellScript(spell_ascension_ghostly_strike);
    RegisterSpellScriptWithArgs(AscensionFreepick::spell_ascension_freepick_specialization_swap,
        "spell_ascension_freepick_specialization_swap");
}
