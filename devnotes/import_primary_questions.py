"""Load the primary-school maths questions into the AR3D question bank.

Reads "primary school questions.docx", which groups 100 questions into four
colour tiers by card range (1-25 HIJAU, 26-50 BIRU, 51-75 UNGU, 76-100 EMAS),
and posts them to the API with a level and a checkpoint square.

Each tier is spread round-robin across the checkpoints that fall inside its own
card range, so every question lands on a square whose difficulty matches it.
The lecturer can move any question afterwards from the admin screen.

    python3 devnotes/import_primary_questions.py --dry-run
    python3 devnotes/import_primary_questions.py --base-url https://... --password ...
"""

import argparse
import json
import re
import sys
import urllib.error
import urllib.request
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
DOCX = Path(__file__).with_name("primary school questions.docx")
TOPIC = "Maths for Primary Students"

# Checkpoints per tier, in board order. Mirrors CHECKPOINTS in server/ar3d/db.py.
TIER_CHECKPOINTS = {
    "HIJAU": [(8, "muzium-samudera"), (18, "menara-taming-sari"), (25, "pantai-klebang")],
    "BIRU": [(35, "masjid-cina"), (39, "kota-a-famosa"), (49, "masjid-selat")],
    "UNGU": [(55, "menara-taming-sari"), (67, "kota-a-famosa"), (71, "stadium-hang-jebat")],
    "EMAS": [
        (79, "muzium-samudera"),
        (81, "masjid-selat"),
        (85, "masjid-cina"),
        (93, "pantai-klebang"),
        (98, "stadium-hang-jebat"),
    ],
}


def _text(element):
    return "".join(node.text or "" for node in element.iter(W + "t")).strip()


def parse_docx():
    """Return [{level, prompt, answer}] in document order."""
    root = ET.fromstring(zipfile.ZipFile(DOCX).read("word/document.xml"))
    questions = []
    tier = None
    for child in root.find(W + "body"):
        if child.tag == W + "p":
            heading = re.match(r"^[^\w]*Tahap (\w+) \(Kad (\d+)[–-](\d+)\)", _text(child))
            if heading:
                tier = heading.group(1).upper()
        elif child.tag == W + "tbl" and tier:
            rows = [[_text(c) for c in r.findall(W + "tc")] for r in child.findall(W + "tr")]
            if not rows or rows[0][0].upper() != "SOALAN":
                continue
            for row in rows[1:]:
                if len(row) >= 2 and row[0] and row[1]:
                    questions.append({"level": tier, "prompt": row[0], "answer": row[1]})
            # Each tier heading owns exactly one question table.
            tier = None
    return questions


def assign_checkpoints(questions):
    """Spread each tier round-robin over the checkpoints inside its card range."""
    seen = {}
    for question in questions:
        squares = TIER_CHECKPOINTS[question["level"]]
        index = seen.get(question["level"], 0)
        square, place = squares[index % len(squares)]
        seen[question["level"]] = index + 1
        question["checkpoint"] = square
        question["place"] = place
    return questions


def _request(url, password, payload=None, method="GET"):
    body = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request(url, data=body, method=method)
    request.add_header("Content-Type", "application/json")
    if password:
        request.add_header("X-Admin-Password", password)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise SystemExit(f"{method} {url} failed: {error.code} {error.read().decode()}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default="https://afwanhaziq.vps.webdock.cloud")
    parser.add_argument("--password", default="change-me")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    questions = assign_checkpoints(parse_docx())
    counts = {}
    for question in questions:
        counts[(question["level"], question["checkpoint"])] = (
            counts.get((question["level"], question["checkpoint"]), 0) + 1
        )
    print(f"Parsed {len(questions)} questions from {DOCX.name}")
    for (level, square), count in sorted(counts.items(), key=lambda item: item[0][1]):
        print(f"  square {square:>2}  {level:<6} {count} questions")

    if args.dry_run:
        for question in questions[:5]:
            print("  sample:", question)
        return

    topics = _request(f"{args.base_url}/api/ar3d/topics", args.password)["topics"]
    topic_id = next((t["id"] for t in topics if t["name"] == TOPIC), None)
    if topic_id is None:
        raise SystemExit(f"Topic {TOPIC!r} not found on the server")

    existing = _request(
        f"{args.base_url}/api/ar3d/questions?topic={urllib.parse.quote(TOPIC)}",
        args.password,
    )["questions"]
    already = {q["prompt"].strip() for q in existing}

    created = skipped = 0
    for question in questions:
        if question["prompt"].strip() in already:
            skipped += 1
            continue
        _request(
            f"{args.base_url}/api/ar3d/admin/questions",
            args.password,
            {
                "topic_id": topic_id,
                "prompt": question["prompt"],
                "accepted_answers": [question["answer"]],
                "level": question["level"],
                "place": question["place"],
                "checkpoint": question["checkpoint"],
                "is_active": 1,
            },
            method="POST",
        )
        created += 1
    print(f"Created {created}, skipped {skipped} already present.")


if __name__ == "__main__":
    sys.exit(main())
