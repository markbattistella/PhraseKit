import json
import os
import sys
import jsonschema
from jsonschema import validate
from pathlib import Path
import re
from github import Github

# Define the schema for validation
schema = {
    "type": "object",
    "properties": {
        "pending": {"type": "array", "items": {"type": "string"}},
        "safe": {"type": "array", "items": {"type": "string"}},
        "unsafe": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["pending", "safe", "unsafe"]
}

# Load environment variables
words = os.environ.get("WORDS", "")
pos_list = os.environ.get("POS", "").splitlines()
issue_number = os.environ.get("GITHUB_ISSUE_NUMBER")
repo_name = os.environ.get("GITHUB_REPOSITORY")
token = os.environ.get("GITHUB_TOKEN")

# Convert the words and POS list into usable data
word_list = [word.strip().lower() for word in words.splitlines() if word.strip()]
pos_list = [pos.strip().lower() for pos in pos_list if pos.strip()]

if not word_list or not pos_list:
    print("No valid words or POS provided.")
    sys.exit(1)

# Validate words (must be alpha only)
invalid_words = [word for word in word_list if not re.match(r'^[a-z]+$', word)]
if invalid_words:
    invalid_word_list = ', '.join(invalid_words)
    message = f"The following words are invalid and cannot be processed: {invalid_word_list}. Only alphabetic words are allowed."

    # Post comment to GitHub issue
    g = Github(token)
    repo = g.get_repo(repo_name)
    issue = repo.get_issue(int(issue_number))
    issue.create_comment(message)

    print(message)
    sys.exit(1)

# Paths to the JSON files
base_path = Path("./Sources/PhraseKit/Resources")
file_map = {
    "adjective": base_path / "_adjective.json",
    "adverb": base_path / "_adverb.json",
    "noun": base_path / "_noun.json",
    "verb": base_path / "_verb.json"
}

# Ensure the base directory exists
base_path.mkdir(parents=True, exist_ok=True)

# Function to load or create a JSON file
def load_or_create_json(path):
    if path.exists():
        with open(path, "r") as f:
            data = json.load(f)
    else:
        data = {"pending": [], "safe": [], "unsafe": []}
    return data

# Function to save JSON data
def save_json(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

# Update the appropriate JSON files
for word in word_list:
    for pos in pos_list:
        if pos in file_map:
            json_path = file_map[pos]
            json_data = load_or_create_json(json_path)
            if word not in json_data["pending"] and word not in json_data["safe"] and word not in json_data["unsafe"]:
                json_data["pending"].append(word)
            save_json(json_path, json_data)

print("Words successfully added to the pending list in the appropriate JSON files.")
