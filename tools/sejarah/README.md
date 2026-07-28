# Sejarah Melaka question bank

Tooling for the 66 landmark questions in `docs/sejarahmelakaquestions/`.

## Parse

```bash
python3 tools/sejarah/parse_sejarah.py
```

Reads the seven `.docx` files and writes `sejarah_questions.json` next to the
script. Answers are matched by option **text**, not by the letter printed in the
source — a few letters in the documents point at the wrong option.

Known source discrepancy: Kota A'Famosa Q5 says `Jawapan: B. Porta de Santiago`
but "Porta de Santiago" is option A. The text match wins, which is the
historically correct answer.

## Push to the API

```bash
python3 tools/sejarah/push_sejarah.py --dry-run
```

Drop `--dry-run` to actually create the questions. The script skips questions
already on the server (matched by place + prompt), so it is safe to re-run.

The admin password comes from `AR3D_ADMIN_PASSWORD`. The script refuses to run
against a server older than `2026.07.28.1`, because the `place` and `options`
columns do not exist there and both fields would be silently dropped.
