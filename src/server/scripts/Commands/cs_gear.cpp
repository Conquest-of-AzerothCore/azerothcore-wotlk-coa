/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "Chat.h"
#include "CommandScript.h"
#include "Language.h"
#include "Mail.h"
#include "Player.h"
#include "RBAC.h"
#include "WorldSession.h"

using namespace Acore::ChatCommands;

class gear_commandscript : public CommandScript
{
public:
    gear_commandscript() : CommandScript("gear_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable gearCommandTable =
        {
            { "repair",  HandleGearRepairCommand, rbac::RBAC_PERM_COMMAND_GEAR_REPAIR, Console::No },
            { "stats",   HandleGearStatsCommand,  rbac::RBAC_PERM_COMMAND_GEAR_STATS,  Console::No },
            { "unequip", HandleGearUnequipCommand, rbac::RBAC_PERM_COMMAND_GEAR_UNEQUIP, Console::Yes }
        };

        static ChatCommandTable commandTable =
        {
            { "gear", gearCommandTable }
        };

        return commandTable;
    }

    static bool HandleGearRepairCommand(ChatHandler* handler, Optional<PlayerIdentifier> target)
    {
        if (!target)
        {
            target = PlayerIdentifier::FromTargetOrSelf(handler);
        }

        if (!target || !target->IsConnected())
        {
            return false;
        }

        // check online security
        if (handler->HasLowerSecurity(target->GetConnectedPlayer()))
        {
            return false;
        }

        // Repair items
        target->GetConnectedPlayer()->DurabilityRepairAll(false, 0, false);

        std::string nameLink = handler->playerLink(target->GetName());

        handler->PSendSysMessage(LANG_YOU_REPAIR_ITEMS, nameLink);

        if (handler->needReportToTarget(target->GetConnectedPlayer()))
        {
            ChatHandler(target->GetConnectedPlayer()->GetSession()).PSendSysMessage(LANG_YOUR_ITEMS_REPAIRED, nameLink);
        }

        return true;
    }

    static bool HandleGearUnequipCommand(ChatHandler* handler,
        Variant<EXACT_SEQUENCE("all"), ItemTemplate const*> items, uint8 mailAll, Optional<PlayerIdentifier> target)
    {
        if (mailAll > 1)
        {
            handler->SendErrorMessage("Use 0 to move the items into the bags, or 1 to mail them.");
            return false;
        }

        if (!target)
        {
            target = PlayerIdentifier::FromTargetOrSelf(handler);
        }

        if (!target || !target->IsConnected())
        {
            handler->SendErrorMessage(LANG_PLAYER_NOT_FOUND);
            return false;
        }

        Player* player = target->GetConnectedPlayer();
        if (handler->HasLowerSecurity(player))
        {
            return false;
        }

        std::vector<uint8> slots;
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        {
            Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            if (!item)
            {
                continue;
            }

            if (items.holds_alternative<ItemTemplate const*>())
            {
                if (item->GetEntry() != items.get<ItemTemplate const*>()->ItemId)
                {
                    continue;
                }

                slots.push_back(slot);
                break;
            }

            slots.push_back(slot);
        }

        if (items.holds_alternative<ItemTemplate const*>() && slots.empty())
        {
            handler->SendErrorMessage("{} does not have item {} equipped.", handler->playerLink(target->GetName()),
                items.get<ItemTemplate const*>()->ItemId);
            return false;
        }

        uint32 storedCount = 0;
        std::vector<Item*> mailItems;
        for (uint8 slot : slots)
        {
            Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            ItemPosCountVec dest;
            if (!mailAll && player->CanStoreItem(NULL_BAG, NULL_SLOT, dest, item, false) == EQUIP_ERR_OK)
            {
                player->RemoveItem(INVENTORY_SLOT_BAG_0, slot, true);
                player->StoreItem(dest, item, true);
                ++storedCount;
                continue;
            }

            player->MoveItemFromInventory(INVENTORY_SLOT_BAG_0, slot, true);
            mailItems.push_back(item);
        }

        if (!mailItems.empty())
        {
            WorldSession* session = handler->GetSession();
            uint32 senderGuid = session ? session->GetPlayer()->GetGUID().GetCounter() : 0;
            MailSender sender(MAIL_NORMAL, senderGuid, MAIL_STATIONERY_GM);
            CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
            for (std::size_t first = 0; first < mailItems.size(); first += MAX_MAIL_ITEMS)
            {
                MailDraft draft("Unequipped items", "A Game Master removed your equipped items.");
                std::size_t last = std::min(first + MAX_MAIL_ITEMS, mailItems.size());
                for (std::size_t i = first; i < last; ++i)
                {
                    mailItems[i]->DeleteFromInventoryDB(trans);
                    mailItems[i]->SaveToDB(trans);
                    draft.AddItem(mailItems[i]);
                }

                draft.SendMailTo(trans, MailReceiver(player), sender, MAIL_CHECK_MASK_COPIED);
            }

            CharacterDatabase.CommitTransaction(trans);
        }

        player->UpdateTitansGrip();

        std::string nameLink = handler->playerLink(target->GetName());
        handler->PSendSysMessage("Unequipped {}: {} item(s) moved to the bags, {} item(s) sent by mail.", nameLink,
            storedCount, mailItems.size());

        if (handler->needReportToTarget(player))
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "{} unequipped your gear: {} item(s) moved to your bags, {} item(s) sent to your mailbox.",
                handler->GetNameLink(), storedCount, mailItems.size());
        }

        return true;
    }

    static bool HandleGearStatsCommand(ChatHandler* handler)
    {
        Player* player = handler->getSelectedPlayerOrSelf();

        if (!player)
        {
            return false;
        }

        handler->PSendSysMessage("Character: {}", player->GetPlayerName());
        handler->PSendSysMessage("Current equipment average item level: |cff00ffff{}|r", (int16)player->GetAverageItemLevel());

        if (sWorld->getIntConfig(CONFIG_MIN_LEVEL_STAT_SAVE))
        {
            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHAR_STATS);
            stmt->SetData(0, player->GetGUID().GetCounter());
            PreparedQueryResult result = CharacterDatabase.Query(stmt);

            if (result)
            {
                Field* fields = result->Fetch();
                uint32 MaxHealth = fields[0].Get<uint32>();
                uint32 Strength = fields[1].Get<uint32>();
                uint32 Agility = fields[2].Get<uint32>();
                uint32 Stamina = fields[3].Get<uint32>();
                uint32 Intellect = fields[4].Get<uint32>();
                uint32 Spirit = fields[5].Get<uint32>();
                uint32 Armor = fields[6].Get<uint32>();
                uint32 AttackPower = fields[7].Get<uint32>();
                uint32 SpellPower = fields[8].Get<uint32>();
                uint32 Resilience = fields[9].Get<uint32>();

                handler->PSendSysMessage("Health: |cff00ffff{}|r - Stamina: |cff00ffff{}|r", MaxHealth, Stamina);
                handler->PSendSysMessage("Strength: |cff00ffff{}|r - Agility: |cff00ffff{}|r", Strength, Agility);
                handler->PSendSysMessage("Intellect: |cff00ffff{}|r - Spirit: |cff00ffff{}|r", Intellect, Spirit);
                handler->PSendSysMessage("AttackPower: |cff00ffff{}|r - SpellPower: |cff00ffff{}|r", AttackPower, SpellPower);
                handler->PSendSysMessage("Armor: |cff00ffff{}|r - Resilience: |cff00ffff{}|r", Armor, Resilience);
            }
        }

        return true;
    }
};

void AddSC_gear_commandscript()
{
    new gear_commandscript();
}
