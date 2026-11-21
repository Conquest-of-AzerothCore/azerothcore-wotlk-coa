# Hour (`metric_delta` `hour`, ADR 0699)

`hour` is a realm-local hour from 0 to 23, or absent. `fixtures` sets the scenario's top-level `hour`, which the batch
runner already honours (a simulated clock jumps to that hour and runs the case exclusively; a real clock runs it in
single mode on a worldserver whose TZ puts local time at the start of that hour), and names it in the contract.
`model` records the hour. It adds no check: the metric itself must tell the time-of-day branch apart, and a second
entry at the other hour is the control arm. Absent, the scenario is unchanged.

Witch Hunter: Evil Never Sleeps 804185 `night_agility` (hour 0: Night Hunter 807198, Agility +4%) and
`day_agility_control` (hour 12: Day Hunter 807231 instead, Agility unchanged).
