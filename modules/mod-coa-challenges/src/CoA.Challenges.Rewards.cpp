// mod-coa-challenges: challenge/trial rewards (DB-first + generated .conf).
//
// Reward data lives in coa_challenge_reward (one row per challenge/level/reward)
// and, when the DB is empty, in the generated .conf as
//   CoAChallenges.Rewards.<id>.<level> = itemId:amount:ach:special:first;...
// Delivery is by mail (CoAChallenges.GrantRewards), on completion.
//
// Provenance: the client export (CoAExport.lua Levels[].Rewards[]) carries
// ItemID/ItemAmount/Achievement/IsSpecialReward/IsFirstCompletion per level.
// Achievement ids are custom; they are only grantable when the
// server's Achievement.dbc carries them (grant is defensive: unknown ids are
// logged, never crash).
#include "CoA.Challenges.Review.h"
#include "Mail.h"
#include "Item.h"
#include "ObjectMgr.h"
#include "AchievementMgr.h"

namespace CoAChallenges
{

    namespace
    {
        // Ascension grants one achievement per class per trial. The name encodes
        // it as "<prefix>[<Class>] <Trial>" (prefix is "" or "Realm First!"); the
        // client export only carries a single variant (Witch Doctor), so the
        // grant must resolve the variant for the player's class *and* prefix.
        // Fails safe: any parse miss returns the stored id unchanged.
        bool ParseClassAchievement(std::string const& name, std::string& prefix,
            std::string& label, std::string& family)
        {
            size_t const open = name.find('[');
            if (open == std::string::npos)
                return false;
            size_t const close = name.find(']', open + 1);
            if (close == std::string::npos)
                return false;
            prefix = name.substr(0, open);
            while (!prefix.empty() && (prefix.back() == ' ' || prefix.back() == '\t'))
                prefix.pop_back();
            label = name.substr(open + 1, close - open - 1);
            size_t f = close + 1;
            while (f < name.size() && name[f] == ' ')
                ++f;
            family = name.substr(f);
            return !label.empty() && !family.empty();
        }

        // The same trial exists as "" (normal) and "Realm First!" sets; keep them
        // apart so a normal reward never grants the Realm First variant.
        std::string FamilyKey(std::string const& prefix, std::string const& family)
        {
            return prefix + '\x1f' + family;
        }

        // class label -> server class id (Warrior=1 .. Runemaster=32, Hero=10).
        // Derived once from the normal "Hardcore" family, whose ids are the
        // canonical class order at a stride of 20 (base + 20*(classId-1)).
        using LabelToClass = std::unordered_map<std::string, uint8>;
        using FamilyToClassAch = std::unordered_map<std::string, std::unordered_map<uint8, uint32>>;

        struct ClassAchievementMaps
        {
            LabelToClass labelToClass;
            FamilyToClassAch familyToClassAch;
        };

        ClassAchievementMaps const& GetClassAchievementMaps()
        {
            static ClassAchievementMaps maps;
            static std::once_flag once;
            std::call_once(once, []()
            {
                struct Item { uint32 id; std::string label; };
                std::unordered_map<std::string, std::vector<Item>> byFamily;
                for (AchievementEntry const* a : sAchievementStore)
                {
                    if (!a || !a->name[0])
                        continue;
                    std::string prefix, label, family;
                    if (!ParseClassAchievement(a->name[0], prefix, label, family))
                        continue;
                    byFamily[FamilyKey(prefix, family)].push_back({ a->ID, label });
                }

                // Canonical class order from the normal "Hardcore" set (the
                // generic "[Mastery]"/"[Conquest]" rows land at index >32 and
                // are excluded).
                auto hc = byFamily.find(FamilyKey("", "Hardcore"));
                if (hc != byFamily.end())
                {
                    uint32 minId = 0;
                    for (Item const& it : hc->second)
                        if (!minId || it.id < minId)
                            minId = it.id;
                    if (minId)
                        for (Item const& it : hc->second)
                        {
                            if (it.id < minId || (it.id - minId) % 20 != 0)
                                continue;
                            uint32 const idx = (it.id - minId) / 20 + 1;
                            if (idx >= 1 && idx <= 32)
                                maps.labelToClass[it.label] = uint8(idx);
                        }
                }

                // key -> classId -> achievement id (per-family id order may
                // differ from the canonical one).
                for (auto const& [key, items] : byFamily)
                    for (Item const& it : items)
                    {
                        auto lc = maps.labelToClass.find(it.label);
                        if (lc != maps.labelToClass.end())
                            maps.familyToClassAch[key][lc->second] = it.id;
                    }
            });
            return maps;
        }

        // Returns the player's variant of a class-specific achievement, or
        // `storedId` when it is class-agnostic / no variant is known.
        uint32 ResolveClassAchievement(uint32 storedId, uint8 playerClass)
        {
            AchievementEntry const* stored = sAchievementStore.LookupEntry(storedId);
            if (!stored || !stored->name[0])
                return storedId;
            std::string prefix, label, family;
            if (!ParseClassAchievement(stored->name[0], prefix, label, family))
                return storedId;

            ClassAchievementMaps const& maps = GetClassAchievementMaps();
            // Skip non-class labels (e.g. "[Mastery]").
            if (maps.labelToClass.find(label) == maps.labelToClass.end())
                return storedId;
            auto fit = maps.familyToClassAch.find(FamilyKey(prefix, family));
            if (fit == maps.familyToClassAch.end())
                return storedId;
            auto cit = fit->second.find(playerClass);
            if (cit == fit->second.end())
                return storedId;
            return cit->second;
        }
    } // namespace

    // DB-only: rewards come from coa_challenge_reward (no conf fallback).
    // Returns the reward list for one level; a missing per-level entry falls
    // back to the level-0/union entry (if any).
    std::vector<RewardDef> GetChallengeRewards(uint32 challengeID, uint32 level)
    {
        std::lock_guard<std::mutex> lock(DefMutex);
        auto it = DefCache.find(challengeID);
        if (it == DefCache.end())
            return {};
        auto const& rw = it->second.rewards;
        if (level > 0)
        {
            auto lv = rw.find(level);
            if (lv != rw.end())
                return lv->second;
        }
        auto unionIt = rw.find(0);
        if (unionIt != rw.end())
            return unionIt->second;
        return {};
    }

    // isSpecial is client-display metadata (echoed by `.coa reward`); it does
    // NOT gate delivery today - only isFirst does.
    void GrantChallengeRewards(Player* player, uint32 challengeID, uint32 level, bool firstItemReward,
        bool firstAchievement)
    {
        if (!player)
            return;
        if (!sConfigMgr->GetOption<bool>("CoAChallenges.GrantRewards", true))
            return;

        std::vector<RewardDef> rewards = GetChallengeRewards(challengeID, level);
        if (rewards.empty())
            return;

        std::string const subject = sConfigMgr->GetOption<std::string>(
            "CoAChallenges.Reward.MailSubject", "Challenge Reward");
        std::string const body = sConfigMgr->GetOption<std::string>(
            "CoAChallenges.Reward.MailBody", "Your challenge reward is enclosed.");

        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        // (itemId, stack) pairs collected here; sent as one or more mails, each
        // capped at MAX_MAIL_ITEMS attachments.
        std::vector<std::pair<uint32, uint32>> itemStacks;

        for (RewardDef const& r : rewards)
        {
            if (r.achievement && (!r.isFirst || firstAchievement))
            {
                // Ascension achievements are per class; resolve the variant for
                // the completing character (e.g. grant "[Warrior] Ironman"
                // instead of the stored "[Witch Doctor] Ironman").
                uint32 const achId = ResolveClassAchievement(r.achievement, player->getClass());
                if (AchievementEntry const* entry = sAchievementStore.LookupEntry(achId))
                {
                    if (!player->HasAchieved(achId))
                    {
                        player->CompletedAchievement(entry);
                        LOG_INFO("module.coa_challenges",
                            "Achievement {} (stored {}, class {}) for {} (challenge {} level {}): hasAchieved after call = {}",
                            achId, r.achievement, uint32(player->getClass()), player->GetName(),
                            challengeID, level, player->HasAchieved(achId) ? 1 : 0);
                    }
                }
                else
                {
                    // Custom achievement, absent from the server
                    // Achievement.dbc. Item rewards still go through.
                    LOG_WARN("module.coa_challenges",
                        "Achievement {} (challenge {} level {}) unknown to core, not granted to {}",
                        achId, challengeID, level, player->GetName());
                }
            }

            if (r.itemId && (!r.isFirst || firstItemReward))
            {
                ItemTemplate const* proto = sObjectMgr->GetItemTemplate(r.itemId);
                if (!proto)
                {
                    LOG_WARN("module.coa_challenges",
                        "Reward item {} (challenge {} level {}) unknown to core, not sent to {}",
                        r.itemId, challengeID, level, player->GetName());
                    continue;
                }
                // Item::CreateItem clamps to the template's max stack, so split
                // the amount into stacks (non-stackable rewards become several
                // mail items) instead of silently losing the excess.
                uint32 remaining = r.amount;
                uint32 maxStack = proto->GetMaxStackSize();
                if (!maxStack)
                    maxStack = 1;
                while (remaining > 0)
                {
                    uint32 stack = std::min(remaining, maxStack);
                    itemStacks.emplace_back(r.itemId, stack);
                    remaining -= stack;
                }
            }
        }

        // One mail per MAX_MAIL_ITEMS attachments: a large reward (e.g. many
        // non-stackable items) would otherwise overflow the client's mail frame
        // and the excess would be unretrievable.
        for (size_t i = 0; i < itemStacks.size(); i += MAX_MAIL_ITEMS)
        {
            MailDraft draft(subject, body);
            bool any = false;
            for (size_t j = i; j < itemStacks.size() && j < i + MAX_MAIL_ITEMS; ++j)
            {
                Item* item = Item::CreateItem(itemStacks[j].first, itemStacks[j].second, player);
                if (!item)
                    continue;
                item->SaveToDB(trans);
                draft.AddItem(item);
                any = true;
                LOG_INFO("module.coa_challenges",
                    "Queued reward item {}x{} for {} (challenge {} level {})",
                    itemStacks[j].first, itemStacks[j].second, player->GetName(), challengeID, level);
            }
            if (any)
                draft.SendMailTo(trans, MailReceiver(player),
                    MailSender(MAIL_NORMAL, 0, MAIL_STATIONERY_GM), MAIL_CHECK_MASK_COPIED);
        }
        CharacterDatabase.CommitTransaction(trans);
    }

} // namespace CoAChallenges
