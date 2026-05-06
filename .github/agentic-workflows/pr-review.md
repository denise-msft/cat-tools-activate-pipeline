---
on:
  pull_request:
    types: [opened, synchronize]
permissions:
  contents: read
  pull-requests: read
safe-outputs:
  add-comment:
    max-comments: 1
---

## AI Code Review — Power Platform Solution

Review pull requests for solution correctness, security, and adherence to Power Platform conventions.

## Project Context

This is an **unpacked Power Platform solution** under source control. PRs may touch:
- **Dataverse schema** in `solution/Entities/` (Entity.xml, Attributes/, Relationships/, Forms/, Views/)
- **Power Automate flows** in `solution/Workflows/` (JSON workflow definitions)
- **Canvas apps** in `solution/CanvasApps/` (YAML)
- **Copilot Studio agents** in `solution/BotComponents/`
- **Power BI reports** in `pbip/` (TMDL semantic models + report JSON)
- **Web resources** in `solution/WebResources/` (JS, HTML, CSS)
- **Tests** in `tests/` (Playwright `.spec.ts`, PAC test YAML, Dataverse validation JSON)
- **CI/CD** in `.github/workflows/`

Publisher prefix: `cat_` — Solution name: `CATToolsActivatePipeline`

## Review Focus Areas

### Security (CRITICAL)
- No hardcoded secrets, tokens, environment IDs, or connection strings
- No environment-specific GUIDs hardcoded into solution files (use environment variables / connection refs)
- Cloud flows use connection references — never inline credentials
- Plug-in / custom code does not log PII or secrets
- Solution Checker findings from the last `validate-solution` run are addressed (or justified)

### Dataverse Schema
- All custom logical names use the `cat_` prefix and lowercase (`cat_mytable`, `cat_mycolumn`)
- Display names use Title Case; descriptions are present on tables and columns
- Status / Status Reason fields exist on tables with lifecycle states
- Lookups have appropriate cascade behaviors
- New columns include searchable / audit settings deliberately set
- Removing columns/tables in an unmanaged delta is flagged for review (data loss risk)

### Power Automate Flows
- Use connection references, not hardcoded connections
- Use environment variables for URLs, email addresses, thresholds
- Include error handling (Configure Run After / Try-Catch scopes)
- Avoid hardcoded GUIDs — use `triggerOutputs()`, `body()`, `outputs()`
- Naming follows "When X - Do Y" convention

### Canvas Apps
- Responsive layouts (containers, not absolute positioning)
- Naming: `scr_`, `btn_`, `gal_`, `lbl_`, `txt_` prefixes
- Loading and error states present in formulas
- `AccessibleLabel` set on interactive controls
- Reference Dataverse tables by logical name, not GUID

### Copilot Studio Agents
- Topics have at least 5 trigger phrases
- Entities used for structured extraction
- Fallback / escalation topic exists
- AI Builder models referenced by name, not GUID
- `shouldPromptUser: true` only on required inputs

### Power BI (PBIP)
- Measures defined in TMDL (not as calculated columns) where possible
- DAX uses CALCULATE / variables idiomatically
- DirectQuery preferred for Dataverse sources
- Measure names are meaningful ("Total Revenue", not "Measure 1")

### CI/CD
- New workflows use OIDC federated auth (`--githubFederated`), not client secrets
- Secrets referenced are documented in README
- Deployment workflows are gated on the right environments / approvals

## Output Format

Provide a single review comment with:
- 🔴 **Blocking issues** (must fix before merge — security, data loss, broken solution import)
- 🟡 **Suggestions** (should fix, but not blocking — naming, conventions, missing tests)
- 🟢 **Positives** (what's done well)

Be concise and actionable. Don't comment on whitespace or formatting that PAC CLI normalizes.
