/*
 * Spellbook: the Books of Ascension as a real class trainer.
 *
 * Right-clicking a book opens the ordinary trainer window - the one with known, available
 * and unavailable rows and a Train button - and the list is built for whoever opened it, so
 * a book someone else put down trains your class, not theirs.
 *
 * Two things here are deliberate:
 *
 *  * The list is sent by hand instead of through Trainer::SendSpells. The core's version
 *    filters every row through Player::IsSpellFitByClassAndRace, which asks
 *    SkillRaceClassInfo.dbc about the spell's skill line, and that table has no rows for
 *    Ascension's classes (ids 12 and up). Every custom spell is therefore filtered out and
 *    the window arrives empty, which is indistinguishable client side from a book that does
 *    nothing.
 *
 *  * Purchases are answered here too. The core resolves trainers per creature entry
 *    (sObjectMgr->GetTrainer(npc->GetEntry())), which cannot serve a list that depends on who
 *    is looking, and Trainer::TeachSpell runs the same class/race filter that would refuse
 *    every one of these spells. Because the row set is the server's, a purchase re-publishes
 *    it: the rank just bought turns "used" and the rank above it turns trainable, in the same
 *    window. The re-sent window carries the same rows in the same order as the one on screen -
 *    a held rank stays in the list rather than leaving it - so the client's own restore of its
 *    selection and scroll position lands on the row the player was on and nothing moves.
 *
 *    A purchase is also announced exactly once, by the core: an ability the character did not
 *    have arrives as SMSG_LEARNED_SPELL, and a rank up as SMSG_SUPERCEDED_SPELL, which the
 *    client announces itself. The window sends no learned-spell packet of its own, or a rank
 *    up would show its line twice.
 *
 * The list itself is what automatic progression would have granted: class progression spells,
 * rank upgrades gated on their first rank, and the automatic talent entries. No ability is
 * invented here, so the book can never offer something the realm would not have given.
 */

#include "Chat.h"
#include "Configuration/Config.h"
#include "Creature.h"
#include "GossipDef.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "SpellMgr.h"
#include "WorldSession.h"

#include <algorithm>
#include <iterator>
#include <map>
#include <string>
#include <utility>
#include <vector>

// The progression tables this module serves live with the compat layer that generated them.
// They are plain generated data headers, so they are read rather than copied.
#include "AscensionCoATalentData.h"
#include "AscensionCustomClassData.h"
#include "AscensionFelsworn.h"
#include "AscensionGuardianCompletion.h"
#include "AscensionPyromancerData.h"
#include "AscensionSpellProgressionData.h"
#include "AscensionTalentReplacementData.h"
#include "SpellbookCostData.h"
#include "SpellbookOfferData.h"
#include "SpellbookRankData.h"
#include "SpellbookTrainerData.h"
#include "SpellbookTreeSpellData.h"
#include "spellbook_api.h"
#include "spellbook_notify.h"

namespace
{
    /// The script the book templates carry. Kept in one place so the SQL that installs a book
    /// and the code that serves it cannot drift apart silently.
    constexpr char const *BOOK_SCRIPT = "npc_spellbook_trainer";
    constexpr char const *ENABLE_KEY = "Spellbook.Enable";
    constexpr char const *NOTIFY_ON_READY_KEY = "Spellbook.Notify.OnClientReady";
    constexpr char const *COST_ENABLE_KEY = "Spellbook.Cost.Enable";
    constexpr char const *COST_MULTIPLIER_KEY = "Spellbook.Cost.Multiplier";

    /// The client telling the server its extension module has registered its handlers,
    /// which is the first moment the announcement push can be answered at all. The compat
    /// layer answers the same message for the advancement handshake.
    constexpr uint16 CMSG_EXTENSION_INITIALIZED = 0x0561;
    constexpr char const *GREETING = "Hello! Ready for some training?";

    constexpr uint32 BEGINNERS_BOOK = 75118;
    constexpr uint32 BEGINNERS_TEXT = 22;
    constexpr uint32 BOOK_TEXT = 19108;

    /// The client reads the active row state from this byte. A known spell is never sent -
    /// the window drops it - so only the first two are ever written.
    enum class RowState : uint8
    {
        Available = 0,
        Unavailable = 1,
        Known = 2
    };

    enum class BuyResult : uint32
    {
        Unavailable = 0,
        NotEnoughMoney = 1,
        NotEnoughSkill = 2
    };

    struct Row
    {
        uint32 SpellId = 0;
        uint8 RequiredLevel = 0;
        uint32 RequiredAbility = 0;
        uint32 SkillLine = 0;
        uint32 Cost = 0;   // copper, before the multiplier and the reputation discount
        RowState State = RowState::Unavailable;
    };

    bool Enabled()
    {
        return sConfigMgr->GetOption<bool>(ENABLE_KEY, true);
    }

    bool Charging()
    {
        return sConfigMgr->GetOption<bool>(COST_ENABLE_KEY, true);
    }

    /// Copper this row costs this viewer: the band price for the level the window gates the row
    /// at, times the configured multiplier, times the viewer's reputation discount with the
    /// book. Trainer::SendSpells and Trainer::TeachSpell apply the same two steps, so the price
    /// the window shows and the price the Train button charges cannot drift apart.
    int32 RowPrice(Player *player, Creature *book, Row const &row)
    {
        if (!Charging() || !row.Cost)
            return 0;

        float price = float(row.Cost) * sConfigMgr->GetOption<float>(COST_MULTIPLIER_KEY, 1.0f);
        if (book)
            price *= player->GetReputationPriceDiscount(book);

        return int32(price);
    }

    bool IsBook(Creature const *creature)
    {
        return creature && creature->GetScriptName() == BOOK_SCRIPT;
    }

    /// The skill line a spell is filed under, which is what the client groups the window by.
    /// It is a label only: nothing here gates on skill values, because these spells are not
    /// in the DBC tables the core's skill checks consult.
    uint32 SkillLineForSpell(uint32 spellId)
    {
        auto const bounds = sSpellMgr->GetSkillLineAbilityMapBounds(spellId);
        for (auto itr = bounds.first; itr != bounds.second; ++itr)
            if (itr->second->SkillLine)
                return itr->second->SkillLine;

        return 0;
    }

    /// The specialisation the character is currently in, read straight from the setting the
    /// Character Advancement storage writes, so this module needs nothing from the compat
    /// layer.
    uint32 ActiveSpec(Player *player)
    {
        if (!player)
            return 0;

        return player->GetPlayerSetting("core.ascension_active_spec", 0).value;
    }

    /// Whether the character has this ability or a higher rank of the same chain. A rank below
    /// the highest the character holds is not an upgrade and cannot be granted: Player::addSpell
    /// marks it inactive and returns without announcing anything, so the window must show it as
    /// known rather than offer a purchase that does nothing.
    bool HasRankOrBetter(Player *player, uint32 spellId)
    {
        if (player->HasSpell(spellId))
            return true;

        SpellInfo const *info = sSpellMgr->GetSpellInfo(spellId);
        if (!info || !info->IsRanked())
            return false;

        for (SpellInfo const *rank = sSpellMgr->GetSpellInfo(sSpellMgr->GetFirstSpellInChain(spellId));
             rank; rank = rank->GetNextRankSpell())
            if (rank->GetRank() >= info->GetRank() && player->HasSpell(rank->Id))
                return true;

        return false;
    }

    /// Whether the client's talent trees grant this spell. A node's spell enters the
    /// character through the tree: its one rank by spending that node, or by reaching the
    /// level of an automatic node. So the window must not sell it - and since the node data
    /// lists only that entry rank, the upgrades above it stay in the window. See
    /// SpellbookTreeSpellData.h, which the generator derives from the client's own tree data.
    bool IsTreeSpell(uint32 classId, uint32 spellId)
    {
        auto const &table = SpellbookTreeSpellData::TreeSpells;
        std::pair<uint32, uint32> const key(classId, spellId);
        auto const itr = std::lower_bound(table.begin(), table.end(), key,
            [](SpellbookTreeSpellData::TreeSpell const &row, std::pair<uint32, uint32> const &wanted)
            {
                return row.ClassId < wanted.first ||
                       (row.ClassId == wanted.first && row.SpellId < wanted.second);
            });

        return itr != table.end() && itr->ClassId == classId && itr->SpellId == spellId;
    }

    /// Whether Explode is currently replaced by Echo of Nozdormu for this character, in
    /// which case the book lists no Explode rank at all: the conversion already covers the
    /// whole chain on the action bars, so offering its ranks would only re-announce a spell
    /// the character no longer casts. Keyed on the aura AscensionPyromancer::Refresh itself
    /// uses, so the window and the conversion cannot disagree.
    bool ReplacedByEchoOfNozdormu(Player* player, uint32 spellId)
    {
        return player && player->getClass() == CLASS_PYROMANCER && player->HasAura(520937) &&
            sSpellMgr->GetFirstSpellInChain(spellId) == 800792;
    }

    bool CanLearnTalentReplacement(Player* player, uint32 spellId)
    {
        if (player->getClass() == CLASS_PYROMANCER &&
            std::find(std::begin(PyromancerEchoRanks), std::end(PyromancerEchoRanks), spellId) !=
                std::end(PyromancerEchoRanks))
            return ActiveSpec(player) == 39 && player->HasSpell(520937);

        for (auto const& replacement : AscensionCompatData::TalentReplacements)
            if (replacement.ClassId == player->getClass() &&
                std::any_of(replacement.Ranks.begin(), replacement.Ranks.end(),
                    [spellId](auto const& rank) { return rank.SpellId == spellId; }))
                return replacement.SpecId == ActiveSpec(player) && player->HasSpell(replacement.ParentSpellId);

        return true;
    }

    /// The row set behind both the window and the announcement push.
    ///
    /// The window view is what the player is shown, and it is the only view that gets
    /// narrowed: a spell the talent trees grant is left out, and so is anything the character
    /// already holds, so every row on screen is a row the Train button can grant. The
    /// announcement push asks for the union instead - every spell this class can ever be
    /// handed, tree content and already-held ranks included - because its job is to tell the
    /// client which abilities deserve a "New Spell Learned" alert wherever they came from.
    std::vector<Row> BuildRows(Player *player, bool windowView = true)
    {
        std::vector<Row> rows;
        if (!player)
            return rows;

        uint8 const classId = uint8(player->getClass());
        uint32 const spec = ActiveSpec(player);

        auto add = [&rows, classId, windowView, player, spec](uint32 spellId, uint8 requiredLevel,
                                                uint32 requiredAbility)
        {
            if (!spellId || !sSpellMgr->GetSpellInfo(spellId))
                return;
            if (!AscensionFelsworn::CanLearnRift(player, spellId))
                return;
            if (windowView && classId == CLASS_FLESHWARDEN && player->HasAura(301302) &&
                sSpellMgr->GetFirstSpellInChain(spellId) == 801016)
                return;
            if (windowView && classId == CLASS_GUARDIAN && AscensionGuardian::Ballad(spellId) &&
                (spec != 20 || !player->HasAura(505344)))
                return;

            // A spell the talent trees grant is the tree's to hand out, whatever source
            // below would otherwise reach it through.
            if (windowView && IsTreeSpell(classId, spellId))
                return;

            // Explode while Echo of Nozdormu replaces it: neither its known ranks nor its
            // upgrades are listed, so the window cannot sell back a spell the conversion
            // just took off the bars.
            if (windowView && ReplacedByEchoOfNozdormu(player, spellId))
                return;

            if (windowView && !CanLearnTalentReplacement(player, spellId))
                return;

            for (Row const &known : rows)
                if (known.SpellId == spellId)
                    return;

            Row row;
            row.SpellId = spellId;
            row.RequiredLevel = requiredLevel;
            row.RequiredAbility = requiredAbility;
            row.SkillLine = SkillLineForSpell(spellId);

            // Priced at the level the window gates the row at. A source that carries no level
            // for the spell falls back to Spell.dbc's BaseLevel, the same fallback the rank
            // chains above use, so a row is never free because one source left its level blank.
            uint8 const pricedLevel = requiredLevel ? requiredLevel
                : uint8(std::min<uint32>(sSpellMgr->AssertSpellInfo(spellId)->BaseLevel, 255));
            row.Cost = SpellbookCostData::Price(pricedLevel, spellId);

            rows.push_back(row);
        };

        for (auto const &entry : AscensionCompatData::ClassSpells)
            if (entry.ClassId == classId)
                add(entry.SpellId, entry.RequiredLevel, 0);

        // Each ladder's ranks, in the order the data gives them, so every row can require the
        // rank directly under it. That is the requirement the original trainer window published
        // - the captured offer list carries "Witchblight (Rank 2)" on the rank-3 row - and the
        // one the client checks against the character. Pointing every rank at the ladder's first
        // rank instead reads fine on the bare state byte, but breaks on screen: the character's
        // first rank is superseded as soon as the second is bought, so the client greys every row
        // above it for a requirement the character no longer holds.
        std::map<uint32, std::vector<std::pair<uint8, uint32>>> ladders;   // root -> (level, spell)
        for (auto const &entry : AscensionProgression::Ranks)
        {
            if (entry.ClassId != classId)
                continue;

            auto &members = ladders[entry.FirstSpellId];
            if (members.empty())
                if (SpellInfo const *first = sSpellMgr->GetSpellInfo(entry.FirstSpellId))
                    members.emplace_back(uint8(std::min<uint32>(first->BaseLevel, 255)),
                                         entry.FirstSpellId);

            members.emplace_back(entry.RequiredLevel, entry.SpellId);
        }

        // The rank under \p spellId in its ladder, at the level its row is gated at. A ladder
        // this window knows nothing about falls back to the root, and the root needs no rank
        // under it.
        auto rankBelow = [&ladders](uint32 root, uint8 level, uint32 spellId) -> uint32
        {
            auto const found = ladders.find(root);
            if (found != ladders.end())
            {
                uint32 below = 0;
                for (auto const &member : found->second)
                    if (member.second != spellId && member.first < level)
                        below = member.second;

                if (below)
                    return below;
            }

            return spellId != root ? root : 0;
        };

        // The first rank is offered as well: it is the class's base ability, and for 199 of
        // them the generated class data carries no level at all, so without this the window
        // hides whole abilities. Spell.dbc's BaseLevel is where those levels come from - it
        // matches the level the generated data records for 236 of the 242 first ranks it does
        // have, and both first ranks the captured original trainer window was seen selling
        // (Chronomancer's Nozdormu's Wisdom, Pyromancer's Seal of Alysrazor) are level 1 in the
        // capture and BaseLevel 1 in the client data.
        for (auto const &entry : AscensionProgression::Ranks)
        {
            if (entry.ClassId != classId)
                continue;

            if (SpellInfo const *first = sSpellMgr->GetSpellInfo(entry.FirstSpellId))
                if (first->BaseLevel >= 1 && first->BaseLevel <= MAX_LEVEL)
                    add(entry.FirstSpellId, uint8(first->BaseLevel), 0);

            add(entry.SpellId, entry.RequiredLevel,
                rankBelow(entry.FirstSpellId, entry.RequiredLevel, entry.SpellId));
        }

        for (auto const &entry : AscensionCompatData::CoATalentEntries)
            if (entry.ClassId == classId && !entry.AECost && !entry.TECost &&
                (!entry.SpecId || !spec || entry.SpecId == spec))
                for (uint32 spellId : entry.SpellIds)
                    add(spellId, entry.RequiredLevel, 0);

        // Services the original trainer window sold but this realm's generated class data
        // never resolved to a level. Without them the window is missing whole rank chains for
        // some classes: Stormbringer's Torrential Wrath and Brine, the Guardian Ballads,
        // Pyromancer's Echo of Nozdormu, the Ranger's Bushcraft kit. See SpellbookOfferData.h.
        for (SpellbookOfferData::Offer const &offer : SpellbookOfferData::Offers)
            if (offer.ClassId == classId)
                add(offer.SpellId, offer.RequiredLevel,
                    rankBelow(offer.FirstSpellId, offer.RequiredLevel, offer.SpellId));

        // Class trainer rows the realm's own NPCTrainer.dbc teaches under this class's tab
        // name, that no other source sells: the top ranks of ladders the captured window only
        // showed part of (Devotion of Grace rank 8, Chromie's Wisdom 5, the Ranger's Bushcraft
        // tiers, the Venomancer's fourth form). See SpellbookTrainerData.h.
        for (SpellbookTrainerData::Offer const &offer : SpellbookTrainerData::Offers)
            if (offer.ClassId == classId)
                add(offer.SpellId, offer.RequiredLevel,
                    rankBelow(offer.FirstSpellId, offer.RequiredLevel, offer.SpellId));

        // Upgrades of abilities this window already sells that the realm's generated
        // progression data never resolved - the client's own rank ladders carry them, and
        // without them the last ranks of those abilities were unreachable from any book.
        // See SpellbookRankData.h. The requirement is the highest rank this window offers
        // below them, so an upgrade still needs the rank under it.
        for (SpellbookRankData::Rank const &rank : SpellbookRankData::Ranks)
            if (rank.ClassId == classId)
                add(rank.SpellId, rank.RequiredLevel, rank.RequiredSpellId);

        // The ladder the rows themselves carry: a row requires the rank under it, so the row
        // that requires this one is the rank above it. A rank the character already holds above
        // this one is not a purchase the window can sell - Player::addSpell only moves it into
        // the active spec and announces nothing for it, while the rank it pulls in is announced
        // instead, which showed the player a chat line for a rank they did not buy. The core's
        // chain check cannot see a ladder it has no chain rows for, so the rows' own links
        // answer as well.
        std::map<uint32, uint32> rankAbove;
        for (Row const &row : rows)
            if (row.RequiredAbility && !rankAbove.count(row.RequiredAbility))
                rankAbove[row.RequiredAbility] = row.SpellId;

        auto holdsRankAbove = [player, &rankAbove](uint32 spellId)
        {
            uint32 higher = spellId;
            for (std::size_t hops = 0; hops < 16; ++hops)
            {
                auto const found = rankAbove.find(higher);
                if (found == rankAbove.end())
                    return false;

                higher = found->second;
                if (player->HasSpell(higher))
                    return true;
            }

            return false;
        };

        std::vector<Row> view;
        view.reserve(rows.size());
        for (Row &row : rows)
        {
            // Already held, in this rank or a higher one: the book has nothing left to teach
            // here, and the row stays in the list as the trainer window's "used" row - the way
            // a stock trainer greys the row it just sold. Dropping it instead would renumber
            // every row below it on each purchase, and a client restores its selection and its
            // scroll position by row number, so the list would move under the player.
            if (HasRankOrBetter(player, row.SpellId) || holdsRankAbove(row.SpellId))
                row.State = RowState::Known;
            // A rank whose prerequisite is missing, or whose level is above the character, is
            // unavailable - exactly as the original window showed it - and the requirement the
            // row carries is what the client draws under it. A purchase re-sends the window so
            // the row it unlocked turns available; see HandlePurchase.
            else if (player->GetLevel() < row.RequiredLevel ||
                     (row.RequiredAbility && !player->HasSpell(row.RequiredAbility)))
                row.State = RowState::Unavailable;
            else
                row.State = RowState::Available;

            view.push_back(row);
        }

        return view;
    }

    /// Tells the client every spell this player's book can offer is worth announcing, so an
    /// ability the realm grants outside the window - automatic progression on a level up -
    /// is announced too. Every push rebuilds the client's spell index once per row, which is
    /// why this is opt-in: a window is a few hundred rows.
    void PushWindowTags(Player *player)
    {
        if (!player || !SpellbookNotify::Enabled() ||
            !sConfigMgr->GetOption<bool>(NOTIFY_ON_READY_KEY, false))
            return;

        std::vector<uint32> spellIds;
        for (Row const &row : BuildRows(player, false))
            spellIds.push_back(row.SpellId);

        // The window no longer sells what a talent tree grants, so a pick in the tree is the
        // only way those spells arrive and it is the pick that has to raise the alert. They are
        // not rows, so they are read straight from the tree table - the classes' own spells,
        // sorted, which is a contiguous run.
        auto const &tree = SpellbookTreeSpellData::TreeSpells;
        auto const first = std::lower_bound(tree.begin(), tree.end(), uint32(player->getClass()),
            [](SpellbookTreeSpellData::TreeSpell const &entry, uint32 classId)
            {
                return entry.ClassId < classId;
            });
        for (auto itr = first; itr != tree.end() && itr->ClassId == player->getClass(); ++itr)
            spellIds.push_back(itr->SpellId);

        SpellbookNotify::Push(player, spellIds);
        LOG_INFO("module.spellbook", "Announced {} spell(s) to {} (class {}) on client ready",
                 spellIds.size(), player->GetName(), uint32(player->getClass()));
    }

    /// The trainer window, written to match WorldPackets::NPC::TrainerList::Write exactly:
    /// guid, type, count, then one block per row, then the greeting.
    void SendTrainerWindow(Player *player, Creature *book, std::vector<Row> const &rows)
    {
        WorldPacket data(SMSG_TRAINER_LIST);
        data << book->GetGUID();
        data << int32(0);  // Trainer::Type::Class
        data << int32(rows.size());

        for (Row const &row : rows)
        {
            data << int32(row.SpellId);
            data << uint8(row.State);
            data << int32(RowPrice(player, book, row));
            data << uint32(0) << uint32(0);  // talent point costs
            data << uint8(row.RequiredLevel);
            data << int32(row.SkillLine);
            data << int32(0);                // no skill value requirement, see above
            data << uint32(row.RequiredAbility) << uint32(0) << uint32(0);
        }

        data << std::string(GREETING);
        player->SendDirectMessage(&data);
    }

    uint32 BookGossipText(Creature const *book)
    {
        return (book && book->GetEntry() == BEGINNERS_BOOK) ? BEGINNERS_TEXT : BOOK_TEXT;
    }

    /// Opens the window for \p player on \p book. False when there is nothing to show, so the
    /// caller can still offer the bulk alternative rather than leaving the book inert.
    bool OpenTrainer(Player *player, Creature *book)
    {
        if (!player || !book)
            return false;

        std::vector<Row> const rows = BuildRows(player);
        if (rows.empty())
            return false;

        SendTrainerWindow(player, book, rows);
        LOG_INFO("module.spellbook", "Sent {} trainer row(s) for {} (class {}) on book {}",
                 rows.size(), player->GetName(), uint32(player->getClass()), book->GetEntry());
        return true;
    }

    /// Learns everything the window currently offers as available. This is the book's
    /// "catch me up" action, so a character who fell behind does not have to click through
    /// eighty rows after a fix or a level cap change.
    uint32 LearnEverythingAvailable(Player *player, Creature *book)
    {
        uint32 learned = 0;
        for (Row const &row : BuildRows(player))
        {
            if (row.State != RowState::Available)
                continue;

            // Per ability, in front of its own learn, so every one of them arrives announced
            // exactly as a single purchase does.
            SpellbookNotify::Push(player, row.SpellId);

            player->learnSpell(row.SpellId, false);
            if (player->HasSpell(row.SpellId))
                sScriptMgr->OnPlayerLearnTrainerSpell(player, book, row.SpellId);
            ++learned;
        }

        return learned;
    }

    /// Whether Player::addSpell will announce this ability as superseding an active lower rank
    /// rather than as newly learned. Mirrors the condition in Player::addSpell: the superseded
    /// path is only taken for a ranked ability that is not stackable with its ranks, and only
    /// when a lower rank is currently active.
    bool SupersedesActiveRank(Player *player, uint32 spellId)
    {
        SpellInfo const *info = sSpellMgr->GetSpellInfo(spellId);
        if (!info || info->IsStackableWithRanks() || !info->IsRanked())
            return false;

        for (SpellInfo const *rank = sSpellMgr->GetSpellInfo(sSpellMgr->GetFirstSpellInChain(spellId));
             rank; rank = rank->GetNextRankSpell())
            if (rank->GetRank() < info->GetRank() && player->HasActiveSpell(rank->Id))
                return true;

        return false;
    }

    /// A purchase from the window. Returns true when the packet belonged to a book, whether
    /// or not the ability was granted.
    bool HandlePurchase(Player *player, WorldPacket const &packet)
    {
        if (!player || !IsAscensionClass(player->getClass()))
            return false;

        // A packed guid followed by the spell id; read a copy so the dispatcher's buffer is
        // left alone.
        WorldPacket copy(packet);
        ObjectGuid guid;
        int32 spellId = 0;
        copy >> guid >> spellId;
        if (!guid || spellId <= 0)
            return false;

        Creature *book = player->GetNPCIfCanInteractWith(guid, 0);
        if (!IsBook(book))
            return false;

        uint32 const wanted = uint32(spellId);
        std::vector<Row> const rows = BuildRows(player);
        auto const found = std::find_if(rows.begin(), rows.end(),
            [wanted](Row const &row) { return row.SpellId == wanted; });

        // Only what this player was shown can be bought, so the window is the only way in.
        // A row the window does not hold is a spell the tree grants, which never was the book's;
        // a row it holds as "used" is one the character already has. Both are answered, so the
        // client is never left waiting on a purchase nothing will handle.
        if (found == rows.end())
        {
            if (!AscensionFelsworn::CanLearnRift(player, wanted) ||
                !CanLearnTalentReplacement(player, wanted) ||
                ReplacedByEchoOfNozdormu(player, wanted) ||
                IsTreeSpell(uint32(player->getClass()), wanted) ||
                HasRankOrBetter(player, wanted) ||
                (player->getClass() == CLASS_GUARDIAN && AscensionGuardian::Ballad(wanted)))
            {
                WorldPacket failed(SMSG_TRAINER_BUY_FAILED);
                failed << book->GetGUID() << uint32(wanted)
                       << uint32(AsUnderlyingType(BuyResult::Unavailable));
                player->SendDirectMessage(&failed);
                return true;
            }

            return false;
        }

        if (found->State != RowState::Available)
        {
            WorldPacket failed(SMSG_TRAINER_BUY_FAILED);
            failed << book->GetGUID() << uint32(wanted)
                   << uint32(AsUnderlyingType(BuyResult::NotEnoughSkill));
            player->SendDirectMessage(&failed);
            LOG_INFO("module.spellbook", "{} was refused {} from book {}: state {}, requires {}",
                     player->GetName(), wanted, book->GetEntry(), AsUnderlyingType(found->State),
                     found->RequiredAbility ? std::to_string(found->RequiredAbility) : "nothing");
            return true;
        }

        // Charged before the learn, like Trainer::TeachSpell, and refused the way a trainer
        // refuses: an empty purse answers with the failure the client shows as "Not enough
        // money" instead of learning the spell for free.
        int32 const price = RowPrice(player, book, *found);
        if (price > 0 && !player->HasEnoughMoney(price))
        {
            WorldPacket failed(SMSG_TRAINER_BUY_FAILED);
            failed << book->GetGUID() << uint32(wanted)
                   << uint32(AsUnderlyingType(BuyResult::NotEnoughMoney));
            player->SendDirectMessage(&failed);
            LOG_INFO("module.spellbook", "{} could not afford {} ({} copper) from book {}",
                     player->GetName(), wanted, price, book->GetEntry());
            return true;
        }

        if (price > 0)
            player->ModifyMoney(-price);

        // Sampled before the learn: the core deactivates the lower rank while learning, so
        // afterwards there is nothing left to observe.
        bool const supersedes = SupersedesActiveRank(player, wanted);

        // In front of the learn, so the client's answer to "is this worth announcing" is
        // already in place when the learned-spell packet arrives behind it.
        SpellbookNotify::Push(player, wanted);

        // Nothing is announced from here. The core sends SMSG_LEARNED_SPELL for a grant that did
        // not supersede anything, and answers an upgrade with SMSG_SUPERCEDED_SPELL, which the
        // client announces itself. Adding a learned-spell packet on top of that cue announced
        // every rank-up twice.
        player->learnSpell(wanted, false);

        WorldPacket succeeded(SMSG_TRAINER_BUY_SUCCEEDED);
        succeeded << book->GetGUID() << uint32(wanted);
        player->SendDirectMessage(&succeeded);
        if (player->HasSpell(wanted))
            sScriptMgr->OnPlayerLearnTrainerSpell(player, book, wanted);

        // The row set belongs to the server, so the window on screen is stale the moment this is
        // learned: the rank just bought has to turn "used" and the rank above it has to turn
        // trainable. The re-sent window holds the same rows in the same order as the one on
        // screen, so the client's own restore of the row it had selected lands on that row again
        // and the list does not move under the player.
        SendTrainerWindow(player, book, BuildRows(player));

        // The one line that says which of the two announcements the client got: an upgrade is
        // answered with SMSG_SUPERCEDED_SPELL, which the client announces on its own, and an
        // ability the core added is announced with SMSG_LEARNED_SPELL by the core. A purchase
        // the core refused outright is learned by nobody and must announce nothing.
        LOG_INFO("module.spellbook", "{} trained {} from book {} (class {}) for {} copper: {}",
                 player->GetName(), wanted, book->GetEntry(), uint32(player->getClass()), price,
                 !player->HasSpell(wanted) ? "nothing learned"
                     : (supersedes ? "superseded the rank below, which the client announces"
                                   : "announced by the core"));
        return true;
    }

    /// The other way a client can ask: some clients request the trainer list for a unit
    /// directly instead of opening its gossip, so the same window answers that too. Without
    /// this, a book flagged as a trainer could answer nothing at all.
    bool HandleTrainerListRequest(Player *player, WorldPacket const &packet)
    {
        if (!player || !IsAscensionClass(player->getClass()))
            return false;

        WorldPacket copy(packet);
        ObjectGuid guid;
        copy >> guid;
        if (!guid)
            return false;

        Creature *book = player->GetNPCIfCanInteractWith(guid, 0);
        if (!IsBook(book))
            return false;

        return OpenTrainer(player, book);
    }

    class SpellbookBookScript : public CreatureScript
    {
    public:
        SpellbookBookScript() : CreatureScript(BOOK_SCRIPT) { }

        bool OnGossipHello(Player *player, Creature *book) override
        {
            ClearGossipMenuFor(player);
            if (!Enabled())
                return true;

            // Any other class trains at the book what its realm's class trainers teach it.
            if (!IsAscensionClass(player->getClass()))
            {
                player->GetSession()->SendTrainerList(book);
                return true;
            }

            // Right-clicking a book is a request for the trainer window: no gossip page in
            // between, which is how the books behaved on the live realm.
            if (OpenTrainer(player, book))
                return true;

            AddGossipItemFor(player, GOSSIP_ICON_TRAINER, "Learn everything I am eligible for.",
                             GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF);
            SendGossipMenuFor(player, BookGossipText(book), book->GetGUID());
            return true;
        }

        bool OnGossipSelect(Player *player, Creature *book, uint32 sender, uint32 action) override
        {
            ClearGossipMenuFor(player);
            CloseGossipMenuFor(player);
            if (sender != GOSSIP_SENDER_MAIN || action != GOSSIP_ACTION_INFO_DEF ||
                !Enabled() || !IsAscensionClass(player->getClass()))
                return true;

            uint32 const learned = LearnEverythingAvailable(player, book);
            if (learned)
            {
                ChatHandler(player->GetSession())
                    .PSendSysMessage("The book taught you {} ability or rank(s).", learned);
                LOG_INFO("module.spellbook", "{} learned {} ability or rank(s) from book {}",
                         player->GetName(), learned, book->GetEntry());
            }
            else
                ChatHandler(player->GetSession())
                    .SendSysMessage("You already know everything this book can teach you.");

            return true;
        }
    };

    /// Consumes the purchase before the core's handler sees it: sObjectMgr has no trainer for
    /// these entries, so nothing else can serve the request.
    class SpellbookServerScript : public ServerScript
    {
    public:
        SpellbookServerScript()
            : ServerScript("SpellbookServerScript", {SERVERHOOK_CAN_PACKET_RECEIVE})
        {
        }

        [[nodiscard]] bool CanPacketReceive(WorldSession *session,
                                            WorldPacket const &packet) override
        {
            if (!session || !session->GetPlayer() || !Enabled())
                return true;

            uint16 const opcode = packet.GetOpcode();
            if (opcode == CMSG_TRAINER_BUY_SPELL)
                return !HandlePurchase(session->GetPlayer(), packet);

            if (opcode == CMSG_TRAINER_LIST)
                return !HandleTrainerListRequest(session->GetPlayer(), packet);

            if (opcode == CMSG_EXTENSION_INITIALIZED)
                PushWindowTags(session->GetPlayer());

            return true;
        }
    };
}

/// SMSG_SUPERCEDED_SPELL is how a temporary spell replacement swaps the client's bars, and the client
/// announces the spell it swaps in as "learned" when that spell is notable. A talent's variant (Spirit
/// Volley, Falconstrike) carries no notable bit, but the book spell it hands back when it ends
/// (Reclamation, Quick Shot) does, so every revert drew the "New Spell Learned" toast. The spell is
/// muted for exactly that one notice and made notable again right after it.
class spellbook_swap_notice final : public PlayerScript
{
public:
    spellbook_swap_notice() : PlayerScript("spellbook_swap_notice",
                                           {PLAYERHOOK_ON_TEMPORARY_SPELL_REPLACEMENT_NOTICE}) { }

    void OnPlayerTemporarySpellReplacementNotice(Player *player, uint32 /*previous*/, uint32 replacement,
                                                 bool sent) override
    {
        if (sent)
            SpellbookNotify::Push(player, replacement);
        else
            SpellbookNotify::Mute(player, replacement);
    }
};

/// A temporary spell (Remote Detonation while a mine is out, the Guardian's stomp, a talent's variant) is learned
/// and dropped again with its owner, and every SMSG_LEARNED_SPELL printed "You have learned a new spell", could draw
/// the "New Spell Learned" toast and, up to level 10, placed the spell on another empty button. Its row is sent quiet
/// for exactly that packet and put back right after.
class spellbook_temporary_learn_notice final : public PlayerScript
{
public:
    spellbook_temporary_learn_notice() : PlayerScript("spellbook_temporary_learn_notice",
                                                      {PLAYERHOOK_ON_TEMPORARY_SPELL_LEARN_NOTICE}) { }

    void OnPlayerTemporarySpellLearnNotice(Player *player, uint32 spellId, bool sent) override
    {
        if (sent)
            SpellbookNotify::Unquiet(player, spellId);
        else
            SpellbookNotify::Quiet(player, spellId);
    }
};

class spellbook_notify_config final : public WorldScript
{
public:
    spellbook_notify_config() : WorldScript("spellbook_notify_config", {WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        SpellbookNotify::LoadConfig();
    }
};

class spellbook_metric_provider final : public WorldScript
{
public:
    spellbook_metric_provider() : WorldScript("spellbook_metric_provider")
    {
        CoASpellbook::SetProvider({Spellbook::RowCount, Spellbook::OffersSpell, Spellbook::CoversSpell,
            Spellbook::UpgradeRanksAbove});
    }

    ~spellbook_metric_provider() override
    {
        CoASpellbook::SetProvider({});
    }
};

void AddSpellbookScripts()
{
    new spellbook_notify_config();
    new spellbook_metric_provider();
    new spellbook_swap_notice();
    new spellbook_temporary_learn_notice();
    new SpellbookBookScript();
    new SpellbookServerScript();
}

// The window this module would build for a player, for callers outside this file. The
// gameplay test driver asserts on it, and it is defined next to the builder so the two
// cannot drift apart.
namespace Spellbook
{
    uint32 RowCount(Player *player)
    {
        return uint32(BuildRows(player).size());
    }

    bool OffersSpell(Player *player, uint32 spellId)
    {
        for (Row const &row : BuildRows(player))
            if (row.SpellId == spellId)
                return true;

        return false;
    }

    bool CoversSpell(Player *player, uint32 spellId)
    {
        if (!player)
            return false;

        // The window drops what the character already holds, so membership alone would report
        // a bought spell as missing. Entitlement is the union of the two.
        return OffersSpell(player, spellId) || HasRankOrBetter(player, spellId);
    }

    std::vector<uint32> UpgradeRanksAbove(Player *player, uint8 level)
    {
        std::vector<uint32> spells;
        if (!player)
            return spells;

        for (SpellbookOfferData::Offer const &offer : SpellbookOfferData::Offers)
            if (offer.ClassId == player->getClass() && offer.FirstSpellId && offer.RequiredLevel > level)
                spells.push_back(offer.SpellId);

        for (SpellbookRankData::Rank const &rank : SpellbookRankData::Ranks)
            if (rank.ClassId == player->getClass() && rank.RequiredLevel > level)
                spells.push_back(rank.SpellId);

        return spells;
    }
}
