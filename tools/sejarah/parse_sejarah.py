"""Parse the Sejarah Melaka .docx question banks into structured JSON."""
import glob
import json
import os
import re
import unicodedata
import zipfile

DOCS = "/Users/afwanhaziq/Documents/GitHub/my_ar_app/docs/sejarahmelakaquestions"
OUT = os.path.join(os.path.dirname(__file__), "sejarah_questions.json")

# docx filename -> (place code, display name)
PLACES = {
    "KOTA A FAMOSA": ("kota-a-famosa", "Kota A'Famosa"),
    "MASJID CINA MELAKA": ("masjid-cina", "Masjid Cina Melaka"),
    "MASJID SELAT": ("masjid-selat", "Masjid Selat Melaka"),
    "MENARA TAMING SARI": ("menara-taming-sari", "Menara Taming Sari"),
    "MUZIUM SAMUDERA": ("muzium-samudera", "Muzium Samudera"),
    "PANTAI KLEBANG": ("pantai-klebang", "Pantai Klebang"),
    "STADIUM HANG JEBAT": ("stadium-hang-jebat", "Stadium Hang Jebat"),
}


def docx_lines(path):
    with zipfile.ZipFile(path) as z:
        xml = z.read("word/document.xml").decode("utf-8")
    xml = xml.replace("</w:p>", "\n")
    text = re.sub(r"<[^>]+>", "", xml)
    for entity, char in (("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
                         ("&quot;", '"'), ("&apos;", "'")):
        text = text.replace(entity, char)
    text = unicodedata.normalize("NFKC", text)
    return [line.strip() for line in text.split("\n") if line.strip()]


def norm(value):
    """Loose comparison key: lowercase, no punctuation, collapsed spaces."""
    value = unicodedata.normalize("NFKC", value).lower()
    value = re.sub(r"[^\w\s]", " ", value)
    return " ".join(value.split())


def parse(path):
    lines = docx_lines(path)
    title = lines[0].strip()
    place_code, place_name = PLACES[title]

    questions = []
    current = None
    pending_answer = None

    def flush():
        if current and current["options"]:
            questions.append(current)

    for line in lines[1:]:
        q_match = re.match(r"^(\d+)\s*[.)]\s*(.+)$", line)
        opt_match = re.match(r"^([A-D])\s*[.)]\s*(.+)$", line)
        ans_match = re.match(r"^Jawapan\s*:\s*(.*)$", line, re.I)

        if ans_match:
            pending_answer = ans_match.group(1).strip()
            if current is not None:
                current["raw_answer"] = pending_answer
        elif opt_match:
            if current is not None:
                current["options"].append(
                    (opt_match.group(1), opt_match.group(2).strip())
                )
        elif q_match:
            flush()
            current = {
                "number": int(q_match.group(1)),
                "question": q_match.group(2).strip(),
                "options": [],
                "raw_answer": None,
            }
        elif current is not None and current.get("raw_answer"):
            # Continuation of a wrapped answer line.
            current["raw_answer"] += " " + line
    flush()

    results = []
    problems = []
    for q in questions:
        raw = (q.get("raw_answer") or "").strip()
        letter_match = re.match(r"^([A-D])\s*[.)]?\s*(.*)$", raw, re.I)
        letter = letter_match.group(1).upper() if letter_match else None
        answer_text = (letter_match.group(2) if letter_match else raw).strip()

        options = [text for _, text in q["options"]]
        by_letter = {ltr: text for ltr, text in q["options"]}

        # Prefer matching the answer TEXT; letters in the source are sometimes wrong.
        index = None
        if answer_text:
            for i, text in enumerate(options):
                if norm(text) == norm(answer_text):
                    index = i
                    break
            if index is None:
                for i, text in enumerate(options):
                    if norm(answer_text) and norm(answer_text) in norm(text):
                        index = i
                        break
        matched_by = "text"
        if index is None and letter and letter in by_letter:
            index = [ltr for ltr, _ in q["options"]].index(letter)
            matched_by = "letter"

        if index is None:
            problems.append(f"{title} Q{q['number']}: cannot resolve answer {raw!r}")
            continue
        if letter and letter in by_letter and answer_text:
            if norm(by_letter[letter]) != norm(options[index]):
                problems.append(
                    f"{title} Q{q['number']}: letter '{letter}' points to "
                    f"{by_letter[letter]!r} but answer text says {answer_text!r} "
                    f"-> using text (option {chr(65 + index)})"
                )
        if len(options) != 4:
            problems.append(
                f"{title} Q{q['number']}: has {len(options)} options, expected 4"
            )

        results.append({
            "place": place_code,
            "place_name": place_name,
            "number": q["number"],
            "question": q["question"],
            "options": options,
            "correct_index": index,
            "correct_answer": options[index],
            "matched_by": matched_by,
        })
    return results, problems


all_questions = []
all_problems = []
for path in sorted(glob.glob(os.path.join(DOCS, "*.docx"))):
    got, problems = parse(path)
    all_questions.extend(got)
    all_problems.extend(problems)
    print(f"{os.path.basename(path):28} {len(got):2} questions")

print("\nTOTAL:", len(all_questions))
if all_problems:
    print("\nISSUES FOUND:")
    for problem in all_problems:
        print(" -", problem)
else:
    print("\nNo issues found.")

with open(OUT, "w", encoding="utf-8") as fh:
    json.dump(all_questions, fh, ensure_ascii=False, indent=2)
print("\nWrote", OUT)
