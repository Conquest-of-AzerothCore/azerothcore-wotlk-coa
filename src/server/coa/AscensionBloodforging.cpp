/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBloodforging.h"
#include "AscensionClientSpellPatches.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "DataMap.h"
#include "Errors.h"
#include "GameTime.h"
#include "Item.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "WorldSession.h"
#include <algorithm>
#include <map>
#include <string>
#include <tuple>
#include <vector>

namespace Bloodforging
{
namespace
{
constexpr uint32 BloodyJar = 777999;
constexpr uint32 BloodyJarSpell = 9977999;
constexpr char const* PendingBloodforgeKey = "ascension_bloody_jar_confirmation";
constexpr char const* BloodforgeWarning =
    "Bloodforging an item transforms it into PvP Gear, removing the PvE Power and replacing it with PvP Power.\n\n"
    "Heroic, Mythic or Ascended items will be converted into Normal Bloodforged items.\n\n"
    "This is IRREVERSIBLE.";

enum BloodforgeActions : uint32
{
    ActionBloodforge = GOSSIP_ACTION_INFO_DEF + 1
};

struct PendingBloodforge final : DataMap::Base
{
    ObjectGuid Jar;
    ObjectGuid Target;
    uint32 SourceEntry = 0;
    uint32 BloodforgedEntry = 0;
    Milliseconds Expires = Milliseconds::zero();
    bool Accepted = false;
};

using Appearance = std::tuple<std::string, uint32, uint32, uint32, uint32>;
using Catalogue = std::map<Appearance, std::vector<uint32>>;
using Rank = std::tuple<uint32, uint32, uint32>;

bool BloodforgedTier(ItemTemplate const& item, bool heroic)
{
    return IsBloodforged(item) && (item.Description.find("Heroic") != std::string::npos) == heroic
        && item.Description.find("Mythic") == std::string::npos
        && item.Description.find("Ascended") == std::string::npos;
}

bool Gear(ItemTemplate const& item)
{
    return (item.Class == ITEM_CLASS_ARMOR || item.Class == ITEM_CLASS_WEAPON)
        && item.InventoryType != INVTYPE_NON_EQUIP && item.InventoryType != INVTYPE_BAG
        && item.InventoryType != INVTYPE_BODY && item.InventoryType != INVTYPE_TABARD
        && !item.StartQuest && item.Bonding != BIND_QUEST_ITEM && !item.Duration
        && !item.HasFlag(ITEM_FLAG_CONJURED) && !item.HasFlag(ITEM_FLAG_IS_BOUND_TO_ACCOUNT);
}

Appearance AppearanceOf(ItemTemplate const& item, bool bloodforged)
{
    return {bloodforged ? item.Name1.substr(std::string("Bloodforged ").size()) : item.Name1,
        item.Class, item.SubClass, item.InventoryType, item.DisplayInfoID};
}

Catalogue BuildCatalogue()
{
    Catalogue result;
    for (auto const& [entry, item] : *sObjectMgr->GetItemTemplateStore())
        if ((BloodforgedTier(item, false) || BloodforgedTier(item, true)) && Gear(item))
            result[AppearanceOf(item, true)].push_back(entry);
    return result;
}

bool Compatible(ItemTemplate const& source, ItemTemplate const& target, bool heroic)
{
    if (!BloodforgedTier(target, heroic) || !Gear(target) || target.Quality > source.Quality
        || target.RequiredLevel > source.RequiredLevel || target.ItemLevel > source.ItemLevel
        || target.Bonding == BIND_WHEN_PICKED_UP || target.Bonding == BIND_WHEN_USE
        || AppearanceOf(source, false) != AppearanceOf(target, true)
        || source.socketBonus != target.socketBonus)
        return false;
    for (uint8 slot = 0; slot < MAX_ITEM_PROTO_SOCKETS; ++slot)
        if (source.Socket[slot].Color != target.Socket[slot].Color)
            return false;
    return true;
}

bool Available(Player const* player, Item const* item)
{
    return item && item->GetOwnerGUID() == player->GetGUID() && !item->IsEquipped()
        && player->IsInventoryPos(item->GetPos()) && !item->IsInTrade() && !item->IsWrapped()
        && !item->IsRefundable() && !item->IsBOPTradable();
}

bool ConvertOwned(Player* player, Item* jar, Item* target)
{
    if (!jar || jar->GetEntry() != BloodyJar || !Available(player, jar) || !Available(player, target)
        || player->IsInCombat() || !player->IsAlive() || !FindEntry(*target->GetTemplate()))
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "This item cannot be Bloodforged. Unequip it and check that a matching Bloodforged version exists.");
        return false;
    }
    uint32 const original = target->GetEntry();
    uint32 const count = target->GetCount();
    InventoryResult const capacity = player->CanTakeMoreSimilarItems(
        FindEntry(*target->GetTemplate()), count, target);
    if (capacity != EQUIP_ERR_OK)
    {
        player->SendEquipError(capacity, target, nullptr);
        return false;
    }
    player->ApplyItemObtainSpells(target, false);
    if (!Convert(*target))
    {
        player->ApplyItemObtainSpells(target, true);
        ChatHandler(player->GetSession()).SendSysMessage("No compatible Bloodforged version was found.");
        return false;
    }
    player->ItemRemovedQuestCheck(original, count);
    player->ItemAddedQuestCheck(target->GetEntry(), count);
    player->ApplyItemObtainSpells(target, true);
    target->SetState(ITEM_CHANGED, player);
    target->SendUpdateToPlayer(player);
    auto transaction = CharacterDatabase.BeginTransaction();
    player->SaveInventoryAndGoldToDB(transaction);
    auto committed = CharacterDatabase.AsyncCommitTransaction(transaction);
    if (!committed.m_future.get())
        ABORT("Bloodforging inventory transaction failed; refusing to continue");
    ChatHandler(player->GetSession()).SendSysMessage("Your item has been Bloodforged.");
    return true;
}

SpellCastResult CheckBloodforgeTarget(Player* player, Item* jar, Item* target)
{
    if (!player || !jar || jar->GetEntry() != BloodyJar || !Available(player, jar)
        || !Available(player, target) || !FindEntry(*target->GetTemplate()))
        return SPELL_FAILED_BAD_TARGETS;
    if (player->IsInCombat())
        return SPELL_FAILED_AFFECTING_COMBAT;
    if (!player->IsAlive())
        return SPELL_FAILED_CASTER_DEAD;
    if (player->CanUseItem(jar) != EQUIP_ERR_OK)
        return SPELL_FAILED_BAD_TARGETS;
    if (player->CanTakeMoreSimilarItems(FindEntry(*target->GetTemplate()), target->GetCount(), target)
        != EQUIP_ERR_OK)
        return SPELL_FAILED_TOO_MANY_OF_ITEM;
    return SPELL_CAST_OK;
}

class item_ascension_bloody_jar : public ItemScript
{
public:
    item_ascension_bloody_jar() : ItemScript("item_ascension_bloody_jar") { }

    bool OnUse(Player* player, Item* jar, SpellCastTargets const& targets) override
    {
        player->CustomData.Erase(PendingBloodforgeKey);
        CloseGossipMenuFor(player);
        ClearGossipMenuFor(player);
        player->SendEquipError(EQUIP_ERR_NONE, jar, nullptr);
        Item* target = targets.GetItemTarget();
        SpellCastResult const result = CheckBloodforgeTarget(player, jar, target);
        if (result != SPELL_CAST_OK)
        {
            if (SpellInfo const* info = sSpellMgr->GetSpellInfo(BloodyJarSpell))
                Spell::SendCastResult(player, info, 0, result);
            return true;
        }
        PendingBloodforge* pending = player->CustomData.GetDefault<PendingBloodforge>(PendingBloodforgeKey);
        pending->Jar = jar->GetGUID();
        pending->Target = target->GetGUID();
        pending->SourceEntry = target->GetEntry();
        pending->BloodforgedEntry = FindEntry(*target->GetTemplate());
        pending->Expires = GameTime::GetGameTimeMS() + Milliseconds(60000);
        AddGossipItemFor(player, GOSSIP_ICON_TRAINER, "Bloodforge " + target->GetTemplate()->Name1,
            GOSSIP_SENDER_MAIN, ActionBloodforge, BloodforgeWarning, 0, false);
        SendGossipMenuFor(player, 1, jar->GetGUID());
        return true;
    }

    void OnGossipSelect(Player* player, Item* jar, uint32 sender, uint32 action) override
    {
        CloseGossipMenuFor(player);
        ClearGossipMenuFor(player);
        PendingBloodforge const* pending = player->CustomData.Get<PendingBloodforge>(PendingBloodforgeKey);
        if (!pending)
            return;
        PendingBloodforge confirmation = *pending;
        player->CustomData.Erase(PendingBloodforgeKey);
        Item* target = player->GetItemByGuid(confirmation.Target);
        if (sender != GOSSIP_SENDER_MAIN || action != ActionBloodforge || confirmation.Accepted
            || confirmation.Jar != jar->GetGUID() || GameTime::GetGameTimeMS() >= confirmation.Expires
            || CheckBloodforgeTarget(player, jar, target) != SPELL_CAST_OK
            || target->GetEntry() != confirmation.SourceEntry
            || FindEntry(*target->GetTemplate()) != confirmation.BloodforgedEntry)
        {
            ChatHandler(player->GetSession()).SendSysMessage(
                "Bloodforging confirmation expired or the item is no longer available. Select the item again.");
            return;
        }
        confirmation.Accepted = true;
        *player->CustomData.GetDefault<PendingBloodforge>(PendingBloodforgeKey) = confirmation;
        SpellCastTargets targets;
        targets.SetItemTarget(target);
        player->CastItemUseSpell(jar, targets, 0, 0);
        player->CustomData.Erase(PendingBloodforgeKey);
    }
};

class spell_ascension_bloody_jar : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloody_jar);

    bool _confirmed = false;
    uint32 _sourceEntry = 0;

    SpellCastResult CheckTarget()
    {
        Player* player = GetCaster()->ToPlayer();
        Item* jar = GetCastItem();
        Item* target = GetExplTargetItem();
        SpellCastResult const result = CheckBloodforgeTarget(player, jar, target);
        if (result != SPELL_CAST_OK)
            return result;
        if (!_confirmed)
        {
            PendingBloodforge const* pending = player->CustomData.Get<PendingBloodforge>(PendingBloodforgeKey);
            if (!pending || !pending->Accepted || pending->Jar != jar->GetGUID()
                || pending->Target != target->GetGUID() || pending->SourceEntry != target->GetEntry()
                || pending->BloodforgedEntry != FindEntry(*target->GetTemplate())
                || GameTime::GetGameTimeMS() >= pending->Expires)
                return SPELL_FAILED_BAD_TARGETS;
            _sourceEntry = pending->SourceEntry;
            _confirmed = true;
            player->CustomData.Erase(PendingBloodforgeKey);
        }
        return target->GetEntry() == _sourceEntry ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }

    void Bloodforge(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        Item* target = GetHitItem();
        if (_confirmed && player && target && target->GetEntry() == _sourceEntry)
            ConvertOwned(player, GetCastItem(), target);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_bloody_jar::CheckTarget);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_bloody_jar::Bloodforge, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class bloody_jar_client_query : public PlayerScript
{
public:
    bloody_jar_client_query() : PlayerScript("bloody_jar_client_query", {PLAYERHOOK_ON_LOGIN}) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!player->GetSession()->IsBot())
            player->GetSession()->SendItemQuerySingleResponse(BloodyJar);
    }
};
}

bool IsBloodforged(ItemTemplate const& item)
{
    return item.Name1.starts_with("Bloodforged ") && item.Description.find("Bloodforged") != std::string::npos;
}

uint32 FindEntry(ItemTemplate const& source, Method method)
{
    if (!Gear(source) || IsBloodforged(source))
        return 0;
    static Catalogue const catalogue = BuildCatalogue();
    auto found = catalogue.find(AppearanceOf(source, false));
    if (found == catalogue.end())
        return 0;
    auto select = [&](bool heroic)
    {
        uint32 selected = 0;
        Rank best{};
        bool ambiguous = false;
        for (uint32 entry : found->second)
        {
            ItemTemplate const* target = sObjectMgr->GetItemTemplate(entry);
            if (!target || !Compatible(source, *target, heroic))
                continue;
            Rank rank{source.RequiredLevel - target->RequiredLevel, source.Quality - target->Quality,
                source.ItemLevel - target->ItemLevel};
            if (!selected || rank < best)
            {
                selected = entry;
                best = rank;
                ambiguous = false;
            }
            else if (rank == best)
                ambiguous = true;
        }
        return ambiguous ? 0 : selected;
    };
    if (method == Method::HighRiskDrop && source.Description.find("@Heroic") != std::string::npos)
        if (uint32 entry = select(true))
            return entry;
    return select(false);
}

bool Convert(Item& item, Method method)
{
    ItemTemplate const* source = item.GetTemplate();
    uint32 const entry = FindEntry(*source, method);
    ItemTemplate const* target = sObjectMgr->GetItemTemplate(entry);
    if (!target || item.GetCount() > target->GetMaxStackSize() || item.IsInTrade() || item.IsWrapped()
        || item.IsRefundable() || item.IsBOPTradable())
        return false;
    for (uint8 slot = 0; slot < MAX_ITEM_PROTO_SPELLS; ++slot)
        if (source->Spells[slot].SpellId != target->Spells[slot].SpellId)
            item.SetSpellCharges(slot, target->Spells[slot].SpellCharges);
    item.SetEntry(entry);
    item.SetBinding(false);
    item.SetUInt32Value(ITEM_FIELD_MAXDURABILITY, target->MaxDurability);
    item.SetUInt32Value(ITEM_FIELD_DURABILITY,
        std::min(item.GetUInt32Value(ITEM_FIELD_DURABILITY), target->MaxDurability));
    if (item.GetItemRandomPropertyId() < 0)
        item.UpdateItemSuffixFactor();
    return true;
}
}

void AddSC_AscensionBloodforging()
{
    Ascension::ClientSpellPatches::Instance().Register(Bloodforging::BloodyJarSpell);
    using Bloodforging::spell_ascension_bloody_jar;
    RegisterSpellScript(spell_ascension_bloody_jar);
    new Bloodforging::item_ascension_bloody_jar();
    new Bloodforging::bloody_jar_client_query();
}
