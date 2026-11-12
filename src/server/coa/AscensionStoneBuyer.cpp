/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionClientLua.h"
#include "DatabaseEnv.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include <cctype>
#include <mutex>
#include <sstream>
#include <string>
#include <string_view>
#include <unordered_set>

namespace
{
constexpr uint32 RequirementType = 24;
constexpr uint32 RequirementRow = 16267;
constexpr char Token[] = "COA_STONE_BUYER";
constexpr Milliseconds LoginLuaDelay = 5s;

constexpr char StoneBuyerLua[] = R"lua(
if CoAStoneBuyer then
    return
end
CoAStoneBuyer = true

local TOKEN_ITEM = 975001

local STONES = {
    ["aeriepeak"] = {1777036},
    ["agmarshammer"] = {436},
    ["allerianstronghold"] = {102178},
    ["altarofshatar"] = {777018, 102179, 1175646},
    ["ambermill"] = {1780058},
    ["amberpinelodge"] = {458},
    ["area52"] = {777017},
    ["argentstand"] = {441},
    ["argenttournamentgrounds"] = {452},
    ["argentvanguard"] = {456},
    ["astranaar"] = {1780026},
    ["auberdine"] = {1780024},
    ["azjolnerub"] = {437},
    ["azshara"] = {777023},
    ["blackrockmountain"] = {1203467},
    ["blackwatch"] = {454},
    ["bloodhoofvillage"] = {1780055},
    ["bloodvenompost"] = {777021},
    ["bootybay"] = {777008},
    ["brackenwallvillage"] = {1780014},
    ["brill"] = {1780050},
    ["brunnhildarvillage"] = {450},
    ["bulwark"] = {1780059},
    ["campmojache"] = {1777024},
    ["camponeqwah"] = {459},
    ["camptaurajo"] = {1780015},
    ["campwinterhoof"] = {460},
    ["cenarionhold"] = {777013},
    ["cenarionrefuge"] = {102180, 1175643},
    ["chillwindcamp"] = {1880049},
    ["coldarra"] = {425},
    ["conquesthold"] = {439},
    ["cosmowrench"] = {102181},
    ["crossroads"] = {1780016},
    ["dalarancity"] = {777028},
    ["darkshire"] = {1780030},
    ["darnassus"] = {777004},
    ["dolanaar"] = {1780052},
    ["draktharonkeep"] = {442},
    ["dunniffelem"] = {451},
    ["eastvaleloggingcamp"] = {1780031},
    ["emeraldsanctuary"] = {1780023},
    ["evergrove"] = {102182, 1175644},
    ["everlook"] = {777007},
    ["exodar"] = {777015},
    ["falconwatch"] = {102183},
    ["faldirscove"] = {1780045},
    ["farstriderlodge"] = {1780040},
    ["feathermoonstronghold"] = {1777025},
    ["flamecrest"] = {1780056},
    ["forestsong"] = {1780027},
    ["freewindpost"] = {1780012},
    ["frosthold"] = {449},
    ["gadgetzan"] = {777009},
    ["garadar"] = {102184},
    ["gatesofahnqiraj"] = {1203468},
    ["ghostwalkerspost"] = {1780020},
    ["goldshire"] = {1780051, 1880045},
    ["gromarshcrashsite"] = {448},
    ["gromgolbasecamp"] = {1780033},
    ["groveoftheancients"] = {1780025},
    ["gundrak"] = {443},
    ["gurubashiarena"] = {777020},
    ["hammerfall"] = {1780044},
    ["hammertoedigsite"] = {1780039},
    ["harborage"] = {1780057},
    ["honorhold"] = {102185},
    ["icecrowncitadel"] = {455},
    ["ironforge"] = {777005},
    ["k3"] = {447},
    ["karazhan"] = {777031},
    ["kargath"] = {1780038},
    ["kharanos"] = {1780049},
    ["lakeshire"] = {1780036},
    ["lakesidelanding"] = {444},
    ["lightshope"] = {777006},
    ["marshalsrefuge"] = {1780010},
    ["menethilharbor"] = {1780042},
    ["moakiharbor"] = {435},
    ["moonglade"] = {777032},
    ["morgansvigil"] = {1780037},
    ["morshanbasecamp"] = {1780017},
    ["mudsprocket"] = {777012},
    ["naxxramasdragonblight"] = {432},
    ["nesingwarybasecamp"] = {445},
    ["nesingwarysexpedition"] = {1780035},
    ["nethergardekeep"] = {1777026},
    ["newagamand"] = {428},
    ["nijelspoint"] = {1777044},
    ["ogrila"] = {102186},
    ["onyxiaslair"] = {1203469},
    ["oreborharborage"] = {102187},
    ["orgrimmar"] = {777000, 134996},
    ["ragefirechasmorgrimmar"] = {777029},
    ["ratchet"] = {777010},
    ["razorhill"] = {1780054, 1880046},
    ["rebelcamp"] = {1780034},
    ["refugepoint"] = {1780043},
    ["revantuskvillage"] = {1777037},
    ["sanctumofthestars"] = {777019, 102188, 1175645},
    ["senjinvillage"] = {1780053},
    ["sentinelhill"] = {1780032},
    ["sepulcher"] = {1780048},
    ["shadowmoonvillage"] = {102189},
    ["shadowpreyvillage"] = {1777043},
    ["shadowvault"] = {453},
    ["shattrath"] = {777016},
    ["silvermooncity"] = {777014},
    ["southshore"] = {1780046},
    ["splintertreepost"] = {1780028},
    ["starsrest"] = {461},
    ["stockadestormwind"] = {777030},
    ["stonard"] = {1777027},
    ["stonebreakerhold"] = {102190},
    ["stonetalonpeak"] = {1780019},
    ["stormspire"] = {102196},
    ["stormspiredeprecated"] = {777022},
    ["stormwind"] = {777003, 134997},
    ["sunrockretreat"] = {1780018},
    ["swampratpost"] = {102191},
    ["sylvanaar"] = {102192},
    ["talonbranchglade"] = {1880047},
    ["talrendispoint"] = {1780021},
    ["tarrenmill"] = {1780047},
    ["telaar"] = {102193},
    ["telredor"] = {102194},
    ["templeoftelhamat"] = {102195},
    ["thalanaar"] = {1780011},
    ["thelsamar"] = {1780041},
    ["theramoreisle"] = {1780013},
    ["thondrorilriver"] = {1880048},
    ["thoriumpoint"] = {777011},
    ["thrallmar"] = {102197},
    ["thunderbluff"] = {777002},
    ["thunderlordstronghold"] = {102198},
    ["toshleysstation"] = {102199},
    ["ulduar"] = {446},
    ["undercity"] = {777001},
    ["unupe"] = {426},
    ["utgardekeep"] = {429},
    ["valgarde"] = {430},
    ["valiancekeep"] = {424},
    ["valormok"] = {1780022},
    ["vengeancelanding"] = {427},
    ["venomspite"] = {462},
    ["venturebay"] = {438},
    ["warsonghold"] = {423},
    ["westfallbrigadeencampment"] = {440},
    ["westguardkeep"] = {431},
    ["wildhammerstronghold"] = {102200},
    ["wintergardekeep"] = {433},
    ["wyrmresttemple"] = {434},
    ["yojambaisle"] = {1777023},
    ["zabrajin"] = {102201},
    ["zimtorga"] = {457},
    ["zoramgaroutpost"] = {1780029},
    ["zulgurub"] = {1203466},
}

local ZONE_ALIASES = {
    ["arathi"] = {"refugepoint", "hammerfall"},
    ["arathihighlands"] = {"refugepoint", "hammerfall"},
    ["ashenvale"] = {"astranaar"},
    ["azshara"] = {"talrendispoint", "valormok"},
    ["badlands"] = {"kargath"},
    ["barrens"] = {"crossroads", "ratchet", "camptaurajo"},
    ["bladesedgemountains"] = {"sylvanaar", "thunderlordstronghold", "evergrove"},
    ["blastedlands"] = {"nethergardekeep"},
    ["boreantundra"] = {"valiancekeep", "warsonghold"},
    ["burningsteppes"] = {"flamecrest"},
    ["crystalsongforest"] = {"dalarancity"},
    ["darkshore"] = {"auberdine"},
    ["desolace"] = {"nijelspoint", "shadowpreyvillage"},
    ["dragonblight"] = {"wintergardekeep", "wyrmresttemple", "agmarshammer"},
    ["dunmorogh"] = {"kharanos"},
    ["durotar"] = {"razorhill", "senjinvillage"},
    ["duskwood"] = {"darkshire"},
    ["dustwallow"] = {"theramoreisle", "mudsprocket"},
    ["dustwallowmarsh"] = {"theramoreisle", "mudsprocket"},
    ["easternplaguelands"] = {"lightshope"},
    ["elwynn"] = {"goldshire"},
    ["elwynnforest"] = {"goldshire"},
    ["felwood"] = {"emeraldsanctuary", "bloodvenompost"},
    ["feralas"] = {"feathermoonstronghold", "campmojache"},
    ["grizzlyhills"] = {"amberpinelodge", "conquesthold"},
    ["hellfirepeninsula"] = {"honorhold", "thrallmar"},
    ["hillsbrad"] = {"southshore", "tarrenmill"},
    ["hillsbradfoothills"] = {"southshore", "tarrenmill"},
    ["hinterlands"] = {"aeriepeak"},
    ["howlingfjord"] = {"valgarde", "vengeancelanding", "westguardkeep"},
    ["icecrown"] = {"argentvanguard", "shadowvault"},
    ["lochmodan"] = {"thelsamar"},
    ["mulgore"] = {"bloodhoofvillage"},
    ["nagrand"] = {"telaar", "garadar"},
    ["netherstorm"] = {"area52"},
    ["redridge"] = {"lakeshire"},
    ["redridgemountains"] = {"lakeshire"},
    ["searinggorge"] = {"thoriumpoint"},
    ["shadowmoonvalley"] = {"wildhammerstronghold", "shadowmoonvillage"},
    ["sholazarbasin"] = {"nesingwarybasecamp"},
    ["silithus"] = {"cenarionhold"},
    ["silverpine"] = {"sepulcher"},
    ["silverpineforest"] = {"sepulcher"},
    ["stonetalon"] = {"stonetalonpeak", "sunrockretreat"},
    ["stonetalonmountains"] = {"stonetalonpeak", "sunrockretreat"},
    ["stormpeaks"] = {"k3", "frosthold"},
    ["stormwindcity"] = {"stormwind"},
    ["stranglethorn"] = {"bootybay"},
    ["stranglethornvale"] = {"bootybay"},
    ["swampofsorrow"] = {"stonard"},
    ["swampofsorrows"] = {"stonard"},
    ["tanaris"] = {"gadgetzan"},
    ["teldrassil"] = {"dolanaar"},
    ["terokkarforest"] = {"allerianstronghold", "stonebreakerhold"},
    ["thehinterlands"] = {"aeriepeak"},
    ["thestormpeaks"] = {"k3", "frosthold"},
    ["thousandneedles"] = {"freewindpost"},
    ["tirisfal"] = {"brill"},
    ["tirisfalglades"] = {"brill"},
    ["ungoro"] = {"marshalsrefuge"},
    ["ungorocrater"] = {"marshalsrefuge"},
    ["westernplaguelands"] = {"chillwindcamp"},
    ["westfall"] = {"sentinelhill"},
    ["wetlands"] = {"menethilharbor"},
    ["winterspring"] = {"everlook"},
    ["zangarmarsh"] = {"telredor", "zabrajin", "oreborharborage"},
    ["zuldrak"] = {"argentstand", "zimtorga"},
}

local function Norm(s)
    if not s or s == "" then
        return ""
    end
    s = string.lower(s)
    s = s:gsub("^stone of retreat:%s*", "")
    s = s:gsub("^the%s+", "")
    s = s:gsub("[^%w]+", "")
    return s
end

local function Chat(msg)
    local frame = DEFAULT_CHAT_FRAME or ChatFrame1
    if frame then
        frame:AddMessage("|cff33ff99StoneBuyer:|r " .. tostring(msg))
    end
end

local function IsOwned(itemId)
    if not C_VanityCollection then
        return false
    end
    if C_VanityCollection.IsCollectionItemOwned then
        local ok, owned = pcall(C_VanityCollection.IsCollectionItemOwned, itemId)
        if ok and owned then
            return true
        end
    end
    if C_VanityCollection.IsOwned then
        local ok, owned = pcall(C_VanityCollection.IsOwned, itemId)
        if ok and owned then
            return true
        end
    end
    return false
end

local function IdsForName(name)
    local key = Norm(name)
    if key ~= "" and STONES[key] then
        return STONES[key], key
    end
    local aliasList = key ~= "" and ZONE_ALIASES[key]
    if aliasList then
        local ids = {}
        for i = 1, #aliasList do
            local more = STONES[aliasList[i]]
            if more then
                for j = 1, #more do
                    ids[#ids + 1] = more[j]
                end
            end
        end
        if #ids > 0 then
            return ids, key
        end
    end
    return nil, key
end

local function MapNames()
    local names = {}
    local function add(n)
        if n and n ~= "" then
            names[#names + 1] = n
        end
    end
    if WorldMapFrame and WorldMapFrame.areaName then
        add(WorldMapFrame.areaName)
    end
    if WorldMapFrameAreaLabel and WorldMapFrameAreaLabel.GetText then
        add(WorldMapFrameAreaLabel:GetText())
    end
    if GetMapInfo then
        add(GetMapInfo())
    end
    if WorldMapTooltip and WorldMapTooltip.IsShown and WorldMapTooltip:IsShown() then
        if WorldMapTooltipTextLeft1 and WorldMapTooltipTextLeft1.GetText then
            add(WorldMapTooltipTextLeft1:GetText())
        end
    end
    if GameTooltip and GameTooltip.IsShown and GameTooltip:IsShown() then
        if GameTooltipTextLeft1 and GameTooltipTextLeft1.GetText then
            add(GameTooltipTextLeft1:GetText())
        end
    end
    return names
end

local function ItemCost(itemId)
    local priced = PRICES[itemId]
    if type(priced) == "number" and priced > 0 then
        return priced
    end
end

local pendingName, pendingId, pendingCost

local function TryPurchase(itemId, name, cost)
    if C_VanityCollection and C_VanityCollection.PurchaseCollectionItem then
        local ok, err = pcall(C_VanityCollection.PurchaseCollectionItem, itemId)
        if ok then
            if cost then
                Chat("Requested purchase of Stone of Retreat: " .. name .. " (" .. itemId .. ") for "
                    .. cost .. " Bazaar Tokens.")
            else
                Chat("Requested purchase of Stone of Retreat: " .. name .. " (" .. itemId .. ") with Bazaar Tokens.")
            end
            return true
        end
        Chat("Purchase API error: " .. tostring(err))
        return false
    end
    Chat("No purchase API is available.")
    return false
end

StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["STONEBUYER_CONFIRM"] = {
    text = "Buy Stone of Retreat: %s for %s Bazaar Tokens?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        if pendingId and pendingName then
            TryPurchase(pendingId, pendingName, pendingCost)
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}
StaticPopupDialogs["STONEBUYER_CONFIRM_UNPRICED"] = {
    text = "Buy Stone of Retreat: %s with Bazaar Tokens?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        if pendingId and pendingName then
            TryPurchase(pendingId, pendingName, pendingCost)
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

local function BuyForName(name)
    local ids = IdsForName(name)
    if not ids then
        Chat("No Stone of Retreat is listed for \"" .. tostring(name or "?") .. "\".")
        return
    end
    local target
    for i = 1, #ids do
        if not IsOwned(ids[i]) then
            target = ids[i]
            break
        end
    end
    if not target then
        Chat("You already own the stone for " .. name .. ". Shift-click the map to teleport if you have learned it.")
        return
    end
    local cost = ItemCost(target)
    if cost then
        local have = (GetItemCount and GetItemCount(TOKEN_ITEM)) or 0
        if have < cost then
            Chat("You need " .. cost .. " Bazaar Tokens to buy Stone of Retreat: " .. name
                .. " (you have " .. have .. ").")
            return
        end
    end
    pendingName, pendingId, pendingCost = name, target, cost
    if StaticPopup_Show then
        if cost then
            StaticPopup_Show("STONEBUYER_CONFIRM", name, tostring(cost))
        else
            StaticPopup_Show("STONEBUYER_CONFIRM_UNPRICED", name)
        end
    else
        TryPurchase(target, name, cost)
    end
end

local function OnMapClick(button, mouseButton)
    if mouseButton and mouseButton ~= "LeftButton" and mouseButton ~= "LeftButtonDown" then
        return
    end
    if not IsShiftKeyDown or not IsControlKeyDown then
        return
    end
    if not IsShiftKeyDown() or not IsControlKeyDown() then
        return
    end
    local names = MapNames()
    for i = 1, #names do
        if IdsForName(names[i]) then
            BuyForName(names[i])
            return
        end
    end
    BuyForName(names[1] or "this location")
end

local hooked = false
local function HookMap()
    if hooked then
        return
    end
    if hooksecurefunc and WorldMapButton_OnClick then
        hooksecurefunc("WorldMapButton_OnClick", OnMapClick)
        hooked = true
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    HookMap()
end)
HookMap()

SLASH_STONEBUYER1 = "/stonebuyer"
SLASH_STONEBUYER2 = "/sbuy"
SlashCmdList["STONEBUYER"] = function(msg)
    msg = strtrim and strtrim(msg or "") or (msg or "")
    if msg == "" or msg == "help" then
        Chat("Ctrl+Shift-click a zone or pin on the world map to buy its Stone of Retreat "
            .. "with Bazaar Tokens. Or type /stonebuyer <zone name>.")
        return
    end
    BuyForName(msg)
end
)lua";

std::unordered_set<uint32> StoneItemIds()
{
    std::unordered_set<uint32> ids;
    std::string_view const lua = StoneBuyerLua;
    std::size_t const start = lua.find("local STONES = {");
    std::size_t const end = lua.find("local ZONE_ALIASES");
    if (start == std::string_view::npos || end == std::string_view::npos || end <= start)
        return ids;

    std::string_view const block = lua.substr(start, end - start);
    for (std::size_t i = 0; i < block.size();)
    {
        if (std::isdigit(static_cast<unsigned char>(block[i])))
        {
            uint32 value = 0;
            while (i < block.size() && std::isdigit(static_cast<unsigned char>(block[i])))
            {
                value = value * 10u + static_cast<uint32>(block[i] - '0');
                ++i;
            }
            if (value)
                ids.insert(value);
        }
        else
            ++i;
    }
    return ids;
}

std::string PriceTableLua()
{
    static std::mutex lock;
    static std::string cached;
    static bool loaded = false;
    std::lock_guard<std::mutex> guard(lock);
    if (loaded)
        return cached;

    std::unordered_set<uint32> const ids = StoneItemIds();
    std::ostringstream out;
    out << "local PRICES = {";
    bool first = true;
    if (!ids.empty())
    {
        std::ostringstream list;
        bool firstId = true;
        for (uint32 id : ids)
        {
            if (!firstId)
                list << ',';
            firstId = false;
            list << id;
        }
        QueryResult result = WorldDatabase.Query(
            "SELECT `ItemID`, `BazaarTokenCost` FROM `coa_client_vanity_collection` "
            "WHERE `BazaarTokenCost` > 0 AND `ItemID` IN ({})",
            list.str());
        if (result)
        {
            do
            {
                Field const* fields = result->Fetch();
                if (!first)
                    out << ',';
                first = false;
                out << '[' << fields[0].Get<uint32>() << "]=" << fields[1].Get<uint32>();
            } while (result->NextRow());
        }
    }
    out << "}\n";
    cached = out.str();
    loaded = true;
    return cached;
}

std::string BuildStoneBuyerLua()
{
    return PriceTableLua() + StoneBuyerLua;
}

void SendStoneBuyer(Player* player)
{
    if (!player || !player->GetSession() || player->GetSession()->IsBot())
        return;

    RunAscensionClientLua(player, {RequirementType, RequirementRow, Token, BuildStoneBuyerLua()});
}

class AscensionStoneBuyerPlayer final : public PlayerScript
{
public:
    AscensionStoneBuyerPlayer()
        : PlayerScript("coa_stone_buyer_player", {PLAYERHOOK_ON_LOGIN})
    {
    }

    void OnPlayerLogin(Player* player) override
    {
        if (!player->GetSession() || player->GetSession()->IsBot())
            return;

        ObjectGuid const guid = player->GetGUID();
        player->m_Events.AddEventAtOffset([guid]()
        {
            Player* current = ObjectAccessor::FindPlayer(guid);
            if (current && current->IsInWorld())
                SendStoneBuyer(current);
        }, LoginLuaDelay);
    }
};
}

void AddSC_AscensionStoneBuyer()
{
    new AscensionStoneBuyerPlayer();
}
