int main()
{
    ResourceService service;
    bool const graceHolds = service.AdvanceStaticDecay(1, 3, 5999) == 0;
    bool const firstSecondLoses = service.AdvanceStaticDecay(1, 3, 1) == 1;
    bool const depletionStops = service.AdvanceStaticDecay(1, 2, 2500) == 2;
    bool const depletionRestartsGrace = service.AdvanceStaticDecay(1, 3, 5999) == 0;
    service.ForgetStaticDecay(1);
    bool const forgetRestartsGrace = service.AdvanceStaticDecay(1, 3, 5999) == 0;
    service.ForgetStaticDecay(1);
    assert(graceHolds && firstSecondLoses && depletionStops && depletionRestartsGrace && forgetRestartsGrace);

    std::vector<std::thread> mapUpdaters;
    for (uint64 worker = 0; worker < 4; ++worker)
        mapUpdaters.emplace_back([&service, worker]
        {
            for (uint64 tick = 0; tick < 200000; ++tick)
            {
                ObjectGuid const guid = worker * 1000000 + tick % 512;
                if (tick % 3)
                    service.AdvanceStaticDecay(guid, 100, 62);
                else
                    service.ForgetStaticDecay(guid);
            }
        });
    for (std::thread& mapUpdater : mapUpdaters)
        mapUpdater.join();
    bool const everyTimerForgotten = [&service]
    {
        for (uint64 worker = 0; worker < 4; ++worker)
            for (uint64 slot = 0; slot < 512; ++slot)
                service.ForgetStaticDecay(worker * 1000000 + slot);
        return service._staticDecayTimers.empty();
    }();
    assert(everyTimerForgotten);
}
