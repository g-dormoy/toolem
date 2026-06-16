---
name: team-report
description: Weekly team report for a squad, generated from the Obsidian vault. Aggregates the week's daily notes into a full readable Snapshot with metrics, and updates each person's activity log. Use for "weekly report", "team report", "Friday report".
---

# Team Report (weekly)

Produce the weekly Snapshot for one squad from the `vault/` Obsidian database. Reads the week's daily notes (written by `team-ingest`) plus targeted confirmation queries. Does **not** sync Notion — the vault + Dataview views are the source of truth.

## Usage

```
/team-report backend
/team-report growth --week-ending 2026-06-12
/team-report backend --since 2026-06-06 --until 2026-06-12
```

## Parameters

- `<team>` — required: matches a `vault/Teams/{Team}.md` filename
- `--week-ending YYYY-MM-DD` — last day of the report week (default: today)
- `--since / --until YYYY-MM-DD` — explicit window override

## Instructions

Invoke the vault-based **`team-report`** agent (`subagent_type: team-report`) with the prompt below.

Prompt:

```
Generate the weekly Snapshot.

Team: {team}
Parameters: {pass through --week-ending or --since/--until, or "last 7 days" if none}
Today's date: {current date YYYY-MM-DD}

Follow .claude/agents/team-report.md exactly:
1. Read vault/_meta/SCHEMAS.md and vault/Teams/{Team}.md
2. Read the week's vault/Daily/{Team} *.md notes; aggregate metrics + events
3. Confirm with targeted Jira/GitHub queries; Slack weekly highlights
4. Compute week-on-week delta from the prior Snapshot frontmatter
5. Write vault/Snapshots/{Team} {week_end}.md (full report + metrics frontmatter)
6. Append one weekly line to each active person's People activity log
7. Print a summary
```
