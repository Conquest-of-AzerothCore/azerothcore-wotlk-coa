/*
 * Where Bazaar Tokens come from.
 *
 * The shop is only half the economy. Ascension sold tokens for real money and
 * let players buy them off the auction house; with the shop gone, the only way
 * left is to play. The rule the server owner asked for: a little from
 * everything, more from harder content.
 *
 *   quest turned in     0 to 12
 *   creature killed     0 to 3
 *   dungeon boss       14 to 22
 *   raid boss          41 to 53
 *
 * Every amount is multiplied at level 60, because a character that stops
 * levelling would otherwise stop earning.
 *
 * The zero in the lower two ranges is deliberate: most kills and some quests
 * give nothing at all, so tokens stay something one notices.
 *
 * A kill pays the player with the killing blow, or, with
 * EtherealBazaar.Tokens.GroupShare, whoever tapped the creature: every member
 * of a tapping group in reward range receives the same roll.
 */

#include "EtherealBazaar.h"

#include "Chat.h"
#include "CoATestZoneBonus.h"
#include "Configuration/Config.h"
#include "Creature.h"
#include "Group.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QuestDef.h"
#include "Mail.h"
#include "Random.h"
#include "ScriptMgr.h"

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

    // The multiplier is a percentage so the config can hold a whole number.
    // At 150 a level-60 character earns half again as much.
    uint32 ApplyLevelBonus(Player* player, uint32 amount)
    {
        if (!amount)
            return 0;

        uint32 const abLevel = sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.BonusLevel", 60);
        if (player->GetLevel() < abLevel)
            return amount;

        uint32 const prozent = sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.BonusPercent", 150);
        return std::max<uint32>(1, amount * prozent / 100);
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

        Grant(player, Wuerfeln("Quest", 0, 12), "a quest");
    }
};

class ethereal_bazaar_kill_tokens : public UnitScript
{
public:
    ethereal_bazaar_kill_tokens() : UnitScript("ethereal_bazaar_kill_tokens", true, { UNITHOOK_ON_UNIT_DEATH }) { }

    void OnUnitDeath(Unit* victim, Unit* killer) override
    {
        Creature* killed = victim ? victim->ToCreature() : nullptr;
        if (!Enabled() || !killed)
            return;

        // Nothing for what a player made themselves, and nothing for the
        // harmless: a totem farm should not be a token farm.
        if (killed->IsSummon() || killed->IsCritter() || killed->IsTotem())
            return;

        std::vector<Player*> const recipients = Recipients(killed, killer);
        if (recipients.empty())
            return;

        // Bosses are worth a real amount, and a raid boss more than a dungeon
        // one. IsDungeonBoss covers the flagged encounters; the world bosses
        // outside an instance are deliberately left with the ordinary rate.
        uint32 amount;
        char const* grund;
        if (killed->IsDungeonBoss())
        {
            Map const* map = killed->GetMap();
            bool const raid = map && map->IsRaid();
            amount = Wuerfeln(raid ? "RaidBoss" : "DungeonBoss", raid ? 41 : 14, raid ? 53 : 22);
            grund = raid ? "a raid boss" : "a dungeon boss";
        }
        else
        {
            amount = Wuerfeln("Creature", 0, 3);
            grund = "a creature";
        }

        // One roll for the whole group, so a healer who never touched the
        // target earns what the tank who killed it earns.
        for (Player* recipient : recipients)
            Grant(recipient, amount, grund);
    }

private:
    static std::vector<Player*> Recipients(Creature* killed, Unit* killer)
    {
        std::vector<Player*> recipients;

        if (!sConfigMgr->GetOption<bool>("EtherealBazaar.Tokens.GroupShare", false))
        {
            if (Player* player = killer ? killer->ToPlayer() : nullptr)
                recipients.push_back(player);
            return recipients;
        }

        // The loot recipient is cleared when the kill earns no reward (too
        // little player damage), so those kills pay nobody here either.
        if (Group* group = killed->GetLootRecipientGroup())
        {
            for (GroupReference* itr = group->GetFirstMember(); itr; itr = itr->next())
                if (Player* member = itr->GetSource())
                    if (member->IsAtGroupRewardDistance(killed))
                        recipients.push_back(member);
            return recipients;
        }

        if (Player* tapper = killed->GetLootRecipient())
            if (tapper->IsInMap(killed))
                recipients.push_back(tapper);

        return recipients;
    }
};

void AddEtherealBazaarTokenScripts()
{
    new ethereal_bazaar_tokens();
    new ethereal_bazaar_kill_tokens();
}
