/*
 * Stone of Retreat faction table - generated, do not hand-edit lightly.
 *
 * Each hub row was classified from the NPCs standing at the destination
 * (their FactionTemplate group mask: Alliance / Horde / neither) and then
 * reviewed; shared sites (Dalaran, Shattrath, Argent Tournament, Light's
 * Hope, instance terraces) are BOTH, and a few faction camps whose only
 * nearby NPCs are holiday guests or a single quest giver are set by hand.
 *
 * Regenerate from Database/Custom/stone-of-retreat-destinations.sql +
 * creature spawns if the destination list changes.
 */
#ifndef MOD_TELEPORT_ACTIONBAR_STONE_FACTION_DATA_H
#define MOD_TELEPORT_ACTIONBAR_STONE_FACTION_DATA_H

#include <cstdint>

namespace StoneFaction
{
enum Side : uint8
{
    Both = 0,
    Alliance = 1,
    Horde = 2
};

struct Entry
{
    uint32 Spell;
    uint8 Side;
    char const* Hub;
};

// Teleport spell learned by a Stone of Retreat item -> the side that may use it.
inline constexpr Entry TeleportFactions[] =
{
    { 777018  , Both    , "Altar of Sha'tar" },
    { 102179  , Both    , "Altar of Shatar" },
    { 1777093 , Both    , "Ambermill" },
    { 777017  , Both    , "Area 52" },
    { 76905   , Both    , "Argent Tournament Grounds" },
    { 76890   , Both    , "Azjol-Nerub" },
    { 777023  , Both    , "Azshara" },
    { 777025  , Both    , "Blackrock Mountain" },
    { 76907   , Both    , "Blackwatch" },
    { 777008  , Both    , "Booty Bay" },
    { 76903   , Both    , "Brunnhildar Village" },
    { 777013  , Both    , "Cenarion Hold" },
    { 102180  , Both    , "Cenarion Refuge" },
    { 76878   , Both    , "Coldarra" },
    { 102181  , Both    , "Cosmowrench" },
    { 777028  , Both    , "Dalaran City" },
    { 76895   , Both    , "Drak'Tharon Keep" },
    { 76904   , Both    , "Dun Niffelem" },
    { 1777058 , Both    , "Emerald Sanctuary" },
    { 102182  , Both    , "Evergrove" },
    { 777007  , Both    , "Everlook" },
    { 1777080 , Both    , "Faldir's Cove" },
    { 777009  , Both    , "Gadgetzan" },
    { 777026  , Both    , "Gates of Ahn'Qiraj" },
    { 76896   , Both    , "Gundrak" },
    { 777020  , Both    , "Gurubashi Arena" },
    { 1777074 , Both    , "Hammertoe Digsite" },
    { 76908   , Both    , "Icecrown Citadel" },
    { 76900   , Both    , "K3" },
    { 777031  , Both    , "Karazhan" },
    { 76897   , Both    , "Lakeside Landing" },
    { 777006  , Both    , "Light's Hope" },
    { 1777045 , Both    , "Marshal's Refuge" },
    { 76888   , Both    , "Moa'ki Harbor" },
    { 777032  , Both    , "Moonglade" },
    { 777012  , Both    , "Mudsprocket" },
    { 76885   , Both    , "Naxxramas (Dragonblight)" },
    { 76898   , Both    , "Nesingwary Base Camp" },
    { 1777070 , Both    , "Nesingwary's Expedition" },
    { 102186  , Both    , "Ogri'la" },
    { 777027  , Both    , "Onyxia's Lair" },
    { 777010  , Both    , "Ratchet" },
    { 102188  , Both    , "Sanctum of the Stars" },
    { 777019  , Both    , "Sanctum of the Stars" },
    { 777016  , Both    , "Shattrath" },
    { 1777054 , Both    , "Stonetalon Peak" },
    { 777030  , Both    , "Stockade (Stormwind)" },
    { 777022  , Both    , "Stormspire (Deprecated)" },
    { 76894   , Both    , "The Argent Stand" },
    { 76909   , Both    , "The Argent Vanguard" },
    { 76906   , Both    , "The Shadow Vault" },
    { 102196  , Both    , "The Stormspire" },
    { 76917   , Both    , "Thondroril River" },
    { 777011  , Both    , "Thorium Point" },
    { 102199  , Both    , "Toshley's Station" },
    { 76899   , Both    , "Ulduar" },
    { 76879   , Both    , "Unu'pe" },
    { 76882   , Both    , "Utgarde Keep" },
    { 76887   , Both    , "Wyrmrest Temple" },
    { 1777023 , Both    , "Yojamba Isle" },
    { 76910   , Both    , "Zim'Torga" },
    { 777024  , Both    , "Zul'Gurub" },
    { 1777036 , Alliance, "Aerie Peak" },
    { 102178  , Alliance, "Allerian Stronghold" },
    { 76911   , Alliance, "Amberpine Lodge" },
    { 1777061 , Alliance, "Astranaar" },
    { 1777059 , Alliance, "Auberdine" },
    { 76918   , Alliance, "Chillwind Camp" },
    { 1777065 , Alliance, "Darkshire" },
    { 777004  , Alliance, "Darnassus" },
    { 1777087 , Alliance, "Dolanaar" },
    { 1777066 , Alliance, "Eastvale Logging Camp" },
    { 1777075 , Alliance, "Farstrider Lodge" },
    { 1777025 , Alliance, "Feathermoon Stronghold" },
    { 1777062 , Alliance, "Forest Song" },
    { 76902   , Alliance, "Frosthold" },
    { 1777086 , Alliance, "Goldshire" },
    { 1777060 , Alliance, "Grove of the Ancients" },
    { 102185  , Alliance, "Honor Hold" },
    { 777005  , Alliance, "Ironforge" },
    { 1777084 , Alliance, "Kharanos" },
    { 1777071 , Alliance, "Lakeshire" },
    { 1777077 , Alliance, "Menethil Harbor" },
    { 1777072 , Alliance, "Morgan's Vigil" },
    { 1777026 , Alliance, "Nethergarde Keep" },
    { 1777044 , Alliance, "Nijel's Point" },
    { 102187  , Alliance, "Orebor Harborage" },
    { 1777069 , Alliance, "Rebel Camp" },
    { 1777078 , Alliance, "Refuge Point" },
    { 1777067 , Alliance, "Sentinel Hill" },
    { 1777081 , Alliance, "Southshore" },
    { 76914   , Alliance, "Stars' Rest" },
    { 777003  , Alliance, "Stormwind" },
    { 102192  , Alliance, "Sylvanaar" },
    { 76916   , Alliance, "Talonbranch Glade" },
    { 1777056 , Alliance, "Talrendis Point" },
    { 102193  , Alliance, "Telaar" },
    { 102194  , Alliance, "Telredor" },
    { 102195  , Alliance, "Temple of Telhamat" },
    { 1777046 , Alliance, "Thalanaar" },
    { 777015  , Alliance, "The Exodar" },
    { 1777092 , Alliance, "The Harborage" },
    { 1777076 , Alliance, "Thelsamar" },
    { 1777048 , Alliance, "Theramore Isle" },
    { 76883   , Alliance, "Valgarde" },
    { 76877   , Alliance, "Valiance Keep" },
    { 76893   , Alliance, "Westfall Brigade Encampment" },
    { 76884   , Alliance, "Westguard Keep" },
    { 102200  , Alliance, "Wildhammer Stronghold" },
    { 76886   , Alliance, "Wintergarde Keep" },
    { 76889   , Horde   , "Agmar's Hammer" },
    { 1777090 , Horde   , "Bloodhoof Village" },
    { 777021  , Horde   , "Bloodvenom Post" },
    { 1777049 , Horde   , "Brackenwall Village" },
    { 1777085 , Horde   , "Brill" },
    { 1777024 , Horde   , "Camp Mojache" },
    { 76912   , Horde   , "Camp Oneqwah" },
    { 1777050 , Horde   , "Camp Taurajo" },
    { 76913   , Horde   , "Camp Winterhoof" },
    { 76892   , Horde   , "Conquest Hold" },
    { 102183  , Horde   , "Falcon Watch" },
    { 1777091 , Horde   , "Flame Crest" },
    { 1777047 , Horde   , "Freewind Post" },
    { 102184  , Horde   , "Garadar" },
    { 1777055 , Horde   , "Ghost Walker's Post" },
    { 76901   , Horde   , "Grom'arsh Crash-Site" },
    { 1777068 , Horde   , "Grom'gol Basecamp" },
    { 1777079 , Horde   , "Hammerfall" },
    { 1777073 , Horde   , "Kargath" },
    { 1777052 , Horde   , "Mor'shan Base Camp" },
    { 76881   , Horde   , "New Agamand" },
    { 777000  , Horde   , "Orgrimmar" },
    { 777029  , Horde   , "Ragefire Chasm (Orgrimmar)" },
    { 1777089 , Horde   , "Razor Hill" },
    { 1777037 , Horde   , "Revantusk Village" },
    { 1777088 , Horde   , "Sen'jin Village" },
    { 102189  , Horde   , "Shadowmoon Village" },
    { 1777043 , Horde   , "Shadowprey Village" },
    { 777014  , Horde   , "Silvermoon City" },
    { 1777063 , Horde   , "Splintertree Post" },
    { 1777027 , Horde   , "Stonard" },
    { 102190  , Horde   , "Stonebreaker Hold" },
    { 1777053 , Horde   , "Sun Rock Retreat" },
    { 102191  , Horde   , "Swamprat Post" },
    { 1777082 , Horde   , "Tarren Mill" },
    { 1777094 , Horde   , "The Bulwark" },
    { 1777051 , Horde   , "The Crossroads" },
    { 1777083 , Horde   , "The Sepulcher" },
    { 102197  , Horde   , "Thrallmar" },
    { 777002  , Horde   , "Thunder Bluff" },
    { 102198  , Horde   , "Thunderlord Stronghold" },
    { 777001  , Horde   , "Undercity" },
    { 1777057 , Horde   , "Valormok" },
    { 76880   , Horde   , "Vengeance Landing" },
    { 76915   , Horde   , "Venomspite" },
    { 76891   , Horde   , "Venture Bay" },
    { 76876   , Horde   , "Warsong Hold" },
    { 102201  , Horde   , "Zabra'jin" },
    { 1777064 , Horde   , "Zoram'gar Outpost" },
};

inline constexpr std::size_t TeleportFactionCount =
    sizeof(TeleportFactions) / sizeof(TeleportFactions[0]);
} // namespace StoneFaction

#endif // MOD_TELEPORT_ACTIONBAR_STONE_FACTION_DATA_H
