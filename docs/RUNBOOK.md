# Operational Runbook: Agent-Driven Power Platform Development

## Quick Start

### One-Time Setup

#### 1. Enable Copilot Coding Agent
1. Go to **github.com/settings/copilot** → **Coding agent**
2. Enable "Copilot coding agent" policy
3. Under Repository access, select **All repositories** or add `cat-tools-activate-pipeline`
4. Verify: Open any issue and check if `copilot` appears in the assignee dropdown

> **Requires**: Copilot Pro+ subscription (or Copilot Business/Enterprise via org)

#### 2. Configure GitHub Secrets
Go to **github.com/denise-msft/cat-tools-activate-pipeline/settings/secrets/actions** and add:

| Secret | Description | Where to get it |
|--------|-------------|-----------------|
| `PP_CLIENT_ID` | Service Principal App ID | Azure Portal → App Registrations |
| `PP_CLIENT_SECRET` | Service Principal secret | Azure Portal → App Registrations → Certificates & Secrets |
| `PP_TENANT_ID` | Azure AD Tenant ID | Azure Portal → Entra ID → Overview |
| `PP_DEV_ENV_URL` | Dev environment URL | `https://org-dev.crm.dynamics.com` |
| `PP_DEV_ENV_ID` | Dev environment ID | Power Platform Admin Center → Environments |
| `PP_STAGING_ENV_URL` | Staging env URL | Same pattern |
| `PP_PROD_ENV_URL` | Production env URL | Same pattern |

#### 3. Create Service Principal
```bash
# Create app registration
az ad app create --display-name "CAT Tools Pipeline SP"

# Create service principal
az ad sp create --id <app-id>

# Grant Dataverse permissions
# In Power Platform Admin Center: Add as System Administrator to each environment
```

#### 4. Register Solution Publisher
In your dev environment, create (or verify) the publisher:
- **Name**: CAT Tools
- **Prefix**: cat
- **Option Value Prefix**: 10000

---

## Daily Workflow

### Creating a New Feature

```
1. Write a PRD → Create issue with "PRD Feature" template
2. Label it: prd + decompose
3. Agent (or you) decomposes into child issues
4. Assign child issues to @copilot (start with schema → app → flow)
5. Agent creates branches, edits solution files, opens PRs
6. CI validates each PR (pack, check, import, test)
7. You review PRs and merge
8. Dev deploy runs automatically on merge to main
```

### Fixing a Bug

```
1. Create issue with "Bug Fix" template
2. Describe the bug with repro steps
3. Assign to @copilot
4. Agent investigates, fixes, opens PR
5. Review and merge
```

### Deploying to Staging/Production

```
1. Go to Actions tab → "Deploy to Staging" workflow
2. Click "Run workflow"
3. Type "deploy" to confirm → Packs managed solution → Imports to staging
4. For production: same flow, type "PRODUCTION" to confirm
```

---

## Issue Labels Reference

| Label | When to Use |
|-------|-------------|
| `prd` | Product Requirements Documents |
| `decompose` | PRD needs to be broken into work items |
| `schema` | Dataverse table/column/relationship changes |
| `canvas-app` | Canvas Power App work |
| `model-app` | Model-driven app work |
| `cloud-flow` | Power Automate flow work |
| `copilot-agent` | Copilot Studio agent work |
| `power-bi` | Power BI report/dashboard work |
| `config` | Environment variables, connection references |
| `test` | Test plans and test cases |
| `bug` | Bug fixes |

---

## Agent Behavior

### What the agent CAN do:
- Edit solution XML/JSON/YAML files (Dataverse schema, forms, views)
- Create/modify Power Automate flow JSON
- Edit Canvas app YAML (unpacked format)
- Write Copilot Studio agent definitions
- Create Power BI TMDL and report JSON
- Write test plans (YAML + Power Fx)
- Run PAC CLI commands via MCP tools
- Create branches, commit, and open PRs

### What the agent CANNOT do (human needed):
- Complex Canvas app visual design (pixel-perfect layout)
- Live environment debugging
- Create service principals or manage Azure AD
- Approve production deployments
- Resolve merge conflicts in binary files

---

## Troubleshooting

### CI Pipeline fails on "Pack Solution"
- Check for XML syntax errors in Customizations.xml
- Verify all entity references in Solution.xml exist in Entities/ folder
- Ensure GUIDs are unique and properly formatted

### Agent doesn't pick up the issue
- Verify Copilot coding agent is enabled (Settings → Copilot → Coding agent)
- Check that the repo has coding agent access
- Ensure the issue is assigned to `copilot`, not just labeled

### Solution import fails in dev
- Check service principal has System Administrator role
- Verify environment URL in secrets matches actual env
- Check solution dependencies (missing tables, etc.)

### Tests fail
- Ensure app is published in the target environment
- Check Playwright browsers are installed in CI runner
- Verify test plan YAML references correct app logical name

---

## Architecture

See: [docs/architecture/solution-architecture.md](../docs/architecture/solution-architecture.md)

## File Structure

```
.github/
├── copilot-instructions.md     ← Agent brain (always active)
├── .copilot/mcp.json           ← MCP tools available to agent
├── instructions/               ← Path-specific rules (auto-applied per file type)
├── agents/                     ← Specialized agent personas
├── workflows/                  ← CI/CD pipelines
└── ISSUE_TEMPLATE/             ← Structured issue forms

solution/                       ← Unpacked Power Platform solution
├── Other/Solution.xml          ← Solution manifest
├── Other/Customizations.xml    ← Component registry
├── Entities/                   ← Dataverse tables
├── Workflows/                  ← Cloud flow JSON
├── CanvasApps/                 ← Canvas app YAML
├── BotComponents/              ← Copilot Studio agents
└── WebResources/               ← JS/HTML/CSS

pbip/                           ← Power BI reports (TMDL + JSON)
tests/                          ← Automated test plans
config/                         ← Environment configuration
docs/                           ← PRDs and architecture
```
