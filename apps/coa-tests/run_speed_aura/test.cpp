#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <initializer_list>
#include <string>
#include <vector>

using uint32 = std::uint32_t;
using int32 = std::int32_t;
enum { WORLDHOOK_ON_AFTER_CONFIG_LOAD, GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR, PLAYERHOOK_ON_LOGIN,
    PLAYERHOOK_ON_PLAYER_RESURRECT, EFFECT_0 = 0, SPELL_EFFECT_APPLY_AURA = 6 };
struct Config
{
    bool enabled = false;
    template<class T> T GetOption(char const* key, bool fallback)
    {
        assert(std::string(key) == "Ascension.RunSpeedAura.Enable" && !fallback);
        return enabled;
    }
} config;
Config* sConfigMgr = &config;
int warnings = 0;
#define LOG_WARN(...) (++warnings)
struct Player
{
    bool alive = true;
    bool aura = false;
    unsigned casts = 0;
    bool IsAlive() const { return alive; }
    bool HasAura(uint32 id) const { assert(id == 86000); return aura; }
    void AddAura(uint32 id, Player* target)
    {
        assert(id == 86000 && target == this);
        aura = true;
        ++casts;
    }
};
struct SpellInfo { uint32 Id = 86000; struct EffectInfo { int Effect = 0; } Effects[3]; };
struct WorldScript
{
    WorldScript(char const*, std::initializer_list<int>) { }
    virtual void OnAfterConfigLoad(bool) { }
};
struct GlobalScript
{
    GlobalScript(char const*, std::initializer_list<int>) { }
    virtual void OnLoadSpellCustomAttr(SpellInfo*) { }
};
struct PlayerScript
{
    PlayerScript(char const*, std::initializer_list<int>) { }
    virtual void OnPlayerLogin(Player*) { }
    virtual void OnPlayerResurrect(Player*, float, bool&) { }
};

PRODUCTION_SOURCE

enum { MOVE_RUN, SPELL_AURA_MOD_INCREASE_SPEED, SPELL_AURA_MOD_INCREASE_MOUNTED_SPEED,
    SPELL_AURA_MOD_MOUNTED_SPEED_ALWAYS, SPELL_AURA_MOD_MOUNTED_SPEED_NOT_STACK,
    SPELL_AURA_MOD_SPEED_ALWAYS, SPELL_AURA_MOD_SPEED_NOT_STACK, SPELL_AURA_MOD_DECREASE_SPEED };
struct Movement
{
    bool mounted = false;
    std::vector<int> bonuses;
    int mountBonus = 60;
    int snare = 0;
    bool IsMounted() const { return mounted; }
    int GetMaxPositiveAuraModifier(int type) const
    {
        if (type == SPELL_AURA_MOD_INCREASE_MOUNTED_SPEED)
            return mountBonus;
        if (type == SPELL_AURA_MOD_INCREASE_SPEED)
            return bonuses.empty() ? 0 : *std::max_element(bonuses.begin(), bonuses.end());
        return 0;
    }
    int GetMaxNegativeAuraModifier(int type) const
    {
        assert(type == SPELL_AURA_MOD_DECREASE_SPEED);
        return snare;
    }
    float GetTotalAuraMultiplier(int) const { return 1; }
    static void AddPct(float& amount, int percent) { amount *= 1 + percent / 100.0f; }
    float Calculate()
    {
        int32 main_speed_mod = 0;
        float stack_bonus = 1;
        float non_stack_bonus = 1;
        switch (int(MOVE_RUN))
        {
RUN_BRANCH
        }
SPEED_CALCULATION
SLOW_CALCULATION
        return speed;
    }
};

int main()
{
    ascension_run_speed_world world;
    ascension_run_speed_record record;
    ascension_run_speed_player hook;
    Player player;
    SpellInfo spell;
    world.OnAfterConfigLoad(false);
    record.OnLoadSpellCustomAttr(&spell);
    hook.OnPlayerLogin(&player);
    assert(!player.aura && spell.Effects[0].Effect == 0);
    config.enabled = true;
    world.OnAfterConfigLoad(false);
    record.OnLoadSpellCustomAttr(&spell);
    assert(spell.Effects[0].Effect == 6 && spell.Effects[1].Effect == 0 && spell.Effects[2].Effect == 0);
    SpellInfo other;
    other.Id = 123;
    record.OnLoadSpellCustomAttr(&other);
    assert(other.Effects[0].Effect == 0);
    hook.OnPlayerLogin(&player);
    hook.OnPlayerLogin(&player);
    bool sickness = false;
    hook.OnPlayerResurrect(&player, 1, sickness);
    assert(player.aura && player.casts == 1);
    player.aura = false;
    player.alive = false;
    hook.OnPlayerLogin(&player);
    assert(!player.aura);
    player.alive = true;
    hook.OnPlayerResurrect(&player, 1, sickness);
    assert(player.aura && player.casts == 2);
    config.enabled = false;
    world.OnAfterConfigLoad(true);
    assert(RunSpeedEnabled && warnings == 1);
    world.OnAfterConfigLoad(false);
    player.aura = false;
    hook.OnPlayerLogin(&player);
    assert(!player.aura);
    Movement movement;
    assert(movement.Calculate() == 1);
    movement.bonuses = {15};
    assert(std::abs(7 * movement.Calculate() - 8.05f) < 0.0001f);
    movement.bonuses = {15, 15, 8};
    assert(std::abs(movement.Calculate() - 1.15f) < 0.0001f);
    movement.bonuses = {15, 70};
    assert(std::abs(movement.Calculate() - 1.7f) < 0.0001f);
    movement.bonuses = {15};
    movement.snare = -50;
    assert(std::abs(movement.Calculate() - 0.575f) < 0.0001f);
    movement.mounted = true;
    movement.snare = 0;
    assert(std::abs(movement.Calculate() - 1.6f) < 0.0001f);
}
