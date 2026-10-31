/*
 * Copyright (С) since 2019+ AzerothCore <www.azerothcore.org>
 * Licence MIT https://opensource.org/MIT
 */

#include "Battlefield.h"
#include "BattlefieldMgr.h"
#include "Chat.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "CFBG.h"

using namespace Acore::ChatCommands;

class cfbg_commandscript : public CommandScript
{
public:
    cfbg_commandscript() : CommandScript("cfbg_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable cfbgCommands =
        {
            { "race",  HandleCFBGChooseRace, SEC_PLAYER,        Console::No  },
            { "debug", HandleCFBGDebug,      SEC_MODERATOR,     Console::Yes },
        };

        static ChatCommandTable commandTable =
        {
            { "cfbg",  cfbgCommands },
        };

        return commandTable;
    }

    static bool HandleCFBGChooseRace(ChatHandler* handler, std::string raceInput)
    {
        Player* player = handler->GetPlayer();

        uint8 raceId = 0;

        if (sCFBG->RandomizeRaces() || sCFBG->KeepRace())
        {
            handler->SendSysMessage("Race selection is currently disabled.");
            handler->SetSentErrorMessage(true);
            return true;
        }

        for (auto const& raceVariable : *sCFBG->GetRaceInfo())
        {
            if (raceInput == raceVariable.RaceName)
            {
                if (player->GetTeamId(true) == raceVariable.TeamId)
                {
                    raceId = raceVariable.RaceId;
                }
                else
                {
                    handler->SendSysMessage("Race not available to your faction.");
                    handler->SetSentErrorMessage(true);
                    return true;
                }

                if (!IsRaceValidForClass(player, raceId))
                {
                    handler->SendSysMessage("Race not available to your class.");
                    handler->SetSentErrorMessage(true);
                    return true;
                }

                if (raceId == RACE_NIGHTELF)
                {
                    handler->SendSysMessage("Night elf models are not available as the female model is missing and the male one causes client crashes.");
                    handler->SetSentErrorMessage(true);
                    return true;
                }

                if (player->getGender() == GENDER_FEMALE && (raceId == RACE_TROLL || raceId == RACE_DWARF))
                {
                    handler->SendSysMessage("Female models are not available for the following races: troll, dwarf.");
                    handler->SetSentErrorMessage(true);
                    return true;
                }
            }
        }

        player->UpdatePlayerSetting("mod-cfbg", SETTING_CFBG_RACE, raceId);

        if (!raceId)
        {
            handler->SendSysMessage("Race unavailable. CFBG selected race set to random. You will be morphed into a random race when you enter a battleground on the opposite team.");
        }
        else
        {
            handler->PSendSysMessage("CFBG selected race set to {}", raceInput);
        }

        return true;
    }

    static char const* TeamIdName(TeamId t)
    {
        switch (t)
        {
            case TEAM_ALLIANCE: return "Alliance";
            case TEAM_HORDE:    return "Horde";
            default:            return "Neutral";
        }
    }

    static char const* YesNo(bool v) { return v ? "yes" : "no"; }
    static char const* MarkYN(bool v) { return v ? "Y" : "-"; }

    static bool HandleCFBGDebug(ChatHandler* handler, Optional<PlayerIdentifier> player)
    {
        if (!player)
            player = PlayerIdentifier::FromTargetOrSelf(handler);

        if (!player || !player->IsConnected())
        {
            handler->SendErrorMessage(LANG_PLAYER_NOT_FOUND);
            return false;
        }

        Player* target = player->GetConnectedPlayer();
        ObjectGuid const guid = target->GetGUID();

        bool const isFake     = sCFBG->IsPlayerFake(target);
        bool const native     = sCFBG->IsPlayingNative(target);
        bool const forgetBG   = sCFBG->ShouldForgetBGPlayers(target);
        bool const inBG       = target->InBattleground();
        uint8 const preferredRace = target->GetPlayerSetting("mod-cfbg", SETTING_CFBG_RACE).value;
        FakePlayer const* fake = sCFBG->GetFakePlayer(target);

        // === Header ===
        handler->PSendSysMessage("=== CFBG debug: {} ===", target->GetName());
        handler->PSendSysMessage("  GUID: {}", guid.ToString());
        handler->PSendSysMessage("  Config:  System={}  WG={}",
            YesNo(sCFBG->IsEnableSystem()), YesNo(sCFBG->IsEnableWGSystem()));

        // === Faction / appearance ===
        handler->SendSysMessage(" ");
        handler->SendSysMessage("  Faction");
        handler->PSendSysMessage("    Native     {:<8}  (race {})",
            TeamIdName(target->GetTeamId(true)), uint32(target->getRace(true)));
        handler->PSendSysMessage("    Current    {:<8}  (race {})",
            TeamIdName(target->GetTeamId()), uint32(target->getRace()));
        handler->PSendSysMessage("    BG team    {}", TeamIdName(target->GetBgTeamId()));
        handler->PSendSysMessage("    Display    {} (current) / {} (native)",
            target->GetDisplayId(), target->GetNativeDisplayId());

        // === CFBG state ===
        handler->SendSysMessage(" ");
        handler->SendSysMessage("  State");
        handler->PSendSysMessage("    Faked              {}", YesNo(isFake));
        handler->PSendSysMessage("    Playing native     {}", YesNo(native));
        handler->PSendSysMessage("    In battleground    {}", YesNo(inBG));
        handler->PSendSysMessage("    Class / Gender     {} / {}",
            uint32(target->getClass()), uint32(target->getGender()));
        handler->PSendSysMessage("    Preferred race     {}", uint32(preferredRace));
        handler->PSendSysMessage("    Forget BG players  {}", YesNo(forgetBG));

        // === Fake record ===
        if (fake)
        {
            handler->SendSysMessage(" ");
            handler->SendSysMessage("  Fake record");
            handler->PSendSysMessage("    Fake  team={:<8}  race={}  morph={}",
                TeamIdName(fake->FakeTeamID), uint32(fake->FakeRace), fake->FakeMorph);
            handler->PSendSysMessage("    Real  team={:<8}  race={}  morph={}  nativeMorph={}",
                TeamIdName(fake->RealTeamID), uint32(fake->RealRace),
                fake->RealMorph, fake->RealNativeMorph);
        }

        // === Wintergrasp ===
        uint32 const zoneId = target->GetZoneId();
        Battlefield* bf = sBattlefieldMgr->GetBattlefieldToZoneId(zoneId);
        bool const inWGZone = bf && bf->GetTypeId() == BATTLEFIELD_WG;

        // Look up the WG battlefield even when the player is elsewhere, so we
        // can still flag stale fakes outside the zone. 4197 is Wintergrasp.
        Battlefield* wg = inWGZone ? bf : nullptr;
        if (!wg)
            if (Battlefield* candidate = sBattlefieldMgr->GetBattlefieldToZoneId(4197))
                if (candidate->GetTypeId() == BATTLEFIELD_WG)
                    wg = candidate;

        handler->SendSysMessage(" ");
        handler->SendSysMessage("  Wintergrasp");
        handler->PSendSysMessage("    In WG zone   {} (zone {})", YesNo(inWGZone), zoneId);

        if (!wg)
        {
            handler->SendSysMessage("    War time     n/a (no WG battlefield)");
        }
        else
        {
            handler->PSendSysMessage("    War time     {}", YesNo(wg->IsWarTime()));

            bool const inQueueA = wg->GetPlayersQueueSet(TEAM_ALLIANCE).count(guid) > 0;
            bool const inQueueH = wg->GetPlayersQueueSet(TEAM_HORDE).count(guid)    > 0;
            bool const invitedA = wg->GetInvitedPlayersMap(TEAM_ALLIANCE).count(guid) > 0;
            bool const invitedH = wg->GetInvitedPlayersMap(TEAM_HORDE).count(guid)    > 0;
            bool const inWarA   = wg->GetPlayersInWarSet(TEAM_ALLIANCE).count(guid)   > 0;
            bool const inWarH   = wg->GetPlayersInWarSet(TEAM_HORDE).count(guid)      > 0;

            handler->SendSysMessage("    Player in sets:");
            handler->PSendSysMessage("                   Alliance  Horde");
            handler->PSendSysMessage("      Queue           {}        {}", MarkYN(inQueueA), MarkYN(inQueueH));
            handler->PSendSysMessage("      Invited         {}        {}", MarkYN(invitedA), MarkYN(invitedH));
            handler->PSendSysMessage("      In war          {}        {}", MarkYN(inWarA),   MarkYN(inWarH));

            // Which side does core track this player on, if any?
            bool const onA = inWarA || invitedA || inQueueA;
            bool const onH = inWarH || invitedH || inQueueH;
            std::optional<TeamId> coreTeam;
            if (onA) coreTeam = TEAM_ALLIANCE;
            if (onH) coreTeam = TEAM_HORDE;
            bool const inBothSides = onA && onH;

            // ---- Oddity scan ----
            std::vector<std::string> issues;

            if (inBothSides)
                issues.emplace_back("Tracked on BOTH Alliance and Horde WG sets (set leak)");

            if (fake && fake->FakeTeamID == fake->RealTeamID)
                issues.emplace_back(Acore::StringFormat(
                    "Stale fake record: FakeTeamID == RealTeamID ({})",
                    TeamIdName(fake->FakeTeamID)));

            if (coreTeam && !inBothSides && target->GetTeamId() != *coreTeam)
                issues.emplace_back(Acore::StringFormat(
                    "Current team ({}) does not match core WG side ({})",
                    TeamIdName(target->GetTeamId()), TeamIdName(*coreTeam)));

            if (fake && coreTeam && !inBothSides && fake->FakeTeamID != *coreTeam)
                issues.emplace_back(Acore::StringFormat(
                    "Fake team ({}) does not match core WG side ({})",
                    TeamIdName(fake->FakeTeamID), TeamIdName(*coreTeam)));

            if (isFake && fake)
            {
                bool const inRealWarSet = (fake->RealTeamID == TEAM_ALLIANCE) ? inWarA : inWarH;
                bool const inFakeWarSet = (fake->FakeTeamID == TEAM_ALLIANCE) ? inWarA : inWarH;
                if (inRealWarSet && !inFakeWarSet && fake->FakeTeamID != fake->RealTeamID)
                    issues.emplace_back(Acore::StringFormat(
                        "Faked {} but sitting in core {} war set (battlegroup desync)",
                        TeamIdName(fake->FakeTeamID), TeamIdName(fake->RealTeamID)));
            }

            if (inWGZone && wg->IsWarTime() && isFake && !inWarA && !inWarH && !invitedA && !invitedH)
                issues.emplace_back("Faked in WG zone during war but absent from war/invited sets");

            if (isFake && !inWGZone && !inBG)
                issues.emplace_back("Faked outside WG zone with no battleground (cleanup leak)");

            if (inWGZone && isFake && !sCFBG->IsEnableWGSystem())
                issues.emplace_back("Faked in WG zone but CFBG.Battlefield.Enable=0");

            handler->SendSysMessage(" ");
            if (issues.empty())
            {
                handler->SendSysMessage("  Oddities: none");
            }
            else
            {
                handler->PSendSysMessage("  Oddities ({}):", uint32(issues.size()));
                for (std::string const& msg : issues)
                    handler->PSendSysMessage("    ! {}", msg);
            }
        }

        return true;
    }

    static bool IsRaceValidForClass(Player* player, uint8 fakeRace)
    {
        RaceData const& raceData = sCFBG->GetRaceDataForClass(player->getClass());

        std::vector<uint8> const& availableRacesForClass = player->GetTeamId(true) == TEAM_HORDE ?
            raceData.availableRacesA : raceData.availableRacesH;

        for (auto const& races : availableRacesForClass)
        {
            if (races == fakeRace)
            {
                return true;
            }
        }

        return false;
    }
};

void AddSC_cfbg_commandscript()
{
    new cfbg_commandscript();
}

class cfbg_bf_commandscript : public CommandScript
{
public:
    cfbg_bf_commandscript() : CommandScript("cfbg_bf_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable bfSubCommands =
        {
            { "list", HandleBFList, SEC_ADMINISTRATOR, Console::No },
        };

        static ChatCommandTable commandTable =
        {
            { "bf", bfSubCommands },
        };

        return commandTable;
    }

    static bool HandleBFList(ChatHandler* handler, uint32 battleId)
    {
        Battlefield* bf = sBattlefieldMgr->GetBattlefieldByBattleId(battleId);

        if (!bf)
        {
            handler->SendErrorMessage("Battlefield {} not found.", battleId);
            return false;
        }

        uint32 const allianceZone = bf->GetPlayersInZoneCount(TEAM_ALLIANCE);
        uint32 const hordeZone    = bf->GetPlayersInZoneCount(TEAM_HORDE);
        uint32 const allianceWar  = bf->GetPlayersInWarCount(TEAM_ALLIANCE);
        uint32 const hordeWar     = bf->GetPlayersInWarCount(TEAM_HORDE);
        uint32 const maxPerTeam   = bf->GetMaxPlayersPerTeam();

        handler->SendSysMessage(Acore::StringFormat("Battlefield {} | {}", battleId,
            bf->IsWarTime() ? "WAR" : "PEACE").c_str());
        handler->SendSysMessage(Acore::StringFormat("  Alliance: {} in zone, {} in war / {} max",
            allianceZone, allianceWar, maxPerTeam).c_str());
        handler->SendSysMessage(Acore::StringFormat("  Horde:    {} in zone, {} in war / {} max",
            hordeZone, hordeWar, maxPerTeam).c_str());

        return true;
    }
};

void AddSC_cfbg_bf_commandscript()
{
    new cfbg_bf_commandscript();
}
