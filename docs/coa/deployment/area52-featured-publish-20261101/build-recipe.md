# Featured Draft Publish correction — prepared November 1, 2026

Prepared client candidate: patch-E.MPQ. Review source.patch and correction-manifest.json. No installation, activation, publication, restart, SQL or DLL modification. This is not an activation-ready deployment package. Keep existing stable package unchanged.

## Finding and repair

Owner's paired observation: the same selections publish as Leveling but the Featured version returns PUBLISH_BUILD_NOT_TRAVERSIBLE. Read-only native inspection identifies CanPublishBuild -> 0x1010f440, category-specific branches and generic traversal result35. SetCategory binding0x100de360 only parses/stores the category; no dispatch or persistence in that binding. Native-plan conversion passes category into validation. These addresses describe only the DLL hash in correction-manifest.json; no binary patch is proposed. The exact proprietary failing predicate was not executed or reconstructed; do not label the name dropdown itself as proven broken.

Existing UI now uses Area52CanPublishBuild. For an Area52 GM with matching selected archetype/name/description ID, if native Featured validation returns ONLY generic traversal failure, synchronously validate the identical selections with the full native Leveling validator. Restore and read back original Featured category before returning, updating UI, saving, or showing publication consent. Name, archetype marker, skills, talents and enchants are never rewritten. Invalid progression and all other errors remain blocked. No global native API replacement; other realms/categories use original validation. Restore failure blocks saving/publishing until reopening editor. Click path revalidates, then uses existing server save acknowledgement followed by explicit author/CC0 consent; no public request is sent by validation.

Retains detailed traversal diagnostics, numeric Publish tooltip correction and existing Save behavior. Dropdown/catalog/character-creation connection preserved. Candidate preserves all16 other effective archive members byte-for-byte.

## Offline evidence

- test_featured.py: actual selector/catalog and publishing Lua methods; adapted native API exercises reported category mismatch, valid/invalid progression, metadata and mixed failures, GM/name/ID restrictions, category restoration and failure latch, isolation, exact save identity and consent after acknowledgement.
- check_dropdown.py: all56 archetypes and actual existing helper functions with frame adapter, GM transitions, editor restoration and visibility.
- test_diagnostics.py: eight diagnostic cases including unknown reasons, exact entry/level/spell location, point shortfalls, missing API detail and safe exception reporting.
- check_stage.py: numeric/boolean button behavior, preserved Save forwarding, complete Lua5.1 syntax, candidate archive readback and unchanged other members.

No live gameplay/client test. Native validator internals are not simulated as proof of real acceptance; the fixture reproduces owner-reported category behavior and tests the compatibility code. Package/distribution preparation and stable CheckOnly remain separate before any activation-ready claim. Prepared candidate has not been added to installed files or tester feed.
