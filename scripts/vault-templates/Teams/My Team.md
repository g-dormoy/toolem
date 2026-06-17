---
type: team
name: my-team              # lowercase slug — used in Daily/Snapshot filenames and Dataview queries
jira_project: ENG          # your Jira project key (e.g. ENG, GROW, PAY)
tsd_project:               # optional: shared support-desk Jira project key
tsd_squad_field: squad     # optional: Jira custom field that routes TSD tickets to squads
tsd_squads: [MySquad]      # optional: your squad's values in that field (list)
github_org: your-org       # GitHub organisation slug
repos:
  - your-org/your-repo     # one line per GitHub repo this squad owns
slack:
  team: "#sqd-myteam"      # primary team channel
  problem: "#problem-mymetric"  # problem / metric channel
  other: []                # optional: additional channels to scan (list)
fellow:                    # optional: Fellow meeting discovery (omit to default to team `name`)
  meeting_titles: ["My Team DSM", "My Team"]   # ← CONFIGURE: standup title + squad name patterns
people:
  - "[[Person One]]"       # wikilinks to vault/People/ notes — one per team member
  - "[[Person Two]]"
# --- optional: lead-time workflow tuning (omit to use defaults) ---
# workflow:
#   active_start: [In Progress]   # ← CONFIGURE: your Jira "work started" status
#   done: [Done]                   # ← CONFIGURE: your Jira "done" status
#   exclude_dwell: [Done]          # ← CONFIGURE: statuses omitted from bottleneck breakdown
---
# My Team

EM: Your Name.

## Roster
<!-- List people by role, e.g.: -->
<!-- Developers: [[Person One]], [[Person Two]] -->
<!-- Product: [[Person Three]] (PM) -->

## Channels
- Team: #sqd-myteam
- Problem: #problem-mymetric
