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
    GameTime::now = std::chrono::milliseconds(1000);
    script.Tick(&script.fixtureEffect);
    assert(script.fixtureEffect.timer == 1000 && !script.aura.removed);
    GameTime::now = std::chrono::milliseconds(2000);
    script.Tick(&script.fixtureEffect);
    assert(script.fixtureEffect.timer == 1000 && !script.aura.removed);
    GameTime::now = std::chrono::milliseconds(3000);
    script.Tick(&script.fixtureEffect);
    assert(script.fixtureEffect.timer == 500 && !script.aura.removed);
    assert((heals == std::vector<int32>{211, 211, 211}));
    GameTime::now = std::chrono::milliseconds(3500);
    script.Tick(&script.fixtureEffect);
    assert(heals.size() == 3 && script.aura.removed);

    Ascension::RenewalContributions live;
    live.Add(0, 212, 11000, 1000);
    assert((live.Advance(1000) == std::vector<int32>{212}));
    live.Add(1559, 245, 11000, 1000);
    assert(live.Amount() == 437 && live.Delay(1559) == 441);
    assert((live.Advance(12000) == std::vector<int32>(11, 437)));
    assert(live.Remaining(12000) == 559 && live.Delay(12000) == 559);
    assert(live.Advance(12559).empty() && live.Amount() == 0);

    Ascension::RenewalContributions timeline;
    timeline.Add(0, 100, 3000, 1000);
    assert((timeline.Advance(1000) == std::vector<int32>{100}));
    timeline.Add(1200, 100, 3000, 1000);
    assert(timeline.Amount() == 166 && timeline.Delay(1200) == 800);
    assert((timeline.Advance(2000) == std::vector<int32>{166}));
    timeline.Add(2400, 100, 3000, 1000);
    assert(timeline.Amount() == 210 && timeline.Delay(2400) == 600);
    assert((timeline.Advance(5000) == std::vector<int32>{210, 210, 210}));
    assert(timeline.Advance(5400).empty() && timeline.Amount() == 0);

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
