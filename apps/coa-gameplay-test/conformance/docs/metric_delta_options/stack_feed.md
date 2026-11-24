# Stack feed (`metric_delta` `stack_feed`, ADR 1249, provisional)

`stack_feed` is `{"aura": A, "cap": C, "window_ms": W, "trials": N, "source": text}`, plus an optional
`"refeed_auras": [[aura, stacks], ...]`, on an entry whose metric is `aura_stacks` of `A`, with `expected` C,
`before_expected` 0, `setup_casts`, no `attack_swings`, the plain `between` gate, and `setup_wait_ms` and `wait_ms`
below `W`. It proves a stack cap reached through a feed that applies `A` only by chance (a proc roll, a crit), where a
single reading would fail a correct cap whenever too few applications land.

The treatment phase becomes N trials. Trial 1 is the plain after phase; trials 2 to N copy it after the reading,
each opened by a wait of `W + 1000` ms so the previous trial's aura has expired. In every trial the scenario reads,
at the start, after every feed cast (`setup_casts`) and after the trigger's `wait_ms`, the `measure_actor`'s
`aura_apply_count` of `A` (every new stack and every refresh, `OnAuraApply`), its `aura_stacks` and the
`game_time_ms` (labels `<spell> stack_feed t<trial> p<poll> count|stacks|clock`). `refeed_auras` are set again on the
caster after every treatment feed cast, so a spender's resource fixture does not run out; they are preconditions,
not the claim.

Any stacks read above C alerts its trial first, whatever the trial's validity (review I4): a cap that breaks only in a
trial that is otherwise void still fails. Otherwise a trial is void (never a pass or a fail) when a read is missing, `A`
has stacks at its start, it counts fewer than C + 1 applications, a span from the poll before one application bracket to
the poll that ends the next one (or the end read) reaches `W` (an expiry is possible inside it), or `A` is gone at the
end read. A valid trial passes when the most stacks read equal C; more, or fewer after C + 1 applications without a
possible expiry, alert. The verdict alerts when the control reading is not 0 or a valid trial alerts, is `ok` when at
least one trial is valid and none alerts, and `unmeasured` when every trial is void. It states the void rate v (voided /
N), the residual `v^N` (at most 0.05% is the target, sized from the larger v of a counted pair) and the applications per
feed cast of the valid trials. Python only, opt-in: every read already exists.

Named points: `phase_steps` (the start poll), `setup_cast_steps` (the refeed and the poll after every feed cast),
`fixtures` (the end poll, the repeated trials and the contract), `model`, `verdict`.

Felsworn: Malice of Gul'dan 800214 `felstrike_stack_cap` (Felstrike 802678 on the dummy, cap 3, 6000 ms).
