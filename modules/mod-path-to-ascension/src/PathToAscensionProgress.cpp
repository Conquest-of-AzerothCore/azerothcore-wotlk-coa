/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "PathToAscension.h"

#include "AllBattlegroundScript.h"
#include "AllCreatureScript.h"
#include "AllGameObjectScript.h"
#include "AllSpellScript.h"
#include "AscensionAverageItemLevel.h"
#include "AscensionBuildCreatorRules.h"
#include "AscensionItemPower.h"
#include "AscensionMysticEnchant.h"
#include "AscensionWildcard.h"
#include "AuctionHouseMgr.h"
#include "Battleground.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DataMap.h"
#include "GameObject.h"
#include "GlobalScript.h"
#include "Group.h"
#include "Item.h"
#include "KillRewarder.h"
#include "LFGMgr.h"
#include "Log.h"
#include "Mail.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Pet.h"
#include "Player.h"
#include "PlayerScript.h"
#include "QuestDef.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldScript.h"
#include "WorldSession.h"

#include <algorithm>
#include <charconv>
#include <filesystem>
#include <string_view>

namespace PathToAscension
{
    namespace
    {
        constexpr uint16 SMSG_TUTORIAL_PATCH = 0x06A5;

        Catalog catalog;
        Settings settings;
        bool loaded = false;

        struct TutorialRuntime : DataMap::Base
        {
            EventMap events;
            bool initialized = false;
            std::vector<std::pair<uint32, ObjectGuid>> escapeAuras;
        };

        TutorialRuntime& Runtime(Player* player)
        {
            return *player->CustomData.GetDefault<TutorialRuntime>("mod-path-to-ascension.runtime");
        }

        RealmProfile ReadRealmProfile(uint32 value, RealmProfile fallback)
        {
            return value <= uint32(RealmProfile::Development) ? RealmProfile(value) : fallback;
        }

        // Onyxia's Lair and Naxxramas still run as level 80 Wrath of the Lich King raids here.
        bool IsWrathRaidTutorial(uint32 tutorialId)
        {
            static constexpr uint32 ids[] = { 123, 127, 130, 134, 137, 141, 144, 148 };
            return std::find(std::begin(ids), std::end(ids), tutorialId) != std::end(ids);
        }

        constexpr uint32 MythicPlusTutorial = 17;

        uint32 ContentExpansion()
        {
            int32 const configured = sConfigMgr->GetOption<int32>("PathToAscension.Expansion", EXPANSION_CLASSIC);
            if (configured >= EXPANSION_CLASSIC && configured <= EXPANSION_WRATH_OF_THE_LICH_KING)
                return uint32(configured);

            return sConfigMgr->GetOption<uint32>("Expansion", EXPANSION_WRATH_OF_THE_LICH_KING);
        }

        uint32 ClientExpansion()
        {
            uint32 const maxLevel = sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);
            return maxLevel <= 60 ? EXPANSION_CLASSIC
                : maxLevel <= 70 ? EXPANSION_THE_BURNING_CRUSADE : EXPANSION_WRATH_OF_THE_LICH_KING;
        }

        RealmProfile ClientRealmProfile()
        {
            std::string const type = sConfigMgr->GetOption<std::string>("CoA.RealmType", "live", false);
            if (type == "seasonal")
                return RealmProfile::Seasonal;
            if (type == "league")
                return RealmProfile::League;
            if (type == "ptr")
                return RealmProfile::PTR;
            if (type == "development")
                return RealmProfile::Development;
            return RealmProfile::Live;
        }

        bool CountsForPlayer(Player const* player)
        {
            return settings.verifiedProgress && player && player->IsInWorld() && player->GetSession()
                && !player->GetSession()->IsBot();
        }

        uint32 EquippedItemPower(Player const* player, bool pvp)
        {
            uint32 power = 0;
            for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
            {
                Item const* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
                if (!item || !item->IsSoulBound() || item->IsBroken())
                    continue;

                // Original equipment carries its PvE/PvP power as an on-equip marker spell.
                power += AscensionItemPower::OfItem(item->GetTemplate(), pvp);
            }

            return power;
        }

        void CheckEquipmentTutorials(Player* player)
        {
            // Explicit equipped-average item level thresholds. Where the installed client carries two
            // conflicting values for a Vanilla prerequisite, the higher one satisfies both.
            float const itemLevel = AscensionAverageItemLevel::Equipped(player);
            for (auto const [tutorialId, threshold] : {std::pair{10u, 40u}, {200u, 52u}, {201u, 58u}, {202u, 62u},
                {203u, 62u}, {204u, 64u}, {205u, 69u}, {206u, 75u}, {207u, 80u}, {208u, 92u}, {209u, 95u},
                {210u, 100u}, {211u, 108u}, {212u, 114u}, {213u, 116u}, {214u, 134u}, {215u, 134u},
                {216u, 136u}, {217u, 124u}, {218u, 145u}})
                if (itemLevel >= float(threshold))
                    CompleteVerifiedTutorial(player, tutorialId);
        }

        void CheckLevelTutorials(Player* player)
        {
            for (auto const [tutorialId, level] : {std::pair{74u, 10u}, {80u, 15u}, {84u, 20u}, {101u, 60u},
                {104u, 70u}})
                if (player->GetLevel() >= level)
                    CompleteVerifiedTutorial(player, tutorialId);
        }

        void CompleteGameModeTutorial(Player* player, uint32 tutorialId)
        {
            Tutorial const* tutorial = catalog.Find(tutorialId);
            if (tutorial && MatchesGameModes(player, *tutorial))
                CompleteVerifiedTutorial(player, tutorialId);
        }

        void CompletePrestigeTutorials(Player* player)
        {
            CompleteGameModeTutorial(player, 40);
            CompleteGameModeTutorial(player, 241);
        }

        bool KnowsPrimaryStatPath(Player const* player)
        {
            return std::any_of(AscensionWildcard::PRIMARY_STAT_PATHS.begin(),
                AscensionWildcard::PRIMARY_STAT_PATHS.end(), [player](AscensionWildcard::PrimaryStatPath const& path)
            {
                return player->HasSpell(path.SpellId);
            });
        }

        struct StarterMount
        {
            uint32 race;
            uint32 tutorial;
            uint32 item;
            uint32 spell;
        };

        constexpr StarterMount StarterMounts[] =
        {
            {1, 110, 5656, 458}, {2, 111, 5665, 6653}, {3, 112, 5873, 6898},
            {4, 113, 47100, 66847}, {5, 114, 13333, 17464}, {6, 115, 15277, 18989},
            {7, 116, 13322, 17454}, {8, 117, 8588, 8395}, {10, 118, 28927, 34795},
            {11, 119, 29744, 35710}
        };

        bool StarterMountQuestRewarded(Player const* player, StarterMount const& mount)
        {
            Tutorial const* tutorial = GetCatalog().Find(mount.tutorial);
            return tutorial && tutorial->QuestId() && player->GetQuestRewardStatus(tutorial->QuestId());
        }

        void CheckStarterMountTutorial(Player* player)
        {
            uint32 const delivered = SettingValue(player, RidingSetting, 0);
            for (StarterMount const& mount : StarterMounts)
                if (mount.race == player->getRace() && player->HasSpell(mount.spell)
                    && (delivered == mount.item || StarterMountQuestRewarded(player, mount)))
                    CompleteVerifiedTutorial(player, mount.tutorial);
        }

        void CheckStateTutorials(Player* player)
        {
            CheckStarterMountTutorial(player);
            CheckEquipmentTutorials(player);

            if (EquippedItemPower(player, false) >= 460)
            {
                CompleteVerifiedTutorial(player, 8);
                CompleteVerifiedTutorial(player, 250);
                CompleteVerifiedTutorial(player, 251);
            }

            if (EquippedItemPower(player, true) >= 250)
            {
                CompleteVerifiedTutorial(player, 9);
                CompleteVerifiedTutorial(player, 258);
                CompleteVerifiedTutorial(player, 259);
            }

            if (player->HasSpell(33391))
                CompleteVerifiedTutorial(player, 27);

            if (player->HasSpell(33388))
            {
                CompleteVerifiedTutorial(player, 90);
                CompleteVerifiedTutorial(player, 91);
            }

            // Item 106954 teaches Specialization II (979994).
            if (player->HasSpell(979994) || player->GetSpecsCount() >= 2)
                CompleteVerifiedTutorial(player, 28);

            constexpr uint32 FirstPrestigeAchievement = 13100;
            if (player->HasAchieved(FirstPrestigeAchievement))
                CompletePrestigeTutorials(player);

            if (KnowsPrimaryStatPath(player))
                CompleteGameModeTutorial(player, 50);

            if (player->GetLevel() >= 10)
                CompleteGameModeTutorial(player, 239);

            if (SettingValue(player, VerifiedSetting, 89) != 1)
            {
                lfg::LfgState const state = sLFGMgr->GetState(player->GetGUID());
                if (state == lfg::LFG_STATE_QUEUED || state == lfg::LFG_STATE_PROPOSAL
                    || state == lfg::LFG_STATE_DUNGEON)
                    CompleteVerifiedTutorial(player, 89);
            }
        }

        void SendAvailabilityOverrides(Player* player)
        {
            uint32 const serverAvailability = RealmAvailabilityField(settings.realm);
            uint32 const clientAvailability = RealmAvailabilityField(settings.client);
            for (auto const& [id, tutorial] : catalog.Tutorials())
            {
                if (!tutorial.fields[serverAvailability] && !tutorial.fields[clientAvailability])
                    continue;

                uint32 const expansion = tutorial.fields[TutorialField::Expansion];
                bool const offered = IsExpansionOffered(tutorial);
                bool const clientShows = expansion == AnyExpansion || expansion == settings.clientExpansion;
                bool const realmBridge = settings.realm != settings.client
                    && tutorial.fields[serverAvailability] && !tutorial.fields[clientAvailability];
                if (offered == clientShows && !realmBridge)
                    continue;

                uint32 const patchedExpansion = offered == clientShows ? expansion
                    : offered ? AnyExpansion : (settings.clientExpansion + 1) % AnyExpansion;

                // Extensions.dll 0x101e4ea0 reads 45 DWORDs and five C strings; pointer fields 35..39
                // are replaced by its own parser. The patch only aligns the client's realm and expansion
                // visibility with the tutorials the server offers; eligibility stays server-side.
                WorldPacket patch(SMSG_TUTORIAL_PATCH, 256 + tutorial.pages.size());
                for (uint32 index = 0; index < 35; ++index)
                    patch << uint32(index == TutorialField::Expansion ? patchedExpansion : tutorial.fields[index]);
                for (uint32 index = 0; index < 5; ++index)
                    patch << uint32(0);
                for (uint32 index = TutorialField::FirstRealmAvailability; index < 93; ++index)
                    patch << uint32(index == clientAvailability && realmBridge ? 1 : tutorial.fields[index]);
                patch << tutorial.icon << tutorial.auxiliaryText << tutorial.name << tutorial.pages << tutorial.hint;
                player->SendDirectMessage(&patch);
            }
        }

        void RecordNpcVisit(Player* player, Creature* creature)
        {
            if (!CountsForPlayer(player) || !creature || !player->IsAlive() || player->IsGameMaster())
                return;

            uint32 const entry = creature->GetEntry();
            // Tutorial 2 names two independent visits: Ameer Greatluck and Tiraxis.
            if (entry == 80061 || entry == 900007)
            {
                uint32 const bit = entry == 80061 ? 1u : 2u;
                bool const first = !(SettingValue(player, EventSetting, 2) & bit);
                RecordTutorialEvent(player, 2, bit);
                if ((SettingValue(player, EventSetting, 2) & 3u) == 3u)
                    CompleteVerifiedTutorial(player, 2);
                SyncTracking(player, 2);
                if (first)
                    player->SaveToDB(false, false);
            }

            uint32 const zone = creature->GetZoneId();
            if (entry == 416000 && zone == 3703)
                CompleteVerifiedTutorial(player, 267);
            else if (entry == 1414503 && zone == 1519)
                CompleteVerifiedTutorial(player, 64);
            else if (entry == 1414502 && zone == 1637)
                CompleteVerifiedTutorial(player, 65);

            if (entry == 10157257)
            {
                if (zone == 1519)
                    CompleteVerifiedTutorial(player, 268);
                else if (zone == 1637)
                    CompleteVerifiedTutorial(player, 269);
            }
            else if (entry == 439420)
            {
                if (zone == 1519)
                    CompleteVerifiedTutorial(player, 234);
                else if (zone == 1637)
                    CompleteVerifiedTutorial(player, 237);
            }

            switch (entry)
            {
                case 14720: CompleteVerifiedTutorial(player, 57); break;
                case 6174: CompleteVerifiedTutorial(player, 58); break;
                case 3310: CompleteVerifiedTutorial(player, 82); break;
                case 352: CompleteVerifiedTutorial(player, 83); break;
                case 16841: CompleteVerifiedTutorial(player, 265); break;
                case 19254: CompleteVerifiedTutorial(player, 266); break;
                case 20500: CompleteVerifiedTutorial(player, 270); break;
                case 20511: CompleteVerifiedTutorial(player, 271); break;
                default: break;
            }
        }

        struct RaidObjective
        {
            uint32 map;
            uint32 boss;
            std::array<uint32, 4> tutorials;
        };

        // One entry per original raid; the four tutorials follow the instance's spawn mode:
        // Normal, Heroic, Mythic and Ascended.
        constexpr RaidObjective RaidObjectives[] =
        {
            {309, 14834, {121, 128, 135, 142}}, {409, 11502, {122, 129, 136, 143}},
            {469, 11583, {124, 131, 138, 145}}, {509, 15339, {125, 132, 139, 146}},
            {531, 15727, {126, 133, 140, 147}}, {532, 15690, {149, 158, 167, 176}},
            {565, 19044, {150, 159, 168, 177}}, {544, 17257, {151, 160, 169, 178}},
            {548, 21212, {152, 161, 170, 179}}, {550, 19622, {153, 162, 171, 180}},
            {568, 23863, {154, 163, 172, 181}}, {534, 17968, {155, 164, 173, 182}},
            {564, 22917, {156, 165, 174, 183}}, {580, 25315, {157, 166, 175, 184}}
        };

        void RecordRaidKill(Player* player, Creature* creature)
        {
            Map const* map = player->FindMap();
            if (!map || map != creature->FindMap())
                return;

            if (!map->Instanceable() && creature->GetCreatureTemplate()->rank == CREATURE_ELITE_WORLDBOSS)
                CompleteVerifiedTutorial(player, 36);

            if (!map->IsRaid() || map->GetSpawnMode() > 3)
                return;

            uint32 const mode = map->GetSpawnMode();
            for (RaidObjective const& objective : RaidObjectives)
            {
                if (map->GetId() != objective.map || creature->GetEntry() != objective.boss)
                    continue;

                CompleteVerifiedTutorial(player, objective.tutorials[mode]);
                if (mode == 0)
                    CompleteVerifiedTutorial(player, 15);
                else if (mode == 1)
                    CompleteVerifiedTutorial(player, 18);
                else if (mode == 3)
                    CompleteVerifiedTutorial(player, 19);
                return;
            }
        }

        bool IsTutorialRaidAchievement(uint32 achievement)
        {
            return achievement >= 87293 && achievement <= 87356;
        }

        void RecordAuctionReceipt(Player* player, Mail const* mail, uint32 itemId)
        {
            if (!mail || mail->messageType != MAIL_AUCTION || mail->receiver != player->GetGUID().GetCounter())
                return;

            // A won auction's mail subject is "item:0:AUCTION_WON:auctionId:count".
            std::array<uint32, 5> fields{};
            std::string_view subject(mail->subject);
            for (uint32 index = 0; index < fields.size(); ++index)
            {
                std::size_t const separator = subject.find(':');
                std::string_view const part = subject.substr(0, separator);
                auto const parsed = std::from_chars(part.data(), part.data() + part.size(), fields[index]);
                if (parsed.ec != std::errc() || parsed.ptr != part.data() + part.size()
                    || (index < 4 && separator == std::string_view::npos))
                    return;
                subject = separator == std::string_view::npos ? std::string_view{} : subject.substr(separator + 1);
            }

            if (!subject.empty() || fields[0] != itemId || fields[1] != 0 || fields[2] != AUCTION_WON
                || !fields[3] || !fields[4])
                return;

            ItemTemplate const* item = sObjectMgr->GetItemTemplate(itemId);
            if (!item)
                return;

            if (item->Quality == ITEM_QUALITY_ARTIFACT
                && (item->Class == ITEM_CLASS_ARMOR || item->Class == ITEM_CLASS_WEAPON))
                CompleteVerifiedTutorial(player, 5);

            switch (itemId)
            {
                case 777800: case 777801: case 777802: case 777803: case 777804: case 777805:
                case 777806: case 778021: case 778022: case 778023: case 778024: case 778025:
                case 975001:
                    CompleteVerifiedTutorial(player, 29);
                    break;
                default:
                    break;
            }
        }

        bool VendorShowsArenaEquipment(uint32 vendorEntry)
        {
            VendorItemData const* items = sObjectMgr->GetNpcVendorItemList(vendorEntry);
            if (!items)
                return false;

            for (VendorItem const* vendorItem : items->m_items)
            {
                if (!vendorItem || !vendorItem->ExtendedCost)
                    continue;

                ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(vendorItem->item);
                ItemExtendedCostEntry const* cost = sItemExtendedCostStore.LookupEntry(vendorItem->ExtendedCost);
                if (itemTemplate && cost && (cost->reqarenapoints || cost->reqpersonalarenarating)
                    && (itemTemplate->Class == ITEM_CLASS_ARMOR || itemTemplate->Class == ITEM_CLASS_WEAPON))
                    return true;
            }

            return false;
        }

        bool TeachesNewProfession(uint32 spellId)
        {
            SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
            if (!spell)
                return false;

            std::vector<uint32> learned{spellId};
            for (SpellEffectInfo const& effect : spell->Effects)
                if (effect.Effect == SPELL_EFFECT_LEARN_SPELL && effect.TriggerSpell)
                    learned.push_back(effect.TriggerSpell);

            return std::any_of(learned.begin(), learned.end(), [](uint32 id)
            {
                SpellLearnSkillNode const* skill = sSpellMgr->GetSpellLearnSkill(id);
                return skill && skill->step == 1 && IsProfessionSkill(skill->skill);
            });
        }

        bool TeachesHigherRank(uint32 spellId)
        {
            SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
            if (!spell)
                return false;

            std::vector<uint32> learned{spellId};
            for (SpellEffectInfo const& effect : spell->Effects)
                if (effect.Effect == SPELL_EFFECT_LEARN_SPELL && effect.TriggerSpell)
                    learned.push_back(effect.TriggerSpell);

            return std::any_of(learned.begin(), learned.end(), [](uint32 id)
            {
                return sSpellMgr->GetFirstSpellInChain(id) != id;
            });
        }

        void RecordManastormDepth(Player* player, uint32 depth)
        {
            if (depth >= 1 && depth <= 5)
            {
                RecordTutorialEvent(player, 220, 1u << (depth - 1));
                if ((SettingValue(player, EventSetting, 220) & 0x1Fu) == 0x1Fu)
                    CompleteVerifiedTutorial(player, 220);
            }

            for (auto const [tutorialId, required] : {std::pair{221u, 50u}, {222u, 100u}, {223u, 500u}, {224u, 1000u}})
                if (depth == required)
                    CompleteVerifiedTutorial(player, tutorialId);
        }

        void RecordAppearance(Player* player, uint32 appearanceId)
        {
            if (!CountsForPlayer(player) || player->IsGameMaster() || !appearanceId)
                return;

            // At most ten distinct appearance IDs, stored as values rather than indexes.
            uint32 count = 0;
            bool known = false;
            if (PlayerSettingVector const* seen = player->FindPlayerSettings(AppearanceSetting))
                for (uint32 i = 0; i < 10 && i < seen->size(); ++i)
                {
                    count += (*seen)[i].value != 0;
                    known |= (*seen)[i].value == appearanceId;
                }

            if (!known && count < 10)
                player->UpdatePlayerSetting(AppearanceSetting, count++, appearanceId);
            if (count >= 10)
                CompleteVerifiedTutorial(player, 245);
        }

        bool EscapedControl(Player* player)
        {
            TutorialRuntime& runtime = Runtime(player);
            std::vector<std::pair<uint32, ObjectGuid>> before;
            before.swap(runtime.escapeAuras);
            return std::any_of(before.begin(), before.end(), [player](auto const& aura)
            {
                return !player->HasAura(aura.first, aura.second);
            });
        }

        namespace Mystic = AscensionMysticEnchant;

        constexpr uint32 MysticReforgeGoal = 10;
        constexpr uint32 GoldenAbilityPack = 778998;

        // Tutorials 3 and 275 share one objective list: buy, reforge ten times, earn an extract.
        void RecordMysticExtracting(Player* player, uint32 bit)
        {
            RecordTutorialEvent(player, 3, bit);
            if ((SettingValue(player, EventSetting, 3) & 7u) != 7u)
                return;

            CompleteGameModeTutorial(player, 3);
            CompleteGameModeTutorial(player, 275);
        }

        void RecordMysticReforge(Player* player)
        {
            if (!CountsForPlayer(player) || player->IsGameMaster())
                return;

            uint32 const reforges = SettingValue(player, CountSetting, 3);
            if (reforges < MysticReforgeGoal)
                player->UpdatePlayerSetting(CountSetting, 3, reforges + 1);
            if (reforges + 1 >= MysticReforgeGoal)
                RecordMysticExtracting(player, 2);
        }

        void CheckMysticCollection(Player* player)
        {
            std::optional<Mystic::Collection> const collection = Mystic::Summarize(player);
            if (!collection)
                return;

            if (collection->Known[Mystic::QUALITY_EPIC] >= 3)
                CompleteGameModeTutorial(player, 11);
            if (collection->Known[Mystic::QUALITY_LEGENDARY])
                CompleteGameModeTutorial(player, 12);
            if (collection->KnownTotal >= 10)
                CompleteGameModeTutorial(player, 26);
            if (collection->KnownWorldforged)
                CompleteGameModeTutorial(player, 63);

            // Every quality the player's class can find on a scroll on this realm.
            bool offered = false;
            bool everyQuality = true;
            for (uint32 quality = 0; quality < Mystic::QUALITY_MAX; ++quality)
                if (collection->Offered[quality])
                {
                    offered = true;
                    everyQuality &= collection->Known[quality] != 0;
                }
            if (offered && everyQuality)
                CompleteGameModeTutorial(player, 273);
        }

        void CheckMysticSlots(Player* player)
        {
            std::optional<Mystic::Collection> const collection = Mystic::Summarize(player);
            if (!collection)
                return;

            if (collection->OpenSlots && collection->FilledSlots == collection->OpenSlots)
                CompleteGameModeTutorial(player, 59);
            if (collection->Active[Mystic::QUALITY_LEGENDARY])
                CompleteGameModeTutorial(player, 60);
            if (collection->Active[Mystic::QUALITY_EPIC] >= 3)
                CompleteGameModeTutorial(player, 61);
        }

        void RecordArchitect(Player* player, uint32 bit)
        {
            RecordTutorialEvent(player, 75, bit);
            if ((SettingValue(player, EventSetting, 75) & 3u) == 3u)
                CompleteGameModeTutorial(player, 75);
        }

        void RecordBuildActivation(Player* player, uint32 progress)
        {
            constexpr uint32 featured = AscensionBuildCreator::ACTIVATION_FEATURED;
            constexpr uint32 featuredEndGame = featured | AscensionBuildCreator::ACTIVATION_END_GAME;
            if ((progress & featuredEndGame) == featuredEndGame)
                CompleteGameModeTutorial(player, 7);
            if (progress & featured)
                RecordArchitect(player, 2);
        }
    }

    Settings const& GetSettings()
    {
        return settings;
    }

    Catalog const& GetCatalog()
    {
        return catalog;
    }

    bool IsLoaded()
    {
        return loaded;
    }

    uint32 SettingValue(Player const* player, char const* source, uint32 index)
    {
        PlayerSettingVector const* values = player->FindPlayerSettings(source);
        return values && index < values->size() ? (*values)[index].value : 0;
    }

    bool MatchesRaceAndClass(Player const* player, Tutorial const& tutorial)
    {
        uint32 const races = tutorial.fields[TutorialField::RaceMask];
        uint32 const race = player->getRace();
        if (races && (!race || race > 32 || !(races & (1u << (race - 1)))))
            return false;

        uint64 const classes = uint64(tutorial.fields[TutorialField::ClassMaskLow])
            | (uint64(tutorial.fields[TutorialField::ClassMaskHigh]) << 32);
        uint32 const playerClass = player->getClass();
        return !classes || (playerClass && playerClass <= 64 && (classes & (uint64(1) << (playerClass - 1))));
    }

    bool MatchesGameModes(Player const* player, Tutorial const& tutorial)
    {
        uint32 const required = tutorial.fields[TutorialField::RequiredGameModes];
        uint32 const excluded = tutorial.fields[TutorialField::ExcludedGameModes];
        if (!required && !excluded)
            return true;

        std::optional<uint32> const modes = sScriptMgr->OnPlayerGetGameModeMask(player);
        return modes && (!required || (required & *modes)) && !(excluded & *modes);
    }

    bool IsCallBoard(uint32 entry)
    {
        switch (entry)
        {
            case 108606: case 402000: case 402001: case 402002: case 402003:
            case 412000: case 412001: case 413000: case 422000: case 1008002:
            case 1008008: case 1804480: case 2250000:
                return true;
            default:
                return false;
        }
    }

    void CompleteVerifiedTutorial(Player* player, uint32 tutorialId)
    {
        if (!loaded || !CountsForPlayer(player) || player->IsGameMaster())
            return;

        Tutorial const* tutorial = catalog.Find(tutorialId);
        if (!tutorial)
            return;

        if (!tutorial->fields[RealmAvailabilityField(settings.realm)] || !MatchesRaceAndClass(player, *tutorial))
            return;

        uint32 const achievementId = tutorial->AchievementId();
        if (SettingValue(player, VerifiedSetting, tutorialId) == 1
            && (!achievementId || player->HasAchieved(achievementId)))
            return;

        if (!achievementId)
        {
            player->UpdatePlayerSetting(VerifiedSetting, tutorialId, 1);
            SyncTracking(player, tutorialId);
            return;
        }

        if (AchievementEntry const* achievement = sAchievementStore.LookupEntry(achievementId))
        {
            if (!player->HasAchieved(achievementId))
                player->CompletedAchievement(achievement);

            if (player->HasAchieved(achievementId))
            {
                player->UpdatePlayerSetting(VerifiedSetting, tutorialId, 1);
                SyncTracking(player, tutorialId);
            }
        }
    }

    void RecordTutorialEvent(Player* player, uint32 tutorialId, uint32 bit)
    {
        if (!loaded || !CountsForPlayer(player))
            return;

        uint32 const previous = SettingValue(player, EventSetting, tutorialId);
        if (!(previous & bit))
            player->UpdatePlayerSetting(EventSetting, tutorialId, previous | bit);

        if (tutorialId == 225 && (SettingValue(player, EventSetting, 225) & 3u) == 3u)
            CompleteVerifiedTutorial(player, 225);
    }

    bool IsLegacyAvailable(uint32 tutorialId)
    {
        if (!loaded || !settings.legacyContent)
            return false;

        Tutorial const* tutorial = catalog.Find(tutorialId);
        if (!tutorial || tutorial->fields[TutorialField::Expansion] >= settings.expansion)
            return false;

        // Only restored legacy quest references without a current-expansion variant.
        return tutorialId == 16 || tutorialId == 41 || (tutorialId >= 121 && tutorialId <= 184
            && !IsWrathRaidTutorial(tutorialId)) || (tutorialId >= 200 && tutorialId <= 218);
    }

    bool IsExpansionOffered(Tutorial const& tutorial)
    {
        uint32 const expansion = tutorial.fields[TutorialField::Expansion];
        if (expansion == AnyExpansion)
            return true;

        return !IsWrathRaidTutorial(tutorial.Id()) && tutorial.Id() != MythicPlusTutorial
            && (expansion == settings.expansion || IsLegacyAvailable(tutorial.Id()));
    }

    bool IsStarterMountQuest(uint32 questId)
    {
        return std::any_of(std::begin(StarterMounts), std::end(StarterMounts), [questId](StarterMount const& mount)
        {
            Tutorial const* tutorial = GetCatalog().Find(mount.tutorial);
            return tutorial && tutorial->QuestId() == questId;
        });
    }

    bool IsCallbackImplemented(uint32 tutorialId)
    {
        static constexpr uint32 ids[] =
        {
            2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 19, 22, 23, 24, 26, 27, 28, 29, 30,
            31, 32, 33, 36, 39, 40, 41, 50, 51, 52, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 74, 75, 76,
            78, 80, 82, 83, 84, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 100, 101, 104, 105, 110, 111,
            112, 113, 114, 115, 116, 117, 118, 119, 121, 122, 124, 125,
            126, 128, 129, 131, 132, 133, 135, 136, 138, 139, 140, 142, 143, 145, 146, 147, 149, 150,
            151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168,
            169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 193, 200,
            201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218,
            219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 237, 238, 239,
            240, 241, 242, 244, 245, 247, 249, 250, 251, 258, 259, 260, 261, 265, 266, 267, 268, 269, 270,
            271, 273, 275, 276, 277
        };
        return std::binary_search(std::begin(ids), std::end(ids), tutorialId);
    }
}

using namespace PathToAscension;

class PathToAscensionWorld final : public WorldScript
{
public:
    PathToAscensionWorld() : WorldScript("PathToAscensionWorld", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        if (!sConfigMgr->GetOption<bool>("PathToAscension.Enable", true))
            return;

        std::string error;
        std::filesystem::path const directory = std::filesystem::path(sWorld->GetDataPath()) / "dbc";
        if (!catalog.Load(directory.string(), error))
        {
            LOG_ERROR("module.pta", "Path to Ascension disabled: {}", error);
            return;
        }

        // The client protocol has been inspected only for this installed catalog.
        if (catalog.Tutorials().size() != ExpectedTutorials || catalog.Quests().size() != ExpectedQuests)
        {
            LOG_ERROR("module.pta", "Path to Ascension disabled: unsupported tutorial catalog ({} rows, {} quests)",
                catalog.Tutorials().size(), catalog.Quests().size());
            return;
        }

        settings.expansion = ContentExpansion();
        settings.clientExpansion = ClientExpansion();
        settings.realm = ReadRealmProfile(sConfigMgr->GetOption<uint32>("PathToAscension.RealmProfile",
            uint32(RealmProfile::PTR)), RealmProfile::PTR);
        settings.client = ClientRealmProfile();
        settings.verifiedProgress = sConfigMgr->GetOption<bool>("PathToAscension.VerifiedProgress.Enable", true);
        settings.rewards = sConfigMgr->GetOption<bool>("PathToAscension.Rewards.Enable", true);
        settings.tracking = sConfigMgr->GetOption<bool>("PathToAscension.Tracking.Enable", true);
        settings.legacyContent = sConfigMgr->GetOption<bool>("PathToAscension.LegacyContent.Enable", false);
        settings.browser = true;
        loaded = true;
        ConfigureRewards();

        LOG_INFO("module.pta", "Path to Ascension loaded {} tutorials and {} quest references (realm profile {}, "
            "client profile {}, expansion {}, client expansion {})", catalog.Tutorials().size(),
            catalog.Quests().size(), uint32(settings.realm), uint32(settings.client), settings.expansion,
            settings.clientExpansion);
    }
};

class PathToAscensionPlayers final : public PlayerScript
{
public:
    PathToAscensionPlayers() : PlayerScript("PathToAscensionPlayers",
        { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_UPDATE,
          PLAYERHOOK_ON_AFTER_STORE_OR_EQUIP_NEW_ITEM, PLAYERHOOK_ON_REWARD_KILL_REWARDER,
          PLAYERHOOK_ON_BEFORE_CRITERIA_PROGRESS, PLAYERHOOK_ON_SEND_LIST_INVENTORY,
          PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST, PLAYERHOOK_ON_LEARN_PET_TALENT, PLAYERHOOK_ON_LEARN_TRAINER_SPELL,
          PLAYERHOOK_ON_TAKE_MAIL_ITEM, PLAYERHOOK_ON_COA_PROGRESS, PLAYERHOOK_ON_PLAYER_QUEST_ACCEPT,
          PLAYERHOOK_ON_COA_PRESTIGE_SAVED }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!loaded || !player->GetSession() || player->GetSession()->IsBot())
            return;

        SendAvailabilityOverrides(player);
        CheckLevelTutorials(player);
    }

    void OnPlayerLevelChanged(Player* player, uint8 /*oldLevel*/) override
    {
        if (loaded)
            CheckLevelTutorials(player);
    }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (!loaded || !CountsForPlayer(player))
            return;

        TutorialRuntime& runtime = Runtime(player);
        if (!runtime.initialized)
        {
            runtime.initialized = true;
            runtime.events.ScheduleEvent(1, Milliseconds(1000));
        }

        runtime.events.Update(diff);
        if (runtime.events.ExecuteEvent())
        {
            CheckStateTutorials(player);
            runtime.events.ScheduleEvent(1, Milliseconds(1000));
        }
    }

    void OnPlayerAfterStoreOrEquipNewItem(Player* player, uint32 /*vendorSlot*/, Item* item, uint8 /*count*/,
        uint8 /*bag*/, uint8 /*slot*/, ItemTemplate const* /*proto*/, Creature* vendor, VendorItem const* vendorItem,
        bool /*store*/) override
    {
        constexpr uint32 Tiraxis = 900007;
        constexpr uint32 BazaarToken = 975001;
        if (!loaded || !item || !vendor || !vendorItem || vendor->GetEntry() != Tiraxis || !vendorItem->ExtendedCost)
            return;

        ItemExtendedCostEntry const* cost = sItemExtendedCostStore.LookupEntry(vendorItem->ExtendedCost);
        if (!cost)
            return;

        for (uint8 index = 0; index < MAX_ITEM_EXTENDED_COST_REQUIREMENTS; ++index)
            if (cost->reqitem[index] == BazaarToken && cost->reqitemcount[index])
            {
                CompleteVerifiedTutorial(player, 30);
                return;
            }
    }

    void OnPlayerRewardKillRewarder(Player* player, KillRewarder* rewarder, bool /*isDungeon*/,
        float& /*rate*/) override
    {
        if (!loaded || !player->IsInWorld())
            return;

        Creature* creature = rewarder->GetVictim() ? rewarder->GetVictim()->ToCreature() : nullptr;
        if (!creature || !creature->IsInWorld())
            return;

        // The same eligibility the core applies to kill credit: grouped players must be alive or corpseless.
        if (player->GetGroup() && !player->IsAlive() && player->GetCorpse())
            return;

        RecordRaidKill(player, creature);
    }

    bool OnPlayerBeforeCriteriaProgress(Player* /*player*/, AchievementCriteriaEntry const* criteria) override
    {
        // Tutorial raid criteria repeat one boss across four difficulties; only a verified kill of the
        // right mode may complete them.
        return !loaded || !criteria || !IsTutorialRaidAchievement(criteria->referredAchievement);
    }

    void OnPlayerSendListInventory(Player* player, ObjectGuid /*vendorGuid*/, uint32& vendorEntry) override
    {
        if (loaded && CountsForPlayer(player) && VendorShowsArenaEquipment(vendorEntry))
        {
            CompleteVerifiedTutorial(player, 24);
            CompleteVerifiedTutorial(player, 249);
        }
    }

    void OnPlayerCompleteQuest(Player* player, Quest const* quest) override
    {
        if (!loaded || !quest || !quest->IsDaily())
            return;

        for (uint32 board : {108606u, 402000u, 402001u, 402002u, 402003u, 412000u, 412001u, 413000u, 422000u,
                 1008002u, 1008008u, 1804480u, 2250000u})
        {
            auto const enders = sObjectMgr->GetGOQuestInvolvedRelationBounds(board);
            for (auto itr = enders.first; itr != enders.second; ++itr)
                if (itr->second == quest->GetQuestId())
                {
                    CompleteVerifiedTutorial(player, 233);
                    return;
                }
        }
    }

    void OnPlayerLearnPetTalent(Player* player, Pet* /*pet*/, uint32 /*spellId*/) override
    {
        if (loaded)
            CompleteVerifiedTutorial(player, 105);
    }

    void OnPlayerLearnTrainerSpell(Player* player, Creature* trainer, uint32 spellId) override
    {
        constexpr uint32 BookOfArtisans = 57500;
        if (!loaded || !trainer)
            return;

        if (trainer->GetEntry() == BookOfArtisans && TeachesNewProfession(spellId))
            CompleteVerifiedTutorial(player, 78);

        if (TeachesHigherRank(spellId))
            CompleteVerifiedTutorial(player, 56);
    }

    void OnPlayerQuestAccept(Player* player, Quest const* quest) override
    {
        constexpr uint32 NoviceRidingCredit = 445303;
        if (loaded && IsStarterMountQuest(quest->GetQuestId()) && player->GetSkillValue(SKILL_RIDING))
            player->KilledMonsterCredit(NoviceRidingCredit);
    }

    void OnPlayerCoAPrestigeSaved(Player* player) override
    {
        if (loaded)
            CompletePrestigeTutorials(player);
    }

    void OnPlayerTakeMailItem(Player* player, Mail const* mail, uint32 itemEntry) override
    {
        if (loaded && CountsForPlayer(player))
            RecordAuctionReceipt(player, mail, itemEntry);
    }

    void OnPlayerCoAProgress(Player* player, CoAProgressEvent event, uint32 value) override
    {
        if (!loaded)
            return;

        switch (event)
        {
            case CoAProgressEvent::ManastormEntered:
                CompleteVerifiedTutorial(player, 219);
                break;
            case CoAProgressEvent::ManastormPurchase:
                switch (value)
                {
                    case 339041: RecordTutorialEvent(player, 225, 1); break;
                    case 1300179: CompleteVerifiedTutorial(player, 226); break;
                    case 339050: CompleteVerifiedTutorial(player, 227); break;
                    case 99269: CompleteVerifiedTutorial(player, 228); break;
                    default: break;
                }
                break;
            case CoAProgressEvent::ManastormPotion:
                CompleteVerifiedTutorial(player, 229);
                break;
            case CoAProgressEvent::ManastormEscape:
                if (EscapedControl(player))
                    CompleteVerifiedTutorial(player, 230);
                break;
            case CoAProgressEvent::ManastormFullLoadout:
                CompleteVerifiedTutorial(player, 231);
                break;
            case CoAProgressEvent::ManastormActiveSlot:
                // Tutorial 232's objective row names the Interrupt Rod slot.
                if (value == 93429 && player->HasSpell(value))
                    CompleteVerifiedTutorial(player, 232);
                break;
            case CoAProgressEvent::ManastormDepthCleared:
                RecordManastormDepth(player, value);
                break;
            case CoAProgressEvent::ClosestResurrection:
                CompleteVerifiedTutorial(player, 193);
                break;
            case CoAProgressEvent::Transmogrified:
                CompleteVerifiedTutorial(player, 6);
                break;
            case CoAProgressEvent::VanityDelivered:
                CompleteVerifiedTutorial(player, 51);
                CompleteVerifiedTutorial(player, 244);
                break;
            case CoAProgressEvent::VanityCollected:
                if (value == 339041)
                    RecordTutorialEvent(player, 225, 2);
                break;
            case CoAProgressEvent::AppearanceCollected:
                RecordAppearance(player, value);
                break;
            case CoAProgressEvent::ExperimentalTeleporter:
                CompleteVerifiedTutorial(player, 31);
                break;
            case CoAProgressEvent::OutfitSaved:
                CompleteVerifiedTutorial(player, 247);
                break;
            case CoAProgressEvent::MysticScrollPurchased:
                RecordMysticExtracting(player, 1);
                break;
            case CoAProgressEvent::MysticScrollReforged:
                RecordMysticReforge(player);
                break;
            case CoAProgressEvent::MysticExtractEarned:
                RecordMysticExtracting(player, 4);
                break;
            case CoAProgressEvent::MysticEnchantExtracted:
                CompleteGameModeTutorial(player, 4);
                CompleteGameModeTutorial(player, 276);
                CheckMysticCollection(player);
                break;
            case CoAProgressEvent::MysticCollectionApplied:
                CompleteGameModeTutorial(player, 39);
                CompleteGameModeTutorial(player, 277);
                CheckMysticSlots(player);
                break;
            case CoAProgressEvent::MysticScrollApplied:
                CompleteGameModeTutorial(player, 52);
                CheckMysticSlots(player);
                break;
            case CoAProgressEvent::MysticPresetActivated:
                CompleteGameModeTutorial(player, 62);
                CheckMysticSlots(player);
                break;
            case CoAProgressEvent::ArchitectOpened:
                RecordArchitect(player, 1);
                break;
            case CoAProgressEvent::BuildActivated:
                RecordBuildActivation(player, value);
                break;
            case CoAProgressEvent::SoloArenaQueued:
                if (value == ARENA_TYPE_2v2)
                    CompleteGameModeTutorial(player, 23);
                break;
            case CoAProgressEvent::WildcardScrollUnlearned:
                CompleteGameModeTutorial(player, value ? 95 : 94);
                break;
            case CoAProgressEvent::WildcardEntryLocked:
                CompleteGameModeTutorial(player, 96);
                break;
            case CoAProgressEvent::WildcardCardPackOpened:
                CompleteGameModeTutorial(player, 97);
                if (value == GoldenAbilityPack)
                    CompleteGameModeTutorial(player, 98);
                break;
            case CoAProgressEvent::WildcardStarterCardSet:
                if (player->GetLevel() < 10)
                    CompleteGameModeTutorial(player, 100);
                break;
            case CoAProgressEvent::WildcardScrollsClaimed:
                CompleteGameModeTutorial(player, 238);
                break;
            case CoAProgressEvent::WildcardScrollsRepurchased:
                CompleteGameModeTutorial(player, 240);
                break;
            case CoAProgressEvent::WildcardRapidRolled:
                CompleteGameModeTutorial(player, 242);
                break;
        }
    }
};

class PathToAscensionSpells final : public AllSpellScript
{
public:
    PathToAscensionSpells() : AllSpellScript("PathToAscensionSpells",
        { ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_BEFORE_EFFECTS, ALLSPELLHOOK_ON_HIT_RESULT }) { }

    void OnSpellCast(Spell* /*spell*/, Unit* caster, SpellInfo const* info, bool /*skipCheck*/) override
    {
        if (!loaded || !info || !caster)
            return;

        // Titan Scroll casts; the adjacent odd IDs are Keeper's Scrolls and do not count.
        switch (info->Id)
        {
            case 993944: case 993956: case 993958: case 993960: case 993962:
                CompleteVerifiedTutorial(caster->ToPlayer(), 33);
                break;
            default:
                break;
        }
    }

    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        constexpr uint32 EscapeSpell = 93311;
        constexpr uint32 EscapeItem = 254042;
        if (!loaded || !info || info->Id != EscapeSpell || !caster)
            return;

        Player* player = caster->ToPlayer();
        if (!player || !player->IsInWorld())
            return;

        TutorialRuntime& runtime = Runtime(player);
        runtime.escapeAuras.clear();
        if (!spell->m_CastItem || spell->m_CastItem->GetEntry() != EscapeItem)
            return;

        uint64 mechanics = 0;
        for (SpellEffectInfo const& effect : info->Effects)
            if (effect.ApplyAuraName == SPELL_AURA_MECHANIC_IMMUNITY && effect.MiscValue > 0 && effect.MiscValue < 64)
                mechanics |= uint64(1) << effect.MiscValue;

        for (auto const& [id, application] : player->GetAppliedAuras())
            if (!application->IsPositive()
                && (application->GetBase()->GetSpellInfo()->GetAllEffectsMechanicMask() & mechanics))
                runtime.escapeAuras.emplace_back(id, application->GetBase()->GetCasterGUID());
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 missInfo, uint32 /*damage*/, uint32 /*healing*/,
        bool /*critical*/) override
    {
        if (!loaded || missInfo != SPELL_MISS_NONE || !target || target != spell->GetCaster())
            return;

        Player* player = target->ToPlayer();
        if (!player)
            return;

        SpellInfo const* info = spell->GetSpellInfo();
        if (info->HasAura(SPELL_AURA_MOUNTED) && player->IsMounted() && player->IsOutdoors())
        {
            CompleteVerifiedTutorial(player, 92);
            CompleteVerifiedTutorial(player, 93);
        }
    }
};

class PathToAscensionInnkeepers final : public AllSpellScript
{
public:
    PathToAscensionInnkeepers() : AllSpellScript("PathToAscensionInnkeepers", { ALLSPELLHOOK_ON_HIT_RESULT }) { }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 missInfo, uint32 /*damage*/, uint32 /*healing*/,
        bool /*critical*/) override
    {
        // NPCHandler::SendBindPoint casts 3286 from the innkeeper after the hearthstone is bound.
        constexpr uint32 BindSpell = 3286;
        if (!loaded || missInfo != SPELL_MISS_NONE || spell->GetSpellInfo()->Id != BindSpell || !target
            || !spell->GetCaster())
            return;

        Creature const* innkeeper = spell->GetCaster()->ToCreature();
        if (innkeeper && innkeeper->HasNpcFlag(UNIT_NPC_FLAG_INNKEEPER))
            CompleteVerifiedTutorial(target->ToPlayer(), 76);
    }
};

class PathToAscensionCreatures final : public AllCreatureScript
{
public:
    PathToAscensionCreatures() : AllCreatureScript("PathToAscensionCreatures") { }

    bool CanCreatureGossipHello(Player* player, Creature* creature) override
    {
        if (loaded)
            RecordNpcVisit(player, creature);
        return false;
    }
};

class PathToAscensionGameObjects final : public AllGameObjectScript
{
public:
    PathToAscensionGameObjects() : AllGameObjectScript("PathToAscensionGameObjects") { }

    bool CanGameObjectGossipHello(Player* player, GameObject* object) override
    {
        if (loaded && IsCallBoard(object->GetEntry()))
        {
            CompleteVerifiedTutorial(player, 79);
            CompleteVerifiedTutorial(player, 81);
        }
        return false;
    }
};

class PathToAscensionDungeons final : public GlobalScript
{
public:
    PathToAscensionDungeons() : GlobalScript("PathToAscensionDungeons",
        { GLOBALHOOK_ON_AFTER_UPDATE_ENCOUNTER_STATE }) { }

    void OnAfterUpdateEncounterState(Map* map, EncounterCreditType /*type*/, uint32 /*creditEntry*/, Unit* source,
        Difficulty /*difficulty*/, std::list<DungeonEncounter const*> const* /*encounters*/, uint32 dungeonId,
        bool /*updated*/) override
    {
        if (!loaded || !dungeonId || !map || !map->IsNonRaidDungeon() || map->IsScriptedPrivateInstance() || !source
            || source->FindMap() != map)
            return;

        auto const* dungeon = sLFGMgr->GetLFGDungeon(dungeonId);
        if (!dungeon || dungeon->map != map->GetId() || dungeon->difficulty != map->GetDifficulty()
            || dungeon->expansion > 2)
            return;

        for (auto const& reference : map->GetPlayers())
        {
            Player* player = reference.GetSource();
            if (!player || !player->IsInWorld() || !player->IsAtGroupRewardDistance(source))
                continue;

            if (map->GetDifficulty() == DUNGEON_DIFFICULTY_NORMAL)
            {
                // An end-game clear: the dungeon's LFG range reaches its expansion's level cap.
                if (dungeon->maxlevel >= 60u + 10u * dungeon->expansion)
                    CompleteVerifiedTutorial(player, 13);
            }
            else if (map->GetDifficulty() == DUNGEON_DIFFICULTY_HEROIC)
            {
                if (dungeon->expansion == 0)
                    CompleteVerifiedTutorial(player, 14);
                else if (dungeon->expansion == 1)
                {
                    CompleteVerifiedTutorial(player, 260);
                    CompleteVerifiedTutorial(player, 41);
                }
                else
                    CompleteVerifiedTutorial(player, 261);
            }
            else if (map->GetDifficulty() == DUNGEON_DIFFICULTY_EPIC)
                CompleteVerifiedTutorial(player, 16);
        }
    }
};

class PathToAscensionBattlegrounds final : public AllBattlegroundScript
{
public:
    PathToAscensionBattlegrounds() : AllBattlegroundScript("PathToAscensionBattlegrounds",
        { ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_END_REWARD }) { }

    void OnBattlegroundEndReward(Battleground* battleground, Player* player, TeamId /*winner*/) override
    {
        if (!loaded)
            return;

        // Finishing a War Game counts on either side; an aborted private transfer never ends one.
        if (battleground->IsWargame())
            CompleteVerifiedTutorial(player, 32);
        else if (!battleground->isArena())
            CompleteVerifiedTutorial(player, 22);
    }
};

void AddPathToAscensionProgressScripts()
{
    new PathToAscensionWorld();
    new PathToAscensionPlayers();
    new PathToAscensionSpells();
    new PathToAscensionInnkeepers();
    new PathToAscensionCreatures();
    new PathToAscensionGameObjects();
    new PathToAscensionDungeons();
    new PathToAscensionBattlegrounds();
}
