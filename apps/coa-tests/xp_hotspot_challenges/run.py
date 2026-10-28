from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]


def function(path, signature):
    source = (root / path).read_text(encoding='utf-8')
    start = source.index(signature)
    opening = source.index('{', start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


binding_path = 'modules/mod-coa-challenges/src/CoA.Challenges.Scripts.cpp'
binding = function(binding_path, 'bool OnPlayerHasNoBonusExperience(Player* player) override')
dispatch = function('src/server/game/Scripting/ScriptDefines/PlayerScript.cpp',
                    'bool ScriptMgr::OnPlayerHasNoBonusExperience(Player* player)')
registration = (root / binding_path).read_text(encoding='utf-8').split('CoAChallengesPlayer() :', 1)[1].split('{ }', 1)[0]
assert 'PLAYERHOOK_ON_HAS_NO_BONUS_EXPERIENCE' in registration
source = r'''
#include <cassert>
#include <string>
#include <vector>
struct Player { bool restricted = false; };
bool PlayerHasRule(Player* player, char const* rule)
{
    assert(std::string(rule) == "CHALLENGE_RULES_TYPE_NO_BONUS_EXPERIENCE");
    return player && player->restricted;
}
struct PlayerScript
{
    bool enabled = true;
    virtual bool OnPlayerHasNoBonusExperience(Player*) { return false; }
    virtual ~PlayerScript() = default;
};
struct ChallengeScript : PlayerScript {
''' + binding + r'''
};
std::vector<PlayerScript*> scripts;
struct ScriptMgr { bool OnPlayerHasNoBonusExperience(Player* player); };
#define CALL_ENABLED_HOOKS(type, hook, body) for (auto* script : scripts) if (script->enabled) { body }
''' + dispatch + r'''
int main()
{
    ScriptMgr manager;
    Player player;
    ChallengeScript challenge;
    PlayerScript other;
    assert(!manager.OnPlayerHasNoBonusExperience(&player));
    scripts = {&challenge, &other};
    assert(!manager.OnPlayerHasNoBonusExperience(&player));
    player.restricted = true;
    assert(manager.OnPlayerHasNoBonusExperience(&player));
    scripts = {&other, &challenge};
    assert(manager.OnPlayerHasNoBonusExperience(&player));
    challenge.enabled = false;
    assert(!manager.OnPlayerHasNoBonusExperience(&player));
    challenge.enabled = true;
    player.restricted = false;
    assert(!manager.OnPlayerHasNoBonusExperience(&player));
}
'''
with tempfile.TemporaryDirectory() as folder:
    path = Path(folder)
    (path / 'test.cpp').write_text(source)
    subprocess.run(['g++', '-std=c++20', str(path / 'test.cpp'), '-o', str(path / 'test')], check=True)
    subprocess.run([str(path / 'test')], check=True)
print('Production challenge binding and query aggregation passed; mocked hook registry, no gameplay.')
