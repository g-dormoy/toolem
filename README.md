# Team Tracking — Cowork

AI-powered team intelligence for engineering management. Claude agents pull from Jira, GitHub, and Slack daily, accumulate structured data in an Obsidian vault, and surface it as weekly reports, 1:1 prep docs, and inline attention points.

---

## Prerequisites

### 1. Obsidian (required)

Open the `vault/` folder as an **Obsidian vault**. This is where all data lives — Daily notes, Snapshots, People logs, Project notes.

- Install [Obsidian](https://obsidian.md) (free).
- Open → select the `vault/` folder inside this repo.
- Install the community plugin **Dataview** (Settings → Community plugins → Browse → "Dataview"). It powers the live queries in `vault/_meta/Views.md`.

Without Obsidian + Dataview, the data still accumulates correctly (it's plain Markdown + YAML frontmatter), but you lose the graph view, backlinks, and live dashboards.

### 2. MCP connectors

The agents use these Claude.ai MCP integrations, configured in your Claude Code session:

| Connector | Used for |
|-----------|---------|
| Atlassian | Jira ticket queries |
| Slack | Channel reads (team + problem channels) |
| GitHub CLI (`gh`) | PRs, CI runs (authenticated headlessly) |
| Google Drive | Team-specific metric spreadsheets (optional) |

### 3. Claude Code CLI

All commands below are slash commands run from a Claude Code session opened at this directory.

---

## Configuration

Create one file per squad in `vault/Teams/` — this is the only place you put org-specific values. The agent files are generic and read everything from here at runtime.

| Frontmatter key   | What it is                                           | Example              |
|-------------------|------------------------------------------------------|----------------------|
| `jira_project`    | Your Jira project key                                | `ENG`                |
| `tsd_project`     | Shared support-desk project key (optional)           | `HELP`               |
| `tsd_squad_field` | Jira custom field that routes support-desk tickets   | `squad`              |
| `tsd_squads`      | Your squad's values in that field                    | `[Backend]`          |
| `github_org`      | GitHub organisation                                  | `my-org`             |
| `repos`           | GitHub repos this squad owns                         | `["my-org/my-repo"]` |
| `slack.team`      | Primary team channel                                 | `"#squad-backend"`   |
| `slack.problem`   | Problem / metric channel                             | `"#problem-revenue"` |
| `people`          | Roster — wikilinks to `vault/People/` notes          | `[[Alice Smith]]`    |

See `vault/_meta/SCHEMAS.md` for the full schema, including the `vault/People/` note format.

---

## How it works

The vault is a **living database of entities** — People, Projects, Teams — not a folder of documents. Two scheduled processes keep it current; a third reads it on demand.

```
Every weekday (or on demand)     →  /team-ingest <team>
Every Friday afternoon           →  /team-report <team>
Before a 1:1 (on demand)        →  /team-1on1 "<person>"
Whenever you notice something    →  /note <team> <observation>
```

Data flows one way: **Jira / GitHub / Slack → vault → reports**. Nothing is ever written back to those sources.

---

## Vault structure

| Folder | What it contains | Written by |
|--------|-----------------|------------|
| `vault/Teams/` | One config note per squad (Jira keys, channels, repos, roster) | You (rarely) |
| `vault/People/` | One note per developer / PM, with a rolling weekly activity log | `team-report` (weekly) |
| `vault/Projects/` | One note per epic / workstream — status, risks, open questions | `team-ingest` (daily) |
| `vault/Daily/` | One note per team per day — events + metrics | `team-ingest` (daily) |
| `vault/Snapshots/` | One note per team per week — full readable report + weekly metrics | `team-report` (weekly) |
| `vault/1on1s/` | One brief per person per 1:1 | `team-1on1` (on demand) |
| `vault/Observations/` | Manager attention points, auto-closed by next weekly report | `/note` (you) |
| `vault/_meta/` | Schema contract (`SCHEMAS.md`) and Dataview query templates | You |

---

## Commands

### `/team-ingest` — daily vault sync

Pulls today's Jira, GitHub, and Slack activity for a squad. Refreshes Project notes and writes one `vault/Daily/{Team} {date}.md` note. Idempotent — re-running the same date overwrites that day's note without creating duplicates.

```
/team-ingest backend
/team-ingest growth
/team-ingest backend --date 2026-06-15          # specific day
/team-ingest backend --since 2026-06-08 --until 2026-06-12   # backfill a range
```

**What it does:**
- Queries all Jira tickets that changed today — the team's Jira project and, if configured, a shared support desk (`tsd_project`) filtered by squad
- Fetches PRs opened and merged today across team repos via `gh`
- Scans team Slack channels lightly for blockers, decisions, and open questions (not a full summary)
- Maps every ticket and PR to the right person and project
- Computes cycle time (In Progress → Done, business days) for any tickets completed today
- Updates matched Project notes (status, risks, activity log line)
- Writes the Daily note with metrics frontmatter (for Dataview) and a `## Needs Classification` section for unmatched work

**Does not** write the weekly report. **Does not** touch People notes.

---

### `/team-report` — weekly snapshot (run Friday afternoon)

Aggregates the week's Daily notes into a full readable Snapshot and updates each person's activity log. This is the authoritative weekly report — it also recomputes lead-time metrics directly from Jira changelogs rather than trusting the daily approximations.

```
/team-report backend
/team-report growth
/team-report backend --week-ending 2026-06-12   # specific week
/team-report backend --since 2026-06-06 --until 2026-06-12
```

**What it produces (`vault/Snapshots/{Team} {week_end}.md`):**
- Executive summary (5 bullets, 30-second read)
- Jira: status breakdown, new/completed tickets, velocity trend (week-on-week), blockers
- Lead time & bottlenecks: median + p85 cycle time (business days), per-status dwell breakdown, WoW trend
- GitHub: open PRs (with age + review status), merged PRs, PR turnaround averages, CI failures
- Slack: key discussions and unresolved threads per channel
- Project status summaries with links
- Manager Attention Points (from any open `/note` observations — auto-closed after pickup)
- Recommendations

**Also updates** each active person's `vault/People/{Name}.md` activity log with one weekly line.

**Idempotent** — re-running the same week overwrites that Snapshot.

---

### `/team-1on1` — 1:1 preparation brief (on demand)

Produces a focused brief for one person scoped to the period **since your last 1:1 with them**. Reads the vault (Daily notes, the person's activity log, their Projects) and confirms with targeted Jira/GitHub queries.

```
/team-1on1 "Alice Smith"
/team-1on1 "Alice Smith" --since 2026-06-02
/team-1on1 "Alice Smith" --since 2026-06-02 --until 2026-06-16
```

The window defaults to: date of the most recent prior `vault/1on1s/{Person} *.md` → today. If no prior brief exists, it defaults to 14 days back.

**What it produces (`vault/1on1s/{Person} {date}.md`):**
- Summary: the shape of their period (what they shipped, where they got stuck)
- Wins & Highlights — concrete things to acknowledge, with PR/ticket links
- Talking Points / To Raise — specific and actionable (a stale PR, a blocked ticket, a decision pending)
- Their Jira tickets with status + movement
- Their personal lead time (cycle time in business days, WoW trend vs last 1:1)
- Their PRs: merged + open (flags stale open PRs)
- Slack threads they drove or that await them
- Follow-ups from the last 1:1 checked against this period's activity

**Does not** re-ingest, does not write Snapshots, does not modify People/Project/Daily notes.

---

### `/note` — add an observation

Flag something for the next weekly report or 1:1 prep. The observation lands in `vault/Observations/` with `status: open` and is automatically picked up (and closed) when `team-report` next runs for that team.

```
/note backend GMV is up 12% WoW — looks like the new campaign is driving it
/note growth Alice flagged a webhook retry storm — needs watching, linked to Payment Webhook Handling
/note backend velocity blockers pile-up, 3 tickets stuck in Tech Review >5 days
```

Parameters inferred from natural language: team, observation text, any project names (auto-linked as `[[wikilinks]]`), optional metric tag (gmv, prs, blockers, velocity).

---

## Automation (optional — macOS launchd)

The `scripts/` folder contains shell scripts and launchd plists to run the daily ingest and weekly report automatically.

| Script | Schedule | What it does |
|--------|----------|-------------|
| `daily-sync.sh` | Weekdays 07:30 | `team-ingest` for each squad (edit the script for your team names) |
| `weekly-report.sh` | Fridays 15:00 | `team-report` for each squad (edit the script for your team names) |

**Before enabling automation**, validate that headless Claude can reach Jira and Slack (the connectors are claude.ai-based and may require an interactive session):

```sh
./scripts/run-team-task.sh "Run the team-ingest skill for the backend squad for today."
```

Check `vault/.logs/` and `vault/Daily/{Team} <today>.md`. If Jira and Slack data is present, headless auth works. Then install:

```sh
./scripts/install-launchd.sh
```

See `scripts/README.md` for full details.

---

## Typical weekly flow

```
Mon–Thu    /team-ingest backend     # keep the vault fresh each day
Mon–Thu    /team-ingest growth

Friday PM  /team-report backend     # weekly Snapshot + People logs
Friday PM  /team-report growth

Anytime    /note <team> <observation>          # flag something for the report
Before 1:1 /team-1on1 "<name>"               # prep a specific 1:1
```

If you missed a day, backfill it before running the weekly report:

```
/team-ingest backend --since 2026-06-09 --until 2026-06-12
```
