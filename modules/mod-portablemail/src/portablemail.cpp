/*
 * mod-portablemail - the world objects CoA's portable gadgets summon.
 *
 * The gadgets are ordinary items whose on-use spell creates a temporary world object: the
 * Gnomish Portable Post Tube is a mailbox, the transpolyporters are spellcasters, the Mystic
 * Enchanting Altar is a binder. The spell is a SPELL_EFFECT_TRANS_DOOR, so the core spawns the
 * gameobject named in its MiscValue after looking it up in `gameobject_template`, and returns
 * early - objectless, with an error in the log - when that row is missing.
 *
 * The world database held none of those rows, so the items did nothing. The rows are restored by
 * data/sql/db-world/portablemail.sql, which the DB updater applies at startup. That file also
 * carries the Fel Gateway's spell override, which sets its lifetime to the 30 seconds its own
 * text promises.
 *
 * What this module itself does:
 *   * checks once at startup that each gadget's whole chain is intact - the item sells the
 *     spell, the spell lives as long as the gadget says it does, and the object it spawns is
 *     present with the type, model and size the realm shipped - so a database reset cannot
 *     silently kill the gadgets a second time;
 *   * exposes `.portablemail status` so a game master can see the same list on demand.
 *
 * The module never creates or grants items. Values and provenance are in the SQL file and in
 * this module's README.
 */

#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "GameObject.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"

#include <array>
#include <cmath>
#include <string>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
enum PortableMailSpells : uint32
{
    SPELL_TRANSPOLYPORTER_TELEPORT = 979612
};

// One portable gadget: the object its spell spawns, what that object should be, and the item and
// spell that lead to it. `objectLifetimeMs` is how long the object is meant to stand, which the
// spell takes from its DurationIndex via SpellDuration.dbc.
struct PortableGadget
{
    uint32 objectEntry;
    uint32 objectType;
    uint32 displayId;
    float objectSize;
    uint32 itemEntry;
    uint32 spellId;
    uint32 objectLifetimeMs;
    char const* objectName;
};

// Expected values are the realm's own, recovered from the live client caches; see
// data/sql/db-world/portablemail.sql for the provenance of each row. The lifetimes are the ones
// the gadgets advertise in their own text: 3 minutes for the post tube, 5 for the altar, 30
// seconds for both transpolyporters - the Fel Gateway's is set by the spell_dbc row in that file.
constexpr std::array<PortableGadget, 4> PortableGadgets =
{{
    { 1903511, GAMEOBJECT_TYPE_MAILBOX,      12003,  0.75f, 1903512, 985210, 180000, "Gnomish Portable Post Tube" },
    { 1903510, GAMEOBJECT_TYPE_SPELLCASTER,   2047,  1.00f, 1903510, 979611,  30000,
        "Gnomish Portable Transpolyporter" },
    { 1903512, GAMEOBJECT_TYPE_BINDER,      12004,  0.50f, 1903513, 985211, 300000, "Portable Mystic Altar" },
    { 1903520, GAMEOBJECT_TYPE_SPELLCASTER, 138000,  1.00f, 1903515, 979411,  30000,
        "Demonic Portable Transpolyporter" },
}};

// Spell durations are milliseconds, and -1 means "until cancelled".
std::string Lifetime(int32 ms)
{
    if (ms < 0)
        return "permanent";
    if (ms && ms % 60000 == 0)
        return std::to_string(ms / 60000) + "m";
    return std::to_string(ms / 1000) + "s";
}

char const* TypeName(uint32 type)
{
    switch (type)
    {
        case GAMEOBJECT_TYPE_MAILBOX:     return "mailbox";
        case GAMEOBJECT_TYPE_SPELLCASTER: return "spellcaster";
        case GAMEOBJECT_TYPE_BINDER:      return "binder";
        default:                          return "object";
    }
}

// Every broken link in the chain, empty when the gadget is exactly what the realm shipped.
std::vector<std::string> GadgetProblems(PortableGadget const& gadget)
{
    std::vector<std::string> problems;

    ItemTemplate const* item = sObjectMgr->GetItemTemplate(gadget.itemEntry);
    if (!item)
        problems.push_back("no row in item_template");
    else
    {
        if (item->Spells[0].SpellId != int32(gadget.spellId))
            problems.push_back("item spells " + std::to_string(item->Spells[0].SpellId) + ", expected " +
                std::to_string(gadget.spellId));
        if (item->Spells[0].SpellTrigger != ITEM_SPELLTRIGGER_ON_USE)
            problems.push_back("item spell is not triggered on use");
    }

    SpellInfo const* spell = sSpellMgr->GetSpellInfo(gadget.spellId);
    if (!spell)
        problems.push_back("spell " + std::to_string(gadget.spellId) + " is not in the server's spell data");
    else
    {
        if (spell->GetDuration() != int32(gadget.objectLifetimeMs))
            problems.push_back("spell lives " + Lifetime(spell->GetDuration()) + ", expected " +
                Lifetime(gadget.objectLifetimeMs));

        // EffectTransmitted reads the object entry from this effect's MiscValue.
        SpellEffectInfo const& effect = spell->Effects[EFFECT_0];
        if (effect.Effect != SPELL_EFFECT_TRANS_DOOR)
            problems.push_back("spell's first effect does not summon a world object");
        else if (effect.MiscValue != int32(gadget.objectEntry))
            problems.push_back("spell summons object " + std::to_string(effect.MiscValue) + ", expected " +
                std::to_string(gadget.objectEntry));
    }

    GameObjectTemplate const* info = sObjectMgr->GetGameObjectTemplate(gadget.objectEntry);
    if (!info)
        problems.push_back("no row in gameobject_template");
    else if (info->type != gadget.objectType)
        problems.push_back("object type " + std::to_string(info->type) + ", expected " +
            std::to_string(gadget.objectType));
    else if (info->displayId != gadget.displayId)
        problems.push_back("object displayId " + std::to_string(info->displayId) + ", expected " +
            std::to_string(gadget.displayId));
    else if (std::fabs(info->size - gadget.objectSize) > 0.001f)
        problems.push_back("object size " + std::to_string(info->size) + ", expected " +
            std::to_string(gadget.objectSize));

    // The summon can succeed while the portal's click action is missing or points at another spell.
    if (info && info->type == GAMEOBJECT_TYPE_SPELLCASTER && gadget.objectType == GAMEOBJECT_TYPE_SPELLCASTER)
    {
        if (info->spellcaster.spellId != SPELL_TRANSPOLYPORTER_TELEPORT)
            problems.push_back("object casts spell " + std::to_string(info->spellcaster.spellId) + ", expected " +
                std::to_string(SPELL_TRANSPOLYPORTER_TELEPORT));
        if (!sSpellMgr->GetSpellInfo(info->spellcaster.spellId))
            problems.push_back("object's click spell " + std::to_string(info->spellcaster.spellId) +
                " is not in the server's spell data");
    }

    return problems;
}

std::string Join(std::vector<std::string> const& parts)
{
    std::string joined;
    for (std::string const& part : parts)
        joined += (joined.empty() ? "" : "; ") + part;
    return joined;
}

// One line describing a gadget: what it is, how long it lives and whether it works.
std::string StatusLine(PortableGadget const& gadget)
{
    SpellInfo const* spell = sSpellMgr->GetSpellInfo(gadget.spellId);
    std::vector<std::string> const problems = GadgetProblems(gadget);
    return "  " + std::string(gadget.objectName) + " [" + TypeName(gadget.objectType) + "] - item " +
           std::to_string(gadget.itemEntry) + " -> spell " + std::to_string(gadget.spellId) + " (" +
           (spell ? "lives " + Lifetime(spell->GetDuration()) : std::string("no spell data")) +
           ") -> object " + std::to_string(gadget.objectEntry) + ": " +
           (problems.empty() ? std::string("ok") : "BROKEN - " + Join(problems));
}
} // namespace

class PortableMailWorldScript : public WorldScript
{
public:
    PortableMailWorldScript() : WorldScript("PortableMailWorldScript") { }

    void OnStartup() override
    {
        if (!sConfigMgr->GetOption<bool>("PortableMail.VerifyOnStartup", true))
            return;

        uint32 ready = 0;
        for (PortableGadget const& gadget : PortableGadgets)
        {
            std::vector<std::string> const problems = GadgetProblems(gadget);
            if (problems.empty())
            {
                ++ready;
                continue;
            }

            LOG_ERROR("sql.sql", "mod-portablemail: '{}' has invalid data - {}. Item {} / spell {} / object {}. "
                      "See modules/mod-portablemail/data/sql/db-world/portablemail.sql.",
                      gadget.objectName, Join(problems), gadget.itemEntry, gadget.spellId, gadget.objectEntry);
        }

        if (ready == PortableGadgets.size())
            LOG_INFO("server.loading", ">> mod-portablemail: all {} portable gadgets are complete "
                     "(item, spell and world object).", ready);
        else
            LOG_WARN("server.loading", ">> mod-portablemail: {}/{} portable gadgets have the expected data; "
                     "see the problems listed below.",
                     ready, PortableGadgets.size());

        for (PortableGadget const& gadget : PortableGadgets)
            LOG_INFO("server.loading", "{}", StatusLine(gadget));
    }
};

class PortableMailCommandScript : public CommandScript
{
public:
    PortableMailCommandScript() : CommandScript("PortableMailCommandScript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable portableMailCommandTable =
        {
            { "status", HandleStatusCommand, SEC_GAMEMASTER, Console::Yes },
            { "",       HandleStatusCommand, SEC_GAMEMASTER, Console::Yes },
        };

        static ChatCommandTable commandTable =
        {
            { "portablemail", portableMailCommandTable },
        };

        return commandTable;
    }

    static bool HandleStatusCommand(ChatHandler* handler)
    {
        handler->SendSysMessage("Portable gadgets - item -> spell (lifetime) -> world object:");
        for (PortableGadget const& gadget : PortableGadgets)
            handler->SendSysMessage(StatusLine(gadget));
        return true;
    }
};

void AddSC_portablemail()
{
    new PortableMailWorldScript();

    if (sConfigMgr->GetOption<bool>("PortableMail.Command", true))
        new PortableMailCommandScript();
}
