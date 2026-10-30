#!/usr/bin/env python3
"""Audit the countable SRD 5.2.1 working inventory.

No global completion percentage is reported until every SRD section/entity is
inventoried and reconciled with the authoritative source. An unlock catalogue
does not prove that the underlying class feature's effect is implemented.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
MATRIX = ROOT / "docs" / "srd_5_2_1_requirements.json"
CATALOGUE = ROOT / "docs" / "class_feature_coverage_0_6_8.json"
ENTITIES = ROOT / "docs" / "srd_5_2_1_entities.json"
STATUSES = {"tested", "partial", "missing", "unverified"}
AREAS = {
    "class_features", "character_creation", "combat", "core_rules",
    "equipment", "exploration", "feats", "magic_items", "monsters",
    "progression", "spells",
}


def valid_choice(value: object, choices: set[str]) -> bool:
    """Guard set membership against lists and dicts in malformed JSON."""
    return isinstance(value, str) and value in choices


def validate_matrix(matrix: dict, catalogue: dict) -> list[str]:
    errors: list[str] = []
    if not isinstance(matrix, dict) or not isinstance(catalogue, dict):
        return ["Anforderungsmatrix und Klassenkatalog müssen JSON-Objekte sein."]
    if matrix.get("schema_version") != 1 or matrix.get("srd_version") != "5.2.1":
        errors.append("Unerwartetes Matrixschema oder falsche SRD-Version.")
    rows = matrix.get("requirements")
    gaps = matrix.get("inventory_gaps")
    if not isinstance(rows, list) or not isinstance(gaps, list):
        return errors + ["requirements und inventory_gaps müssen Listen sein."]
    ids: set[str] = set()
    for row in rows:
        if not isinstance(row, dict):
            errors.append("Ein Requirement muss ein JSON-Objekt sein.")
            continue
        rid = row.get("id")
        if not isinstance(rid, str) or not rid.strip():
            errors.append("Requirement ohne stabile ID.")
        elif rid in ids:
            errors.append(f"Doppelte Anforderungs-ID: {rid}")
        else:
            ids.add(rid)
        if not valid_choice(row.get("area"), AREAS):
            errors.append(f"{rid}: unbekannter Bereich.")
        if not valid_choice(row.get("rule_implemented"), STATUSES):
            errors.append(f"{rid}: ungültiger Umsetzungsstatus.")
        if not row.get("source_url") or not row.get("source"):
            errors.append(f"{rid}: fehlender SRD-Quellverweis.")
        if not isinstance(row.get("tests"), list) or not isinstance(row.get("code"), list):
            errors.append(f"{rid}: tests/code müssen Listen sein.")
        if not isinstance(row.get("kind"), str):
            errors.append(f"{rid}: ungültiger Anforderungstyp.")
        if row.get("kind") == "level_feature":
            if row.get("class_level") not in range(1, 21):
                errors.append(f"{rid}: Klassenstufe muss 1–20 sein.")
            if row.get("rule_implemented") == "tested" and not row.get("tests"):
                errors.append(f"{rid}: voll getestet ohne konkrete Testreferenz.")
    reference_entries = catalogue.get("entries")
    if not isinstance(reference_entries, list):
        errors.append("Klassenkatalog muss eine entries-Liste enthalten.")
        reference_entries = []
    catalogued = [r for r in rows if isinstance(r, dict) and r.get("kind") == "level_feature"]
    expected_ids: set[str] = set()
    for entry in reference_entries:
        entry_id = entry.get("id") if isinstance(entry, dict) else None
        if not isinstance(entry_id, str) or not entry_id:
            errors.append("Katalogeintrag ohne gültige ID.")
            continue
        expected_ids.add("docs/class_feature_coverage_0_6_8.json#" + entry_id)
    actual_ids: set[str] = set()
    signatures: set[tuple[str | int | None, ...]] = set()
    for row in catalogued:
        reference = row.get("catalogue_reference")
        if not isinstance(reference, str):
            errors.append("Klassenfähigkeit ohne gültige Katalogreferenz.")
        else:
            actual_ids.add(reference)
        signature = tuple(row.get(field) for field in (
            "class_name", "subclass", "class_level", "name"
        ))
        if not all(value is None or isinstance(value, (str, int)) for value in signature):
            errors.append("Klassenfähigkeit mit ungültigen Metadaten.")
        elif signature in signatures:
            # Same-name upgrades can repeat at different levels, but not at the same level.
            errors.append("Doppelte Klassenfähigkeit auf gleicher Klassenstufe.")
        else:
            signatures.add(signature)
    if expected_ids != actual_ids or len(catalogued) != len(reference_entries):
        errors.append("Klassenanforderungen stimmen nicht exakt mit dem 282-Einträge-Referenzkatalog überein.")
    gap_ids: set[str] = set()
    for gap in gaps:
        if not isinstance(gap, dict):
            errors.append("Inventarlücke muss ein JSON-Objekt sein.")
            continue
        gid = gap.get("id")
        if not isinstance(gid, str) or not gid or gid in gap_ids:
            errors.append(f"Ungültige oder doppelte Inventarlücken-ID: {gid}")
        else:
            gap_ids.add(gid)
        if not valid_choice(gap.get("area"), AREAS) or not gap.get("source") or not gap.get("detail"):
            errors.append(f"{gid}: Lücke benötigt Bereich, Referenz und Arbeitsauftrag.")
    if matrix.get("global_percent_permitted") and (
        not matrix.get("scope_complete") or gaps
    ):
        errors.append("Globaler SRD-Prozentsatz trotz offener Inventurlücken unzulässig.")
    if matrix.get("scope_complete") and gaps:
        errors.append("Inventar darf bei offenen Lücken nicht vollständig sein.")
    return errors



def validate_entities(entities: dict, matrix: dict) -> list[str]:
    """Check unique, traceable named entries without treating transcription as verified rules."""
    errors: list[str] = []
    if not isinstance(entities, dict) or not isinstance(matrix, dict):
        return ["Entity-Inventar und Anforderungsmatrix müssen JSON-Objekte sein."]
    if entities.get("schema_version") != 1:
        errors.append("Unbekanntes Entity-Inventarschema.")
    rows = entities.get("entries")
    if not isinstance(rows, list):
        return errors + ["Entity-Inventar muss entries-Liste enthalten."]
    requirements = matrix.get("requirements")
    if not isinstance(requirements, list):
        return errors + ["Anforderungsmatrix muss eine requirements-Liste enthalten."]
    ids = {
        row["id"] for row in requirements
        if isinstance(row, dict) and isinstance(row.get("id"), str)
    }
    names_by_kind: set[tuple[str, str]] = set()
    kinds = {"spell_definition", "monster_statblock", "magic_item", "feat"}
    for row in rows:
        if not isinstance(row, dict):
            errors.append("Entity-Eintrag muss ein JSON-Objekt sein.")
            continue
        rid = row.get("id")
        if not isinstance(rid, str) or not rid:
            errors.append("Unbenannter Entity-Eintrag ohne ID.")
            continue
        if rid in ids:
            errors.append(f"Doppelte Entity-/Requirement-ID: {rid}")
        ids.add(rid)
        if not valid_choice(row.get("kind"), kinds) or not valid_choice(row.get("area"), AREAS):
            errors.append(f"{rid}: Kategorie oder Entitätstyp ungültig.")
        name = row.get("name")
        if not isinstance(name, str) or not name.strip():
            errors.append(f"{rid}: Name fehlt oder Entity mehrfach vorhanden.")
        else:
            key = (row.get("kind") if isinstance(row.get("kind"), str) else "", name)
            if key in names_by_kind:
                errors.append(f"{rid}: Name fehlt oder Entity mehrfach vorhanden.")
            names_by_kind.add(key)
        if not valid_choice(row.get("rule_implemented"), STATUSES):
            errors.append(f"{rid}: kein gültiger Implementierungsstatus.")
        if not row.get("source_url") or not row.get("transcription_url"):
            errors.append(f"{rid}: Quellen- oder Provenienzverweis fehlt.")
        if row.get("rule_implemented") == "tested" and not row.get("tests"):
            errors.append(f"{rid}: getestet ohne konkreten Testnachweis.")
        if row.get("kind") == "spell_definition" and row.get("spell_level") not in range(10):
            errors.append(f"{rid}: Zauberstufe 0 bis 9 erforderlich.")
    if entities.get("verified_against_official_pdf") is True and matrix.get("inventory_gaps"):
        errors.append("Entitätskatalog kann bei ungeprüften Quellenlücken nicht als offiziell verifiziert gelten.")
    return errors


def summary(matrix: dict, entities: dict | None = None) -> dict:
    rows = matrix["requirements"] + (entities["entries"] if entities else [])
    return {
        "counted_requirements": len(rows),
        "by_area": dict(sorted(Counter(r["area"] for r in rows).items())),
        "by_status": dict(sorted(Counter(r["rule_implemented"] for r in rows).items())),
        "class_feature_entries": sum(r["kind"] == "level_feature" for r in rows),
        "open_inventory_gaps": len(matrix["inventory_gaps"]),
        "scope_complete": matrix["scope_complete"],
        "global_srd_coverage_percent": None,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--matrix", type=Path, default=MATRIX)
    parser.add_argument("--catalogue", type=Path, default=CATALOGUE)
    parser.add_argument("--entities", type=Path, default=ENTITIES)
    parser.add_argument("--json", action="store_true", help="Zusammenfassung als JSON ausgeben")
    parser.add_argument("--require-complete-inventory", action="store_true")
    parser.add_argument("--require-fully-tested", action="store_true")
    args = parser.parse_args(argv)
    matrix = json.loads(args.matrix.read_text(encoding="utf-8"))
    catalogue = json.loads(args.catalogue.read_text(encoding="utf-8"))
    entities = json.loads(args.entities.read_text(encoding="utf-8"))
    errors = validate_matrix(matrix, catalogue) + validate_entities(entities, matrix)
    # Invalid record structure must not reach completeness checks or summary,
    # where indexing an invalid record could raise TypeError or KeyError.
    if errors:
        print("\n".join("FEHLER: " + e for e in errors), file=sys.stderr)
        return 1
    if args.require_complete_inventory and (not matrix.get("scope_complete") or matrix.get("inventory_gaps")):
        errors.append("SRD-Gesamtinventar ist noch nicht vollständig.")
    if args.require_fully_tested and (
        not matrix.get("scope_complete") or matrix.get("inventory_gaps") or
        any(r["rule_implemented"] != "tested" for r in matrix.get("requirements", []) + entities.get("entries", []))
    ):
        errors.append("Die vollständig getestete SRD-Engine ist noch nicht nachgewiesen.")
    if errors:
        print("\n".join("FEHLER: " + e for e in errors), file=sys.stderr)
        return 1
    result = summary(matrix, entities)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"SRD 5.2.1: {result['counted_requirements']} eindeutig erfasste Arbeitsanforderungen")
        print(f"Klassen-Freischaltungen: {result['class_feature_entries']}")
        print(f"Offene Bereiche der Quelleninventur: {result['open_inventory_gaps']}")
        for key, value in result["by_status"].items():
            print(f"  {key}: {value}")
        print("GESAMT-SRD-FERTIGSTELLUNG: NICHT BERECHENBAR (Inventar unvollständig)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
