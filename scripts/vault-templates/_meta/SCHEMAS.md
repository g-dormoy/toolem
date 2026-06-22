---
type: meta
---
# Entity Schemas — the data contract

This note defines the frontmatter contract for every entity type in the vault. The **ingest agent** and **report agent** both treat this as the source of truth. Change a schema here first, then update the agents.

---

## Quick-start — what to configure

Three things to set in your Team note (`vault/Teams/`) before running `/team-ingest`:

| What | Field in your Team note | Default |
|------|------------------------|---------|
| Your Jira "work started" status | `workflow.active_start` | `In Progress` |
| Your Jira "done" status | `workflow.done` | `Done` |
| Statuses to skip in bottleneck view | `workflow.exclude_dwell` | `[Done]` |

If your Jira workflow uses the default status names (`In Progress`, `Done`), you can omit the `workflow:` block entirely — the agents use those as defaults.

> **Agent contract — do not rename these:**
> - All field names (`type`, `name`, `team`, `status`, `merged_prs`, `cycle_bd_median`, …)
> - All `type:` values: `team`, `person`, `project`, `daily`, `snapshot`, `oneonone`, `observation`, `goal`, `decision`
> - All project `status:` values: `planned`, `in-progress`, `blocked`, `shipped`, `dropped`, `unknown`
> - All goal `status:` values: `planned`, `on-track`, `at-risk`, `met`, `partial`, `missed`, `dropped`
> - Vault folder names (`Teams/`, `People/`, `Daily/`, `Snapshots/`, `Goals/`, …)
>
> The agents read these field names and values literally. Changing them breaks ingestion and reporting silently.

---

## Cadence model

Two processes **write** to the vault, and one **reads** it on demand:

- **`team-ingest` (daily)** keeps entities current. It refreshes `project` notes and writes one `daily` note per team per day. Fast, no narrative.
- **`team-report` (weekly, Friday PM)** reads the week's `daily` notes, writes the `snapshot` (readable weekly report + metrics), and appends one weekly line to each `person`'s activity log.
- **`team-1on1` (on demand)** reads the vault — it does not ingest. It slices one `person`'s activity since the last 1:1 and writes a `oneonone` brief. It is the only consumer that produces a per-person artifact; it never modifies `daily`/`snapshot`/`person`/`project` notes.

So: `daily` = day-granular event log + metrics (written daily). `snapshot` = weekly report + metrics (written Friday). `oneonone` = per-person brief (written on demand). `person` logs are weekly-grained; `project` notes are kept fresh daily.

Conventions:
- `type` is required on every note and drives all Dataview queries.
- Dates are ISO `YYYY-MM-DD`. Never store relative dates ("next week") — resolve them.
- Link fields hold `[[Wikilinks]]` to other notes (by title).
- Unknown values: omit the key rather than writing `null`/`TBD`.

---

## `type: team`

One per squad. Maintained by hand; rarely changes.

```yaml
---
type: team
name: your-team                # lowercase slug — used in filenames and Dataview queries
jira_project: ENG              # main Jira project key
tsd_project:                   # optional: shared support-desk project key
tsd_squad_field: squad         # optional: Jira custom field that routes TSD tickets
tsd_squads: [YourSquad]        # optional: your squad's values in that field
github_org: your-org
repos:
  - your-org/your-repo
slack:
  team: "#sqd-yourteam"
  problem: "#problem-yourmetric"
  other: ["#optional-extra-channel"]
people: ["[[Person One]]", "[[Person Two]]"]   # roster
# --- optional: Fellow meeting discovery (title patterns; defaults to team `name` if omitted) ---
fellow:
  meeting_titles: ["YourTeam DSM", "YourTeam"]   # patterns matched against Fellow meeting titles
# --- optional: lead-time workflow tuning (defaults apply if omitted) ---
workflow:
  active_start: [In Progress]    # ← CONFIGURE: your Jira "work started" status
  done: [Done]                   # ← CONFIGURE: your Jira "done" status
  exclude_dwell: [Done]          # ← CONFIGURE: statuses to omit from bottleneck breakdown
---
```

The `workflow` block tunes the lead-time model (see **Lead time & cycle time** below). If omitted: `active_start` defaults to the first transition into a status named "In Progress" (else the first `statusCategory: indeterminate`), `done` to any `statusCategory: done`.

The optional `fellow.meeting_titles` block lists the title patterns `team-ingest` uses to find this squad's meetings in Fellow (e.g. the recurring standup title plus the squad name). Fellow has no per-squad channels, so discovery is by title + date; if omitted, ingest falls back to searching by the team `name`.

---

## `type: person`

One per developer or product member. Body holds a rolling, dated activity log.

```yaml
---
type: person
name: Person One
team: your-team
role: developer                # developer | product
position: Developer            # free text (e.g. "Product Manager")
github: person-one-github      # required — JOIN KEY for PR attribution
email: person.one@company.com  # required — JOIN KEY for Jira / Slack
jira_account_id:               # required once — resolve via lookupJiraAccountId
aliases: [PersonOne]           # helps wikilink + mention resolution
active: true
---
## Activity Log
- YYYY-MM-DD — weekly summary line, auto-appended by team-report [[Snapshots/Your Team YYYY-MM-DD]]
```

The **weekly** `team-report` appends to `## Activity Log` (most recent first), one line per week per person, prefixed with the week-ending date. Re-running a week **replaces** the line with that date rather than adding a duplicate. Prior lines are never rewritten. The daily `team-ingest` does **not** touch person notes.

---

## `type: project`

One per epic / workstream. The unit you associate work to. Status carries forward between runs.

```yaml
---
type: project
name: Your Project
team: your-team
status: in-progress            # planned | in-progress | blocked | shipped | dropped | unknown
owner: "[[Person One]]"        # optional
people: ["[[Person One]]"]     # contributors
jira_keys: [ENG-001, ENG-002]  # JOIN KEY — tickets rolling up to this project
eta: YYYY-MM-DD                # absolute date or week, optional
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [your-tag]
---
## Summary
One paragraph: what this is and why it matters.

## Activity Log
- YYYY-MM-DD — first activity line, auto-appended by team-ingest.

## Open Questions
- [ ] ...

## Risks / Blockers
- ...

## Links
- Jira epic, key Slack threads, dashboards.
```

`status`, `eta`, `updated`, and the section bodies are refreshed by ingest; `## Activity Log` is appended to.

---

## `type: daily`

One per team per day, written by `team-ingest`. A lightweight day-granular event log + metrics. **This is the fine-grained time series** the weekly report aggregates from.

```yaml
---
type: daily
team: your-team
date: YYYY-MM-DD
# --- metrics (numbers only, for Dataview) ---
merged_prs: 3
opened_prs: 2
tickets_moved: 4        # tickets that changed status today
tickets_done: 2
ci_failures: 0
# --- lead time (business days, In Progress → Done; see "Lead time & cycle time") ---
completed_measurable: 2   # of tickets_done, how many entered In Progress (have a cycle time)
cycle_bd_median: 3.4      # median In Progress→Done of today's completions (noisy at small N — for the day log only; weekly report recomputes authoritatively)
# --- focus (on-goal / reactive / drift split of today's completed deliverables; see "Focus model") ---
on_goal_done: 1           # deliverables completed today that served an open weekly goal
reactive_done: 1          # off-goal but legitimate-unplanned (support desk / Bug / hotfix)
drift_done: 0             # off-goal and not reactive — the defocus signal
# --- entity links (who/what moved today) ---
people: ["[[Person One]]"]
projects: ["[[Your Project]]"]
goals: ["[[Goals/Your Team YYYY-MM-DD short-title]]"]   # open goals today's work touched (omit if none)
---
## Events
- [[Person One]] merged [#101](url) — brief description → [[Your Project]]
- [ENG-001](url) moved In Progress → Done ([[Person One]]) → [[Your Project]]
- [ENG-050](url) hot-fix shipped ([[Person One]]) → [[Your Project]] · reactive
- [ENG-051](url) moved → Done ([[Person One]]) — off-roadmap cleanup · drift

## Lead Time — tickets completed today
One row per ticket that reached Done today. `Kind` = deliverable (Story/Task/Bug) or subtask. `Cycle` = In Progress→Done in business days. `Breakdown` = business-days per status the ticket sat in (bottleneck-spotting). "—" cycle = never entered In Progress.

| Ticket | Kind | Assignee | Cycle (bd) | Per-status breakdown (bd) |
|--------|------|----------|-----------|---------------------------|
| [ENG-001](url) | deliverable | [[Person One]] | 3.4 | To Do 0.5 · In Progress 1.8 · Tech Review 1.1 |
| [ENG-002](url) | subtask | [[Person One]] | 1.2 | In Progress 1.2 |

## Meeting Notes
_Omit this section entirely if no Fellow meetings were found for today. Findings are sourced from Fellow (summaries / decisions / action items) and normalised to English._

### Daily standup — YYYY-MM-DD — [Fellow](https://fellow.link/…)
- Attendees: [[Person One]], [[Person Two]]
- **Decisions:** …
- **Blockers / risks:** …
- **Action items:** [[Person One]] to do X by YYYY-MM-DD
- **Open questions:** …

## Needs Classification
- [ENG-099](url) — new ticket, no matching project. (assignee)
```

Filename: `Daily/{Team} {date}.md` (e.g. `Daily/Your Team YYYY-MM-DD.md`). **Idempotent by date** — re-running a day overwrites that note. Work that matches no project is listed under `## Needs Classification` for you to triage (ingest never auto-creates projects). The `## Lead Time` table is the per-ticket audit trail; the **weekly report and 1:1 recompute lead-time aggregates directly from changelogs** for the window (medians of a week are not averages of daily medians), so they never depend on parsing this table.

In `## Events`, completed work that is **off-goal** carries a trailing focus tag — `· reactive` or `· drift` per the **Focus model** below; on-goal lines are left untagged. The `on_goal_done` / `reactive_done` / `drift_done` counts are the day's audit trail; the weekly report recomputes the authoritative figures from the completed-this-week set.

---

## `type: snapshot`

One per **weekly** report run, per team, written by `team-report` on Fridays. **This is the weekly metrics time series** — Dataview reads the frontmatter to build velocity/throughput trends.

```yaml
---
type: snapshot
team: your-team
period_start: YYYY-MM-DD
period_end: YYYY-MM-DD
generated: YYYY-MM-DD
# --- metrics (numbers only, for Dataview) ---
merged_prs: 14
open_prs: 3
completed_tickets: 9
new_tickets: 5
avg_review_hours: 11
avg_merge_hours: 34
ci_failures: 1
open_blockers: 2
# --- lead time (business days, In Progress → Done; medians of tickets COMPLETED this week) ---
cycle_bd_median: 4.2          # all completed tickets (deliverables + subtasks)
cycle_bd_p85: 9.1             # 85th percentile — watch the tail
cycle_bd_median_deliverable: 6.5   # Story / Task / Bug only
cycle_bd_p85_deliverable: 12.0
cycle_bd_median_subtask: 2.1       # Sub-task only
cycle_bd_p85_subtask: 5.0
completed_measurable: 12      # tickets with a measurable cycle (entered In Progress)
# --- focus (share of completed deliverables that served the week's goals; see "Focus model") ---
focus_pct: 71                 # on-goal deliverables / all completed deliverables, whole percent
on_goal_done: 10              # completed deliverables that served an open goal
reactive_done: 3              # off-goal but legitimate-unplanned (support / Bug / hotfix)
drift_done: 1                 # off-goal and not reactive
drift_bd: 2.4                 # business-days of cycle time spent on drift items
# --- entity links ---
people: ["[[Person One]]"]
projects: ["[[Your Project]]"]
goals: ["[[Goals/Your Team YYYY-MM-DD short-title]]"]   # goals scored this week (omit if none set)
---
# Your Team — week ending YYYY-MM-DD

## Executive Summary
...

## Jira / GitHub / Slack sections
...
```

Filename: `Snapshots/{Team} {period_end}.md` (e.g. `Snapshots/Your Team YYYY-MM-DD.md`).

The lead-time KPIs (`cycle_bd_*`) are the chartable trend line. The **per-status bottleneck breakdown** (where the time actually goes) lives in the report body as a table, not in frontmatter, because status names are team-specific — see the `team-report` `## Lead Time & Bottlenecks` section.

---

## `type: oneonone`

One per 1:1, per person, written **on demand** by `team-1on1` before a manager's 1:1. A focused, decision-oriented brief slicing one person's activity since the last 1:1. Read-only over the rest of the vault — it never re-ingests or writes Snapshot/People/Project notes.

```yaml
---
type: oneonone
person: "[[Person One]]"
team: your-team
period_start: YYYY-MM-DD      # since last 1:1 (or override)
period_end: YYYY-MM-DD        # the 1:1 date
generated: YYYY-MM-DD
# --- lead time (business days; this person's tickets completed in the window) ---
cycle_bd_median: 3.1
cycle_bd_p85: 7.0
completed_measurable: 5
projects: ["[[Your Project]]"]
---
# 1:1 Prep — Person One — YYYY-MM-DD to YYYY-MM-DD

## Summary
## Wins & Highlights
## Talking Points / To Raise
## Jira — Their Tickets
## Lead Time — Their Throughput   (median cycle, trend vs last 1:1, slowest statuses)
## GitHub — Their PRs
## Slack & Collaboration
## Projects
## Follow-ups from last 1:1
```

Filename: `1on1s/{Person} {period_end}.md` (e.g. `1on1s/Person One YYYY-MM-DD.md`). **Idempotent by `period_end`** — re-running the same 1:1 date overwrites that brief; a different date makes a new one. Default window start = the latest prior `1on1s/{Person} *.md` date (else 14 days back).

---

## `type: observation`

A manager-authored attention point, flagged for surfacing in the next weekly report or 1:1 prep. Created via `/note`; closed automatically by `team-report`.

```yaml
---
type: observation
team: your-team
date: YYYY-MM-DD
status: open               # open | picked_up
projects: ["[[Your Project]]"]   # optional wikilinks
metric: gmv                # optional tag (gmv | prs | blockers | velocity | …)
picked_up_by:              # set by team-report: "Snapshots/Your Team YYYY-MM-DD"
---
## Note
One paragraph describing the observation.

## Data
| Date | Metric |
|------|--------|
| … | … |
```

Filename: `Observations/{date}-{team}-{slug}.md` (e.g. `Observations/YYYY-MM-DD-your-team-short-title.md`).

`team-report` globs all `status: open` observations for the team, includes them under `## Manager Attention Points` in the Snapshot, then sets `status: picked_up` and `picked_up_by: Snapshots/{Team} {week_end}`.

---

## `type: goal`

A **weekly team goal** — the intent the EM sets at the start of the week, scored at the end. Created by hand (via `/goal`) on Monday; **closed by `team-report` on Friday** (`status` → `met`/`partial`/`missed`, `outcome` and `scored_by` set). Same create-by-hand / close-by-report lifecycle as `observation`, bookended to the week.

```yaml
---
type: goal
team: your-team
week_start: YYYY-MM-DD        # Monday of the goal week
week_ending: YYYY-MM-DD       # Friday — JOIN KEY to that week's Snapshot
title: Ship the X feature
rank: 1                       # priority order; 1 = top
projects: ["[[Your Project]]"]   # the work that serves this goal (defines the on-goal set)
jira_keys: [ENG-001]             # optional — flag specific tickets beyond the projects
success: "What 'done' looks like for this goal"
status: planned               # planned | on-track | at-risk | met | partial | missed | dropped
outcome:                      # one line, set by team-report on Friday
scored_by:                    # set by team-report: "Snapshots/Your Team YYYY-MM-DD"
---
## Why
One or two lines: why this is the priority this week.

## Notes
Optional running notes. The EM may set `status: at-risk` by hand mid-week.
```

Filename: `Goals/{Team} {week_ending} {slug}.md` (e.g. `Goals/Your Team YYYY-MM-DD ship-the-x-feature.md`). **Idempotent by filename** — re-running `/goal` for the same title + week overwrites that goal.

`week_ending` is the join key: `team-report` for the week ending W loads every goal whose `week_ending == W`. A goal is **open** for that week when its `status` is not terminal (`met`/`partial`/`missed`/`dropped`). `team-report` globs open goals for its week (as it does observations), scores each against the week's delivery, includes them under `## Weekly Goals & Focus`, then closes them. `team-ingest` reads open goals to tag daily work but **never** writes goal notes.

---

## Focus model — on-goal / reactive / drift

The one shared contract for "is the team focused on the week's goals?" `team-ingest` (daily tagging) and `team-report` (weekly scoring) classify completed work the same way, against the week's **open `goal` notes** (see `type: goal`).

**Build the on-goal set** from the union of every open goal's `projects` (wikilinks) and `jira_keys`. Then each completed **deliverable** is exactly one of:

- **on-goal** — its matched project is in the on-goal project set, **or** its key is in a goal's `jira_keys`.
- **reactive** — *not* on-goal, **and** legitimate-unplanned: it came from the support desk (`tsd_project`), **or** its `issuetype` is `Bug`, **or** it carries a hotfix/incident label. Expected baseline firefighting, not a focus failure.
- **drift** — *not* on-goal **and** *not* reactive. The real defocus signal: work that was neither planned nor forced.

**Precedence is on-goal > reactive > drift.** A Bug or support ticket whose project is goal-linked is **on-goal**, not reactive — goal membership always wins.

**The unit** is the **deliverable** — the same Story/Task/Bug lens as the lead-time model (subtasks and Epics excluded). Classify the deliverables **completed in the window** (`status changed to Done DURING (since, until)`), the same set the lead-time model uses.

**The metrics:**
- `focus_pct` = on-goal deliverables ÷ all completed deliverables, as a whole-number percent. With fewer than ~4 completed deliverables, report the raw counts and mark "small sample".
- Report each bucket **count** (`on_goal_done` / `reactive_done` / `drift_done`) and a **bd-weighted** view using each ticket's `cycle_bd`: `drift_bd` = total business-days of cycle time spent on drift items.

**Trend.** `team-report` diffs the window's `focus_pct` against the prior `Snapshot`'s (↑ = more on-goal = improvement). If no prior, say "baseline".

**Daily vs weekly.** `team-ingest` tags each day's completions and stores per-bucket counts in the `daily` note for the audit trail; `team-report` recomputes the authoritative weekly figures directly from the completed-this-week set — never by summing daily counts — exactly as it does for lead time.

---

## Lead time & cycle time — the time-in-status model

The one shared contract for every lead-time number in the vault. `team-ingest`, `team-report`, and `team-1on1` all compute it the same way, from a ticket's **status changelog**. Get the changelog with `getJiraIssue(issueIdOrKey, expand="changelog", fields=["status","created","issuetype","assignee","parent"])`; each `histories[]` entry has a `created` timestamp and `items[]` where `field == "status"` carries `fromString` → `toString`.

**Build the status timeline.** From `created` (the issue's creation time, the start of its first status) plus every `field=status` transition in time order, derive a list of `(status, entered_at, left_at)` intervals. Ignore no-op transitions where `fromString == toString` (automation re-stamps, e.g. Done→Done). A ticket may enter the same status more than once (bounce-backs) — keep every interval.

**The two anchor points:**
- **Cycle start** = the **first** time the ticket enters a status in the team's `workflow.active_start` (default: a status named `In Progress`; fallback: the first transition into `statusCategory: indeterminate`). This is the "In Progress" the EM means.
- **Done** = the **last** transition into a `workflow.done` status (or any `statusCategory: done`). Using the last one handles reopen→redo.
- **Cycle time** = business time from cycle start to Done. If the ticket reached Done **without ever** entering `active_start` (e.g. created→Done, or only sat in To Do), it has **no cycle time** — exclude it from cycle medians, but still count it in `tickets_done`/`completed`, and note the count of such tickets so they're visible.

**Per-status dwell (the bottleneck view)** = for each status the ticket occupied, the **sum** of business time across all its intervals (bounce-backs added together). This is what exposes where effort/time actually goes — a fat `Tech Review` or `Blocked` or `To Do` (queue) dwell is the signal. Report dwell under each status's raw name; skip statuses in `workflow.exclude_dwell` (default `[Done]`).

**Business time (the clock).** Count only time falling **Monday–Friday**; weekend hours are excluded. Convert to **business days** = business hours / 24, rounded to 1 decimal. Use Jira's timezone (Europe/Paris). A positive duration under 0.05 bd renders as `<0.1`. Holidays are **not** excluded in v1 (a known, accepted approximation — note it if a number looks inflated by a holiday week). "bd" in any field/column means business days.

**Two lenses (always split these):**
- **Deliverables** — any non-subtask standard issue at `hierarchyLevel: 0` (`subtask: false`): Story, Task, Bug, Spike, etc. The user-facing units. Use the deliverable's **own** changelog (not a rollup of its subtasks).
- **Subtasks** — `issuetype.subtask: true` (`hierarchyLevel: -1`). The granular execution units.
- **Epics** (`hierarchyLevel: 1`) are **excluded** — they are the vault's Projects, not flow units.

(Defining the deliverable lens by hierarchy level rather than by name means uncommon types like **Spike** are included automatically — don't drop them.)

**Summary statistic** = **median** as the headline (robust to a single outlier) and **p85** to watch the tail. Compute over the set of *measurable* tickets (those with a cycle time) **completed in the window** — i.e. `status changed to Done DURING (since, until)`. Medians are computed from the raw per-ticket values of the whole window, never by averaging daily figures. With fewer than ~4 measurable tickets, report the raw values instead of a median and say "small sample".

**Trend.** Each consumer compares the window's median to the previous period's: weekly report diffs the prior `Snapshot`'s `cycle_bd_median*`; 1:1 diffs the prior 1:1 brief's `cycle_bd_median`. Show direction (↓ is improvement — faster) and the delta in bd. If no prior, say "baseline".

**Worked example.** Changelog: created `Day 1 12:35` → In Progress `Day 2 17:33` → Ready `Day 3 11:21` → In Progress `Day 3 14:17` → Tech Review `Day 5 15:20` → Done `Day 8 12:39`. Cycle start = first In Progress (`Day 2 17:33`), Done = `Day 8 12:39`. Business days between them (excluding weekend) ≈ **3.8 bd**. Dwell: In Progress = two intervals summed; Tech Review = Day 5 15:20 → Day 8 12:39 minus weekend; Ready ≈ 0.1 bd; the created→In Progress gap is "To Do" queue dwell.

---

## `type: decision` (optional)

Capture a notable Slack decision or thread so it survives beyond the channel.

```yaml
---
type: decision
team: your-team
date: YYYY-MM-DD
people: ["[[Person One]]", "[[Person Two]]"]
projects: ["[[Your Project]]"]
slack: https://yourworkspace.slack.com/archives/.../p...
---
Decision text in one or two sentences, plus the rationale.
```
