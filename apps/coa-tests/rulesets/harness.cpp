#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <map>
#include <set>
using uint32 = std::uint32_t;
using uint8 = std::uint8_t;
// ENUMS
using SpellEffIndex = uint32;
constexpr uint32 EFFECT_0 = 0, SPELL_EFFECT_DUMMY = 3;
constexpr int GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 1, AURA_REMOVE_BY_DEATH = 1;
constexpr int PLAYERHOOK_ON_LOGIN = 1;
using AuraRemoveMode = int;
struct Player;
struct Aura;
struct AuraApplication;
struct SpellInfo
{
    uint32 Id = 0, Attributes = 0, AttributesEx3 = 0, Stances = 0;
    bool HasAttribute(SpellAttr0 attr) const { return (Attributes & attr) != 0; }
    bool HasAttribute(SpellCustomAttributes) const { return false; }
    bool HasAttribute(SpellAttr7) const { return false; }
    bool IsChanneled() const { return false; }
    bool IsSingleTarget() const { return false; }
    bool IsDeathPersistent() const;
};
struct Unit
{
    virtual ~Unit() = default;
    virtual Player* ToPlayer() { return nullptr; }
    uint32 GetGUID() const { return 1; }
    using AuraApplicationMap = std::map<uint32, AuraApplication*>;
    using AuraMap = std::map<uint32, Aura*>;
    AuraApplicationMap m_appliedAuras;
    AuraMap m_ownedAuras;
    void _UnapplyAura(AuraApplicationMap::iterator& it, int) { it = m_appliedAuras.erase(it); }
    void RemoveOwnedAura(AuraMap::iterator& it, int) { it = m_ownedAuras.erase(it); }
    void RemoveAllAurasOnDeath();
    virtual bool HasAura(uint32) const { return false; }
};
struct Player : Unit
{
    bool resting = false;
    bool inWorld = true;
    bool IsInWorld() const { return inWorld; }
    std::set<uint32> auras;
    std::set<uint32> known;
    uint32 learns = 0;
    bool HasSpell(uint32 id) const { return known.contains(id); }
    void learnSpell(uint32 id, bool dependent) { assert(!dependent); known.insert(id); ++learns; }
    Player* ToPlayer() override { return this; }
    bool HasPlayerFlag(PlayerFlags flag) const { assert(flag == PLAYER_FLAGS_RESTING); return resting; }
    bool HasAura(uint32 id) const override { return auras.contains(id); }
    void RemoveAurasDueToSpell(uint32 id) { auras.erase(id); }
    void CastSpell(Player* target, uint32 id, bool triggered)
    {
        assert(target == this && triggered);
        auras.insert(id);
    }
};
struct Aura
{
    SpellInfo* info;
    Unit* owner;
    SpellInfo const* GetSpellInfo() const { return info; }
    uint32 GetCasterGUID() const { return owner->GetGUID(); }
    Unit* GetOwner() const { return owner; }
    bool IsPassive() const { return info->HasAttribute(SPELL_ATTR0_PASSIVE); }
    bool IsDeathPersistent() const { return info->IsDeathPersistent(); }
    bool IsSingleTarget() const { return false; }
    bool IsUsingCharges() const { return false; }
    uint32 GetCharges() const { return 0; }
    bool CanBeSaved() const;
};
struct AuraApplication { Aura* aura; Aura const* GetBase() const { return aura; } };
struct Hook { template<class T> void operator+=(T) { } };
struct SpellScript
{
    Unit* caster = nullptr;
    SpellInfo* info = nullptr;
    Hook OnCheckCast, OnEffectHit;
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual bool Load() { return true; }
    virtual void Register() { }
    Unit* GetCaster() const { return caster; }
    SpellInfo const* GetSpellInfo() const { return info; }
    bool ValidateSpellInfo(std::initializer_list<uint32> ids)
    {
        assert((std::set<uint32>(ids) == std::set<uint32>{1004019, 1004119, 9931032}));
        return true;
    }
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
};
struct ConfigMgrStub
{
    bool rulesetLoginDefault = true;
    template <class T> T GetOption(char const*, T) const { return T(rulesetLoginDefault); }
};
ConfigMgrStub configMgrStub;
#define sConfigMgr (&configMgrStub)
#define PrepareSpellScript(name)
#define RegisterSpellScript(name)
#define SpellCheckCastFn(...) 0
#define SpellEffectFn(...) 0
// NATIVE
// SOURCE
void CheckAura(SpellInfo info)
{
    Unit owner;
    Aura aura{&info, &owner};
    AuraApplication app{&aura};
    assert(aura.CanBeSaved() && aura.IsDeathPersistent());
    info.AttributesEx3 &= ~SPELL_ATTR3_ALLOW_AURA_WHILE_DEAD;
    owner.m_appliedAuras.emplace(1, &app);
    owner.m_ownedAuras.emplace(1, &aura);
    owner.RemoveAllAurasOnDeath();
    assert(owner.m_appliedAuras.empty() && owner.m_ownedAuras.empty());
    ruleset_aura_metadata metadata;
    metadata.OnLoadSpellCustomAttr(&info);
    owner.m_appliedAuras.emplace(1, &app);
    owner.m_ownedAuras.emplace(1, &aura);
    owner.RemoveAllAurasOnDeath();
    assert(owner.m_appliedAuras.size() == 1 && owner.m_ownedAuras.size() == 1 && aura.CanBeSaved());
}
int main()
{
    Player player;
    ruleset_player_spells login;
    player.known.insert(84421);
    player.known.insert(123);
    player.auras.insert(123);
    login.OnPlayerLogin(&player);
    assert((player.known == std::set<uint32>{123, 84420, 84421, 84422}) && player.learns == 2);
    assert((player.auras == std::set<uint32>{123, 9931032}));
    login.OnPlayerLogin(&player);
    assert(player.learns == 2 && (player.auras == std::set<uint32>{123, 9931032}));
    for (auto const& kept : {std::set<uint32>{1004019}, std::set<uint32>{1004119}, std::set<uint32>{9931032}})
    {
        player.auras = kept;
        login.OnPlayerLogin(&player);
        assert(player.auras == kept);
    }
    player.auras = {1004119, 9931032};
    login.OnPlayerLogin(&player);
    assert((player.auras == std::set<uint32>{9931032}));
    configMgrStub.rulesetLoginDefault = false;
    Player gated;
    login.OnPlayerLogin(&gated);
    assert((gated.known == std::set<uint32>{84420, 84421, 84422}) && gated.learns == 3 && gated.auras.empty());
    gated.auras = {1004119, 9931032};
    login.OnPlayerLogin(&gated);
    assert((gated.auras == std::set<uint32>{9931032}));
    configMgrStub.rulesetLoginDefault = true;
    Player evicted;
    evicted.inWorld = false;
    login.OnPlayerLogin(&evicted);
    assert((evicted.known == std::set<uint32>{84420, 84421, 84422}) && evicted.auras.empty());
    Unit npc;
    SpellInfo info;
    spell_ascension_ruleset_select script;
    script.caster = &npc;
    script.info = &info;
    assert(!script.Load() && script.CheckCast() == SPELL_FAILED_NOT_HERE);
    script.caster = &player;
    assert(script.Load() && script.Validate(&info) && script.CheckCast() == SPELL_FAILED_NOT_HERE);
    player.resting = true;
    assert(script.CheckCast() == SPELL_CAST_OK);
    const std::map<uint32, std::set<uint32>> modes = {
        {84420, {1004119}}, {84421, {1004019}}, {84422, {9931032}}
    };
    for (auto const& [previous, auras] : modes)
        for (auto const& [selected, expected] : modes)
        {
            (void)previous;
            player.auras = auras;
            player.auras.insert(123);
            info.Id = selected;
            script.Select(0);
            auto wanted = expected;
            wanted.insert(123);
            assert(player.auras == wanted);
            script.Select(0);
            assert(player.auras == wanted);
        }
    auto before = player.auras;
    info.Id = 123;
    script.Select(0);
    assert(player.auras == before);
    ruleset_aura_metadata metadata;
    metadata.OnLoadSpellCustomAttr(&info);
    assert(info.AttributesEx3 == 0);
    // DBC_CASES
}
