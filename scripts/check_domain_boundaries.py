#!/usr/bin/env python3
"""Enforce independent story/rules tracks at the explicit module boundary.

The legacy GameEngine is currently the facade/composition root; shared
models.dart is transitional until typed rule/story snapshots are separated.
"""
from __future__ import annotations

import posixpath
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Dart configurable imports/exports can switch the URI per platform. Guard
# *every* selectable URI, not only the default URI before a conditional clause.
IMPORT = re.compile(
    r"^\\s*(?:import|export)\\s+['\\\"](?P<primary>[^'\\\"]+)['\\\"]"
    r"(?P<conditional>(?:\\s+if\\s*\\([^)]*\\)\\s*['\\\"][^'\\\"]+['\\\"])*)",
    re.M,
)
CONDITIONAL_URI = re.compile(r"\\bif\\s*\\([^)]*\\)\\s*['\\\"]([^'\\\"]+)['\\\"]")
STORY_ALLOWED = {
    "dart:convert",
    "app/lib/domain/models.dart",
    "app/lib/domain/ai_story.dart",
}
# Keep this in sync with app/pubspec.yaml; the regression test checks the name.
APPLICATION_PACKAGE = "lebendiger_spielleiter"
# The facade composes both modules. The two legacy shims must expose
# precisely these canonically owned story implementations and nothing else.
DOMAIN_STORY_IMPORT_ALLOWED = {
    "app/lib/domain/game_engine.dart": {
        "../story/story_campaign_engine.dart",
        "../story/story_memory_engine.dart",
    },
    "app/lib/domain/rabenwacht_campaign.dart": {
        "../story/rabenwacht_campaign.dart",
        "../story/fourteenth_voice_campaign.dart",
        "../story/story_rule_port.dart",
    },
    "app/lib/domain/ai_story.dart": {"../story/ai_story.dart"},
}


def _target(relative_path: str, uri: str) -> str:
    """Resolve relative Dart imports in repository-relative POSIX paths."""
    return posixpath.normpath(posixpath.join(posixpath.dirname(relative_path), uri))


def _package_target(uri: str) -> str | None:
    """Resolve this app's package URIs to canonical repository-relative paths."""
    prefix = f"package:{APPLICATION_PACKAGE}/"
    if not uri.startswith(prefix):
        return None
    return posixpath.normpath("app/lib/" + uri[len(prefix):].lstrip("/"))


def check_imports(relative_path: str, content: str) -> list[str]:
    violations: list[str] = []
    sources: list[str] = []
    for directive in IMPORT.finditer(content):
        sources.append(directive.group("primary"))
        sources.extend(CONDITIONAL_URI.findall(directive.group("conditional")))
    if relative_path.startswith("app/lib/story/"):
        for uri in sources:
            if uri.startswith("dart:"):
                if uri not in STORY_ALLOWED:
                    violations.append(f"{relative_path}: forbidden platform dependency {uri}")
            elif uri.startswith("package:") or ":" in uri:
                violations.append(f"{relative_path}: forbidden provider/framework dependency {uri}")
            else:
                target = _target(relative_path, uri)
                if target.startswith("app/lib/story/") or target in STORY_ALLOWED:
                    continue
                if target.startswith("app/lib/domain/"):
                    violations.append(f"{relative_path}: story must not import {uri}")
                else:
                    violations.append(f"{relative_path}: unexpected cross-module import {uri}")
    elif relative_path.startswith("app/lib/domain/"):
        allowed = DOMAIN_STORY_IMPORT_ALLOWED.get(relative_path, set())
        for uri in sources:
            if uri.startswith("package:"):
                target = _package_target(uri)
                if target is not None and target.startswith("app/lib/story/"):
                    violations.append(f"{relative_path}: rule module imports story {uri}")
                continue
            if ":" in uri:
                continue
            if _target(relative_path, uri).startswith("app/lib/story/") and uri not in allowed:
                violations.append(f"{relative_path}: rule module imports story {uri}")
    return violations


def check_repository(root: Path = ROOT) -> list[str]:
    result: list[str] = []
    story = root / "app/lib/story"
    if not story.exists():
        return ["missing app/lib/story module"]
    for module in (story, root / "app/lib/domain"):
        for file in sorted(module.rglob("*.dart")):
            relative = file.relative_to(root).as_posix()
            result.extend(check_imports(relative, file.read_text(encoding="utf-8")))
    return result


if __name__ == "__main__":
    problems = check_repository()
    if problems:
        for problem in problems:
            print(problem)
        raise SystemExit(1)
    print("Story/Rules-Importgrenzen: OK")
