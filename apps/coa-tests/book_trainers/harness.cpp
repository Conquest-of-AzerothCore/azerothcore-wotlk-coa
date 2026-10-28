#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

using uint8 = std::uint8_t;
using uint32 = std::uint32_t;

constexpr uint32 UNIT_NPC_FLAG_TRAINER_CLASS = 0x20;
constexpr uint8 CLASS_MAGE = 8;
constexpr uint8 CLASS_HERO = 10;
constexpr uint8 CLASS_PRIMALIST = 31;

struct Player
{
    uint8 cls;
    bool rankHero;
    uint8 getClass() const { return cls; }
};

struct Creature
{
    uint32 entry;
    uint32 flags;
    uint32 GetEntry() const { return entry; }
    bool HasNpcFlag(uint32 flag) const { return (flags & flag) != 0; }
};

namespace Trainer
{
    enum class Type { Class, Mount, Tradeskill, Pet };

    struct Spell
    {
        uint32 SpellId = 0;
    };

    class Trainer
    {
    public:
        Trainer(uint32 id, Type type, uint32 requirement, std::string, std::vector<Spell> spells)
            : _id(id), _type(type), _requirement(requirement), _spells(std::move(spells)) { }
        uint32 GetTrainerId() const { return _id; }
        Type GetTrainerType() const { return _type; }
        uint32 GetTrainerRequirement() const { return _requirement; }
        std::vector<Spell> const& GetSpells() const { return _spells; }

    private:
        uint32 _id;
        Type _type;
        uint32 _requirement;
        std::vector<Spell> _spells;
    };

    using WildcardRankRows = std::vector<Spell> (*)(Player const* player);
    using ClassTrainerFor = Trainer* (*)(Trainer const& trainer, Player const* player);
    using RankTrainerHero = bool (*)(Player const* player);
}

struct ObjectMgr
{
    std::unordered_map<uint32, Trainer::Trainer> trainers;
    std::unordered_map<uint32, uint32> creatureTrainers;

    Trainer::Trainer* GetTrainer(uint32 creatureId)
    {
        auto link = creatureTrainers.find(creatureId);
        if (link == creatureTrainers.end())
            return nullptr;
        auto trainer = trainers.find(link->second);
        return trainer == trainers.end() ? nullptr : &trainer->second;
    }
    std::unordered_map<uint32, Trainer::Trainer> const& GetTrainers() const { return trainers; }
};

ObjectMgr objectMgr;
ObjectMgr* sObjectMgr = &objectMgr;

std::vector<Trainer::Spell> Spells(uint32 first, uint32 count)
{
    std::vector<Trainer::Spell> spells;
    for (uint32 i = 0; i < count; ++i)
        spells.push_back({ first + i });
    return spells;
}

std::optional<Trainer::Trainer> reborn;

bool IsWildcardHero(Player const*)
{
    return false;
}

namespace Trainer
{
    constexpr uint32 WILDCARD_RANK_TRAINER_ID = std::numeric_limits<uint32>::max();
    WildcardRankRows WildcardRankRowsOf = [](Player const*) { return Spells(9000, 3); };
    ClassTrainerFor ClassTrainerOf = nullptr;
    RankTrainerHero RankTrainerHeroOf = [](Player const* player) { return player->rankHero; };

// ACTUAL_TRAINER
}

void Expect(bool condition, char const* what)
{
    if (!condition)
    {
        std::cerr << "FAIL: " << what << "\n";
        std::exit(1);
    }
}

int main()
{
    objectMgr.trainers.emplace(16, Trainer::Trainer(16, Trainer::Type::Class, CLASS_MAGE, "", Spells(100, 256)));
    objectMgr.trainers.emplace(17, Trainer::Trainer(17, Trainer::Type::Class, CLASS_MAGE, "", Spells(500, 6)));
    objectMgr.trainers.emplace(26, Trainer::Trainer(26, Trainer::Type::Class, CLASS_MAGE, "", Spells(600, 4)));
    objectMgr.trainers.emplace(900031, Trainer::Trainer(900031, Trainer::Type::Class, CLASS_PRIMALIST, "", Spells(700, 40)));
    objectMgr.trainers.emplace(50, Trainer::Trainer(50, Trainer::Type::Tradeskill, 0, "", Spells(800, 10)));
    objectMgr.creatureTrainers = { { 198, 17 }, { 331, 16 }, { 900, 50 } };

    Creature const book{ 75115, 0x10 | UNIT_NPC_FLAG_TRAINER_CLASS };
    Creature const portalTrainer{ 198, 0x10 | UNIT_NPC_FLAG_TRAINER_CLASS };
    Creature const mageTrainer{ 331, 0x10 | UNIT_NPC_FLAG_TRAINER_CLASS };
    Creature const tailor{ 900, 0x10 };
    Creature const gossipOnly{ 1234, 0x1 };

    Player const mage{ CLASS_MAGE, false };
    Player const hero{ CLASS_HERO, true };
    Player const heroElsewhere{ CLASS_HERO, false };

    Trainer::Trainer* trainer = Trainer::GetTrainerFor(&book, &mage);
    Expect(trainer && trainer->GetTrainerId() == 16, "a book serves a stock character its class's full trainer list");
    Expect(Trainer::GetTrainerFor(&portalTrainer, &mage)->GetTrainerId() == 17, "a world trainer keeps its own list");
    Expect(Trainer::GetTrainerFor(&tailor, &mage)->GetTrainerId() == 50, "a profession trainer keeps its own list");
    Expect(!Trainer::GetTrainerFor(&gossipOnly, &mage), "a unit that is no class trainer serves nothing");
    Expect(!Trainer::GetTrainerFor(&book, &heroElsewhere), "a Hero that trains no ranks gets no class list from a book");

    trainer = Trainer::GetTrainerFor(&book, &hero);
    Expect(trainer && trainer->GetTrainerId() == Trainer::WILDCARD_RANK_TRAINER_ID,
           "a rank-training Hero gets the next ranks of its abilities from a book");
    Expect(trainer->GetSpells().size() == 3 && trainer->GetSpells()[0].SpellId == 9000, "the Hero's rows are its rank rows");
    trainer = Trainer::GetTrainerFor(&mageTrainer, &hero);
    Expect(trainer && trainer->GetTrainerId() == Trainer::WILDCARD_RANK_TRAINER_ID,
           "a rank-training Hero gets the same rows at a world class trainer");

    reborn.emplace(16000016, Trainer::Type::Class, CLASS_MAGE, "", Spells(1100100, 250));
    Trainer::ClassTrainerOf = [](Trainer::Trainer const& stock, Player const*) -> Trainer::Trainer* {
        return stock.GetTrainerId() == 16 ? &*reborn : nullptr;
    };
    trainer = Trainer::GetTrainerFor(&book, &mage);
    Expect(trainer && trainer->GetTrainerId() == 16000016, "a book serves the realm's replacement of the class trainer");

    std::cout << "PASS: books serve the class's full list, its realm replacement, or a Hero's rank rows\n";
    return 0;
}
