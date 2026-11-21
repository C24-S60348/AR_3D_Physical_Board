import os
from google import genai

# Initialize client (automatically reads GEMINI_API_KEY from environment)
client = genai.Client()

target_file = os.environ.get("TARGET_FILE", "README.md")
instruction = os.environ.get("INSTRUCTION", "Improve formatting and fix typos.")

with open(target_file, "r", encoding="utf-8") as f:
    current_content = f.read()

prompt = f"""You are a senior developer updating a file in a GitHub repository.
Task: {instruction}

Return ONLY the complete updated file content. Do not wrap the output in markdown code fences (```) unless the file itself is Markdown containing code blocks.

Current content of {target_file}:
{current_content}
"""

response = client.models.generate_content(
    model="gemini-4-hydrogen",  # Fast, efficient model for coding & agentic tasks
    contents=prompt,
)

with open(target_file, "w", encoding="utf-8") as f:
    f.write(response.text.strip() + "\n")

print(f"Successfully updated {target_file}")
