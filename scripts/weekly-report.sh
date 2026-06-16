#!/bin/zsh
# Weekly Snapshot report for both squads. Invoked by launchd on Friday afternoons.
set -euo pipefail
HERE="$(dirname "$0")"

# Edit the team names below to match your vault/Teams/ folder.
"$HERE/run-team-task.sh" "Run the team-report skill for the backend squad for the last 7 days."
"$HERE/run-team-task.sh" "Run the team-report skill for the growth squad for the last 7 days."
