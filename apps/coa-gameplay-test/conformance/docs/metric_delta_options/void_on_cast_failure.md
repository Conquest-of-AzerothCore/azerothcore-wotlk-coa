# Void on cast failure (`metric_delta` `void_on_cast_failure`, ADR 1207, provisional)

`void_on_cast_failure: true` makes the verdict `unmeasured`, never `ok` or `alert`, when the run's `cast_failures`
list any refused cast (a setup cast, a step cast or the trigger; the entry does not judge a cast). The readings keep
their explanation, followed by the refusals. It adds no step and no reading. Refused for a `cast_failure` metric, which
judges the cast itself. Absent, the verdict is unchanged.

Sun Cleric: Learning Light 300360 "or 3 casts". Illumination 500143 has a 2000 ms cast time; a cast submitted while
the previous one runs is refused (reason 105), so the count of casts that ran is not the count the entry meant.
