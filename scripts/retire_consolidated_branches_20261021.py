#!/usr/bin/env python3
"""One-time cleanup of audited 2026-10-21 branches; fail closed.

The live state is checked again immediately before deletion. Only the exact
pre-audited branch heads and a fully merged maintenance branch are eligible.
No application source files are changed by this program.
"""
import json
import os
import sys
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request, urlopen

REPOSITORY = "ManuEtt/Dnd"
AUDITED_MAIN = "cab20cf3f299c7dc18da121f3c2c16bfb382548b"
MAINTENANCE = "maintenance/retire-consolidated-branches-20261021"

# "ancestor": already in main's commit history.
# "covered": independent/squashed history, but all old files remain unchanged
# in main, other than a deliberately reviewed allowlist of later evolutions.
SNAPSHOT = {
    "feature/rabenwacht-brief-von-morgen-20261021":
        ("1ac8e0dd239c023957b445b9a255e8be113c678e", "covered"),
    "feature/rabenwacht-voice-act8-council-20261021":
        ("c27dafae1ef5b7f658994d72c7389baa51da74ff", "covered"),
    "feature/rabenwacht-voice-epilogue-20261021":
        ("6aa401c21a2df7e377eef5905530f4c6487c68cd", "covered"),
    "feature/srd-fireball-grid-preview-ui-20261021":
        ("3ac0025cb01815d6dd2a36825d8b55ab5f55c8d8", "ancestor"),
    "feature/srd-sphere-area-preview-20261021":
        ("f2fcab80d37fa94ca5e37851981997a97130cfe4", "ancestor"),
    "integration/rabenwacht-acht-epilog-brief-20261021":
        ("ef77140b62c282368669f5c12563ed3d90cd5b33", "covered"),
    "integration/rabenwacht-story-current-main-20261021":
        ("4f8dce193009270a9ae4df3b063c5dea638ea674", "covered"),
}

# These paths were specifically reviewed: branches predate later SRD/UI
# work, or the final integrated narrative extends earlier story stages.
# The final story sources and tests MUST still match the audited blob SHAs.
ALLOWED_EVOLUTION = frozenset({
    "CHANGELOG.md",
    "DEVELOPMENT_STATUS.md",
    "TESTING.md",
    "app/lib/domain/srd_spell_grid_target_rules.dart",
    "app/lib/rules/rules_api.dart",
    "app/lib/story/fourteenth_voice_campaign.dart",
    "app/lib/ui/app.dart",
    "docs/RABENWACHT_DIE_VIERZEHNTE_STIMME.md",
    "docs/srd_5_2_1_requirements.json",
})
STORY_ANCHORS = {
    "app/lib/story/fourteenth_voice_act8.dart":
        "2067d30e7b132bafcd33a84577c7548f823f04b5",
    "app/lib/story/fourteenth_voice_epilogue.dart":
        "d19f88668478d1f446e02cd30f62d52517894411",
    "app/lib/story/fourteenth_voice_morrow.dart":
        "1e6f69c78c304c693ee602d44bca40ee641ea1ae",
    "app/lib/story/fourteenth_voice_campaign.dart":
        "3d7a20ad97050d75127643e7428c7f4427ea8c56",
    "app/test/rabenwacht_fourteenth_voice_act8_test.dart":
        "3ed0a7c11e71d80a9134daa8a140acf13d7b7ca3",
    "app/test/rabenwacht_fourteenth_voice_epilogue_test.dart":
        "cd74bf10c87b2abcd304adfc4e01d43cdf61fb99",
    "app/test/rabenwacht_fourteenth_voice_morrow_test.dart":
        "52f05f902496de1a11cd66fa6b79017472848329",
}


def covered(branch_files, main_files, allowed=ALLOWED_EVOLUTION):
    """Reject lost or changed branch files outside audited newer components."""
    return bool(branch_files) and all(
        path in main_files and (main_files[path] == sha or path in allowed)
        for path, sha in branch_files.items()
    )


def eligible(name, actual_sha, protected, mode, *, ahead_by=None, files_ok=False):
    if protected or name == "main" or name not in SNAPSHOT:
        return False
    expected, expected_mode = SNAPSHOT[name]
    if actual_sha != expected or mode != expected_mode:
        return False
    return ahead_by == 0 if mode == "ancestor" else files_ok


def api(method, route, token):
    request = Request(
        "https://api.github.com/repos/" + REPOSITORY + "/" + route,
        method=method,
        headers={
            "Authorization": "Bearer " + token,
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "Wuerfelraunen-branch-retirement-20261021",
        },
    )
    try:
        with urlopen(request, timeout=25) as response:
            data = response.read()
            return json.loads(data) if data else {}
    except HTTPError as exc:
        if exc.code == 404:
            return None
        raise


def blobs(commit, token):
    data = api("GET", "git/trees/" + commit + "?recursive=1", token)
    if not data or data.get("truncated"):
        raise RuntimeError("Baum fehlt oder ist abgeschnitten: " + commit)
    return {item["path"]: item["sha"] for item in data["tree"]
            if item["type"] == "blob"}


def branch_info(name, token):
    return api("GET", "branches/" + quote(name, safe="/"), token)


def main():
    if os.environ.get("GITHUB_REPOSITORY") != REPOSITORY:
        raise SystemExit("Falsches Repository: Abbruch.")
    if os.environ.get("GITHUB_REF") != "refs/heads/main":
        raise SystemExit("Nur auf main erlaubt.")
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        raise SystemExit("Kein GITHUB_TOKEN; Abbruch.")
    main_sha = os.environ.get("GITHUB_SHA", "")
    if len(main_sha) != 40 or branch_info("main", token)["commit"]["sha"] != main_sha:
        raise SystemExit("main hat sich verändert: Abbruch.")

    history = api("GET", "compare/" + AUDITED_MAIN + "...main", token)
    if not history or history.get("behind_by") != 0:
        raise SystemExit("main ist nicht Nachfolger des geprüften Ausgangscommits.")
    current = blobs(main_sha, token)
    if any(current.get(path) != sha for path, sha in STORY_ANCHORS.items()):
        raise SystemExit("Rabenwacht-Inhalte/Tests haben sich seit Audit geändert.")

    to_delete = []
    for name, (sha, mode) in SNAPSHOT.items():
        data = branch_info(name, token)
        if data is None:
            print("Bereits entfernt:", name)
            continue
        files_ok = mode == "covered" and covered(blobs(sha, token), current)
        comparison = (api("GET", "compare/main..." + quote(name, safe="/"), token)
                      if mode == "ancestor" else None)
        ahead = comparison.get("ahead_by") if comparison else None
        if not eligible(name, data["commit"]["sha"], data.get("protected", True),
                        mode, ahead_by=ahead, files_ok=files_ok):
            raise SystemExit("Nicht sicher integriert: " + name)
        to_delete.append((name, sha))

    maintenance = branch_info(MAINTENANCE, token)
    if maintenance is not None:
        comparison = api("GET", "compare/main..." + quote(MAINTENANCE, safe="/"), token)
        if maintenance.get("protected", True) or not comparison or comparison.get("ahead_by") != 0:
            raise SystemExit("Maintenance-Branch ist noch nicht vollständig gemergt.")
        to_delete.append((MAINTENANCE, maintenance["commit"]["sha"]))

    print("Audit bestanden; geprüfte Branches:", len(to_delete))
    if "--execute" not in sys.argv:
        print("Dry-run: keine Löschung.")
        return

    for name, sha in to_delete:
        # Race guard: do not remove a branch whose head has moved.
        if branch_info("main", token)["commit"]["sha"] != main_sha:
            raise SystemExit("main während Ausführung verändert; Stop.")
        latest = branch_info(name, token)
        if latest is None:
            print("Bereits entfernt:", name)
            continue
        if latest.get("protected", True) or latest["commit"]["sha"] != sha:
            raise SystemExit("Branch während Ausführung verändert: " + name)
        api("DELETE", "git/refs/heads/" + quote(name, safe="/"), token)
        if branch_info(name, token) is not None:
            raise SystemExit("Branch nach DELETE noch vorhanden: " + name)
        print("Gelöscht:", name)


if __name__ == "__main__":
    main()
