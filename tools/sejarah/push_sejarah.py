"""Push the parsed Sejarah Melaka questions to the live AR3D API.

Safe to re-run: questions already on the server (matched by prompt within the
same place) are skipped rather than duplicated.
"""
import json
import os
import sys
import urllib.error
import urllib.request

BASE = "https://afwanhaziq.vps.webdock.cloud"
PASSWORD = os.environ.get("AR3D_ADMIN_PASSWORD", "change-me")
TOPIC = "Tourism Melaka"
SOURCE = os.path.join(os.path.dirname(__file__), "sejarah_questions.json")
DRY_RUN = "--dry-run" in sys.argv


def request(method, path, payload=None, admin=False):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Accept", "application/json")
    if data:
        req.add_header("Content-Type", "application/json")
    if admin:
        req.add_header("X-Admin-Password", PASSWORD)
    with urllib.request.urlopen(req, timeout=20) as response:
        body = response.read().decode()
    return json.loads(body) if body else {}


def main():
    questions = json.load(open(SOURCE, encoding="utf-8"))

    # The place and options columns only exist on the newer backend; without
    # them the push would silently drop both fields.
    health = request("GET", "/api/ar3d/health")
    version = health.get("version", "")
    if version < "2026.07.28.1":
        sys.exit(
            f"Server is running an older build (version={version or 'unknown'}).\n"
            "Pull afwan_cron on the VPS and restart Flask before pushing."
        )

    topics = request("GET", "/api/ar3d/topics")["topics"]
    topic = next((t for t in topics if t["name"] == TOPIC), None)
    if topic is None:
        sys.exit(f"Topic {TOPIC!r} not found on the server.")

    existing = request("GET", "/api/ar3d/admin/questions", admin=True)["questions"]
    seen = {
        (q.get("place"), (q.get("prompt") or "").strip())
        for q in existing
        if q.get("topic_id") == topic["id"]
    }

    created = skipped = 0
    for item in questions:
        key = (item["place"], item["question"].strip())
        if key in seen:
            skipped += 1
            continue
        payload = {
            "topic_id": topic["id"],
            "prompt": item["question"],
            "accepted_answers": [item["correct_answer"]],
            "options": item["options"],
            "place": item["place"],
            "is_active": True,
        }
        if DRY_RUN:
            print(f"would create [{item['place']}] {item['question'][:60]}")
        else:
            try:
                request("POST", "/api/ar3d/admin/questions", payload, admin=True)
            except urllib.error.HTTPError as error:
                sys.exit(
                    f"Failed on [{item['place']}] {item['question'][:60]}: "
                    f"{error.code} {error.read().decode()[:300]}"
                )
        created += 1

    print(f"created={created} skipped={skipped} total={len(questions)}")


if __name__ == "__main__":
    main()
