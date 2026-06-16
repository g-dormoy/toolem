#!/bin/zsh
# Run a single Claude Code task headless for the team-tracking vault.
# Usage: run-team-task.sh "<prompt>"
set -euo pipefail

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE="$(command -v claude)"
LOG_DIR="$PROJECT/vault/.logs"

mkdir -p "$LOG_DIR"
STAMP="$(date +%Y-%m-%dT%H-%M-%S)"
LOG="$LOG_DIR/${STAMP}.log"

cd "$PROJECT"
echo "[$STAMP] >>> $1" | tee -a "$LOG"
# --dangerously-skip-permissions so MCP/Bash tools don't block in headless mode.
"$CLAUDE" -p "$1" --dangerously-skip-permissions >> "$LOG" 2>&1
echo "[$(date +%Y-%m-%dT%H-%M-%S)] <<< done (exit $?)" | tee -a "$LOG"
