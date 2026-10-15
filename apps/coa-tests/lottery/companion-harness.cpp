#include "COLLECTIBLES_HEADER"
#include <algorithm>
#include <map>
#include <set>
#include <stdexcept>
#include <vector>
using uint32 = uint32_t;
constexpr uint32 VANITY_CATEGORY_MOUNTS = 1;
constexpr uint32 VANITY_CATEGORY_COMPANIONS = 0x08000000;
constexpr uint32 ITEM_WONDROUS_WISDOMBALL = 100;
constexpr uint32 ITEM_FIX_O_TRON_5000 = 101;
namespace AscensionCompatConfig { enum Key { LEARN_OWNED_COMPANIONS, UNLOCK_ALL_VANITY }; }
struct Config
{
    bool learn = true;
    bool unlockAll = false;
    template<class T> T GetConfigValue(AscensionCompatConfig::Key key) const
    { return key == AscensionCompatConfig::LEARN_OWNED_COMPANIONS ? learn : unlockAll; }
} ascensionCompatConfig;
struct SpellMgr
{
    std::set<uint32> available{92453, 12345};
    bool GetSpellInfo(uint32 id) const { return available.contains(id); }
} spellMgr;
auto* sSpellMgr = &spellMgr;
struct Player
{
    std::set<uint32> known;
    bool HasSpell(uint32 id) const { return known.contains(id); }
};
struct PlayerCollectionState { std::set<uint32> OwnedVanityItems; };
struct VanityInfo { uint32 LearnedSpell; uint32 CategoryMask; };
struct Service
{
    std::map<uint32, VanityInfo> _vanityItems{
        {97393, {92453, VANITY_CATEGORY_COMPANIONS}},
        {99999, {12345, VANITY_CATEGORY_COMPANIONS}}};
    COMPANION_METHOD
};
void Require(bool value) { if (!value) throw std::runtime_error("companion ownership assertion failed"); }
int main()
{
    Service service;
    Player winner, alt, unrelated;
    PlayerCollectionState owned{{97393}}, empty;
    Require(service.GetMissingOwnedCompanionSpells(&winner, owned) == std::vector<uint32>{92453});
    Require(service.GetMissingOwnedCompanionSpells(&alt, owned) == std::vector<uint32>{92453});
    Require(service.GetMissingOwnedCompanionSpells(&unrelated, empty).empty());
    winner.known.insert(92453);
    Require(service.GetMissingOwnedCompanionSpells(&winner, owned).empty());
    ascensionCompatConfig.unlockAll = true;
    Require(service.GetMissingOwnedCompanionSpells(&unrelated, empty) == std::vector<uint32>{12345});
    Require(service.GetMissingOwnedCompanionSpells(&alt, owned) == (std::vector<uint32>{12345, 92453}));
    spellMgr.available.erase(92453);
    Require(service.GetMissingOwnedCompanionSpells(&alt, owned) == std::vector<uint32>{12345});
    ascensionCompatConfig.learn = false;
    Require(service.GetMissingOwnedCompanionSpells(&alt, owned).empty());
}
