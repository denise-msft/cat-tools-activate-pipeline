---
on:
  issues:
    types: [opened]
permissions:
  contents: read
  issues: read
safe-outputs:
  add-labels:
    max-labels: 5
  add-comment:
    max-comments: 1
---

## Auto-Triage New Issues

When a new issue is opened, analyze it and apply appropriate labels and a triage comment.

## Classification Rules

Analyze the issue title, body, and any selected issue template (PRD, schema-change, app-change,
flow-change, bug-fix) to determine the right labels.

### Priority Labels
- `priority:critical` — Production deployment blocked, data loss risk, security vulnerability
- `priority:high` — Major component broken, blocking the release of an in-flight PRD
- `priority:medium` — Feature not working correctly, workaround exists
- `priority:low` — Cosmetic issues, minor improvements, nice-to-haves

### Area Labels (Power Platform components)
- `area:dataverse` — Tables, columns, relationships, business rules, plug-ins, security roles
- `area:flow` — Power Automate cloud flows, connection references, environment variables
- `area:canvas` — Canvas apps (YAML), screens, controls, formulas, components
- `area:mda` — Model-driven apps, sitemaps, forms, views, dashboards
- `area:copilot-studio` — Copilot Studio agents, topics, entities, generative answers
- `area:powerbi` — PBIP semantic models (TMDL), report layouts, DAX measures
- `area:web-resources` — JavaScript, HTML, CSS web resources
- `area:ci-cd` — GitHub Actions, PAC CLI, deployment pipelines, OIDC auth
- `area:tests` — Playwright E2E, PAC test engine YAML, Dataverse schema validation
- `area:docs` — README, PRDs, architecture docs

### Type Labels
- `prd` — Product requirements doc, needs decomposition into child issues
- `bug` — Something isn't working as expected
- `enhancement` — New feature or improvement
- `decompose` — PRD ready to be broken down by `@solution-architect`
- `question` — Needs clarification or discussion
- `good-first-issue` — Suitable for new contributors

## Triage Comment

Add a brief comment with:
1. Suggested priority and reasoning
2. Which Power Platform component area is affected
3. Which agent persona should pick this up (e.g., `@schema-designer`, `@flow-engineer`,
   `@app-builder`, `@report-builder`, `@solution-architect`, `@test-engineer`)
4. Any relevant existing files in `solution/`, `pbip/`, or `tests/` that the agent should reference
5. Whether this might be related to any open issues or in-flight PRDs

Be helpful and concise. Welcome new contributors warmly.
