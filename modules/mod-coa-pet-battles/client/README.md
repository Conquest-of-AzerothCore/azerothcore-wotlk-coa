# Pet battle client addons

These addons are based on azerothcore-linux-server commit 22bb7f3. The CoA journal uses the version 2 protocol
for individual pet copies, breed stats, team selection and release. The server also accepts the original species
protocol. Players need all three addons in the client's `Interface/AddOns/`.

- `AcoreLib` — the hidden addon-whisper transport (`ACORE` prefix) and the hello/ping handshake.
- `wotlk_petbattle` — the battle window: abilities, swaps, the trap, health bars, damage numbers. `/pbtest` holds GM
  tools.
- `wotlk_pets` — the pet journal (`/pets`): pets, abilities, teams, feeding, the follower, the 3D previews, the zone
  levels on the world map and the wild pet blips on the minimap.

`MANIFEST.sha256` pins every file; `tools/pet_data/test_client_addons.py` checks the copies against it (and against an
upstream checkout when `PET_BATTLES_UPSTREAM` names one). `Pets.lua` and `Battle.lua` carry the CoA protocol and
interface changes. Refresh the manifest when updating an addon file.
