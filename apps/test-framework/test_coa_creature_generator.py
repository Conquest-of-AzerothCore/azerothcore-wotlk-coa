"""Synthetic planner regressions; no archive, database or network required."""
import copy
import importlib.util
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
import coa_creature_sql as generator


def smart(**changes):
    row = {
        'entryorguid': 100, 'source_type': 0, 'id': 0, 'link': 0,
        'event_type': 0, 'event_phase_mask': 0, 'event_chance': 100, 'event_flags': 0,
        **{f'event_param{i}': 0 for i in range(1, 7)},
        'action_type': 1,
        **{f'action_param{i}': 0 for i in range(1, 7)},
        'target_type': 1,
        **{f'target_param{i}': 0 for i in range(1, 5)},
        'target_x': 0.0, 'target_y': 0.0, 'target_z': 0.0, 'target_o': 0.0,
        'comment': 'synthetic SmartAI row',
    }
    row.update(changes)
    return row


class CreaturePlanner(unittest.TestCase):
    def fixture(self):
        donor = {'entry':100,'name':'Synthetic Guard (1)','minlevel':40,'maxlevel':41,'faction':35,
                 'unit_class':1,'ScriptName':'','AIName':'','HealthModifier':2.0,'ManaModifier':1.0,
                 'type':7,'family':0,'rank':1,'VerifiedBuild':12340}
        shell = dict(donor,entry=200,minlevel=1,maxlevel=1,faction=0,unit_class=0,VerifiedBuild=-12340)
        target={'creature_template':[donor],'smart_scripts':[],'conditions':[],'creature_text':[]}
        archive={'creature_template':[shell], 'creature_template_model':[
            {'CreatureID':200,'Idx':0,'CreatureDisplayID':123,'DisplayScale':1.0,
             'Probability':1.0,'VerifiedBuild':12340}]}
        dbc={'FactionTemplate':{35},'CreatureDisplayInfo':{123},'CreatureType':{7},'CreatureFamily':set(),'Spell':set()}
        item={'entry':118,'name':'Synthetic Potion','class':0,'Bonding':0,'startquest':0}
        npc={'id':'200','name':'Synthetic Guard - Heroic','levels':'Level 70 Elite','drops':[
            {'entity':{'type':'item','key':'118','label':'Synthetic Potion'},'chance':'1.0%'}]}
        return [npc],target,archive,dbc,[item],[]

    def test_captured_identity_retains_difficulty_alias_and_mirror_level(self):
        inputs=self.fixture(); before=copy.deepcopy(inputs)
        cohorts,report=generator.prepare(*inputs)
        self.assertEqual(inputs,before)
        row=cohorts[0]['tables']['creature_template'][0]
        self.assertEqual(('Synthetic Guard (1)',70,70,35,1,-12341),tuple(row[k] for k in
            ('name','minlevel','maxlevel','faction','unit_class','VerifiedBuild')))
        self.assertTrue(any('differs' in n for n in cohorts[0]['info']['notes']))
        self.assertEqual(12340,cohorts[0]['tables']['creature_template_model'][0]['VerifiedBuild'])

    def test_en_dash_level_range_retains_maximum(self):
        inputs = self.fixture()
        inputs[0][0]['levels'] = 'Level 40– 43 Elite'

        cohorts, _ = generator.prepare(*inputs)

        template = cohorts[0]['tables']['creature_template'][0]
        self.assertEqual((40, 43), (template['minlevel'], template['maxlevel']))

    def test_ambiguous_twins_are_not_chosen_arbitrarily(self):
        inputs=self.fixture(); inputs[1]['creature_template'].append(dict(inputs[1]['creature_template'][0],entry=101))
        cohorts,report=generator.prepare(*inputs)
        self.assertEqual([],cohorts)
        self.assertEqual([],report['candidates'])

    def test_invalid_faction_or_display_withholds_entire_creature(self):
        for key,value in [('faction',0),('unit_class',0)]:
            inputs=self.fixture(); inputs[1]['creature_template'][0][key]=value
            cohorts,report=generator.prepare(*inputs)
            self.assertEqual([],cohorts)
            self.assertTrue(report['excluded'])
        inputs=self.fixture(); inputs[3]['CreatureDisplayInfo']=set()
        self.assertEqual([],generator.prepare(*inputs)[0])

    def test_cpp_binding_omitted_and_disclosed(self):
        inputs=self.fixture(); inputs[1]['creature_template'][0]['ScriptName']='synthetic_boss'
        cohorts,_=generator.prepare(*inputs)
        row=cohorts[0]['tables']['creature_template'][0]
        self.assertEqual('',row['ScriptName'])
        self.assertTrue(any('C++' in n for n in cohorts[0]['info']['notes']))

    def test_smart_ai_closes_text_locales_and_clears_services(self):
        inputs = self.fixture()
        donor = inputs[1]['creature_template'][0]
        donor.update(AIName='SmartAI', npcflag=129, gossip_menu_id=44)
        inputs[1]['smart_scripts'] = [smart(action_param1=0)]
        inputs[1]['creature_text'] = [
            {'CreatureID': 100, 'GroupID': 0, 'ID': 0, 'Text': 'used'},
            {'CreatureID': 100, 'GroupID': 1, 'ID': 0, 'Text': 'unused'},
        ]
        inputs[1]['creature_text_locale'] = [
            {'CreatureID': 100, 'GroupID': 0, 'ID': 0, 'Locale': 'frFR', 'Text': 'used-fr'},
            {'CreatureID': 100, 'GroupID': 1, 'ID': 0, 'Locale': 'frFR', 'Text': 'unused-fr'},
        ]

        cohorts, _ = generator.prepare(*inputs)

        self.assertEqual(1, len(cohorts))
        tables = cohorts[0]['tables']
        template = tables['creature_template'][0]
        self.assertEqual(('SmartAI', 0, 0), (
            template['AIName'], template['npcflag'], template['gossip_menu_id'],
        ))
        self.assertEqual([(200, 0, 0)], [
            (r['CreatureID'], r['GroupID'], r['ID']) for r in tables['creature_text']
        ])
        self.assertEqual([(200, 0, 0, 'frFR')], [
            (r['CreatureID'], r['GroupID'], r['ID'], r['Locale'])
            for r in tables['creature_text_locale']
        ])

    def test_blocked_or_missing_smart_ai_withholds_entire_creature(self):
        inputs = self.fixture()
        inputs[1]['creature_template'][0]['AIName'] = 'SmartAI'
        inputs[1]['smart_scripts'] = [smart(target_type=10, target_param1=12345)]

        cohorts, report = generator.prepare(*inputs)

        self.assertEqual([], cohorts)
        self.assertIn('context_target', {
            reason['code'] for item in report['excluded'] for reason in item['reasons']
        })

        inputs = self.fixture()
        inputs[1]['creature_template'][0]['AIName'] = 'SmartAI'
        cohorts, report = generator.prepare(*inputs)
        self.assertEqual([], cohorts)
        self.assertIn('no_template_smart_scripts', {
            reason['code'] for item in report['excluded'] for reason in item['reasons']
        })

    def test_duplicate_unknown_and_quest_sensitive_loot_withheld(self):
        for mode in ('duplicate','unknown','quest'):
            inputs=self.fixture()
            if mode=='duplicate': inputs[0][0]['drops']*=2
            if mode=='unknown': inputs[0][0]['drops'][0]['chance']='—'
            if mode=='quest': inputs[4][0]['Bonding']=4
            cohorts,report=generator.prepare(*inputs)
            self.assertEqual([],cohorts[0]['tables']['creature_loot_template'])
            self.assertTrue(report['loot_exclusions'])

if __name__=='__main__':
    unittest.main()
