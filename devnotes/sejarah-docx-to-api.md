# Sejarah Melaka: .docx → live question bank

How the 66 landmark questions got from Word documents into the AR3D API.
Written up so the next batch of landmarks can follow the same path.

The questions themselves, all 66 with answers marked, are in
[`sejarah-questions-all.md`](sejarah-questions-all.md).

## The pipeline

```
docs/sejarahmelakaquestions/*.docx
  → tools/sejarah/parse_sejarah.py
  → tools/sejarah/sejarah_questions.json
  → tools/sejarah/push_sejarah.py
  → https://afwanhaziq.vps.webdock.cloud  (topic "Tourism Melaka", id 4)
  → app fetches per-landmark via ?place=<code>
```

## 1. Source documents

Seven `.docx` files, one per landmark, in `docs/sejarahmelakaquestions/`.
Each follows the same shape:

```
KOTA A FAMOSA            <- line 1 is the title, and the place lookup key
1. Siapa membina Kota A'Famosa?
A. Belanda
B. Portugis
C. Inggeris
D. Jepun
Jawapan: B. Portugis
```

Counts: Kota A'Famosa 10, Masjid Cina 10, **Masjid Selat 6**, Menara Taming
Sari 10, Muzium Samudera 10, Pantai Klebang 10, Stadium Hang Jebat 10 = 66.
Masjid Selat really does only have 6 in the source — it is not a parse failure.

## 2. Parsing

No `python-docx` dependency. A `.docx` is a zip, so the parser reads
`word/document.xml` directly, turns `</w:p>` into newlines, strips tags with a
regex, and unescapes the five XML entities. Then `unicodedata.NFKC` normalises
the curly apostrophes and non-breaking spaces Word likes to insert — without
that, `Kota A'Famosa` in the prompt and in the answer line don't compare equal.

Line classification is three regexes: question (`^\d+[.)]`), option
(`^[A-D][.)]`), answer (`^Jawapan\s*:`). Anything else after an answer line is
treated as a wrapped continuation of that answer.

### The important rule: match by text, not by letter

Several documents print the wrong letter next to the right answer. So the
parser resolves the answer by comparing the answer **text** against the option
texts (exact on a normalised key first, then substring), and only falls back to
the letter when no text match exists. `matched_by` in the JSON records which
path was taken.

Known case: Kota A'Famosa Q5 says `Jawapan: B. Porta de Santiago`, but
"Porta de Santiago" is option **A**. The text wins, which is also the
historically correct answer.

The parser prints every discrepancy it finds rather than silently picking one,
so a new batch of documents gets reviewed before it is pushed.

## 3. The JSON

`tools/sejarah/sejarah_questions.json` is committed. One object per question:

```json
{
  "place": "kota-a-famosa",
  "place_name": "Kota A'Famosa",
  "number": 1,
  "question": "...",
  "options": ["Belanda", "Portugis", "Inggeris", "Jepun"],
  "correct_index": 1,
  "correct_answer": "Portugis",
  "matched_by": "text"
}
```

`place` is the code the app sends as `?place=`; it must match the `'place'`
value in `_placeInfo` in `lib/screens/scanner_screen.dart`.

## 4. Pushing

`push_sejarah.py` posts each question to `/api/ar3d/admin/questions` under
topic "Tourism Melaka" (id 4), with `X-Admin-Password`. Two safety properties:

- **Idempotent.** It reads the existing admin question list first and skips
  anything already stored with the same `(place, prompt)`. Re-running is safe.
- **Version guarded.** It calls `/api/ar3d/health` and refuses to run against a
  server older than `2026.07.28.1`. That build is the first with the `place`
  and `choices_json` columns; an older backend accepts the POST but silently
  drops both fields, which would have left 66 questions with no options and no
  place. This bit us conceptually before it bit us in practice — the guard
  exists because the VPS was behind at the time.

Password comes from `AR3D_ADMIN_PASSWORD`. Dry run first:

```bash
python3 tools/sejarah/push_sejarah.py --dry-run
```

## 5. Verification after the push

Per-place counts on the live API matched the source exactly (66 total), and a
one-off script re-read all 66 stored questions and compared `options` and
`accepted_answers` against the JSON: 0 mismatches. Also confirmed the public
`/api/ar3d/questions` payload does **not** include `accepted_answers` — only
the admin endpoint does, and grading happens server-side.

## Adding a new landmark

1. Drop the `.docx` in `docs/sejarahmelakaquestions/`.
2. Add its title to the `PLACES` map in `parse_sejarah.py` with a new code.
3. Run the parser, read the ISSUES list, fix the source doc if a question is
   genuinely wrong.
4. Add the same code to `_placeInfo` in `scanner_screen.dart` so the scanned
   card requests it.
5. Dry-run the push, then push.
