---
name: team-ingest
description: Daily vault sync for a squad — pulls the day's Jira, GitHub, Slack, and Fellow meeting notes, refreshes Project notes, and writes a daily metrics note to the Obsidian vault. Use for "daily sync", "ingest today", "update the vault".
---

# Team Ingest (daily)

Keep the `vault/` Obsidian database current for one squad by capturing the day's activity. This does **not** produce the weekly report — use `team-report` for that.

## Usage

```
/team-ingest backend
/team-ingest growth --date 2026-06-15
/team-ingest backend --since 2026-06-08 --until 2026-06-12   # backfill
```

## Parameters

- `<team>` — required: matches a `vault/Teams/{Team}.md` filename
- `--date YYYY-MM-DD` — day to ingest (default: today)
- `--since / --until YYYY-MM-DD` — backfill a range (one daily note per day)

## Instructions

Invoke the `team-ingest` agent with this prompt:

```
Ingest daily vault activity.

Team: {team}
Parameters: {pass through --date or --since/--until, or "today" if none}
Today's date: {current date YYYY-MM-DD}

Follow .claude/agents/team-ingest.md exactly:
1. Read vault/_meta/SCHEMAS.md and vault/Teams/{Team}.md
2. Load People and Projects notes for the team; resolve missing jira_account_id
3. Collect the day's Jira / GitHub / Slack activity and Fellow meeting notes
4. Associate work to people and projects
5. Update matched Project notes and write vault/Daily/{Team} {date}.md (idempotent by date)
6. Print a summary of what changed
```
