# Groot Coin exchange scenarios (exchange enabled)

These need `GrootCoin.ExchangeEnable = 1`, so they are not part of the default gameplay suite, which runs with the
shipped config. Copy `conf/ethereal_bazaar.conf.dist` to a directory as `ethereal_bazaar.conf`, set
`GrootCoin.Enable = 1` and `GrootCoin.ExchangeEnable = 1`, point `modules_config_dir` at that directory in a
copy of `conf/verify-all.json`, then (from the repository root):

```bash
python3 -B tools/verify_all.py --settings <that settings copy> --stages gameplay --gameplay-db-workers 1 \
    --scenario modules/mod-ethereal-bazaar/tests/scenarios/groot-coin-exchange-relog.json \
               modules/mod-ethereal-bazaar/tests/scenarios/groot-coin-exchange-coins-gone.json
```

`--gameplay-db-workers 1` matters: the exchange refuses to start with more than one characters-database worker.

| Scenario | Checks |
| --- | --- |
| `groot-coin-exchange-relog.json` | 5 of 12 coins, then "Exchange all 7"; exact counts in memory and after each relog |
| `groot-coin-exchange-coins-gone.json` | coins destroyed after the menu opened: accepting spends and pays nothing, also after relog |
