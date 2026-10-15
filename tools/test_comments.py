from pathlib import Path
import subprocess
import tempfile
import unittest

import check_comments
from comment_policy import comments, language, violations


class CommentPolicyTests(unittest.TestCase):
    def test_cpp_comments_are_found_without_matching_literals(self):
        source = 'auto url = "https://example.test";\nauto raw = R"tag(/* data */ // data)tag";\n'
        source += "auto number = 1'000'000; auto quote = '\\'';\nint value = 1; // redundant\n/* prose */\n"
        found = violations(source, 'src/server/coa/Test.cpp')
        self.assertEqual([entry.text for entry in found], ['// redundant', '/* prose */'])
        self.assertEqual(found[0].line, 4)

    def test_cpp_continued_line_comment_includes_the_following_line(self):
        source = '// prose \\\ncontinued\nint value = 1;\n'
        found = violations(source, 'tools/test.cpp')
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0].end_line, 2)

    def test_licenses_and_exact_tool_directives_are_preserved(self):
        source = '/* Copyright 2026 Example; licensed under AGPL. */\n'
        source += '// clang-format off\n// NOLINTNEXTLINE(readability-identifier-naming)\nint x;\n'
        self.assertEqual(violations(source, 'tools/test.cpp'), [])
        self.assertEqual(len(violations('int x; // copyright excuse\n', 'tools/test.cpp')), 1)

    def test_harness_markers_are_allowed_only_in_test_templates(self):
        source = '// ACTUAL_SOURCE\n// NATIVE_ENUMS\n// explanation\n'
        found = violations(source, 'apps/coa-tests/example/harness.cpp')
        self.assertEqual([entry.text for entry in found], ['// explanation'])
        self.assertEqual(len(violations(source, 'src/server/coa/Test.cpp')), 3)

    def test_comment_between_tokens_is_still_a_comment(self):
        found = violations('int/**/value;', 'tools/test.cpp')
        self.assertEqual(found[0].text, '/**/')

    def test_unterminated_block_comment_is_not_a_silent_pass(self):
        found = violations('int value; /* explanation', 'tools/test.cpp')
        self.assertEqual(found[0].text, '/* explanation')

    def test_python_comments_and_docstrings_are_found_without_matching_data(self):
        source = '"""module prose"""\nVALUE = "# literal"\n# prose\ndef method():\n    """function prose"""\n'
        found = violations(source, 'tools/example.py')
        self.assertEqual(sorted(entry.kind for entry in found), ['docstring', 'docstring', 'python'])

    def test_python_machine_comments_remain(self):
        source = '#!/usr/bin/env python3\n# coding: utf-8\nimport example  # noqa: E402\n'
        source += 'value = example.value  # type: ignore[attr-defined]\n'
        self.assertEqual(violations(source, 'apps/coa-dbc/coa-dbc-viewer'), [])

    def test_python_license_header_remains(self):
        self.assertEqual(violations('# Copyright 2026 Example\n# AGPL license terms\nvalue = 1\n',
                                    'tools/example.py'), [])
        self.assertEqual(violations('"""SPDX-License-Identifier: AGPL-3.0-only"""\nvalue = 1\n',
                                    'tools/example.py'), [])

    def test_python_source_offsets_handle_unicode_before_a_docstring(self):
        source = 'def example():\n    """Объяснение"""\n    return "значение"\n'
        found = violations(source, 'tools/example.py')
        self.assertEqual(source[found[0].start:found[0].end], '"""Объяснение"""')

    def test_only_added_lines_are_enforced(self):
        source = '// existing\nint value;\n/* first\nnew explanation\nlast */\n'
        found = violations(source, 'tools/test.cpp', {4})
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0].line, 3)

    def test_upstream_dependencies_and_configuration_are_outside_scope(self):
        for path in ['src/server/game/Spells/Spell.cpp', 'deps/example/test.py',
                     'modules/other/src/Test.cpp', 'data/sql/base/world.sql',
                     'src/server/coa/conf/coa.conf.dist']:
            with self.subTest(path=path):
                self.assertIsNone(language(path))
                self.assertEqual(comments('// prose', path), [])


class CommentDiffTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.git('init', '-q')
        self.git('config', 'user.name', 'Comment policy fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        (self.root / 'tools').mkdir()
        (self.root / 'tools/example.py').write_text('# existing\nvalue = 1\n')
        self.git('add', '.')
        self.git('-c', 'commit.gpgsign=false', 'commit', '-qm', 'fixture')

    def git(self, *arguments):
        return subprocess.run(['git', *arguments], cwd=self.root, check=True, capture_output=True)

    def test_modifying_code_does_not_reject_existing_comments(self):
        (self.root / 'tools/example.py').write_text('# existing\nvalue = 2\n')
        self.assertEqual(check_comments.check(root=self.root)['status'], 'passed')
        self.assertEqual(check_comments.check(all_files=True, root=self.root)['status'], 'failed')

    def test_staged_and_unstaged_new_comments_fail(self):
        path = self.root / 'tools/example.py'
        path.write_text('# existing\nvalue = 2\n# new\n')
        for staged in [False, True]:
            if staged:
                self.git('add', '.')
            self.assertEqual(check_comments.check(root=self.root)['issues'][0]['line'], 3)

    def test_new_file_with_spaces_and_docstrings_fails(self):
        (self.root / 'tools/new file.py').write_text('"""explanation"""\nvalue = 1\n')
        result = check_comments.check(root=self.root)
        self.assertEqual(result['issues'][0]['path'], 'tools/new file.py')
        self.git('add', '.')
        self.assertEqual(check_comments.check(root=self.root)['status'], 'failed')

    def test_deleted_files_are_ignored(self):
        (self.root / 'tools/example.py').unlink()
        self.assertEqual(check_comments.check(root=self.root)['status'], 'passed')

    def test_source_symlinks_are_rejected(self):
        (self.root / 'tools/link.py').symlink_to(self.root / 'tools/example.py')
        with self.assertRaisesRegex(ValueError, 'symlink'):
            check_comments.check(root=self.root)

    def test_invalid_base_is_not_a_silent_pass(self):
        with self.assertRaises(subprocess.CalledProcessError):
            check_comments.check(base='missing-fixture-ref', root=self.root)


if __name__ == '__main__':
    unittest.main()
