#include "JournalMessages.h"
#include "Engine/Describe.h"
#include "Engine/LuaNumber.h"
#include "Engine/PetFactory.h"
#include "Engine/Rules.h"
#include "WireText.h"
#include <algorithm>
#include <cmath>
#include <regex>

namespace CoAPetBattles::Protocol
{
    namespace
    {
        constexpr size_t TeamSlots = 3;

        std::optional<uint32_t> Species(std::string const& payload)
        {
            std::optional<double> const value = LuaNumberOf(payload);
            if (!value || *value < 0 || *value != std::floor(*value) || *value > 4294967295.0)
                return std::nullopt;
            return static_cast<uint32_t>(*value);
        }
    }

    namespace
    {
        Store::OwnedPet const* SelectedPet(Store::Journal const& journal, uint32_t key, bool ownedIds)
        {
            return ownedIds ? journal.Pet(key) : journal.PetOfSpecies(key);
        }
    }

    std::string TeamMessage(Store::Journal const& journal, uint8_t team, bool ownedIds)
    {
        auto const& slots = journal.TeamAt(team).slots;
        if (ownedIds)
            return std::to_string(team) + "," + std::to_string(slots[0]) + "," + std::to_string(slots[1]) + "," +
                std::to_string(slots[2]);
        return std::to_string(team) + "," + std::to_string(journal.SpeciesForPet(slots[0])) + "," +
            std::to_string(journal.SpeciesForPet(slots[1])) + "," +
            std::to_string(journal.SpeciesForPet(slots[2]));
    }

    std::string PetMessage(Engine::Catalog const& catalog, Store::Journal const& journal, Store::OwnedPet const& pet,
        uint32_t now, bool ownedIds)
    {
        Engine::SpeciesDef const* def = catalog.Species(pet.species);
        uint8_t const level = std::min<uint8_t>(pet.level, catalog.Config().maxLevel);
        Engine::Stats const stats = Engine::StatsForPet(*def, level, pet.quality, catalog.Config().maxLevel, pet.breed);
        std::string const copy = ownedIds ? std::to_string(pet.id) + "," + std::to_string(pet.breed) + "," +
            Integer(std::floor(stats.speed + 0.5)) + "," + std::to_string(static_cast<uint8_t>(pet.source)) + "," : "";
        return copy + std::to_string(pet.species) + "," + std::to_string(level) + "," + std::to_string(pet.xp) + "," +
            std::to_string(pet.picks[0]) + "," + std::to_string(pet.picks[1]) + "," + std::to_string(pet.picks[2]) +
            "," + def->family + "," + def->icon + "," + std::to_string(journal.MaxHealth(pet)) + "," +
            Integer(std::floor(stats.power + 0.5)) + "," + std::to_string(pet.quality) + "," +
            std::to_string(journal.CurrentHealth(pet, now)) + "," +
            std::to_string(Store::XpNeeded(catalog, level)) + "," + def->name;
    }

    namespace
    {
        bool Feed(Engine::Catalog const& catalog, Store::Journal& journal, std::string const& payload,
            JournalReply const& reply)
        {
            static std::regex const pattern(R"(^(\d+),(\d+)$)");
            std::smatch match;
            if (!std::regex_match(payload, match, pattern))
                return false;
            std::optional<uint32_t> const key = Species(match[1].str());
            std::optional<uint32_t> const food = Species(match[2].str());
            if (!key || !food)
                return false;
            uint32_t const item = *food;
            auto const say = [&reply](std::string const& text) { reply.send("pbt", "msg", text); };
            if (reply.inBattle && reply.inBattle())
            {
                say("Pets cannot be fed during a battle.");
                return false;
            }
            Store::OwnedPet const* pet = SelectedPet(journal, *key, reply.ownedIds);
            Engine::SpeciesDef const* def = pet ? catalog.Species(pet->species) : nullptr;
            if (!pet || !def)
            {
                say("You do not own that pet.");
                return false;
            }
            std::optional<uint8_t> const level = reply.foodLevel ? reply.foodLevel(item) : std::nullopt;
            if (!level)
            {
                say("That is not food a pet can eat.");
                return false;
            }
            if (!reply.hasItem || !reply.hasItem(item))
            {
                say("You do not have that food.");
                return false;
            }
            std::string const petLevel = std::to_string(pet->level);
            uint32_t const petId = pet->id;
            switch (journal.Feed(petId, *level, reply.now))
            {
                case Store::FeedResult::NotOwned:
                    say("You do not own that pet.");
                    return false;
                case Store::FeedResult::FullHealth:
                    say(def->name + " is already at full health.");
                    return false;
                case Store::FeedResult::TooWeak:
                    say("That food is too weak for a level " + petLevel + " pet: it needs a food of level " + petLevel +
                        " or more.");
                    return false;
                case Store::FeedResult::Fed:
                    break;
            }
            if (reply.takeItem)
                reply.takeItem(item);
            Settings const& settings = catalog.Config();
            if (reply.fedRefresh && settings.fedStepSeconds)
                reply.fedRefresh(petId, settings.fedSeconds / settings.fedStepSeconds + 1,
                    uint64_t(settings.fedStepSeconds) * 1000);
            reply.send("pbj", reply.ownedIds ? "pet2" : "pet",
                PetMessage(catalog, journal, *journal.Pet(petId), reply.now, reply.ownedIds));
            say(def->name + " is well fed and recovers health for " + std::to_string(settings.fedSeconds) +
                " seconds.");
            return true;
        }
    }

    void SendJournal(Engine::Catalog const& catalog, Store::Journal const& journal, JournalReply const& reply)
    {
        if (reply.ownedIds)
            reply.send("pbj", "begin2", "");
        for (Store::OwnedPet const* pet : journal.Pets())
            if (reply.ownedIds || journal.PetIdForSpecies(pet->species) == pet->id)
                reply.send("pbj", reply.ownedIds ? "pet2" : "pet",
                    PetMessage(catalog, journal, *pet, reply.now, reply.ownedIds));
        for (uint8_t team = 1; team <= Store::TeamCount; ++team)
            reply.send("pbj", reply.ownedIds ? "team2" : "team", TeamMessage(journal, team, reply.ownedIds));
        reply.send("pbj", reply.ownedIds ? "active2" : "active", std::to_string(journal.ActiveTeam()));
        reply.send("pbj", reply.ownedIds ? "follow2" : "follow", std::to_string(reply.follower ? reply.follower() : 0));
        reply.send("pbj", reply.ownedIds ? "done2" : "done", "");
    }

    bool HandleJournalMessage(Engine::Catalog const& catalog, Store::Journal& journal, std::string const& action,
        std::string const& payload, JournalReply const& reply)
    {
        if (action == "list")
        {
            if (reply.syncCompanions)
                reply.syncCompanions();
            SendJournal(catalog, journal, reply);
            return true;
        }
        if (action == "abil")
        {
            std::optional<uint32_t> const species = Species(payload);
            Store::OwnedPet const* mine = species ? SelectedPet(journal, *species, reply.ownedIds) : nullptr;
            Engine::SpeciesDef const* def = mine ? catalog.Species(mine->species) :
                (!reply.ownedIds && species ? catalog.Species(*species) : nullptr);
            if (!def)
                return false;
            double const power = Engine::StatsForPet(*def, mine ? mine->level : 1, mine ? mine->quality : 1,
                catalog.Config().maxLevel, mine ? mine->breed : 0).power;
            std::string const abilityAction = reply.ownedIds ? "abl2" : "abl";
            std::string const prefix = "pbj|" + abilityAction + "|" + std::to_string(*species) + ",3,2|";
            for (Engine::KitOption const& option : Engine::Kit(catalog, def->entry))
            {
                Engine::PetAbility const& ability = option.ability;
                std::string tip = WireSafe(Engine::Describe(catalog,
                    { ability.text, &ability.turns, ability.family, std::nullopt }, power));
                std::string const name = WireSafe(ability.name);
                std::string const cooldown = Engine::LuaNumber(ability.cooldown);
                std::string const unlock = Engine::LuaNumber(option.unlock);
                int64_t const room = std::min<int64_t>(170, 240 - static_cast<int64_t>(prefix.size() +
                    ability.icon.size() + name.size() + cooldown.size() + unlock.size() + 6));
                tip = CutAtSentence(tip, room);
                reply.send("pbj", abilityAction, std::to_string(*species) + "," + std::to_string(option.slot) + "," +
                    std::to_string(option.option) + "|" + ability.icon + "#" + name + "#" + tip + "#" + cooldown + "#" +
                    unlock);
            }
            return false;
        }
        if (action == "setabil")
        {
            static std::regex const pattern(R"(^(\d+),(\d),(\d)$)");
            std::smatch match;
            if (!std::regex_match(payload, match, pattern))
                return false;
            std::optional<uint32_t> const species = Species(match[1].str());
            uint32_t const slot = static_cast<uint32_t>(std::stoul(match[2].str()));
            uint8_t const option = static_cast<uint8_t>(std::stoul(match[3].str()));
            Store::OwnedPet const* pet = species ? SelectedPet(journal, *species, reply.ownedIds) : nullptr;
            if (!pet || slot < 1 || slot > TeamSlots || (option != 1 && option != 2))
                return false;
            std::array<uint8_t, 3> picks = pet->picks;
            picks[slot - 1] = option;
            journal.SetPicks(pet->id, picks);
            reply.send("pbj", reply.ownedIds ? "pet2" : "pet",
                PetMessage(catalog, journal, *pet, reply.now, reply.ownedIds));
            return true;
        }
        if (action == "setteam")
        {
            static std::regex const pattern(R"(^(\d),(\d+),(\d+),(\d+)$)");
            std::smatch match;
            if (!std::regex_match(payload, match, pattern))
                return false;
            uint8_t const team = static_cast<uint8_t>(std::stoul(match[1].str()));
            if (team < 1 || team > Store::TeamCount)
                return false;
            std::array<uint32_t, 3> slots {};
            for (size_t i = 0; i < slots.size(); ++i)
            {
                std::optional<uint32_t> const species = Species(match[i + 2].str());
                if (!species || (*species && !SelectedPet(journal, *species, reply.ownedIds)))
                {
                    SendJournal(catalog, journal, reply);
                    return false;
                }
                slots[i] = reply.ownedIds ? *species : journal.PetIdForSpecies(*species);
            }
            if (journal.SetTeam(team, slots) != Store::TeamResult::Saved)
            {
                SendJournal(catalog, journal, reply);
                return false;
            }
            reply.send("pbj", reply.ownedIds ? "team2" : "team", TeamMessage(journal, team, reply.ownedIds));
            return true;
        }
        if (action == "active")
        {
            std::optional<uint32_t> const team = Species(payload);
            if (!team || *team < 1 || *team > Store::TeamCount)
                return false;
            journal.SetActiveTeam(static_cast<uint8_t>(*team));
            reply.send("pbj", reply.ownedIds ? "active2" : "active", std::to_string(*team));
            return true;
        }
        if (action == "feed")
            return Feed(catalog, journal, payload, reply);
        if (action == "summon")
        {
            std::optional<uint32_t> const species = Species(payload);
            if (Store::OwnedPet const* pet = species ? SelectedPet(journal, *species, reply.ownedIds) : nullptr; pet && reply.summon)
                reply.summon(pet->id);
            return false;
        }
        if (action == "dismiss")
        {
            if (reply.dismiss)
                reply.dismiss();
            return false;
        }
        if (action == "release" && reply.ownedIds)
        {
            if (reply.releaseBlocked && reply.releaseBlocked())
            {
                reply.send("pbj", "releaseerror2", "Finish your account's pet battle before releasing a pet.");
                return false;
            }
            std::optional<uint32_t> const petId = Species(payload);
            if (!petId || !journal.Release(*petId))
            {
                reply.send("pbj", "releaseerror2", "That pet cannot be released.");
                return false;
            }
            if (reply.released)
                reply.released(*petId);
            return true;
        }
        if (action == "prime")
        {
            if (std::optional<uint32_t> const count = reply.prime ? reply.prime() : std::nullopt)
                reply.send("pbj", "primed", std::to_string(*count));
            return false;
        }
        return false;
    }
}
