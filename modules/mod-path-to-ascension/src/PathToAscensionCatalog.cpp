/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "PathToAscension.h"
#include "ClientDBC.h"

#include <filesystem>
#include <set>

namespace PathToAscension
{
    bool Catalog::Load(std::string const& dbcDirectory, std::string& error)
    {
        Catalog candidate;
        ClientDBC tutorials;
        ClientDBC rewards;
        ClientDBC objectives;
        ClientDBC categories;
        std::filesystem::path const directory(dbcDirectory);
        error.clear();

        // Tutorial.dbc declares 92 fields in its header but its physical record holds 93 DWORDs.
        if (!tutorials.Load((directory / "Tutorial.dbc").string(), 93)
            || !rewards.Load((directory / "TutorialRewards.dbc").string(), 4)
            || !objectives.Load((directory / "TutorialObjectives.dbc").string(), 24)
            || !categories.Load((directory / "TutorialCategories.dbc").string(), 18))
        {
            error = "Unable to load the client tutorial DBC tables";
            return false;
        }

        for (uint32 index = 0; index < categories.GetRecordCount(); ++index)
        {
            ClientDBC::Record const record = categories.GetRecord(index);
            uint32 const id = record.GetUInt32(0);
            if (!id || !candidate._categories.emplace(id, std::string(record.GetString(1))).second)
            {
                error = "Invalid or duplicate tutorial category ID";
                return false;
            }
        }

        for (uint32 index = 0; index < tutorials.GetRecordCount(); ++index)
        {
            ClientDBC::Record const record = tutorials.GetRecord(index);
            Tutorial tutorial{};
            for (uint32 field = 0; field < tutorial.fields.size(); ++field)
                tutorial.fields[field] = record.GetUInt32(field);
            tutorial.icon = record.GetString(35);
            tutorial.auxiliaryText = record.GetString(36);
            tutorial.name = record.GetString(37);
            tutorial.pages = record.GetString(54);
            tutorial.hint = record.GetString(71);

            uint32 const id = tutorial.Id();
            if (!id || candidate._tutorials.contains(id))
            {
                error = "Invalid or duplicate tutorial ID";
                return false;
            }

            if (tutorial.CategoryId() && !candidate._categories.contains(tutorial.CategoryId()))
            {
                error = "Tutorial references an unknown category";
                return false;
            }

            if (tutorial.QuestId())
                candidate._quests[tutorial.QuestId()].push_back(id);
            candidate._tutorials.emplace(id, std::move(tutorial));
        }

        // The client tables keep reward and objective rows of removed tutorials. They are never
        // attached to another tutorial.
        std::set<uint32> rewardIds;
        for (uint32 index = 0; index < rewards.GetRecordCount(); ++index)
        {
            ClientDBC::Record const record = rewards.GetRecord(index);
            Reward const reward{record.GetUInt32(0), record.GetUInt32(2), record.GetUInt32(3)};
            if (!reward.itemId || !reward.count || !rewardIds.insert(reward.rowId).second)
            {
                error = "Invalid or duplicate tutorial reward row";
                return false;
            }

            auto const tutorial = candidate._tutorials.find(record.GetUInt32(1));
            if (tutorial != candidate._tutorials.end())
                tutorial->second.rewards.push_back(reward);
        }

        std::set<uint32> objectiveIds;
        for (uint32 index = 0; index < objectives.GetRecordCount(); ++index)
        {
            ClientDBC::Record const record = objectives.GetRecord(index);
            Objective objective{record.GetUInt32(0), record.GetUInt32(2), {}, std::string(record.GetString(7))};
            if (!objectiveIds.insert(objective.id).second)
            {
                error = "Duplicate tutorial objective row";
                return false;
            }

            for (uint32 field = 0; field < objective.data.size(); ++field)
                objective.data[field] = record.GetUInt32(3 + field);

            auto const tutorial = candidate._tutorials.find(record.GetUInt32(1));
            if (tutorial != candidate._tutorials.end())
                tutorial->second.objectives.push_back(std::move(objective));
        }

        if (candidate._tutorials.empty() || candidate._quests.empty())
        {
            error = "The tutorial catalog is empty";
            return false;
        }

        *this = std::move(candidate);
        return true;
    }

    Tutorial const* Catalog::Find(uint32 id) const
    {
        auto const found = _tutorials.find(id);
        return found == _tutorials.end() ? nullptr : &found->second;
    }
}
