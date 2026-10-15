/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

// Destiny Weaver: the leveling-experience NPC.
//
// The live realm fronted two per-character choices with ten "Destiny Weaver" creatures - five
// models, two names each - and this realm has neither the creatures nor the choices. What is
// restored here is the menu and the two settings behind it; the creatures and their gossip text
// are in the module's SQL revision.
//
//   * Open World Scaling        - the open-world creatures this character fights and the quest
//                                 levels they read and play at. Each character is sent their own
//                                 version of a creature (destiny_weaver_scaling.cpp), so a level-30
//                                 and a level-20 character see one level-15 creature at 27 and 17.
//   * Experience Bonus Control  - the bonus experience sources (potions, auras, recruit-a-friend)
//                                 stop paying, so the character progresses at the base rate; the
//                                 stripping itself is in destiny_weaver_xp.cpp.
//
// Both are stored per character. A character that never chose scaling follows the realm default,
// which is how the realm behaves today; Experience Bonus Control is opt-in.
//
// The menu is the live realm's, taken from a screenshot of the original gossip: the greeting is
// npc_text 30520 and the two options read
//
//   Experience bonuses! <state>      (experience first, then scaling)
//   Open world scaling! <state>
//
// with <state> green while the choice is on and red while it is off. Each option paints its own
// icon through an inline texture escape in the option text rather than the option's icon byte:
//
//   |TInterface/ICONS/<name>:40:40:-22:0|t|r<label>
//
// 40x40, pulled 22px left so it hangs over the row's left edge. That is how an Ascension menu
// carries these icons - an archive observation of a live menu (npc 6740, the Stormwind innkeeper)
// records the same shape with inv_misc_rune_01 and inv_misc_bag_10 - and it is the only way to
// reach art outside the client's own gossip icon set. Both icons were confirmed in game against the
// captured screenshot: the scaling one is nhi_corruptionpower and the experience one is
// nhi_infernaltome, the burning tome. Nothing else in the menu deviates from the capture, including
// the absence of a third option.
#include "destiny_weaver.h"

#include "Chat.h"
#include "Config.h"
#include "Creature.h"
#include "Group.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Opcodes.h"
#include "Player.h"
#include "ScriptedGossip.h"
#include "ScriptMgr.h"
#include "StringFormat.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include "AscensionCompatOpcodes.h"

#include <mutex>
#include <optional>
#include <unordered_map>

namespace
{
    struct PendingScalingChoice
    {
        ObjectGuid PlayerGuid;
        std::optional<bool> Enabled;
    };

    // Only logged-in characters can receive a choice. Session pointers are identity keys only,
    // removed on logout; player state is accessed exclusively by the player hooks below.
    std::mutex g_scalingChoiceLock;
    std::unordered_map<WorldSession const*, PendingScalingChoice> g_scalingChoices;

    /// Stored value of a choice: 0 = the character never made one, 1 = on, 2 = off. Keeping "never
    /// chose" distinct from "chose off" is what lets a realm default exist without rewriting every
    /// character's row the first time the default changes.
    constexpr uint32 CHOICE_UNSET = 0;
    constexpr uint32 CHOICE_ON = 1;
    constexpr uint32 CHOICE_OFF = 2;

    /// The gossip's own sender id. Distinctive, so a stray gossip menu cannot reach these actions.
    constexpr uint32 GOSSIP_SENDER_DESTINY_WEAVER = 0xD357;

    /// The greeting the live NPC opened with. The id was free in this realm's npc_text, so the
    /// original numbering stays. The pointer text that sends new characters here is npc_text 19175.
    constexpr uint32 GOSSIP_TEXT_GREETING = 30520;

    /// The two option icons, as named in the capture. See the header for where they come from.
    constexpr char const* ICON_EXPERIENCE_BONUS = "nhi_infernaltome";
    constexpr char const* ICON_OPEN_WORLD_SCALING = "nhi_corruptionpower";

    /// The green / red the original paints the state in. The trailing |r closes both the colour
    /// and the texture escape that precedes the label.
    constexpr char const* STATE_ENABLED = "|cff00ff00ENABLED";
    constexpr char const* STATE_DISABLED = "|cffff2020DISABLED";

    enum DestinyWeaverAction : uint32
    {
        ACTION_TOGGLE_SCALING = 1,
        ACTION_TOGGLE_EXPERIENCE_BONUS_CONTROL
    };

    /// One option row: the icon escape, then the label, then the state word in its colour.
    std::string OptionText(char const* icon, char const* label, bool enabled)
    {
        return Acore::StringFormat("|TInterface/ICONS/{}:40:40:-22:0|t|r{} {}", icon, label,
                                   enabled ? STATE_ENABLED : STATE_DISABLED);
    }

    uint32 StoredChoice(Player* player, uint32 index)
    {
        if (!player)
            return CHOICE_UNSET;
        return player->GetPlayerSetting(DestinyWeaver::SETTING_SOURCE, index).value;
    }

    void StoreChoice(Player* player, uint32 index, bool enabled)
    {
        if (!player)
            return;
        player->UpdatePlayerSetting(DestinyWeaver::SETTING_SOURCE, index, enabled ? CHOICE_ON : CHOICE_OFF);
    }

    bool ModuleEnabled()
    {
        return sConfigMgr->GetOption<bool>("DestinyWeaver.Enable", true);
    }

    /// The character's own stored choice. While a character is grouped, the party's setting is the
    /// leader's instead - that is a separate question, asked in DestinyWeaver::LevelScalingEnabled.
    bool PersonalLevelScaling(Player* player)
    {
        if (!ModuleEnabled() || !sConfigMgr->GetOption<bool>("DestinyWeaver.LevelScaling", true))
            return false;

        switch (StoredChoice(player, DestinyWeaver::SETTING_LEVEL_SCALING))
        {
            case CHOICE_ON:
                return true;
            case CHOICE_OFF:
                return false;
            default:
                return sConfigMgr->GetOption<bool>("DestinyWeaver.LevelScaling.Default", true);
        }
    }

    void SendDestinyWeaverMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);

        // The row states what is true now, so Experience Bonus Control reads as the bonuses
        // themselves: control off means the bonuses still pay. Clicking flips it and the menu is
        // re-sent, which is what the live NPC did.
        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
                         OptionText(ICON_EXPERIENCE_BONUS, "Experience bonuses!",
                                    !DestinyWeaver::ExperienceBonusControlEnabled(player)),
                         GOSSIP_SENDER_DESTINY_WEAVER, ACTION_TOGGLE_EXPERIENCE_BONUS_CONTROL);

        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
                         OptionText(ICON_OPEN_WORLD_SCALING, "Open world scaling!",
                                    DestinyWeaver::LevelScalingEnabled(player)),
                         GOSSIP_SENDER_DESTINY_WEAVER, ACTION_TOGGLE_SCALING);

        SendGossipMenuFor(player, GOSSIP_TEXT_GREETING, creature);
    }
}

class npc_destiny_weaver : public CreatureScript
{
public:
    npc_destiny_weaver() : CreatureScript("npc_destiny_weaver") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (!ModuleEnabled())
            return false;

        SendDestinyWeaverMenu(player, creature);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        if (!ModuleEnabled() || sender != GOSSIP_SENDER_DESTINY_WEAVER)
            return true;

        switch (action)
        {
            case ACTION_TOGGLE_SCALING:
                DestinyWeaver::SetLevelScaling(player, !DestinyWeaver::LevelScalingEnabled(player));
                break;
            case ACTION_TOGGLE_EXPERIENCE_BONUS_CONTROL:
                DestinyWeaver::SetExperienceBonusControl(
                    player, !DestinyWeaver::ExperienceBonusControlEnabled(player));
                break;
            default:
                return true;
        }

        // Both rows state what the character has now, so the menu is re-sent rather than the
        // player being told in chat: one visit, one window, the row flips, no message to dismiss.
        SendDestinyWeaverMenu(player, creature);
        return true;
    }
};

namespace DestinyWeaver
{
bool LevelScalingEnabled(Player* player)
{
    // While grouped, the leader's choice is the group's: they invited the character into their run,
    // and everyone in it should be playing the same world. Nothing is written to anyone's settings -
    // leaving the group gives each member their own choice back exactly as they left it, which is
    // what makes this a group setting rather than a change to the character.
    if (player)
        if (Group* group = player->GetGroup())
            if (group->GetLeaderGUID() != player->GetGUID())
                if (Player* leader = ObjectAccessor::FindConnectedPlayer(group->GetLeaderGUID()))
                    return PersonalLevelScaling(leader);

    return PersonalLevelScaling(player);
}

bool PersonalLevelScalingChoice(Player* player)
{
    return PersonalLevelScaling(player);
}

bool ExperienceBonusControlEnabled(Player* player)
{
    if (!ModuleEnabled() ||
        !sConfigMgr->GetOption<bool>("DestinyWeaver.ExperienceBonusControl", true))
        return false;

    return StoredChoice(player, SETTING_EXPERIENCE_BONUS_CONTROL) == CHOICE_ON;
}

void SetLevelScaling(Player* player, bool enabled)
{
    StoreChoice(player, SETTING_LEVEL_SCALING, enabled);

    // The character who threw the switch is answered in the Weaver's own words - the line the live
    // realm showed - and marked as believing the state it is now being shown, so the refresh below
    // can announce the change to their group without also announcing it back to them.
    NotifyScalingSelf(player, enabled);

    // The choice is what decides the level each accepted quest is played at, so the quest log has to
    // be told again: the client caches a quest's data by quest id and would otherwise keep showing
    // the level and the rewards it was picked up under.
    if (player && player->IsInWorld())
        player->RefreshQuestLogQueries();

    // The switch governs the group and a client's view of the world is a cache, so what the acting
    // character and their group are looking at has to be re-sent, not only their quest log.
    RefreshScalingClients(player);
}

bool ResolveQuestScaling(Player const* player)
{
    // The realm switches are the core's business and it has already checked them; all this answers
    // is what this character chose. The cast is only there because Player::GetPlayerSetting is not
    // const - nothing on the path writes to the character.
    return LevelScalingEnabled(const_cast<Player*>(player));
}

/// One line in the middle of the screen: `SMSG_NOTIFICATION`, the opcode the realm's own
/// autobroadcasts use. One packet per line, because the client draws one notification per packet.
void SendCentered(Player* player, std::string const& line)
{
    WorldPacket data(SMSG_NOTIFICATION, line.size() + 1);
    data << line;
    player->SendDirectMessage(&data);
}

void NotifyGroupScaling(Player* player, bool enabled)
{
    if (!player || !player->IsInWorld())
        return;

    // Yellow for the sentence, the state word in its own colour and then reset: what the live
    // notification looked like, and the reason the message is built here rather than localised - the
    // one word that carries the meaning is coloured, so it cannot be split out into a format string.
    std::string const line = std::string("|cffffff00Your group has Level Scaling ") +
        (enabled ? "|cff00ff00ENABLED|r" : "|cffff0000DISABLED|r");

    SendCentered(player, line);
    ChatHandler(player->GetSession()).SendSysMessage(line);

    LOG_INFO("module.destiny_weaver", "{} was notified that their group's level scaling is {}",
             player->GetName(), enabled ? "enabled" : "disabled");
}

void NotifyPersonalScaling(Player* player, bool enabled)
{
    if (!player || !player->IsInWorld())
        return;

    // The Weaver's own wording, as the live realm sent it when the switch was thrown:
    //
    //   You have enabled open world creature scaling!
    //   You have disabled open world creature scaling!
    //   Quest items and credits will not be awarded if creatures are grey level.
    //
    // The second line is only there when switching off, and it is the reason the switch matters: a
    // creature that is grey to the character awards no quest items and no credits, which scaling on
    // is what lifts it out of.
    std::string const line = std::string("|cffffff00You have ") +
        (enabled ? "|cff00ff00enabled|r" : "|cffff0000disabled|r") +
        "|cffffff00 open world creature scaling!|r";

    if (!enabled)
    {
        // The reason the switch matters, sent *first*: the client stacks centre-screen notifications
        // with the newest line on top, so the sentence about what just happened is the one written
        // last and the note reads underneath it - the order the live realm showed.
        std::string const note =
            "|cffffff00Quest items and credits will not be awarded if creatures are grey level.|r";
        SendCentered(player, note);
        SendCentered(player, line);
        ChatHandler(player->GetSession()).SendSysMessage(line);
        ChatHandler(player->GetSession()).SendSysMessage(note);
    }
    else
    {
        SendCentered(player, line);
        ChatHandler(player->GetSession()).SendSysMessage(line);
    }

    LOG_INFO("module.destiny_weaver", "{} was told they have {} open world creature scaling",
             player->GetName(), enabled ? "enabled" : "disabled");
}

bool GroupScalingApplies(Player* player)
{
    // True while the switch this character is shown is their group's rather than their own, which is
    // only the case while there is a leader present to have one: a group whose leader has gone leaves
    // every member on the choice they stored themselves, and that is what they are being shown.
    if (!player)
        return false;

    Group* group = player->GetGroup();
    if (!group)
        return false;

    return ObjectAccessor::FindConnectedPlayer(group->GetLeaderGUID()) != nullptr;
}

void SetExperienceBonusControl(Player* player, bool enabled)
{
    StoreChoice(player, SETTING_EXPERIENCE_BONUS_CONTROL, enabled);

    LOG_INFO("module.destiny_weaver", "{} {} experience bonus control",
             player ? player->GetName() : "<no player>", enabled ? "enabled" : "disabled");
}

bool HandleClientLevelScalingPacket(WorldSession* session, WorldPacket const& packet)
{
    if (!session)
        return false;

    if (packet.size() < sizeof(uint32))
    {
        LOG_WARN("module.destiny_weaver",
                 "Short level-scaling packet from account {}: {} bytes - ignored",
                 session->GetAccountId(), packet.size());
        return true;
    }

    std::lock_guard<std::mutex> guard(g_scalingChoiceLock);
    auto itr = g_scalingChoices.find(session);
    if (itr != g_scalingChoices.end())
        itr->second.Enabled = packet.read<uint32>(0) != 0;
    return true;
}
}

class destiny_weaver_choice_script : public PlayerScript
{
public:
    destiny_weaver_choice_script()
        : PlayerScript("destiny_weaver_choice_script",
                       { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT }) { }

    void OnPlayerLogin(Player* player) override
    {
        std::lock_guard<std::mutex> guard(g_scalingChoiceLock);
        g_scalingChoices[player->GetSession()] = {player->GetGUID(), std::nullopt};
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!player->IsInWorld())
            return;

        std::optional<bool> enabled;
        {
            std::lock_guard<std::mutex> guard(g_scalingChoiceLock);
            auto itr = g_scalingChoices.find(player->GetSession());
            if (itr == g_scalingChoices.end() || itr->second.PlayerGuid != player->GetGUID())
                return;
            enabled = itr->second.Enabled;
            itr->second.Enabled.reset();
        }

        if (enabled)
            DestinyWeaver::SetLevelScaling(player, *enabled);
    }

    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> guard(g_scalingChoiceLock);
        auto itr = g_scalingChoices.find(player->GetSession());
        if (itr != g_scalingChoices.end() && itr->second.PlayerGuid == player->GetGUID())
            g_scalingChoices.erase(itr);
    }
};

/// Keeps the group's view of the world honest.
///
/// The rules need nothing from an event: `LevelScalingEnabled` reads the current group and its
/// leader on every query, so the moment a group forms, changes hands or breaks up, the next question
/// already answers correctly - and it answers with the leader's *switch* only, never their level.
/// What an event is for is the other half: a client holds a level and a pool for every creature it
/// was sent, and quest data for every quest it was sent, and only a fresh message replaces those. So
/// every event that can move a character's effective answer marks the clients it moved.
class destiny_weaver_group_script : public GroupScript
{
public:
    destiny_weaver_group_script()
        : GroupScript("destiny_weaver_group_script",
                       { GROUPHOOK_ON_ADD_MEMBER, GROUPHOOK_ON_REMOVE_MEMBER,
                         GROUPHOOK_ON_CHANGE_LEADER, GROUPHOOK_ON_DISBAND }) { }

    /// The newcomer starts following the leader's switch, so their own world moves and nobody
    /// else's does.
    void OnAddMember(Group* group, ObjectGuid guid) override
    {
        Player* member = ObjectAccessor::FindConnectedPlayer(guid);
        if (!member)
            return;

        uint32 const marked = DestinyWeaver::RefreshClient(member);
        LOG_INFO("module.destiny_weaver",
                 "{} joined a group whose leader has scaling {}: re-sent their view of the world "
                 "({} client(s))",
                 member->GetName(),
                 group && DestinyWeaver::LevelScalingEnabled(member) ? "on" : "off", marked);
    }

    /// A member leaving goes back to their own choice. If it was the *leader* who left, every
    /// member's answer changed instead - the switch they were following is gone - and the same is
    /// true when a leader simply disconnects, which arrives here as a removal.
    void OnRemoveMember(Group* group, ObjectGuid guid, RemoveMethod /*method*/, ObjectGuid /*kicker*/, char const* /*reason*/) override
    {
        if (group && group->GetLeaderGUID() == guid)
        {
            // Not a reminder, because these members are not handed their own choice: they were
            // following the switch and the core hands the lead to one of them, so what they end up on
            // is a leader's switch that may not be their own. A change is reported in the group's
            // words when it moves; nothing is said when it does not.
            uint32 const marked = DestinyWeaver::RefreshGroup(group);
            LOG_INFO("module.destiny_weaver",
                     "the group's leader left: {} member(s) now follow whoever leads next", marked);
            return;
        }

        // Back to their own choice, and told so in the Weaver's words - a reminder of what they are
        // left with rather than a report of a change, so it speaks even when the two agree.
        if (Player* member = ObjectAccessor::FindConnectedPlayer(guid))
            if (uint32 const marked = DestinyWeaver::RefreshClient(member, true))
                LOG_INFO("module.destiny_weaver",
                         "{} left the group: back to their own scaling choice, in the Weaver's words "
                         "({} client(s))",
                         member->GetName(), marked);
    }

    /// Handing over the lead can flip the whole group's switch - a leader with scaling off taking
    /// over a group that had it on turns scaling off for everyone - and it never changes anyone's
    /// level, because a member's level is only ever their own.
    void OnChangeLeader(Group* group, ObjectGuid newLeaderGuid, ObjectGuid /*oldLeaderGuid*/) override
    {
        Player* newLeader = ObjectAccessor::FindConnectedPlayer(newLeaderGuid);
        char const* switchState = newLeader
            ? (DestinyWeaver::LevelScalingEnabled(newLeader) ? "on" : "off")
            : "back to each member's own";

        // The new leader's switch now governs the group, and the level still governs nobody:
        // every member keeps answering with their own level, so this re-sends what they see of a
        // creature - never *which* level that version is.
        uint32 const marked = DestinyWeaver::RefreshGroup(group);
        LOG_INFO("module.destiny_weaver",
                 "leadership is now {}'s: the group's scaling switch is {}, and {} client(s) were "
                 "re-sent their own view of the world",
                 newLeader ? newLeader->GetName() : std::string("<offline>"), switchState, marked);
    }

    void OnDisband(Group* group) override
    {
        // Fired while the member list is still intact, which is what makes this the one place every
        // member can be told: the group's override is gone and each of them is back on their own
        // choice, so the Weaver's line is a reminder rather than a report and speaks every time.
        uint32 const marked = DestinyWeaver::RefreshGroup(group, true);
        LOG_INFO("module.destiny_weaver",
                 "group disbanded: {} member(s) back to their own scaling choice, in the Weaver's "
                 "words", marked);
    }
};

/// Catches the client's level-scaling opcode when the compat module's protocol consumer is not
/// running (it is the one that dispatches to registered modules while it is enabled).
class destiny_weaver_server_script : public ServerScript
{
public:
    destiny_weaver_server_script()
        : ServerScript("destiny_weaver_server_script", {SERVERHOOK_CAN_PACKET_RECEIVE_EARLY}) { }

    bool CanPacketReceiveEarly(WorldSession* session, WorldPacket const& packet) override
    {
        if (packet.GetOpcode() != DestinyWeaver::CMSG_SET_LEVEL_SCALING)
            return true;

        return !DestinyWeaver::HandleClientLevelScalingPacket(session, packet);
    }
};

void AddSC_destiny_weaver()
{
    // The opcode belongs to this module; the compat consumer hands over anything claimed here.
    AscensionCompatOpcodes::Claim(DestinyWeaver::CMSG_SET_LEVEL_SCALING,
                                  &DestinyWeaver::HandleClientLevelScalingPacket);

    new npc_destiny_weaver();
    new destiny_weaver_choice_script();
    new destiny_weaver_group_script();
    new destiny_weaver_server_script();
}
