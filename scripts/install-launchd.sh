#!/bin/zsh
# Install launchd jobs for the daily sync and weekly report.
# Run once from any directory — the repo path is resolved automatically.
set -euo pipefail

# Reverse-DNS prefix for launchd labels. Change to match your domain or GitHub handle.
# Convention: com.yourname  or  io.github.yourhandle
LABEL_PREFIX="com.example"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
LAUNCHD_DIR="$HOME/Library/LaunchAgents"
PLIST_DIR="$REPO/scripts/launchd"

mkdir -p "$LAUNCHD_DIR" "$REPO/vault/.logs"

for JOB in team-daily-sync team-weekly-report; do
  LABEL="$LABEL_PREFIX.$JOB"
  DEST="$LAUNCHD_DIR/$LABEL.plist"
  sed -e "s|REPO_PATH|$REPO|g" -e "s|LABEL_PREFIX|$LABEL_PREFIX|g" \
    "$PLIST_DIR/$JOB.plist" > "$DEST"
  launchctl unload "$DEST" 2>/dev/null || true
  launchctl load "$DEST"
  echo "Loaded $LABEL"
done

echo "Done. Logs will appear in $REPO/vault/.logs/"
