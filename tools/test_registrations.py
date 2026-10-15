import unittest

from check_registrations import inspect


class RegistrationTests(unittest.TestCase):
    def setUp(self):
        self.sources = {
            'CoAScriptLoader.cpp': 'void AddSC_Example();\n'
                             'void AddCoAScripts()\n{\n    AddSC_Example();\n}\n',
            'Example.cpp': 'void AddSC_Example()\n{\n    new ExampleScript();\n}\n',
        }

    def test_valid_flat_loader(self):
        self.assertEqual(inspect(self.sources)['status'], 'passed')

    def test_worldserver_must_call_the_coa_loader_once(self):
        registered = 'sScriptMgr->SetScriptLoader([] { AddScripts(); AddCoAScripts(); });'
        self.assertEqual(inspect(self.sources, registered)['status'], 'passed')
        for worldserver in ['sScriptMgr->SetScriptLoader(AddScripts);', '// AddCoAScripts();',
                            registered.replace('AddCoAScripts();', 'AddCoAScripts(); AddCoAScripts();')]:
            with self.subTest(worldserver=worldserver):
                self.assertEqual(inspect(self.sources, worldserver)['status'], 'failed')

    def test_second_root_loader_definition_is_reported(self):
        self.sources['Other.cpp'] = 'void AddCoAScripts() {}'
        result = inspect(self.sources)
        self.assertEqual(result['status'], 'failed')
        self.assertEqual(result['issues'][0]['message'], 'Expected one CoA root loader across all sources')

    def test_forgetting_a_registration_is_reported(self):
        self.sources['Forgotten.cpp'] = 'void AddAscensionForgottenScripts() {}'
        result = inspect(self.sources)
        self.assertEqual(result['status'], 'failed')
        self.assertEqual(result['issues'][0]['entry'], 'AddAscensionForgottenScripts')
        self.assertEqual(result['issues'][0]['calls'], [])

    def test_duplicate_calls_are_reported_with_locations(self):
        self.sources['CoAScriptLoader.cpp'] = self.sources['CoAScriptLoader.cpp'].replace(
            '    AddSC_Example();', '    AddSC_Example();\n    AddSC_Example();')
        result = inspect(self.sources)
        self.assertEqual(result['status'], 'failed')
        self.assertEqual([call['line'] for call in result['issues'][0]['calls']], [4, 5])

    def test_declaration_does_not_replace_a_definition(self):
        del self.sources['Example.cpp']
        result = inspect(self.sources)
        self.assertEqual(result['status'], 'failed')
        self.assertEqual(result['issues'][0]['definitions'], [])

    def test_duplicate_definitions_are_reported(self):
        self.sources['Duplicate.cpp'] = self.sources['Example.cpp']
        result = inspect(self.sources)
        self.assertEqual(result['status'], 'failed')
        self.assertEqual(len(result['issues'][0]['definitions']), 2)

    def test_comments_and_strings_cannot_satisfy_missing_calls(self):
        for replacement in ['// AddSC_Example();', '/* AddSC_Example(); */',
                            '"AddSC_Example();";', 'R"tag(AddSC_Example();)tag";']:
            with self.subTest(replacement=replacement):
                sources = dict(self.sources)
                loader = sources['CoAScriptLoader.cpp']
                sources['CoAScriptLoader.cpp'] = loader.replace('    AddSC_Example();', replacement)
                self.assertEqual(inspect(sources)['status'], 'failed')

    def test_fake_definitions_in_literals_and_comments_are_ignored(self):
        self.sources['Example.cpp'] += '\n// void AddSC_Comment() {}\n/* void AddSC_Block() {} */\n'
        self.sources['Example.cpp'] += 'auto example = R"test(void AddSC_Raw() {})test";\n'
        self.sources['Example.cpp'] += 'auto text = "void AddSC_Text() {}";\n'
        self.assertEqual(inspect(self.sources)['status'], 'passed')

    def test_unsupported_conditional_loader_is_not_treated_as_unconditional_registration(self):
        self.sources['CoAScriptLoader.cpp'] = self.sources['CoAScriptLoader.cpp'].replace(
            '    AddSC_Example();', '    if (enabled) AddSC_Example();')
        self.assertEqual(inspect(self.sources)['status'], 'failed')


if __name__ == '__main__':
    unittest.main()
