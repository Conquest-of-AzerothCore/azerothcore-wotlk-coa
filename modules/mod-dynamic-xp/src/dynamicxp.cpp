/*
Credits
Script reworked by Micrah/Milestorme and Poszer (Poszer is the Best)
Module Created by Micrah/Milestorme
Original Script from AshmaneCore https://github.com/conan513 Single Player Project

Local additions:
  * ".xp <rate>" lets a player pick their own rate from the list in Dynamic.XP.Preset.Allowed, or go back to the
    realm's rate. A game master sets the realm value with ".xp realm <rate>", which stays the default for every
    character without a personal choice.
  * an optional reminder about ".xp", told to a player when they log in and broadcast to
    the realm every Dynamic.XP.Reminder.Interval minutes.
*/

#include "Chat.h"
#include "CommandScript.h"
#include "Configuration/Config.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "StringConvert.h"
#include "Tokenize.h"

#include <atomic>
#include <cmath>
#include <fstream>
#include <string>
#include <string_view>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
    /// A flat multiplier on the experience the realm grants; 1 leaves it unchanged.
    constexpr uint32 PRESET_REALM_DEFAULT = 1;
    constexpr char PRESET_CONFIG_KEY[] = "Dynamic.XP.Preset";
    constexpr char PRESET_CONFIG_FILE[] = "modules/dynamicxp.conf";
    constexpr char PLAYER_CHOICE_CONFIG_KEY[] = "Dynamic.XP.Preset.PlayerChoice";
    constexpr char ALLOWED_CONFIG_KEY[] = "Dynamic.XP.Preset.Allowed";
    constexpr char ALLOWED_DEFAULT[] = "1,2,3,4,5";
    /// The highest rate the offered list can hold: g_allowedRates keeps one bit per rate.
    constexpr uint32 PRESET_MAX = 31;

    /// A character's own choice, stored as preset + 1 so that zero means "no personal
    /// choice yet". A stored rate that is no longer offered falls back to the realm's.
    ///
    /// The "core." prefix is required, not cosmetic: Player::_SavePlayerSettings and
    /// _LoadCharacterSettings drop every source that does not start with it while
    /// EnablePlayerSettings is 0, which is how this realm runs. A name without the
    /// prefix is held in memory, then silently lost on relog.
    constexpr char PLAYER_PRESET_SETTING[] = "core.dynamic_xp.preset";

    constexpr char REMINDER_ENABLE_KEY[] = "Dynamic.XP.Reminder.Enable";
    constexpr char REMINDER_INTERVAL_KEY[] = "Dynamic.XP.Reminder.Interval";
    constexpr char REMINDER_MESSAGE_KEY[] = "Dynamic.XP.Reminder.Message";

    /// -1 until the value has been read from the config. XP is granted on several map
    /// threads at once, so the realm value is cached in an atomic rather than re-read.
    std::atomic<int32> g_realmPresetCache{-1};

    /// Bit n is set when xn is offered; 0 until the list has been read from the config.
    std::atomic<uint32> g_allowedRates{0};

    /// Milliseconds since the last periodic reminder. World thread only.
    uint32 g_sinceReminder = 0;

    /// The realm default is always offered, so a fallback to it is always valid.
    uint32 AllowedRatesFromConfig()
    {
        uint32 rates = 1u << PRESET_REALM_DEFAULT;
        std::string const list = sConfigMgr->GetOption<std::string>(ALLOWED_CONFIG_KEY, ALLOWED_DEFAULT);
        for (std::string_view token : Acore::Tokenize(list, ',', false))
        {
            size_t const first = token.find_first_not_of(" \t");
            if (first == std::string_view::npos)
                continue;

            token = token.substr(first, token.find_last_not_of(" \t") - first + 1);
            Optional<uint32> const rate = Acore::StringTo<uint32>(token);
            if (rate && *rate >= 1 && *rate <= PRESET_MAX)
                rates |= 1u << *rate;
        }
        return rates;
    }

    uint32 AllowedRates()
    {
        uint32 const cached = g_allowedRates.load(std::memory_order_relaxed);
        if (cached)
            return cached;

        uint32 const rates = AllowedRatesFromConfig();
        g_allowedRates.store(rates, std::memory_order_relaxed);
        return rates;
    }

    bool IsKnownPreset(uint32 preset)
    {
        return preset >= 1 && preset <= PRESET_MAX && (AllowedRates() & (1u << preset));
    }

    /// "|cff4CFF00.xp 1|r, |cff4CFF00.xp 2|r or |cff4CFF00.xp 3|r" for the offered rates.
    std::string DescribeAllowed(std::string_view command)
    {
        std::vector<std::string> choices;
        uint32 const rates = AllowedRates();
        for (uint32 rate = 1; rate <= PRESET_MAX; ++rate)
            if (rates & (1u << rate))
                choices.push_back("|cff4CFF00" + std::string(command) + " " + std::to_string(rate) + "|r");

        std::string text;
        for (size_t i = 0; i < choices.size(); ++i)
        {
            if (i)
                text += i + 1 == choices.size() ? " or " : ", ";
            text += choices[i];
        }
        return text;
    }

    uint32 PresetFromConfig()
    {
        uint32 const preset = sConfigMgr->GetOption<uint32>(PRESET_CONFIG_KEY, PRESET_REALM_DEFAULT);
        return IsKnownPreset(preset) ? preset : PRESET_REALM_DEFAULT;
    }

    uint32 RealmPreset()
    {
        int32 const cached = g_realmPresetCache.load(std::memory_order_relaxed);
        if (cached >= 0)
            return uint32(cached);

        uint32 const preset = PresetFromConfig();
        g_realmPresetCache.store(int32(preset), std::memory_order_relaxed);
        return preset;
    }

    void RefreshFromConfig()
    {
        g_allowedRates.store(AllowedRatesFromConfig(), std::memory_order_relaxed);
        g_realmPresetCache.store(int32(PresetFromConfig()), std::memory_order_relaxed);
    }

    bool PlayersMayChoose()
    {
        return sConfigMgr->GetOption<bool>(PLAYER_CHOICE_CONFIG_KEY, true);
    }

    /// A character's own choice. False when they have never made one.
    bool PersonalPreset(Player const *player, uint32 &preset)
    {
        if (!player)
            return false;

        PlayerSettingVector const *values = player->FindPlayerSettings(PLAYER_PRESET_SETTING);
        if (!values || values->empty())
            return false;

        uint32 const stored = (*values)[0].value;
        if (!stored)
            return false;

        preset = stored - 1;
        return IsKnownPreset(preset);
    }

    /// A stored rate that is no longer offered is dropped for good, so the character follows the realm even if
    /// that rate is offered again later.
    void DropWithdrawnPreset(Player *player)
    {
        PlayerSettingVector const *values = player->FindPlayerSettings(PLAYER_PRESET_SETTING);
        if (!values || values->empty() || !(*values)[0].value)
            return;

        if (!IsKnownPreset((*values)[0].value - 1))
            player->UpdatePlayerSetting(PLAYER_PRESET_SETTING, 0, 0);
    }

    void StorePersonalPreset(Player *player, uint32 preset)
    {
        if (player)
            player->UpdatePlayerSetting(PLAYER_PRESET_SETTING, 0, preset + 1);
    }

    void ClearPersonalPreset(Player *player)
    {
        if (player)
            player->UpdatePlayerSetting(PLAYER_PRESET_SETTING, 0, 0);
    }

    /// The rate that applies to this character: their own choice, else the realm's.
    uint32 EffectivePreset(Player const *player)
    {
        uint32 preset = 0;
        if (PlayersMayChoose() && PersonalPreset(player, preset))
            return preset;
        return RealmPreset();
    }

    std::string DescribePreset(uint32 preset)
    {
        return "x" + std::to_string(preset);
    }

    void ApplyPreset(uint32 &amount, uint32 preset)
    {
        if (preset > 1)
            amount = static_cast<uint32>(std::round(amount * preset));
    }

    /// Writes the realm value into this module's config so a restart keeps it. Only the
    /// "Dynamic.XP.Preset" line is rewritten: the rest of the file stays as the operator
    /// wrote it. The line is appended when the file does not have it.
    /// Returns whether the file now holds the value; \p path always names the file.
    bool PersistRealmPreset(uint32 preset, std::string &path)
    {
        path = sConfigMgr->GetConfigPath() + PRESET_CONFIG_FILE;

        std::vector<std::string> lines;
        bool replaced = false;
        std::ifstream input(path);
        if (input)
        {
            std::string line;
            while (std::getline(input, line))
            {
                size_t const first = line.find_first_not_of(" \t");
                if (!replaced && first != std::string::npos &&
                    line.compare(first, sizeof(PRESET_CONFIG_KEY) - 1, PRESET_CONFIG_KEY) == 0)
                {
                    lines.push_back(std::string(PRESET_CONFIG_KEY) + " = " +
                                    std::to_string(preset));
                    replaced = true;
                    continue;
                }
                lines.push_back(line);
            }
            input.close();
        }

        std::ofstream output(path, replaced ? std::ios::trunc : std::ios::app);
        if (!output)
            return false;

        if (replaced)
        {
            for (std::string const &entry : lines)
                output << entry << '\n';
        }
        else
        {
            output << '\n' << PRESET_CONFIG_KEY << " = " << preset << '\n';
        }

        return output.good();
    }

    bool ReminderEnabled()
    {
        return sConfigMgr->GetOption<bool>(REMINDER_ENABLE_KEY, true);
    }

    std::string ReminderText()
    {
        std::string text = sConfigMgr->GetOption<std::string>(REMINDER_MESSAGE_KEY, "");
        if (!text.empty())
            return text;

        return "|cff4CFF00XP rate|r: pick your own with " + DescribeAllowed(".xp") +
               ", or |cff4CFF00.xp default|r to follow the realm. |cff4CFF00.xp|r shows what you are on.";
    }

    /// One announcement, to every player who is online and has not turned automatic
    /// announcements off (the same switch the realm's autobroadcast honours).
    void BroadcastReminder()
    {
        if (!ReminderEnabled())
            return;

        std::string const text = ReminderText();
        ChatHandler(nullptr).DoForAllValidSessions([&text](Player *player)
        {
            ChatHandler(player->GetSession()).SendWorldTextOptional(
                text, ANNOUNCER_FLAG_DISABLE_AUTOBROADCAST);
        });

        LOG_INFO("module.dynamic_xp", "Announced the .xp reminder to the realm.");
    }
}

class spp_dynamic_xp_rate : public PlayerScript
{
public:
    spp_dynamic_xp_rate() : PlayerScript("spp_dynamic_xp_rate", {
        PLAYERHOOK_ON_LOGIN,
        PLAYERHOOK_ON_GIVE_EXP
    }) { };

    void OnPlayerLogin(Player* player) override
    {
        DropWithdrawnPreset(player);

        // Told to the player who just arrived, not broadcast to the realm: a realm with bots logs
        // characters in and out constantly, and each login announced to everybody filled the chat.
        if (ReminderEnabled() && !player->GetSession()->IsBot())
            ChatHandler(player->GetSession()).SendSysMessage(ReminderText().c_str());

        if (!sConfigMgr->GetOption<bool>("Dynamic.XP.Rate.Announce", false))
            return;

        ChatHandler(player->GetSession()).PSendSysMessage(
            "This server is running a |cff4CFF00{}|r XP rate. Type |cff4CFF00.xp|r to "
            "change your own.", DescribePreset(EffectivePreset(player)));
    }

    void OnPlayerGiveXP(Player* player, uint32& amount, Unit* /*victim*/, uint8 /*xpSource*/) override
    {
        ApplyPreset(amount, EffectivePreset(player));
    }
};

/// Configs are loaded before this runs, at startup and on ".reload config", so an edit
/// of dynamicxp.conf by hand takes effect without a restart.
class spp_dynamic_xp_config : public WorldScript
{
public:
    spp_dynamic_xp_config() : WorldScript("spp_dynamic_xp_config") { }

    void OnBeforeConfigLoad(bool /*reload*/) override
    {
        RefreshFromConfig();
    }

    void OnUpdate(uint32 diff) override
    {
        uint32 const minutes = sConfigMgr->GetOption<uint32>(REMINDER_INTERVAL_KEY, 40);
        if (!minutes)
            return;

        g_sinceReminder += diff;
        if (g_sinceReminder < minutes * 60 * 1000)
            return;

        g_sinceReminder = 0;
        BroadcastReminder();
    }
};

class dynamic_xp_commandscript : public CommandScript
{
public:
    dynamic_xp_commandscript() : CommandScript("dynamic_xp_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable const xpCommandTable =
        {
            { "default", HandleMineDefault,  SEC_PLAYER,     Console::No },
            { "realm",   HandleRealm,        SEC_GAMEMASTER, Console::Yes },
            { "",        HandleMine,         SEC_PLAYER,     Console::No },
        };

        static ChatCommandTable const commandTable =
        {
            { "xp", xpCommandTable },
        };
        return commandTable;
    }

private:
    // --- a player's own rate -------------------------------------------------

    static bool SetMine(ChatHandler* handler, uint32 preset)
    {
        Player* player = handler ? handler->GetPlayer() : nullptr;
        if (!player)
            return false;

        if (!PlayersMayChoose())
        {
            handler->SendSysMessage(
                "Choosing your own XP rate is turned off on this realm; ask a game master.");
            return true;
        }

        if (!IsKnownPreset(preset))
        {
            handler->SendErrorMessage("{} is not offered on this realm. Pick {}.", DescribePreset(preset),
                                      DescribeAllowed(".xp"));
            return false;
        }

        StorePersonalPreset(player, preset);
        handler->PSendSysMessage("Your XP rate is now |cff4CFF00{}|r, saved for this character.",
                                 DescribePreset(preset));
        return true;
    }

    static bool HandleMine(ChatHandler* handler, Optional<uint32> rate)
    {
        return rate ? SetMine(handler, *rate) : ShowMine(handler);
    }

    static bool HandleMineDefault(ChatHandler* handler)
    {
        Player* player = handler ? handler->GetPlayer() : nullptr;
        if (!player)
            return false;

        ClearPersonalPreset(player);
        handler->PSendSysMessage("Your XP rate now follows the realm: |cff4CFF00{}|r.",
                                 DescribePreset(RealmPreset()));
        return true;
    }

    static bool ShowMine(ChatHandler* handler)
    {
        Player* player = handler ? handler->GetPlayer() : nullptr;
        if (!player)
            return false;

        uint32 personal = 0;
        bool const owns = PlayersMayChoose() && PersonalPreset(player, personal);

        handler->PSendSysMessage("Your XP rate: |cff4CFF00{}|r ({}).",
                                 DescribePreset(EffectivePreset(player)),
                                 owns ? "your own choice" : "the realm rate");
        if (owns)
            handler->PSendSysMessage("The realm rate is {}. |cff4CFF00.xp default|r "
                                     "follows it again.", DescribePreset(RealmPreset()));
        if (PlayersMayChoose())
            handler->PSendSysMessage("Pick yours with {}.", DescribeAllowed(".xp"));
        return true;
    }

    // --- the realm's rate, for game masters ----------------------------------

    static bool SetRealm(ChatHandler* handler, uint32 preset)
    {
        if (!handler)
            return false;

        if (!IsKnownPreset(preset))
        {
            handler->SendErrorMessage("{} is not offered on this realm. Pick {}.", DescribePreset(preset),
                                      DescribeAllowed(".xp realm"));
            return false;
        }

        std::string path;
        bool const persisted = PersistRealmPreset(preset, path);
        // Apply it for this session even when the file could not be written, so the
        // switch always does what the operator asked for.
        g_realmPresetCache.store(int32(preset), std::memory_order_relaxed);

        if (preset == 1)
            handler->PSendSysMessage(
                "The realm rate is back to |cff4CFF00x1|r: no bonus is applied.");
        else
            handler->PSendSysMessage("The realm rate is now |cff4CFF00{}|r.",
                                     DescribePreset(preset));

        if (persisted)
            handler->PSendSysMessage("Saved to {}. Characters with their own choice keep it.",
                                     path);
        else
            handler->PSendSysMessage("Could not write {}; the change lasts until the next "
                                     "restart.", path);
        return true;
    }

    static bool HandleRealm(ChatHandler* handler, Optional<uint32> rate)
    {
        return rate ? SetRealm(handler, *rate) : ShowRealm(handler);
    }

    static bool ShowRealm(ChatHandler* handler)
    {
        if (!handler)
            return false;

        handler->PSendSysMessage("Realm XP rate: |cff4CFF00{}|r (the default for every "
                                 "character without its own choice).",
                                 DescribePreset(RealmPreset()));
        handler->PSendSysMessage("Change it with {}.", DescribeAllowed(".xp realm"));
        return true;
    }
};

void AddSC_dynamic_xp_rate()
{
    new spp_dynamic_xp_rate();
    new spp_dynamic_xp_config();
    new dynamic_xp_commandscript();
}
