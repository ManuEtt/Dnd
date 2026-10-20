#!/usr/bin/env python3
"""One-time, allowlisted cleanup of verified merged branches.

Intentionally executed only by the dedicated GitHub Actions workflow on
main, with a short-lived GITHUB_TOKEN. No arbitrary branch names accepted.
"""
import json
import os
import sys
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request, urlopen

REPOSITORY = "ManuEtt/Dnd"
BRANCH_SNAPSHOT = {
    "docs/srd-crawling-ci-20261020": "915d70aa75b172ee6ff49347e597b9db2a142b4c",
    "docs/srd-force-defense-ci-20261020": "dc45f477c81ecccd7216d3747e91aa07c5cab06f",
    "docs/srd-magic-missile-ci-20261020": "f441be46c6bc7e542e10abec411c1bd5cb6d2e2c",
    "docs/srd-shield-ci-20261020": "3c7ad81bdff5e4d920c4fde8ca6f443cd4c6dc6f",
    "feature/level-up-xp-sequential-20261020": "d8b8d3d4e3ce3e6e44f6736051ce86439b75d7c3",
    "feature/srd-crawling-20261020": "3462106592157953473c7d777b0d5b664872243a",
    "feature/srd-enemy-shield-reaction-20261020": "81635c8eccb0d06e5d1bf95d54f5884c62f4a215",
    "feature/srd-magic-missile-20261020": "78d89230281f8196edbff628ca243d591ef092b3",
    "feature/srd-missile-force-defense-20261020": "8f703b0002ae6dcb5279893020bea63e14771184",
    "docs/srd-hero-shield-ci-20261020": "33ba2b4d2f6297fd5d43900fb1ea54a7060a9651",
    "feature/srd-hero-shield-auto-reaction-20261020": "090adb4c5fe21ddfc83d0903d5ef39181c50dd9f",
    "feature/srd-hero-shield-hit-choice-20261020": "011c53826956e609994930c65221bca9c33d9985"
}
MAINTENANCE_BRANCH = "maintenance/retire-merged-branches-20261020"


def eligible(name, *, actual_sha, ahead_by, protected, is_merged):
    """Only retire an unchanged explicitly nominated branch already on main."""
    if name == "main" or name not in (*BRANCH_SNAPSHOT, MAINTENANCE_BRANCH):
        return False
    if protected or ahead_by != 0 or not is_merged:
        return False
    expected = BRANCH_SNAPSHOT.get(name)
    return bool(actual_sha) and (expected is None or actual_sha == expected)


def call(method, route, token):
    url = "https://api.github.com/repos/" + REPOSITORY + "/" + route
    req = Request(
        url,
        method=method,
        headers={
            "Authorization": "Bearer " + token,
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "Wuerfelraunen-merged-branch-cleanup",
        },
    )
    try:
        with urlopen(req, timeout=25) as response:
            raw = response.read()
            return json.loads(raw) if raw else None
    except HTTPError as exc:
        if exc.code == 404:
            return None
        raise


def main():
    if os.environ.get("GITHUB_REPOSITORY") != REPOSITORY:
        raise SystemExit("Abbruch: nicht das erlaubte Repository.")
    if os.environ.get("GITHUB_REF") != "refs/heads/main":
        raise SystemExit("Abbruch: nur auf dem aktuellen main ausführen.")
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        raise SystemExit("Fehlendes GITHUB_TOKEN; keinerlei Löschung.")
    main_branch = call("GET", "branches/main", token)
    if not main_branch:
        raise SystemExit("Hauptbranch nicht auflösbar.")
    expected_main_sha = os.environ.get("GITHUB_SHA", "")
    if main_branch["commit"]["sha"] != expected_main_sha:
        raise SystemExit("main hat sich seit dem Start verändert: Abbruch.")
    result = []
    failures = []
    for name in (*BRANCH_SNAPSHOT, MAINTENANCE_BRANCH):
        path_name = quote(name, safe="")
        branch = call("GET", "branches/" + path_name, token)
        if branch is None:
            result.append((name, "bereits gelöscht"))
            continue
        actual_sha = branch["commit"]["sha"]
        compare = call("GET", "compare/main..." + path_name, token)
        eligible_now = (
            compare is not None and eligible(
                name,
                actual_sha=actual_sha,
                ahead_by=compare.get("ahead_by"),
                protected=branch.get("protected", True),
                is_merged=compare.get("status") in ("behind", "identical"),
            )
        )
        if not eligible_now:
            failures.append(name + ": neue/ungeprüfte Commits oder geschützt")
            continue
        # Recheck HEAD and merge base immediately before deleting.
        current = call("GET", "branches/" + path_name, token)
        if current is None:
            result.append((name, "bereits gelöscht"))
            continue
        if current["commit"]["sha"] != actual_sha:
            failures.append(name + ": Branch-HEAD während Prüfung geändert")
            continue
        if "--execute" in sys.argv:
            try:
                call("DELETE", "git/refs/heads/" + quote(name, safe="/"), token)
            except HTTPError as exc:
                failures.append(name + ": DELETE HTTP " + str(exc.code))
                continue
            result.append((name, "gelöscht"))
        else:
            result.append((name, "löschbar, Dry-Run"))
    for name, status in result:
        print(status + ": " + name)
    for failure in failures:
        print("GESCHÜTZT: " + failure, file=sys.stderr)
    if failures:
        raise SystemExit("Nicht alle Branches konnten sicher entfernt werden.")


if __name__ == "__main__":
    main()
