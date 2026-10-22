#include <cstdio>

namespace
{
int failures = 0;

void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

enum PetType : unsigned
{
    SUMMON_PET = 1,
    HUNTER_PET = 3
};

enum Classes : unsigned
{
    CLASS_WARRIOR = 1,
    CLASS_HUNTER = 3,
    CLASS_DEATH_KNIGHT = 6,
    CLASS_MAGE = 8,
    CLASS_WARLOCK = 9,
    CLASS_HERO = 10,
    CLASS_BARBARIAN = 12,
    CLASS_TINKER = 28,
    CLASS_WILDWALKER = 31,
    CLASS_SPIRIT_MAGE = 32
};

enum ClassContext : unsigned
{
    CLASS_CONTEXT_PET = 10
};

enum CreatureType : unsigned
{
    CREATURE_TYPE_BEAST = 1,
    CREATURE_TYPE_DEMON = 3,
    CREATURE_TYPE_ELEMENTAL = 4,
    CREATURE_TYPE_UNDEAD = 6,
    CREATURE_TYPE_HUMANOID = 7,
    CREATURE_TYPE_MECHANICAL = 9
};

bool IsAscensionClass(unsigned classId)
{
    return classId >= CLASS_BARBARIAN && classId <= CLASS_SPIRIT_MAGE;
}

struct CreatureTemplate
{
    unsigned type;
};

struct Player
{
    unsigned cls;

    bool IsClass(Classes unitClass, ClassContext) const { return cls == unitClass; }
    unsigned getClass() const { return cls; }
};

struct Pet
{
    PetType petType;
    unsigned entry;
    CreatureTemplate creatureTemplate;

    PetType getPetType() const { return petType; }
    CreatureTemplate const* GetCreatureTemplate() const { return &creatureTemplate; }
    unsigned GetEntry() const { return entry; }

    bool IsPermanentPetFor(Player* owner) const;
};

// ACTUAL_PERMANENT

Pet Make(PetType petType, unsigned entry, unsigned creatureType)
{
    Pet pet{};
    pet.petType = petType;
    pet.entry = entry;
    pet.creatureTemplate.type = creatureType;
    return pet;
}

bool Permanent(Pet const& pet, unsigned playerClass)
{
    Player owner{ playerClass };
    return pet.IsPermanentPetFor(&owner);
}
}

int main()
{
    Pet tinker = Make(SUMMON_PET, 60070, CREATURE_TYPE_MECHANICAL);
    Check(Permanent(tinker, CLASS_TINKER), "a Tinker's built mechanical pet is permanent for the client");
    Check(Permanent(Make(SUMMON_PET, 50048, CREATURE_TYPE_MECHANICAL), CLASS_TINKER),
        "every Tinker build pet is permanent");
    Check(Permanent(Make(SUMMON_PET, 60070, CREATURE_TYPE_MECHANICAL), CLASS_WILDWALKER),
        "a custom class's summoned pet is permanent");
    Check(Permanent(Make(HUNTER_PET, 1188, CREATURE_TYPE_BEAST), CLASS_WILDWALKER),
        "a Wildwalker's tamed beast stays a hunter pet");
    Check(Permanent(Make(HUNTER_PET, 1188, CREATURE_TYPE_BEAST), CLASS_HUNTER),
        "a stock hunter pet stays permanent");

    Check(!Permanent(Make(SUMMON_PET, 416, CREATURE_TYPE_DEMON), CLASS_WARRIOR),
        "stock classes keep the old summon rule");
    Check(!Permanent(Make(SUMMON_PET, 416, CREATURE_TYPE_DEMON), CLASS_HERO),
        "the classless Hero keeps the old summon rule");

    Check(Permanent(Make(SUMMON_PET, 416, CREATURE_TYPE_DEMON), CLASS_WARLOCK),
        "a warlock's demon is permanent");
    Check(!Permanent(Make(SUMMON_PET, 416, CREATURE_TYPE_HUMANOID), CLASS_WARLOCK),
        "a warlock's non-demon summon is not permanent");

    Check(Permanent(Make(SUMMON_PET, 26125, CREATURE_TYPE_UNDEAD), CLASS_DEATH_KNIGHT),
        "a death knight's ghoul is permanent");
    Check(!Permanent(Make(SUMMON_PET, 26125, CREATURE_TYPE_HUMANOID), CLASS_DEATH_KNIGHT),
        "a death knight's non-undead summon is not permanent");

    Check(Permanent(Make(SUMMON_PET, 37994, CREATURE_TYPE_ELEMENTAL), CLASS_MAGE),
        "the mage's water elemental is permanent");
    Check(!Permanent(Make(SUMMON_PET, 99999, CREATURE_TYPE_ELEMENTAL), CLASS_MAGE),
        "another mage summon is not permanent");

    Check(Permanent(Make(HUNTER_PET, 1188, CREATURE_TYPE_BEAST), CLASS_TINKER),
        "a hunter pet stays permanent for any owner class");

    return failures ? 1 : 0;
}
