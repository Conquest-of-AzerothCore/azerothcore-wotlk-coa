/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
/*
 * mod-craftsmans-codex - CoA's Craftsman's Codex: one extra primary profession.
 *
 * The item "Craftsman's Codex" (97871, and 2200001 "Soulbound Craftsman's Codex" - the same row
 * with Bonding = 1) carries one on-use spell, 93292, whose single effect is SPELL_EFFECT_DUMMY
 * and whose own text is the whole promise:
 *
 *     "Unlocks a new primary profession slot. You can unlock all primary professions."
 *
 * A dummy effect does nothing by itself, and the client ships no behaviour behind this one: its
 * Interface/FrameXML/Data/Items.lua knows the id (CRAFTSMANS_CODEX = 97871) and
 * Ascension_ProfessionBook.lua quotes it in the hint it shows when you try to open a third
 * profession - "You will need to use a [Craftsman's Codex] to learn an additional profession" -
 * and that is all the client does with it. So where the portable gadgets needed data, this one
 * needs code.
 *
 * What a "primary profession slot" is, though, is not ours to invent. The core already keeps the
 * number of slots a character has left to spend in one player field, PLAYER_CHARACTER_POINTS2
 * (Player::GetFreePrimaryProfessionPoints), and that single value is the whole gate:
 *
 *   * Player::InitPrimaryProfessions sets it to MaxPrimaryTradeSkill before the spell book is
 *     loaded, and loading spends one per primary profession the character already knows, so its
 *     meaning is "profession slots still free";
 *   * Trainer::CanTeachSpell refuses a profession's first rank while it is zero - the only thing
 *     standing between a character and their third profession;
 *   * Trainer::SendSpells tells the client how many profession points each trainer entry costs,
 *     which is what greys a profession out in the trainer window.
 *
 * Unlocking a slot is therefore adding to that number, and that is what this module does. What
 * data cannot hold is how many codexes a character has spent: the counter is rebuilt from the
 * maximum at every login, so the unlock is remembered per character in `mod_craftsmans_codex`
 * (data/sql/db-characters) and returned to the counter before the client is told anything.
 *
 * The grant is permanent, and it survives the two ways a character could otherwise lose it:
 * unlearning a profession (where the core refunds a slot but caps the refund at
 * MaxPrimaryTradeSkill, a ceiling an unlocked character is above) and relogging. Both are
 * handled by re-deriving the allowance from the number of professions the character actually
 * knows, counted the same way the core counts them when it spends a slot - a primary
 * profession's first rank, present in the spell book.
 *
 * Server-side only: no client file changes, no new opcodes. The item, its icon, its tooltip text
 * and the profession-book hint all ship in the client already; the client is told the result the
 * same way it is told any other profession count, through the player field it already reads.
 */

#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "DBCStores.h"
#include "DBCStructure.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "World.h"
#include "WorldSession.h"

#include <array>
#include <mutex>
#include <string>
#include <string_view>
#include <unordered_map>

using namespace Acore::ChatCommands;

namespace
{
// The codex's own spell, shared by every item that grants one.
constexpr uint32 CodexSpell = 93292;
constexpr char const* CodexScriptName = "spell_craftsmans_codex";
constexpr char const* CodexTable = "mod_craftsmans_codex";

// The items that carry it: the one CoA sold (97871) and the soulbound variant (2200001).
constexpr std::array<uint32, 2> CodexItems = { 97871, 2200001 };

[[nodiscard]] bool Enabled()
{
    return sConfigMgr->GetOption<bool>("CraftsmansCodex.Enable", true);
}

// The professions every character starts with room for.
[[nodiscard]] uint32 BaseSlots()
{
    return sWorld->getIntConfig(CONFIG_MAX_PRIMARY_TRADE_SKILL);
}

// Every skill line the client's SkillLine.dbc files under SKILL_CATEGORY_PROFESSION - the set
// "all primary professions" means. Stock 3.3.5 has 11; this realm's own SkillLine.dbc also
// carries CoA's Fletching, so its number is whatever that table says, not a constant.
[[nodiscard]] uint32 ProfessionCount()
{
    uint32 count = 0;
    for (uint32 i = 1; i < sSkillLineStore.GetNumRows(); ++i)
        if (SkillLineEntry const* skill = sSkillLineStore.LookupEntry(i))
            if (skill->categoryId == SKILL_CATEGORY_PROFESSION)
                ++count;

    return count;
}

// How many professions a character may hold in total: the base allowance plus every codex
// they can still spend. Reaching it is what "You can unlock all primary professions" means.
[[nodiscard]] uint32 SlotCeiling()
{
    uint32 const configured = sConfigMgr->GetOption<uint32>("CraftsmansCodex.MaxSlots", 0);
    return configured ? configured : ProfessionCount();
}

// The professions a character knows, counted exactly the way the core counts them when it
// spends a slot while loading the spell book: a primary profession's first rank, present in
// the spell book. Reading the same set is what makes the allowance below a re-derivation
// rather than a second opinion.
[[nodiscard]] uint32 KnownPrimaryProfessions(Player const* player)
{
    uint32 known = 0;
    for (auto const& [spellId, playerSpell] : player->GetSpellMap())
    {
        if (!playerSpell || playerSpell->State == PLAYERSPELL_REMOVED)
            continue;

        // The load path spends a slot only for a spell in the active spec (`_addSpell` returns
        // before its accounting otherwise), so a spell outside it is not a profession here.
        if (!playerSpell->IsInSpec(player->GetActiveSpec()))
            continue;

        SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
        if (info && info->IsPrimaryProfessionFirstRank())
            ++known;
    }

    return known;
}

// Hand the character's allowance to the core: the counter is "profession slots still free", so
// it is the allowance minus the professions that already fill it.
void ApplyAllowance(Player* player, uint32 unlockedSlots)
{
    uint32 const allowance = BaseSlots() + unlockedSlots;
    uint32 const known = KnownPrimaryProfessions(player);
    uint32 const free = allowance > known ? allowance - known : 0;

    if (player->GetFreePrimaryProfessionPoints() == free)
        return;

    player->SetFreePrimaryProfessions(uint16(free));

    // The client reads the count from this field, and the trainer window prices every
    // profession against it, so it has to be re-sent rather than only stored.
    player->ForceValuesUpdateAtIndex(PLAYER_CHARACTER_POINTS2);
}

// What a codex says when it lands, in the two places a player looks: a line in the chat frame,
// which stays there as a record, and a line across the middle of the screen, which is hard to
// miss. Both are coloured - `|cffRRGGBB`...`|r` is the client's own escape, the same one an item
// link is built from - and both use the same two: the thing the player just got in gold, the
// change itself in green, over the channel's own base colour. A line that is one colour top to
// bottom reads as a warning no matter which colour it is.
//
// Neither line counts anything. How many professions the character holds and how many slots they
// have unlocked are both real numbers, and quoting them together is how a player ends up doing
// subtraction over a toast they will read once: "3 of your 3 slots are still free" says the same
// thing as "a new slot is unlocked" and takes twice as long to believe. The counters are what
// `.codex status` is for.
static void AnnounceUnlock(Player* player)
{
    ChatHandler(player->GetSession()).PSendSysMessage(
        "|cffffd100Craftsman's Codex|r: a new |cff40ff40primary profession slot|r is unlocked.");

    // Short on purpose: this one is drawn large, over whatever the player was doing, and it is
    // gone again in a few seconds. Same palette as the chat line rather than one flat colour, so
    // it reads as an announcement and not as an error.
    player->GetSession()->SendAreaTriggerMessage(
        "|cffffd100New profession slot|r |cff40ff40unlocked|r");
}

// The codexes each character has spent, backed by the characters database and remembered for
// the session so the hot paths never touch the database.
class CodexStore
{
public:
    static CodexStore& Instance()
    {
        static CodexStore store;
        return store;
    }

    // Unlocked slots for this character, 0 for one that never used a codex. Read once per login
    // and from the database on demand for a character the module has not seen yet (- a command
    // naming an offline character).
    uint32 Slots(uint32 characterGuid)
    {
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _slots.find(characterGuid);
            if (itr != _slots.end())
                return itr->second;
        }

        uint32 slots = 0;
        if (QueryResult result = CharacterDatabase.Query("SELECT `slots` FROM `{}` WHERE `guid` = {}",
                                                         CodexTable, characterGuid))
            slots = result->Fetch()[0].Get<uint32>();

        std::lock_guard<std::mutex> lock(_mutex);
        _slots[characterGuid] = slots;
        return slots;
    }

    // Called for a character entering the world, before the client has been sent anything.
    void Load(uint32 characterGuid)
    {
        {
            std::lock_guard<std::mutex> lock(_mutex);
            _slots.erase(characterGuid);
        }

        Slots(characterGuid);
    }

    void Unload(uint32 characterGuid)
    {
        std::lock_guard<std::mutex> lock(_mutex);
        _slots.erase(characterGuid);
    }

    // One codex spent: adds a slot and writes it through. The row is keyed by the character,
    // and a character's first codex is what creates it.
    uint32 Add(uint32 characterGuid)
    {
        uint32 const slots = Slots(characterGuid) + 1;

        {
            std::lock_guard<std::mutex> lock(_mutex);
            _slots[characterGuid] = slots;
        }

        CharacterDatabase.Execute(
            "INSERT INTO `{}` (`guid`, `slots`) VALUES ({}, {}) "
            "ON DUPLICATE KEY UPDATE `slots` = {}, `last_used_at` = CURRENT_TIMESTAMP",
            CodexTable, characterGuid, slots, slots);

        return slots;
    }

    void Reset(uint32 characterGuid)
    {
        {
            std::lock_guard<std::mutex> lock(_mutex);
            _slots[characterGuid] = 0;
        }

        CharacterDatabase.Execute("DELETE FROM `{}` WHERE `guid` = {}", CodexTable, characterGuid);
    }

private:
    CodexStore() = default;

    std::mutex _mutex;
    std::unordered_map<uint32, uint32> _slots;
};

// A character guid from a name, whether or not that character is online: a codex can be spent
// on an offline character - there is nothing to apply it to at the time, and the login hook
// picks it up - and a game master may want to look at one.
[[nodiscard]] uint32 CharacterGuidByName(std::string_view name)
{
    std::string escaped(name);
    CharacterDatabase.EscapeString(escaped);

    if (QueryResult result = CharacterDatabase.Query("SELECT `guid` FROM `characters` WHERE `name` = '{}'", escaped))
        return result->Fetch()[0].Get<uint32>();

    return 0;
}

// One codex spent: remember it, hand the new allowance to the core, and tell the player.
void UnlockSlot(Player* player)
{
    uint32 const characterGuid = player->GetGUID().GetCounter();
    uint32 const slots = CodexStore::Instance().Add(characterGuid);

    ApplyAllowance(player, slots);

    AnnounceUnlock(player);

    LOG_INFO("module",
             "mod-craftsmans-codex: {} ({}) used a Craftsman's Codex - {} unlocked slot(s), allowance {}.",
             player->GetName(), characterGuid, slots, BaseSlots() + slots);
}

// ---------------------------------------------------------------------------------------
// The spell
// ---------------------------------------------------------------------------------------

class spell_craftsmans_codex : public SpellScript
{
    PrepareSpellScript(spell_craftsmans_codex);

    // A codex is worth nothing to a character who can already hold every profession, and the
    // item is consumed on a successful cast (item_template.spellcharges_1 = -1, taken by
    // Spell::TakeCastItem), so the two cases where that is true are refused before the cast
    // rather than paid for.
    SpellCastResult CheckRoom()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player)
            return SPELL_CAST_OK;

        if (!Enabled())
        {
            LOG_DEBUG("module", "mod-craftsmans-codex: {} used a Craftsman's Codex while the module is disabled.",
                      player->GetName());
            return SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        }

        uint32 const unlocked = CodexStore::Instance().Slots(player->GetGUID().GetCounter());
        uint32 const ceiling = SlotCeiling();

        if (KnownPrimaryProfessions(player) >= ceiling || BaseSlots() + unlocked >= ceiling)
            return SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;

        return SPELL_CAST_OK;
    }

    void Unlock(SpellEffIndex /*effIndex*/)
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (player && Enabled())
            UnlockSlot(player);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_craftsmans_codex::CheckRoom);
        OnEffectHitTarget += SpellEffectFn(spell_craftsmans_codex::Unlock, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

// ---------------------------------------------------------------------------------------
// The character's allowance: kept right at login and after a profession is unlearned
// ---------------------------------------------------------------------------------------

class craftsmans_codex_allowance : public PlayerScript
{
public:
    craftsmans_codex_allowance() : PlayerScript("craftsmans_codex_allowance",
        { PLAYERHOOK_ON_LOAD_FROM_DB, PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_FORGOT_SPELL }) { }

    // Player::LoadFromDB, before the client is sent the character. This matters: the counter has
    // to be part of that first update, because the client prices trainer entries against it.
    //
    // The spell book is not loaded yet at this point (`Player::_LoadSpells` runs after this
    // hook), and it does not have to be: Player::InitPrimaryProfessions has just set the counter
    // to MaxPrimaryTradeSkill with the comment "to max set before any spell loaded", and the
    // load spends one slot per profession the character already knows. Adding the unlocked slots
    // to that maximum is therefore adding them to the finished allowance.
    void OnPlayerLoadFromDB(Player* player) override
    {
        if (!Enabled())
            return;

        uint32 const characterGuid = player->GetGUID().GetCounter();
        CodexStore::Instance().Load(characterGuid);
        player->SetFreePrimaryProfessions(uint16(BaseSlots() + CodexStore::Instance().Slots(characterGuid)));
    }

    // The authoritative pass, now that the spell book is in memory: the allowance minus the
    // professions the character actually holds. A no-op when the load above was already right.
    void OnPlayerLogin(Player* player) override
    {
        if (!Enabled())
            return;

        ApplyAllowance(player, CodexStore::Instance().Slots(player->GetGUID().GetCounter()));
    }

    void OnPlayerLogout(Player* player) override
    {
        CodexStore::Instance().Unload(player->GetGUID().GetCounter());
    }

    // Unlearning a profession refunds the slot the core spent on it, but caps the refund at
    // MaxPrimaryTradeSkill (Player::removeSpell) - a ceiling a character with unlocked slots is
    // above, which would silently eat one of them. The refund is re-derived here instead.
    void OnPlayerForgotSpell(Player* player, uint32 spellId) override
    {
        if (!Enabled())
            return;

        SpellInfo const* removed = sSpellMgr->GetSpellInfo(spellId);
        if (!removed || !removed->IsPrimaryProfessionFirstRank())
            return;

        uint32 const unlocked = CodexStore::Instance().Slots(player->GetGUID().GetCounter());
        if (!unlocked)                              // nothing unlocked: the core's own refund is right
            return;

        ApplyAllowance(player, unlocked);
    }
};

// ---------------------------------------------------------------------------------------
// Startup check and the game master command
// ---------------------------------------------------------------------------------------

class CraftsmansCodexWorldScript : public WorldScript
{
public:
    CraftsmansCodexWorldScript() : WorldScript("CraftsmansCodexWorldScript") { }

    void OnStartup() override
    {
        if (!sConfigMgr->GetOption<bool>("CraftsmansCodex.VerifyOnStartup", true))
            return;

        bool complete = true;

        // The spell has to be the dummy this module answers, or the cast never reaches the script.
        SpellInfo const* spell = sSpellMgr->GetSpellInfo(CodexSpell);
        if (!spell || spell->Effects[EFFECT_0].Effect != SPELL_EFFECT_DUMMY)
        {
            LOG_ERROR("module", "mod-craftsmans-codex: spell {} is not in the server's spell data with a "
                      "SPELL_EFFECT_DUMMY first effect - the codex items cannot work.", CodexSpell);
            complete = false;
        }

        // A registered script runs only where the database binds the spell to it.
        bool bound = false;
        SpellScriptsBounds const scripts = sObjectMgr->GetSpellScriptsBounds(CodexSpell);
        for (auto itr = scripts.first; itr != scripts.second; ++itr)
            if (sObjectMgr->GetScriptName(itr->second) == CodexScriptName)
                bound = true;

        if (!bound)
        {
            LOG_ERROR("module", "mod-craftsmans-codex: spell {} is not bound to '{}' in `spell_script_names` - "
                      "apply modules/mod-craftsmans-codex/data/sql/db-world/.", CodexSpell, CodexScriptName);
            complete = false;
        }

        // The items have to be the ones that carry it.
        for (uint32 entry : CodexItems)
        {
            ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry);
            if (!item || item->Spells[0].SpellId != int32(CodexSpell))
            {
                LOG_ERROR("module", "mod-craftsmans-codex: item {} does not carry spell {} - a Craftsman's Codex "
                          "used through it would do nothing.", entry, CodexSpell);
                complete = false;
            }
        }

        // And the ledger has to exist, or every use would log a database error instead of granting.
        if (!CharacterDatabase.Query("SHOW TABLES LIKE '{}'", CodexTable))
        {
            LOG_ERROR("module", "mod-craftsmans-codex: the characters database has no `{}` table - apply "
                      "modules/mod-craftsmans-codex/data/sql/db-characters/.", CodexTable);
            complete = false;
        }

        if (complete)
            LOG_INFO("module", ">> mod-craftsmans-codex: Craftsman's Codex complete - spell {} bound, item(s) {} grant "
                     "one primary profession slot each (base {}, up to {} professions on this realm).",
                     CodexSpell, CodexItems[0], BaseSlots(), SlotCeiling());
        else
            LOG_WARN("module", ">> mod-craftsmans-codex: the Craftsman's Codex is not fully in place; see the errors above.");
    }
};

class CraftsmansCodexCommandScript : public CommandScript
{
public:
    CraftsmansCodexCommandScript() : CommandScript("CraftsmansCodexCommandScript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable codexCommandTable =
        {
            { "status", HandleStatusCommand, SEC_GAMEMASTER,    Console::Yes },
            { "grant",  HandleGrantCommand,  SEC_ADMINISTRATOR, Console::Yes },
            { "reset",  HandleResetCommand,  SEC_ADMINISTRATOR, Console::Yes },
        };

        static ChatCommandTable commandTable =
        {
            { "codex", codexCommandTable },
        };

        return commandTable;
    }

    // .codex status [name] - what the character's allowance is and how it is spent.
    static bool HandleStatusCommand(ChatHandler* handler, Optional<std::string> name)
    {
        Player* online = nullptr;
        uint32 characterGuid = 0;

        if (name)
        {
            online = ObjectAccessor::FindPlayerByName(*name);
            characterGuid = online ? online->GetGUID().GetCounter() : CharacterGuidByName(*name);
            if (!characterGuid)
            {
                handler->SendSysMessage("No character by that name.");
                return true;
            }
        }
        else
        {
            online = handler->GetPlayer();
            if (!online)
            {
                handler->SendSysMessage("Name a character: .codex status <name>");
                return true;
            }

            characterGuid = online->GetGUID().GetCounter();
        }

        uint32 const unlocked = CodexStore::Instance().Slots(characterGuid);
        uint32 const allowance = BaseSlots() + unlocked;
        uint32 const known = online ? KnownPrimaryProfessions(online) : 0;
        uint32 const free = online ? online->GetFreePrimaryProfessionPoints() : (allowance > known ? allowance - known : 0);

        handler->PSendSysMessage("Craftsman's Codex - {} (guid {}):", name ? *name : online->GetName(), characterGuid);
        handler->PSendSysMessage("  codex slots unlocked: {}", unlocked);
        handler->PSendSysMessage("  allowance: {} primary professions ({} base + {} unlocked)",
                                 allowance, BaseSlots(), unlocked);
        handler->PSendSysMessage("  professions held: {}, still free: {}, ceiling: {}",
                                 known, free, SlotCeiling());

        if (!online)
            handler->SendSysMessage("  (offline; the held/free counts are what they will be on their next login)");

        return true;
    }

    // .codex grant <name> [count] - hand out unlocked slots without spending an item.
    static bool HandleGrantCommand(ChatHandler* handler, std::string name, Optional<uint32> count)
    {
        Player* online = ObjectAccessor::FindPlayerByName(name);
        uint32 const characterGuid = online ? online->GetGUID().GetCounter() : CharacterGuidByName(name);
        if (!characterGuid)
        {
            handler->SendSysMessage("No character by that name.");
            return true;
        }

        uint32 const wanted = count && *count ? *count : 1;

        uint32 slots = 0;
        for (uint32 i = 0; i < wanted; ++i)
            slots = CodexStore::Instance().Add(characterGuid);

        if (online)
        {
            ApplyAllowance(online, slots);

            // The slot is the player's, not the game master's: a grant announces itself exactly
            // the way the item does, so nobody is left with an allowance they were never told about.
            AnnounceUnlock(online);
        }

        handler->PSendSysMessage("{} now has {} unlocked slot(s): {} primary professions in total.",
                                 name, slots, BaseSlots() + slots);
        LOG_INFO("module", "mod-craftsmans-codex: .codex grant gave {} slot(s) to {} (guid {}), now {}.",
                 wanted, name, characterGuid, slots);

        return true;
    }

    // .codex reset <name> - take every unlocked slot back off a character.
    static bool HandleResetCommand(ChatHandler* handler, std::string name)
    {
        Player* online = ObjectAccessor::FindPlayerByName(name);
        uint32 const characterGuid = online ? online->GetGUID().GetCounter() : CharacterGuidByName(name);
        if (!characterGuid)
        {
            handler->SendSysMessage("No character by that name.");
            return true;
        }

        CodexStore::Instance().Reset(characterGuid);

        if (online)
            ApplyAllowance(online, 0);

        handler->PSendSysMessage("{} is back to {} primary profession(s).", name, BaseSlots());
        LOG_INFO("module", "mod-craftsmans-codex: .codex reset cleared the unlocked slots of {} (guid {}).",
                 name, characterGuid);

        return true;
    }
};
} // namespace

void AddSC_craftsmans_codex()
{
    RegisterSpellScript(spell_craftsmans_codex);

    new craftsmans_codex_allowance();
    new CraftsmansCodexWorldScript();

    if (sConfigMgr->GetOption<bool>("CraftsmansCodex.Command", true))
        new CraftsmansCodexCommandScript();
}
