"""Dump the maths question banks from the live API into a devnotes markdown file.

Unlike the Sejarah bank there is no source document for these — the API is the
only copy, so this reads the admin endpoint and writes a readable snapshot.

    AR3D_ADMIN_PASSWORD=... python3 tools/dump_maths_questions.py
"""
import json
import os
import urllib.request
from collections import defaultdict

BASE = "https://afwanhaziq.vps.webdock.cloud"
PASSWORD = os.environ.get("AR3D_ADMIN_PASSWORD", "change-me")
OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "devnotes",
    "maths-questions-all.md",
)

# Topic id -> (heading, ordering weight). Tourism Melaka (4) lives in its own
# file because it is generated from the .docx sources instead.
TOPICS = {
    1: "Maths for Primary Students",
    2: "Maths for Secondary Students",
    3: "Maths for Higher Education",
}
LEVEL_ORDER = ["ASAS", "SEDERHANA", "APLIKASI", "ANALISIS", "CABARAN"]


def fetch(path, admin=False):
    req = urllib.request.Request(BASE + path)
    req.add_header("Accept", "application/json")
    if admin:
        req.add_header("X-Admin-Password", PASSWORD)
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.loads(response.read().decode())


def render_question(lines, index, q):
    flag = "" if q.get("is_active") else "  *(inactive)*"
    lines.append(f"**{index}. {q['prompt']}**{flag}\n")
    options = q.get("options") or []
    accepted = q.get("accepted_answers") or []
    if options:
        for i, option in enumerate(options):
            letter = chr(65 + i)
            correct = any(
                option.strip().lower() == a.strip().lower() for a in accepted
            )
            lines.append(
                f"- **{letter}. {option}** ✅" if correct else f"- {letter}. {option}"
            )
    else:
        # Free-text question: every accepted spelling of the answer is graded.
        lines.append("- Answer: " + " / ".join(f"`{a}`" for a in accepted))
    if q.get("image_url"):
        lines.append(f"- Image: {q['image_url']}")
    lines.append("")


def main():
    questions = fetch("/api/ar3d/admin/questions", admin=True)["questions"]
    version = fetch("/api/ar3d/health").get("version", "unknown")

    grouped = defaultdict(lambda: defaultdict(list))
    for q in questions:
        if q["topic_id"] in TOPICS:
            grouped[q["topic_id"]][q.get("level") or ""].append(q)

    total = sum(len(v) for levels in grouped.values() for v in levels.values())
    lines = [
        "# Maths question banks — all questions\n",
        f"Snapshot of the live API (`{BASE}`, version `{version}`), "
        f"{total} questions across the three maths topics.\n",
        "There is no source document for these — the server database is the only "
        "copy, so this file is a backup as much as a reference. Regenerate with "
        "`python3 tools/dump_maths_questions.py`; do not hand-edit.\n",
        "Free-text questions list every accepted spelling of the answer. "
        "Multiple-choice questions mark the correct option. Questions flagged "
        "*(inactive)* are hidden from the app.\n",
        "Tourism Melaka (topic 4) is in "
        "[`sejarah-questions-all.md`](sejarah-questions-all.md).\n",
    ]

    for topic_id in sorted(grouped):
        levels = grouped[topic_id]
        count = sum(len(v) for v in levels.values())
        lines.append(f"## {TOPICS[topic_id]}\n")
        lines.append(f"`topic_id={topic_id}` · {count} questions\n")
        ordered = [lvl for lvl in LEVEL_ORDER if lvl in levels]
        ordered += [lvl for lvl in sorted(levels) if lvl not in ordered]
        for level in ordered:
            items = sorted(levels[level], key=lambda q: q["id"])
            if level:
                lines.append(f"### {level}\n")
                lines.append(f"`level={level}` · {len(items)} questions\n")
            elif len(ordered) > 1:
                lines.append("### No level\n")
            for i, q in enumerate(items, 1):
                render_question(lines, i, q)

    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))
    print(f"wrote {OUT} ({total} questions)")


if __name__ == "__main__":
    main()
