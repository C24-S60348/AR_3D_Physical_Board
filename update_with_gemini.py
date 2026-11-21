import os
from pathlib import Path
from pydantic import BaseModel, Field
from google import genai
from google.genai import types

# 1. Define the structured output schema so Gemini returns clean file edits
class FileChange(BaseModel):
    file_path: str = Field(description="Relative path of the file to update or create")
    content: str = Field(description="Complete updated content of the file")

class RepoUpdate(BaseModel):
    commit_summary: str = Field(description="Short git commit message summarizing all changes")
    files: list[FileChange] = Field(description="List of files modified or created")

# 2. Collect relevant files from the repo (skipping hidden folders, dependencies, and large files)
IGNORE_DIRS = {".git", ".github", "node_modules", "venv", ".venv", "__pycache__", "build", "dist"}
ALLOWED_EXTS = {".py", ".js", ".ts", ".jsx", ".tsx", ".dart", ".html", ".css", ".md", ".json", ".yaml", ".yml", ".sql", ".sh"}

def gather_repo_files(target_paths: str) -> str:
    collected = []
    # If user specified specific paths (comma-separated), read those; otherwise scan whole repo
    roots = [Path(p.strip()) for p in target_paths.split(",") if p.strip()] if target_paths.strip() != "ALL" else [Path(".")]

    for root in roots:
        paths = [root] if root.is_file() else root.rglob("*")
        for path in paths:
            if not path.is_file():
                continue
            if any(part in IGNORE_DIRS for part in path.parts):
                continue
            if path.suffix.lower() not in ALLOWED_EXTS or path.stat().st_size > 100_000:
                continue
            try:
                text = path.read_text(encoding="utf-8")
                collected.append(f"--- FILE: {path.as_posix()} ---\n{text}\n")
            except UnicodeDecodeError:
                continue

    return "\n".join(collected)

# 3. Run Gemini with Structured Outputs
client = genai.Client()
target_paths = os.environ.get("TARGET_PATHS", "ALL")
instruction = os.environ.get("INSTRUCTION", "Review and improve code quality.")

repo_context = gather_repo_files(target_paths)

prompt = f"""You are a senior software engineer updating a GitHub repository.
User Instruction: {instruction}

Analyze the repository files below and return ONLY the files that need to be modified or newly created to fulfill the instruction. Include the COMPLETE content for each returned file.

Repository Files:
{repo_context}
"""

response = client.models.generate_content(
    model="gemini-3.8-flash",  # Great balance of speed, 1M context, and free-tier availability
    contents=prompt,
    config=types.GenerateContentConfig(
        response_mime_type="application/json",
        response_schema=RepoUpdate,
        temperature=0.2,
    ),
)

result = RepoUpdate.model_validate_json(response.text)

# 4. Write updated/new files to disk
for item in result.files:
    file_path = Path(item.file_path)
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(item.content.rstrip() + "\n", encoding="utf-8")
    print(f"Updated: {item.file_path}")

# Save commit message for GitHub Actions to use
Path(".gemini_commit_msg").write_text(result.commit_summary, encoding="utf-8")
print(f"Done. Summary: {result.commit_summary}")
