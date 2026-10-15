int main()
{
    struct Case { uint8 cls; uint32 first, last, resource; int32 amount; bool cast, each; };
    std::vector<Case> cases = {
        {14, 524706, 524706, 800058, 1, false, false},
        {14, 805240, 805240, 800058, 1, false, true},
        {16, 501421, 501432, 803102, 20, false, false},
        {16, 801844, 801844, 803102, 20, false, false},
        {16, 807105, 807111, 803102, 25, false, false},
        {16, 500043, 500043, 803102, 10, true, false},
        {16, 500925, 500925, 803102, 40, true, false},
        {16, 500927, 500927, 803102, 20, true, false},
        {16, 560032, 560032, 803102, 50, true, false},
        {17, 806869, 806874, 500906, 2, false, false},
        {17, 520005, 520005, 500906, 1, false, false},
    };
    ResourceService service;
    for (uint32 id : {500125u, 572332u, 800774u, 572907u, 560249u, 560315u, 681304u, 504263u})
    {
        Player player;
        player.cls = CLASS_SON_OF_ARUGAL;
        Spell spell{&player, {id}};
        spell.info.SpellFamilyName = 26;
        spell.info.PowerType = POWER_HEALTH;
        spell.powerCost = 100;
        service.OnSpellCast(&spell);
        assert(player.Count(SPELL_BLOODMAGE_THIRST) == 0);
        player.AddAura(SPELL_BLOODMAGE_THIRST_PASSIVE, &player);
        spell.triggered = true;
        service.OnSpellCast(&spell);
        assert(player.Count(SPELL_BLOODMAGE_THIRST) == 0);
        spell.triggered = false;
        spell.powerCost = 0;
        service.OnSpellCast(&spell);
        assert(player.Count(SPELL_BLOODMAGE_THIRST) == 0);
        spell.powerCost = 100;
        spell.info.PowerType = 1;
        service.OnSpellCast(&spell);
        assert(player.Count(SPELL_BLOODMAGE_THIRST) == 0);
        spell.info.PowerType = POWER_HEALTH;
        player.cls = 14;
        service.OnSpellCast(&spell);
        assert(player.Count(SPELL_BLOODMAGE_THIRST) == 0);
        player.cls = CLASS_SON_OF_ARUGAL;
        for (uint32 casts = 1; casts <= 12; ++casts)
        {
            service.OnSpellCast(&spell);
            assert(player.Count(SPELL_BLOODMAGE_THIRST) == int32(std::min(casts, 10u)));
        }
    }

    for (Case const& test : cases)
        for (uint32 id = test.first; id <= test.last; ++id)
        {
            Player player, enemy;
            player.cls = test.cls;
            Spell spell{&player, {id}};
            spell.triggered = true;
            service.OnSpellCast(&spell);
            service.OnSpellHitResult(&spell, &enemy, 0, 100, false);
            assert(player.Count(test.resource) == 0);
            spell.triggered = false;
            service.OnSpellHitResult(&spell, &player, 0, 100, false);
            enemy.friendly = true;
            service.OnSpellHitResult(&spell, &enemy, 0, 100, false);
            enemy.friendly = false;
            service.OnSpellHitResult(&spell, &enemy, 1, 100, false);
            assert(player.Count(test.resource) == 0);
            if (test.each)
            {
                service.OnSpellHitResult(&spell, &enemy, 0, 0, false);
                assert(player.Count(test.resource) == 0);
            }
            service.OnSpellHitResult(&spell, &enemy, 0, 100, false);
            assert(player.Count(test.resource) == (test.cast ? 0 : test.amount));
            service.OnSpellCast(&spell);
            assert(player.Count(test.resource) == test.amount);
            service.OnSpellHitResult(&spell, &enemy, 0, 100, true);
            assert(player.Count(test.resource) == test.amount * (test.each ? 2 : 1));

            int32 cap = test.resource == 803102 ? 100 : 6;
            player.AddAura(test.resource, &player)->m_stackAmount = cap - 1;
            Spell next{&player, {id}};
            service.OnSpellHitResult(&next, &enemy, 0, 100, false);
            service.OnSpellCast(&next);
            assert(player.Count(test.resource) == cap);

            player.auras.clear();
            player.cls = 8;
            Spell wrongClass{&player, {id}};
            service.OnSpellHitResult(&wrongClass, &enemy, 0, 100, false);
            service.OnSpellCast(&wrongClass);
            assert(player.Count(test.resource) == 0);
            if (test.cls == 16)
            {
                player.cls = 16;
                player.AddAura(800098, &player);
                Spell ward{&player, {id}};
                service.OnSpellHitResult(&ward, &enemy, 0, 100, false);
                service.OnSpellCast(&ward);
                assert(player.Count(803102) == 0);
            }
        }
    struct Control { uint8 cls; uint32 id; };
    for (auto const& test : std::vector<Control>{
        {14, 801901}, {14, 501257}, {14, 547210}, {14, 801312}, {14, 501281},
        {14, 500610}, {14, 500761}, {14, 500762}, {14, 802075}, {14, 805239}, {14, 803476},
        {14, 707901}, {14, 707902}, {14, 707903}, {14, 712483}, {16, 804826},
        {17, 805671}, {17, 560664}, {17, 805669}})
    {
        Player player, enemy;
        player.cls = test.cls;
        Spell spell{&player, {test.id}};
        service.OnSpellHitResult(&spell, &enemy, 0, 100, false);
        service.OnSpellCast(&spell);
        assert(player.Count(800058) == 0 && player.Count(803102) == 0 && player.Count(500906) == 0);
    }
    {
        constexpr uint32 REAP = 573303;
        constexpr uint32 SOUL_FRAGMENT = 805077;
        auto reap = [&service](Player& caster, Player& target, uint8 missInfo, uint32 damage,
            uint32 effect)
        {
            Spell spell{&caster, {REAP}};
            spell.info.Effects = {effect, 0, 0};
            service.OnSpellHitResult(&spell, &target, missInfo, damage, false);
        };

        Player player, enemy;
        player.cls = 30;

        reap(player, enemy, SPELL_MISS_NONE, 0, SPELL_EFFECT_NORMALIZED_WEAPON_DMG);
        assert(player.Count(SOUL_FRAGMENT) == 1);

        reap(player, enemy, 1, 0, SPELL_EFFECT_NORMALIZED_WEAPON_DMG);
        assert(player.Count(SOUL_FRAGMENT) == 1);

        player.auras.clear();
        reap(player, enemy, SPELL_MISS_NONE, 0, 0);
        assert(player.Count(SOUL_FRAGMENT) == 0);

        reap(player, enemy, SPELL_MISS_NONE, 100, 0);
        assert(player.Count(SOUL_FRAGMENT) == 1);

        for (uint32 effect : {SPELL_EFFECT_SCHOOL_DAMAGE, SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL,
                              SPELL_EFFECT_WEAPON_PERCENT_DAMAGE, SPELL_EFFECT_WEAPON_DAMAGE,
                              SPELL_EFFECT_NORMALIZED_WEAPON_DMG})
        {
            Player caster, target;
            caster.cls = 30;
            target.friendly = true;
            reap(caster, target, SPELL_MISS_NONE, 0, effect);
            assert(caster.Count(SOUL_FRAGMENT) == 0);

            target.friendly = false;
            reap(caster, target, SPELL_MISS_NONE, 0, effect);
            assert(caster.Count(SOUL_FRAGMENT) == 1);
        }
    }
}
