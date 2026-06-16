# Scheduling the vault sync (local, launchd)

These run the daily `team-ingest` and weekly `team-report` skills automatically via macOS `launchd`. They are **not active until you load them** (see step 3).

## Files
- `run-team-task.sh` — runs one Claude task headless, logs to `vault/.logs/`.
- `daily-sync.sh` — ingest for each squad (edit team names to match your `vault/Teams/`).
- `weekly-report.sh` — report for each squad (edit team names to match your `vault/Teams/`).
- `install-launchd.sh` — stamps the repo path and your label prefix into the plists and loads them (run once per machine).
- `launchd/team-daily-sync.plist` — template: weekdays 07:30.
- `launchd/team-weekly-report.plist` — template: Fridays 15:00.

## ⚠️ Validate first (the auth caveat)

Your Jira and Slack tools are **claude.ai connectors** — they may not authenticate in a headless run. GitHub (`gh`) works headless. So before trusting the schedule, confirm a headless run can reach all three:

```sh
./scripts/run-team-task.sh "Run the team-ingest skill for the backend squad for today."
```

Then check the newest file in `vault/.logs/` and the written `vault/Daily/{Team} <today>.md`. If Jira/Slack data is present, headless auth works — proceed. If not, keep running the sync manually (same command) or from an interactive Claude session, and don't load the schedule.

## Install (only after validation)

**Before running the install script, set your label prefix.** Open `scripts/install-launchd.sh` and edit the `LABEL_PREFIX` line near the top:

```sh
LABEL_PREFIX="com.yourname"   # reverse-DNS convention: com.yourname or io.github.yourhandle
```

This prefix becomes the launchd job identifier (e.g. `com.yourname.team-daily-sync`). It must be unique on your machine — use something you own. The default `com.example` is a placeholder and should not be left as-is.

Then run:

```sh
./scripts/install-launchd.sh
```

This resolves the repo path, stamps both `REPO_PATH` and `LABEL_PREFIX` into the plists, writes them to `~/Library/LaunchAgents/`, and loads them. Safe to re-run (it unloads before reloading).

Test a job immediately without waiting for the clock:
```sh
launchctl start com.example.team-daily-sync   # use your LABEL_PREFIX
```

## Manage
```sh
launchctl list | grep team-daily-sync                                    # is it registered?
launchctl unload ~/Library/LaunchAgents/com.example.team-daily-sync.plist   # disable (use your LABEL_PREFIX)
```

Notes:
- `launchd` only fires while you're logged in; missed runs (laptop asleep) fire on next wake.
- Adjust times by editing the `StartCalendarInterval` in the plist, then `unload` + `load`.
- Each run consumes Claude usage and hits Jira/GitHub/Slack — that's why nothing auto-loads.
