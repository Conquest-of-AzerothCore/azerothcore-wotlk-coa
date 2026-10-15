/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Item.h"
#include "ItemScript.h"
#include "Player.h"
#include "ScriptMgr.h"

namespace
{
enum BankVoucher : uint32
{
    OrnateBankVoucher = 102130,
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
}

void AddSC_AscensionBankVoucher()
{
    new item_ascension_bank_voucher();
}
