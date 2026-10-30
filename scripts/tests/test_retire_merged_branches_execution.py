"""Execution-level regressions for the allowlisted, one-time branch cleanup.

Network calls are mocked: tests never delete an actual GitHub branch.
"""
import contextlib
import io
import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.parse import quote

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import retire_merged_branches as cleanup


class RetireMergedBranchesExecutionTests(unittest.TestCase):
    def run_cleanup(self, *, execute=True, changed_main=False,
                    protected_later=False, diverged_later=False,
                    delete_persists=False):
        name, sha = next(iter(cleanup.BRANCH_SNAPSHOT.items()))
        branch_path = "branches/" + quote(name, safe="")
        compare_path = "compare/main..." + quote(name, safe="")
        counts = {"main": 0, "branch": 0, "compare": 0}
        deleted = []

        def fake_call(method, route, token):
            self.assertEqual(token, "test-token")
            if method == "GET" and route == "branches/main":
                counts["main"] += 1
                value = "0" * 40 if changed_main and counts["main"] > 1 else "a" * 40
                return {"commit": {"sha": value}}
            if method == "GET" and route == branch_path:
                counts["branch"] += 1
                if deleted and not delete_persists:
                    return None
                return {"commit": {"sha": sha},
                        "protected": protected_later and counts["branch"] > 1}
            if method == "GET" and route == compare_path:
                counts["compare"] += 1
                if diverged_later and counts["compare"] > 1:
                    return {"ahead_by": 1, "status": "diverged"}
                return {"ahead_by": 0, "status": "behind"}
            if method == "GET" and route.startswith("branches/"):
                return None  # Other allowlisted branches have already gone.
            if method == "DELETE":
                deleted.append(route)
                return None
            self.fail("unexpected request: " + method + " " + route)

        env = {"GITHUB_REPOSITORY": cleanup.REPOSITORY,
               "GITHUB_REF": "refs/heads/main",
               "GITHUB_SHA": "a" * 40,
               "GITHUB_TOKEN": "test-token"}
        output, errors = io.StringIO(), io.StringIO()
        failed = False
        with patch.dict(os.environ, env, clear=True), \
             patch.object(sys, "argv", ["cleanup.py"] + (["--execute"] if execute else [])), \
             patch.object(cleanup, "call", side_effect=fake_call), \
             contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
            try:
                cleanup.main()
            except SystemExit:
                failed = True
        return counts, deleted, failed, output.getvalue(), errors.getvalue()

    def test_successful_delete_checks_main_compare_and_absence(self):
        counts, deleted, failed, output, _ = self.run_cleanup()
        self.assertFalse(failed)
        self.assertEqual(len(deleted), 1)
        self.assertEqual(counts, {"main": 2, "branch": 3, "compare": 2})
        self.assertIn("gelöscht:", output)

    def test_main_changes_between_initial_check_and_delete(self):
        counts, deleted, failed, _, _ = self.run_cleanup(changed_main=True)
        self.assertTrue(failed)
        self.assertEqual(deleted, [])
        self.assertEqual(counts["main"], 2)

    def test_branch_becomes_protected_before_delete(self):
        _, deleted, failed, _, error = self.run_cleanup(protected_later=True)
        self.assertTrue(failed)
        self.assertEqual(deleted, [])
        self.assertIn("GESCHÜTZT:", error)

    def test_branch_diverges_before_delete(self):
        counts, deleted, failed, _, error = self.run_cleanup(diverged_later=True)
        self.assertTrue(failed)
        self.assertEqual(deleted, [])
        self.assertEqual(counts["compare"], 2)
        self.assertIn("GESCHÜTZT:", error)

    def test_delete_without_disappearance_is_not_reported_as_success(self):
        _, deleted, failed, output, error = self.run_cleanup(delete_persists=True)
        self.assertTrue(failed)
        self.assertEqual(len(deleted), 1)
        self.assertFalse(any(line.startswith("gelöscht:") for line in output.splitlines()))
        self.assertIn("nach DELETE noch vorhanden", error)

    def test_dry_run_never_deletes_and_skips_mutation_only_checks(self):
        counts, deleted, failed, output, _ = self.run_cleanup(execute=False)
        self.assertFalse(failed)
        self.assertEqual(deleted, [])
        self.assertEqual(counts, {"main": 1, "branch": 2, "compare": 1})
        self.assertIn("Dry-Run", output)


if __name__ == "__main__":
    unittest.main()
