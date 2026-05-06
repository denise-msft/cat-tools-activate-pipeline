---
on:
  schedule: weekly
permissions:
  contents: read
  issues: read
safe-outputs:
  create-issue:
    title-prefix: "[test-improvement] "
    labels: [testing, enhancement]
    close-older-issues: true
---

## Weekly Test Improvement Suggestions

Analyze the test suite and suggest improvements to increase coverage and reliability across the
Power Platform solution.

## What to Analyze

1. **Dataverse schema validation gaps** — Look at `tests/dataverse/schema-validation.json`. Are all
   tables in `solution/Entities/` covered? Are required attributes, relationships, and option set
   values asserted?
2. **Canvas app test coverage** — Compare `tests/canvas/*.te.yaml` test plans against the apps in
   `solution/CanvasApps/`. Each screen should have at least one happy-path test.
3. **Model-driven app test coverage** — Compare `tests/mda/*.te.yaml` test plans against any
   model-driven apps. Forms, views, and business process flows should have coverage.
4. **Flow test coverage** — Cloud flows in `solution/Workflows/` should have integration tests in
   `tests/flows/` exercising trigger paths and error branches.
5. **E2E coverage** — Compare `tests/e2e/*.spec.ts` against deployed code apps and key user journeys.
6. **Copilot Studio agent coverage** — Topics should have transcript-based tests for trigger phrases
   and primary fulfillment paths.
7. **Edge cases** — Empty states, permission denials, concurrency, large datasets, business-rule
   violations.

## Output

Create an issue with:
- A prioritized list of 3-5 test improvements
- For each, explain what to test, which file/component, and why it matters
- Include a code/YAML snippet showing the test pattern to use
- Estimate effort (small/medium/large)
- Suggest which agent persona should pick it up (`@test-engineer` is usually the right call)

Focus on high-impact tests that catch real regressions during solution import — not vanity coverage metrics.
