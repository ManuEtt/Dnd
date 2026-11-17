"""Security regression tests for the one-time cleanup allowlist."""
import contextlib
import io
import os
import sys
import unittest
from pathlib import Path
from unittest import mock
from urllib.parse import quote

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import retire_merged_branches as retirement
from retire_merged_branches import BRANCH_SNAPSHOT, MAINTENANCE_BRANCH, eligible


class BranchRetirementTests(unittest.TestCase):
    def test_snapshots_are_exact_and_never_main(self):
        self.assertEqual(len(BRANCH_SNAPSHOT), 12)
        self.assertNotIn("main", BRANCH_SNAPSHOT)
        self.assertTrue(all(len(commit) == 40 for commit in BRANCH_SNAPSHOT.values()))

    def test_eligible_only_when_unchanged_and_merged(self):
        name, sha = next(iter(BRANCH_SNAPSHOT.items()))
        self.assertTrue(
            eligible(name, actual_sha=sha, ahead_by=0, protected=False, is_merged=True)
        )
        for kwargs in (
            {"actual_sha": "0" * 40, "ahead_by": 0, "protected": False, "is_merged": True},
            {"actual_sha": sha, "ahead_by": 1, "protected": False, "is_merged": True},
            {"actual_sha": sha, "ahead_by": 0, "protected": True, "is_merged": True},
            {"actual_sha": sha, "ahead_by": 0, "protected": False, "is_merged": False},
        ):
            self.assertFalse(eligible(name, **kwargs))

    def test_dangerous_and_unlisted_branches_are_never_eligible(self):
        for name in ("main", "develop", "feature/new-work", "../main"):
            self.assertFalse(
                eligible(
                    name, actual_sha="a" * 40, ahead_by=0,
                    protected=False, is_merged=True,
                )
            )

    def test_new_maintenance_branch_only_if_merged(self):
        self.assertTrue(
            eligible(
                MAINTENANCE_BRANCH,
                actual_sha="a" * 40,
                ahead_by=0,
                protected=False,
                is_merged=True,
            )
        )


    def _simulate_execute(self, *, final_sha=None, final_protected=False,
                          current_protected=False):
        """Exercise the actual cleanup loop without ever making a network call."""
        name, expected_sha = next(iter(BRANCH_SNAPSHOT.items()))
        main_sha = 'f' * 40
        encoded = quote(name, safe='')
        branch_route = 'branches/' + encoded
        compare_route = 'compare/main...' + encoded
        delete_route = 'git/refs/heads/' + quote(name, safe='/')
        branch_reads = 0
        calls = []

        def fake_call(method, route, token):
            nonlocal branch_reads
            calls.append((method, route))
            self.assertEqual(token, 'test-token')
            if route == 'branches/main':
                return {'commit': {'sha': main_sha}}
            if route == branch_route and method == 'GET':
                branch_reads += 1
                if branch_reads == 4:
                    # Confirm deletion after the accepted DELETE request.
                    return None
                if branch_reads == 3:
                    return {
                        'commit': {'sha': final_sha or expected_sha},
                        'protected': final_protected,
                    }
                return {
                    'commit': {'sha': expected_sha},
                    'protected': current_protected if branch_reads == 2 else False,
                }
            if route == compare_route:
                return {'ahead_by': 0, 'status': 'identical'}
            if method == 'DELETE' and route == delete_route:
                return None
            # All other allowlisted branches are already absent.
            return None

        env = {
            'GITHUB_REPOSITORY': retirement.REPOSITORY,
            'GITHUB_REF': 'refs/heads/main',
            'GITHUB_SHA': main_sha,
            'GITHUB_TOKEN': 'test-token',
        }
        with mock.patch.dict(os.environ, env), \
             mock.patch.object(sys, 'argv', ['retire_merged_branches.py', '--execute']), \
             mock.patch.object(retirement, 'call', side_effect=fake_call), \
             contextlib.redirect_stdout(io.StringIO()), \
             contextlib.redirect_stderr(io.StringIO()):
            if final_protected or final_sha is not None or current_protected:
                with self.assertRaises(SystemExit):
                    retirement.main()
            else:
                retirement.main()
        return calls, branch_reads, delete_route, branch_route

    def test_cleanup_revalidates_branch_after_final_comparison_and_can_delete(self):
        calls, reads, delete_route, branch_route = self._simulate_execute()
        self.assertEqual(reads, 4)
        self.assertEqual(calls.count(('DELETE', delete_route)), 1)
        last_comparison = max(
            i for i, (_, route) in enumerate(calls) if route.startswith('compare/main...')
        )
        final_branch_read = [
            i for i, (method, route) in enumerate(calls)
            if method == 'GET' and route == branch_route
        ][-2]
        self.assertGreater(final_branch_read, last_comparison)

    def test_cleanup_refuses_newly_protected_branch_before_delete(self):
        calls, reads, delete_route, _ = self._simulate_execute(final_protected=True)
        self.assertEqual(reads, 3)
        self.assertNotIn(('DELETE', delete_route), calls)

    def test_cleanup_refuses_branch_changed_after_merge_comparison(self):
        calls, reads, delete_route, _ = self._simulate_execute(final_sha='e' * 40)
        self.assertEqual(reads, 3)
        self.assertNotIn(('DELETE', delete_route), calls)

    def test_cleanup_refuses_protection_changed_after_initial_branch_read(self):
        calls, reads, delete_route, _ = self._simulate_execute(current_protected=True)
        self.assertEqual(reads, 2)
        self.assertNotIn(('DELETE', delete_route), calls)



if __name__ == "__main__":
    unittest.main()
