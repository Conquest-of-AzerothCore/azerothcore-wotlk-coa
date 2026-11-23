#include "Sim.h"
#include "LuaNumber.h"
#include "Pet.h"
#include "Round.h"
#include <map>

namespace CoAPetBattles::Engine
{
    namespace
    {
        std::string Health(Event const& event)
        {
            return "(" + LuaNumber(event.Number("hp")) + "/" + LuaNumber(event.Number("max")) + ")";
        }

        Side SideOf(Event const& event, std::string const& key)
        {
            return event.Text(key) == "E" ? Side::E : Side::P;
        }

        std::string const& NameOf(Battle const& battle, Event const& event, std::string const& side,
            std::string const& index)
        {
            return battle.At(SideOf(event, side), static_cast<int32_t>(event.Number(index))).name;
        }

        std::optional<std::string> Line(Battle const& battle, Event const& event, std::map<Side, std::string>& used)
        {
            std::string const& kind = event.kind;
            if (kind == "act")
            {
                used[SideOf(event, "side")] = event.Text("name");
                if (!event.Flag("dmg"))
                    return NameOf(battle, event, "side", "idx") + " uses " + event.Text("name");
                return std::nullopt;
            }
            if (kind == "dmg")
            {
                std::string const& target = NameOf(battle, event, "tside", "tidx");
                if (event.Flag("recoil"))
                    return target + " hurts itself for " + LuaNumber(event.Number("dmg")) + " " + Health(event);
                if (event.Flag("reflect"))
                    return target + " takes " + LuaNumber(event.Number("dmg")) + " reflected damage " + Health(event);
                std::string const ability = used.count(SideOf(event, "side")) ? used[SideOf(event, "side")] : "attack";
                return NameOf(battle, event, "side", "idx") + ": " + ability + " -> " + target + " " +
                    LuaNumber(event.Number("dmg")) + " " + Health(event) + (event.Flag("crit") ? " critical" : "");
            }
            if (kind == "dot")
                return NameOf(battle, event, "side", "idx") + " takes " + LuaNumber(event.Number("dmg")) +
                    " over time " + Health(event);
            if (kind == "heal")
                return NameOf(battle, event, "side", "idx") + " heals " + LuaNumber(event.Number("amt")) + " " +
                    Health(event);
            if (kind == "dodge")
            {
                Side const from = SideOf(event, "from");
                return NameOf(battle, event, "side", "idx") + " dodges " +
                    (used.count(from) ? used[from] : std::string("the attack"));
            }
            if (kind == "buff" || kind == "debuff")
                return NameOf(battle, event, "side", "idx") + ": " + event.Text("what") + " (" +
                    LuaNumber(event.Number("turns")) + " rounds)";
            if (kind == "weather")
                return event.Text("name").empty() ? std::string("weather ends") : "weather: " + event.Text("name");
            if (kind == "stunned")
                return NameOf(battle, event, "side", "idx") + LockText(event);
            if (kind == "faint")
                return NameOf(battle, event, "side", "idx") + " faints.";
            return std::nullopt;
        }
    }

    SimResult RunSim(Catalog const& catalog, uint32_t speciesA, uint32_t speciesB, int32_t level, uint32_t seed)
    {
        SimResult result;
        int32_t const maxLevel = catalog.Config().maxLevel;
        for (uint32_t species : { speciesA, speciesB })
        {
            SpeciesDef const* def = catalog.Species(species);
            if (!def)
            {
                result.error = "unknown pet species " + std::to_string(species);
                return result;
            }
            if (def->kit.empty())
            {
                result.error = "pet species " + std::to_string(species) + " has no abilities";
                return result;
            }
        }
        if (level < 1 || level > maxLevel)
        {
            result.error = "level must be 1-" + std::to_string(maxLevel);
            return result;
        }
        SeededRng rng(seed);
        Pet a = NewPet(catalog, speciesA, level, std::nullopt, rng, 4, std::nullopt);
        Pet b = NewPet(catalog, speciesB, level, std::nullopt, rng, 4, std::nullopt);
        std::string const levelText = std::to_string(level) + " rare";
        result.lines.push_back("[Pet sim] " + a.name + " (" + levelText + ") vs " + b.name + " (" + levelText +
            "), seed " + std::to_string(seed));
        Battle battle(catalog, { std::move(a) }, { std::move(b) }, rng);
        for (int32_t round = 1; round <= SimRoundLimit; ++round)
        {
            std::string const commandP = AI(battle, Side::P);
            std::string const commandE = AI(battle, Side::E);
            RoundResult const outcome = Round(battle, commandP, commandE);
            std::map<Side, std::string> used;
            for (Event const& event : outcome.events)
                if (std::optional<std::string> line = Line(battle, event, used))
                    result.lines.push_back("R" + std::to_string(round) + " " + *line);
            if (outcome.status == "win")
            {
                result.lines.push_back(battle.Current(Side::P).name + " wins.");
                return result;
            }
            if (outcome.status == "loss")
            {
                result.lines.push_back(battle.Current(Side::E).name + " wins.");
                return result;
            }
        }
        result.lines.push_back("Draw after " + std::to_string(SimRoundLimit) + " rounds.");
        return result;
    }
}
