/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

// Public surface of the Destiny Weaver module.
//
// The two choices the NPC (and the character-creation screen) offer are per character, so they
// live in the core's own `character_settings` store, the same place the dynamic-XP module keeps
// a player's rate. Anything else only needs to ask.
#ifndef DESTINY_WEAVER_H
#define DESTINY_WEAVER_H

#include "Define.h"

class Group;
class Player;
class WorldPacket;
class WorldSession;

namespace DestinyWeaver
{
    /// Where a character's choices are stored. The "core." prefix is required by
    /// Player::_SavePlayerSettings, and both indices are independent flags.
    constexpr char SETTING_SOURCE[] = "core.destiny_weaver";
    constexpr uint32 SETTING_LEVEL_SCALING = 0;
    constexpr uint32 SETTING_EXPERIENCE_BONUS_CONTROL = 1;

    /// The client's own opcode for its level-scaling choice: one uint32 flag. It arrives from the
    /// character-creation screen on first login and again whenever the game-mode menu changes it.
    /// Observed in this realm's packet log as `payload=4 bytes [01 00 00 00]`.
    constexpr uint16 CMSG_SET_LEVEL_SCALING = 0x0667;

    /// Whether open-world creatures should come up to this character's level. A character that
    /// never chose follows the realm default (DestinyWeaver.LevelScaling.Default).
    ///
    /// While grouped this answers with the **leader's** switch, and with nothing else of theirs: the
    /// leader decides whether scaling is on, never *at what level*. Every member's level comes from
    /// that member - `ScaleCreatureLevelForViewer(original, viewer->GetLevel(), offset)` and
    /// `EffectiveQuestLevel(questLevel, playerLevel, curve)` are only ever handed the character served -
    /// so a level-12 in a level-31 leader's group fights level 7 versions of what the leader sees at
    /// 26, and a creature is never turned into one version for the whole party.
    bool LevelScalingEnabled(Player* player);

    /// The same question with the group out of it: the choice this character stored for themselves,
    /// which is what they hold when they are not following a party at all. Never the leader's, and
    /// never the effective state - a notification that hands a character their own setting back has to
    /// name *their* setting, and asking the effective question inside a group hook answers with the
    /// switch they are leaving rather than the one they are being given.
    bool PersonalLevelScalingChoice(Player* player);

    /// Whether this character asked for the base rate: the bonus experience sources - Potions of
    /// Experience, Auras of Experience and the recruit-a-friend bonus - pay nothing, which is what
    /// destiny_weaver_xp.cpp strips out of every award. The realm's XP rate and the dynamic-XP
    /// presets are a different system and keep applying. Off unless the character turned it on.
    bool ExperienceBonusControlEnabled(Player* player);

    void SetLevelScaling(Player* player, bool enabled);
    void SetExperienceBonusControl(Player* player, bool enabled);

    /// Answers the core's per-character question about quest level scaling
    /// (LocalLevelScaling::QuestScalingOwner). States only the character's own choice: the realm's
    /// own switches are checked by the core before this is asked.
    bool ResolveQuestScaling(Player const* player);

    /// Queues the client's level-scaling choice without accessing a Player on the network thread.
    /// Returns true when the packet was consumed,
    /// which is what both callers - the compat module's opcode dispatch and this module's own
    /// ServerScript, used when compat is switched off - do with the result.
    bool HandleClientLevelScalingPacket(WorldSession* session, WorldPacket const& packet);

    /// Tells a client that the view it holds is out of date, so its creatures are re-sent with the
    /// level and pool its own scaling now calls for, and its quest log is re-queried. The choice
    /// itself is read live and needs none of this; a client's *cache* of what it was told does.
    ///
    /// Thread-safe: it records the request, and it is served on the thread that owns the client.
    /// `RefreshClient` marks one character, `RefreshGroup` every online member of a group, and
    /// `RefreshScalingClients` the character plus their group - which is what a group event wants,
    /// because while grouped the leader's switch is everyone's answer. The two `Refresh*Client(s)`
    /// forms return how many clients they marked, so a caller can say so in the log.
    ///
    /// `remindDefault` is for the events that hand a character their own choice back - leaving a
    /// group, being disbanded. Those are told in the Weaver's own words whether or not the state
    /// moved, because what they are getting is a reminder of what their default is rather than the
    /// report of a change, and while grouped they are still looking at a group's switch. Without it a
    /// character whose own choice happens to match their group's hears nothing; without the *value*
    /// coming from `PersonalLevelScalingChoice` rather than the effective state, the sentence names
    /// the switch being left behind - which is the leader's, and can be the opposite one.
    uint32 RefreshClient(Player* player, bool remindDefault = false);
    uint32 RefreshGroup(Group* group, bool remindDefault = false);
    void RefreshScalingClients(Player* player);

    /// The Ascension-style notification for a character whose group scaling state just changed: the
    /// same sentence in the middle of the screen (`SMSG_NOTIFICATION`, the opcode the realm's own
    /// autobroadcasts use) and in the chat log, with the state word coloured - green for enabled, red
    /// for disabled - and the rest in plain yellow.
    ///
    ///     Your group has Level Scaling Enabled
    ///     Your group has Level Scaling Disabled
    ///
    /// Sent from the refresh path, which is the one place that knows what a client currently
    /// believes, so one real change is one message whatever caused it.
    ///
    ///     Your group has Level Scaling ENABLED
    ///     Your group has Level Scaling DISABLED
    void NotifyGroupScaling(Player* player, bool enabled);

    /// The same treatment in the Weaver's own words, for a change that is the character's own rather
    /// than their group's: throwing the switch, or getting their default back when the group is gone.
    ///
    ///     You have enabled open world creature scaling!
    ///     You have disabled open world creature scaling!
    ///     Quest items and credits will not be awarded if creatures are grey level.
    ///
    /// The third line only accompanies switching off - it is the reason the switch is worth having.
    void NotifyPersonalScaling(Player* player, bool enabled);

    /// True while the switch this character is shown is their group's rather than their own, i.e.
    /// while they are grouped and a leader is present to have one.
    bool GroupScalingApplies(Player* player);

    /// Answers the character who just changed the switch, in the Weaver's words, and records that
    /// they have been told: the state marked is the one they are now being *shown*, which while a
    /// group is in effect is the leader's switch rather than the choice just stored.
    void NotifyScalingSelf(Player* player, bool enabled);
}

#endif
