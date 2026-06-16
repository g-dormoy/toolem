#!/bin/zsh
# Daily vault sync for both squads. Invoked by launchd on weekday mornings.
set -euo pipefail
HERE="$(dirname "$0")"

# Edit the team names below to match your vault/Teams/ folder.
"$HERE/run-team-task.sh" "Run the team-ingest skill for the backend squad for today."
"$HERE/run-team-task.sh" "Run the team-ingest skill for the growth squad for today."
