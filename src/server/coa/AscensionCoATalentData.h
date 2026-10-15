#ifndef ASCENSION_COA_TALENT_DATA_H
#define ASCENSION_COA_TALENT_DATA_H

#include <array>
#include <cstdint>
#include <vector>

namespace AscensionCompatData
{
struct CoATalentEntry
{
    std::uint32_t EntryId;
    std::uint8_t ClassId;
    std::uint16_t SpecId;
    std::uint8_t SpellCount;
    std::uint8_t AECost;
    std::uint8_t TECost;
    std::uint8_t RequiredLevel;
    std::array<std::uint32_t, 3> SpellIds;
    bool Talent = false;
    bool FreeUnlearn = false;
    std::array<std::uint32_t, 3> RequiredEntryIds{};
};

struct CoASelectableFreeEntry
{
    std::uint32_t EntryId;
    std::uint32_t GroupId;
};

struct CoAAutomaticDependency
{
    std::uint32_t EntryId;
    std::array<std::uint32_t, 2> RequiredEntryIds;
};

struct CoASpecialization
{
    std::uint16_t SpecId;
    std::uint8_t ClassId;
    std::uint32_t IdentityEntryId;
    std::uint32_t SignatureEntryId;
    std::array<std::uint8_t, 3> PrimaryStats{};
};

struct CoATalentBudget
{
    std::uint8_t ClassId;
    std::uint8_t Level;
    std::uint8_t AE;
    std::uint8_t TE;
};

extern std::vector<CoATalentEntry> CoATalentEntries;
extern std::vector<CoASelectableFreeEntry> CoASelectableFreeEntries;
extern std::vector<CoAAutomaticDependency> CoAAutomaticDependencies;
extern std::vector<CoASpecialization> CoASpecializations;
extern std::vector<CoATalentBudget> CoATalentBudgets;

bool GetCoATalentBudget(std::uint8_t classId, std::uint8_t level, std::uint32_t& ae, std::uint32_t& te);

bool LoadCoATalentData();
}

#endif
