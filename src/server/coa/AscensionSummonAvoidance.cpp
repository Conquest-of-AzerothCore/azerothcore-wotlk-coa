/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "PetDefines.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <array>

namespace
{
enum AvoidingSummonEntry : uint32
{
    NPC_EMERALD_DRAGON_WHELP        = 8776,
    NPC_CRIMSON_CANNON              = 11199,
    NPC_ESKHANDAR                   = 14306,
    NPC_TIMBERMAW_ANCESTOR          = 15720,
    NPC_FUNGARIAN                   = 45896,
    NPC_SENTRY_TURRET               = 50046,
    NPC_ABOMINATION                 = 50068,
    NPC_GHOUL                       = 50073,
    NPC_SKELETAL_MAGE               = 50075,
    NPC_SKELETAL_ARCHER             = 50076,
    NPC_SERPENT_WARD                = 50105,
    NPC_DECAYING_COLOSSUS           = 50115,
    NPC_SHADOWHOUND                 = 50124,
    NPC_FROST_WYRM                  = 50177,
    NPC_LESSER_SHADOWHOUND          = 50224,
    NPC_PHOENIX                     = 50258,
    NPC_WAR_FALCON                  = 50264,
    NPC_HELLFIRE_IMP                = 50301,
    NPC_CRYPT_FIEND                 = 50323,
    NPC_ROARING_PYRE                = 50359,
    NPC_HELLFIRE_ABYSSAL            = 50375,
    NPC_WAR_FALCON_DIVE             = 50393,
    NPC_SERPENT_WARD_GUARD          = 50587,
    NPC_SHRAPNEL_MINE               = 50600,
    NPC_GREATER_SKELETAL_WARRIOR    = 51065,
    NPC_OIL_SPILL_PYLON             = 51204,
    NPC_HONORED_ANCESTOR            = 51265,
    NPC_ROTTING_FROST_GIANT         = 51275,
    NPC_BROOD_EGG                   = 52121,
    NPC_DRAGONHAWK                  = 52393,
    NPC_PRIMAL_TOTEM                = 224861,
    NPC_SPECTRAL_SCYTHE             = 250305,
    NPC_MIMIC_WARD                  = 300659,
    NPC_ELECTRIFIED_WATER_ELEMENTAL = 310603,
    NPC_ANIMATED_BLOOD              = 315301,
    NPC_BLOOD_PARASITE              = 335301,
    NPC_BATTLE_TURRET_RANK_1        = 347770,
    NPC_MANIFESTATION_OF_YSHAARJ    = 397771,
    NPC_BATTLE_TURRET_RANK_2        = 457771,
    NPC_BATTLE_TURRET_RANK_3        = 457772,
    NPC_GRAVEBOUND_CHAMPION         = 500482,
    NPC_SPELLBOUND_CHAMPION         = 500483,
    NPC_ICEBOUND_CHAMPION           = 500484,
    NPC_AIR_ELEMENTAL               = 500941,
    NPC_ANIMATED_ZOMBIE             = 503031,
    NPC_GREATER_IMP                 = 510100,
    NPC_RISEN_GHOUL                 = 542065,
    NPC_SPIRIT_OF_LIFE              = 840002,
    NPC_WILD_IMP                    = 855350,
    NPC_SPIDERLING                  = 999298,
    NPC_SCARAB                      = 999299,
};

enum SummonAvoidanceSpell : uint32
{
    SPELL_STRONG_AVOIDANCE          = 680927,
    SPELL_SPECTRAL_SCYTHE_PASSIVE   = 500485,
    SPELL_MECHANICAL_WARD           = 992173,
};

struct SummonAvoidance
{
    uint32 entry;
    uint32 spell;
};

constexpr std::array<SummonAvoidance, 51> SummonAvoidances =
{{
    { NPC_EMERALD_DRAGON_WHELP,        SPELL_PET_AVOIDANCE },
    { NPC_CRIMSON_CANNON,              SPELL_PET_AVOIDANCE },
    { NPC_ESKHANDAR,                   SPELL_PET_AVOIDANCE },
    { NPC_TIMBERMAW_ANCESTOR,          SPELL_PET_AVOIDANCE },
    { NPC_FUNGARIAN,                   SPELL_PET_AVOIDANCE },
    { NPC_SENTRY_TURRET,               SPELL_PET_AVOIDANCE },
    { NPC_ABOMINATION,                 SPELL_STRONG_AVOIDANCE },
    { NPC_GHOUL,                       SPELL_PET_AVOIDANCE },
    { NPC_SKELETAL_MAGE,               SPELL_PET_AVOIDANCE },
    { NPC_SKELETAL_ARCHER,             SPELL_PET_AVOIDANCE },
    { NPC_SERPENT_WARD,                SPELL_MECHANICAL_WARD },
    { NPC_DECAYING_COLOSSUS,           SPELL_PET_AVOIDANCE },
    { NPC_SHADOWHOUND,                 SPELL_PET_AVOIDANCE },
    { NPC_FROST_WYRM,                  SPELL_PET_AVOIDANCE },
    { NPC_LESSER_SHADOWHOUND,          SPELL_PET_AVOIDANCE },
    { NPC_PHOENIX,                     SPELL_PET_AVOIDANCE },
    { NPC_WAR_FALCON,                  SPELL_PET_AVOIDANCE },
    { NPC_HELLFIRE_IMP,                SPELL_PET_AVOIDANCE },
    { NPC_CRYPT_FIEND,                 SPELL_PET_AVOIDANCE },
    { NPC_ROARING_PYRE,                SPELL_PET_AVOIDANCE },
    { NPC_HELLFIRE_ABYSSAL,            SPELL_PET_AVOIDANCE },
    { NPC_WAR_FALCON_DIVE,             SPELL_PET_AVOIDANCE },
    { NPC_SERPENT_WARD_GUARD,          SPELL_MECHANICAL_WARD },
    { NPC_SHRAPNEL_MINE,               SPELL_PET_AVOIDANCE },
    { NPC_GREATER_SKELETAL_WARRIOR,    SPELL_PET_AVOIDANCE },
    { NPC_OIL_SPILL_PYLON,             SPELL_PET_AVOIDANCE },
    { NPC_HONORED_ANCESTOR,            SPELL_PET_AVOIDANCE },
    { NPC_ROTTING_FROST_GIANT,         SPELL_PET_AVOIDANCE },
    { NPC_BROOD_EGG,                   SPELL_PET_AVOIDANCE },
    { NPC_DRAGONHAWK,                  SPELL_PET_AVOIDANCE },
    { NPC_PRIMAL_TOTEM,                SPELL_PET_AVOIDANCE },
    { NPC_SPECTRAL_SCYTHE,             SPELL_SPECTRAL_SCYTHE_PASSIVE },
    { NPC_MIMIC_WARD,                  SPELL_MECHANICAL_WARD },
    { NPC_ELECTRIFIED_WATER_ELEMENTAL, SPELL_PET_AVOIDANCE },
    { NPC_ANIMATED_BLOOD,              SPELL_PET_AVOIDANCE },
    { NPC_BLOOD_PARASITE,              SPELL_PET_AVOIDANCE },
    { NPC_BATTLE_TURRET_RANK_1,        SPELL_PET_AVOIDANCE },
    { NPC_MANIFESTATION_OF_YSHAARJ,    SPELL_PET_AVOIDANCE },
    { NPC_BATTLE_TURRET_RANK_2,        SPELL_PET_AVOIDANCE },
    { NPC_BATTLE_TURRET_RANK_3,        SPELL_PET_AVOIDANCE },
    { NPC_GRAVEBOUND_CHAMPION,         SPELL_PET_AVOIDANCE },
    { NPC_SPELLBOUND_CHAMPION,         SPELL_PET_AVOIDANCE },
    { NPC_ICEBOUND_CHAMPION,           SPELL_PET_AVOIDANCE },
    { NPC_AIR_ELEMENTAL,               SPELL_PET_AVOIDANCE },
    { NPC_ANIMATED_ZOMBIE,             SPELL_PET_AVOIDANCE },
    { NPC_GREATER_IMP,                 SPELL_PET_AVOIDANCE },
    { NPC_RISEN_GHOUL,                 SPELL_PET_AVOIDANCE },
    { NPC_SPIRIT_OF_LIFE,              SPELL_PET_AVOIDANCE },
    { NPC_WILD_IMP,                    SPELL_PET_AVOIDANCE },
    { NPC_SPIDERLING,                  SPELL_PET_AVOIDANCE },
    { NPC_SCARAB,                      SPELL_PET_AVOIDANCE },
}};

uint32 SummonAvoidanceSpellFor(uint32 entry)
{
    auto const avoidance = std::find_if(SummonAvoidances.begin(), SummonAvoidances.end(),
        [entry](SummonAvoidance const& candidate) { return candidate.entry == entry; });
    return avoidance != SummonAvoidances.end() ? avoidance->spell : 0;
}

void ApplySummonAvoidance(Creature* summon)
{
    if (uint32 const spell = SummonAvoidanceSpellFor(summon->GetEntry()))
        summon->AddAura(spell, summon);
}

bool IsPlayerSummon(TempSummon const* summon)
{
    Unit* summoner = summon->GetSummonerUnit();
    return summoner && summoner->GetCharmerOrOwnerPlayerOrPlayerItself();
}
}

class ascension_summon_avoidance : public PlayerScript
{
public:
    ascension_summon_avoidance() : PlayerScript("ascension_summon_avoidance",
        {PLAYERHOOK_ON_AFTER_GUARDIAN_INIT_STATS_FOR_LEVEL}) { }

    void OnPlayerAfterGuardianInitStatsForLevel(Player*, Guardian* guardian) override
    {
        if (guardian)
            ApplySummonAvoidance(guardian);
    }
};

class ascension_summon_avoidance_unguarded : public AllCreatureScript
{
public:
    ascension_summon_avoidance_unguarded() : AllCreatureScript("ascension_summon_avoidance_unguarded") { }

    void OnCreatureAddWorld(Creature* creature) override
    {
        if (!creature->IsSummon() || creature->HasUnitTypeMask(UNIT_MASK_GUARDIAN))
            return;

        if (IsPlayerSummon(creature->ToTempSummon()))
            ApplySummonAvoidance(creature);
    }
};

void AddSC_AscensionSummonAvoidance()
{
    new ascension_summon_avoidance();
    new ascension_summon_avoidance_unguarded();
}
