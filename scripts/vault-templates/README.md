# Vault

This is the Obsidian vault for the team tracking system. It is a living database of People, Projects, and activity logs — not a folder of documents.

## Folder structure

| Folder | Written by | Contents |
|--------|-----------|----------|
| `_meta/` | You | Schema contract (`SCHEMAS.md`) and Dataview dashboards (`Views.md`) |
| `Teams/` | You | One config note per squad (Jira keys, repos, Slack channels, roster) |
| `People/` | You + `team-report` | One note per developer/PM — frontmatter + rolling activity log |
| `Projects/` | `team-ingest` | One note per epic/workstream — status, risks, activity log |
| `Daily/` | `team-ingest` | One note per team per day — events + metrics |
| `Snapshots/` | `team-report` | One note per team per week — full readable report + metrics |
| `1on1s/` | `team-1on1` | One brief per person per 1:1 |
| `Observations/` | `/note` skill | Manager attention points, auto-closed by the next weekly report |
| `Goals/` | `/goal` skill | One note per weekly team goal — scored + auto-closed by the next weekly report |

## Commands (run from a Claude Code session at the repo root)

```
/goal <team> <goal>         # set the week's goal — run at the start of the week
/team-ingest <team>         # daily vault sync — run Mon–Thu
/team-report <team>         # weekly snapshot + goal scoring — run Friday afternoon
/team-1on1 "<name>"         # 1:1 prep brief — run before a 1:1
/note <team> <observation>  # flag something for the next report
```

## Setup checklist

- [ ] Install [Obsidian](https://obsidian.md) and open this folder as a vault
- [ ] Install the **Dataview** community plugin (Settings → Community plugins → Browse → "Dataview")
- [ ] Rename `Teams/My Team.md` to your team name, fill in the frontmatter
- [ ] Update `"your-team"` in `_meta/Views.md` queries to match your team's `name:` slug
- [ ] Add a `People/<Name>.md` note for each team member (see `_meta/SCHEMAS.md` for the format)
- [ ] Run `/team-ingest <team>` to populate the first daily note
