## Campaign011 group1 — resumed session

- 277082 Electrical Discharge: implemented. Missing354damage-event action restored via shared native handler. Mangle(Bear)damage rolls native15%; copied20%per-tick amount drives native three1000ms Nature ticks for tooltip60%total. Zero extra coefficients and native caster-area targeting/duration retained.
- 277785 Twin Fangs: implemented. Individually audited native354repair: only RaptorStrike/MongooseBite/Counterattack, equipped offhandweapon, native50%chance,100%triggeringdamage Physical child277787; explicit pending proc and zero extra coefficients. Not mass-credit from engine census.
- 278016 Big Flaming Grimfire: blocked. Compared root/278017/278015: parent promises half-strength nextSoulFire projectile, child instead describes independent level/SP/APformula. Parent also needs278018passive stats and278014ownedLivingBombextension. Precise cast-versus-impact reservation/consumption of next-cast buff unresolved; do not grant partial projectile as full root.
- 280220 Shadowcrawl: implemented. Shared354nativeevent forwards10%of periodic damage at native30%chance. Corrected destination-before-area selection for child280221so burst centers on triggering victim, preserving native8-target/radius/duration and shapeshift permissions. Zero extra coefficients; direct damage excluded.
- 270358 Spreading Plague: blocked. Reused cached diagnosis and current shared169comparison. Native payload coefficients already repaired; spread-radius/mode/copy contracts remain unresolved. No diagnostic repetition beyond bounded selected-root evidence; no invented radius/transfer semantics.

Cumulative103/100. All implementations runtime-unverified. Formatting only; no builds/tests/SQL deployment/server changes/Git.
