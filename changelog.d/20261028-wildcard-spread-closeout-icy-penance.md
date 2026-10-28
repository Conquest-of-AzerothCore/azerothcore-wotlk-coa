# Wildcard spread helper compatibility and Icy Penance

- Effect169:four additional reviewed Infected Blood/Rabies helpers now use caster-owned native aura reapplication.
  Dedicated spreading implementations remain unchanged;this does not credit additional repaired card roots.
- Effect170:three newer Dusk Till Dawn helpers now support guarded,unambiguous known-rank spell fan-out.
  Full Dusk controller activation/stack sequencing remains blocked and is not claimed repaired.
- Icy Penance271341:eight bolt ranks lacked explicit authored SP/AP scaling and the Spirit-path SP increase.
  They now use0.58SP+0.078APper bolt,and only the SP contribution doubles under the native Spirit/Healing path.
  Existing channel timing,targeting,visuals and native damage modifiers are preserved.

New world migration:rev_20261028_01_wildcard_icy_penance.sql,pending deployment.
Formatting/static checks only;all source changes runtime-unverified. No compilation or gameplay tests.
