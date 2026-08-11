"""Load the higher-education maths questions into the AR3D question bank.

The source document, "SOALAN MATEMATIK iGB (NEW) higher education.docx", cannot
be parsed. Word saved it with no superscript runs at all, so every exponent was
flattened into a plain digit -- "23 x 25" is really 2**3 x 2**5 -- and the
matrices, fractions and integrals were broken into loose text fragments that
land in the wrong section. Bahagian G's equations sit after Bahagian H's
heading.

So the questions below are transcribed by hand instead, with the notation
restored. Where the flattened text was ambiguous the answer settles it: "23 x
25" has to be 2**3 x 2**5 because the document's own answer is 2**8 = 256.

Higher Education carries no level and no checkpoint. Those exist for the other
banks only -- Primary pins questions to board squares, Secondary sorts them into
difficulty buckets -- and scanner_screen.dart draws this topic whole:

    // Level buckets only exist under the secondary-school bank on the server;
    // Primary and Higher Education are drawn whole.

    python3 devnotes/import_higher_education_questions.py --dry-run
    python3 devnotes/import_higher_education_questions.py --password change-me
"""

import argparse
import json
import sys
import urllib.error
import urllib.parse
import urllib.request

TOPIC = "Maths for Higher Education"

# (section, prompt, [accepted answers]) -- the first answer is shown as the
# correct one. The alternatives spell out the same value in the other forms a
# student is likely to type; the server already ignores case, spacing and
# equivalent numbers such as 1.5 and 3/2.
QUESTIONS = [
    # ---- Bahagian A: Pemfaktoran Algebra ----
    ("A", "Faktorkan sepenuhnya: x² + 7x + 12", ["(x + 3)(x + 4)", "(x + 4)(x + 3)"]),
    ("A", "Faktorkan: 3x² + 12x", ["3x(x + 4)", "3x(4 + x)"]),
    ("A", "Faktorkan: 4x² − 9", ["(2x − 3)(2x + 3)", "(2x + 3)(2x − 3)"]),
    ("A", "Faktorkan: 2x² + 5x − 3", ["(2x − 1)(x + 3)", "(x + 3)(2x − 1)"]),

    # ---- Bahagian B: Persamaan Linear ----
    ("B", "Selesaikan: 5x − 12 = 18", ["x = 6", "6"]),
    ("B", "Selesaikan: 7(x − 2) = 3x + 12", ["x = 13/2", "13/2", "6.5", "x = 6.5"]),
    ("B", "Selesaikan: x/3 + 5 = 9", ["x = 12", "12"]),

    # ---- Bahagian C: Persamaan Kuadratik ----
    ("C", "Selesaikan: x² − 6x + 8 = 0", ["x = 2, 4", "2, 4", "x = 4, 2"]),
    ("C", "Selesaikan: x² − 9 = 0", ["x = ±3", "x = 3, −3", "±3", "3, −3"]),
    ("C", "Selesaikan: 2x² + 6x = 0", ["x = 0, −3", "0, −3", "x = −3, 0"]),

    # ---- Bahagian D: Indeks (Laws of Indices) ----
    ("D", "Permudahkan: x⁷ ÷ x²", ["x⁵", "x^5"]),
    ("D", "Permudahkan: a³ × a⁵", ["a⁸", "a^8"]),
    ("D", "Permudahkan: (x³)²", ["x⁶", "x^6"]),
    ("D", "Permudahkan: 3x⁴y² ÷ 6xy", ["x³y/2", "x^3y/2", "(x³y)/2"]),

    # ---- Bahagian E: Pecahan Algebra ----
    ("E", "Permudahkan: (x² − 9)/(x − 3)", ["x + 3", "3 + x"]),
    ("E", "Permudahkan: 3x/9", ["x/3"]),
    ("E", "Tambah: x/4 + x/2", ["3x/4"]),

    # ---- Bahagian F: Fungsi ----
    ("F", "Diberi f(x) = 4x − 5. Cari f(3).", ["7", "f(3) = 7"]),
    ("F", "Diberi g(x) = x² + 2. Cari g(−2).", ["6", "g(−2) = 6"]),
    ("F", "Diberi f(x) = 2x + 1. Cari f(5).", ["11", "f(5) = 11"]),

    # ---- Bahagian G: Sistem Persamaan ----
    ("G", "Selesaikan sistem persamaan: x + y = 9 dan x − y = 3", ["x = 6, y = 3", "x=6, y=3"]),
    ("G", "Selesaikan sistem persamaan: 2x + y = 10 dan x + y = 7", ["x = 3, y = 4", "x=3, y=4"]),

    # ---- Bahagian H: Matriks ----
    ("H", "Diberi A = [[1, 2], [3, 4]]. Cari 2A.", ["[[2, 4], [6, 8]]", "2 4 6 8"]),
    ("H", "Cari hasil tambah [[1, 2], [3, 4]] + [[5, 6], [7, 8]]", ["[[6, 8], [10, 12]]", "6 8 10 12"]),
    ("H", "Cari determinan matriks [[2, 5], [1, 4]]", ["3"]),

    # ---- Bahagian I: Differentiation (Pembezaan) ----
    ("I", "Cari dy/dx jika y = 5x³", ["15x²", "15x^2"]),
    ("I", "Cari dy/dx jika y = 7x⁴ − 3x", ["28x³ − 3", "28x^3 − 3"]),
    ("I", "Cari dy/dx jika y = 6", ["0"]),
    ("I", "Cari dy/dx jika y = 4x⁵ + 2x² − 8", ["20x⁴ + 4x", "20x^4 + 4x"]),
    ("I", "Cari dy/dx jika y = √x", ["1/(2√x)", "1/(2 akar x)", "(1/2)x^(−1/2)"]),
    ("I", "Cari dy/dx jika y = 1/x", ["−1/x²", "−1/x^2", "−x^(−2)"]),
    ("I", "Cari dy/dx jika y = 3x² + 5x − 7", ["6x + 5"]),
    ("I", "Cari kecerunan lengkung y = x³ − 2x + 1 pada x = 2", ["10"]),
    ("I", "Cari dy/dx jika y = 8x^(3/2)", ["12x^(1/2)", "12√x", "12 akar x"]),
    ("I", "Cari dy/dx jika y = 2x⁵ − x² + 4x − 9", ["10x⁴ − 2x + 4", "10x^4 − 2x + 4"]),

    # ---- Bahagian J: Integration (Pengamiran) ----
    ("J", "Cari ∫ 5x³ dx", ["(5/4)x⁴ + C", "5x⁴/4 + C"]),
    ("J", "Cari ∫ 6x dx", ["3x² + C", "3x^2 + C"]),
    ("J", "Cari ∫ (4x³ + 2x) dx", ["x⁴ + x² + C", "x^4 + x^2 + C"]),
    ("J", "Cari ∫ 9 dx", ["9x + C"]),
    ("J", "Cari ∫ x⁵ dx", ["x⁶/6 + C", "(1/6)x⁶ + C"]),
    ("J", "Cari ∫ (1/x) dx", ["ln |x| + C", "ln|x| + C"]),
    ("J", "Cari ∫ √x dx", ["(2/3)x^(3/2) + C", "2x^(3/2)/3 + C"]),
    ("J", "Cari ∫ (2x² + 5) dx", ["(2/3)x³ + 5x + C", "2x³/3 + 5x + C"]),
    ("J", "Cari ∫ (3x⁴ − 8x) dx", ["(3/5)x⁵ − 4x² + C", "3x⁵/5 − 4x² + C"]),
    ("J", "Cari ∫ (7x² + 4x − 3) dx", ["(7/3)x³ + 2x² − 3x + C", "7x³/3 + 2x² − 3x + C"]),

    # ---- Bahagian K: Indeks (Indices) ----
    ("K", "Permudahkan: 2³ × 2⁵", ["256", "2⁸", "2^8"]),
    ("K", "Permudahkan: x⁸ ÷ x³", ["x⁵", "x^5"]),
    ("K", "Permudahkan: (a⁴)³", ["a¹²", "a^12"]),
    ("K", "Permudahkan: x⁵y³ × x²y⁴", ["x⁷y⁷", "x^7y^7"]),
    ("K", "Permudahkan: 12x⁵y³ ÷ 4x²y", ["3x³y²", "3x^3y^2"]),
    ("K", "Permudahkan: x⁰ (dengan x ≠ 0)", ["1"]),
    ("K", "Permudahkan: x⁻³", ["1/x³", "1/x^3"]),
    ("K", "Permudahkan: (x/y)²", ["x²/y²", "x^2/y^2"]),
    ("K", "Permudahkan: 27^(1/3)", ["3"]),
    ("K", "Permudahkan: 16^(1/2)", ["4"]),

    # ---- Bahagian L: Logaritma (Logarithms) ----
    ("L", "Tukarkan kepada bentuk eksponen: log₂ 8 = 3", ["2³ = 8", "2^3 = 8"]),
    ("L", "Tukarkan kepada bentuk logaritma: 10⁴ = 10000", ["log₁₀ 10000 = 4", "log10 10000 = 4"]),
    ("L", "Hitungkan: log₁₀ 100", ["2"]),
    ("L", "Hitungkan: log₅ 125", ["3"]),
    ("L", "Hitungkan: log₃ 81", ["4"]),
    ("L", "Permudahkan: log₂ 8 + log₂ 4", ["5", "3 + 2 = 5"]),
    ("L", "Gunakan hukum logaritma untuk permudahkan: log x + log y", ["log(xy)", "log xy"]),
    ("L", "Gunakan hukum logaritma untuk permudahkan: log x − log y", ["log(x/y)", "log x/y"]),
    ("L", "Selesaikan: log₂(x) = 5", ["x = 32", "32"]),
    ("L", "Selesaikan: log₁₀(x) = 2", ["x = 100", "100"]),

    # ---- Bahagian M: Soalan Aplikasi (Indices & Logarithms) ----
    ("M", "Selesaikan: 3ˣ = 81", ["x = 4", "4"]),
    ("M", "Selesaikan: 2^(x+1) = 32", ["x = 4", "4"]),
    ("M", "Selesaikan: 5^(2x) = 125", ["x = 3/2", "3/2", "1.5", "x = 1.5"]),
    ("M", "Selesaikan: log₄(x) = 3", ["x = 64", "64"]),
    ("M", "Selesaikan: log₇(49) = x", ["x = 2", "2"]),
]

SECTIONS = {
    "A": "Pemfaktoran Algebra", "B": "Persamaan Linear", "C": "Persamaan Kuadratik",
    "D": "Indeks", "E": "Pecahan Algebra", "F": "Fungsi", "G": "Sistem Persamaan",
    "H": "Matriks", "I": "Differentiation", "J": "Integration", "K": "Indeks (Indices)",
    "L": "Logaritma", "M": "Soalan Aplikasi",
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

    # The document has exactly 70 questions, Soalan 1 to 70.
    if len(QUESTIONS) != 70:
        raise SystemExit(f"expected 70 questions, have {len(QUESTIONS)}")
    prompts = [q[1] for q in QUESTIONS]
    if len(set(prompts)) != len(prompts):
        raise SystemExit("duplicate prompts would be skipped on re-run")

    counts = {}
    for section, _, _ in QUESTIONS:
        counts[section] = counts.get(section, 0) + 1
    print(f"{len(QUESTIONS)} questions ready for {TOPIC}")
    for section in sorted(counts):
        print(f"  Bahagian {section}  {SECTIONS[section]:<22} {counts[section]:>2}")

    if args.dry_run:
        print("\nsamples:")
        for section, prompt, answers in QUESTIONS[:3] + QUESTIONS[-2:]:
            print(f"  [{section}] {prompt}\n        -> {answers}")
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
    for _, prompt, answers in QUESTIONS:
        if prompt.strip() in already:
            skipped += 1
            continue
        _request(
            f"{args.base_url}/api/ar3d/admin/questions",
            args.password,
            {
                "topic_id": topic_id,
                "prompt": prompt,
                "accepted_answers": answers,
                "is_active": 1,
            },
            method="POST",
        )
        created += 1
    print(f"\nCreated {created}, skipped {skipped} already present.")


if __name__ == "__main__":
    sys.exit(main())
