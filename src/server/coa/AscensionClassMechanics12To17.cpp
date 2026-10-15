/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionClassMechanics12To17.h"
#include "Player.h"
#include "Spell.h"
#include <array>
#include <utility>

namespace
{
using SpellRange = std::pair<std::uint32_t, std::uint32_t>;

constexpr std::uint32_t SPELL_BARBARIAN_RELENTLESS = 300505;
constexpr std::uint32_t SPELL_BARBARIAN_BEHEADER = 705222;
constexpr std::uint32_t SPELL_BARBARIAN_GIANT_TOSSER = 807863;
constexpr std::uint32_t SPELL_BARBARIAN_GIANT_TOSSER_ENERGIZE = 807909;
constexpr std::uint32_t SPELL_BARBARIAN_BATTLE_RHYTHM = 800193;
constexpr std::uint32_t SPELL_BARBARIAN_BATTLE_RHYTHM_ENERGIZE = 800951;
constexpr std::uint32_t SPELL_BARBARIAN_HEADHUNTER_ENERGIZE = 706816;
constexpr std::uint32_t SPELL_BARBARIAN_THIRST_FOR_BATTLE = 570236;
constexpr std::uint32_t SPELL_BARBARIAN_THIRST_ENERGIZE = 560463;
constexpr std::uint8_t BARBARIAN_RELENTLESS_ENERGY = 10;
constexpr float BARBARIAN_GIANT_TOSSER_MINIMUM_DISTANCE = 20.0f;

constexpr std::uint32_t SPELL_FELSWORN_TYRANTS_GAZE = 805240;
constexpr std::uint32_t SPELL_FELSWORN_TYRANTS_GAZE_HEAL = 805241;

constexpr std::uint32_t SPELL_STORMBRINGER_STATIC_ELECTRICITY = 524954;
constexpr std::uint32_t SPELL_STORMBRINGER_STORMCLOUD = 801859;
constexpr std::uint32_t SPELL_STORMBRINGER_GEYSER = 800374;
constexpr std::uint32_t SPELL_STORMBRINGER_THUNDER_KING = 804591;
constexpr std::uint32_t SPELL_STORMBRINGER_THUNDER_FIST = 800020;
constexpr std::uint32_t SPELL_STORMBRINGER_RAGING_STORM = 800014;
constexpr std::uint32_t NPC_STORMBRINGER_ELECTRIFIED_WATER = 310603;
constexpr std::uint32_t STORMBRINGER_ELECTRIFIED_WATER_DURATION = 20000;

constexpr std::array<SpellRange, 2> STORMBRINGER_TORRENTIAL_WRATH =
{{
    {503352, 503360},
    {804017, 804017}
}};

constexpr std::array<SpellRange, 2> BARBARIAN_ANCESTRAL_STRIKE =
{{
    {801576, 801576},
    {802444, 802450}
}};

constexpr std::array<SpellRange, 2> BARBARIAN_SMASH =
{{
    {801755, 801755},
    {501027, 501035}
}};

constexpr std::array<SpellRange, 2> BARBARIAN_BRUTAL_SWING =
{{
    {500913, 500913},
    {500996, 501002}
}};

constexpr std::array<SpellRange, 3> BARBARIAN_DECAPITATE =
{{
    {573228, 573228},
    {804414, 804414},
    {806905, 806908}
}};

constexpr std::array<SpellRange, 3> BARBARIAN_HEADHUNTERS_SPEAR =
{{
    {503402, 503407},
    {504712, 504712},
    {804137, 804137}
}};

template <std::size_t Size>
bool IsSpellInRanges(std::uint32_t spellId,
    std::array<SpellRange, Size> const& ranges)
{
    for (SpellRange const& range : ranges)
        if (spellId >= range.first && spellId <= range.second)
            return true;
    return false;
}

bool IsSuccessfulHostileHit(Player const* player, Unit const* target,
    std::uint8_t missInfo, std::uint32_t damage)
{
    return player && target && target != player &&
        missInfo == SPELL_MISS_NONE && damage &&
        !player->IsFriendlyTo(target);
}

void RestoreAllEnergy(Player* player)
{
    player->SetPower(POWER_ENERGY, player->GetMaxPower(POWER_ENERGY));
}
}

void HandleAscensionClassMechanics12To17CalculatedTarget(Spell* spell,
    Player* player, Unit* target, TargetInfo& targetInfo)
{
    if (!spell || !player || !target || player->getClass() != CLASS_BARBARIAN)
        return;

    if (player->HasAura(SPELL_BARBARIAN_GIANT_TOSSER) &&
        IsSpellInRanges(spell->GetSpellInfo()->Id,
            BARBARIAN_HEADHUNTERS_SPEAR) &&
        player->GetDistance(target) > BARBARIAN_GIANT_TOSSER_MINIMUM_DISTANCE)
    {
        targetInfo.damage *= 2;
        targetInfo.damageBeforeTakenMods *= 2;
    }
}

void HandleAscensionClassMechanics12To17Hit(Spell* spell, Player* player,
    Unit* target, std::uint8_t missInfo, std::uint32_t damage, bool critical)
{
    if (!spell || !player || spell->IsTriggered() ||
        !IsSuccessfulHostileHit(player, target, missInfo, damage))
        return;

    std::uint32_t spellId = spell->GetSpellInfo()->Id;
    switch (player->getClass())
    {
        case CLASS_BARBARIAN:
        {
            if (player->HasAura(SPELL_BARBARIAN_THIRST_FOR_BATTLE) && IsSpellInRanges(spellId, BARBARIAN_SMASH))
                player->CastSpell(player, SPELL_BARBARIAN_THIRST_ENERGIZE, true);

            if (IsSpellInRanges(spellId, BARBARIAN_HEADHUNTERS_SPEAR))
            {
                player->CastSpell(player,
                    SPELL_BARBARIAN_HEADHUNTER_ENERGIZE, true);
                if (player->HasAura(SPELL_BARBARIAN_GIANT_TOSSER) &&
                    player->GetDistance(target) >
                        BARBARIAN_GIANT_TOSSER_MINIMUM_DISTANCE)
                {
                    player->CastSpell(player,
                        SPELL_BARBARIAN_GIANT_TOSSER_ENERGIZE, true);
                }
            }

            if (critical && player->HasAura(SPELL_BARBARIAN_RELENTLESS) &&
                (IsSpellInRanges(spellId, BARBARIAN_ANCESTRAL_STRIKE) ||
                    IsSpellInRanges(spellId, BARBARIAN_BRUTAL_SWING)))
            {
                player->ModifyPower(POWER_ENERGY,
                    BARBARIAN_RELENTLESS_ENERGY);
            }

            if (critical && player->HasAura(SPELL_BARBARIAN_BATTLE_RHYTHM))
            {
                player->CastSpell(player,
                    SPELL_BARBARIAN_BATTLE_RHYTHM_ENERGIZE, true);
            }

            if (player->HasAura(SPELL_BARBARIAN_BEHEADER) &&
                IsSpellInRanges(spellId, BARBARIAN_DECAPITATE) &&
                !target->IsAlive())
            {
                RestoreAllEnergy(player);
            }
            break;
        }
        case CLASS_DEMON_HUNTER:
        {
            if (spellId == SPELL_FELSWORN_TYRANTS_GAZE)
            {
                player->CastSpell(player,
                    SPELL_FELSWORN_TYRANTS_GAZE_HEAL, true);
            }
            break;
        }
        case CLASS_STORMBRINGER:
        {
            if (critical && player->HasAura(SPELL_STORMBRINGER_STATIC_ELECTRICITY) &&
                IsSpellInRanges(spellId, STORMBRINGER_TORRENTIAL_WRATH) &&
                !spell->GetScriptValue(SPELL_STORMBRINGER_STATIC_ELECTRICITY))
            {
                spell->SetScriptValue(SPELL_STORMBRINGER_STATIC_ELECTRICITY, 1);
                player->SummonCreature(NPC_STORMBRINGER_ELECTRIFIED_WATER,
                    player->GetPosition(), TEMPSUMMON_TIMED_DESPAWN,
                    STORMBRINGER_ELECTRIFIED_WATER_DURATION);
            }

            if (IsSpellInRanges(spellId, STORMBRINGER_TORRENTIAL_WRATH) &&
                target->HasAura(SPELL_STORMBRINGER_STORMCLOUD, player->GetGUID()))
            {
                player->CastSpell(target, SPELL_STORMBRINGER_GEYSER, true);
            }

            if (critical && player->HasAura(SPELL_STORMBRINGER_THUNDER_KING))
            {
                player->CastSpell(target, SPELL_STORMBRINGER_THUNDER_FIST, true);
                player->CastSpell(player, SPELL_STORMBRINGER_RAGING_STORM, true);
            }
            break;
        }
        default:
            break;
    }
}
