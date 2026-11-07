from pathlib import Path
import os
import re
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
MODULE = ROOT / 'modules/mod-manastorm-endless/src'


def method(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def vendor_ranks():
    header = (ROOT / 'src/server/coa/AscensionManastormGadgets.h').read_text(encoding='utf-8')
    gadgets = [tuple(map(int, row)) for row in re.findall(
        r'\{(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(?:true|false)\}', header)]
    migration = ROOT / 'data/sql/updates/pending_db_world/zz_manastorm_cogsworth_ranks.sql'
    text = migration.read_text(encoding='utf-8')
    rows = re.findall(r'\(23, 179539, (\d+), 0, 0, 25, 0, (\d+), 0, 0, ([01]),', text)
    conditions = {}
    for item, spell, negative in rows:
        conditions.setdefault(int(item), []).append((int(spell), bool(int(negative))))
    assert len(gadgets) == 149 and len(conditions) == 149
    families = {}
    for gadget in gadgets:
        families.setdefault(gadget[3], []).append(gadget)
    for family in families.values():
        family.sort(key=lambda item: item[4])
        for owned in range(len(family) + 1):
            known = {item[1] for item in family[:owned]}
            visible = [item[0] for item in family
                       if all((spell in known) != negative for spell, negative in conditions[item[0]])]
            expected = [family[owned][0]] if owned < len(family) else []
            assert visible == expected, (family[0][3], owned, visible, expected)
        for highest in range(len(family)):
            known = {family[highest][1]}
            visible = [item[0] for item in family
                       if all((spell in known) != negative for spell, negative in conditions[item[0]])]
            assert not any(item[0] in visible for item in family[:highest + 1])



def scaling_curve():
    text = (ROOT / 'data/sql/updates/pending_db_world/zz_manastorm_tuning_curve.sql').read_text(encoding='utf-8')
    rows = {int(d): (float(h), float(v)) for d, h, v in re.findall(
        r'\((\d+), ([0-9.]+), ([0-9.]+), 1, 1\)', text)}
    assert sorted(rows) == list(range(1, 2001))
    anchors = [(1, .60, .20), (10, .70, .23), (25, .85, .27), (50, 1., .30),
               (100, 1.25, .40), (200, 1.75, .60), (500, 3., 1.), (1000, 5., 1.75), (2000, 9., 3.)]
    for lo, hi in zip(anchors, anchors[1:]):
        for depth in range(lo[0], hi[0] + 1):
            fraction = (depth - lo[0]) / (hi[0] - lo[0])
            for column in (0, 1):
                expected = lo[column + 1] + fraction * (hi[column + 1] - lo[column + 1])
                assert abs(rows[depth][column] - expected) < .000001
    groups = re.findall(r'\((\d+), (\d+), ([0-9.]+), ([0-9.]+), 1, 1, 1\)', text)
    assert len(groups) == 5
    for n, row in enumerate(groups, 1):
        low, high, health, damage = row
        assert int(low) == int(high) == n
        assert abs(float(health) - (1 + .6 * (n - 1))) < .000001
        assert abs(float(damage) - (1 + .05 * (n - 1))) < .000001


def main():
    source = (MODULE / 'ManastormMgr.cpp').read_text(encoding='utf-8')
    spells = (MODULE / 'Manastorm.cpp').read_text(encoding='utf-8')
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    functions = {'COMPANION_ATTACK': 'bool SuppressPreparingCompanionAttack(', 'PROTECT': 'void ApplySafetyBubbleProtection(', 'CLEAR': 'void ClearSafetyBubble(',
                 'CAPTURE': 'void CaptureStageCompanions(', 'RESTORE': 'void RestoreStageCompanions(',
                 'USABLE': 'bool ManastormMgr::IsPlayerInUsableEndlessStage(',
                 'HEARTS': 'void ManastormMgr::UpdateHeartPickups(',
                 'TRANSITION_PROTECTION': 'bool ManastormMgr::IsPlayerProtectedDuringTransition('}
    functions.update({
        'RECOVERABLE_BUFF': 'bool IsRecoverableStageBuff(',
        'CLEAR_DEBUFFS': 'void ClearStageDebuffs(',
        'CAPTURE_RECOVERY': 'void CaptureStageRecovery(',
        'RESTORE_RECOVERY': 'void RestoreStageRecovery(',
        'PREPARE_MEMBER_TRANSFER': 'bool PrepareStageMemberTransfer(',
        'PROTECTED_PORTAL': 'bool IsProtectedStagePortal(',
        'LEFT_ENTRANCE': 'bool HasPlayerLeftStageEntrance(',
    })
    run_header = (MODULE / 'ManastormRun.h').read_text(encoding='utf-8')
    for marker, signature in [('STAGE_BUFF', 'struct StageBuff'), ('STAGE_RECOVERY', 'struct StageRecovery')]:
        code = code.replace('// ACTUAL_' + marker, method(run_header, signature) + ';')
    code = code.replace('// ACTUAL_COOLDOWN_RESET',
        method(run_header, 'bool MarkStageCooldownsReset(').replace('_instanceId', 'instanceId'))
    remove_member = method(run_header, 'bool RemoveMember(').replace('_members', 'members')
    remove_member = remove_member.replace('_ownerGuid', 'ownerGuid')
    remove_member = remove_member.replace('_pendingStageTransferMembers', 'pendingTransfers')
    code = code.replace('// ACTUAL_REMOVE_MEMBER', remove_member)
    for marker, signature in functions.items():
        code = code.replace('// ACTUAL_' + marker, method(source, signature))
    damage = re.sub(r'\s+', '', method(source, 'void ManastormMgr::OnDamage('))
    protection = ('if(IsProtectedStagePortal(victim->ToCreature())||'
                  'IsPlayerProtectedDuringTransition(victim->ToPlayer())){damage=0;return;}')
    assert protection in damage
    assert damage.index(protection) < damage.index('if(sManastormReflectDamageDispatch)')
    environment = method(spells, 'bool OnPlayerEnvironmentalDamage(')
    assert 'IsPlayerProtectedDuringTransition(player)' in environment
    assert 'PLAYERHOOK_ON_PLAYER_ENVIRONMENTAL_DAMAGE' in spells
    for signature in ['bool ManastormMgr::PrepareStage(', 'bool ManastormMgr::TransferMemberToCurrentStage(']:
        transfer = method(source, signature)
        assert transfer.index('PrepareStageMemberTransfer(') < transfer.index('->TeleportTo(')
    arrival = method(source, 'bool ManastormMgr::OnPlayerEnterMap(')
    assert 'RemoveAllSpellCooldown()' in arrival and 'MarkStageCooldownsReset(' in arrival
    assert 'HasPlayerLeftStageEntrance(member, map, *entrance)' in arrival
    assert 'member->GetExactDist(entrance->position_x' not in arrival
    assert 'ClearSafetyBubble(member,true)' in re.sub(r'\s+', '', arrival)
    update = method(source, 'void ManastormMgr::Update(')
    assert 'ClearSafetyBubble(member,true)' in re.sub(r'\s+', '', update)
    ui = (MODULE / 'ManastormClientUIFixes.cpp').read_text(encoding='utf-8')
    queue = ui.split('constexpr std::string_view QueueLevelGuardsLua = R"lua(', 1)[1].split(')lua";', 1)[0]
    assert 'table.sort(levels, function(left, right) return left > right end)' in queue
    assert queue.count('self.levels = GetSortedLevels()') == 2
    assert 'levels[#levels + 1] = level' in queue
    assert 'levelSelect.ScrollList:SetSelectedIndex(index, ScrollListMixin.UpdateType.Always)' in queue
    assert 'if wasShown then levelSelect:Show() end' in queue
    leave = method(source, 'bool ManastormMgr::LeaveRunMember(')
    assert 'FailRun(' not in leave
    assert leave.index('->TeleportTo(') < leave.index('run.RemoveMember(guid)')
    assert 'SetScriptedPrivateOwner(owner, members' in leave
    assert 'member->PrepareScriptedPrivateInstance(' in leave
    assert 'LeaveRunMember(' in method(source, 'bool ManastormMgr::StopRun(')
    assert 'LeaveRunMember(' in method(source, 'bool ManastormMgr::HandleReleaseAfterWipe(')
    assert 'LeaveRunMember(*run, player, false' in arrival
    portal = method(source, 'void ManastormMgr::SpawnStagePortal(')
    assert 'UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_IMMUNE_TO_NPC' in portal
    necromancer = (ROOT / 'src/server/coa/AscensionNecromancerAbilities.cpp').read_text(encoding='utf-8')
    assert 'Command(info) && (player->HasAura(500983) ||' in necromancer
    assert '(!Named(info, 504868) && Minions(player).empty())' in necromancer
    patch = method(spells, 'void OnLoadSpellCustomAttr(').replace(
        'void OnLoadSpellCustomAttr(', 'void PatchSafetySpell(').replace(' override', '')
    code = code.replace('// ACTUAL_PATCH', patch)
    affixes = (MODULE / 'ManastormAffixEngine.cpp').read_text(encoding='utf-8')
    start = affixes.index('void ManastormAffixEngine::InitializeStage(')
    end = affixes.index('    ManastormAffixPolicy const* policy', start)
    selection = affixes[start:end].replace('ManastormAffixEngine::InitializeStage', 'InitializeAutomaticAffixes')
    code = code.replace('// ACTUAL_SELECTION', selection + '    ++run.selections;\n}')
    distance = re.search(r'constexpr float HEART_PICKUP_DISTANCE = [^;]+;', source)[0]
    code = code.replace('// ACTUAL_DISTANCE', distance)
    compiler = shutil.which(os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable the C++20 compiler environment.'
    with tempfile.TemporaryDirectory(prefix='manastorm-floor-safety-') as directory:
        out = Path(directory)
        cpp = out / 'actual.cpp'
        executable = out / ('harness.exe' if os.name == 'nt' else 'harness')
        cpp.write_text(code, encoding='utf-8')
        flags = (['/nologo', '/std:c++20', '/EHsc', '/utf-8', str(cpp), '/Fe' + str(executable)]
                 if Path(compiler).stem.lower() == 'cl' else ['-std=c++20', str(cpp), '-o', str(executable)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=30)
    vendor_ranks()
    scaling_curve()
    print('PASS: production preparation, protection, companion transfers and center-only pickups; all vendor ranks.')


if __name__ == '__main__':
    main()
