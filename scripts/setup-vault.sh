#!/bin/zsh
# setup-vault.sh — scaffold the Obsidian vault for team tracking
# Usage: ./scripts/setup-vault.sh [--team NAME] [--force]
#
#   --team NAME   name the team template file vault/Teams/NAME.md (default: "My Team")
#   --force       proceed even if vault/ is already non-empty (overwrites template files only;
#                 existing Daily/Snapshots/etc. notes are left untouched)
set -euo pipefail

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
FORCE=false
TEAM_NAME="My Team"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)  FORCE=true; shift ;;
    --team)   TEAM_NAME="$2"; shift 2 ;;
    *)        print -u2 "Unknown option: $1"; print -u2 "Usage: $0 [--team NAME] [--force]"; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve paths relative to this script
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT="$(cd "$SCRIPT_DIR/.." && pwd)/vault"
TEMPLATES="$SCRIPT_DIR/vault-templates"

# ---------------------------------------------------------------------------
# Guard: abort if vault already exists and is non-empty
# ---------------------------------------------------------------------------
if [[ -d "$VAULT" ]] && [[ -n "$(ls -A "$VAULT" 2>/dev/null)" ]]; then
  if [[ "$FORCE" == "false" ]]; then
    print -u2 "ERROR: vault/ already exists and is non-empty."
    print -u2 "  Run with --force to overwrite template files, or remove vault/ manually."
    exit 1
  fi
  echo "WARNING: vault/ is non-empty — overwriting template files (--force)."
fi

# ---------------------------------------------------------------------------
# Create directories
# ---------------------------------------------------------------------------
mkdir -p \
  "$VAULT/_meta" \
  "$VAULT/Teams" \
  "$VAULT/People" \
  "$VAULT/Projects" \
  "$VAULT/Daily" \
  "$VAULT/Snapshots" \
  "$VAULT/1on1s" \
  "$VAULT/Observations" \
  "$VAULT/Goals" \
  "$VAULT/.logs" \
  "$VAULT/.obsidian"

# ---------------------------------------------------------------------------
# Copy template files
# ---------------------------------------------------------------------------
cp "$TEMPLATES/_meta/SCHEMAS.md"        "$VAULT/_meta/SCHEMAS.md"
cp "$TEMPLATES/_meta/Views.md"          "$VAULT/_meta/Views.md"
cp "$TEMPLATES/.obsidian/app.json"      "$VAULT/.obsidian/app.json"
cp "$TEMPLATES/README.md"               "$VAULT/README.md"
cp "$TEMPLATES/Teams/My Team.md"        "$VAULT/Teams/${TEAM_NAME}.md"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "vault/ created at $VAULT"
echo ""
echo "Next steps:"
echo "  1. Open vault/ as an Obsidian vault (File → Open folder as vault)"
echo "  2. Install Dataview: Settings → Community plugins → Browse → \"Dataview\""
echo "  3. Edit vault/Teams/${TEAM_NAME}.md — update name: and all placeholders"
echo "  4. Replace \"your-team\" in vault/_meta/Views.md with your team's name: slug"
echo "  5. Add vault/People/<Name>.md for each team member (see _meta/SCHEMAS.md)"
echo "  6. Run /team-ingest <team> from a Claude Code session to populate the first daily note"
