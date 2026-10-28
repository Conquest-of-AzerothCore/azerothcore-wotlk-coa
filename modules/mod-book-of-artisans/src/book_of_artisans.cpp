/*
 * mod-book-of-artisans - the profession trainer books of the realm and the window they open.
 *
 * CoA's books are props a player right-clicks: the Book of Artisans teaches every profession,
 * every rank and every recipe, the Beginner's Book of Artisans the apprentice tier in the
 * starting zones. Both are ordinary core trainers - `creature_default_trainer` points the
 * creature at a `trainer` row and `trainer_spell` carries the list - so the window is the
 * core's own (`WorldSession::SendTrainerList` -> `Trainer::SendSpells`) and this module never
 * builds one. That is deliberate: `Trainer::GetSpellState` is the single function that both
 * writes a row's state and gates the purchase of it, so a row can never read as available in
 * the window and then be refused, or read as known and still be sold. A window built anywhere
 * else would be a second opinion about the same character.
 *
 * What the data cannot say either is which rows a player has any business seeing. The books carry
 * every rank of every profession at once, and the client draws every rank out of reach as a red row
 * nobody can buy: a character who has never held a needle gets shown Grand Master Tailoring, and
 * there is nothing to do about it from there. So the books ask for the trainable rows
 * (`SendTrainerList`'s `onlyTrainable`, a plain argument to `Trainer::SendSpells`): the entry rank
 * of each profession and the ranks they have reached. A rank they already hold is left out too: the
 * client re-reads the open window's rank rows whenever a spell is learned and draws a held rank as
 * available again, so a greyed rank row would turn green after the next recipe was trained.
 * Train the apprentice rank, put the skill to 50, and journeyman is in the next window sent.
 *
 * What the module adds is the two things data cannot express:
 *
 *   * the page's first option. A right click is answered with the page the SQL defines - "I
 *     require training!" and "I would like to browse your goods." - and the core is what
 *     sends it, so the module only takes over the training option: that is what keeps the
 *     window it opens the filtered one. The second option opens the vendor list, which is the
 *     core's own business, and the list of goods is data (`npc_vendor`);
 *   * the window is a snapshot of the character at the moment it was sent, so a purchase from
 *     the book is followed by a fresh list. Learning a profession, buying a rank and learning a
 *     recipe all change what the book offers - the rows behind them, the rows they made
 *     available - and without that second list the client would keep showing the state from
 *     before the purchase until the book was closed and reopened.
 *
 * Deliberately *not* done here: pushing a new list when a profession skill goes up elsewhere
 * (crafting, mainly). A trainer window in 3.3.5 is a snapshot the player reopens, pushing one
 * on every skill-up would send a 169 KB list behind a window that may well be closed, and the
 * client cannot tell the server that it closed the frame.
 *
 * The other half of the restoration is data, and it is in the SQL next door: the page, its two
 * options, the text it shows and the shelves behind the second option. `npcflag` 177 (gossip |
 * trainer | class trainer | vendor) is what makes the client ask for that page and then accept
 * both frames the page's options lead to. The startup check at the end of this file reports any
 * half of that chain that goes missing.
 *
 * The creature script is attached by the world SQL in data/sql/db-world/book_of_artisans.sql,
 * which also restores both creatures, their display and their spawns. That SQL is applied by
 * the core's own module updater, so the module and the data stay together.
 */

#include "Creature.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "Log.h"
#include "Mail.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "Trainer.h"
#include "WorldPacket.h"
#include "WorldSession.h"

namespace
{
    constexpr uint32 BOOK_OF_ARTISANS_ENTRY = 57500;     // Book of Artisans
    constexpr uint32 BEGINNERS_BOOK_ENTRY   = 57524;     // Beginner's Book of Artisans
    constexpr uint32 BOOK_DISPLAY_ID        = 48503;     // Creature\FlyingBook\FlyingBook_01_Pet_purple.mdx

    // The books hold every rank of every profession at once, and want the window without the rows
    // nobody could buy; each is asked for through the core, never built here (see the file header).
    constexpr bool ONLY_TRAINABLE_ROWS = true;

    bool IsBook(Creature const* creature)
    {
        if (!creature)
            return false;

        uint32 const entry = creature->GetEntry();
        return entry == BOOK_OF_ARTISANS_ENTRY || entry == BEGINNERS_BOOK_ENTRY;
    }

    // The tool a trade cannot work without. Woodcutting's Lumber Axe is handed out by mod-woodworking.
    constexpr std::pair<uint32, uint32> PROFESSION_TOOLS[] =
    {
        { SKILL_BLACKSMITHING, 5956 },  // Blacksmith Hammer
        { SKILL_JEWELCRAFTING, 20815 }, // Jeweler's Kit
        { SKILL_INSCRIPTION,   39505 }, // Virtuoso Inking Set
        { SKILL_MINING,        2901 },  // Mining Pick
        { SKILL_SKINNING,      7005 },  // Skinning Knife
        { SKILL_FISHING,       6256 },  // Fishing Pole
    };

    void GiveTool(Player* player, uint32 itemId)
    {
        if (player->HasItemCount(itemId, 1, true) || player->AddItem(itemId, 1))
            return;

        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        MailDraft draft("Book of Artisans", "The tool of your new trade did not fit in your bags.");
        if (Item* item = Item::CreateItem(itemId, 1, player))
        {
            item->SaveToDB(trans);
            draft.AddItem(item);
        }

        draft.SendMailTo(trans, player, MailSender(MAIL_CREATURE, BOOK_OF_ARTISANS_ENTRY));
        CharacterDatabase.CommitTransaction(trans);
    }
}

/// The page a right click opens is the SQL's (`gossip_menu_option` 57500: "I require
/// training!" and "I would like to browse your goods."), and the core sends it, so this class
/// does not answer the hello at all. It answers one of the page's two options: the training one
/// is taken over, because that is the only way the window it opens is the filtered one, and the
/// goods one is left to the core, which is where a vendor list comes from.
class BookOfArtisansScript : public CreatureScript
{
public:
    BookOfArtisansScript() : CreatureScript("npc_book_of_artisans") { }

    bool OnGossipSelect(Player* player, Creature* book, uint32 /*sender*/, uint32 action) override
    {
        // For a menu built from `gossip_menu_option`, what reaches a script as the action is the
        // option's own `OptionType` - see the SQL - so the page can be re-sorted without this
        // module losing track of which option it is answering.
        if (!player || !IsBook(book) || action != GOSSIP_OPTION_TRAINER)
            return false;

        ClearGossipMenuFor(player);
        player->GetSession()->SendTrainerList(book, ONLY_TRAINABLE_ROWS);
        return true;
    }
};

/// The book's own view of the trainer protocol. Both requests are consumed for these two
/// creatures so the answer is the same whichever way the client asks, and so a purchase can be
/// followed by a fresh window.
class BookOfArtisansServerScript : public ServerScript
{
public:
    BookOfArtisansServerScript()
        : ServerScript("BookOfArtisansServerScript", { SERVERHOOK_CAN_PACKET_RECEIVE }) { }

    [[nodiscard]] bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (!session || !session->GetPlayer())
            return true;

        uint16 const opcode = packet.GetOpcode();
        if (opcode != CMSG_TRAINER_LIST && opcode != CMSG_TRAINER_BUY_SPELL)
            return true;

        // A packed guid, and for a purchase the spell behind it. Read a copy so the dispatcher's
        // buffer is left alone for the trainers this module does not own.
        WorldPacket copy(packet);
        ObjectGuid guid;
        copy >> guid;
        if (!guid)
            return true;

        // The same gate the core's own handler applies, trainer flag included: a book that lost its
        // flag is a book the core would refuse, and this module must not be the way around that.
        Player* player = session->GetPlayer();
        Creature* book = player->GetNPCIfCanInteractWith(guid, UNIT_NPC_FLAG_TRAINER);
        if (!IsBook(book))
            return true;   // another trainer's packet: the core's own handler answers it

        if (opcode == CMSG_TRAINER_LIST)
        {
            player->GetSession()->SendTrainerList(book, ONLY_TRAINABLE_ROWS);
            return false;
        }

        int32 spellId = 0;
        copy >> spellId;

        // The core's own purchase: the same requirement check, the same price, the same failure
        // packets and the same learned spell as training from a placed trainer.
        if (Trainer::Trainer* trainer = sObjectMgr->GetTrainer(book->GetEntry()))
            if (spellId > 0)
            {
                std::vector<uint32> untrainedSkills;
                for (auto const& [skill, tool] : PROFESSION_TOOLS)
                    if (!player->HasSkill(skill))
                        untrainedSkills.push_back(skill);

                trainer->TeachSpell(book, player, uint32(spellId));

                for (auto const& [skill, tool] : PROFESSION_TOOLS)
                    if (player->HasSkill(skill)
                        && std::find(untrainedSkills.begin(), untrainedSkills.end(), skill) != untrainedSkills.end())
                        GiveTool(player, tool);
            }

        // Learning a profession, buying a rank or learning a recipe changes other rows too:
        // what the purchase made available, and what it made known. The client only sees that
        // in a list sent after the purchase.
        player->GetSession()->SendTrainerList(book, ONLY_TRAINABLE_ROWS);
        LOG_DEBUG("module.bookofartisans", "{} bought {} from book {}; window sent again.",
                  player->GetName(), spellId, book->GetEntry());
        return false;
    }
};

/// Reports at startup whether each book's whole chain - creature, display, model info, trainer,
/// page, shelves and the flags the client reads - survived, and what each half holds.
class BookOfArtisansWorldScript : public WorldScript
{
public:
    BookOfArtisansWorldScript()
        : WorldScript("BookOfArtisansWorldScript", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        Report(BOOK_OF_ARTISANS_ENTRY, "Book of Artisans");
        Report(BEGINNERS_BOOK_ENTRY, "Beginner's Book of Artisans");
    }

private:
    static void Report(uint32 entry, char const* name)
    {
        CreatureTemplate const* proto = sObjectMgr->GetCreatureTemplate(entry);
        if (!proto)
        {
            LOG_ERROR("module.bookofartisans", "{} (entry {}) is missing from `creature_template`; "
                      "the book cannot be spawned.", name, entry);
            return;
        }

        if (proto->Models.empty())
        {
            LOG_ERROR("module.bookofartisans", "{} (entry {}) has no row in `creature_template_model`; "
                      "the core drops the creature with \"has no model ... can't load\".", name, entry);
            return;
        }

        if (!sObjectMgr->GetCreatureModelInfo(BOOK_DISPLAY_ID))
        {
            LOG_ERROR("module.bookofartisans", "{} (entry {}) uses display {} but `creature_model_info` "
                      "has no row for it.", name, entry, BOOK_DISPLAY_ID);
            return;
        }

        // The flags decide whether the page and both of its options are ever drawn, and every
        // missing half is silent in game, so each one is reported here.
        if (!(proto->npcflag & UNIT_NPC_FLAG_TRAINER))
            LOG_ERROR("module.bookofartisans", "{} (entry {}) is not flagged as a trainer "
                      "(npcflag 0x{:X}); the client draws no trainer window for it, so "
                      "\"I require training!\" would open nothing.", name, entry, proto->npcflag);
        else if (!(proto->npcflag & UNIT_NPC_FLAG_GOSSIP))
            LOG_ERROR("module.bookofartisans", "{} (entry {}) carries no gossip flag (npcflag "
                      "0x{:X}); the client never asks for the page, and with it never offers the "
                      "shop. Set `npcflag` to 177.", name, entry, proto->npcflag);
        else if (!(proto->npcflag & UNIT_NPC_FLAG_VENDOR))
            LOG_ERROR("module.bookofartisans", "{} (entry {}) carries no vendor flag (npcflag "
                      "0x{:X}); \"I would like to browse your goods.\" would open nothing. "
                      "Set `npcflag` to 177.", name, entry, proto->npcflag);

        // The page and the shelves are data too, and half of either is just as silent.
        auto const page = sObjectMgr->GetGossipMenuItemsMapBounds(proto->GossipMenuId);
        if (page.first == page.second)
            LOG_ERROR("module.bookofartisans", "{} (entry {}) has `gossip_menu_id` {} with no "
                      "rows in `gossip_menu_option`; its page would come up empty.", name, entry,
                      proto->GossipMenuId);

        VendorItemData const* shelves = sObjectMgr->GetNpcVendorItemList(entry);
        if (!shelves)
            LOG_ERROR("module.bookofartisans", "{} (entry {}) has no `npc_vendor` rows; \"I "
                      "would like to browse your goods.\" would open an empty shop.", name, entry);

        Trainer::Trainer const* trainer = sObjectMgr->GetTrainer(entry);
        if (!trainer)
        {
            LOG_ERROR("module.bookofartisans", "{} (entry {}) has no `creature_default_trainer` row; "
                      "right-clicking it would answer nothing.", name, entry);
            return;
        }

        LOG_INFO("module.bookofartisans", "{} (entry {}) ready: display {} x{}, npcflag 0x{:X}, "
                 "trainer {} with {} spells, {} items on the shelves.", name, entry,
                 proto->Models.front().CreatureDisplayID, proto->Models.front().DisplayScale,
                 proto->npcflag, AsUnderlyingType(trainer->GetTrainerType()),
                 trainer->GetSpells().size(), shelves ? shelves->GetItemCount() : 0);
    }
};

void AddSC_book_of_artisans()
{
    new BookOfArtisansScript();
    new BookOfArtisansServerScript();
    new BookOfArtisansWorldScript();
}
