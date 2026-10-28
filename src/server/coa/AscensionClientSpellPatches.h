#ifndef ASCENSION_CLIENT_SPELL_PATCHES_H
#define ASCENSION_CLIENT_SPELL_PATCHES_H

#include "Define.h"
#include <array>
#include <mutex>
#include <optional>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace Ascension
{
    template<class Tag>
    class ClientPatches
    {
    public:
        using Selector = std::array<uint32, 3>;
        using EnabledPredicate = bool (*)();
        enum class Delivery { Login, Item };

        static ClientPatches& Instance()
        {
            static ClientPatches patches;
            return patches;
        }

        void Register(uint32 id, Selector const& selector = {}, EnabledPredicate enabled = nullptr,
            Delivery delivery = Delivery::Login)
        {
            std::lock_guard lock(_mutex);
            std::vector<Patch>& patches = _patches[id];
            for (Patch& patch : patches)
                if (patch.enabled == enabled && patch.delivery == delivery)
                {
                    Merge(patch.selector, selector);
                    return;
                }
            patches.push_back({ selector, enabled, delivery });
        }

        std::unordered_set<uint32> GetIds(bool includeDisabled = false) const
        {
            std::lock_guard lock(_mutex);
            std::unordered_set<uint32> ids;
            for (auto const& [id, patches] : _patches)
                for (Patch const& patch : patches)
                    if (includeDisabled || patch.IsEnabled())
                    {
                        ids.insert(id);
                        break;
                    }
            return ids;
        }

        bool Contains(uint32 id, std::optional<Delivery> delivery = std::nullopt) const
        {
            std::lock_guard lock(_mutex);
            auto const found = _patches.find(id);
            if (found != _patches.end())
                for (Patch const& patch : found->second)
                    if (patch.IsEnabled() && (!delivery || patch.delivery == *delivery))
                        return true;
            return false;
        }

        Selector GetSelector(uint32 id) const
        {
            std::lock_guard lock(_mutex);
            Selector selector{};
            auto const found = _patches.find(id);
            if (found != _patches.end())
                for (Patch const& patch : found->second)
                    if (patch.IsEnabled())
                        Merge(selector, patch.selector);
            return selector;
        }

    private:
        struct Patch
        {
            Selector selector;
            EnabledPredicate enabled;
            Delivery delivery;

            bool IsEnabled() const { return !enabled || enabled(); }
        };

        static void Merge(Selector& destination, Selector const& source)
        {
            for (std::size_t word = 0; word < destination.size(); ++word)
                destination[word] |= source[word];
        }

        mutable std::mutex _mutex;
        std::unordered_map<uint32, std::vector<Patch>> _patches;
    };

    using ClientSpellPatches = ClientPatches<struct SpellPatchTag>;
    using ClientItemPatches = ClientPatches<struct ItemPatchTag>;
}

#endif
