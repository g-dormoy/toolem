---
name: team-1on1
description: Prepare a 1:1 brief for one person from the Obsidian vault. Slices that person's Jira, GitHub and Slack activity since the last 1:1 into a readable prep doc with talking points, wins, and things to raise. Use for "1:1 prep", "prep my 1:1 with <name>", "one-on-one for <name>".
---

# 1:1 Prep (per person, on demand)

Produce a focused **1:1 preparation brief** for a single team member from the `vault/` Obsidian database. Reads what `team-ingest` already captured (Daily notes, Project notes, the person's Activity Log) plus a few targeted confirmation queries, scoped to **one person** since your **last 1:1 with them**. Does not re-ingest, does not write a Snapshot, does not touch the weekly report.

## Usage

```
/team-1on1 "Duy Nguyen"
/team-1on1 "Duy Nguyen" --since 2026-06-02
/team-1on1 "Lucas Karmane" --since 2026-06-02 --until 2026-06-16
```

## Parameters

- `<person>` — required: the person's note title (e.g. `"Duy Nguyen"`). Team is inferred from their `vault/People/{person}.md` note.
- `--since YYYY-MM-DD` — start of the window. Default: the date of the most recent prior 1:1 doc for this person in `vault/1on1s/`, else 14 days ago.
- `--until YYYY-MM-DD` — end of the window. Default: today.

## Instructions

Invoke the `team-1on1` agent with this prompt:

```
Prepare a 1:1 brief.

Person: {person}
Parameters: {pass through --since / --until, or "since last 1:1" if none}
Today's date: {current date YYYY-MM-DD}

Follow .claude/agents/team-1on1.md exactly:
1. Read vault/_meta/SCHEMAS.md and vault/People/{Person}.md (infer team, get join keys)
2. Determine the window (last 1:1 → today unless overridden)
3. Read the team's vault/Daily notes in the window + linked Project notes; slice to this person
4. Confirm with targeted Jira/GitHub queries scoped to this person; scan Slack lightly for their threads
5. Write vault/1on1s/{Person} {until}.md (type: oneonone — brief + talking points)
6. Print a summary
```
