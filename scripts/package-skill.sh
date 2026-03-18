#!/usr/bin/env bash
# package-skill.sh — sync repo contents into skill/agent-memory-setup and package a .skill artifact
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$REPO_ROOT/skill/agent-memory-setup"
DIST_DIR="${1:-$REPO_ROOT/dist}"
PACKAGE_SCRIPT="/opt/homebrew/lib/node_modules/openclaw/skills/skill-creator/scripts/package_skill.py"

mkdir -p "$DIST_DIR" "$SKILL_DIR"

# Reset generated subtrees but keep SKILL.md as the authored entrypoint.
rm -rf "$SKILL_DIR/templates" "$SKILL_DIR/programs" "$SKILL_DIR/references" "$SKILL_DIR/examples" "$SKILL_DIR/assets"
mkdir -p "$SKILL_DIR/scripts" "$SKILL_DIR/references"
find "$SKILL_DIR/scripts" -mindepth 1 -maxdepth 1 -type f ! -name 'setup.sh' -delete 2>/dev/null || true

# Sync current repo resources into the skill.
cp -R "$REPO_ROOT/templates" "$SKILL_DIR/templates"
cp -R "$REPO_ROOT/programs" "$SKILL_DIR/programs"
cp -R "$REPO_ROOT/examples" "$SKILL_DIR/examples"
cp "$REPO_ROOT/references/write-discipline.md" "$SKILL_DIR/references/write-discipline.md"
cp "$REPO_ROOT/references/learnings-examples.md" "$SKILL_DIR/references/learnings-examples.md"
cp "$REPO_ROOT/references/ground-truth-guide.md" "$SKILL_DIR/references/ground-truth-guide.md"
cp "$REPO_ROOT/references/program-md-guide.md" "$SKILL_DIR/references/program-md-guide.md"
cp "$REPO_ROOT/references/shared-drive-multi-agent-design.md" "$SKILL_DIR/references/shared-drive-multi-agent-design.md"
cp "$REPO_ROOT/scripts/setup.sh" "$SKILL_DIR/scripts/setup.sh"
cp "$REPO_ROOT/scripts/consolidate.sh" "$SKILL_DIR/scripts/consolidate.sh"
cp "$REPO_ROOT/scripts/eval.sh" "$SKILL_DIR/scripts/eval.sh"
cp "$REPO_ROOT/scripts/prune.sh" "$SKILL_DIR/scripts/prune.sh"
chmod +x "$SKILL_DIR/scripts/setup.sh" "$SKILL_DIR/scripts/consolidate.sh" "$SKILL_DIR/scripts/eval.sh" "$SKILL_DIR/scripts/prune.sh"

# Validate + package
python3 "$PACKAGE_SCRIPT" "$SKILL_DIR" "$DIST_DIR"

echo ""
echo "Skill packaged successfully."
echo "Directory: $SKILL_DIR"
echo "Artifact:  $DIST_DIR/agent-memory-setup.skill"
