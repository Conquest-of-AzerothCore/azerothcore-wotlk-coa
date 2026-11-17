#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
constexpr uint32 NPC_MEMORY_OF_KELTHUZAD = 9417025;
constexpr int32  BLIZZARD_WARNING_MS     = 2000;
}

class spell_wisdomball_memory_blizzard : public AuraScript
{
    PrepareAuraScript(spell_wisdomball_memory_blizzard);

    bool CheckAreaTarget(Unit*)
    {
        Unit const* caster = GetCaster();
        if (!caster || !caster->IsCreature() || caster->GetEntry() != NPC_MEMORY_OF_KELTHUZAD)
            return true;

        return GetMaxDuration() - GetDuration() >= BLIZZARD_WARNING_MS;
    }

    void Register() override
    {
        DoCheckAreaTarget += AuraCheckAreaTargetFn(spell_wisdomball_memory_blizzard::CheckAreaTarget);
    }
};

void AddSC_wisdomball_memory_blizzard()
{
    RegisterSpellScript(spell_wisdomball_memory_blizzard);
}
