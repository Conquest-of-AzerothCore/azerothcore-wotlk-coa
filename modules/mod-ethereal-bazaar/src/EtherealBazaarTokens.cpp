/*
 * Where Bazaar Tokens come from.
 *
 * The shop is only half the economy. Ascension sold tokens for real money and
 * let players buy them off the auction house; with the shop gone, the only way
 * left is to play. The rule the server owner asked for: a little from
 * everything, more from harder content.
 *
 *   quest turned in     0 to 6
 *   creature killed     0 to 2
 *   dungeon boss        6 to 12
 *   raid boss          30 to 40
 *
 * A percentage from BonusLevel on can multiply every amount; by default it
 * is 100, so there is no bonus.
 *
 * The zero in the lower two ranges is deliberate: most kills and some quests
 * give nothing at all, so tokens stay something one notices.
 *
 * A kill pays everyone the native kill credit rewards: whoever tapped the
 * creature, and every member of a tapping group in reward range, whether they
 * attacked, healed or watched. Each member rolls their own amount.
 *
 * A kill far below the player's own level pays nothing, so outlevelled mobs
 * are not a token farm. Each member is judged on their own level; see KillPays.
 *
 * A player outside a group is paid only for a creature they hit themselves,
 * like loot and experience, so pets left to fight alone cannot farm tokens
 * while the owner is away.
 *
 * Repeated open-world kills of the same creature entry pay less each time: a
 * per-player, per-entry "heat" rises by one on every ordinary creature kill
 * and recovers over time at a rate tied to that creature's own respawn
 * delay, and the plain kill amount is multiplied by (FactorPercent/100)^heat
 * before it is rolled. A kill whose multiplier falls under CutoffPercent
 * pays nothing. Dungeon and raid bosses, and anything outside a world map,
 * are unaffected; see BazaarDegressionRules.h and ApplyDegression.
 */

#include "EtherealBazaar.h"

#include "BazaarDegressionRules.h"
#include "Chat.h"
#include "CoATestZoneBonus.h"
#include "Configuration/Config.h"
#include "Creature.h"
#include "DataMap.h"
#include "Formulas.h"
#include "GameTime.h"
#include "Group.h"
#include "KillRewarder.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QuestDef.h"
#include "Mail.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "StringConvert.h"
#include "World.h"

#include <algorithm>

namespace
{
    bool Enabled()
    {
        return sConfigMgr->GetOption<bool>("EtherealBazaar.Tokens.Enable", true);
    }

    uint32 Wuerfeln(char const* was, uint32 minVorgabe, uint32 maxVorgabe)
    {
        uint32 const lo = sConfigMgr->GetOption<uint32>(
            Acore::StringFormat("EtherealBazaar.Tokens.{}.Min", was), minVorgabe);
        uint32 const hi = sConfigMgr->GetOption<uint32>(
            Acore::StringFormat("EtherealBazaar.Tokens.{}.Max", was), maxVorgabe);
        return urand(lo, std::max(lo, hi));
    }

    // The setting is a number of levels, or "grey" for the XP rule: anything grey
    // to this player pays nothing. Creatures above the player always pay.
    //
    // A levelling character is judged on the level they are shown, so a world
    // scaled to them keeps paying. At maximum level the creature's own level
    // counts: scaling lifts every dungeon to about that level, which would let a
    // starting dungeon pay as much as the endgame.
    bool KillPays(Player* player, Creature const* killed)
    {
        uint32 const level = player->GetLevel();
        bool const atMaxLevel = level >= sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.MaxLevel", 60);
        std::string const setting = atMaxLevel
            ? sConfigMgr->GetOption<std::string>("EtherealBazaar.Tokens.MaxLevelsAboveMob.AtMaxLevel", "5")
            : sConfigMgr->GetOption<std::string>("EtherealBazaar.Tokens.MaxLevelsAboveMob.WhileLeveling", "grey");

        uint32 const killedLevel = atMaxLevel ? killed->GetLevel() : killed->getLevelForTarget(player);
        if (Optional<uint32> const levelsAbove = Acore::StringTo<uint32>(setting))
            return killedLevel + *levelsAbove >= level;

        return killedLevel > Acore::XP::GetGrayLevel(level);
    }

    // Loot and experience already require an ungrouped player to have hit the
    // creature; tokens follow the same rule.
    bool IsUnearnedSoloKill(Player* player, Creature const* killed)
    {
        return !player->GetGroup() && sWorld->getBoolConfig(CONFIG_SOLO_KILL_REQUIRES_PLAYER_HIT) &&
            !killed->WasAttackedDirectlyBy(player->GetGUID());
    }

    // The multiplier is a percentage so the config can hold a whole number.
    uint32 ApplyLevelBonus(Player* player, uint32 amount)
    {
        if (!amount)
            return 0;

        uint32 const abLevel = sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.BonusLevel", 60);
        if (player->GetLevel() < abLevel)
            return amount;

        uint32 const prozent = sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.BonusPercent", 100);
        return std::max<uint32>(1, amount * prozent / 100);
    }

    // Per-player, per-entry heat for the open-world kill degression. Lives on
    // the Player object through CustomData, so it needs no global map or
    // locking and disappears on logout; bounded and LRU-evicted so an
    // unbounded tour of creature entries cannot grow it forever.
    class DegressionState : public DataMap::Base
    {
    public:
        std::vector<BazaarDegression::Entry> Entries;
    };

    char const* const DEGRESSION_STATE_KEY = "mod-ethereal-bazaar.tokens.degression";

    bool DegressionEnabled()
    {
        return sConfigMgr->GetOption<bool>("EtherealBazaar.Tokens.Degression.Enable", true);
    }

    BazaarDegression::Entry& FindOrCreateDegressionEntry(std::vector<BazaarDegression::Entry>& entries,
        uint32 entry, uint64 now, uint32 maxEntries)
    {
        for (BazaarDegression::Entry& candidate : entries)
            if (candidate.key == entry)
                return candidate;

        if (maxEntries == 0)
            maxEntries = 1;

        if (entries.size() >= maxEntries)
        {
            std::size_t const evict = BazaarDegression::LeastRecentlyUpdatedIndex(entries);
            entries[evict] = BazaarDegression::Entry{entry, 0.0, now};
            return entries[evict];
        }

        entries.push_back(BazaarDegression::Entry{entry, 0.0, now});
        return entries.back();
    }

    // Degression applies only to ordinary creature kills in the open world;
    // dungeon/raid bosses and anything in an instance or battleground keep
    // paying the plain roll untouched.
    uint32 ApplyDegression(Player* player, Creature* killed, uint32 amount)
    {
        if (!DegressionEnabled())
            return amount;

        Map const* map = killed->GetMap();
        if (!map || !map->IsWorldMap())
            return amount;

        uint32 const factorPercent =
            sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.Degression.FactorPercent", BazaarDegression::DEFAULT_FACTOR_PERCENT);
        uint32 const recoveryFactor =
            sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.Degression.RecoveryFactor", BazaarDegression::DEFAULT_RECOVERY_FACTOR);
        uint32 const cutoffPercent =
            sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.Degression.CutoffPercent", BazaarDegression::DEFAULT_CUTOFF_PERCENT);
        uint32 const maxEntries =
            sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.Degression.MaxEntries", BazaarDegression::DEFAULT_MAX_ENTRIES);

        uint64 const now = GameTime::GetGameTime().count();
        DegressionState* state = player->CustomData.GetDefault<DegressionState>(DEGRESSION_STATE_KEY);
        BazaarDegression::Entry& tracked =
            FindOrCreateDegressionEntry(state->Entries, killed->GetEntry(), now, maxEntries);

        uint64 const elapsed = now > tracked.lastUpdate ? now - tracked.lastUpdate : 0;
        double const heat = BazaarDegression::DecayHeat(tracked.heat, elapsed, killed->GetRespawnDelay(), recoveryFactor);
        double const multiplier = BazaarDegression::Multiplier(heat, factorPercent);

        tracked.heat = heat + 1.0;
        tracked.lastUpdate = now;

        if (!amount || BazaarDegression::IsBelowCutoff(multiplier, cutoffPercent))
            return 0;

        return BazaarDegression::ScaledAmount(amount, multiplier, rand_norm());
    }

    void Grant(Player* player, uint32 amount, char const* grund)
    {
        if (!player || !amount)
            return;

        amount = TestZoneBonus::Apply(player, TestZoneBonus::Reward::BazaarTokens, ApplyLevelBonus(player, amount));
        if (!amount)
            return;

        // A full bag must not swallow the reward. Mail is the only honest
        // fallback: the player keeps what they earned and notices it.
        ItemPosCountVec dest;
        InventoryResult const check =
            player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, BAZAAR_TOKEN_ITEM, amount);
        if (check == EQUIP_ERR_OK)
        {
            Item* item = player->StoreNewItem(dest, BAZAAR_TOKEN_ITEM, true);

            // Der Einsammel-Hinweis oben rechts kommt aus SendNewItem. Bei
            // Tokens faellt er bei jedem zweiten Mob an und wird schnell zum
            // Rauschen; die Tasche aktualisiert sich auch ohne ihn. Wer ihn
            // will, schaltet ihn an.
            if (item && sConfigMgr->GetOption<bool>("EtherealBazaar.Tokens.Announce", false))
                player->SendNewItem(item, amount, true, false);
        }
        else if (Item* item = Item::CreateItem(BAZAAR_TOKEN_ITEM, amount, player))
        {
            CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
            item->SaveToDB(trans);
            MailDraft("Bazaar Tokens",
                      "Your bags were full, so Tiraxis had these sent on.")
                .AddItem(item)
                .SendMailTo(trans, MailReceiver(player), MailSender(MAIL_CREATURE, BAZAAR_NPC_TIRAXIS));
            CharacterDatabase.CommitTransaction(trans);
        }

        LOG_DEBUG("module.bazaar", "Ethereal Bazaar: {} earned {} token(s) from {}.",
                  player->GetName(), amount, grund);
    }
}

class ethereal_bazaar_tokens : public PlayerScript
{
public:
    ethereal_bazaar_tokens() : PlayerScript("ethereal_bazaar_tokens") { }

    void OnPlayerCompleteQuest(Player* player, Quest const* quest) override
    {
        if (!Enabled() || !player || !quest)
            return;

        Grant(player, Wuerfeln("Quest", 0, 6), "a quest");
    }

    void OnPlayerRewardKillRewarder(Player* player, KillRewarder* rewarder, bool, float&) override
    {
        Creature* killed = rewarder && rewarder->GetVictim() ? rewarder->GetVictim()->ToCreature() : nullptr;
        if (!Enabled() || !player || !killed)
            return;

        // Nothing for what a player made themselves, and nothing for the
        // harmless: a totem farm should not be a token farm.
        if (killed->IsSummon() || killed->IsCritter() || killed->IsTotem())
            return;

        if (!KillPays(player, killed) || IsUnearnedSoloKill(player, killed))
            return;

        // Bosses are worth a real amount, and a raid boss more than a dungeon
        // one. IsDungeonBoss covers the flagged encounters; the world bosses
        // outside an instance are deliberately left with the ordinary rate.
        if (killed->IsDungeonBoss())
        {
            Map const* map = killed->GetMap();
            bool const raid = map && map->IsRaid();
            Grant(player, Wuerfeln(raid ? "RaidBoss" : "DungeonBoss", raid ? 30 : 6, raid ? 40 : 12),
                  raid ? "a raid boss" : "a dungeon boss");
            return;
        }

        Grant(player, ApplyDegression(player, killed, Wuerfeln("Creature", 0, 2)), "a creature");
    }
};

void AddEtherealBazaarTokenScripts()
{
    new ethereal_bazaar_tokens();
}
