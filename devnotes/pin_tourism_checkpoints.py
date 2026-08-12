"""Pin the Tourism Melaka questions to the squares of their own landmark.

Every question already names a landmark through its `place`, but the board
prints each landmark twice — once early, once late — and the questions were not
pinned to either. The scanner therefore fell back to matching on place, so both
squares of a landmark served the same pool and a student could meet the same
question twice with no difficulty progression.

Each landmark's questions are split down the middle: the first half goes to the
early square, the second half to the late one. Nothing is reworded, and any
question the lecturer has already pinned by hand is left alone.

    python3 devnotes/pin_tourism_checkpoints.py --dry-run
    python3 devnotes/pin_tourism_checkpoints.py --password change-me
"""

import argparse
import json
import sys
import urllib.error
import urllib.request

TOPIC = "Tourism Melaka"

# place -> (early square, late square). Mirrors CHECKPOINTS in server/ar3d/db.py.
SQUARES = {
    "muzium-samudera": (8, 79),
    "menara-taming-sari": (18, 55),
    "pantai-klebang": (25, 93),
    "masjid-cina": (35, 85),
    "kota-a-famosa": (39, 67),
    "masjid-selat": (49, 81),
    "stadium-hang-jebat": (71, 98),
}


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

    rows = _request(f"{args.base_url}/api/ar3d/admin/questions", args.password)["questions"]
    questions = [q for q in rows if q["topic_name"] == TOPIC and q["is_active"]]

    plan = []
    for place, (early, late) in sorted(SQUARES.items()):
        mine = [q for q in questions if q.get("place") == place]
        # Keep a stable order so a re-run assigns the same squares.
        mine.sort(key=lambda q: q["id"])
        half = (len(mine) + 1) // 2
        for index, question in enumerate(mine):
            square = early if index < half else late
            if question.get("checkpoint") == square:
                continue
            plan.append((question, square))

    unplaced = [q for q in questions if q.get("place") not in SQUARES]
    print(f"{len(questions)} active {TOPIC} questions")
    for place, (early, late) in sorted(SQUARES.items()):
        mine = [q for q in questions if q.get("place") == place]
        half = (len(mine) + 1) // 2
        print(f"  {place:22} {len(mine):>3} -> {half} on square {early}, {len(mine)-half} on square {late}")
    if unplaced:
        print(f"  !! {len(unplaced)} question(s) have no recognised place and are left alone")
    print(f"\n{len(plan)} question(s) need updating")

    if args.dry_run:
        for question, square in plan[:6]:
            print(f"   id={question['id']} -> square {square}  {question['prompt'][:46]!r}")
        return

    for question, square in plan:
        _request(
            f"{args.base_url}/api/ar3d/admin/questions/{question['id']}",
            args.password,
            {
                "topic_id": question["topic_id"],
                "prompt": question["prompt"],
                "accepted_answers": question["accepted_answers"],
                "is_active": 1,
                "checkpoint": str(square),
                # Sent back unchanged; the update endpoint would keep them
                # anyway, but being explicit makes the intent obvious.
                "place": question["place"],
                "options": question.get("options") or [],
            },
            method="PUT",
        )
    print(f"Updated {len(plan)} question(s).")


if __name__ == "__main__":
    sys.exit(main())
