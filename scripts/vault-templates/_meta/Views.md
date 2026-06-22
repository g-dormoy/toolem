---
type: meta
---
# Views — Dataview dashboards

These queries replace the Notion dashboards. They read entity frontmatter live, so they're always current. Requires the **Dataview** community plugin (Settings → Community plugins → Dataview; enable JS queries is not needed — these are DQL).

Once a few `Snapshots/` exist, this note becomes your standing dashboard. Pin it.

> **Setup note:** Replace `"your-team"` in every query below with the `name:` slug from your `vault/Teams/` note (e.g. `"backend"`, `"growth"`). If you have multiple teams, duplicate each query block and change the slug.

---

## Velocity trend (per team)

```dataview
TABLE period_end AS "Week", merged_prs AS "Merged PRs", completed_tickets AS "Done", cycle_bd_median AS "Cycle (bd)", avg_review_hours AS "Review h", avg_merge_hours AS "Merge h", open_blockers AS "Blockers"
FROM "Snapshots"
WHERE type = "snapshot" AND team = "your-team"
SORT period_end DESC
```

---

## Lead-time trend (per team)

Cycle time = In Progress → Done in **business days**, median of tickets completed that week. Watch the trend, not the absolute — and watch `p85` for the tail.

```dataview
TABLE period_end AS "Week",
  cycle_bd_median AS "All (med)", cycle_bd_p85 AS "All (p85)",
  cycle_bd_median_deliverable AS "Deliverable (med)",
  cycle_bd_median_subtask AS "Subtask (med)",
  completed_measurable AS "n"
FROM "Snapshots"
WHERE type = "snapshot" AND team = "your-team"
SORT period_end DESC
```

Per-status **bottleneck** detail (which status ate the time) lives in each Snapshot's `## Lead Time & Bottlenecks` body table — status names are team-specific so they're not in frontmatter. Open the latest Snapshot to see it.

---

## Focus trend (per team)

Share of each week's completed deliverables that served the team's stated goals (`focus_pct`), with the off-goal split — **reactive** (legitimate firefighting: support / bugs / hotfixes) vs **drift** (off-goal, unforced). Watch `drift_done` / `drift_bd` rising as the defocus signal.

```dataview
TABLE period_end AS "Week", focus_pct AS "Focus %", on_goal_done AS "On-goal", reactive_done AS "Reactive", drift_done AS "Drift", drift_bd AS "Drift (bd)"
FROM "Snapshots"
WHERE type = "snapshot" AND team = "your-team" AND focus_pct
SORT period_end DESC
```

Per-goal verdicts (met / partial / missed) and the defocus detail live in each Snapshot's `## Weekly Goals & Focus` body section.

---

## This week's goals (per team)

The goals currently set, newest week first. Closed goals carry their verdict in `status`; open ones show `planned` / `at-risk`.

```dataview
TABLE week_ending AS "Week", rank AS "#", status AS "Status", success AS "Success criterion", scored_by AS "Scored in"
FROM "Goals"
WHERE type = "goal" AND team = "your-team"
SORT week_ending DESC, rank ASC
```

---

## Daily activity (last 14 days, per team)

```dataview
TABLE date AS "Day", merged_prs AS "Merged", opened_prs AS "Opened", tickets_done AS "Done", ci_failures AS "CI fails"
FROM "Daily"
WHERE type = "daily" AND team = "your-team"
SORT date DESC
LIMIT 14
```

---

## Active projects by status

```dataview
TABLE status, eta, join(people) AS "People", updated
FROM "Projects"
WHERE type = "project" AND status != "shipped" AND status != "dropped"
SORT status ASC, updated DESC
```

## Projects needing a status refresh (imported / unknown)

```dataview
LIST
FROM "Projects"
WHERE type = "project" AND status = "unknown"
```

---

## Roster

```dataview
TABLE team, position, github, email
FROM "People"
WHERE type = "person" AND active = true
SORT team ASC, role ASC
```

---

## Open questions across all projects

This surfaces every unchecked `## Open Questions` item, with its project.

```dataview
TASK
FROM "Projects"
WHERE !completed
```

---

## What changed for a person recently

Open any `People/` note and read its `## Activity Log`. To pull everyone's latest line into one place, use the file list and inline links — or just lean on the graph view to see who's connected to which project.
