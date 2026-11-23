# After auras present (`metric_delta` `after_auras_present`)

`after_auras_present` is a non-empty list of distinct `{"aura": id, "source": text}`. Right before the after reading,
the scenario reads the `aura` metric of each `aura` on the caster. A run in which one of them is absent (or its read is
missing) is `unmeasured`: the after reading is not the arm the entry states. With all of them present the verdict is
the plain `metric_delta` verdict. `source` names where each aura comes from.

Use it for the guards of an after reading: a condition the treatment needs at the read (a silence a striker cast),
and a control arm in the same run that must read present under that condition (a second aura the condition must not
remove). An absent guard can never turn into a false `ok` or a false alert.

Named point: `verdict(verdict, run, value)`, as `before_aura_absent` and `strike_landed`; `fixtures` adds the reads.
No other named point of `metric_delta_scenario` is used.

Witch Doctor: Ingredient: Bloodthistle 801664 `cauldron_silenced` (player report #10643): Spell Lock 24259 from the
striker (the silence) and the Fish Oil Cauldron buff 803269 (Ingredient: Fish Oil 801662, brewed beside Bloodthistle
under Mixologist 561069; PreventionType 0, so it refreshes while silenced).
