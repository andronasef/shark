#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:-}"
MODE="${2:-}"

if [[ -z "$VERSION" ]]; then
    echo "Usage: $0 <version> [--user-only|--github]" >&2
    exit 1
fi

python3 - "$VERSION" "$MODE" << 'PYEOF'
import sys
import re

raw_version = sys.argv[1].strip()
mode = sys.argv[2].strip() if len(sys.argv) > 2 else ""

# Normalize versions (strip leading 'v')
version = raw_version.lstrip("v").lstrip("V")

try:
    with open("CHANGELOG.md", "r", encoding="utf-8") as f:
        content = f.read()
except Exception as e:
    print(f"Error reading CHANGELOG.md: {e}", file=sys.stderr)
    sys.exit(1)

# Find release header: ## [version] ...
pattern = re.compile(rf"^##\s*\[{re.escape(version)}\].*?$", re.MULTILINE)
match = pattern.search(content)

# If not found directly, check for alpha mapping (e.g. 1.0.4 -> 1.0.0-alpha.4)
if not match:
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)$", version)
    if m:
        alpha_candidate = f"{m.group(1)}.{m.group(2)}.0-alpha.{m.group(3)}"
        pattern = re.compile(rf"^##\s*\[{re.escape(alpha_candidate)}\].*?$", re.MULTILINE)
        match = pattern.search(content)

if not match:
    print(f"Warning: Version [{version}] not found in CHANGELOG.md", file=sys.stderr)
    sys.exit(0)

start_pos = match.end()
# Find end of this version's section (next ## [ heading or EOF)
next_match = re.search(r"^##\s*\[", content[start_pos:], re.MULTILINE)
if next_match:
    section = content[start_pos : start_pos + next_match.start()]
else:
    # Also check if there is a '---' separator before legacy versions
    sep_match = re.search(r"^---\s*$", content[start_pos:], re.MULTILINE)
    if sep_match:
        section = content[start_pos : start_pos + sep_match.start()]
    else:
        section = content[start_pos:]

section = section.strip()

# Extract User Changelog
user_match = re.search(r"^###\s*User Changelog\s*\n(.*?)(?=^###|\Z)", section, re.MULTILINE | re.DOTALL)
user_changelog = user_match.group(1).strip() if user_match else ""

if mode == "--user-only":
    # App Store "What's New": pure user changelog bullet points
    if user_changelog:
        print(user_changelog)
    else:
        print(section)
elif mode == "--github":
    # GitHub release notes: user changelog at top, followed by technical changelog
    output = []
    if user_changelog:
        output.append("### What's New")
        output.append(user_changelog)
        output.append("")
    # Remaining technical sections (Added, Changed, Fixed)
    tech_section = re.sub(r"^###\s*User Changelog\s*\n.*?(?=^###|\Z)", "", section, flags=re.MULTILINE | re.DOTALL).strip()
    if tech_section:
        output.append("### Technical Changes")
        output.append(tech_section)
    print("\n".join(output))
else:
    # Default: the full release section
    print(section)
PYEOF
