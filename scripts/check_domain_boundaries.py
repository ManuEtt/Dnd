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
# *every* selectable URI, including when harmless comments separate tokens.
# Also guard part and URI-based part of: these directives share a Dart library
# and therefore must not cross the Story/Rules ownership boundary.
# Keep quoted URIs intact; only tolerate whitespace and Dart comments at the
# grammar's token boundaries, never extract strings from arbitrary code.
_TRIVIA = r"(?:\s|/\*[\s\S]*?\*/|//[^\n]*\n)*"
IMPORT = re.compile(
    r"^[ \t]*(?P<kind>import|export|part(?:" + _TRIVIA + r"of)?)" + _TRIVIA
    + r"['\"](?P<primary>[^'\"]+)['\"]"
    + r"(?P<conditional>(?:" + _TRIVIA
    + r"if" + _TRIVIA + r"\([^)]*\)" + _TRIVIA
    + r"['\"][^'\"]+['\"]" + r")*)",
    re.M,
)
CONDITIONAL_URI = re.compile(
    r"\bif" + _TRIVIA + r"\([^)]*\)" + _TRIVIA
    + r"['\"]([^'\"]+)['\"]"
)

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


def _strip_comments_and_mark_strings(content: str) -> tuple[str, bytearray]:
    """Mask Dart comments without changing offsets; identify string literals.

    Dart block comments may nest. Only actual code can start directives:
    otherwise an import inside a block comment or multiline string can be
    mistaken for code, while a legitimate directive after a comment is missed.
    """
    visible = list(content)
    strings = bytearray(len(content))
    length = len(content)
    index = 0
    while index < length:
        if content.startswith('//', index):
            end = content.find('\\n', index)
            if end < 0:
                end = length
            visible[index:end] = ' ' * (end - index)
            index = end
            continue
        if content.startswith('/*', index):
            start = index
            depth = 1
            index += 2
            while index < length and depth:
                if content.startswith('/*', index):
                    depth += 1
                    index += 2
                elif content.startswith('*/', index):
                    depth -= 1
                    index += 2
                else:
                    index += 1
            for position in range(start, index):
                if content[position] != '\\n':
                    visible[position] = ' '
            continue
        if content[index] in ("'", '"'):
            start = index
            delimiter = content[index] * (
                3 if content.startswith(content[index] * 3, index) else 1
            )
            raw = (
                start > 0 and content[start - 1] in ('r', 'R')
                and (start == 1 or not (
                    content[start - 2].isalnum() or content[start - 2] == '_'
                ))
            )
            index += len(delimiter)
            while index < length:
                if content.startswith(delimiter, index):
                    index += len(delimiter)
                    break
                if content[index] == '\\\\' and not raw:
                    index += 2
                else:
                    index += 1
            for position in range(start, min(index, length)):
                strings[position] = 1
            continue
        index += 1
    return ''.join(visible), strings


def check_imports(relative_path: str, content: str) -> list[str]:
    violations: list[str] = []
    sources: list[tuple[str, str]] = []
    visible, strings = _strip_comments_and_mark_strings(content)
    for directive in IMPORT.finditer(visible):
        if strings[directive.start("kind")]:
            continue
        kind = directive.group("kind")
        sources.append((kind, directive.group("primary")))
        sources.extend(
            (kind, uri)
            for uri in CONDITIONAL_URI.findall(directive.group("conditional"))
        )
    if relative_path.startswith("app/lib/story/"):
        for kind, uri in sources:
            if uri.startswith("dart:"):
                if uri not in STORY_ALLOWED:
                    violations.append(f"{relative_path}: forbidden platform dependency {uri}")
            elif uri.startswith("package:") or ":" in uri:
                violations.append(f"{relative_path}: forbidden provider/framework dependency {uri}")
            else:
                target = _target(relative_path, uri)
                if (target.startswith("app/lib/story/")
                        or (target in STORY_ALLOWED and not kind.startswith("part"))):
                    continue
                if target.startswith("app/lib/domain/"):
                    verb = "include" if kind.startswith("part") else "import"
                    violations.append(f"{relative_path}: story must not {verb} {uri}")
                else:
                    violations.append(f"{relative_path}: unexpected cross-module import {uri}")
    elif relative_path.startswith("app/lib/domain/"):
        allowed = DOMAIN_STORY_IMPORT_ALLOWED.get(relative_path, set())
        for kind, uri in sources:
            verb = "includes" if kind.startswith("part") else "imports"
            if uri.startswith("package:"):
                target = _package_target(uri)
                if target is not None and target.startswith("app/lib/story/"):
                    violations.append(f"{relative_path}: rule module {verb} story {uri}")
                continue
            if ":" in uri:
                continue
            if (_target(relative_path, uri).startswith("app/lib/story/")
                    and (kind.startswith("part") or uri not in allowed)):
                violations.append(f"{relative_path}: rule module {verb} story {uri}")
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
