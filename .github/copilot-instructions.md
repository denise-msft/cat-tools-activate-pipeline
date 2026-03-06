# Power Platform Solution Development — Copilot Agent Instructions

You are an AI coding agent specialized in building and maintaining Microsoft Power Platform solutions. This repository contains an **unpacked Power Platform solution** stored as source-controlled files. Your job is to implement changes by editing these files directly.

## Solution Context

- **Publisher Prefix**: `cat_` (all custom tables, columns, and components use this prefix)
- **Solution Name**: CATToolsActivatePipeline
- **Platform**: Microsoft Power Platform (Dataverse, Power Apps, Power Automate, Copilot Studio, Power BI)
- **Architecture**: Source-controlled unpacked solution → CI/CD packs and deploys

## What You Can Edit

### Dataverse Schema (`solution/Entities/`)
Each entity (table) is a folder containing:
- `Entity.xml` — Table definition (display name, plural name, primary field, ownership type)
- `Attributes/` — Column definitions (type, display name, required level, format)
- `Relationships/` — Lookup/many-to-many relationships
- `Forms/` — Model-driven app forms (XML)
- `Views/` — Saved queries (FetchXML)

**Rules for Dataverse:**
- Always use `cat_` prefix for logical names: `cat_mytable`, `cat_mycolumn`
- Schema names are lowercase with no spaces: `cat_projectstatus`
- Display names use Title Case: "Project Status"
- Include descriptions on all tables and columns
- Use appropriate attribute types (Lookup, OptionSet, DateTime, Currency, etc.)
- Define Status/Status Reason fields for any table needing lifecycle states
- Create meaningful views: Active records, My records, All records

### Power Automate Flows (`solution/Workflows/`)
Flows are stored as JSON workflow definitions inside the solution.

**Rules for Flows:**
- Use descriptive flow names: "When Project Created - Send Notification"
- Always use connection references (not hardcoded connections)
- Include error handling (Configure Run After on critical actions)
- Use environment variables for configurable values (URLs, email addresses, thresholds)
- Scope actions logically (Try/Catch pattern using Scope + Configure Run After)
- Add comments to complex expressions
- Use `triggerOutputs()`, `body()`, `outputs()` for data access — never hardcode GUIDs

### Canvas Apps (`solution/CanvasApps/`)
Canvas apps are stored in unpacked YAML format.

**Rules for Canvas Apps:**
- Follow responsive design patterns (use containers, not absolute positioning)
- Use consistent naming: `scr_ScreenName`, `btn_ButtonName`, `gal_GalleryName`, `lbl_LabelName`, `txt_TextInputName`
- Reference Dataverse tables via their logical name
- Use variables sparingly — prefer contextual data flow
- Include loading states and error handling in formulas
- Use component libraries for reusable UI patterns
- Always add `AccessibleLabel` properties to interactive controls

### Copilot Studio Agents (`solution/BotComponents/`)
Agent definitions are stored as YAML/JSON in the bot components folder.

**Rules for Copilot Studio:**
- Topics should have clear trigger phrases (minimum 5 per topic)
- Use entities for structured data extraction
- Include fallback/escalation topics
- Reference AI Builder models by name, not GUID
- Use adaptive cards for rich responses
- Keep conversation flows focused — one intent per topic
- `shouldPromptUser: true` ONLY for required inputs, `false` for optional

### Power BI Reports (`pbip/`)
Reports are in PBIP format:
- `*.SemanticModel/` — TMDL files (data model, measures, relationships)
- `*.Report/` — Report layout JSON

**Rules for Power BI:**
- Use DirectQuery to Dataverse when possible
- Create measures in TMDL, not calculated columns (unless needed for sort keys)
- Follow DAX best practices (variables, CALCULATE patterns)
- Use meaningful measure names: "Total Revenue", "Active Projects Count"

### Web Resources (`solution/WebResources/`)
JavaScript, HTML, CSS, and image files.

**Rules for Web Resources:**
- Use `cat_` namespace prefix: `cat_/scripts/main.js`
- Follow modern JavaScript (ES6+, async/await)
- No inline scripts — all JS in separate files
- Include JSDoc comments on public functions

## Testing

After making changes, verify by:
1. Check that solution XML is well-formed
2. Ensure all GUIDs are unique (never duplicate)
3. Verify entity relationships reference existing tables
4. Confirm flow JSON structure is valid
5. Run `pac solution pack` mentally — ensure file paths match expected structure

**IMPORTANT: When you add or modify schema, you MUST update the corresponding test definitions.**

Test plans live in `tests/`:
- `tests/canvas/` — Canvas app UI tests (Power Fx assertions, `.te.yaml` format)
- `tests/mda/` — Model-driven app tests (`.te.yaml` format)
- `tests/dataverse/schema-validation.json` — Schema validation definitions (executed by `tests/scripts/Run-DataverseValidation.ps1`)
- `tests/flows/` — Flow test scenarios (JSON definitions)

### Dataverse Schema Validation
When adding tables or columns, add corresponding entries to `tests/dataverse/schema-validation.json`:
```json
{
  "name": "Verify cat_newtable exists",
  "type": "table_exists",
  "table": "cat_newtable",
  "expected": true
},
{
  "name": "Verify cat_newtable has cat_mycolumn",
  "type": "column_exists",
  "table": "cat_newtable",
  "column": "cat_mycolumn",
  "expected": true
}
```
Supported validation types: `table_exists`, `column_exists`, `relationship_exists`, `record_count`

The CI pipeline runs this automatically after solution import and posts results as a PR comment.

## Environment Configuration

- Connection references are mapped in `config/connection-references.json`
- Environment variables are in `config/environment-variables.json`
- Environment-specific settings (URLs, IDs) are in `config/environments.json`
- **Never hardcode environment-specific values in solution files**

## Workflow

1. Read the assigned issue carefully
2. Create a feature branch: `feature/<issue-number>-<short-description>`
3. Make changes to the appropriate files
4. Ensure changes are consistent across related files (e.g., if adding a table, also add views and forms)
5. Update tests if modifying app behavior
6. Commit with a clear message referencing the issue
7. Open a PR with a summary of changes

## Common Patterns

### Adding a New Dataverse Table
1. Create `solution/Entities/cat_newtable/Entity.xml`
2. Add attributes in `solution/Entities/cat_newtable/Attributes/`
3. Define relationships if needed
4. Create default views (Active, All)
5. Create a main form
6. Update `solution/Other/Customizations.xml` to include the entity

### Adding a New Cloud Flow
1. Create workflow JSON in `solution/Workflows/`
2. Add connection references if new connectors are needed
3. Add environment variables for configurable values
4. Register the workflow in `solution/Other/Customizations.xml`

### Adding a Canvas App Screen
1. Edit the app YAML in `solution/CanvasApps/<app>/`
2. Add screen definition with proper naming
3. Wire navigation from existing screens
4. Add data source connections if needed
5. Create test plan in `tests/canvas/`

## Important Notes
- This is a **community offering** — prioritize simplicity and user experience
- All components should be **solution-aware** (included in the managed solution)
- Use **environment variables** and **connection references** for deployment portability
- Write clear, parseable commit messages for audit trail
