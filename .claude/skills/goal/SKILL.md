---
name: goal
description: Set a weekly team goal in the vault. Captures the week's intent (title, success criteria, the projects/tickets it covers) so team-ingest can tag work on-goal vs off-goal and the weekly team-report can score focus and defocus. Auto-closes when that week's report scores it. Use for "set a goal", "this week's goal", "our priority this week is…", "goal of the week".
---

# Goal — Set a Weekly Team Goal

Create a `type: goal` note in `vault/Goals/` so the week's work can be flagged on-goal vs off-goal, and so the Friday `team-report` scores it and computes the team's focus. Same lifecycle as `/note`: created by hand, **closed automatically** by the next weekly `team-report`.

## Usage

```
/goal poseidon Ship Payment Dashboard iteration 2 — filters + pagination live behind FF, covers Payment Dashboard, top priority
/goal poseidon Land the PayPal integration POC, success = sandbox payment round-trips end to end
/goal hecate Cut retailer onboarding drop-off, rank 2, covers MyNetwork Simplification
```

## Parameters (all parsed from natural language)

- **team** — name matching a `vault/Teams/*.md` file (infer from context; ask if ambiguous).
- **title** — the goal itself, one crisp line (required).
- **success** — the success criterion ("success = …", "done when …", "so that …"). Optional but encouraged.
- **projects** — any project names mentioned; resolve to `[[Wikilink]]` against `vault/Projects/*.md`. These define the on-goal set.
- **jira_keys** — any explicit ticket keys mentioned (e.g. `ENG-3164`), for flagging beyond the projects. Optional.
- **rank** — priority order if stated ("top priority" → 1, "rank 2" → 2). Default: next rank after existing goals for the week (else 1).
- **week_ending** — only if the user names a different week; otherwise compute it (below).

## Instructions

Follow these steps directly — no subagent needed.

1. **Resolve dates** from the environment (`currentDate` is provided).
   - `week_ending` = the **Friday** of the current week. If today is Saturday or Sunday, use the **coming** Friday. Honour an explicit week the user names.
   - `week_start` = the Monday of that same week (`week_ending` − 4 days).
2. **Resolve team**: glob `vault/Teams/*.md` for valid team names; match one in the args (case-insensitive). If none found and only one team exists, use it. If multiple teams and none is clear, ask the user.
3. **Resolve project wikilinks**: glob `vault/Projects/*.md` and match any project names mentioned (case-insensitive, partial OK). Produce `[[Project Title]]` links. If the user names work that has no project note yet, keep the goal but note it under `## Notes` (do not invent a project).
4. **Resolve rank**: glob `vault/Goals/{Team} {week_ending} *.md`; default `rank` to (count of existing goals for the week) + 1 unless the user stated one.
5. **Build the slug**: lowercase the first ~5 significant words of the title, join with `-`, max 40 chars.
6. **Ensure the directory exists**: `Bash: mkdir -p vault/Goals`
7. **Write the note** to `vault/Goals/{Team} {week_ending} {slug}.md` (overwrite if it already exists — idempotent by filename):

```markdown
---
type: goal
team: {team}
week_start: {week_start}
week_ending: {week_ending}
title: {title}
rank: {rank}
projects: [{wikilinks}]
jira_keys: [{keys}]
success: "{success criterion}"
status: planned
outcome:
scored_by:
---
## Why
{any rationale the user gave, or omit the section}

## Notes
{any work named without a project note, or omit the section}
```

8. **Confirm** to the user: print the filename, the goal title, its rank, the on-goal projects/keys, and the week it applies to.

## Rules

- Never fabricate data. Write exactly what the user said; leave `success` empty if they gave none.
- `status` is always `planned` on creation — only `team-report` sets a terminal status (`met`/`partial`/`missed`) and fills `outcome` / `scored_by`. The EM may hand-edit to `at-risk` mid-week.
- Omit empty keys/sections (`projects: []`, `jira_keys: []`, `## Why`, `## Notes`) rather than leaving them blank.
- If the team cannot be inferred and multiple exist, ask rather than guess.
- To revise a goal, re-run `/goal` with the same title and week — it overwrites by filename. To drop a goal, tell the user to set its `status: dropped`.
