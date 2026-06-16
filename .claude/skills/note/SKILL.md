---
name: note
description: Add an observation or attention point to the vault. Can reference a team, a metric, and one or more projects. Auto-closes when the next weekly team-report picks it up. Use for "add a note", "attention point", "I noticed that…", "flag this for the report".
---

# Note — Add an Observation to the Vault

Create a timestamped observation note in `vault/Observations/` so it surfaces in the next weekly team-report and 1:1 preps.

## Usage

```
/note backend GMV is up 12% WoW — looks like the new campaign is driving it, linked to Payment Recovery
/note growth Alice flagged a webhook retry storm — needs watching
/note gmv jump this week on backend, no clear cause yet
```

## Parameters (all parsed from natural language)

- **team** — name matching a `vault/Teams/*.md` file (infer from context; ask if ambiguous)
- **text** — the observation itself (required)
- **projects** — any project names mentioned; resolve to `[[Wikilink]]` against `vault/Projects/*.md`
- **metric** — optional tag (e.g. `gmv`, `prs`, `blockers`, `velocity`)
- **data** — any numbers or table the user included

## Instructions

Follow these steps directly — no subagent needed.

1. **Resolve today's date** from the environment (already provided as `currentDate`).
2. **Resolve team**: glob `vault/Teams/*.md` to get valid team names; look for one of them in the args (case-insensitive). If none found and only one team exists, use it. If multiple teams and none is clear, ask the user.
3. **Resolve project wikilinks**: glob `vault/Projects/*.md` and match any project names mentioned in the args (case-insensitive, partial OK). Produce `[[Project Title]]` links.
4. **Build the frontmatter slug**: lowercase the first 5 significant words of the observation text, join with `-`, max 40 chars.
5. **Ensure directory exists**: `Bash: mkdir -p vault/Observations`
6. **Write the note** to `vault/Observations/{date}-{team}-{slug}.md`:

```markdown
---
type: observation
team: {team}
date: {date}
status: open
projects: [{wikilinks or empty}]
metric: {metric tag or omit}
picked_up_by:
---
## Note
{observation text, exactly as the user wrote it}

## Data
{any numbers/table the user included, or omit this section entirely}
```

7. **Confirm** to the user: print the filename and a one-line echo of what was saved.

## Rules

- Never fabricate data. Write exactly what the user said.
- `status` is always `open` on creation — only `team-report` sets it to `picked_up`.
- If the team cannot be inferred and multiple exist, ask the user rather than guessing.
- Omit empty sections (`## Data`, `projects: []`, `metric:`) rather than leaving them blank.
