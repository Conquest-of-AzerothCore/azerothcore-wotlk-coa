/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_BUG_REPORT_SERVICE_H
#define COA_BUG_REPORT_SERVICE_H

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>

namespace CoABugReport
{
    constexpr std::size_t MaxPayload = 12000;
    constexpr std::size_t MaxTitle = 0x80;
    constexpr std::size_t MaxDescription = 0x1000;

    struct Report
    {
        uint32_t Category = 0;
        uint32_t Priority = 0;
        bool Public = false;
        std::string Title;
        std::string Description;
    };

    struct Outcome
    {
        uint32_t Id = 0;
        std::string Error;
    };

    constexpr std::string_view Disabled = "Bug reports are not enabled on this realm.";
    constexpr std::string_view Private =
        "Reports on this realm become public GitHub issues. Tick Public to send this report.";
    constexpr std::string_view Cooldown = "Please wait a little before sending another report.";
    constexpr std::string_view Invalid =
        "The report needs a title of 3 to 128 characters and a description, without control characters.";
    constexpr std::string_view Storage = "The report could not be saved. Please try again later.";

    class Service
    {
    public:
        explicit Service(std::filesystem::path directory, uint32_t cooldown = 120)
            : _directory(std::move(directory)), _cooldown(std::max(60u, cooldown)) { }

        Outcome Submit(uint32_t account, Report const& report, std::string const& context, uint64_t now)
        {
            if (!report.Public)
                return { 0, std::string(Private) };

            std::erase_if(_lastSubmit, [now, this](auto const& pair) { return now > pair.second + _cooldown; });
            if (_lastSubmit.contains(account))
                return { 0, std::string(Cooldown) };
            if (_lastSubmit.size() >= 4096)
                return { 0, std::string(Storage) };

            std::string const payload = report.Title + '\n' + report.Description;
            if (report.Title.size() > MaxTitle || report.Description.size() > MaxDescription ||
                payload.size() > MaxPayload || !ValidPayload(payload))
                return { 0, std::string(Invalid) };

            char id[17];
            std::snprintf(id, sizeof(id), "%016llx", static_cast<unsigned long long>(now));
            std::string const key = std::to_string(account) + "-" + id;
            try
            {
                auto const request = _directory / (key + ".report");
                if (std::filesystem::exists(request))
                    return { 0, std::string(Cooldown) };

                auto const temporary = _directory / (key + ".part");
                {
                    std::ofstream output(temporary, std::ios::binary | std::ios::trunc);
                    output << "COABUG1\n" << payload << context;
                    output.flush();
                    if (!output)
                        return { 0, std::string(Storage) };
                    output.close();
                    if (!output)
                        return { 0, std::string(Storage) };
                }
                std::filesystem::rename(temporary, request);
            }
            catch (std::filesystem::filesystem_error const&)
            {
                return { 0, std::string(Storage) };
            }
            _lastSubmit[account] = now;
            return { static_cast<uint32_t>(now), {} };
        }

        static bool ValidPayload(std::string const& payload)
        {
            auto const split = payload.find('\n');
            if (split == std::string::npos || split < 3 || split > 200 || split + 2 >= payload.size())
                return false;
            if (payload.find_first_of("\r\t") < split)
                return false;
            if (payload.find_first_not_of(" \t\r\n", split + 1) == std::string::npos)
                return false;
            return std::all_of(payload.begin(), payload.end(), [](unsigned char c)
            {
                return c >= 32 || c == '\n' || c == '\r' || c == '\t';
            });
        }

    private:
        std::filesystem::path _directory;
        uint32_t _cooldown;
        std::unordered_map<uint32_t, uint64_t> _lastSubmit;
    };
}

#endif
