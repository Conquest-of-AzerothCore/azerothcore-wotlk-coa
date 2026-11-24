#include "PetFactory.h"
#include "Describe.h"
#include "Rules.h"
#include <algorithm>
#include <stdexcept>

namespace CoAPetBattles::Engine
{
    PetAbility MakeAbility(KitEntry const& entry)
    {
        AbilityDef const& def = *entry.ability;
        Presentation const& view = *entry.presentation;
        PetAbility ability;
        ability.id = def.id;
        ability.name = view.name;
        ability.retailName = view.retailName;
        ability.icon = view.icon;
        ability.text = view.tooltip;
        ability.family = def.family;
        ability.cooldown = def.cooldown;
        for (Turn const& turn : def.turns)
            (turn.event == 255 ? ability.turns : ability.procs).push_back(turn);
        if (ability.turns.empty())
        {
            ability.turns = def.turns;
            ability.procs.clear();
        }
        ability.priority = view.goesFirst;
        if (view.visualSpell)
            ability.vis = static_cast<double>(view.visualSpell);
        ability.ranged = view.ranged;
        if (!view.visualMode.empty())
            ability.vmode = view.visualMode;
        if (view.preSpell)
            ability.vpre = static_cast<double>(view.preSpell);
        ability.vhop = view.hop;
        ability.vdmg = view.spellDealsDamage;
        return ability;
    }

    std::vector<KitOption> Kit(Catalog const& catalog, uint32_t species)
    {
        SpeciesDef const* def = catalog.Species(species);
        if (!def)
            throw std::invalid_argument("unknown species " + std::to_string(species));
        std::vector<KitOption> kit;
        for (KitEntry const& entry : def->kit)
            kit.push_back({ entry.slot, entry.option, entry.unlock, MakeAbility(entry) });
        return kit;
    }

    Pet NewPet(Catalog const& catalog, uint32_t species, double level, std::optional<std::array<int32_t, 3>> picks,
        Rng& rng, std::optional<double> quality, std::optional<double> hp)
    {
        SpeciesDef const* def = catalog.Species(species);
        if (!def)
            throw std::invalid_argument("unknown species " + std::to_string(species));
        double const maxLevel = static_cast<double>(catalog.Config().maxLevel);
        level = std::max(1.0, std::min(maxLevel, level));
        Pet pet;
        pet.species = species;
        pet.name = def->name;
        pet.icon = def->icon;
        pet.family = def->family;
        pet.level = level;
        pet.quality = quality.value_or(1);
        Stats const stats = PetStats(def->power, def->speed, def->stamina, level, pet.quality, maxLevel);
        pet.max = stats.health;
        pet.baseMax = stats.health;
        pet.power = stats.power;
        pet.speed = stats.speed;
        pet.hp = std::max(1.0, std::min(pet.max, hp.value_or(pet.max)));
        std::vector<KitOption> const kit = Kit(catalog, species);
        for (int32_t slot = 1; slot <= 3; ++slot)
        {
            int32_t const want = picks ? (*picks)[slot - 1] : rng.Roll(1, 2);
            KitOption const* first = nullptr;
            KitOption const* chosen = nullptr;
            for (KitOption const& k : kit)
            {
                if (k.slot != slot)
                    continue;
                if (k.option == 1)
                    first = &k;
                if (k.option == want)
                    chosen = &k;
            }
            if (first && level >= first->unlock)
            {
                KitOption const& k = (chosen && level >= chosen->unlock) ? *chosen : *first;
                PetAbility ability = k.ability;
                ability.tip = Describe(catalog, { ability.text, &ability.turns, ability.family, std::nullopt },
                    pet.power);
                pet.abil[slot - 1] = ability;
            }
        }
        return pet;
    }

    double RollQuality(Catalog const& catalog, Rng& rng)
    {
        std::array<uint32_t, 4> const& weights = catalog.Config().qualityWeights;
        int32_t total = 0;
        for (uint32_t weight : weights)
            total += static_cast<int32_t>(weight);
        int32_t r = rng.Roll(1, total);
        for (size_t q = 0; q < weights.size(); ++q)
        {
            if (r <= static_cast<int32_t>(weights[q]))
                return static_cast<double>(q + 1);
            r -= static_cast<int32_t>(weights[q]);
        }
        return 1;
    }

    double XPNeeded(Catalog const& catalog, double level)
    {
        std::array<double, 2> const* xp = catalog.Xp(std::max(1.0, std::min(
            static_cast<double>(catalog.Config().maxLevel), level)));
        return xp ? (*xp)[0] * (*xp)[1] : 0;
    }

    double XPPerWin(Catalog const& catalog, double level)
    {
        std::array<double, 2> const* xp = catalog.Xp(std::max(1.0, std::min(
            static_cast<double>(catalog.Config().maxLevel), level)));
        return xp ? (*xp)[1] : 0;
    }

    FamilyMatchups FamilyInfo(std::string const& family)
    {
        FamilyMatchups info { family, "", "", "", "" };
        auto append = [](std::string& list, char const* name) { list += (list.empty() ? "" : "/") + std::string(name); };
        for (char const* other : Families)
        {
            double const m = Matchup(family, other);
            if (m > 1)
                append(info.strong, other);
            else if (m < 1)
                append(info.weak, other);
            double const h = Matchup(other, family);
            if (h > 1)
                append(info.hurtBy, other);
            else if (h < 1)
                append(info.resists, other);
        }
        return info;
    }
}
