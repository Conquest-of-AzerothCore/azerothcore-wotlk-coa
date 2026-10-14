/*
 * Outfit tool for NPCs, used by the SpawnHelper addon's outfit window:
 *   .npcoutfit <head> <shoulders> <shirt> <chest> <waist> <legs> <feet> <wrists> <hands> <back> <tabard> <main hand> <off hand> <ranged>
 * Fourteen item entries (0 leaves a slot empty) dress the selected NPC's creature entry: the armour becomes the entry's
 * creature_display_preset (item display ids, keeping an existing preset's race, face and hair, or taking race and gender
 * from the NPC's model), the weapons its creature_equip_template. The presets are reloaded and the selected NPC and the
 * other NPCs of that entry nearby are redrawn at once; every other spawn of the entry shows it after a restart.
 *   .npclook [skin|face|hair|haircolor|facialhair] [next|prev|<value>]
 * Changes the selected NPC's skin colour, face, hair style, hair colour or facial hair, using only the choices the client
 * has for the NPC's own race and gender; with no part it reports the current look. Saved in the entry's preset.
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
#include "StringConvert.h"
#include "UnitDefines.h"
#include "WorldPacket.h"
#include <algorithm>
#include <array>
#include <iterator>
#include <list>
#include <set>
#include <sstream>
#include <vector>

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

    // The client's texture choices for one race and gender: the variations of a section, or, given a variation, its colours;
    // a colour narrows the variations to those drawn in that colour (faces per skin colour).
    std::vector<uint8> SectionChoices(uint8 race, uint8 gender, CharSectionType section, int32 variation = -1, int32 color = -1)
    {
        std::set<uint8> values;
        for (CharSectionsEntry const* entry : sCharSectionsStore)
        {
            if (entry->Race != race || entry->Gender != gender || entry->GenType != uint32(section))
                continue;
            if (variation >= 0 && entry->Type != uint32(variation))
                continue;
            if (color >= 0 && entry->Color != uint32(color))
                continue;
            values.insert(uint8(variation >= 0 ? entry->Color : entry->Type));
        }
        return { values.begin(), values.end() };
    }

    // Facial hair (beards, or earrings and markings on some female models) is a geoset choice the barber shop lists.
    std::vector<uint8> FacialHairChoices(uint8 race, uint8 gender)
    {
        std::set<uint8> values = { 0 };
        for (BarberShopStyleEntry const* style : sBarberShopStyleStore)
            if (style->type == 2 && style->race == race && style->gender == gender)
                values.insert(uint8(style->hair_id));
        if (values.size() == 1)
            for (uint8 type : SectionChoices(race, gender, SECTION_TYPE_FACIAL_HAIR))
                values.insert(type);
        return { values.begin(), values.end() };
    }

    struct LookPart
    {
        char const* name;
        char const* column;
    };

    LookPart const LOOK_PARTS[5] = { { "skin", "skin" }, { "face", "face" }, { "hair", "hair" }, { "haircolor", "haircolor" },
                                     { "facialhair", "facialhair" } };

    // The valid values of one part, given the rest of the look (faces depend on skin colour, hair colours on the style).
    std::vector<uint8> LookChoices(std::size_t part, uint8 race, uint8 gender, std::array<uint8, 5> const& look)
    {
        switch (part)
        {
            case 0: return SectionChoices(race, gender, SECTION_TYPE_SKIN, 0);
            case 1:
            {
                std::vector<uint8> faces = SectionChoices(race, gender, SECTION_TYPE_FACE, -1, look[0]);
                return faces.empty() ? SectionChoices(race, gender, SECTION_TYPE_FACE) : faces;
            }
            case 2: return SectionChoices(race, gender, SECTION_TYPE_HAIR);
            case 3: return SectionChoices(race, gender, SECTION_TYPE_HAIR, look[2]);
            default: return FacialHairChoices(race, gender);
        }
    }

    // "3/12": where a value sits among its choices, for the addon's display.
    std::string ChoicePosition(std::vector<uint8> const& choices, uint8 value)
    {
        auto it = std::find(choices.begin(), choices.end(), value);
        return (it == choices.end() ? std::string("?") : std::to_string(it - choices.begin() + 1)) + "/" + std::to_string(choices.size());
    }
}

class coa_npc_outfit_commandscript : public CommandScript
{
public:
    coa_npc_outfit_commandscript() : CommandScript("coa_npc_outfit_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "npcoutfit", HandleNpcOutfitCommand, SEC_GAMEMASTER, Console::No },
            { "npclook",   HandleNpcLookCommand,   SEC_GAMEMASTER, Console::No }
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

    static void ReportLook(ChatHandler* handler, CreatureDisplayPreset const* preset, std::array<uint8, 5> const& look)
    {
        std::ostringstream line;
        line << "npclook:";
        for (std::size_t i = 0; i < 5; ++i)
            line << ' ' << LOOK_PARTS[i].name << ' ' << ChoicePosition(LookChoices(i, preset->race, preset->gender, look), look[i]);
        handler->SendSysMessage(line.str());
    }

    static bool HandleNpcLookCommand(ChatHandler* handler, Optional<std::string> partName, Optional<std::string> value)
    {
        Creature* creature = handler->getSelectedCreature();
        if (!creature || creature->IsPet())
        {
            handler->SendErrorMessage(LANG_SELECT_CREATURE);
            return false;
        }

        uint32 entry = creature->GetEntry();
        CreatureDisplayPreset const* preset = sAscensionPresets->GetPreset(entry, creature->GetDisplayId());
        if (!preset)
            preset = sAscensionPresets->GetPreset(entry);
        if (!preset)
        {
            handler->SendErrorMessage("{} (entry {}) has no outfit preset yet; give it an outfit first, then change its look.",
                creature->GetName(), entry);
            return false;
        }

        std::array<uint8, 5> look = { preset->skin, preset->face, preset->hair, preset->haircolor, preset->facialhair };
        if (!partName)
        {
            ReportLook(handler, preset, look);
            return true;
        }

        std::size_t part = 0;
        while (part < 5 && *partName != LOOK_PARTS[part].name)
            ++part;
        if (part == 5 || !value)
        {
            handler->SendErrorMessage("Usage: .npclook [skin|face|hair|haircolor|facialhair] [next|prev|<value>]");
            return false;
        }

        std::vector<uint8> choices = LookChoices(part, preset->race, preset->gender, look);
        if (choices.empty())
        {
            handler->SendErrorMessage("The client has no {} choices for this NPC's race and gender.", LOOK_PARTS[part].name);
            return false;
        }

        auto it = std::find(choices.begin(), choices.end(), look[part]);
        if (*value == "next")
            look[part] = (it == choices.end() || std::next(it) == choices.end()) ? choices.front() : *std::next(it);
        else if (*value == "prev")
            look[part] = (it == choices.end() || it == choices.begin()) ? choices.back() : *std::prev(it);
        else
        {
            Optional<uint8> number = Acore::StringTo<uint8>(*value);
            if (!number || std::find(choices.begin(), choices.end(), *number) == choices.end())
            {
                handler->SendErrorMessage("{} {} is not one of this race and gender's choices.", LOOK_PARTS[part].name, *value);
                return false;
            }
            look[part] = *number;
        }

        // A new skin colour or hair style can leave the face or hair colour without textures; take the first that has them.
        for (std::size_t dependent : { std::size_t(1), std::size_t(3) })
        {
            std::vector<uint8> valid = LookChoices(dependent, preset->race, preset->gender, look);
            if (!valid.empty() && std::find(valid.begin(), valid.end(), look[dependent]) == valid.end())
                look[dependent] = valid.front();
        }

        WorldDatabase.DirectExecute("UPDATE `creature_display_preset` SET `skin` = " + std::to_string(look[0]) + ", `face` = " +
            std::to_string(look[1]) + ", `hair` = " + std::to_string(look[2]) + ", `haircolor` = " + std::to_string(look[3]) +
            ", `facialhair` = " + std::to_string(look[4]) + " WHERE `entry` = " + std::to_string(entry) + " AND `display_id` = " +
            std::to_string(preset->display_id));

        uint32 displayId = preset->display_id;
        sAscensionPresets->LoadFromDB();
        preset = sAscensionPresets->GetPreset(entry, displayId);
        if (!preset)
        {
            handler->SendErrorMessage("The look was saved but the preset did not load; use .localreloadoutfits.");
            return false;
        }

        std::list<Creature*> nearby;
        creature->GetCreatureListWithEntryInGrid(nearby, entry, 200.0f);
        nearby.push_back(creature);
        nearby.sort();
        nearby.unique();
        for (Creature* npc : nearby)
            if (npc->GetDisplayId() == displayId)
                Redraw(npc, preset);

        ReportLook(handler, preset, look);
        return true;
    }
};

void AddSC_cs_coa_npc_outfit()
{
    new coa_npc_outfit_commandscript();
}
