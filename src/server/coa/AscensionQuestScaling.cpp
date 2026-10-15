/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionQuestScaling.h"
#include "Config.h"
#include "Log.h"
#include "Timer.h"
#include "World.h"
#include "WorldScript.h"
#include <atomic>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <unordered_map>
#include <vector>

namespace QuestScalingTable
{
namespace
{
std::unordered_map<std::uint32_t, LocalLevelScaling::QuestCurve> curves;
std::atomic<bool> loaded{false};

bool Load(std::filesystem::path const& path)
{
    std::ifstream file(path, std::ios::binary);
    std::uint32_t header[5] = {};
    if (!file || !file.read(reinterpret_cast<char*>(header), sizeof(header)) || header[0] != 0x43424457 ||
        header[2] != RecordFields || header[3] != RecordSize)
        return false;

    std::vector<char> records(std::size_t(header[1]) * RecordSize);
    if (!file.read(records.data(), std::streamsize(records.size())))
        return false;

    for (std::size_t offset = 0; offset < records.size(); offset += RecordSize)
    {
        std::array<std::int32_t, RecordFields> record;
        std::memcpy(record.data(), records.data() + offset, RecordSize);
        curves[std::uint32_t(record[QuestField])] = CurveFromRecord(record);
    }
    return true;
}

LocalLevelScaling::QuestCurve const* CurveFor(std::uint32_t questId)
{
    if (!loaded.load(std::memory_order_acquire))
        return nullptr;

    auto const itr = curves.find(questId);
    return itr == curves.end() ? nullptr : &itr->second;
}

class Configuration : public WorldScript
{
public:
    Configuration() : WorldScript("QuestScalingConfiguration",
        { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP }) { }

    void OnAfterConfigLoad(bool) override
    {
        LocalLevelScaling::QuestClientScalingFlag.store(
            sConfigMgr->GetOption<bool>("CoA.QuestLevelScaling.ClientFlag", false), std::memory_order_relaxed);
    }

    void OnStartup() override
    {
        if (loaded.load(std::memory_order_relaxed))
            return;

        std::uint32_t const started = getMSTime();
        std::filesystem::path const path =
            std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "QuestTemplateScaling.dbc";
        if (!Load(path))
        {
            curves.clear();
            LOG_ERROR("server.loading", "Quest level scaling has no curves: {} is missing or not a "
                "QuestTemplateScaling table", path.string());
            return;
        }

        loaded.store(true, std::memory_order_release);
        LOG_INFO("server.loading", ">> Loaded {} quest scaling curves in {} ms", curves.size(),
            GetMSTimeDiffToNow(started));
    }
};
}
}

void AddSC_AscensionQuestScaling()
{
    LocalLevelScaling::QuestCurveOwner.store(&QuestScalingTable::CurveFor, std::memory_order_relaxed);
    new QuestScalingTable::Configuration();
}
