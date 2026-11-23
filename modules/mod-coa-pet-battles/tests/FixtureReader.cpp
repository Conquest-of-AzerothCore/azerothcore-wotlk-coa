#include "FixtureReader.h"
#include <filesystem>
#include <fstream>
#include <stdexcept>

namespace CoAPetBattles::Fixtures
{
    namespace
    {
        std::filesystem::path Directory()
        {
            return std::filesystem::path(__FILE__).parent_path() / "fixtures";
        }

        std::vector<std::string> ReadLines(std::string const& name)
        {
            std::ifstream file(Directory() / name);
            if (!file)
                throw std::runtime_error("cannot open fixture " + name);
            std::vector<std::string> lines;
            std::string line;
            while (std::getline(file, line))
                if (!line.empty())
                    lines.push_back(line);
            return lines;
        }

        uint32_t U(std::string const& text) { return static_cast<uint32_t>(std::stoul(text)); }
        int32_t I(std::string const& text) { return static_cast<int32_t>(std::stol(text)); }
        double D(std::string const& text) { return std::stod(text); }
        bool B(std::string const& text) { return text != "0"; }

        void AddRow(DataSet& data, std::vector<std::string> const& f)
        {
            std::string const& table = f[0];
            if (table == "coa_pet_species")
                data.species[U(f[1])] = { U(f[1]), f[2], U(f[3]), B(f[4]), B(f[5]), B(f[6]), B(f[7]), B(f[8]), f[9],
                    static_cast<float>(D(f[10])) };
            else if (table == "coa_pet_kit")
                data.kits[U(f[1])] = { U(f[1]), f[2], static_cast<uint8_t>(U(f[3])), static_cast<int16_t>(I(f[4])),
                    static_cast<int16_t>(I(f[5])), static_cast<int16_t>(I(f[6])) };
            else if (table == "coa_pet_kit_ability")
                data.kitAbilities.push_back({ U(f[1]), static_cast<uint8_t>(U(f[2])), static_cast<uint8_t>(U(f[3])),
                    U(f[4]) });
            else if (table == "coa_pet_ability")
                data.abilities[U(f[1])] = { U(f[1]), f[2], static_cast<int8_t>(I(f[3])),
                    static_cast<uint8_t>(U(f[4])), f[5], U(f[6]) };
            else if (table == "coa_pet_ability_turn")
                data.turns.push_back({ U(f[1]), static_cast<uint8_t>(U(f[2])), static_cast<uint8_t>(U(f[3])),
                    static_cast<uint8_t>(U(f[4])) });
            else if (table == "coa_pet_ability_effect")
            {
                AbilityEffect row { U(f[1]), static_cast<uint8_t>(U(f[2])), static_cast<uint8_t>(U(f[3])),
                    static_cast<uint16_t>(U(f[4])), U(f[5]), {} };
                for (size_t i = 0; i < row.params.size(); ++i)
                    row.params[i] = I(f[6 + i]);
                data.effects.push_back(row);
            }
            else if (table == "coa_pet_effect_property")
                data.labels.push_back({ static_cast<uint16_t>(U(f[1])), static_cast<uint8_t>(U(f[2])), f[3] });
            else if (table == "coa_pet_state")
                data.states[static_cast<uint16_t>(U(f[1]))] = { static_cast<uint16_t>(U(f[1])), f[2] };
            else if (table == "coa_pet_aura_state")
                data.auraStates.push_back({ U(f[1]), f[2], I(f[3]) });
            else if (table == "coa_pet_xp")
                data.xp[static_cast<uint8_t>(U(f[1]))] = { static_cast<uint8_t>(U(f[1])),
                    static_cast<uint16_t>(U(f[2])), static_cast<uint16_t>(U(f[3])) };
            else if (table == "coa_pet_presentation")
                data.presentations.push_back({ U(f[1]), static_cast<uint8_t>(U(f[2])), static_cast<uint8_t>(U(f[3])),
                    static_cast<uint8_t>(U(f[4])), U(f[5]), f[6], f[7], f[8], f[9], U(f[10]), B(f[11]), f[12],
                    U(f[13]), B(f[14]), B(f[15]), B(f[16]) });
            else
                throw std::runtime_error("unexpected fixture table " + table);
        }

        std::optional<std::array<int32_t, 3>> Picks(std::string const& text)
        {
            if (text == "nil")
                return std::nullopt;
            std::array<int32_t, 3> picks {};
            size_t start = 0;
            for (size_t i = 0; i < picks.size(); ++i)
            {
                size_t const comma = text.find(',', start);
                picks[i] = I(text.substr(start, comma - start));
                start = comma + 1;
            }
            return picks;
        }
    }

    std::string DecodeField(std::string const& text)
    {
        std::string decoded;
        for (size_t i = 0; i < text.size(); ++i)
        {
            if (text[i] != '\\' || i + 1 == text.size())
            {
                decoded += text[i];
                continue;
            }
            char const next = text[++i];
            decoded += next == 't' ? '\t' : next == 'n' ? '\n' : next;
        }
        return decoded;
    }

    std::vector<std::string> SplitLine(std::string const& line)
    {
        std::vector<std::string> fields;
        size_t start = 0;
        while (true)
        {
            size_t const tab = line.find('\t', start);
            fields.push_back(DecodeField(line.substr(start, tab == std::string::npos ? std::string::npos : tab - start)));
            if (tab == std::string::npos)
                return fields;
            start = tab + 1;
        }
    }

    DataSet LoadData()
    {
        DataSet data;
        for (std::string const& line : ReadLines("pet_data.txt"))
            AddRow(data, SplitLine(line));
        return data;
    }

    std::vector<TraceBattle> LoadTraces()
    {
        std::vector<TraceBattle> battles;
        for (std::string const& line : ReadLines("traces.txt"))
        {
            size_t const tab = line.find('\t');
            std::string const tag = line.substr(0, tab);
            if (tag == "EV")
            {
                battles.back().rounds.back().events.push_back(line.substr(tab + 1));
                continue;
            }
            std::vector<std::string> const f = SplitLine(line);
            if (tag == "BATTLE")
                battles.push_back({ I(f[1]), {}, {}, {}, {}, {} });
            else if (tag == "KITTIP" || tag == "KITTIPX")
                battles.back().kitTips.push_back({ f[1], I(f[2]), I(f[3]), I(f[4]), f[5], tag == "KITTIPX" });
            else if (tag == "ROLL")
                battles.back().rolls.push_back({ I(f[1]), I(f[2]), I(f[3]) });
            else if (tag == "PET")
                battles.back().pets.push_back({ f[1], I(f[2]), U(f[3]), I(f[4]), I(f[5]), Picks(f[6]),
                    f[7] == "nil" ? std::nullopt : std::optional<double>(D(f[7])), {} });
            else if (tag == "BUILT")
                battles.back().pets.back().built.assign(f.begin() + 3, f.end());
            else if (tag == "TIP" || tag == "TIPX")
                battles.back().tips.push_back({ f[1], I(f[2]), I(f[3]), f[4], tag == "TIPX" });
            else if (tag == "CMD")
                battles.back().rounds.push_back({ f[1], f[2], {}, {}, {} });
            else if (tag == "STATUS")
                battles.back().rounds.back().status = f[1];
            else if (tag == "STATE")
                battles.back().rounds.back().states.emplace_back(f.begin() + 1, f.end());
            else if (tag != "END")
                throw std::runtime_error("unexpected trace line " + tag);
        }
        return battles;
    }
}
