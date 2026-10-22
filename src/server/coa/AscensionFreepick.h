/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_FREEPICK_H
#define ASCENSION_FREEPICK_H

#include "AscensionCoATalentState.h"
#include "AscensionFreepickRules.h"
#include <array>
#include <cstdint>
#include <string>
#include <vector>

class Player;
class SpellInfo;

namespace AscensionFreepick
{
struct UploadResult
{
    char const* Result = "CA_UPDATE_ENTRIES_OK";
    char const* Learn = "";
    std::uint32_t EntryId = 0;
    std::uint32_t Rank = 0;
};

Realm ReadRealm();
bool RealmIsClassless();
bool RealmOffersMysticAltars();
bool IsFreepickHero(Player const* player);
bool HasFreepickBuild(Player const* player);
std::vector<AscensionCoATalentState::KnownEntry> KnownEntries(Player const* player);
UploadResult ApplyUpload(Player* player, std::vector<AscensionCoATalentState::KnownEntry> const& upload);
UploadResult ApplyGuide(Player* player, std::vector<GuideSpell> const& spells, std::uint32_t primaryStat);
std::uint32_t PrestigeSpecialization(Player* player);
void Synchronize(Player* player);
std::array<bool, 5> RealmGates();
std::uint32_t ActiveSpecialization(Player const* player);
bool SwitchSpecialization(Player* player, std::uint32_t index, std::string& error);
std::uint32_t InvestedEssence(Player const* player, std::uint32_t classType, std::uint32_t tab, bool talent);
}

void ApplyAscensionPathPassiveContract(SpellInfo* spellInfo);

#endif
