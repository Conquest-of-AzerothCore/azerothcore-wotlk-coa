## Campaign010 group10 — resumed session

- 271020 Tools of War: partial. Existing AscensionWildcardPhysical.cpp and live271020script/proc already handle distinct rank-chain physical abilities, preserve duration and reset on magic damage. Not a new repair; preserve existing implementation and avoid duplicate work.
- 271051 Martial Crescendo: partial. Existing shared physical-ability handler/livebinding already grants native stacking attack-speed buff with uniqueness, nonrefresh and magic-reset rules. Preserved existing source; no new implementation credit.
- 271125 Pyroclasmic Ignition: implemented. Native aura112 custom982044 lacked a matching handler. Added scoped Explosive Shot direct/periodic damage modifier requiring caster-owned ranked/twin Living Bomb:20%againstplayers and30%againstnonplayers. Other caster bombs, other spells and missing card excluded.
- 271126 Flashpoint: implemented. Added missing Explosive Shot damage proc (including periodic damage) granting native271121. Native8%critical chance perstack,6stackcap/duration retained; one-charge Pyroblast-family finish proc consumes the whole next-cast empowerment only on Pyroblast.
- 281744 Echoed Incinerate: blocked. Previous reconstruction ambiguity retained: helper tooltip PL-28*4.2 conflicts with native baselevel/PPL interpretation. AP0.3082/SP0.4742and Immolate25%known; no invented level formula or partial grant-only completion.

Cumulative93/100. All implementations runtime-unverified. Formatting only; no builds/tests/SQL deployment/server changes/Git.
