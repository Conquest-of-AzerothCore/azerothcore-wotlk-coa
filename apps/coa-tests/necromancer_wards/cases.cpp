namespace
{
uint32 depth = 0;
uint32 auraApplications = 0;
Unit* immune = nullptr;

bool IsWard(uint32 id)
{
    return id == 680388 || id == 681460 || id == 681529;
}

void Dispatch(Unit* target, Aura& aura, bool apply)
{
    if (!IsWard(aura.id))
        return;
    if (++depth > 16)
        throw std::runtime_error("ward reapplication recursed into the owner");
    Lifecycle hook;
    hook.fixtureId = aura.id;
    hook.fixtureCaster = aura.casterUnit;
    hook.fixtureOwner = target;
    hook.fixtureAura = aura;
    for (uint32 index = 0; index < 3; ++index)
    {
        AuraEffect effect;
        effect.index = index;
        if (apply)
            hook.Apply(&effect, 0);
        else
            hook.Removed(&effect, 0);
    }
    --depth;
}
}

Aura* Unit::AddAura(uint32 id, Unit* target)
{
    if (!target->IsAlive() || target == immune)
        return nullptr;
    auto& aura = target->auras[id];
    aura.id = id;
    aura.caster = guid;
    aura.casterUnit = this;
    aura.info = const_cast<SpellInfo*>(manager.GetSpellInfo(id));
    aura.duration = aura.info->GetDuration();
    aura.removed = false;
    ++auraApplications;
    Dispatch(target, aura, true);
    return &aura;
}

void Unit::CastSpell(Unit* target, uint32 id, bool)
{
    if (manager.GetSpellInfo(id)->Effects[0].TargetA.GetTarget() == TARGET_UNIT_CASTER)
        target = this;
    casts.push_back({id, target->guid, 0});
    AddAura(id, target);
}

void Unit::RemoveAurasDueToSpell(uint32 id, ObjectGuid caster)
{
    if (!HasAura(id, caster))
        return;
    Aura removed = auras.at(id);
    auras.erase(id);
    Dispatch(this, removed, false);
}

void CheckWards()
{
    for (uint32 id : {680388, 681460, 681529})
    {
        manager.rows[id].Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        manager.rows[id].duration = 12345;
    }
    for (uint32 count : {0, 1, 2})
    {
        states.clear();
        world.clear();
        Player owner, other;
        owner.level = 6;
        other.guid = 2;
        Creature first, second, foreign, dead;
        first.guid = 10;
        second.guid = 11;
        foreign.guid = 12;
        dead.guid = 13;
        for (Creature* minion : {&first, &second, &foreign, &dead})
        {
            minion->entry = 50065;
            minion->ownerGuid = owner.guid;
            minion->spellOwner = &owner;
            world[minion->guid] = minion;
        }
        foreign.ownerGuid = other.guid;
        foreign.spellOwner = &other;
        dead.alive = false;
        auto& army = State(&owner).minions;
        army = {{foreign.guid, 500970, 1}, {dead.guid, 500970, 1}};
        if (count > 0)
            army.push_back({first.guid, 500970, 1});
        if (count > 1)
            army.push_back({second.guid, 500970, 1});

        for (uint32 id : {681529, 680388, 681460, 681529})
        {
            auraApplications = 0;
            owner.CastSpell(&owner, id, true);
            assert(auraApplications == count + 1);
            assert(owner.HasAura(id, owner.guid));
            assert(!foreign.HasAura(id) && !dead.HasAura(id));
            for (Creature* minion : Minions(&owner))
            {
                assert(minion->HasAura(id, owner.guid));
                assert(minion->GetAura(id)->GetDuration() == owner.GetAura(id)->GetDuration());
                for (uint32 previous : {680388, 681460, 681529})
                    if (previous != id)
                        assert(!owner.HasAura(previous) && !minion->HasAura(previous));
            }
            auraApplications = 0;
            owner.CastSpell(&owner, id, true);
            assert(auraApplications == count + 1 && owner.GetAura(id)->GetStackAmount() == 1);
            owner.GetAura(id)->SetDuration(4321);
            Dispatch(&owner, *owner.GetAura(id), true);
            for (Creature* minion : Minions(&owner))
                assert(minion->GetAura(id)->GetDuration() == 4321);
        }
        if (count > 0)
            other.AddAura(681529, &first);
        owner.RemoveAurasDueToSpell(681529);
        assert(!owner.HasAura(681529) && !second.HasAura(681529));
        if (count > 0)
            assert(first.HasAura(681529, other.guid));

        immune = &first;
        owner.CastSpell(&owner, 680388, true);
        assert(!first.HasAura(680388));
        if (count > 1)
            assert(second.HasAura(680388, owner.guid));
        immune = nullptr;
        owner.RemoveAurasDueToSpell(680388);
        assert(!second.HasAura(680388));
    }
}

int main()
{
    try
    {
        CheckWards();
    }
    catch (std::runtime_error const& error)
    {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
