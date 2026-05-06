---
on:
  schedule: daily
permissions:
  contents: read
  issues: read
  pull-requests: read
safe-outputs:
  create-issue:
    title-prefix: "[daily-status] "
    labels: [report, daily-status]
    close-older-issues: true
---

## CAT Tools Activate Pipeline — Daily Status Report

Create an upbeat daily status report for the activate pipeline as a GitHub issue.

## Context

This repository is an **agent-driven Power Platform solution development pipeline**. It contains
an unpacked Power Platform solution (Dataverse schema, Power Automate flows, Canvas/Model-driven apps,
Copilot Studio agents, Power BI reports). PRDs are filed as issues, decomposed by AI agents into
child issues, implemented by `@copilot`, validated by CI (`pac solution pack` + `pac solution check` +
`pac solution import` + `pac test run`), and deployed via OIDC federated auth.

**Publisher prefix:** `cat_` — **Solution name:** `CATToolsActivatePipeline`

## What to include

- **Repository activity**: Commits to `master`, PRs merged, PRs open, new issues this past day
- **Pipeline health**: Status of `Validate Solution`, `Deploy to Dev`, and `Plan and Review` workflows (passing/failing)
- **Solution health**: Any Solution Checker warnings/errors from the most recent `validate-solution` run
- **Test coverage**: Playwright E2E results, Dataverse schema validation results, Canvas/MDA test pass rate
- **Open issues by area**: Count by label (`area:dataverse`, `area:flow`, `area:canvas`, `area:copilot-studio`, `area:powerbi`)
- **Agent activity**: PRs opened by `@copilot` and other agents, time-to-merge stats
- **Recommendations**: Actionable next steps for the maintainers
- **Fun fact**: One random fun fact about the solution (entity counts, flow counts, total custom columns, lines of TMDL, etc.)

Keep the tone positive and action-oriented. Use emoji for visual scanability.
