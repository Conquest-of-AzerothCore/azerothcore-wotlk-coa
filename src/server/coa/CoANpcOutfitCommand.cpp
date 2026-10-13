/*
 * Outfit tool for NPCs, used by the SpawnHelper addon's outfit window:
 *   .npcoutfit <head> <shoulders> <shirt> <chest> <waist> <legs> <feet> <wrists> <hands> <back> <tabard> <main hand> <off hand> <ranged>
 * Fourteen item entries (0 leaves a slot empty) dress the selected NPC's creature entry: the armour becomes the entry's
 * creature_display_preset (item display ids, keeping an existing preset's race, face and hair, or taking race and gender
 * from the NPC's model), the weapons its creature_equip_template. The presets are reloaded and the selected NPC and the
 * other NPCs of that entry nearby are redrawn at once; every other spawn of the entry shows it after a restart.
 */

#include "AscensionCreaturePreset.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "Language.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "UnitDefines.h"
#include "WorldPacket.h"
#include <array>
#include <list>
#include <sstream>

using namespace Acore::ChatCommands;

namespace
{
    // Naked base display per playable race and gender, the body a preset dresses.
    uint32 BaseDisplay(uint8 race, uint8 gender)
    {
        switch (race)
        {
            case RACE_HUMAN:         return gender ? 50 : 49;
            case RACE_ORC:           return gender ? 52 : 51;
            case RACE_DWARF:         return gender ? 54 : 53;
            case RACE_NIGHTELF:      return gender ? 56 : 55;
            case RACE_UNDEAD_PLAYER: return gender ? 58 : 57;
            case RACE_TAUREN:        return gender ? 60 : 59;
            case RACE_GNOME:         return gender ? 1564 : 1563;
            case RACE_TROLL:         return gender ? 1479 : 1478;
            case RACE_BLOODELF:      return gender ? 15475 : 15476;
            case RACE_DRAENEI:       return gender ? 16126 : 16125;
            default:                 return 0;
        }
    }

    char const* const PRESET_COLUMNS[11] = { "item_head", "item_shoulders", "item_body", "item_chest", "item_waist", "item_legs",
                                             "item_feet", "item_wrists", "item_hands", "item_back", "item_tabard" };
}

class coa_npc_outfit_commandscript : public CommandScript
{
public:
    coa_npc_outfit_commandscript() : CommandScript("coa_npc_outfit_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "npcoutfit", HandleNpcOutfitCommand, SEC_GAMEMASTER, Console::No }
        };
        return commandTable;
    }

    static void Redraw(Creature* creature, CreatureDisplayPreset const* preset)
    {
        creature->SetDisplayId(preset->display_id);
        creature->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
        WorldPacket data(SMSG_MIRRORIMAGE_DATA, 68);
        data << creature->GetGUID();
        data << uint32(preset->display_id);
        data << uint8(preset->race) << uint8(preset->gender) << uint8(preset->class_id) << uint8(preset->skin);
        data << uint8(preset->face) << uint8(preset->hair) << uint8(preset->haircolor) << uint8(preset->facialhair);
        data << uint32(preset->guild_id);
        for (uint32 item : preset->items)
            data << uint32(item);
        creature->SendMessageToSet(&data, true);
    }

    static bool HandleNpcOutfitCommand(ChatHandler* handler, Tail args)
    {
        std::array<uint32, 14> items = {};
        std::istringstream in{ std::string(args) };
        for (uint32& item : items)
            if (!(in >> item))
            {
                handler->SendErrorMessage("Usage: .npcoutfit followed by 14 item entries (0 for an empty slot).");
                return false;
            }

        Creature* creature = handler->getSelectedCreature();
        if (!creature || creature->IsPet())
        {
            handler->SendErrorMessage(LANG_SELECT_CREATURE);
            return false;
        }
        uint32 entry = creature->GetEntry();

        // Armour: item entries to the item display ids a preset stores.
        std::array<uint32, 11> displays = {};
        for (std::size_t i = 0; i < displays.size(); ++i)
        {
            if (!items[i])
                continue;
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(items[i]);
            if (!proto)
            {
                handler->SendErrorMessage("Item {} does not exist.", items[i]);
                return false;
            }
            displays[i] = proto->DisplayInfoID;
        }

        std::ostringstream set;
        for (std::size_t i = 0; i < displays.size(); ++i)
            set << (i ? ", " : "") << '`' << PRESET_COLUMNS[i] << "` = " << displays[i];

        if (sAscensionPresets->HasPreset(entry))
        {
            WorldDatabase.DirectExecute("UPDATE `creature_display_preset` SET " + set.str() + " WHERE `entry` = " + std::to_string(entry));
        }
        else
        {
            // No preset yet: take race from the NPC's model and gender from its model info, and dress the naked body.
            uint32 modelDisplay = creature->GetNativeDisplayId();
            CreatureDisplayInfoEntry const* info = sCreatureDisplayInfoStore.LookupEntry(modelDisplay);
            CreatureDisplayInfoExtraEntry const* extra = info ? sCreatureDisplayInfoExtraStore.LookupEntry(info->ExtendedDisplayInfoID) : nullptr;
            CreatureModelInfo const* modelInfo = sObjectMgr->GetCreatureModelInfo(modelDisplay);
            uint8 race = extra ? uint8(extra->DisplayRaceID) : 0;
            uint8 gender = modelInfo && modelInfo->gender == GENDER_FEMALE ? 1 : 0;
            uint32 base = BaseDisplay(race, gender);
            if (!base)
            {
                handler->SendErrorMessage("{} (entry {}) is not on a playable-race model, so it cannot wear an outfit. Give it a race first.",
                    creature->GetName(), entry);
                return false;
            }

            std::ostringstream cols, vals;
            for (std::size_t i = 0; i < displays.size(); ++i)
            {
                cols << ", `" << PRESET_COLUMNS[i] << '`';
                vals << ", " << displays[i];
            }
            WorldDatabase.DirectExecute("INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, "
                "`face`, `hair`, `haircolor`, `facialhair`, `guild_id`" + cols.str() + ") VALUES (" + std::to_string(entry) + ", " +
                std::to_string(base) + ", " + std::to_string(race) + ", " + std::to_string(gender) + ", 1, 0, 0, 0, 0, 0, 0" + vals.str() + ")");
            WorldDatabase.DirectExecute("DELETE FROM `creature_template_model` WHERE `CreatureID` = " + std::to_string(entry));
            WorldDatabase.DirectExecute("INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, "
                "`Probability`, `VerifiedBuild`) VALUES (" + std::to_string(entry) + ", 0, " + std::to_string(base) + ", 1, 1, 0)");
        }

        // Weapons: what the entry holds, live on the NPCs redrawn below and from the database after a restart.
        WorldDatabase.DirectExecute("DELETE FROM `creature_equip_template` WHERE `CreatureID` = " + std::to_string(entry) + " AND `ID` = 1");
        if (items[11] || items[12] || items[13])
        {
            WorldDatabase.DirectExecute("INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) "
                "VALUES (" + std::to_string(entry) + ", 1, " + std::to_string(items[11]) + ", " + std::to_string(items[12]) + ", " +
                std::to_string(items[13]) + ", 0)");
            WorldDatabase.DirectExecute("UPDATE `creature` SET `equipment_id` = 1 WHERE `id` = " + std::to_string(entry) + " AND `equipment_id` = 0");
        }

        sAscensionPresets->LoadFromDB();
        CreatureDisplayPreset const* preset = sAscensionPresets->GetPreset(entry);
        if (!preset)
        {
            handler->SendErrorMessage("The outfit was saved but the preset did not load; use .localreloadoutfits.");
            return false;
        }

        std::list<Creature*> nearby;
        creature->GetCreatureListWithEntryInGrid(nearby, entry, 200.0f);
        nearby.push_back(creature);
        nearby.sort();
        nearby.unique();
        for (Creature* npc : nearby)
        {
            Redraw(npc, preset);
            for (uint8 slot = 0; slot < 3; ++slot)
                npc->SetVirtualItem(slot, items[11 + slot]);
        }

        handler->PSendSysMessage("Outfit saved for {} (entry {}) and shown on {} nearby. Other spawns of it show it after a restart.",
            creature->GetName(), entry, uint32(nearby.size()));
        return true;
    }
};

void AddSC_cs_coa_npc_outfit()
{
    new coa_npc_outfit_commandscript();
}
