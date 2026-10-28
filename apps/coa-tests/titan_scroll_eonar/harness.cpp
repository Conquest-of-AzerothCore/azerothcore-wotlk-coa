#include <algorithm>
#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <map>
#include <optional>
#include <utility>
#include <vector>

using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;

// NATIVE

enum PlayerHook : uint16
{
    PLAYERHOOK_ON_CREATURE_KILL = 1
};

struct Position
{
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    float o = 0.0f;
    bool operator==(Position const&) const = default;
};

struct Aura
{
};

struct SpellInfo
{
    uint32 Id = 0;
};

struct Unit
{
    Position position;
    uint32 maxHealth = 0;
    Position GetPosition() const { return position; }
    uint32 GetMaxHealth() const { return maxHealth; }
};

struct Creature : Unit
{
    bool summon = false;
    bool critter = false;
    bool totem = false;
    bool IsSummon() const { return summon; }
    bool IsCritter() const { return critter; }
    bool IsTotem() const { return totem; }
};

struct SpellCastTargets
{
    std::optional<Position> destination;
    void SetDst(Position const& target) { destination = target; }
};

struct Cast
{
    uint32 spell = 0;
    std::optional<Position> destination;
    std::map<SpellValueMod, int32> values;
};

struct Player : Unit
{
    Aura aura;
    std::vector<uint32> auras;
    uint32 zone = 0;
    std::vector<Cast> casts;

    Aura* GetAura(uint32 spellId)
    {
        return std::find(auras.begin(), auras.end(), spellId) != auras.end() ? &aura : nullptr;
    }

    uint32 GetZoneId() const { return zone; }

    void CastSpell(SpellCastTargets const& targets, SpellInfo const* spell, CustomSpellValues const* values,
        TriggerCastFlags)
    {
        Cast cast{ spell->Id, targets.destination, {} };
        if (values)
            for (auto const& [mod, value] : *values)
                cast.values[mod] = value;
        casts.push_back(cast);
    }
};

struct AreaTableEntry
{
    uint32 flags = 0;
};

struct AreaTableStore
{
    std::map<uint32, AreaTableEntry> entries;

    AreaTableEntry const* LookupEntry(uint32 id) const
    {
        auto found = entries.find(id);
        return found == entries.end() ? nullptr : &found->second;
    }
} sAreaTableStore;

struct SpellStore
{
    std::map<uint32, SpellInfo> spells;

    SpellInfo const* GetSpellInfo(uint32 id) const
    {
        auto found = spells.find(id);
        return found == spells.end() ? nullptr : &found->second;
    }
} spellStore;

SpellStore* const sSpellMgr = &spellStore;

namespace LocalLevelScaling
{
uint32 viewMaxHealth = 0;

uint32 ViewMaxHealthFor(Player const*, Creature const*)
{
    return viewMaxHealth;
}
}

std::vector<int> rolledChances;
bool rollSucceeds = false;

bool roll_chance_i(int chance)
{
    rolledChances.push_back(chance);
    return rollSucceeds;
}

struct PlayerScript
{
    std::vector<uint16> hooks;
    PlayerScript(char const*, std::vector<uint16> enabledHooks) : hooks(std::move(enabledHooks)) { }
    virtual ~PlayerScript() = default;
    virtual void OnPlayerCreatureKill(Player*, Creature*) { }
};

// SOURCE

struct Kill
{
    std::vector<int> rolls;
    std::vector<Cast> casts;
};

Kill Resolve(Player& killer, Creature& killed, bool roll)
{
    rolledChances.clear();
    rollSucceeds = roll;
    killer.casts.clear();
    titan_scroll_eonar_kill script;
    assert(script.hooks == std::vector<uint16>{ PLAYERHOOK_ON_CREATURE_KILL });
    script.OnPlayerCreatureKill(&killer, &killed);
    return { rolledChances, killer.casts };
}

bool Nothing(Kill const& kill)
{
    return kill.rolls.empty() && kill.casts.empty();
}

void AssertBlessing(Kill const& kill, Position const& corpse, uint32 shownMaxHealth)
{
    int32 const perTick = int32(shownMaxHealth * EXPECTED_HEAL_PERCENT / 100);
    assert(kill.rolls == std::vector<int>{ EXPECTED_CHANCE });
    assert(kill.casts.size() == 1);
    Cast const& cast = kill.casts.front();
    assert(cast.spell == BLESSING_SPELL);
    assert(cast.destination && *cast.destination == corpse);
    assert((cast.values == std::map<SpellValueMod, int32>{ { SPELLVALUE_BASE_POINT0, perTick },
                                                          { SPELLVALUE_BASE_POINT1, perTick } }));
}

int main()
{
    constexpr uint32 openWorldZone = 12;
    constexpr uint32 capitalZone = 1519;
    sAreaTableStore.entries[openWorldZone] = {};
    sAreaTableStore.entries[capitalZone] = { AREA_FLAG_CAPITAL };
    spellStore.spells[BLESSING_SPELL] = { BLESSING_SPELL };

    Player killer;
    killer.position = { 10.0f, 20.0f, 30.0f, 1.0f };
    killer.zone = openWorldZone;
    Creature prey;
    prey.position = { 1.0f, 2.0f, 3.0f, 0.5f };
    prey.maxHealth = 1000;

    assert(Nothing(Resolve(killer, prey, true)));

    killer.auras = { BUFF_SPELL };
    for (bool Creature::*kind : { &Creature::summon, &Creature::critter, &Creature::totem })
    {
        prey.*kind = true;
        assert(Nothing(Resolve(killer, prey, true)));
        prey.*kind = false;
    }

    killer.zone = capitalZone;
    assert(Nothing(Resolve(killer, prey, true)));
    killer.zone = openWorldZone;

    Kill const missed = Resolve(killer, prey, false);
    assert(missed.rolls == std::vector<int>{ EXPECTED_CHANCE } && missed.casts.empty());

    AssertBlessing(Resolve(killer, prey, true), prey.position, prey.maxHealth);

    prey.maxHealth = 140;
    LocalLevelScaling::viewMaxHealth = 872;
    AssertBlessing(Resolve(killer, prey, true), prey.position, LocalLevelScaling::viewMaxHealth);
}
