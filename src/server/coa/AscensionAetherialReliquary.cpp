/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionAetherialReliquary.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "Log.h"
#include "Mail.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "StringFormat.h"
#include "World.h"

#include <string>
#include <string_view>

namespace AetherialReliquary
{
namespace
{
constexpr std::string_view CapturedMessage =
    "Your Experience boosts have been preserved in your Aetherial Boon Reliquary.";
constexpr std::string_view EmptyMessage = "Your Aetherial Reliquary holds no stored buffs.";
constexpr std::string_view BelowMaxLevelMessage = "Your stored experience buffs only work below max level.";
constexpr std::string_view SaveFailedMessage =
    "Your Aetherial Reliquary could not be saved. Contact a game master.";
constexpr char MailSubject[] = "Aetherial Reliquary";
constexpr char MailBody[] = "Your bags were full, so your Aetherial Reliquary was sent by mail.";

std::string const& Source()
{
    static std::string const source(SettingSource);
    return source;
}

std::string_view ReasonName(CaptureReason reason)
{
    switch (reason)
    {
        case CaptureReason::RealmCap:
            return "realm level cap";
    }
    return "unknown";
}

std::string Describe(StoredBuffs const& buffs)
{
    std::string description;
    for (std::size_t i = 0; i < StorableBuffs.size(); ++i)
    {
        if (!description.empty())
            description += ", ";
        description += Acore::StringFormat("{}={}", StorableBuffs[i].spellId, buffs.values[i]);
    }
    return description;
}

Aura* OwnAura(Player* player, uint32 spellId)
{
    return player->GetAura(spellId, player->GetGUID());
}

StoredBuffs ActiveBuffs(Player* player)
{
    StoredBuffs active;
    for (std::size_t i = 0; i < StorableBuffs.size(); ++i)
    {
        Aura const* aura = OwnAura(player, StorableBuffs[i].spellId);
        if (!aura)
            continue;

        if (StorableBuffs[i].kind == BuffKind::Toggle)
            active.values[i] = 1;
        else if (aura->GetDuration() > 0)
            active.values[i] = uint32(aura->GetDuration());
    }
    return active;
}

void Write(Player* player, StoredBuffs const& stored)
{
    for (std::size_t i = 0; i < StorableBuffs.size(); ++i)
        player->UpdatePlayerSetting(Source(), StorableBuffs[i].settingIndex, stored.values[i]);
}

bool OwnsReliquary(Player const* player)
{
    if (player->GetItemCount(ReliquaryItem, true))
        return true;

    for (Mail const* mail : player->GetMails())
    {
        if (mail->state == MAIL_STATE_DELETED)
            continue;

        for (MailItemInfo const& item : mail->items)
            if (item.item_template == ReliquaryItem)
                return true;
    }
    return false;
}

bool Deliver(Player* player, CharacterDatabaseTransaction trans)
{
    ItemPosCountVec destination;
    if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, ReliquaryItem, 1) == EQUIP_ERR_OK)
    {
        Item* item = player->StoreNewItem(destination, ReliquaryItem, true);
        if (!item)
            return false;

        player->SendNewItem(item, 1, true, false);
        return true;
    }

    Item* item = Item::CreateItem(ReliquaryItem, 1, player);
    if (!item)
        return false;

    item->SaveToDB(trans);
    MailDraft(MailSubject, MailBody)
        .AddItem(item)
        .SendMailTo(trans, MailReceiver(player), MailSender(player));
    return true;
}

bool Commit(Player* player, CharacterDatabaseTransaction trans, std::string_view action)
{
    player->SaveToDB(trans, false, false);
    if (CharacterDatabase.AsyncCommitTransaction(trans).m_future.get())
        return true;

    LOG_ERROR("coa", "Aetherial Reliquary {} for {} ({}) was rolled back by the character database.", action,
        player->GetName(), player->GetGUID().ToString());
    ChatHandler(player->GetSession()).SendNotification(SaveFailedMessage);
    return false;
}

void ApplyBuff(Player* player, StorableBuff const& buff, uint32 value)
{
    if (!value)
        return;

    Aura* aura = OwnAura(player, buff.spellId);
    if (buff.kind == BuffKind::Toggle)
    {
        if (!aura && !player->AddAura(buff.spellId, player))
            LOG_ERROR("coa", "Aetherial Reliquary could not restore aura {} to {} ({}).", buff.spellId,
                player->GetName(), player->GetGUID().ToString());
        return;
    }

    uint32 const remaining = aura && aura->GetDuration() > 0 ? uint32(aura->GetDuration()) : 0;
    if (!aura)
        aura = player->AddAura(buff.spellId, player);
    if (!aura)
    {
        LOG_ERROR("coa", "Aetherial Reliquary could not restore aura {} ({} ms) to {} ({}).", buff.spellId, value,
            player->GetName(), player->GetGUID().ToString());
        return;
    }

    int32 const duration = int32(AddDuration(remaining, value));
    aura->SetMaxDuration(duration);
    aura->SetDuration(duration);
}
}

bool IsAtCaptureLevel(Player const* player, CaptureReason reason)
{
    if (!player)
        return false;

    switch (reason)
    {
        case CaptureReason::RealmCap:
            return player->GetLevel() >= sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);
    }
    return false;
}

StoredBuffs GetStored(Player const* player)
{
    StoredBuffs stored;
    if (!player)
        return stored;

    PlayerSettingVector const* settings = player->FindPlayerSettings(Source());
    if (!settings)
        return stored;

    for (std::size_t i = 0; i < StorableBuffs.size(); ++i)
        if (StorableBuffs[i].settingIndex < settings->size())
            stored.values[i] = (*settings)[StorableBuffs[i].settingIndex].value;
    return stored;
}

bool CaptureBuffs(Player* player, CaptureReason reason)
{
    if (!player)
        return false;

    StoredBuffs const active = ActiveBuffs(player);
    if (active.Empty())
        return false;

    StoredBuffs const before = GetStored(player);
    StoredBuffs const after = Merge(before, active);
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    bool const issued = !OwnsReliquary(player);
    if (issued && !Deliver(player, trans))
    {
        LOG_ERROR("coa", "Aetherial Reliquary could not be delivered to {} ({}); {} stayed active.",
            player->GetName(), player->GetGUID().ToString(), Describe(active));
        return false;
    }

    for (StorableBuff const& buff : StorableBuffs)
        player->RemoveAurasDueToSpell(buff.spellId);
    Write(player, after);

    bool const saved = Commit(player, trans, "capture");
    LOG_INFO("coa", "Aetherial Reliquary captured {} from {} ({}) at the {}: stored {} -> {}{}.", Describe(active),
        player->GetName(), player->GetGUID().ToString(), ReasonName(reason), Describe(before), Describe(after),
        issued ? ", reliquary issued" : "");
    if (saved)
        ChatHandler(player->GetSession()).SendNotification(CapturedMessage);
    return saved;
}

bool RestoreBuffs(Player* player)
{
    if (!player)
        return false;

    StoredBuffs const stored = GetStored(player);
    if (stored.Empty())
        return false;

    for (std::size_t i = 0; i < StorableBuffs.size(); ++i)
        ApplyBuff(player, StorableBuffs[i], stored.values[i]);
    Write(player, StoredBuffs{});

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    bool const saved = Commit(player, trans, "restore");
    LOG_INFO("coa", "Aetherial Reliquary restored {} to {} ({}).", Describe(stored), player->GetName(),
        player->GetGUID().ToString());
    return saved;
}

class Displacement final : public SpellScript
{
    PrepareSpellScript(Displacement);

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player)
            return SPELL_FAILED_DONT_REPORT;

        if (GetStored(player).Empty())
        {
            ChatHandler(player->GetSession()).SendNotification(EmptyMessage);
            return SPELL_FAILED_DONT_REPORT;
        }

        if (IsAtCaptureLevel(player, CaptureReason::RealmCap))
        {
            CaptureBuffs(player, CaptureReason::RealmCap);
            ChatHandler(player->GetSession()).SendNotification(BelowMaxLevelMessage);
            return SPELL_FAILED_DONT_REPORT;
        }

        return SPELL_CAST_OK;
    }

    void Restore()
    {
        if (Player* player = GetCaster()->ToPlayer())
            RestoreBuffs(player);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(Displacement::CheckCast);
        AfterCast += SpellCastFn(Displacement::Restore);
    }
};
}

void AddSC_AscensionAetherialReliquary()
{
    RegisterSpellScript(AetherialReliquary::Displacement);
}
