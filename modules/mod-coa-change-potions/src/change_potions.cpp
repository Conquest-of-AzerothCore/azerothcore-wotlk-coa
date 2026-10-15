/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
/*
 * mod-coa-change-potions - the six change potions and the three customization potions, in one
 * place: what they are, where they come from, and what drinking one does.
 *
 * ---------------------------------------------------------------------------------------------
 * The items (data/sql/updates/pending_db_world/rev_20260927_10_coa_change_potion_items.sql)
 * ---------------------------------------------------------------------------------------------
 * Nine item_template rows exist in the realm's own database and in the client's item cache
 * (Ascension_LocalLoot lists all nine), but none of them had a row anywhere in this repository:
 * three of them are dangling rows in mod-ethereal-bazaar's generated convenience list (Tiraxis,
 * 150 Bazaar Tokens each), and the other six have no source in tree at all.
 *
 *   200000  Customization Potion                customization (tradable)
 *   910201  Customization Potion                customization (Tiraxis)
 *   2001185 Soulbound Customization Potion      customization (account-bound)
 *   200001  Race Change Potion                  race (Tiraxis)
 *   2001181 Soulbound Race Change Potion        race (account-bound)
 *   910200  Faction Change Potion               faction (Tiraxis)
 *   505005  Faction Change Potion to Horde      faction, Alliance-only item, 7-day
 *   505006  Faction Change Potion to Alliance   faction, Horde-only item, 7-day
 *   97858   Class Change Potion                 class
 *
 * The first eight carry spell 200164 and the class potion carries 93216.  Both spells are the
 * client's own "Potion Visual": instant, description "Drink up!", a single effect of type 77
 * (SPELL_EFFECT_SCRIPT_EFFECT), and no spell_script_names row on the realm or in this tree.  In
 * other words the spell is a drink animation and nothing else; the service has always lived
 * server side, keyed on the item the player used, which is what this module supplies.
 *
 * ---------------------------------------------------------------------------------------------
 * Race, faction and customization: the realm's own contract
 * ---------------------------------------------------------------------------------------------
 * The 3.3.5a client applies these three services from the character selection screen, and the
 * whole contract is visible in this tree:
 *
 *   - Player::BuildEnumData writes SMSG_CHAR_ENUM's "character customize flags" word straight
 *     from the at-login flags (src/server/game/Entities/Player/Player.cpp:1283-1294):
 *     AT_LOGIN_CUSTOMIZE -> CHAR_CUSTOMIZE_FLAG_CUSTOMIZE, AT_LOGIN_CHANGE_FACTION ->
 *     CHAR_CUSTOMIZE_FLAG_FACTION, AT_LOGIN_CHANGE_RACE -> CHAR_CUSTOMIZE_FLAG_RACE.
 *   - The client's GlueXML turns those into the three service buttons (CharacterSelect.xml
 *     ServiceButtons: CustomizeButton / RaceChangeButton / FactionChangeButton; PAID_RACE_CHANGE
 *     = 3, PAID_FACTION_CHANGE = 2, PAID_CHARACTER_CUSTOMIZATION = 1).
 *   - Clicking one sends the stock opcodes CMSG_CHAR_RACE_CHANGE (0x4F8), CMSG_CHAR_FACTION_CHANGE
 *     (0x4D9) or CMSG_CHAR_CUSTOMIZE (0x473), which WorldSession::HandleCharFactionOrRaceChange /
 *     HandleCharCustomize accept only when the matching flag is set, and clear when the change is
 *     ordered (CharacterHandler.cpp:2098-2103, 2185, 1780-1786).
 *
 * So the missing half has always been just the flag.  Using one of the eight potions sets it - and
 * refuses to spend the potion when another service is already waiting, because the client can only
 * show one of the three buttons at a time.
 *
 * ---------------------------------------------------------------------------------------------
 * Drinking a potion ends at the character screen, ten seconds later
 * ---------------------------------------------------------------------------------------------
 * Every potion now logs the character out to the character selection screen ten seconds after it
 * is used - ten seconds counted by WorldScript::OnUpdate, then WorldSession::LogoutPlayer, the same
 * call the core's own instant logout makes (HandleLogoutRequestOpcode), which is what sends
 * SMSG_LOGOUT_COMPLETE - 0x004E in the client's own opcode table, where CMSG_LOGOUT_REQUEST is
 * 0x004C and SMSG_LOGOUT_RESPONSE is 0x004D.  Both halves have to run on the world thread:
 * ScheduleLogout below
 * records why, with the crash a map-thread logout produced.  The service potions have nothing left
 * to do in the world once the flag is set, and the class potion cannot rebuild a client-side spell
 * book or action bar in place, so the screen the next step happens on is where the player is sent.
 * One notification says so, at most once, in the realm's own notice yellow; the chat copy of the
 * same sentence carries the potion as a real clickable item link.
 *
 * ---------------------------------------------------------------------------------------------
 * Class: there is no contract to restore, so one had to be chosen
 * ---------------------------------------------------------------------------------------------
 * Nothing in the client or in the core can change a class.  The client's paid services are exactly
 * three (above); the client's opcode table lists no class-change opcode and no class button, and
 * the core has no class-change path at all.  The live realm's class change therefore
 * ran on Ascension's own core, and its "which class" step never reached anything we have - which
 * is why this module supplies one: the potion opens an item gossip menu listing the realm's own
 * classes (12..32, the 21 Ascension classes, filtered by sObjectMgr->GetPlayerInfo(race, class),
 * which this repository already treats as the authoritative availability list -
 * rev_20260920_00_custom_class_starting_action_bars.sql says so in as many words), and the pick
 * rebuilds the character.
 *
 * The rebuild is not a class id swap with grants on top of it.  It reproduces, as closely as a
 * server can, the character that would exist if this one had been created at level one as the class
 * being chosen and leveled normally to the level it is.  Spells and their ranks, talents,
 * proficiencies, skill lines and the equipment the class can actually use are derived from that one
 * question, from the realm's own definitions of a class (the long comment above ClassKit lists
 * them, and BuildKit is where they are read); the character's own non-class progression - level,
 * experience, professions, quest and item rewards, mounts, identity - is carried over untouched.
 * Every class-owned spell of the class being left that the class being entered does not account for
 * is removed rather than merely not re-granted, and the removal is bounded by the union of every
 * class's definitions rather than by the class being left, so A -> B -> C -> A ends where A -> A
 * would have.  The section above ClassKit is the full statement of the rule.
 *
 * The player is told what happened and is logged out ten seconds later, because a rebuilt class is
 * a relog: the client's spellbook, talent tree and action bar cannot be rebuilt in place.  Action
 * bars are replaced rather than left to break.  The realm's own progression service
 * (AscensionCompat's AscensionClassService::OnPlayerLogin -> SynchronizeProgression) then reconciles
 * and completes the state on the way back in, for the class the character is by then.
 *
 * ---------------------------------------------------------------------------------------------
 * Why an ItemScript and not an AllItemScript
 * ---------------------------------------------------------------------------------------------
 * The class menu needs the item's gossip handler, and the core reaches item gossip through the
 * item's script id (WorldSession::HandleGossipSelectOptionOpcode's guid.IsItem() branch ->
 * ScriptMgr::OnGossipSelect(player, item, ...) -> ScriptRegistry<ItemScript>), which is keyed on
 * item_template.ScriptName - so the nine rows carry ScriptName = 'item_coa_change_potion' and this
 * single ItemScript answers all nine entries by entry, exactly like
 * src/server/coa/AscensionBankVoucher.cpp does for the bank voucher.
 *
 * One rule from that shape is worth knowing before editing this file: answering OnUse with `true`
 * keeps the core out of the cast entirely, so the potion is spent here - and the item object does
 * not outlive Player::DestroyItemCount.  Everything the handler still needs is read first.
 */

#include "CharacterCache.h"
#include "CharacterPackets.h"
#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "GossipDef.h"
#include "Item.h"
#include "ItemScript.h"
#include "LiveClassResourcePolicy.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptedGossip.h"
#include "SharedDefines.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "WorldScript.h"
#include "WorldSession.h"

// The realm's own definitions of a class.  They belong to the core's CoA library
// (src/server/coa, published to modules as coa-interface), which is where main keeps them,
// so they are included by name rather than out of a module of their own.
#include "AscensionCoATalentData.h"
#include "AscensionCustomClassData.h"
#include "AscensionLiveBaselineData.h"
#include "AscensionRacialAbilities.h"
#include "AscensionSpecialization.h"
#include "AscensionSpellProgressionData.h"
#include "AscensionTalentReplacementData.h"
#include "AscensionTaughtAbilityData.h"

#include <algorithm>
#include <cctype>
#include <mutex>
#include <set>
#include <string>
#include <unordered_set>
#include <vector>

namespace
{
enum ChangePotion : uint32
{
    CustomizationPotion           = 200000,
    RaceChangePotion              = 200001,
    FactionChangePotionToHorde    = 505005,   // item is Alliance-only (FlagsExtra 2)
    FactionChangePotionToAlliance = 505006,   // item is Horde-only (FlagsExtra 1)
    ClassChangePotion             = 97858,
    FactionChangePotion           = 910200,
    CustomizationPotionBazaar     = 910201,
    SoulboundRaceChangePotion     = 2001181,
    SoulboundCustomizationPotion  = 2001185
};

char const* const ScriptName = "item_coa_change_potion";

// The menu header, an npc_text row the module's SQL adds (SendGossipMenuFor sends the id; the
// client asks for the text with CMSG_NPC_TEXT_QUERY and gets it from the world database).
//
// The row's id moves whenever its text changes, and it has now moved twice: the client answers the
// query for an id it has already been given out of its own cache, so a rewritten row under the same
// id keeps showing the string it replaced.  The first version of this header was written in the
// notice yellow and came out almost unreadable in the gossip window; the second is the plain one,
// and 9000092 is the id that carries it.  9000090 and 9000091 are deleted rather than left behind.
constexpr uint32 GossipTextId = 9000092;

// Ten seconds between the notice and the character screen.
constexpr uint32 LogoutDelayMs = 10000;

// Ascension's own classes are 12..32; the ten original ones are deliberately not on the menu.
constexpr uint8 CoAClassFirst = 12;
constexpr uint8 MaxClass = 32;

// The menu: the same classes, under the same names, in the same order the client's own character
// creation screen offers them.  It is the client that owns this list, in
// `Interface\GlueXML\CharacterCreate.lua` - COA_CLASS_ORDER, twenty-one keys, the order the class
// buttons appear in, gated by the same bridge that lets a realm without Ascension's
// creation-capability data create these classes at all (CanCreateClass accepts 12..32 and nothing
// else).  Reading the list from the client rather than inventing one is what makes a class change
// offer exactly what creation offers, in the order the player already knows.
//
// The names are the client's own, and so are the colours
//   - ChrClasses.dbc, the table the client displays, names ids 12..32
//     Barbarian, Witch Doctor, Felsworn, Witch Hunter, Stormbringer, Knight of Xoroth, Guardian,
//     Templar, Bloodmage, Ranger, Chronomancer, Necromancer, Pyromancer, Cultist, Starcaller,
//     Sun Cleric, Tinker, Venomancer, Reaper, Primalist, Runemaster - so the menu says Felsworn,
//     Templar, Bloodmage, Venomancer and Runemaster, not the Demon Hunter / Monk / Son of Arugal /
//     Disciple of Shadra / Runeweaver some server tables call the same ids;
//   - RAID_CLASS_COLORS, the client's own class palette, so the line a class change prints about
//     itself paints the new class the way the client paints it everywhere else.
struct PlayableClass
{
    uint8 Id;
    char const* Name;
    char const* Color;
    char const* Key;      // the client's class key, for the record: COA_CLASS_ORDER and RAID_CLASS_COLORS
};

// COA_CLASS_ORDER: NECROMANCER, PYROMANCER, CULTIST, STARCALLER, SUNCLERIC, TINKER, SPIRITMAGE,
// WILDWALKER, REAPER, PROPHET, CHRONOMANCER, SONOFARUGAL, GUARDIAN, STORMBRINGER, DEMONHUNTER,
// BARBARIAN, WITCHDOCTOR, WITCHHUNTER, FLESHWARDEN, MONK, RANGER.
constexpr PlayableClass PlayableClasses[] =
{
    { 23, "Necromancer",     "|cff45db9c", "NECROMANCER" },
    { 24, "Pyromancer",      "|cffff6112", "PYROMANCER" },
    { 25, "Cultist",         "|cff9c45f2", "CULTIST" },
    { 26, "Starcaller",      "|cff8fffff", "STARCALLER" },
    { 27, "Sun Cleric",      "|cffffb240", "SUNCLERIC" },
    { 28, "Tinker",          "|cffd9d9d9", "TINKER" },
    { 32, "Runemaster",      "|cff40c7eb", "SPIRITMAGE" },
    { 31, "Primalist",       "|cffe38c59", "WILDWALKER" },
    { 30, "Reaper",          "|cff0a876b", "REAPER" },
    { 29, "Venomancer",      "|cff6ba600", "PROPHET" },
    { 22, "Chronomancer",    "|cffffed4a", "CHRONOMANCER" },
    { 20, "Bloodmage",       "|cffa30000", "SONOFARUGAL" },
    { 18, "Guardian",        "|cff9c9482", "GUARDIAN" },
    { 16, "Stormbringer",    "|cff007ded", "STORMBRINGER" },
    { 14, "Felsworn",        "|cff75fa00", "DEMONHUNTER" },
    { 12, "Barbarian",       "|cff8a3303", "BARBARIAN" },
    { 13, "Witch Doctor",    "|cfff500ff", "WITCHDOCTOR" },
    { 15, "Witch Hunter",    "|cff5433cf", "WITCHHUNTER" },
    { 17, "Knight of Xoroth","|cfffc0005", "FLESHWARDEN" },
    { 19, "Templar",         "|cfffffab2", "MONK" },
    { 21, "Ranger",          "|cffbff06b", "RANGER" }
};

// The colours the notices are written in: the realm's own notice yellow (the one
// mod-scrolls-of-retreat and mod-treasure-keeper write their lines in), item gold for a potion
// name, and one accent for everything in the line the player is meant to act on - the ten seconds
// and the button the potion is about.  Those two used to be separate (bright gold for the countdown,
// teal for the button), which made one sentence carry two "look here" colours next to the yellow;
// they are now the same colour, and it is the only saturated one in the line.
//
// The accent is the one colour that is a setting (ChangePotions.NoticeAccent), because it is the one
// that has to sit beside the yellow without competing with it.  The default is amber, picked from a
// rendered set of candidates over the notice's own background.  A class's own name is written in the
// class's colour (PlayableClasses), not in the accent.
char const* const Yellow = "|cffffff00";
char const* const ItemGold = "|cffe6cc80";
char const* const HordeRed = "|cffff2020";
char const* const Reset = "|r";
char const* const DefaultAccent = "|cffffb340";

// The accent as a colour code.  ChangePotions.NoticeAccent is a bare six-digit RGB ("00ff9a"), so a
// realm can retune the notice in mod_coa_change_potions.conf without a rebuild and `.reload config`
// picks the new value up on the next notice.  Anything that is not six hex digits is the default
// rather than a broken line.
std::string Accent()
{
    std::string const requested = sConfigMgr->GetOption<std::string>("ChangePotions.NoticeAccent", "");
    if (requested.size() != 6)
        return DefaultAccent;

    for (char digit : requested)
        if (!std::isxdigit(static_cast<unsigned char>(digit)))
            return DefaultAccent;

    std::string code = "|cff";
    for (char digit : requested)
        code += char(std::toupper(static_cast<unsigned char>(digit)));

    return code;
}

struct ClassGrant
{
    uint8 Class;
    uint8 RequiredLevel;
    uint32 SpellId;
};

std::vector<ClassGrant> g_classGrants;   // ascension_custom_class_spell

// A service as the notice and the log line each need it: the plain name, and the colour its button
// word is written in - the accent for every one of them but the Horde side of a faction potion,
// which names its side in red.
struct Service
{
    char const* Plain;
    char const* Color;      // nullptr: the notice accent
};

Service const ServiceCustomize{ "Customize", nullptr };
Service const ServiceRaceChange{ "Race Change", nullptr };
Service const ServiceFactionChange{ "Faction Change", nullptr };
Service const ServiceFactionChangeToHorde{ "Faction Change to Horde", HordeRed };
Service const ServiceFactionChangeToAlliance{ "Faction Change to Alliance", nullptr };

char const* ClassName(uint8 classId)
{
    for (PlayableClass const& entry : PlayableClasses)
        if (entry.Id == classId)
            return entry.Name;
    return "Unknown";
}

// The class's own colour code ("|cffRRGGBB"), the notice yellow when the class is not ours.
char const* ClassColor(uint8 classId)
{
    for (PlayableClass const& entry : PlayableClasses)
        if (entry.Id == classId)
            return entry.Color;
    return Yellow;
}

// ---------------------------------------------------------------------------------------------
// Talking to the player
// ---------------------------------------------------------------------------------------------
void Notice(Player* player, std::string const& text)
{
    if (!player || !player->GetSession())
        return;
    ChatHandler handler(player->GetSession());
    handler.SendNotification(text);
    handler.SendSysMessage(text);
}

// The potion notices: SMSG_NOTIFICATION draws colours but not item links, so the notification
// names the potion and the chat copy carries the same sentence with the potion as a real link.
void Notify(Player* player, std::string const& notice, std::string const& chat)
{
    if (!player || !player->GetSession())
        return;
    ChatHandler handler(player->GetSession());
    handler.SendNotification(notice);
    handler.SendSysMessage(chat);
}

// The potion as a real chat link, so the line that names it is the potion itself.  The link's colour
// is left open on purpose: the sentence after it opens its own colour code, and the one |r the line
// ends with closes both.  A |r of its own immediately after the link's |h is what the client printed
// as plain text the first time this line was sent, so there is now exactly one per line.
std::string ItemLink(uint32 entry, std::string const& name)
{
    return std::string(ItemGold) + "|Hitem:" + std::to_string(entry) + ":0:0:0:0:0:0:0:0:0|h[" +
           name + "]|h";
}

// A word in a colour, closed, so the sentence it sits in carries on in its own yellow.
std::string Colored(char const* color, std::string const& word)
{
    std::string const code = color ? std::string(color) : Accent();
    return code + word + Reset;
}

// "|cffffff00Customization Potion used. You will be logged out to the character screen in
// |cff00ff9a10 seconds|r|cffffff00, where the |cff00ff9aCustomize|r|cffffff00 button is waiting.|r" -
// the ten seconds and the button in the one accent colour, so the line has a single actionable
// colour and the yellow is only the sentence around it.
std::string ServiceSentence(std::string const& potion, Service const& service)
{
    std::string const accent = Accent();

    // Yellow after the potion as well as before it: the potion may be an item link, whose own gold
    // would otherwise run on into the rest of the sentence.
    return std::string(Yellow) + potion + Yellow + " used. You will be logged out to the character screen in " +
           accent + "10 seconds" + Reset + Yellow + ", where the " +
           Colored(service.Color, service.Plain) + Yellow + " button is waiting." + Reset;
}

// "|cffffff00You are now a |cff45db9cNecromancer|r|cffffff00. You will be logged out to the character
// screen in |cff00ff9a10 seconds|r|cffffff00.|r" - the class named in the colour the client paints
// that class with, which is what the game itself does wherever it names one.  The ten seconds are in
// the same accent as the service potions' countdown.
std::string ClassSentence(std::string const& className, char const* classColor)
{
    return std::string(Yellow) + "You are now a " + classColor + className + Reset + Yellow +
           ". You will be logged out to the character screen in " + Accent() + "10 seconds" +
           Reset + Yellow + "." + Reset;
}

// ---------------------------------------------------------------------------------------------
// The item itself
// ---------------------------------------------------------------------------------------------
// The client grays an item the moment its use request goes out and only the core's own answer
// releases it; a script that answers the request must send that answer itself.  It has to be said
// while the item still exists: Player::DestroyItemCount deletes it once its count is spent.
void Acknowledge(Player* player, Item* item)
{
    if (player && item)
        player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);
}

// The answer first, then the potion.  A script that answers the use request with `true` keeps the
// core out of it entirely (WorldSession::HandleUseItemOpcode only calls CastItemUseSpell when no
// script answered), so nothing else spends the potion -- expect it here.
//
// This must be the last thing in the handler that touches the item: DestroyItemCount leaves the
// object removed (Player::DestroyItem -> Item::SetState(ITEM_REMOVED)) and reading an update field
// from it afterwards faults.  Everything the handler still needs -- the entry for the log line,
// the name for the notice -- is read while the potion exists.  A crash from exactly this omission
// is what the module's first in-game test produced, so it is written down here.
void AcknowledgeAndConsume(Player* player, Item* item)
{
    if (!player || !item)
        return;

    Acknowledge(player, item);

    uint32 count = 1;
    player->DestroyItemCount(item, count, true);
}

// ---------------------------------------------------------------------------------------------
// Logging out to the character screen
// ---------------------------------------------------------------------------------------------
// The ten seconds are counted by the world update, never by Player::m_Events.  m_Events belongs to
// the map: its callbacks run inside Player::Update on a map worker thread, and logging a player out
// from there tears the player out of the map in the middle of that same update - Player::Update
// carries on into UpdatePvPFlag and reads update fields the logout has already freed.  The module
// produced exactly that fault the first time it used m_Events:
//
//     Object::HasByteFlag        Object.cpp:939
//     Player::IsPvP              Player.cpp:16986
//     Player::UpdatePvPFlag      PlayerMisc.cpp:367
//     Player::Update             PlayerUpdates.cpp:83     <- inside the map thread's own update
//     Map::Update                Map.cpp:491
//
// WorldScript::OnUpdate is called from World::Update on the world thread - the thread the core's
// own instant logout runs on (WorldSession::HandleLogoutRequestOpcode -> LogoutPlayer).  The item use
// that schedules a logout is not: CMSG_USE_ITEM is PROCESS_INPLACE, so an in-world player's use is
// handled inside Map::Update, and with MapUpdate.Threads above one two maps can schedule at once.
// The list is therefore locked, and the logouts themselves run after the lock is released.
struct PendingLogout
{
    ObjectGuid Guid;
    uint32 Remaining;      // milliseconds
};

std::vector<PendingLogout> g_pendingLogouts;
std::mutex g_pendingLogoutsLock;

void ScheduleLogout(Player* player)
{
    if (!player || !player->GetSession())
        return;

    ObjectGuid const guid = player->GetGUID();
    std::lock_guard<std::mutex> guard(g_pendingLogoutsLock);
    for (PendingLogout& pending : g_pendingLogouts)
        if (pending.Guid == guid)
        {
            pending.Remaining = LogoutDelayMs;   // drink a second potion, still one logout
            return;
        }

    g_pendingLogouts.push_back(PendingLogout{ guid, LogoutDelayMs });
}

void UpdatePendingLogouts(uint32 diff)
{
    std::vector<ObjectGuid> due;
    {
        std::lock_guard<std::mutex> guard(g_pendingLogoutsLock);
        for (auto itr = g_pendingLogouts.begin(); itr != g_pendingLogouts.end(); )
        {
            if (itr->Remaining > diff)
            {
                itr->Remaining -= diff;
                ++itr;
                continue;
            }

            due.push_back(itr->Guid);
            itr = g_pendingLogouts.erase(itr);
        }
    }

    for (ObjectGuid const& guid : due)
    {
        Player* player = ObjectAccessor::FindPlayer(guid);
        WorldSession* session = player ? player->GetSession() : nullptr;
        if (!player || !session || session->GetPlayer() != player)
            continue;                      // gone already, or logged out by hand in the meantime

        // What HandleLogoutRequestOpcode sends before it logs a player out, so the client is told
        // the logout is instant instead of showing its own countdown.
        WorldPackets::Character::LogoutResponse response;
        response.Instant = true;
        session->SendPacket(response.Write());

        std::string const name = player->GetName();   // LogoutPlayer frees the player
        session->LogoutPlayer(true);                  // saves, then sends SMSG_LOGOUT_COMPLETE

        LOG_INFO("module.coa_change_potions", "{} logged out to the character screen after drinking a potion.",
                 name);
    }
}

// ---------------------------------------------------------------------------------------------
// A class, as this realm defines one
// ---------------------------------------------------------------------------------------------
// The module never asks what could be added to an existing character to make it resemble another
// class.  It asks the one question the realm can answer: what does a character of that class hold
// when it is created at level one and leveled to the level this character is?  Five of the realm's
// own definitions answer it, and they are the same ones its creation and level-up paths read:
//
//   AscensionLiveBaseline::Spells / ::Proficiencies / ::Skills
//       the level-one character: the CoA library's InitializeLiveBaseline builds exactly these
//       inside Player::Create (generated from the live realm);
//   playercreateinfo_spell_custom / playercreateinfo_skills
//       learned at creation through the core's own LearnCustomSpells / LearnDefaultSkills
//       (PlayerStart.CustomSpells is on in this realm);
//   AscensionCompatData::ClassSpells and `ascension_custom_class_spell`
//       the level ladder - the class's abilities with the level each arrives at, which
//       AscensionCompat's OnPlayerLevelChanged hands out while leveling;
//   AscensionProgression::Ranks
//       the rank upgrades, each with the level the realm teaches it at, handed out once the spell
//       they upgrade is held;
//   AscensionCompatData::CoATalentEntries with CoAAutomaticDependencies
//       the free, automatic class-tree talents: no cost, a level gate, a prerequisite gate.
//
// One more pair bounds the class without being granted: UnresolvedTrainerSpells (a character of the
// class may hold these - a trainer sells them - and a potion never hands them out, which is the
// user's rule that a potion grants only what leveling itself grants) and AscensionCompatData's
// ProficiencyDefinitions, the weapon and armour catalogue, which carries its skill lines with it and
// is reconciled on its own (TakeProficiencies).
//
// Removal is bounded the other way, and that is what keeps a class change from becoming a change by
// addition: a spell is taken away only when one of the realm's class definitions owns it, and the
// catalogue is built once over EVERY class rather than over the class being left.  A profession, a
// quest reward, a mount, an item-granted spell or a racial ability belongs to no class and is never
// touched; a spell the old class owns and the new one does not is removed whichever class brought
// it, so a second or third change cannot accumulate what an earlier one handed out.
//
// What the change hands out is the class's base state, never its progression.  It is the same
// distinction the whole module turns on: a potion establishes what a character of a class is, and
// leaves what that character learns afterwards to the player.
//
// Talents follow the spellbook, because that is where this realm keeps them (AscensionCoATalentState
// derives the whole Character Advancement state from known spells): the old class's talent spells
// leave with the rest of its spells, the chosen specialization and every stored build are cleared (a
// character created as the new class has chosen none), and the new class's class tree is offered
// with nothing spent in it.  Its free automatic nodes are the realm's own progressor's business
// (AscensionCompat hands them out on login to whoever holds their prerequisites), and every other
// node, like every rank upgrade and every trainer offer, is a choice the player makes afterwards -
// so a class change grants none of them.  That is why Granted is read from the class as creation
// builds it (level one) while Allowed is read at the character's own level: the first is what the
// change gives, the second is what it is allowed to leave in place.
struct ClassKit
{
    std::vector<uint32> Allowed;      // every class-owned spell a character of this class may hold
    std::vector<uint32> Granted;      // the class's base state: what creation builds at level one
    std::vector<uint16> SkillLines;   // the class's own skill lines
    std::vector<AscensionLiveBaseline::Proficiency> Proficiencies;   // spells, and the skills they carry
    std::vector<AscensionLiveBaseline::Skill> Skills;
};

// Every spell and every skill line any of the realm's classes owns, built once at startup.
std::unordered_set<uint32> g_classSpellCatalog;
std::unordered_set<uint16> g_classSkillCatalog;

void PushUnique(std::vector<uint32>& list, uint32 value)
{
    if (value && std::find(list.begin(), list.end(), value) == list.end())
        list.push_back(value);
}

bool Contains(std::vector<uint32> const& list, uint32 value)
{
    return std::find(list.begin(), list.end(), value) != list.end();
}

bool ContainsSkill(std::vector<uint16> const& list, uint16 value)
{
    return std::find(list.begin(), list.end(), value) != list.end();
}

// A proficiency is a spell whose skill line the catalogue in AscensionCustomClassData owns: it is
// taken away and given back as a skill (TakeProficiencies), never as a plain spell.
bool IsProficiencySpell(uint32 spellId)
{
    return std::any_of(AscensionCompatData::ProficiencyDefinitions.begin(),
                       AscensionCompatData::ProficiencyDefinitions.end(),
                       [spellId](AscensionCompatData::ProficiencyDefinition const& definition)
                       { return definition.SpellId == spellId; });
}

// Racial abilities belong to the race and never to a class: a change of class does not take one
// away, whatever its spell book looks like.  The realm's races are recognised by skill line
// (AscensionRacialAbilities), the same way the CoA library recognises them.
bool IsRacialSpell(Player* player, uint32 spellId)
{
    auto const bounds = sSpellMgr->GetSkillLineAbilityMapBounds(spellId);
    for (auto itr = bounds.first; itr != bounds.second; ++itr)
        if (AscensionRacialAbilities::GetRace(itr->second->SkillLine) == player->getRace())
            return true;
    return false;
}

// The free class-tree talents the realm's own progression hands out by itself: nothing costs a
// point, the level gates it, no specialization is chosen (a character that has just changed class
// has chosen none) and its prerequisites have to be held already.  Rank 1 of a selectable free node
// is a choice the player makes and is not granted here, exactly as AscensionCompat leaves it.
bool AutomaticTalent(AscensionCompatData::CoATalentEntry const& entry, uint8 classId, uint8 level,
                     std::vector<uint32> const& held)
{
    if (entry.ClassId != classId || entry.SpecId || entry.AECost || entry.TECost ||
        entry.RequiredLevel > level || !entry.SpellCount)
        return false;

    if (std::any_of(AscensionCompatData::CoASelectableFreeEntries.begin(),
                    AscensionCompatData::CoASelectableFreeEntries.end(),
                    [&entry](AscensionCompatData::CoASelectableFreeEntry const& selectable)
                    { return selectable.EntryId == entry.EntryId; }))
        return false;

    auto const& dependencies = AscensionCompatData::CoAAutomaticDependencies;
    auto dependency = std::lower_bound(dependencies.begin(), dependencies.end(), entry.EntryId,
        [](AscensionCompatData::CoAAutomaticDependency const& value, uint32 id)
        { return value.EntryId < id; });
    if (dependency == dependencies.end() || dependency->EntryId != entry.EntryId)
        return true;                     // no prerequisite: the level gate is all there is

    for (uint32 requiredId : dependency->RequiredEntryIds)
    {
        if (!requiredId)
            continue;

        auto const& entries = AscensionCompatData::CoATalentEntries;
        auto required = std::lower_bound(entries.begin(), entries.end(), requiredId,
            [](AscensionCompatData::CoATalentEntry const& value, uint32 id) { return value.EntryId < id; });
        if (required == entries.end() || required->EntryId != requiredId || required->ClassId != classId ||
            !std::any_of(required->SpellIds.begin(), required->SpellIds.end(),
                         [&held](uint32 spellId) { return spellId && Contains(held, spellId); }))
            return false;
    }
    return true;
}

// What a character of this class at this level holds, read from the definitions named above.
ClassKit BuildKit(uint8 race, uint8 classId, uint8 level)
{
    ClassKit kit;

    auto allow = [&kit](uint32 spellId, bool granted)
    {
        if (!spellId)
            return;
        PushUnique(kit.Allowed, spellId);
        if (granted)
            PushUnique(kit.Granted, spellId);
    };

    // Creation: the class's own spells for this race, its proficiency spells and its skill lines -
    // what InitializeLiveBaseline builds inside Player::Create.
    for (AscensionLiveBaseline::Spell const& entry : AscensionLiveBaseline::Spells)
        if (entry.ClassId == classId && (!entry.RaceId || entry.RaceId == race))
            allow(entry.SpellId, true);

    for (AscensionLiveBaseline::Proficiency const& entry : AscensionLiveBaseline::Proficiencies)
        if (entry.ClassId == classId)
        {
            kit.Proficiencies.push_back(entry);
            allow(entry.SpellId, true);
        }

    for (AscensionLiveBaseline::Skill const& entry : AscensionLiveBaseline::Skills)
        if (entry.ClassId == classId)
        {
            kit.Skills.push_back(entry);
            if (!ContainsSkill(kit.SkillLines, entry.SkillId))
                kit.SkillLines.push_back(entry.SkillId);
        }

    if (PlayerInfo const* info = sObjectMgr->GetPlayerInfo(race, classId))
    {
        // playercreateinfo_spell_custom, the table the realm's baseline rows live in
        // (PlayerStart.CustomSpells is on, so creation learns these too).
        for (uint32 spellId : info->customSpells)
            allow(spellId, true);

        // playercreateinfo_skills, the other half of what creation hands out.
        for (PlayerCreateInfoSkills::const_iterator itr = info->skills.begin(); itr != info->skills.end(); ++itr)
            if (!ContainsSkill(kit.SkillLines, itr->SkillId))
                kit.SkillLines.push_back(itr->SkillId);
    }

    // Leveling: the class's own ladder, from the generated table and from the realm's live table.
    //
    // These are the level gates that belong to the class, which on this realm are also what the
    // Books of Ascension sell: the class trainer's own offers and ranks carry the same required
    // levels (mod-spellbook reads the same two tables, and CoA.AutoProgression is 0 on this
    // realm, so nothing here is granted at level-up either).  A character that leveled this
    // class from one would hold them, which is what the conversion reproduces; what it does not
    // reproduce is the price, and a potion is not a purchase.
    for (AscensionCompatData::ClassSpell const& entry : AscensionCompatData::ClassSpells)
        if (entry.ClassId == classId && entry.RequiredLevel <= level)
            allow(entry.SpellId, true);

    for (ClassGrant const& grant : g_classGrants)
        if (grant.Class == classId && grant.RequiredLevel <= level)
            allow(grant.SpellId, true);

    // The trainer page: a character of this class may hold these (compat's progression pass leaves
    // them alone so a purchase keeps), and a potion never hands one out - these are the offers with
    // no place in the class's ladder at all, so no amount of leveling would have produced them.
    for (AscensionCompatData::ClassSpell const& entry : AscensionCompatData::UnresolvedTrainerSpells)
        if (entry.ClassId == classId)
            allow(entry.SpellId, false);

    // Ranks, explicitly taught abilities, class-tree transforms and the free talents all hang off a
    // spell that has to be held first, and a rank can itself be the root of a later one, so the four
    // settle together instead of in one pass.
    for (bool grew = true; grew; )
    {
        grew = false;

        // The rank upgrades the realm teaches with level, once the spell they upgrade is held.
        for (AscensionProgression::Rank const& rank : AscensionProgression::Ranks)
            if (rank.ClassId == classId && rank.RequiredLevel <= level &&
                Contains(kit.Allowed, rank.FirstSpellId) && !Contains(kit.Allowed, rank.SpellId))
            {
                allow(rank.SpellId, true);
                grew = true;
            }

        // Abilities an owned ability teaches explicitly (AscensionTaughtAbilityData.h).  Held, not
        // granted: this realm keeps them as temporary spells and re-derives them on every login.
        for (AscensionCompatData::TaughtAbility const& taught : AscensionCompatData::TaughtAbilities)
            if (taught.ClassId == classId && !taught.SpecId && taught.RequiredLevel <= level &&
                Contains(kit.Allowed, taught.ParentSpellId) && !Contains(kit.Allowed, taught.SpellId))
            {
                allow(taught.SpellId, false);
                grew = true;
            }

        // The transforms an owned ability applies, and the ranks they come in.
        for (AscensionCompatData::TalentReplacement const& replacement : AscensionCompatData::TalentReplacements)
        {
            if (replacement.ClassId != classId || replacement.SpecId ||
                !Contains(kit.Allowed, replacement.ParentSpellId))
                continue;

            for (AscensionCompatData::ReplacementRank const& rank : replacement.Ranks)
                if (rank.SpellId && rank.RequiredLevel <= level && !Contains(kit.Allowed, rank.SpellId))
                {
                    allow(rank.SpellId, false);
                    grew = true;
                }
        }

        // The class tree's own spells, with their dependency gate.  They are held, never granted:
        // the realm's progressor hands out the free automatic nodes itself, and every other node on
        // the tree is the player's choice to make after the change (see ClassKit).  They are still
        // in Allowed, so a change does not take one away from a character of the class that has one.
        for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
        {
            if (!AutomaticTalent(entry, classId, level, kit.Allowed))
                continue;

            for (uint32 spellId : entry.SpellIds)
                if (spellId && !Contains(kit.Allowed, spellId))
                {
                    PushUnique(kit.Allowed, spellId);
                    grew = true;
                }
        }
    }

    return kit;
}

// A skill line a class can own.  The realm's own SkillLine.dbc categories are what says so: the
// weapon lines, the class and specialization lines and the armour lines belong to a class, while
// languages, professions, secondary professions and generic lines are the character's own or the
// profession trainer's business and a class change never clears them (Skinning sits in one class's
// baseline skills, and it is still a profession).
bool ClassOwnedSkill(uint16 skillId)
{
    SkillLineEntry const* line = sSkillLineStore.LookupEntry(skillId);
    if (!line)
        return false;

    return line->categoryId == SKILL_CATEGORY_WEAPON || line->categoryId == SKILL_CATEGORY_CLASS ||
           line->categoryId == SKILL_CATEGORY_ARMOR;
}

// The catalogues the removal half is bounded by, built once: every spell and every skill line that
// any of the realm's classes owns, plus the live realm's own class table.  LegacyGeneratedClassSpells
// are in here and not in a kit: they were granted by an earlier generator, and a class change keeps
// one only when today's definitions still account for it.
void LoadClassCatalogs(std::vector<uint32> const& creationSpells)
{
    g_classSpellCatalog.clear();
    g_classSkillCatalog.clear();

    for (uint32 spellId : creationSpells)
        g_classSpellCatalog.insert(spellId);

    for (uint8 classId = CoAClassFirst; classId <= MaxClass; ++classId)
    {
        for (AscensionLiveBaseline::Spell const& entry : AscensionLiveBaseline::Spells)
            if (entry.ClassId == classId)
                g_classSpellCatalog.insert(entry.SpellId);

        for (AscensionLiveBaseline::Proficiency const& entry : AscensionLiveBaseline::Proficiencies)
            if (entry.ClassId == classId)
                g_classSpellCatalog.insert(entry.SpellId);

        for (AscensionLiveBaseline::Skill const& entry : AscensionLiveBaseline::Skills)
            if (entry.ClassId == classId && ClassOwnedSkill(entry.SkillId))
                g_classSkillCatalog.insert(entry.SkillId);

        for (AscensionCompatData::ClassSpell const& entry : AscensionCompatData::ClassSpells)
            if (entry.ClassId == classId)
                g_classSpellCatalog.insert(entry.SpellId);

        for (AscensionCompatData::ClassSpell const& entry : AscensionCompatData::LegacyGeneratedClassSpells)
            if (entry.ClassId == classId)
                g_classSpellCatalog.insert(entry.SpellId);

        for (AscensionCompatData::ClassSpell const& entry : AscensionCompatData::UnresolvedTrainerSpells)
            if (entry.ClassId == classId)
                g_classSpellCatalog.insert(entry.SpellId);

        for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
            if (entry.ClassId == classId)
                for (uint32 spellId : entry.SpellIds)
                    if (spellId)
                        g_classSpellCatalog.insert(spellId);

        for (AscensionProgression::Rank const& rank : AscensionProgression::Ranks)
            if (rank.ClassId == classId)
            {
                g_classSpellCatalog.insert(rank.SpellId);
                if (rank.FirstSpellId)
                    g_classSpellCatalog.insert(rank.FirstSpellId);
            }

        for (AscensionCompatData::TaughtAbility const& taught : AscensionCompatData::TaughtAbilities)
            if (taught.ClassId == classId)
            {
                g_classSpellCatalog.insert(taught.SpellId);
                if (taught.ParentSpellId)
                    g_classSpellCatalog.insert(taught.ParentSpellId);
            }

        for (AscensionCompatData::TalentReplacement const& replacement : AscensionCompatData::TalentReplacements)
            if (replacement.ClassId == classId)
            {
                g_classSpellCatalog.insert(replacement.OriginalSpellId);
                if (replacement.ParentSpellId)
                    g_classSpellCatalog.insert(replacement.ParentSpellId);
                for (AscensionCompatData::ReplacementRank const& rank : replacement.Ranks)
                    if (rank.SpellId)
                        g_classSpellCatalog.insert(rank.SpellId);
            }
    }

    for (ClassGrant const& grant : g_classGrants)
        if (grant.SpellId)
            g_classSpellCatalog.insert(grant.SpellId);

    for (AscensionCompatData::ProficiencyDefinition const& definition : AscensionCompatData::ProficiencyDefinitions)
    {
        g_classSpellCatalog.insert(definition.SpellId);
        if (ClassOwnedSkill(definition.SkillId))
            g_classSkillCatalog.insert(definition.SkillId);
    }
}

uint16 StepFor(Player* player, uint16 skillId)
{
    return player->HasSkill(skillId) ? player->GetSkillStep(skillId) : 0;
}

bool ScalesWithLevel(uint16 skillId)
{
    return std::any_of(AscensionCompatData::ProficiencyDefinitions.begin(),
                       AscensionCompatData::ProficiencyDefinitions.end(),
                       [skillId](AscensionCompatData::ProficiencyDefinition const& definition)
                       { return definition.SkillId == skillId && definition.ScalesWithLevel; });
}

// The character's spell book, read against the new class's kit.  Every known spell that a class of
// this realm owns and the new class does not account for goes - whatever class brought it, which is
// what makes a chain of changes end where a single one would.  What no class owns stays: a
// profession, a quest reward, a mount, an item-granted spell, a racial ability.  The spell's auras
// go with it, so nothing of the old class is left running.
void StripOtherClassSpells(Player* player, ClassKit const& kit, uint32& removed)
{
    std::vector<uint32> doomed;

    for (PlayerSpellMap::const_iterator itr = player->GetSpellMap().begin(); itr != player->GetSpellMap().end(); ++itr)
    {
        uint32 const spellId = itr->first;
        PlayerSpell const* known = itr->second;
        if (!known || known->State == PLAYERSPELL_REMOVED)
            continue;
        if (Contains(kit.Allowed, spellId))
            continue;
        if (IsProficiencySpell(spellId))            // TakeProficiencies owns these, skill lines included
            continue;
        if (IsRacialSpell(player, spellId))         // the race's own, never a class's
            continue;
        if (!g_classSpellCatalog.count(spellId))    // no class owns it at all
            continue;

        doomed.push_back(spellId);
    }

    for (uint32 spellId : doomed)
    {
        player->RemoveAurasDueToSpell(spellId);
        player->removeSpell(spellId, SPEC_MASK_ALL, false);
        ++removed;
    }
}

// The same rule for the skill lines: a class's own skills are bounded by the catalogue over every
// class, and a skill line the class being entered does not have is zeroed.  Every class of this
// realm shares its languages, defence and unarmed, so those are never in question; professions are
// in no class's list and survive a change.
void StripOtherClassSkills(Player* player, ClassKit const& kit, uint32& removed)
{
    for (uint16 skillId : g_classSkillCatalog)
    {
        if (ContainsSkill(kit.SkillLines, skillId) || !player->HasSkill(skillId))
            continue;
        player->SetSkill(skillId, 0, 0, 0);
        ++removed;
    }
}

// The class-dependent half of a character's talent state that does not live in the spell book:
// which specialization is chosen and the stored builds the realm keeps per specialization
// (the CoA library's "core.ascension_active_spec" and "core.ascension_build.<spec>" settings).
// A character created as the class being entered has neither, and a build stored under the old
// class's specialization is exactly the dormant data a hybrid class state hides in.  The
// specialization has to be cleared where the realm reads it, so the login that follows this change
// finds none chosen and grants only the class tree's free nodes.
//
// "core.ascension_starter" is set as well, and for a different reason: the realm's login pass would
// otherwise repair the starter kit of the class being entered (AscensionClassService::RepairStarterKit),
// and a character that changes class is not a character being created - the potion keeps the gear it
// has and hands out none.
void ClearTalentState(Player* player)
{
    ClearAscensionSpecializationSlots(player);
    auto clear = [player](std::string const& setting) { player->UpdatePlayerSetting(setting, 0, 0); };

    clear("core.ascension_active_spec");

    std::set<uint16> specializations;
    for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
        if (entry.SpecId)
            specializations.insert(entry.SpecId);

    for (uint16 specialization : specializations)
        clear(std::string("core.ascension_build.") + std::to_string(specialization));

    player->UpdatePlayerSetting("core.ascension_starter", 0, 1);
}

// The realm's own rule for a class change (AscensionCompat's proficiency synchroniser): a
// proficiency belongs to the class if the baseline lists it, or if a talent brought it - and the
// catalog, not the spell book, bounds what a class change is allowed to take away.
void TakeProficiencies(Player* player, ClassKit const& newKit, uint32& removed)
{
    auto allowed = [player, &newKit](uint32 proficiencySpellId)
    {
        if (std::any_of(newKit.Proficiencies.begin(), newKit.Proficiencies.end(),
                        [proficiencySpellId](AscensionLiveBaseline::Proficiency const& entry)
                        { return entry.SpellId == proficiencySpellId; }))
            return true;

        return std::any_of(AscensionCompatData::TalentProficiencies.begin(),
                           AscensionCompatData::TalentProficiencies.end(),
                           [player, proficiencySpellId](AscensionCompatData::TalentProficiency const& entry)
                           { return entry.ProficiencySpellId == proficiencySpellId && player->HasSpell(entry.TalentSpellId); });
    };

    for (AscensionCompatData::ProficiencyDefinition const& definition : AscensionCompatData::ProficiencyDefinitions)
    {
        if (allowed(definition.SpellId))
            continue;

        if (player->HasSpell(definition.SpellId))
        {
            player->removeSpell(definition.SpellId, SPEC_MASK_ALL, false);
            ++removed;
        }

        if (player->HasSkill(definition.SkillId))
            player->SetSkill(definition.SkillId, 0, 0, 0);
    }
}

void GrantClass(Player* player, ClassKit const& kit)
{
    // Proficiency spells, and the skill lines they carry with them.
    for (AscensionLiveBaseline::Proficiency const& entry : kit.Proficiencies)
    {
        if (!player->HasSpell(entry.SpellId) && sSpellMgr->GetSpellInfo(entry.SpellId))
            player->learnSpell(entry.SpellId, false);

        uint16 const maximum = ScalesWithLevel(entry.SkillId) ? player->GetMaxSkillValueForLevel() : 1;
        player->SetSkill(entry.SkillId, StepFor(player, entry.SkillId), maximum, maximum);
    }

    // The rest of the class's skills.  Unarmed keeps the native current/cap the realm's own
    // baseline explicitly leaves alone, and the weapon ranks are level-scaled.
    for (AscensionLiveBaseline::Skill const& entry : kit.Skills)
    {
        if (entry.SkillId == SKILL_UNARMED)
            continue;

        bool const weapon = ScalesWithLevel(entry.SkillId);
        uint16 const maximum = weapon ? player->GetMaxSkillValueForLevel() : entry.Maximum;
        uint16 const value = weapon ? maximum : entry.Rank;
        player->SetSkill(entry.SkillId, 0, value, maximum);
    }

    for (uint32 spellId : kit.Granted)
        if (!player->HasSpell(spellId) && sSpellMgr->GetSpellInfo(spellId))
            player->learnSpell(spellId, false);

    player->LearnDefaultSkills();   // playercreateinfo_skills for the new class
    player->LearnCustomSpells();    // playercreateinfo_spell_custom, gated by PlayerStart.CustomSpells
}

// Glyphs belong to a class in exactly the sense talents do.  This is the removal the core's own
// race and faction change path performs (CharacterHandler.cpp), applied to every slot.
void ClearGlyphs(Player* player)
{
    for (uint8 slot = 0; slot < MAX_GLYPH_SLOT_INDEX; ++slot)
    {
        uint32 const glyph = player->GetGlyph(slot);
        if (!glyph)
            continue;

        GlyphPropertiesEntry const* glyphEntry = sGlyphPropertiesStore.LookupEntry(glyph);
        if (!glyphEntry)
        {
            player->SetGlyph(slot, 0, true);
            continue;
        }

        player->RemoveAurasDueToSpell(glyphEntry->SpellId);

        Unit::AuraMap& ownedAuras = player->GetOwnedAuras();
        for (Unit::AuraMap::iterator iter = ownedAuras.begin(); iter != ownedAuras.end();)
        {
            Aura* aura = iter->second;
            if (SpellInfo const* triggeredByAuraSpellInfo = aura->GetTriggeredByAuraSpellInfo())
            {
                if (triggeredByAuraSpellInfo->Id == glyphEntry->SpellId)
                {
                    player->RemoveOwnedAura(iter);
                    continue;
                }
            }
            ++iter;
        }

        player->SendLearnPacket(glyphEntry->SpellId, false);   // keeps the client's tooltips honest
        player->SetGlyph(slot, 0, true);
    }

    player->SendTalentsInfoData(false);
}

// The bar a fresh character of this class would start with: playercreateinfo_action, which this
// repository's own updates seed for classes 12..32.
void ResetActionBar(Player* player, PlayerInfo const* info)
{
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
        player->removeActionButton(button);

    for (PlayerCreateInfoActions::const_iterator itr = info->action.begin(); itr != info->action.end(); ++itr)
        player->addActionButton(itr->button, itr->action, itr->type);

    player->SendActionButtons(1);
}

// Class-specific equipment.  A character that had been the new class from the start would not be
// wearing what only the old class can equip, so an item the new class cannot use is moved into the
// bags; the core's own CanUseItem is the judge of that (class mask, proficiency, level, skill).
// Nothing is ever destroyed: if the bags are full the item stays where it is and is logged, because
// losing a player's gear would be worse than the state this repairs.
uint32 ReconcileEquipment(Player* player)
{
    uint32 moved = 0;

    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!item || player->CanUseItem(item) == EQUIP_ERR_OK)
            continue;

        ItemPosCountVec destination;
        if (player->CanStoreItem(NULL_BAG, NULL_SLOT, destination, item, false) != EQUIP_ERR_OK)
        {
            LOG_WARN("module.coa_change_potions",
                     "{} cannot use item {} ({}) after a class change and has no room for it; it stays equipped.",
                     player->GetName(), item->GetEntry(), item->GetTemplate()->Name1);
            continue;
        }

        uint32 const entry = item->GetEntry();
        player->RemoveItem(INVENTORY_SLOT_BAG_0, slot, true);
        player->StoreItem(destination, item, true);
        ++moved;

        LOG_INFO("module.coa_change_potions", "{} moved item {} to the bags: the new class cannot use it.",
                 player->GetName(), entry);
    }

    player->AutoUnequipOffhandIfNeed();
    return moved;
}

void ApplyClassChange(Player* player, Item* item, uint8 newClass)
{
    uint8 const oldClass = player->getClass();
    uint8 const race = player->getRace();
    uint8 const level = player->GetLevel();

    if (newClass < CoAClassFirst || newClass > MaxClass || newClass == oldClass)
        return;

    PlayerInfo const* newInfo = sObjectMgr->GetPlayerInfo(race, newClass);
    if (!newInfo)
    {
        Notice(player, "That class cannot be combined with your race.");
        return;
    }

    if (player->IsInCombat())
    {
        Notice(player, "You cannot drink a change potion in combat.");
        return;
    }

    // The class being entered, read twice, and neither reading is taken from the character: the
    // whole point is that the answer does not depend on the class being left.
    //
    //   kit   is the class at this character's level.  It is what the removal half is bounded by:
    //         what may be taken away is decided over every class's catalogue (LoadClassCatalogs),
    //         and what has to stay is what this class accounts for at this level.
    //   base  is the class as creation builds it, at level one.  It is what the change hands out.
    //         The potion establishes the class's base state and makes none of the character's
    //         progression choices for them: the ability ladder, the rank upgrades and the talent
    //         tree are learned, bought and spent by the player afterwards, exactly as they would be
    //         on a character that started this class at level one and has now reached this level.
    ClassKit const kit = BuildKit(race, newClass, level);
    ClassKit const base = BuildKit(race, newClass, 1);

    // 1. The old class leaves.  Everything the new class does not account for, and that a class of
    //    this realm does own, goes: spells with their auras, skill lines, proficiencies, glyphs,
    //    talents, and the specialization and stored builds that belong to the old class.  The
    //    character's own things - level, experience, professions, quest and item rewards, mounts -
    //    are not in any class's definition and are never touched.
    uint32 removed = 0;
    uint32 removedSkills = 0;
    StripOtherClassSpells(player, kit, removed);
    StripOtherClassSkills(player, kit, removedSkills);
    TakeProficiencies(player, kit, removed);

    player->resetTalents(true);
    ClearGlyphs(player);
    ClearTalentState(player);

    // A pet summoned by the old class is not the new class's pet: the same dismissal
    // Player::ActivateSpec performs for the weaker case of a specialization change.
    if (Pet* pet = player->GetPet())
        player->RemovePet(pet, PET_SAVE_NOT_IN_SLOT);

    // 2. The class itself: the session's field (the class byte and the resource that comes with
    //    it), forced out so the client agrees, and the realm's record of the character.
    uint32 bytes0 = player->GetUInt32Value(UNIT_FIELD_BYTES_0);
    bytes0 = (bytes0 & 0xFFFF00FFu) | (uint32(newClass) << 8);
    player->SetUInt32Value(UNIT_FIELD_BYTES_0, bytes0);
    player->ForceValuesUpdateAtIndex(UNIT_FIELD_BYTES_0);

    if (ChrClassesEntry const* classEntry = sChrClassesStore.LookupEntry(newClass))
        player->setPowerType(Powers(LiveClassResourcePolicy::DefaultPowerForClass(newClass, classEntry->powerType)));

    // Written synchronously: step 5 reads the row straight back into the character cache, and an
    // asynchronous write can still be queued when it does, leaving the cache on the old class.
    CharacterDatabase.DirectExecute("UPDATE `characters` SET `class` = {} WHERE `guid` = {}",
                                    uint32(newClass), player->GetGUID().GetCounter());

    // 3. Base stats, powers and skills, then the starting bar: what a character of this class is
    //    built from before any spell is learned.  The health and resource refill is the one
    //    Player::GiveLevel performs after rebuilding stats, so a class change leaves the character
    //    in the state a fresh login would have put it in.
    player->InitStatsForLevel();
    player->UpdateAllStats();

    if (!player->isDead())
    {
        player->SetFullHealth();
        player->SetPower(POWER_MANA, player->GetMaxPower(POWER_MANA));
        player->SetPower(POWER_ENERGY, player->GetMaxPower(POWER_ENERGY));
        if (player->GetPower(POWER_RAGE) > player->GetMaxPower(POWER_RAGE))
            player->SetPower(POWER_RAGE, player->GetMaxPower(POWER_RAGE));
        player->SetPower(POWER_FOCUS, player->GetMaxPower(POWER_FOCUS));
    }

    uint32 const unequipped = ReconcileEquipment(player);

    ResetActionBar(player, newInfo);

    // 4. The new class arrives: its base state - the proficiencies, skill lines and abilities
    //    creation builds for it, plus whatever the two creation tables add - and none of the
    //    progression the player has not chosen yet.
    GrantClass(player, base);

    // 5. Name queries answer other clients from the character cache (and the character list reads
    //    the row written above), so the cache is made to agree with the new class as well.
    sCharacterCache->RefreshCacheEntry(player->GetGUID().GetCounter());

    // 6. Spend the potion and say what happened.  The logout the notice promises is gone through
    //    rather than asked for: a rebuilt class is a relog, not a conversation.
    AcknowledgeAndConsume(player, item);

    std::string const className = ClassName(newClass);
    std::string const sentence = ClassSentence(className, ClassColor(newClass));
    Notify(player, sentence, sentence);

    ScheduleLogout(player);

    LOG_INFO("module.coa_change_potions",
             "{} ({}) changed class {} -> {} at level {}: {} class spells and {} skill lines removed, "
             "{} spells of the new class granted, {} item(s) unequipped, talents and specialization reset.",
             player->GetName(), player->GetGUID().ToString(), uint32(oldClass), uint32(newClass),
             uint32(level), removed, removedSkills, uint32(base.Granted.size()), unequipped);
}

// ---------------------------------------------------------------------------------------------
// Services the character selection screen applies
// ---------------------------------------------------------------------------------------------
bool ServicePending(Player* player)
{
    return player->HasAtLoginFlag(AT_LOGIN_CUSTOMIZE) ||
           player->HasAtLoginFlag(AT_LOGIN_CHANGE_FACTION) ||
           player->HasAtLoginFlag(AT_LOGIN_CHANGE_RACE);
}

bool RequestService(Player* player, Item* item, AtLoginFlags flag, Service const& service)
{
    // Read while the potion exists; it is spent at the end of this handler and the object does not
    // outlive its own destruction.
    ItemTemplate const* proto = item->GetTemplate();
    uint32 const entry = item->GetEntry();
    std::string const potion = proto ? proto->Name1 : "Change Potion";

    if (ServicePending(player))
    {
        Notice(player, "You already have a character change waiting. Log out to the character "
                       "selection screen and use it before drinking another potion.");
        Acknowledge(player, item);
        return true;
    }

    if (player->IsInCombat())
    {
        Notice(player, "You cannot drink a change potion in combat.");
        Acknowledge(player, item);
        return true;
    }

    player->SetAtLoginFlag(flag);

    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_UPD_ADD_AT_LOGIN_FLAG);
    stmt->SetData(0, uint16(flag));
    stmt->SetData(1, player->GetGUID().GetCounter());
    CharacterDatabase.Execute(stmt);

    AcknowledgeAndConsume(player, item);

    std::string const notice = ServiceSentence(potion, service);
    std::string const chat = ServiceSentence(ItemLink(entry, potion), service);
    Notify(player, notice, chat);

    ScheduleLogout(player);

    LOG_INFO("module.coa_change_potions", "{} used item {} ({}): at_login flag 0x{:X} set.",
             player->GetName(), entry, service.Plain, uint16(flag));
    return true;
}

// ---------------------------------------------------------------------------------------------
// Class
// ---------------------------------------------------------------------------------------------
bool ClassChangeEnabled()
{
    return sConfigMgr->GetOption<bool>("ChangePotions.ClassChangeEnable", true);
}

bool OfferClassChange(Player* player, Item* item)
{
    if (!ClassChangeEnabled())
    {
        Notice(player, "Class changes are not available on this realm.");
        Acknowledge(player, item);
        return true;
    }

    if (player->IsInCombat())
    {
        Notice(player, "You cannot drink a change potion in combat.");
        Acknowledge(player, item);
        return true;
    }

    ClearGossipMenuFor(player);

    uint32 offered = 0;
    for (PlayableClass const& playable : PlayableClasses)
    {
        if (playable.Id == player->getClass())
            continue;
        if (!sObjectMgr->GetPlayerInfo(player->getRace(), playable.Id))
            continue;                       // this realm has no such race and class combination
        AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, playable.Name, GOSSIP_SENDER_MAIN, playable.Id);
        ++offered;
    }

    if (!offered)
    {
        Notice(player, "No other class can be combined with your race.");
        Acknowledge(player, item);
        return true;
    }

    // The item request is answered first, so the client has released the potion by the time the
    // menu opens.  The menu itself is the confirmation; the potion is spent when a class is picked,
    // not now, which is why this returns true without consuming anything.  The GUID is taken while
    // the item certainly exists, the same rule the spend paths follow.
    ObjectGuid const itemGuid = item->GetGUID();
    Acknowledge(player, item);
    SendGossipMenuFor(player, GossipTextId, itemGuid);
    return true;
}

class item_coa_change_potion : public ItemScript
{
public:
    item_coa_change_potion() : ItemScript(ScriptName) { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        if (!player || !item)
            return false;

        switch (item->GetEntry())
        {
            case CustomizationPotion:
            case CustomizationPotionBazaar:
            case SoulboundCustomizationPotion:
                return RequestService(player, item, AT_LOGIN_CUSTOMIZE, ServiceCustomize);
            case RaceChangePotion:
            case SoulboundRaceChangePotion:
                return RequestService(player, item, AT_LOGIN_CHANGE_RACE, ServiceRaceChange);
            case FactionChangePotion:
                return RequestService(player, item, AT_LOGIN_CHANGE_FACTION, ServiceFactionChange);
            case FactionChangePotionToHorde:
                return RequestService(player, item, AT_LOGIN_CHANGE_FACTION, ServiceFactionChangeToHorde);
            case FactionChangePotionToAlliance:
                return RequestService(player, item, AT_LOGIN_CHANGE_FACTION, ServiceFactionChangeToAlliance);
            case ClassChangePotion:
                return OfferClassChange(player, item);
            default:
                // Not ours: let the core cast whatever the item really does.
                return false;
        }
    }

    void OnGossipSelect(Player* player, Item* item, uint32 sender, uint32 action) override
    {
        if (!player || !item || item->GetEntry() != ClassChangePotion || sender != GOSSIP_SENDER_MAIN)
            return;

        CloseGossipMenuFor(player);
        ClearGossipMenuFor(player);

        if (!ClassChangeEnabled())
            return;

        ApplyClassChange(player, item, uint8(action));
    }
};

class mod_coa_change_potions_world : public WorldScript
{
public:
    mod_coa_change_potions_world()
        : WorldScript("mod_coa_change_potions_world", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE }) { }

    void OnStartup() override
    {
        g_classGrants.clear();

        if (QueryResult result = WorldDatabase.Query(
                "SELECT `class`, `required_level`, `spell_id` FROM `ascension_custom_class_spell`"))
        {
            do
            {
                Field* fields = result->Fetch();
                ClassGrant grant;
                grant.Class = fields[0].Get<uint8>();
                grant.RequiredLevel = fields[1].Get<uint8>();
                grant.SpellId = fields[2].Get<uint32>();
                if (grant.SpellId)
                    g_classGrants.push_back(grant);
            } while (result->NextRow());
        }
        else
            LOG_WARN("module.coa_change_potions",
                     "ascension_custom_class_spell is missing or empty; a class change will lean on "
                     "the live class baseline alone.");

        // playercreateinfo_spell_custom reaches a class change the same way it reaches character
        // creation - through Player::LearnCustomSpells, which reads it from the player's own
        // PlayerInfo - but its rows also belong in the removal catalogue, so the ones a custom
        // class can learn are read here.
        std::vector<uint32> creationSpells;
        if (QueryResult result = WorldDatabase.Query(
                "SELECT `classMask`, `Spell` FROM `playercreateinfo_spell_custom`"))
        {
            do
            {
                Field* fields = result->Fetch();
                uint32 const classMask = fields[0].Get<uint32>();
                uint32 const spellId = fields[1].Get<uint32>();
                if (!spellId || !(classMask & 0xFFFFF000u))   // a row the serialized classes can learn
                    continue;
                creationSpells.push_back(spellId);
            } while (result->NextRow());
        }

        LoadClassCatalogs(creationSpells);

        LOG_INFO("module.coa_change_potions",
                 "Loaded {} class progression rows; a class change is built from {} live baseline "
                 "spells, {} proficiencies and {} skills, and is bounded by {} class-owned spells and "
                 "{} class-owned skill lines.",
                 g_classGrants.size(), AscensionLiveBaseline::Spells.size(),
                 AscensionLiveBaseline::Proficiencies.size(), AscensionLiveBaseline::Skills.size(),
                 g_classSpellCatalog.size(), g_classSkillCatalog.size());
    }

    // The world thread's own clock: the ten seconds between a potion and the character screen, and
    // the logout itself, which must not be done from a map event (see ScheduleLogout).
    void OnUpdate(uint32 diff) override
    {
        UpdatePendingLogouts(diff);
    }
};
}  // namespace

void AddSC_CoAChangePotions()
{
    new item_coa_change_potion();
    new mod_coa_change_potions_world();
}
