/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
/*
 * mod-treasure-keeper - CoA's bank companions, the Treasure Keeper and the Celestial Treasure
 * Keeper: non-combat pets whose right click opens the character's own bank.
 *
 * Both are ordinary companions of this realm's pattern - an item whose on-use spell (55884) hands
 * out a summon spell, and the summon spell is a plain guardian:
 *
 *     item 98073 "Celestial Treasure Keeper" -> spell 93417  -> creature 80918  (display 47857)
 *     item 99491 "Treasure Keeper"           -> spell 985356 -> creature 10111377 (display 48611)
 *
 * Their own text is the whole specification:
 *
 *     "Right Click to summon and dismiss your companion, that acts as a portable bank while in
 *      safe zones. Cannot be summoned in High-Risk Open World."
 *
 * The bank they open is the *native* one - not this realm's personal/realm banks, which are
 * summoned vault objects handled elsewhere (CoA's AscensionPersonalBank). No
 * code is needed for it: the pets carry UNIT_NPC_FLAG_BANKER (0x20000) and the core answers the
 * client's own click (CMSG_BANKER_ACTIVATE 0x01B7 -> WorldSession::HandleBankerActivateOpcode ->
 * Player::GetNPCIfCanInteractWith(guid, UNIT_NPC_FLAG_BANKER) -> SendShowBank), which is a path
 * that already allows a player's own pet or guardian.
 *
 * What this module adds is what data cannot express:
 *
 *   * the summon restriction and the use restriction. "High-Risk Open World" is the character
 *     ruleset this fork keeps in src/server/coa/AscensionRulesets.cpp: High-Risk is aura
 *     1004019, War Mode is aura 1004119, and PvE is that same War Mode aura *plus* the marker
 *     9931032 - which is how the client tells the two apart. So the states stay separate here as
 *     they are on the client: War Mode and High-Risk refuse the companion, PvE keeps it. The
 *     refusal speaks with the item's own wording instead of the client's generic cast error, and
 *     each half can be switched off where an operator wants it allowed. A *city* is exempt
 *     altogether, because a city is not "Open World" and this realm's own PvP rulesets cannot reach
 *     a character inside one - see InCity.
 *   * the refusal lines go to the middle of the screen as well as to the chat log, on the realm's
 *     own notification opcode, so the reason is read where the player is looking - see SendNotice.
 *   * the click. A companion keeps its banker flag in every ruleset, so it is always right-clickable
 *     and the click can be *answered*: with the reason when the ruleset forbids it. A companion
 *     serves whoever clicks it, and the window the core opens is the clicker's own bank, so a keeper
 *     another player has out is theirs too - under the same rules, read from the clicker. That is
 *     what PlayerScript::OnPlayerBankerActivate (PLAYERHOOK_ON_BANKER_ACTIVATE) is for - the one
 *     place the native bank window can be withheld, called from the core's own handler before it
 *     resolves the click.
 *   * the readiness report at startup, because every way this companion can be wrong is silent:
 *     without the banker flag a click produces no packet at all, and the display the pets use
 *     carries a 3.5x client model scale (CreatureDisplayInfo.dbc) that an un-countered server
 *     scale turns into a giant. Both are data, and both are in the SQL next door.
 *
 * Deliberately not done here: a second bank window. The core's own handler is the single
 * implementation of "open the native bank", and this module only ever says no to it - a second open
 * would be a second opinion about the same character, exactly as a hand-built trainer window would
 * be for the books.
 */

#include "Chat.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DBCStructure.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include "WorldPacket.h"

namespace
{
// The companions, their summon spells and the displays the client gives them. The displays are
// quoted from the client's own creature cache and from CoA's collection model
// table (AscensionCollectionModelData.h), so the two agree by construction.
constexpr uint32 CELESTIAL_TREASURE_KEEPER = 80918;
constexpr uint32 TREASURE_KEEPER = 10111377;
constexpr uint32 CELESTIAL_TREASURE_KEEPER_DISPLAY = 47857;   // Creature\CelestialHuman\CelestialHuman.m2, client scale 3.5
constexpr uint32 TREASURE_KEEPER_DISPLAY = 48611;             // Creature\wyrmtongue\wyrmtongue.mdx, client scale 0.5
constexpr uint32 SPELL_SUMMON_CELESTIAL_TREASURE_KEEPER = 93417;
constexpr uint32 SPELL_SUMMON_TREASURE_KEEPER = 985356;

// The character rulesets, kept in step with CoA's AscensionRulesets.cpp, which
// selects and applies them. Read from auras rather than from the selection spells: the selection
// spells are the menu, the auras are the state.
constexpr uint32 SPELL_HIGH_RISK = 1004019;   // "High-Risk mode is enabled..."
constexpr uint32 SPELL_WAR_MODE = 1004119;    // carried by War Mode *and* by the PvE set
constexpr uint32 SPELL_PVE = 9931032;         // the marker that tells the PvE set from War Mode

// On by default: the item says the companion "cannot be summoned in High-Risk Open World", and a
// ruleset is where that is enforced. Turning either off allows the summon in that ruleset.
[[nodiscard]] bool BlockedInHighRisk()
{
    return sConfigMgr->GetOption<bool>("TreasureKeeper.BlockInHighRisk", true);
}

[[nodiscard]] bool BlockedInWarMode()
{
    return sConfigMgr->GetOption<bool>("TreasureKeeper.BlockInWarMode", true);
}

// On by default: PvE is its own ruleset, not War Mode. The client makes that distinction with the
// marker 9931032 on top of the shared War Mode aura, so the marker is what a PvE character is
// separated by - and turning this off reads the shared aura alone instead, which refuses PvE too.
[[nodiscard]] bool SeparatePve()
{
    return sConfigMgr->GetOption<bool>("TreasureKeeper.SeparatePveFromWarMode", true);
}

// On by default: a city is not "High-Risk Open World", so the rulesets do not reach a companion
// there either - see InCity below.
[[nodiscard]] bool AllowedInCities()
{
    return sConfigMgr->GetOption<bool>("TreasureKeeper.AllowInCities", true);
}

/// The three states the client's own `C_Player:GetRuleset` reads out of these auras, read once here
/// so the summon gate and the summon guard below cannot drift apart.
struct Ruleset
{
    bool HighRisk;
    bool WarMode;     // the aura the client names "War Mode": carried by War Mode *and* by the PvE set
    bool PveMarker;   // the marker that tells the PvE set from War Mode

    [[nodiscard]] char const* Name() const
    {
        if (HighRisk)
            return "High-Risk Mode";
        if (!WarMode)
            return "no ruleset";
        return PveMarker ? "PvE Mode" : "War Mode";
    }

    // The rulesets are three separate states and the buffs are the rule. PvE is the marker's own
    // state: it carries the shared War Mode aura, but the marker is what makes it PvE, so only War
    // Mode itself - the aura with no marker - and High-Risk refuse the companions.
    [[nodiscard]] bool Refused() const
    {
        return (BlockedInHighRisk() && HighRisk) ||
               (BlockedInWarMode() && WarMode && !(SeparatePve() && PveMarker));
    }
};

[[nodiscard]] Ruleset ReadRuleset(Player* player)
{
    return { player->HasAura(SPELL_HIGH_RISK), player->HasAura(SPELL_WAR_MODE),
             player->HasAura(SPELL_PVE) };
}

/// The state a character is in, named the way the messages name it.
[[nodiscard]] char const* RulesetName(Player* player)
{
    return ReadRuleset(player).Name();
}

[[nodiscard]] char const* RefusalText(Player* player)
{
    return player->HasAura(SPELL_HIGH_RISK)
               ? "Your Treasure Keeper cannot be summoned in High-Risk Open World."
               : "Your Treasure Keeper cannot be summoned while War Mode is active.";
}

/// The same rules, said about the companion that is already out: the item limits where it may be
/// *summoned*, so a summon that was allowed still ends up on a character who is no longer in a safe
/// zone. The click is answered rather than ignored, because that is what the player just did.
[[nodiscard]] char const* UseRefusalText(Player* player)
{
    return player->HasAura(SPELL_HIGH_RISK)
               ? "Your Treasure Keeper cannot be used in High-Risk Open World."
               : "Your Treasure Keeper cannot be used while War Mode is active.";
}

/// Whether the character stands in a city - Stormwind, Orgrimmar, the Undercity, Thunder Bluff,
/// Darnassus, the Exodar, Silvermoon, Shattrath or Dalaran, including their own subzones.
///
/// Read from the client's own area flags, the flag the core's own rest and PvP logic reads for a
/// capital (`AREA_FLAG_CAPITAL`, which the zone and every one of its subzones carries). The zone is
/// checked as well as the area, because a few subzones - Stormwind's Valley of Heroes, for one -
/// carry no flags of their own.
[[nodiscard]] bool InCity(Player* player)
{
    if (AreaTableEntry const* area = sAreaTableStore.LookupEntry(player->GetAreaId()))
        if (area->flags & AREA_FLAG_CAPITAL)
            return true;

    if (AreaTableEntry const* zone = sAreaTableStore.LookupEntry(player->GetZoneId()))
        if (zone->flags & AREA_FLAG_CAPITAL)
            return true;

    return false;
}

/// The ruleset a character is in, minus the one place a ruleset does not reach: a city. The item
/// calls the companion a bank "while in safe zones" and refuses it in "High-Risk Open World" - and
/// a city is not open world: this realm's own PvP rulesets cannot touch a character inside one, so
/// the companion works there whatever the ruleset says. This is the single decision every caller
/// shares - the summon gate, the summon guard and the click.
[[nodiscard]] bool CompanionRefused(Player* player)
{
    if (!ReadRuleset(player).Refused())
        return false;

    return !(AllowedInCities() && InCity(player));
}

/// One line in the middle of the screen as well as in the chat log: `SMSG_NOTIFICATION`, the
/// opcode this realm's own notifications use (the weaver's messages go out on it too). One packet
/// per line, because the client draws one notification per packet. The line is the chat line, so
/// the two never say different things.
void SendNotice(Player* player, std::string const& line)
{
    if (!player || !player->IsInWorld())
        return;

    std::string const text = std::string("|cffffff00") + line;

    WorldPacket data(SMSG_NOTIFICATION, text.size() + 1);
    data << text;
    player->SendDirectMessage(&data);

    ChatHandler(player->GetSession()).SendSysMessage(text);
}

/// Whether the creature is one of the two companions.
[[nodiscard]] bool IsKeeper(Creature* creature)
{
    return creature && (creature->GetEntry() == CELESTIAL_TREASURE_KEEPER ||
                        creature->GetEntry() == TREASURE_KEEPER);
}

/// The bank flag is never taken away, so the companion stays right-clickable in every ruleset: the
/// click is answered with the reason instead of being refused silently by the flag's absence (the
/// client sends nothing at all for a unit without it).
///
/// A companion serves whoever clicks it - the bank the core opens is the *clicking* character's own,
/// so a keeper another player has out is their bank too, under the same rules. Those rules are
/// therefore read from the clicker and never from the owner: it is the clicker's ruleset and the
/// clicker's city that decide whether the window opens, and the clicker who is told why when it does
/// not.
///
/// The click is answered before the core resolves it, because in the PvP rulesets the core's own
/// interaction checks are what would refuse it without a word - so the script does the one check
/// that matters for a message itself: the unit is in reach (or is the clicker's own, wherever the
/// core's own checks stand on it). A packet that names a companion across the map is left to the
/// core as before, so no player is ever told about a click they did not make.
class treasure_keeper_bank_gate : public PlayerScript
{
public:
    treasure_keeper_bank_gate()
        : PlayerScript("treasure_keeper_bank_gate", { PLAYERHOOK_ON_BANKER_ACTIVATE }) { }

    bool OnPlayerBankerActivate(Player* player, ObjectGuid guid) override
    {
        if (!player || !guid)
            return true;

        Creature* keeper = ObjectAccessor::GetCreatureOrPetOrVehicle(*player, guid);
        if (!IsKeeper(keeper))
            return true;

        Player* owner = keeper->GetCharmerOrOwnerPlayerOrPlayerItself();

        // A click the character could have made is answered: a companion in their reach, or their
        // own wherever the core's interaction checks stand on it. Anything else is the core's
        // business, as before.
        if (owner != player && !keeper->IsWithinDistInMap(player, INTERACTION_DISTANCE))
            return true;

        // The window the core is about to open is the clicker's own bank, so a companion that is
        // somebody else's serves on exactly the same terms as their own.
        if (!CompanionRefused(player))
            return true;

        LOG_INFO("module.treasurekeeper", "Refused the bank of entry {} (owned by {}) for {}: {} "
                 "({} yards, reaction {}); the character is not in a city.", keeper->GetEntry(),
                 owner ? owner->GetName() : "nobody", player->GetName(), RulesetName(player),
                 keeper->GetDistance(player), uint32(keeper->GetReactionTo(player)));
        SendNotice(player, UseRefusalText(player));
        return false;
    }
};
}

/// The summon spells of both companions. Refused while the character is in War Mode or High-Risk -
/// PvE is a ruleset of its own and keeps its companion. A companion that is already out is not
/// taken away by a ruleset change; it answers the next click with the reason instead - see the bank
/// gate below.
class spell_treasure_keeper_summon : public SpellScript
{
    PrepareSpellScript(spell_treasure_keeper_summon);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ SPELL_HIGH_RISK, SPELL_WAR_MODE, SPELL_PVE });
    }

    bool Load() override
    {
        return GetCaster()->ToPlayer() != nullptr;
    }

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster()->ToPlayer();
        Ruleset const ruleset = ReadRuleset(player);

        // One line per summon attempt, because this ruleset cannot be read off the client: the PvE
        // set carries the War Mode aura as well, so a character the client names "War Mode" may be
        // the PvE default, and only the PvE marker tells the two apart. Read here rather than
        // guessed at, this is what says which set the summon was allowed or refused under.
        LOG_INFO("module.treasurekeeper", "Summon {} by {}: {}, i.e. High-Risk {} / War Mode aura {} "
                 "/ PvE marker {}; refusing high risk = {}, war mode = {}.", GetSpellInfo()->Id,
                 player->GetName(), ruleset.Name(), ruleset.HighRisk, ruleset.WarMode,
                 ruleset.PveMarker, BlockedInHighRisk(), BlockedInWarMode());

        if (CompanionRefused(player))
        {
            LOG_INFO("module.treasurekeeper", "Refused summon spell {} to {}: {} (refusing high "
                     "risk = {}, war mode = {}); the character is not in a city.",
                     GetSpellInfo()->Id, player->GetName(), ruleset.Name(), BlockedInHighRisk(),
                     BlockedInWarMode());
            // The player has been told why; the client's own generic cast error would only
            // repeat it worse.
            SendNotice(player, RefusalText(player));
            return SPELL_FAILED_DONT_REPORT;
        }

        // An allowed summon says nothing: the line the log already carries above names the ruleset,
        // and a summon is not worth a chat message of its own.
        return SPELL_CAST_OK;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_treasure_keeper_summon::CheckCast);
    }
};

/// The summon gate above answers the two summon spells. This answers the creature, so that whatever
/// path produced it - the item, the companion tab, a macro, an addon - the companion exists only
/// where the ruleset allows it. It is also the one place a summon that did not come through the
/// gate leaves a line in the log, naming what came up and under which ruleset.
class treasure_keeper_summon_guard : public AllCreatureScript
{
public:
    treasure_keeper_summon_guard() : AllCreatureScript("treasure_keeper_summon_guard") { }

    void OnCreatureAddWorld(Creature* creature) override
    {
        if (!creature || !creature->IsSummon() ||
            (creature->GetEntry() != CELESTIAL_TREASURE_KEEPER &&
             creature->GetEntry() != TREASURE_KEEPER))
            return;

        Unit* summoner = creature->ToTempSummon()->GetSummonerUnit();
        Player* owner = summoner ? summoner->ToPlayer() : nullptr;
        if (!owner)
            return;

        if (!CompanionRefused(owner))
            return;

        LOG_INFO("module.treasurekeeper", "entry {} came up for {} while {} (and not in a city) "
                 "although the summon spells did not refuse it; dismissing it.",
                 creature->GetEntry(), owner->GetName(), RulesetName(owner));
        SendNotice(owner, RefusalText(owner));
        creature->DespawnOrUnsummon();
    }
};

/// Reports both companions at startup. This restoration has two data halves and both fail
/// silently in play: a companion without the banker flag answers a right click with nothing at
/// all, and one whose server scale does not counter its display's client scale renders at a size
/// nobody chose. Neither shows up in a log, so this does.
class treasure_keeper_readiness : public WorldScript
{
public:
    treasure_keeper_readiness()
        : WorldScript("treasure_keeper_readiness", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        Report(CELESTIAL_TREASURE_KEEPER, "Celestial Treasure Keeper", CELESTIAL_TREASURE_KEEPER_DISPLAY);
        Report(TREASURE_KEEPER, "Treasure Keeper", TREASURE_KEEPER_DISPLAY);
    }

private:
    static void Report(uint32 entry, char const* name, uint32 expectedDisplay)
    {
        CreatureTemplate const* proto = sObjectMgr->GetCreatureTemplate(entry);
        if (!proto)
        {
            LOG_ERROR("module.treasurekeeper", "{} (entry {}) is missing from `creature_template`; "
                      "the companion cannot be summoned at all.", name, entry);
            return;
        }

        if (proto->Models.empty())
        {
            LOG_ERROR("module.treasurekeeper", "{} (entry {}) has no row in `creature_template_model`; "
                      "the core drops the creature with \"has no model ... can't load\".", name, entry);
            return;
        }

        uint32 const display = proto->Models.front().CreatureDisplayID;
        float const serverScale = proto->Models.front().DisplayScale;

        if (!sObjectMgr->GetCreatureModelInfo(display))
            LOG_ERROR("module.treasurekeeper", "{} (entry {}) uses display {} but `creature_model_info` "
                      "has no row for it; its bounding radius and combat reach stay at the default.",
                      name, entry, display);

        if (display != expectedDisplay)
            LOG_ERROR("module.treasurekeeper", "{} (entry {}) uses display {} where the client's own "
                      "cache says {}; the summoned pet would draw as something else.", name, entry,
                      display, expectedDisplay);

        // The rendered size is the display's own client scale times the server's, so a server
        // scale of 1 leaves an unusual display at whatever its DBC says. 47857 says 3.5.
        float const clientScale = sCreatureDisplayInfoStore.LookupEntry(display)
                                      ? sCreatureDisplayInfoStore.LookupEntry(display)->scale : 1.0f;
        float const rendered = clientScale * serverScale;
        if (rendered > 1.5f)
            LOG_ERROR("module.treasurekeeper", "{} (entry {}) renders at {}x natural size "
                      "(display {} client scale {} x server scale {}); correct it in "
                      "`creature_template_model`.`DisplayScale`.", name, entry, rendered, display,
                      clientScale, serverScale);

        // The flag decides whether the click ever reaches the core. A wrong answer here is as
        // silent as the books' was: nothing is sent, so nothing can fail.
        if (!(proto->npcflag & UNIT_NPC_FLAG_BANKER))
            LOG_ERROR("module.treasurekeeper", "{} (entry {}) is not flagged as a banker "
                      "(npcflag 0x{:X}); the client only offers a bank to a banker-flagged unit "
                      "and a right click on it would answer nothing.", name, entry, proto->npcflag);
        else if (proto->npcflag & UNIT_NPC_FLAG_GOSSIP)
            LOG_ERROR("module.treasurekeeper", "{} (entry {}) carries the gossip flag "
                      "(npcflag 0x{:X}); the client then reads it as a gossip NPC and never sends "
                      "the banker click. Keep `npcflag` at 131072 (banker) alone.", name, entry,
                      proto->npcflag);

        LOG_INFO("module.treasurekeeper", "{} (entry {}) ready: display {} (client scale {} x "
                 "server scale {} = {}x), npcflag 0x{:X}, unit_flags 0x{:X}.", name, entry, display,
                 clientScale, serverScale, rendered, proto->npcflag, proto->unit_flags);
    }
};

void AddSC_treasure_keeper()
{
    RegisterSpellScript(spell_treasure_keeper_summon);
    new treasure_keeper_summon_guard();
    new treasure_keeper_bank_gate();
    new treasure_keeper_readiness();
}
