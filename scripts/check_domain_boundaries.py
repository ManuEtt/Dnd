#!/usr/bin/env python3
"""Enforce independent story/rules tracks at the explicit module boundary.

The legacy GameEngine is currently the facade/composition root; shared
models.dart is transitional until typed rule/story snapshots are separated.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IMPORT = re.compile(r"^\s*(?:import|export)\s+['\"]([^'\"]+)['\"]", re.M)
STORY_ALLOWED = {
    "dart:convert",
    "../domain/models.dart",
    "../domain/ai_story.dart",
}
DOMAIN_STORY_IMPORT_ALLOWED = {
    "app/lib/domain/game_engine.dart",
}


def check_imports(relative_path: str, content: str) -> list[str]:
    violations: list[str] = []
    sources = IMPORT.findall(content)
    if relative_path.startswith("app/lib/story/"):
        for uri in sources:
            if uri.startswith("dart:") and uri not in STORY_ALLOWED:
                violations.append(f"{relative_path}: forbidden platform dependency {uri}")
            elif uri.startswith("package:"):
                violations.append(f"{relative_path}: forbidden provider/framework dependency {uri}")
            elif uri.startswith("../") and uri not in STORY_ALLOWED:
                violations.append(f"{relative_path}: story must not import {uri}")
            elif "/" in uri and not uri.startswith("../"):
                violations.append(f"{relative_path}: unexpected cross-module import {uri}")
    elif relative_path.startswith("app/lib/domain/"):
        if relative_path not in DOMAIN_STORY_IMPORT_ALLOWED:
            for uri in sources:
                if uri.startswith("../story/"):
                    violations.append(f"{relative_path}: rule module imports story {uri}")
    return violations


def check_repository(root: Path = ROOT) -> list[str]:
    result: list[str] = []
    story = root / "app/lib/story"
    if not story.exists():
        return ["missing app/lib/story module"]
    for module in (story, root / "app/lib/domain"):
        for file in sorted(module.glob("*.dart")):
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
