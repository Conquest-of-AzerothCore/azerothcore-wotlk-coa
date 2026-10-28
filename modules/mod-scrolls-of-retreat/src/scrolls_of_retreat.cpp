/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
/*
 * mod-scrolls-of-retreat - the faction gate on the two capital Scrolls of Retreat.
 *
 * The live realm keeps each capital scroll to its own side:
 *
 *     item 1175626 "Scroll of Retreat: Stormwind" -> spell 84289 -> Stormwind, Alliance only
 *     item 1175627 "Scroll of Retreat: Orgrimmar" -> spell 84288 -> Orgrimmar, Horde only
 *
 * The destinations are data (data/sql/updates/pending_db_world/rev_20260926_81_retreat_and_defense_scrolls.sql);
 * the faction half is not.
 * item_template cannot say "this faction": AllowableRace and AllowableClass speak about races and
 * classes, and the client's own refusal for those is its generic red cast error, which would say
 * nothing about the scroll. So the refusal is answered here, in the shape mod-treasure-keeper
 * answers its ruleset refusal to: the same sentence to the middle of the screen and to the chat
 * log, in the realm's own notification yellow with the refused faction painted in its colour.
 *
 * The gate is an AllItemScript and not an ItemScript on purpose. An ItemScript is reached through
 * item_template.ScriptName, and these two rows belong to the core's warchest file
 * (data/sql/updates/pending_db_world/rev_20260924_10_coa_warchest_item_templates.sql): a ScriptName
 * put on them by a module would be wiped the next time that file's REPLACE is re-applied, and the
 * gate would go quiet without a word. An AllItemScript is keyed on the entry in code, so no data
 * change anywhere can empty it. Spells 84288 and 84289 are carried by these two items and by
 * nothing else in the world database, so the two entries are the whole reach of this script.
 *
 * The order in the core (WorldSession::HandleUseItemOpcode): ScriptMgr::OnItemUse is asked before
 * the cast, and a true answer means the script has answered the request - the cast is skipped, so
 * nothing is consumed and no cooldown is started and a refused scroll is left exactly as it was.
 * The client grays the item the moment its request goes out, and only the core's own answer would
 * have released it, hence the native acknowledgement (Player::SendEquipError with EQUIP_ERR_NONE)
 * that the repack's other item scripts send for the same reason.
 */

#include "AllItemScript.h"
#include "Chat.h"
#include "DataMap.h"
#include "Item.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "SharedDefines.h"
#include "Timer.h"
#include "WorldPacket.h"
#include "WorldScript.h"

#include <string>

namespace
{
// The same two namesakes as the item rows in scrolls_of_retreat.sql.
enum ScrollOfRetreat : uint32
{
    ScrollOfRetreatStormwind = 1175626,
    ScrollOfRetreatOrgrimmar = 1175627
};

// The colours: ffffff00 is the realm's notification yellow (the one mod-treasure-keeper's own notices
// are written on), 4c9aff the Alliance blue and ff2020 the Horde red. Both strings open on the yellow
// explicitly, because the notification is drawn yellow by the client's own hand and the chat copy is
// meant to read alike. The chat line carries the scroll as the client's real item link, in the
// colour the core gives a quality 6 item (ItemQualityColors[6] = ffe6cc80), so the line is
// clickable like any other item reference. The notification opcode cannot draw link markup, so it
// names the scroll plainly and the two strings stay the same sentence.
constexpr char const* STORMWIND_NOTICE =
    "|cffffff00The Scroll of Retreat: Stormwind can only be used by |cff4c9affAlliance|r|cffffff00 characters.|r";
constexpr char const* STORMWIND_CHAT =
    "|cffffff00The |cffe6cc80|Hitem:1175626:0:0:0:0:0:0:0:0:0|h[Scroll of Retreat: Stormwind]|h|r"
    "|cffffff00 can only be used by |cff4c9affAlliance|r|cffffff00 characters.|r";

constexpr char const* ORGRIMMAR_NOTICE =
    "|cffffff00The Scroll of Retreat: Orgrimmar can only be used by |cffff2020Horde|r|cffffff00 characters.|r";
constexpr char const* ORGRIMMAR_CHAT =
    "|cffffff00The |cffe6cc80|Hitem:1175627:0:0:0:0:0:0:0:0:0|h[Scroll of Retreat: Orgrimmar]|h|r"
    "|cffffff00 can only be used by |cffff2020Horde|r|cffffff00 characters.|r";

/// A request the client never saw an answer for is one it repeats, so the line is announced at most
/// this often per character - the interval mod-teleport-actionbar holds its stone refusal to.
constexpr uint32 REFUSAL_NOTICE_INTERVAL_MS = 3000;
constexpr char REFUSAL_NOTICE_KEY[] = "scrolls.retreat.refusal";

/// Per character, and alive for exactly as long as the character's own object: nothing here is
/// persisted and there is no map to prune when a character logs out.
struct RefusalNotice : DataMap::Base
{
    uint32 Last = 0;
};

/// One line, in both places at once: SMSG_NOTIFICATION, the opcode this realm's notices go out on
/// (the client draws one notification per packet and the line is read where the player is looking),
/// and the chat log. `notice` and `chat` are the same sentence; only the link markup differs.
void SendRefusal(Player* player, Item* item, std::string const& notice, std::string const& chat)
{
    // Every attempt is answered: the scroll stays refused, and the client only releases the item it
    // grayed out for the request once that request is acknowledged.
    player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);

    uint32 const now = getMSTime();
    RefusalNotice* last = player->CustomData.GetDefault<RefusalNotice>(REFUSAL_NOTICE_KEY);
    if (last->Last && now - last->Last < REFUSAL_NOTICE_INTERVAL_MS)
        return;     // the player is looking at this same line already
    last->Last = now;

    WorldPacket data(SMSG_NOTIFICATION, notice.size() + 1);
    data << notice;
    player->SendDirectMessage(&data);

    ChatHandler(player->GetSession()).SendSysMessage(chat);
}

/// The gate is silent by nature: it only ever speaks to a character of the wrong faction, so a realm
/// where the gate never registered looks exactly like a realm where nobody tried it on the wrong
/// side. One line at startup says which one this is, and says so loudly if a scroll has no item row
/// at all - an item with no row cannot be created, so the gate would have nothing to guard.
class scrolls_of_retreat_readiness : public WorldScript
{
public:
    scrolls_of_retreat_readiness()
        : WorldScript("scrolls_of_retreat_readiness", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        Report(ScrollOfRetreatStormwind, "Scroll of Retreat: Stormwind", "Alliance");
        Report(ScrollOfRetreatOrgrimmar, "Scroll of Retreat: Orgrimmar", "Horde");
    }

private:
    static void Report(uint32 entry, char const* name, char const* faction)
    {
        if (!sObjectMgr->GetItemTemplate(entry))
        {
            LOG_ERROR("module.scrolls_of_retreat", "\"{}\" (entry {}) has no row in `item_template`, so "
                      "it cannot be created at all and the {}-only gate has nothing to guard.", name, entry, faction);
            return;
        }

        LOG_INFO("module.scrolls_of_retreat", "\"{}\" (entry {}) is {}-only: anyone else's use is "
                 "answered with one line to the screen and the chat log.", name, entry, faction);
    }
};

class scroll_of_retreat_faction : public AllItemScript
{
public:
    scroll_of_retreat_faction() : AllItemScript("scroll_of_retreat_faction") { }

    /// Asked about every item use in the realm - ScriptMgr::OnItemUse consults the AllItemScripts
    /// before the item's own script - so anything that is not a Scroll of Retreat is left alone with
    /// the plainest answer there is. A true answer means the use was answered here and the item's
    /// spell is never cast.
    bool CanItemUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        TeamId required;
        char const* notice;
        char const* chat;

        switch (item->GetEntry())
        {
            case ScrollOfRetreatStormwind:
                required = TEAM_ALLIANCE;
                notice = STORMWIND_NOTICE;
                chat = STORMWIND_CHAT;
                break;
            case ScrollOfRetreatOrgrimmar:
                required = TEAM_HORDE;
                notice = ORGRIMMAR_NOTICE;
                chat = ORGRIMMAR_CHAT;
                break;
            default:
                return false;   // not one of ours: no opinion, the core casts as it always did
        }

        if (player->GetTeamId() == required)
            return false;       // the scroll's own side: its teleport spell is the client's

        SendRefusal(player, item, notice, chat);
        return true;
    }
};
}

void AddSC_scrolls_of_retreat()
{
    new scroll_of_retreat_faction();
    new scrolls_of_retreat_readiness();
}
