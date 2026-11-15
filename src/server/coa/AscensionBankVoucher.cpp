/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Chat.h"
#include "Guild.h"
#include "Item.h"
#include "ItemScript.h"
#include "Player.h"
#include "ScriptMgr.h"

namespace
{
enum BankVoucher : uint32
{
    OrnateBankVoucher = 102130,
    GuildVaultVoucher = 102131,
    UnlockVisual = 47292
};

class item_ascension_bank_voucher : public ItemScript
{
public:
    item_ascension_bank_voucher() : ItemScript("item_ascension_bank_voucher") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (item->GetEntry() != OrnateBankVoucher)
            return false;

        player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);
        constexpr uint8 bankSlots = BANK_SLOT_BAG_END - BANK_SLOT_BAG_START;
        if (!player->IsAlive() || player->IsInCombat() || player->GetBankBagSlotCount() >= bankSlots)
            return true;

        player->SetBankBagSlotCount(bankSlots);
        player->UpdateAchievementCriteria(ACHIEVEMENT_CRITERIA_TYPE_BUY_BANK_SLOT);
        uint32 count = 1;
        player->DestroyItemCount(item, count, true);

        player->CastSpell(player, UnlockVisual, true);
        return true;
    }
};

class item_ascension_guild_vault_voucher : public ItemScript
{
public:
    item_ascension_guild_vault_voucher() : ItemScript("item_ascension_guild_vault_voucher") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (item->GetEntry() != GuildVaultVoucher)
            return false;

        player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);

        ChatHandler handler(player->GetSession());
        Guild* guild = player->GetGuild();
        if (!guild || guild->GetLeaderGUID() != player->GetGUID())
        {
            handler.SendSysMessage("Only a guild master can unlock a guild vault tab.");
            return true;
        }

        if (!guild->HandleUnlockBankTab(player->GetSession()))
        {
            handler.SendSysMessage("Your guild vault already owns every tab.");
            return true;
        }

        handler.SendSysMessage("A new tab has been unlocked in your guild vault.");
        uint32 count = 1;
        player->DestroyItemCount(item, count, true);
        return true;
    }
};
}

void AddSC_AscensionBankVoucher()
{
    new item_ascension_bank_voucher();
    new item_ascension_guild_vault_voucher();
}
