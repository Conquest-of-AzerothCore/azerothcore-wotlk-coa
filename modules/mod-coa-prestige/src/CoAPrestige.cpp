/*
 * mod-coa-prestige - Chromie's Prestige Mode for Conquest of Azeroth.
 *
 * A character at the Prestige level speaks to Chromie (creature 178081) and lets her wind back
 * time: the character returns to level 1 in its racial starting zone, the active specialization
 * loses its talents and abilities, zone quests, exotic pets and temporary buffs and debuffs are
 * reset, and items, gold, currencies and reputation are kept. The specialization stays locked
 * until the character is back at the Prestige level, and while Prestige Mode is active the
 * Prestige Challenge aura multiplies the experience the character earns. Every activation pays
 * the Prestige rewards and raises the character's Prestige level.
 *
 * The client carries the whole interface. AscensionUI/Gossips/PrestigeMode.lua replaces Chromie's
 * gossip window with the Prestige window and drives it through three gossip options it finds by
 * their exact text; GetPrestigeLevel() reads the character and account Prestige levels from the
 * SMSG_UPDATE_OBJECT_ADDON field table; C_Player:IsPrestiged() is HasAura(9930831).
 */

#include "AllBattlegroundScript.h"
#include "AllSpellScript.h"
#include "AscensionFreepick.h"
#include "AscensionHighRiskPolicy.h"
#include "AscensionMysticEnchant.h"
#include "AscensionRulesets.h"
#include "AscensionSpecialization.h"
#include "AscensionTalentReplacementData.h"
#include "AscensionWarcraftReborn.h"
#include "AscensionWildcard.h"
#include "Battleground.h"
#include "CoA.Prestige.API.h"
#include "CoAPrestigeRules.h"
#include "AscensionPrestigeReset.h"
#include "CoASpellbook.h"
#include "Chat.h"
#include "Config.h"
#include "CreatureScript.h"
#include "DatabaseEnv.h"
#include "Duration.h"
#include "GameEventMgr.h"
#include "GlobalScript.h"
#include "Item.h"
#include "LFGMgr.h"
#include "Log.h"
#include "Mail.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Pet.h"
#include "Player.h"
#include "PlayerScript.h"
#include "PlayerSettings.h"
#include "QueryCallback.h"
#include "QuestDef.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldScript.h"
#include "WorldSession.h"

#include <atomic>
#include <mutex>
#include <unordered_map>
#include <unordered_set>

namespace
{
    using namespace CoAPrestige;

    constexpr char DefaultRewards[] = "1287330:1 375250:100000 90004:100";
    constexpr uint8 FirstLevel = 1;

    enum ChromieAction : uint32
    {
        ACTION_ACTIVATE = 1,
        ACTION_REWARDS = 2,
        ACTION_EXPERIENCE_ITEMS = 3,
        ACTION_DAILY_LABEL = 4
    };

    std::atomic<bool> g_enabled{ true };
    std::atomic<uint32> g_requiredLevel{ 0 };
    std::atomic<uint32> g_experienceBonusPercent{ 300 };

    std::mutex g_rewardsLock;
    std::vector<RewardItem> g_rewards;

    std::mutex g_accountLock;
    std::unordered_map<ObjectGuid::LowType, uint32> g_otherCharactersPrestige;

    std::vector<RewardItem> Rewards()
    {
        std::lock_guard<std::mutex> guard(g_rewardsLock);
        return g_rewards;
    }

    // Prestige dailies (quests 80954/80955/80956) and the rotation that offers one
    // per day. The daily is granted on activation and turned in at Chromie; it has
    // two objectives (the level cap and a content counter), credited by the hooks
    // below through dummy kill-credit creatures (never spawned; the quest's
    // ObjectiveText supplies the display).
    uint32 ActiveDailyQuest()
    {
        for (PrestigeDaily const& daily : PrestigeDailies)
            if (sGameEventMgr->IsActiveEvent(daily.eventId))
                return daily.questId;
        return 0;
    }

    // The daily's aura only applies where its content is: Battlegrounds, a dungeon
    // instance (not a raid), or the open world.
    bool DailyContentMatches(PrestigeDaily const& daily, bool inBattleground, bool inInstance, bool inDungeon)
    {
        if (daily.auraId == DailyAuraBattlegrounds)
            return inBattleground;
        if (daily.auraId == DailyAuraDungeons)
            return inDungeon;
        return !inInstance && !inBattleground;
    }

    // The cycle's daily benefit follows its content independently of reward eligibility.
    uint32 CycleDailyQuest(Player* player);

    void SyncDailyAuras(Player* player)
    {
        bool const active = IsActive(player);
        uint32 const cycleDaily = CycleDailyQuest(player);
        Battleground* const bg = player->GetBattleground();
        bool const inBattleground = bg && bg->isBattleground();
        bool const inInstance = player->GetMap() && player->GetMap()->Instanceable();
        bool const inDungeon = player->GetMap() && player->GetMap()->IsDungeon() && !player->GetMap()->IsRaid();

        for (PrestigeDaily const& daily : PrestigeDailies)
        {
            // The aura lasts the whole cycle: it stays after the objectives are met and
            // drops when the cycle ends or the character leaves the matching content.
            bool const want = active && cycleDaily == daily.questId
                && DailyContentMatches(daily, inBattleground, inInstance, inDungeon);
            if (want)
            {
                if (!player->HasAura(daily.auraId))
                    player->AddAura(daily.auraId, player);
            }
            else if (player->HasAura(daily.auraId))
                player->RemoveAurasDueToSpell(daily.auraId);
        }
    }

    void LoadConfig()
    {
        g_enabled = sConfigMgr->GetOption<bool>("CoAPrestige.Enable", true);
        g_requiredLevel = ResolveRequiredLevel(sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL));
        g_experienceBonusPercent = sConfigMgr->GetOption<uint32>("CoAPrestige.ExperienceBonusPercent", 300);

        std::string const text = sConfigMgr->GetOption<std::string>("CoAPrestige.Rewards", DefaultRewards);
        std::optional<std::vector<RewardItem>> rewards = ParseRewards(text);
        if (!rewards)
        {
            LOG_ERROR("module.coa_prestige", "CoAPrestige.Rewards \"{}\" is not a list of item:count pairs; "
                "Prestige Mode pays no rewards.", text);
            rewards.emplace();
        }

        std::lock_guard<std::mutex> guard(g_rewardsLock);
        g_rewards = std::move(*rewards);
    }

    std::vector<uint32> SettingValues(Player const* player, char const* source)
    {
        std::vector<uint32> values;
        if (PlayerSettingVector const* settings = player->FindPlayerSettings(source))
            for (PlayerSetting const& setting : *settings)
                values.push_back(setting.value);
        return values;
    }

    void WriteSetting(Player* player, char const* source, std::vector<uint32> const& values)
    {
        std::size_t const previous = SettingValues(player, source).size();
        for (std::size_t index = 0; index < values.size(); ++index)
            player->UpdatePlayerSetting(source, uint32(index), values[index]);
        for (std::size_t index = values.size(); index < previous; ++index)
            player->UpdatePlayerSetting(source, uint32(index), 0);
    }

    State LoadState(Player const* player)
    {
        return DecodeState(SettingValues(player, StateSetting));
    }

    void SaveState(Player* player, State const& state)
    {
        WriteSetting(player, StateSetting, EncodeState(state));
    }

    uint32 CycleDailyQuest(Player* player)
    {
        State const state = LoadState(player);
        if (IsPrestigeDaily(state.dailyQuest))
            return state.dailyQuest;
        for (PrestigeDaily const& daily : PrestigeDailies)
            if (player->GetQuestStatus(daily.questId) != QUEST_STATUS_NONE || player->IsDailyQuestDone(daily.questId))
                return daily.questId;
        return 0;
    }

    void RememberCycleDaily(Player* player, uint32 questId)
    {
        State state = LoadState(player);
        if (state.active && state.dailyQuest != questId && IsPrestigeDaily(questId))
        {
            state.dailyQuest = questId;
            SaveState(player, state);
        }
    }

    uint32 OtherCharactersPrestige(Player const* player)
    {
        std::lock_guard<std::mutex> guard(g_accountLock);
        auto const found = g_otherCharactersPrestige.find(player->GetGUID().GetCounter());
        return found == g_otherCharactersPrestige.end() ? 0 : found->second;
    }

    void SendPrestigeLevels(Player* player)
    {
        uint32 const level = LoadState(player).level;
        WorldPacket data(AddonFieldOpcode, 8 + 2 * 8);
        data << player->GetGUID()
             << AddonFieldPrestigeLevel << level
             << AddonFieldAccountPrestigeLevel << (level + OtherCharactersPrestige(player));
        player->SendDirectMessage(&data);
    }

    // Other characters of the account are not in memory: their Prestige levels come from the
    // setting their own saves wrote, read once at login.
    void LoadOtherCharactersPrestige(Player* player)
    {
        CharacterDatabasePreparedStatement* stmt =
            CharacterDatabase.GetPreparedStatement(CHAR_SEL_ACCOUNT_CHARACTER_SETTINGS_BY_SOURCE);
        stmt->SetData(0, player->GetSession()->GetAccountId());
        stmt->SetData(1, player->GetGUID().GetCounter());
        stmt->SetData(2, std::string(StateSetting));

        ObjectGuid const guid = player->GetGUID();
        player->GetSession()->GetQueryProcessor().AddCallback(CharacterDatabase.AsyncQuery(stmt).WithPreparedCallback(
            [guid](PreparedQueryResult result)
            {
                Player* player = ObjectAccessor::FindConnectedPlayer(guid);
                if (!player)
                    return;

                uint32 total = 0;
                if (result)
                {
                    do
                    {
                        PlayerSettingVector const values =
                            PlayerSettingsStore::ParseSettingsData(result->Fetch()[0].Get<std::string>());
                        if (!values.empty())
                            total += values[0].value;
                    } while (result->NextRow());
                }

                {
                    std::lock_guard<std::mutex> lock(g_accountLock);
                    g_otherCharactersPrestige[guid.GetCounter()] = total;
                }
                if (player->IsInWorld())
                    SendPrestigeLevels(player);
            }));
    }

    void RememberActionBar(Player* player)
    {
        std::vector<BarSlot> bar;
        for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
            if (ActionButton const* action = player->GetActionButton(button))
                if (action->GetType() == ACTION_BUTTON_SPELL && action->GetAction())
                    bar.push_back({ button, action->GetAction() });
        WriteSetting(player, BarSetting, EncodeBar(bar));
    }

    void ClearForgottenActionButtons(Player* player)
    {
        for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
            if (ActionButton const* action = player->GetActionButton(button))
                if (action->GetType() == ACTION_BUTTON_SPELL && !player->HasSpell(action->GetAction()))
                    player->removeActionButton(button);
    }

    void DismissPets(Player* player)
    {
        auto isExotic = [](uint32 creatureId)
        {
            CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(creatureId);
            return creature && creature->IsExotic();
        };
        auto isExoticHunterPet = [&](PetStable::PetInfo const& info)
        {
            return info.Type == HUNTER_PET && isExotic(info.CreatureId);
        };

        if (Pet* pet = player->GetPet())
            player->RemovePet(pet, pet->getPetType() == HUNTER_PET && isExotic(pet->GetEntry())
                ? PET_SAVE_AS_DELETED : PET_SAVE_NOT_IN_SLOT);

        if (PetStable* stable = player->GetPetStable())
        {
            if (stable->CurrentPet && isExoticHunterPet(*stable->CurrentPet))
            {
                Pet::DeleteFromDB(stable->CurrentPet->PetNumber);
                stable->CurrentPet.reset();
                player->SetTemporaryUnsummonedPetNumber(0);
            }

            for (Optional<PetStable::PetInfo>& stabled : stable->StabledPets)
                if (stabled && isExoticHunterPet(*stabled))
                {
                    Pet::DeleteFromDB(stabled->PetNumber);
                    stabled.reset();
                }

            std::erase_if(stable->UnslottedPets, [&](PetStable::PetInfo const& info)
            {
                if (!isExoticHunterPet(info))
                    return false;
                Pet::DeleteFromDB(info.PetNumber);
                return true;
            });
        }

        // A pet put away by mounting is not GetPet(), and the dismount below would bring it back.
        if (player->GetTemporaryUnsummonedPetNumber())
        {
            player->RemovePet(nullptr, PET_SAVE_NOT_IN_SLOT);
            player->SetTemporaryUnsummonedPetNumber(0);
        }

        player->RemoveAllControlled();
        player->UnsummonAllTotems();
    }

    void ResetQuests(Player* player, uint32 maxLevel)
    {
        for (uint16 slot = 0; slot < MAX_QUEST_LOG_SIZE; ++slot)
        {
            uint32 const questId = player->GetQuestSlotQuestId(slot);
            if (!questId || IsPrestigeDaily(questId))
                continue;

            player->TakeQuestSourceItem(questId, false);
            player->AbandonQuest(questId);
            player->RemoveTimedQuest(questId);
            player->SetQuestSlot(slot, 0);
            player->RemoveActiveQuest(questId, false);
        }

        std::vector<uint32> replayable;
        for (uint32 questId : player->getRewardedQuests())
            if (Quest const* quest = sObjectMgr->GetQuestTemplate(questId))
            {
                QuestTraits const traits{ quest->GetZoneOrSort(), quest->GetQuestLevel(), quest->GetType(),
                    quest->IsRepeatable() || quest->IsDailyOrWeekly() || quest->IsMonthly() || quest->IsSeasonal() ||
                    quest->IsDFQuest(), quest->GetMinLevel() };
                if (IsReplayableQuest(traits, maxLevel))
                    replayable.push_back(questId);
            }

        for (uint32 questId : replayable)
            player->RemoveRewardedQuest(questId, false);
    }

    // Upgraded ranks above the new level, which CoA's level pass never takes back. First ranks are
    // left to that pass: it knows which ones a racial, baseline or proficiency grant still allows.
    // The returned chains are the ones whose remaining lower rank has to be made usable again.
    std::unordered_set<uint32> ForgetRanksAbove(Player* player, uint8 level)
    {
        std::unordered_set<uint32> chains;
        for (AscensionClassAbility const& ability : GetAscensionClassAbilities(player->getClass()))
            if (ability.SpellId != ability.FirstSpellId && ability.RequiredLevel > level &&
                player->HasSpell(ability.SpellId))
            {
                chains.insert(sSpellMgr->GetFirstSpellInChain(ability.SpellId));
                player->removeSpell(ability.SpellId, SPEC_MASK_ALL, false);
            }
        for (AscensionCompatData::TalentReplacement const& replacement : AscensionCompatData::TalentReplacements)
            if (replacement.ClassId == player->getClass())
                for (AscensionCompatData::ReplacementRank const& rank : replacement.Ranks)
                    if (rank.RequiredLevel > level && player->HasSpell(rank.SpellId))
                    {
                        chains.insert(sSpellMgr->GetFirstSpellInChain(rank.SpellId));
                        player->removeSpell(rank.SpellId, SPEC_MASK_ALL, false);
                    }
        for (uint32 const spellId : CoASpellbook::UpgradeRanksAbove(player, level))
            if (player->HasSpell(spellId))
            {
                chains.insert(sSpellMgr->GetFirstSpellInChain(spellId));
                player->removeSpell(spellId, SPEC_MASK_ALL, false);
            }
        return chains;
    }

    // Removing a rank leaves the rank below it known but inactive, so it cannot be cast until the
    // next login. Learning the highest rank left again makes it the active one.
    void ReactivateRemainingRanks(Player* player, std::unordered_set<uint32> const& chains)
    {
        for (uint32 const firstRank : chains)
        {
            uint32 highest = 0;
            for (uint32 rank = firstRank; rank; rank = sSpellMgr->GetNextSpellInChain(rank))
                if (player->HasSpell(rank))
                    highest = rank;

            if (!highest || player->HasActiveSpell(highest))
                continue;

            player->removeSpell(highest, SPEC_MASK_ALL, false);
            player->learnSpell(highest, false);
        }
    }

    void StripTemporaryAuras(Player* player)
    {
        player->RemoveAurasByType(SPELL_AURA_MOUNTED);
        player->RemoveOwnedAuras([](Aura const* aura)
        {
            return !aura->IsPassive() && !aura->IsPermanent() && aura->GetId() != PrestigedAura;
        });
    }

    std::vector<RewardItem> ForgetRiding(Player* player)
    {
        std::vector<RewardItem> tomes;
        for (RidingTome const& riding : RidingTomes)
            if (player->HasSpell(riding.spell))
            {
                player->removeSpell(riding.spell, SPEC_MASK_ALL, false);
                tomes.push_back({ riding.tome, 1 });
            }
        return tomes;
    }

    void MailEquippedItems(Player* player, std::vector<Item*>& mailed, CharacterDatabaseTransaction trans)
    {
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        {
            Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            if (!item)
                continue;

            player->MoveItemFromInventory(INVENTORY_SLOT_BAG_0, slot, true);
            item->DeleteFromInventoryDB(trans);
            item->SaveToDB(trans);
            mailed.push_back(item);
        }
    }

    void GrantRewards(Player* player, std::vector<RewardItem> const& rewards, std::vector<Item*>& mailed,
                      CharacterDatabaseTransaction trans)
    {
        for (RewardItem const& reward : rewards)
        {
            if (!sObjectMgr->GetItemTemplate(reward.item))
            {
                LOG_ERROR("module.coa_prestige", "Prestige reward item {} does not exist.", reward.item);
                continue;
            }

            uint32 missing = 0;
            ItemPosCountVec destination;
            if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, reward.item, reward.count, &missing) !=
                    EQUIP_ERR_OK && !missing)
            {
                missing = reward.count;
                destination.clear();
            }

            if (uint32 const stored = reward.count - missing; stored && !destination.empty())
                if (Item* item = player->StoreNewItem(destination, reward.item, true,
                        Item::GenerateItemRandomPropertyId(reward.item)))
                    player->SendNewItem(item, stored, true, false);

            uint32 const stack = std::max<uint32>(1, sObjectMgr->GetItemTemplate(reward.item)->GetMaxStackSize());
            for (uint32 remaining = missing; remaining;)
            {
                uint32 const count = std::min(remaining, stack);
                remaining -= count;
                if (Item* item = Item::CreateItem(reward.item, count, player))
                {
                    item->SaveToDB(trans);
                    mailed.push_back(item);
                }
            }
        }
    }

    void MailItems(Player* player, std::vector<Item*> const& items, CharacterDatabaseTransaction trans)
    {
        for (std::size_t first = 0; first < items.size(); first += MAX_MAIL_ITEMS)
        {
            MailDraft draft("Prestige Mode", "Chromie has returned your equipped gear and any overflow Prestige rewards.");
            for (std::size_t index = first; index < std::min(items.size(), first + MAX_MAIL_ITEMS); ++index)
                draft.AddItem(items[index]);
            draft.SendMailTo(trans, MailReceiver(player), MailSender(MAIL_CREATURE, ChromieEntry),
                MAIL_CHECK_MASK_COPIED);
        }
    }

    bool Activate(Player* player)
    {
        State state = LoadState(player);
        uint32 const requiredLevel = g_requiredLevel;
        bool const wildcard = AscensionWildcard::IsWildcardHero(player);
        bool const reborn = AscensionWarcraftReborn::IsRebornCharacter(player);
        auto const* realmReset = AscensionPrestigeReset::Area52;
        bool const area52 = realmReset && realmReset->Applies(player);
        bool const freepick = !area52 && AscensionFreepick::IsFreepickHero(player);
        AscensionPrestigeReset::Plan resetPlan;
        std::string resetError;
        if (area52 && !realmReset->Prepare(player, resetPlan, resetError))
        {
            ChatHandler(player->GetSession()).SendSysMessage(resetError);
            return false;
        }
        bool const customClass = IsAscensionCustomClassId(player->getClass());
        uint32 const specialization = area52 ? resetPlan.Build + 1u : wildcard ? AscensionWildcard::ActiveSpec(player) + 1 :
            freepick ? AscensionFreepick::ActiveSpecialization(player) + 1u :
            customClass ? GetAscensionActiveSpecialization(player) : player->GetActiveSpec() + 1u;

        ActivationFacts facts;
        facts.enabled = g_enabled;
        facts.level = player->GetLevel();
        facts.requiredLevel = requiredLevel;
        facts.active = state.active;
        facts.specialization = specialization;
        facts.alive = player->IsAlive();
        facts.inCombat = player->IsInCombat();
        facts.travelling = player->IsInFlight() || player->GetVehicle() || player->GetTransport();
        facts.inInstance = player->GetMap()->Instanceable();

        ChatHandler chat(player->GetSession());
        if (Refusal const refusal = CheckActivation(facts); refusal != Refusal::None)
        {
            chat.SendSysMessage(RefusalMessage(refusal, requiredLevel));
            return false;
        }

        PlayerInfo const* start = sObjectMgr->GetPlayerInfo(player->getRace(true), player->getClass());
        if (!start)
        {
            LOG_ERROR("module.coa_prestige", "No starting location for race {} class {}: {} cannot prestige.",
                uint32(player->getRace(true)), uint32(player->getClass()), player->GetName());
            chat.SendSysMessage("Chromie cannot find where your journey began.");
            return false;
        }

        AscensionPrestigeReset::Result resetResult;
        if (area52 && !realmReset->Reset(player, resetPlan, resetResult, resetError))
        {
            chat.SendSysMessage(resetError);
            return false;
        }

        RememberActionBar(player);
        DismissPets(player);
        sLFGMgr->LeaveLfg(player->GetGUID());
        ResetQuests(player, requiredLevel);

        uint32 talents = resetResult.Abilities;
        if (!area52 && wildcard)
            talents = AscensionWildcard::PrestigeSpecialization(player);
        else if (!area52 && freepick)
            talents = AscensionFreepick::PrestigeSpecialization(player);
        else if (!area52 && reborn)
            talents = AscensionWarcraftReborn::ResetActiveTalents(player);
        else if (!area52 && customClass)
            talents = ForgetAscensionClassTalents(player);
        else if (!area52)
            player->resetTalents(true);
        uint32 const enchants = area52 ? resetResult.Enchants :
            reborn ? AscensionMysticEnchant::ClearActivePreset(player) : 0;
        std::vector<RewardItem> const ridingTomes = ForgetRiding(player);
        std::unordered_set<uint32> chains = ForgetRanksAbove(player, FirstLevel);
        if (reborn)
            chains.merge(AscensionWarcraftReborn::ForgetClassSpellsAbove(player, FirstLevel));
        player->GiveLevel(FirstLevel);
        player->SetUInt32Value(PLAYER_XP, 0);
        player->SetRestBonus(player->GetRestBonus());
        ClearForgottenActionButtons(player);
        ReactivateRemainingRanks(player, chains);
        player->SendInitialActionButtons();
        StripTemporaryAuras(player);
        AscensionRulesets::Apply(player, AscensionRulesets::Ruleset::PvE);

        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        std::vector<Item*> mailed;
        MailEquippedItems(player, mailed, trans);

        state.level += 1;
        state.active = true;
        state.specialization = specialization;
        state.dailyQuest = 0;
        SaveState(player, state);

        player->AddAura(PrestigedAura, player);
        player->KilledMonsterCredit(PrestigeKillCredit);
        GrantRewards(player, Rewards(), mailed, trans);
        GrantRewards(player, ridingTomes, mailed, trans);
        GrantPrestigeDaily(player);
        player->SetHomebind(WorldLocation(start->mapId, start->positionX, start->positionY, start->positionZ,
            start->orientation), start->areaId);

        MailItems(player, mailed, trans);
        player->SaveToDB(trans, false, false);
        sScriptMgr->OnPlayerCoAPrestige(player, trans);
        if (!CharacterDatabase.AsyncCommitTransaction(trans).m_future.get())
        {
            LOG_ERROR("module.coa_prestige", "The prestige save of {} ({}) was rolled back by the character database.",
                player->GetName(), player->GetGUID().ToString());
            chat.SendSysMessage("Chromie's magic faltered and your prestige could not be saved. "
                "Contact a game master.");
            return false;
        }
        sScriptMgr->OnPlayerCoAPrestigeSaved(player);

        SendPrestigeLevels(player);
        chat.PSendSysMessage("Chromie winds back time. Prestige {}: reach level {} again to unlock your "
            "specialization.", state.level, requiredLevel);
        if (!mailed.empty())
            chat.SendSysMessage("Your equipped gear and any overflow Prestige rewards were sent to your mailbox.");

        LOG_INFO("module.coa_prestige", "{} ({}) activated Prestige {} in specialization {}: {} talent spell(s), "
            "{} ability chain(s) and {} mystic enchant(s) removed.", player->GetName(), player->GetGUID().ToString(),
            state.level, specialization, talents, chains.size(), enchants);

        if (!player->TeleportTo(start->mapId, start->positionX, start->positionY, start->positionZ,
                start->orientation))
            LOG_ERROR("module.coa_prestige", "{} prestiged but could not be sent to the starting zone.",
                player->GetName());
        return true;
    }

    void CatchUpPrestigeCredits(Player* player)
    {
        uint32 achieved = 0;
        for (uint32 offset = 0; offset < PrestigeAchievementCount; ++offset)
            achieved += player->HasAchieved(PrestigeAchievementFirst + offset) ? 1 : 0;
        for (uint32 credit = MissingPrestigeCredits(LoadState(player).level, achieved); credit; --credit)
            player->KilledMonsterCredit(PrestigeKillCredit);
    }

    void SyncDailyMaxLevelCredit(Player* player)
    {
        if (!player || player->GetLevel() < g_requiredLevel)
            return;

        for (PrestigeDaily const& daily : PrestigeDailies)
        {
            auto& statuses = player->getQuestStatusMap();
            auto const status = statuses.find(daily.questId);
            if (status == statuses.end() || status->second.Status != QUEST_STATUS_INCOMPLETE ||
                status->second.CreatureOrGOCount[0])
                continue;

            Quest const* quest = sObjectMgr->GetQuestTemplate(daily.questId);
            if (!quest || quest->RequiredNpcOrGo[0] != DailyCreditMaxLevel ||
                quest->RequiredNpcOrGoCount[0] != 1)
                continue;

            status->second.CreatureOrGOCount[0] = 1;
            player->SetQuestStatus(daily.questId, QUEST_STATUS_INCOMPLETE, false);
            player->SendQuestUpdateAddCreatureOrGo(quest, ObjectGuid::Empty, 0, 0, 1);
            if (player->CanCompleteQuest(daily.questId))
                player->CompleteQuest(daily.questId);
            else
                player->AdditionalSavingAddMask(ADDITIONAL_SAVING_QUEST_STATUS);
        }
    }

    void CompleteIfDue(Player* player)
    {
        State state = LoadState(player);
        if (!state.active || player->GetLevel() < g_requiredLevel)
            return;

        state.active = false;
        if (player->GetLevel() < 10 && IsAscensionCustomClassId(player->getClass()))
            state.signaturePending = true;
        SaveState(player, state);
        player->RemoveAurasDueToSpell(PrestigedAura);
        SyncDailyAuras(player);
        SendPrestigeLevels(player);
        ChatHandler(player->GetSession()).PSendSysMessage(
            "Prestige {} complete: your specialization is unlocked.", state.level);
    }

    void RestoreSpecializationSignature(Player* player)
    {
        State state = LoadState(player);
        if ((state.active || state.signaturePending) && IsAscensionCustomClassId(player->getClass()) &&
            RestoreAscensionSpecializationSignature(player) && state.signaturePending)
        {
            state.signaturePending = false;
            SaveState(player, state);
        }
    }

    std::string SpecializationSwitchRefusal(Player* player, uint32 /*active*/, uint32 requested)
    {
        if (!g_enabled || IsAscensionCustomClassId(player->getClass()) ||
            IsSpecializationSwitchAllowed(LoadState(player), requested))
            return {};
        return SpecializationLockedMessage(g_requiredLevel);
    }

    std::string SpecializationSlotSwitchRefusal(Player* player, uint32 active, uint32 requested)
    {
        if (!g_enabled || !LoadState(player).active || active == requested)
            return {};
        return "Your active specialization slot is Prestige locked until you complete this Prestige.";
    }
}

class npc_coa_prestige_chromie : public CreatureScript
{
public:
    npc_coa_prestige_chromie() : CreatureScript("npc_coa_prestige_chromie") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (!g_enabled)
            return false;

        ClearGossipMenuFor(player);
        // Pull the character's active prestige daily into the gossip quest list, so
        // the client's PrestigeModeUI (GetGossipActiveQuests / SelectGossipActiveQuest)
        // and the standard quest dialog can turn it in.
        if (IsActive(player))
            GrantPrestigeDaily(player, CycleDailyQuest(player));
        SyncDailyMaxLevelCredit(player);
        player->PrepareQuestMenu(creature->GetGUID());
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, std::string(OptionActivate), GOSSIP_SENDER_MAIN, ACTION_ACTIVATE);
        AddGossipItemFor(player, GOSSIP_ICON_VENDOR, std::string(OptionRewards), GOSSIP_SENDER_MAIN, ACTION_REWARDS);
        AddGossipItemFor(player, GOSSIP_ICON_VENDOR, std::string(OptionExperienceItems), GOSSIP_SENDER_MAIN,
            ACTION_EXPERIENCE_ITEMS);
        // The client matches this label with "^Today's Prestige Quest is (.*)$"
        // to fill the daily tab; it is a label, not an actionable option.
        if (uint32 const dailyId = ActiveDailyQuest())
            if (Quest const* daily = sObjectMgr->GetQuestTemplate(dailyId))
                AddGossipItemFor(player, GOSSIP_ICON_CHAT,
                    "Today's Prestige Quest is " + daily->GetTitle(), GOSSIP_SENDER_MAIN, ACTION_DAILY_LABEL);
        SendPrestigeLevels(player);
        if (AscensionWildcard::IsWildcardHero(player))
            AscensionWildcard::SendPrestigeInfo(player);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        ClearGossipMenuFor(player);
        switch (action)
        {
            case ACTION_ACTIVATE:
                CloseGossipMenuFor(player);
                Activate(player);
                break;
            case ACTION_REWARDS:
                player->GetSession()->SendListInventory(creature->GetGUID());
                break;
            case ACTION_EXPERIENCE_ITEMS:
                player->GetSession()->SendListInventory(creature->GetGUID(), ExperienceVendorEntry);
                break;
            default:
                CloseGossipMenuFor(player);
                break;
        }
        return true;
    }
};

class coa_prestige_player : public PlayerScript
{
public:
    coa_prestige_player() : PlayerScript("coa_prestige_player", { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT,
        PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST, PLAYERHOOK_ON_QUEST_ABANDON,
        PLAYERHOOK_ON_LEARN_SPELL, PLAYERHOOK_ON_MAP_CHANGED,
        PLAYERHOOK_ON_SEND_INITIAL_PACKETS_BEFORE_ADD_TO_MAP,
        PLAYERHOOK_CAN_GIVE_MAIL_REWARD_AT_GIVE_LEVEL }) { }

    // A prestige cycle relevels the character through thresholds it already passed in a
    // previous cycle; sObjectMgr->GetMailLevelReward has no per-character idempotency of its
    // own, so it would resend the same mail every cycle without this guard.
    bool OnPlayerCanGiveMailRewardAtGiveLevel(Player* player, uint8 /*level*/) override
    {
        return !LoadState(player).active;
    }

    // A client that reconnects to a character still in the world gets its initial packets again but
    // no login or map hook, and starts with an empty field table. The levels follow once the
    // character is back on the map.
    void OnPlayerSendInitialPacketsBeforeAddToMap(Player* player, WorldPacket& /*data*/) override
    {
        if (g_enabled)
            player->m_Events.AddEventAtOffset([guid = player->GetGUID()]
            {
                if (Player* player = ObjectAccessor::FindPlayer(guid))
                {
                    RestoreSpecializationSignature(player);
                    SendPrestigeLevels(player);
                }
            }, 1s);
    }

    void OnPlayerLogin(Player* player) override
    {
        if (!g_enabled)
            return;

        LoadOtherCharactersPrestige(player);
        CatchUpPrestigeCredits(player);
        SyncDailyMaxLevelCredit(player);
        CompleteIfDue(player);
        if (LoadState(player).active && !player->HasAura(PrestigedAura))
            player->AddAura(PrestigedAura, player);
        RememberCycleDaily(player, CycleDailyQuest(player));
        SyncDailyAuras(player);
        SendPrestigeLevels(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> guard(g_accountLock);
        g_otherCharactersPrestige.erase(player->GetGUID().GetCounter());
    }

    void OnPlayerLevelChanged(Player* player, uint8 oldLevel) override
    {
        if (!g_enabled)
            return;

        RestoreSpecializationSignature(player);

        // A prestige starts in War Mode; reaching the level where the PvP rulesets can be
        // chosen switches it to PvE Mode, and the player picks High-Risk or War Mode from there.
        if (IsActive(player) && oldLevel < HighRisk::MinimumLevel && player->GetLevel() >= HighRisk::MinimumLevel
            && AscensionRulesets::Has(player, AscensionRulesets::Ruleset::WarMode))
            AscensionRulesets::Apply(player, AscensionRulesets::Ruleset::PvE);

        // "Max Level Reached" daily objective: credited at the required level. The
        // daily still keeps its content objective until that is met too.
        SyncDailyMaxLevelCredit(player);

        CompleteIfDue(player);
    }

    void OnPlayerCompleteQuest(Player* player, Quest const* quest) override
    {
        // "World Quests Completed" objective: any quest turned in outside instances and
        // battlegrounds counts, except the Prestige dailies themselves.
        if (quest && !IsPrestigeDaily(quest->GetQuestId()) && player->GetMap()
            && !player->GetMap()->Instanceable() && !player->InBattleground())
            player->KilledMonsterCredit(DailyCreditWorldQuests);

        // Turning in the reward quest does not end the cycle benefit.
        if (g_enabled)
            SyncDailyAuras(player);
    }

    void OnPlayerQuestAbandon(Player* player, uint32 /*questId*/) override
    {
        if (g_enabled)
            SyncDailyAuras(player);
    }

    void OnPlayerLearnSpell(Player* player, uint32 spellId) override
    {
        std::vector<uint32> const values = SettingValues(player, BarSetting);
        if (values.empty() || !values[0])
            return;

        std::vector<BarSlot> bar = DecodeBar(values);
        std::vector<uint8> const buttons = ClaimButtons(bar, spellId,
            [](uint32 spell) { return sSpellMgr->GetFirstSpellInChain(spell); });
        if (buttons.empty())
            return;

        bool placed = false;
        for (uint8 const button : buttons)
        {
            ActionButton const* current = player->GetActionButton(button);
            bool const free = !current ||
                (current->GetType() == ACTION_BUTTON_SPELL && !player->HasSpell(current->GetAction()));
            if (free && player->addActionButton(button, spellId, ACTION_BUTTON_SPELL))
                placed = true;
        }

        WriteSetting(player, BarSetting, EncodeBar(bar));
        if (placed)
            player->SendInitialActionButtons();
    }

    void OnPlayerMapChanged(Player* player) override
    {
        if (!g_enabled)
            return;

        SyncDailyMaxLevelCredit(player);
        SendPrestigeLevels(player);
        // Entering or leaving a battleground or an instance is what makes a daily's
        // aura apply or drop.
        SyncDailyAuras(player);
    }
};

class coa_prestige_world : public WorldScript
{
public:
    coa_prestige_world()
        : WorldScript("coa_prestige_world", { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP }) { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        LoadConfig();
    }

    void OnStartup() override
    {
        if (!g_enabled)
            return;

        CreatureTemplate const* chromie = sObjectMgr->GetCreatureTemplate(ChromieEntry);
        if (!chromie || chromie->ScriptID != sObjectMgr->GetScriptId("npc_coa_prestige_chromie"))
            LOG_ERROR("module.coa_prestige", "Creature {} is missing or not bound to npc_coa_prestige_chromie: "
                "Prestige Mode cannot be activated.", ChromieEntry);
        if (!sObjectMgr->GetCreatureTemplate(ExperienceVendorEntry))
            LOG_ERROR("module.coa_prestige", "Creature {} is missing: Chromie's Experience Items list is empty.",
                ExperienceVendorEntry);
        if (!sSpellMgr->GetSpellInfo(PrestigedAura))
            LOG_ERROR("module.coa_prestige", "Spell {} is missing: prestiged characters get no experience bonus.",
                PrestigedAura);
    }
};

namespace CoAPrestige
{
    bool IsActive(Player* player)
    {
        return player && player->HasAura(PrestigedAura) && player->GetLevel() < g_requiredLevel;
    }

    uint32 ExperienceBonusPercent()
    {
        return g_experienceBonusPercent;
    }

    uint32 RequiredLevel()
    {
        return g_requiredLevel;
    }

    uint32 GrantPrestigeDaily(Player* player, uint32 questId)
    {
        if (!player)
            return 0;

        for (PrestigeDaily const& daily : PrestigeDailies)
            if (player->GetQuestStatus(daily.questId) != QUEST_STATUS_NONE)
            {
                RememberCycleDaily(player, daily.questId);
                SyncDailyAuras(player);
                return daily.questId;
            }

        uint32 const dailyId = questId ? questId : ActiveDailyQuest();
        if (!dailyId || !IsPrestigeDaily(dailyId))
            return 0;

        RememberCycleDaily(player, dailyId);
        for (PrestigeDaily const& daily : PrestigeDailies)
            if (player->IsDailyQuestDone(daily.questId))
            {
                SyncDailyAuras(player);
                return 0;
            }

        Quest const* daily = sObjectMgr->GetQuestTemplate(dailyId);
        if (!daily)
            return 0;

        if (player->GetQuestStatus(dailyId) == QUEST_STATUS_NONE && !player->IsDailyQuestDone(dailyId))
            player->AddQuest(daily, player);

        SyncDailyAuras(player);
        return dailyId;
    }

    uint32 DailyExperienceBonusPercent(Player* player, uint8 xpSource)
    {
        if (!player || !IsActive(player))
            return 0;

        // Kill and profession experience come from the daily's own aura (84783/84784/
        // 84788, SPELL_AURA_MOD_XP_PCT) while the character is in that content. The aura
        // does not reach quests or the battleground-end award, so this hook covers those.
        bool const quest = xpSource == XPSOURCE_QUEST || xpSource == XPSOURCE_QUEST_DF;
        bool const battleground = xpSource == XPSOURCE_BATTLEGROUND;
        if (!quest && !battleground)
            return 0;

        Battleground* const bg = player->GetBattleground();
        bool const inBattleground = bg && bg->isBattleground();
        bool const inInstance = player->GetMap() && player->GetMap()->Instanceable();
        bool const inDungeon = player->GetMap() && player->GetMap()->IsDungeon() && !player->GetMap()->IsRaid();

        uint32 const cycleDaily = CycleDailyQuest(player);
        for (PrestigeDaily const& daily : PrestigeDailies)
        {
            if (cycleDaily != daily.questId
                || !DailyContentMatches(daily, inBattleground, inInstance, inDungeon))
                continue;

            if (SpellInfo const* aura = sSpellMgr->GetSpellInfo(daily.auraId))
                if (aura->Effects[0].BasePoints > -1)
                    return uint32(aura->Effects[0].BasePoints + 1);
        }
        return 0;
    }
}

// A Warcraft Reborn character's specialization is its talent spec; the lock refuses the other spec's
// activation spell (SPELL_EFFECT_TALENT_SPEC_SELECT, value 1 or 2).
class coa_prestige_talent_spec_lock : public AllSpellScript
{
public:
    coa_prestige_talent_spec_lock() : AllSpellScript("coa_prestige_talent_spec_lock",
        { ALLSPELLHOOK_ON_SPELL_CHECK_CAST }) { }

    void OnSpellCheckCast(Spell* spell, bool /*strict*/, SpellCastResult& result) override
    {
        Player* player = spell->GetCaster() ? spell->GetCaster()->ToPlayer() : nullptr;
        if (!g_enabled || result != SPELL_CAST_OK || !player || IsAscensionCustomClassId(player->getClass()) ||
            AscensionWildcard::IsWildcardHero(player) || AscensionFreepick::IsFreepickHero(player))
            return;

        for (SpellEffectInfo const& effect : spell->GetSpellInfo()->Effects)
            if (effect.Effect == SPELL_EFFECT_TALENT_SPEC_SELECT &&
                !IsSpecializationSwitchAllowed(LoadState(player), uint32(effect.CalcValue(player))))
            {
                ChatHandler(player->GetSession()).SendSysMessage(SpecializationLockedMessage(g_requiredLevel));
                result = SPELL_FAILED_DONT_REPORT;
                return;
            }
    }
};

// "Battlegrounds Completed" daily objective: credit every participant at BG end.
class coa_prestige_daily_battleground : public AllBattlegroundScript
{
public:
    coa_prestige_daily_battleground() : AllBattlegroundScript("coa_prestige_daily_battleground",
        { ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_END_REWARD }) { }

    // The daily counts battlegrounds only, not arenas.
    void OnBattlegroundEndReward(Battleground* bg, Player* player, TeamId /*winnerTeamId*/) override
    {
        if (player && bg && bg->isBattleground())
            player->KilledMonsterCredit(DailyCreditBattlegrounds);
    }
};

// "Dungeons Completed" daily objective: credit the group when the dungeon's final
// encounter fires (dungeonCompleted is the LFG dungeon id, non-zero only for the
// encounter flagged as the dungeon's last boss in instance_encounters).
class coa_prestige_daily_dungeon : public GlobalScript
{
public:
    coa_prestige_daily_dungeon() : GlobalScript("coa_prestige_daily_dungeon",
        { GLOBALHOOK_ON_AFTER_UPDATE_ENCOUNTER_STATE }) { }

    void OnAfterUpdateEncounterState(Map* map, EncounterCreditType /*type*/, uint32 /*creditEntry*/,
        Unit* /*source*/, Difficulty /*difficulty*/, std::list<DungeonEncounter const*> const* /*encounters*/,
        uint32 dungeonCompleted, bool updated) override
    {
        if (!updated || !dungeonCompleted || !map || !map->IsNonRaidDungeon())
            return;

        for (Map::PlayerList::const_iterator it = map->GetPlayers().begin(); it != map->GetPlayers().end(); ++it)
            if (Player* it_player = it->GetSource())
                it_player->KilledMonsterCredit(DailyCreditDungeons);
    }
};

void AddSC_coa_prestige()
{
    new npc_coa_prestige_chromie();
    new coa_prestige_player();
    new coa_prestige_world();
    new coa_prestige_daily_battleground();
    new coa_prestige_daily_dungeon();
    new coa_prestige_talent_spec_lock();
    AddAscensionSpecializationSwitchGuard(SpecializationSwitchRefusal);
    AddAscensionSpecializationSlotSwitchGuard(SpecializationSlotSwitchRefusal);
}
