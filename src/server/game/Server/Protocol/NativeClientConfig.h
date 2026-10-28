#ifndef NATIVE_CLIENT_CONFIG_H
#define NATIVE_CLIENT_CONFIG_H

#include <cstdint>
#include <map>
#include <string>
#include <string_view>

// 0x58D replaces all six client maps. Every producer must share this snapshot.
class NativeClientConfig
{
public:
    void SetInt(std::string const& key, std::uint32_t value) { _integers[key] = value; }
    void SetBool(std::string const& key, bool value) { _booleans[key] = value; }
    void Clear() { _integers.clear(); _booleans.clear(); }

    template<class Packet>
    void Write(Packet& packet) const
    {
        auto key = [&packet](std::string_view name)
        {
            packet << std::uint32_t(name.size());
            packet.append(reinterpret_cast<std::uint8_t const*>(name.data()), name.size());
        };
        packet << std::uint32_t(_integers.size());
        for (auto const& [name, value] : _integers)
        {
            key(name);
            packet << value;
        }
        packet << std::uint32_t(_booleans.size());
        for (auto const& [name, value] : _booleans)
        {
            key(name);
            packet << std::uint8_t(value ? 1 : 0);
        }
        // Unused float, rate, integer-list and float-list maps still need counts.
        packet << std::uint32_t(0) << std::uint32_t(0)
            << std::uint32_t(0) << std::uint32_t(0);
    }

private:
    std::map<std::string, std::uint32_t> _integers;
    std::map<std::string, bool> _booleans;
};

#endif
