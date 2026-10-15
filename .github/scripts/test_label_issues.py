import contextlib
import io
import json
import os
from pathlib import Path
import re
import sys
import unittest
from unittest.mock import call, patch

import label_issues


class LabelIssuesTests(unittest.TestCase):
    def setUp(self):
        self.output = io.StringIO()
        self.stack = contextlib.ExitStack()
        self.addCleanup(self.stack.close)
        self.stack.enter_context(contextlib.redirect_stdout(self.output))
        self.stack.enter_context(contextlib.redirect_stderr(self.output))
        self.stack.enter_context(patch.object(label_issues, "REPO", "owner/repo"))

    def test_classes_categories_and_null_body(self):
        labels = label_issues.determine_labels({"title": "Pyromancer C++ damage bug", "body": None})
        self.assertEqual(labels, ["Pyromancer", "CPP Edit", "Bug"])

    def test_ingame_report_without_class_name(self):
        issue = {
            "title": "Melt Reality Damage",
            "body": (
                "Submitted from the in-game bug-report form.\n\n"
                "#### Spell\nMelt Reality [ID: 806335]\n\n"
                "#### Issue\nDamage is too high? 1629 Damage at level 11\n\n"
                "### Classification\nCategory: 1\nSeverity: 0\n\n"
                "### Server context\nClass ID: 22\nLevel: 11\nMap ID: 1\n"
                "Position: 9652.4, 868.013, 1269.3\nCore revision: 7b66e4380261"
            ),
        }
        self.assertEqual(label_issues.determine_labels(issue), ["Chronomancer", "Bug"])

    def test_class_id_labels_match_server_definitions(self):
        root = Path(__file__).resolve().parents[2]
        source = (root / "src/server/shared/SharedDefines.h").read_text(encoding="utf-8")
        classes = source.split("enum Classes\n{", 1)[1].split("};", 1)[0]
        expected = {
            int(class_id): title.strip()
            for class_id, title in re.findall(r"CLASS_\w+\s*=\s*(\d+),?\s*// TITLE ([^\n]+)", classes)
            if 12 <= int(class_id) <= 32
        }
        self.assertEqual(set(expected.values()), set(label_issues.CLASS_PATTERNS))
        self.assertEqual(label_issues.CLASS_ID_LABELS, expected)
        self.assertTrue(set(expected.values()).issubset(label_issues.MANAGED_LABELS))
        for class_id, label in expected.items():
            with self.subTest(class_id=class_id):
                self.assertEqual(label_issues.determine_labels({"body": f"Class ID: {class_id}"}), [label])

    def test_class_id_field_whitespace_and_line_endings(self):
        body = "### Server context\r\n  class ID :\t22 \r\nLevel: 11\r\n"
        self.assertEqual(label_issues.determine_labels({"body": body}), ["Chronomancer"])

    def test_witch_hunter_name_and_id(self):
        for issue in (
            {"title": "Witch Hunter"},
            {"body": "witch hunter"},
            {"body": "### Server context\nClass ID: 15\nLevel: 11"},
            {"title": "Witch Hunter", "body": "Class ID: 15"},
        ):
            with self.subTest(issue=issue):
                self.assertEqual(label_issues.determine_labels(issue), ["Witch Hunter"])

    def test_witch_hunter_label_is_added_without_removing_existing_labels(self):
        issue = {"body": "Class ID: 15", "labels": [{"name": "Bug"}]}
        with patch.object(label_issues, "gh") as gh:
            label_issues.update_issue("42", issue, label_issues.determine_labels(issue))
        gh.assert_called_once_with(
            "issue", "edit", "42", "--add-label", "Witch Hunter", "--repo", "owner/repo",
        )

    def test_unrelated_and_invalid_ids_do_not_add_class_labels(self):
        for body in (
            "Spell ID: 22\nMap ID: 22\nLevel: 22", "Class ID: 999", "Class ID: 33",
            "Class ID: 1", "Class ID: 2200", "Class ID: -22", "Class ID: 22.5",
            "Class ID: 22abc", "Class ID: unknown", "No Class ID: 22",
        ):
            with self.subTest(body=body):
                self.assertEqual(label_issues.determine_labels({"body": body}), [])

    def test_class_name_and_id_do_not_duplicate_labels(self):
        issue = {"title": "Chronomancer", "body": "Class ID: 22\nClass ID: 22"}
        self.assertEqual(label_issues.determine_labels(issue), ["Chronomancer"])

    def test_cpp_boundaries(self):
        for text in ("C++", "C++ change required", "Fix requires C++.", "CPP", "C++ edit"):
            with self.subTest(text=text):
                self.assertIn("CPP Edit", label_issues.determine_labels({"title": text}))
        self.assertNotIn("CPP Edit", label_issues.determine_labels({"title": "abc++"}))

    def test_no_status_from_prose_or_unchecked_boxes(self):
        for body in (
            "This has never been tested.", "Not tested", "Tested on a local server",
            "Needs to be tested", "- [ ] Tested", "- [ ] Not Tested", "I can’t test this.",
        ):
            with self.subTest(body=body):
                self.assertIsNone(label_issues.determine_testing_status(body))

    def test_explicit_status_formats(self):
        for body, expected in (
            ("Testing status: Tested", "Tested"),
            ("testing status: not tested", "Not Tested"),
            ("- [X] Tested\n- [ ] Not Tested", "Tested"),
            ("- [ ] Tested\n- [x] Not Tested", "Not Tested"),
            ("### Testing status\n\nTested\n\nMore details", "Tested"),
            ("### Testing status\n\nNot Tested", "Not Tested"),
        ):
            with self.subTest(body=body):
                self.assertEqual(label_issues.determine_testing_status(body), expected)

    def test_conflicting_statuses_are_not_guessed(self):
        self.assertIsNone(label_issues.determine_testing_status("- [x] Tested\n- [x] Not Tested"))

    def test_status_must_immediately_follow_heading(self):
        self.assertIsNone(label_issues.determine_testing_status("### Testing status\nUnknown\nTested"))

    def test_status_is_read_from_body_only(self):
        self.assertEqual(label_issues.determine_labels({"title": "Testing status: Tested"}), [])

    def test_existing_labels_are_preserved(self):
        issue = {"labels": [{"name": name} for name in ("Tested", "DB", "human-label")]}
        with patch.object(label_issues, "gh") as gh:
            label_issues.update_issue("42", issue, ["Bug", "CPP Edit", "Not Tested"])
        gh.assert_called_once_with(
            "issue", "edit", "42", "--add-label", "Bug,CPP Edit", "--repo", "owner/repo",
        )

    def test_existing_not_tested_is_not_overridden(self):
        with patch.object(label_issues, "gh") as gh:
            label_issues.update_issue("42", {"labels": [{"name": "Not Tested"}]}, ["Tested"])
        gh.assert_not_called()

    def test_repeated_run_and_case_variants_do_not_write(self):
        with patch.object(label_issues, "gh") as gh:
            label_issues.update_issue("42", {"labels": [{"name": "bug"}]}, ["Bug"])
        gh.assert_not_called()

    def test_dry_run_prints_additions_without_writing(self):
        with patch.object(label_issues, "gh") as gh:
            label_issues.update_issue("42", {"labels": []}, ["Bug", "Tested"], dry_run=True)
        gh.assert_not_called()
        self.assertIn("would add: Bug, Tested", self.output.getvalue())

    def test_pull_request_class_scope_is_labeled(self):
        issue = {
            "title": "fix(CoA/Bloodmage): apply Eternal Curse item armor bonus",
            "body": "Server-side only; not tested in a live client.",
            "pull_request": {"url": "fixture"},
            "labels": [],
        }
        with patch.object(label_issues, "get_issue", return_value=issue):
            with patch.object(label_issues, "gh") as gh:
                label_issues.label_issue("4212")
        gh.assert_called_once_with(
            "pr", "edit", "4212", "--add-label", "Bloodmage", "--repo", "owner/repo",
        )

    def test_pull_request_preview_does_not_write(self):
        issue = {"title": "Bloodmage", "pull_request": {"url": "fixture"}, "labels": []}
        with patch.object(label_issues, "get_issue", return_value=issue):
            with patch.object(label_issues, "gh") as gh:
                label_issues.label_issue("42", dry_run=True)
        gh.assert_not_called()
        self.assertIn("would add: Bloodmage", self.output.getvalue())

    def test_pull_request_preserves_existing_status_and_labels(self):
        issue = {
            "pull_request": {"url": "fixture"},
            "labels": [{"name": name} for name in ("DB", "Tested", "human-label")],
        }
        with patch.object(label_issues, "gh") as gh:
            label_issues.update_issue("42", issue, ["Bloodmage", "Not Tested"])
        gh.assert_called_once_with(
            "pr", "edit", "42", "--add-label", "Bloodmage", "--repo", "owner/repo",
        )

    def test_main_dry_run_reads_but_does_not_edit(self):
        with patch.dict(os.environ, {"ISSUE_NUMBER": "42", "DRY_RUN": "true"}):
            with patch.object(sys, "argv", ["label_issues.py"]):
                with patch.object(label_issues, "gh", return_value='{"title": "Bug", "labels": []}') as gh:
                    label_issues.main()
        gh.assert_called_once_with("api", "repos/owner/repo/issues/42")

    def test_invalid_issue_numbers_fail_before_github(self):
        for number in ("", "0", "-1", "42;echo unsafe", "https://example.com", "1.5"):
            with self.subTest(number=number), patch.dict(os.environ, {"ISSUE_NUMBER": number}):
                with patch.object(sys, "argv", ["label_issues.py"]), patch.object(label_issues, "gh") as gh:
                    with self.assertRaises(SystemExit) as error:
                        label_issues.main()
                self.assertEqual(error.exception.code, 2)
                gh.assert_not_called()

    def test_bulk_run_paginates_and_passes_preview_mode(self):
        with patch.dict(os.environ, {"ISSUE_NUMBER": "", "DRY_RUN": "false"}):
            with patch.object(sys, "argv", ["label_issues.py", "--all", "--dry-run"]):
                with patch.object(label_issues, "gh", return_value="42\n43") as gh:
                    with patch.object(label_issues, "label_issue") as label:
                        label_issues.main()
        gh.assert_called_once_with(
            "api", "--paginate", "repos/owner/repo/issues?state=all&per_page=100",
            "--jq", ".[].number",
        )
        self.assertEqual([call.args for call in label.call_args_list], [("42", True), ("43", True)])

    def test_bulk_run_labels_both_issues_and_pull_requests(self):
        issue = {"title": "Witch Hunter", "labels": []}
        pr = {"title": "Bloodmage", "pull_request": {"url": "fixture"}, "labels": []}
        responses = ["42\n43", json.dumps(issue), "", json.dumps(pr), ""]
        with patch.dict(os.environ, {"ISSUE_NUMBER": "", "DRY_RUN": "false"}):
            with patch.object(sys, "argv", ["label_issues.py", "--all"]):
                with patch.object(label_issues, "gh", side_effect=responses) as gh:
                    label_issues.main()
        self.assertEqual(gh.call_args_list, [
            call("api", "--paginate", "repos/owner/repo/issues?state=all&per_page=100", "--jq", ".[].number"),
            call("api", "repos/owner/repo/issues/42"),
            call("issue", "edit", "42", "--add-label", "Witch Hunter", "--repo", "owner/repo"),
            call("api", "repos/owner/repo/issues/43"),
            call("pr", "edit", "43", "--add-label", "Bloodmage", "--repo", "owner/repo"),
        ])

    def test_github_failure_stops_the_run(self):
        with patch.object(label_issues.subprocess, "run") as run:
            run.return_value.returncode = 1
            run.return_value.stderr = "API failure"
            with self.assertRaises(SystemExit) as error:
                label_issues.gh("api", "repos/owner/repo/issues/42")
        self.assertEqual(error.exception.code, 1)


if __name__ == "__main__":
    unittest.main()
