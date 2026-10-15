int main()
{
    aura_ascension_epoch_renewal script;
    std::vector<int32> heals;
    script.fixtureEffect.dispatch = [&]
    {
        assert(script._nativeTick);
        script.Tick(&script.fixtureEffect);
        heals.push_back(script.fixtureEffect.amount);
    };
    script.fixtureEffect.amount = 100;
    script.Apply(&script.fixtureEffect, 1);
    assert(script.fixtureEffect.amount == 100 && script.fixtureEffect.timer == 1000);
    GameTime::now = std::chrono::milliseconds(500);
    script.aura.duration = 3000;
    script.fixtureEffect.amount = 111;
    script.Apply(&script.fixtureEffect, 1);
    assert(script.fixtureEffect.amount == 211 && script.fixtureEffect.timer == 500);
    for (int32 time : {1000, 1500, 2000, 2500, 3000})
    {
        GameTime::now = std::chrono::milliseconds(time);
        script.Tick(&script.fixtureEffect);
        assert(script.fixtureEffect.timer == 500);
    }
    assert((heals == std::vector<int32>{100, 111, 100, 111, 100}));
    assert(script.fixtureEffect.amount == 111 && !script.aura.removed);
    GameTime::now = std::chrono::milliseconds(3500);
    script.Tick(&script.fixtureEffect);
    assert(heals.back() == 111 && script.aura.removed);

    Ascension::RenewalContributions timeline;
    timeline.Add(0, 100, 3000, 1000);
    timeline.Add(0, 111, 5000, 1000);
    assert((timeline.Advance(3100) == std::vector<int32>{211, 211, 211}));
    assert(timeline.Amount() == 111 && timeline.Remaining(3100) == 1900);
    assert((timeline.Advance(5000) == std::vector<int32>{111, 111}));
    assert(timeline.Amount() == 0);
    timeline.Add(6000, 70, 2500, 1000);
    assert((timeline.Advance(8000) == std::vector<int32>{70, 70}));
    assert(timeline.Amount() == 70 && timeline.Delay(8000) == 500);
    assert(timeline.Advance(8500).empty() && timeline.Amount() == 0);
    timeline.Add(9000, INT32_MAX, 3000, 1000);
    timeline.Add(9000, INT32_MAX, 3000, 1000);
    assert(timeline.Amount() == INT32_MAX);
    assert((timeline.Advance(12000) == std::vector<int32>{INT32_MAX, INT32_MAX, INT32_MAX}));
    Ascension::RenewalContributions otherCaster;
    otherCaster.Add(0, 42, 3000, 1000);
    assert(otherCaster.Amount() == 42 && timeline.Amount() == 0);
}
