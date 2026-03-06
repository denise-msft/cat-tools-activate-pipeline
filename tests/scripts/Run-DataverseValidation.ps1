<#
.SYNOPSIS
    Validates Dataverse schema against the schema-validation.json test definitions.
    Runs after solution import to confirm tables and columns exist in the target environment.

.DESCRIPTION
    Reads tests/dataverse/schema-validation.json and validates each assertion against
    the Dataverse Web API using the authenticated PAC CLI connection. Outputs results
    as both console output and a structured JSON report.

.PARAMETER ValidationFile
    Path to the schema-validation.json file. Defaults to tests/dataverse/schema-validation.json.

.PARAMETER OutputDirectory
    Directory for test result files. Defaults to TestOutput/dataverse.

.PARAMETER EnvironmentUrl
    Dataverse environment URL (e.g., https://org.crm.dynamics.com). If not provided,
    uses the currently authenticated PAC CLI connection.

.EXAMPLE
    .\Run-DataverseValidation.ps1
    .\Run-DataverseValidation.ps1 -ValidationFile "tests/dataverse/schema-validation.json" -OutputDirectory "TestOutput/dataverse"
#>

param(
    [string]$ValidationFile = "tests/dataverse/schema-validation.json",
    [string]$OutputDirectory = "TestOutput/dataverse",
    [string]$EnvironmentUrl = ""
)

$ErrorActionPreference = "Continue"

# Ensure output directory exists
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

# Load validation definitions
if (-not (Test-Path $ValidationFile)) {
    Write-Error "Validation file not found: $ValidationFile"
    exit 1
}

$validationSuite = Get-Content $ValidationFile -Raw | ConvertFrom-Json
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Dataverse Schema Validation" -ForegroundColor Cyan
Write-Host " Suite: $($validationSuite.testSuiteName)" -ForegroundColor Cyan
Write-Host " Tests: $($validationSuite.validations.Count)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get environment URL from PAC CLI if not provided
if ([string]::IsNullOrEmpty($EnvironmentUrl)) {
    try {
        $authList = pac auth list 2>&1
        $envMatch = $authList | Select-String -Pattern "(https://[^\s]+\.crm[^\s]*\.dynamics\.com)" | Select-Object -First 1
        if ($envMatch) {
            $EnvironmentUrl = $envMatch.Matches[0].Value.TrimEnd('/')
            Write-Host "Using environment: $EnvironmentUrl" -ForegroundColor Gray
        } else {
            Write-Warning "Could not determine environment URL from PAC CLI auth. Schema validation will use pac org commands."
        }
    } catch {
        Write-Warning "PAC CLI auth check failed: $_"
    }
}

# Results tracking
$results = @()
$passCount = 0
$failCount = 0
$skipCount = 0
$startTime = Get-Date

foreach ($validation in $validationSuite.validations) {
    $testResult = @{
        name = $validation.name
        type = $validation.type
        status = "unknown"
        message = ""
        duration_ms = 0
    }
    $testStart = Get-Date

    try {
        switch ($validation.type) {
            "table_exists" {
                Write-Host "`n[$($validation.name)]" -ForegroundColor White -NoNewline
                
                # Use PAC CLI to query entity metadata
                $entityName = $validation.table
                $output = pac org fetch `
                    --entity $entityName `
                    --filter "statecode eq 0" `
                    --top 1 2>&1

                $outputStr = $output -join "`n"
                
                if ($validation.expected -eq $true) {
                    if ($outputStr -match "error" -or $outputStr -match "does not exist" -or $outputStr -match "not found" -or $LASTEXITCODE -ne 0) {
                        $testResult.status = "FAIL"
                        $testResult.message = "Table '$entityName' not found in environment"
                        $failCount++
                        Write-Host " FAIL" -ForegroundColor Red
                        Write-Host "  Expected table '$entityName' to exist but it was not found." -ForegroundColor Red
                    } else {
                        $testResult.status = "PASS"
                        $testResult.message = "Table '$entityName' exists"
                        $passCount++
                        Write-Host " PASS" -ForegroundColor Green
                    }
                } else {
                    if ($outputStr -match "error" -or $outputStr -match "does not exist") {
                        $testResult.status = "PASS"
                        $testResult.message = "Table '$entityName' correctly does not exist"
                        $passCount++
                        Write-Host " PASS" -ForegroundColor Green
                    } else {
                        $testResult.status = "FAIL"
                        $testResult.message = "Table '$entityName' exists but was expected not to"
                        $failCount++
                        Write-Host " FAIL" -ForegroundColor Red
                    }
                }
            }

            "column_exists" {
                Write-Host "`n[$($validation.name)]" -ForegroundColor White -NoNewline
                
                $entityName = $validation.table
                $columnName = $validation.column

                # Query entity metadata for the specific attribute
                $output = pac org fetch `
                    --entity $entityName `
                    --attributes $columnName `
                    --top 1 2>&1

                $outputStr = $output -join "`n"

                if ($validation.expected -eq $true) {
                    if ($outputStr -match "error" -or $outputStr -match "not found" -or $outputStr -match "does not contain" -or $LASTEXITCODE -ne 0) {
                        $testResult.status = "FAIL"
                        $testResult.message = "Column '$columnName' not found on table '$entityName'"
                        $failCount++
                        Write-Host " FAIL" -ForegroundColor Red
                        Write-Host "  Expected column '$columnName' on '$entityName' but it was not found." -ForegroundColor Red
                    } else {
                        $testResult.status = "PASS"
                        $testResult.message = "Column '$columnName' exists on table '$entityName'"
                        $passCount++
                        Write-Host " PASS" -ForegroundColor Green
                    }
                } else {
                    if ($outputStr -match "error" -or $outputStr -match "not found") {
                        $testResult.status = "PASS"
                        $testResult.message = "Column '$columnName' correctly does not exist on '$entityName'"
                        $passCount++
                        Write-Host " PASS" -ForegroundColor Green
                    } else {
                        $testResult.status = "FAIL"
                        $testResult.message = "Column '$columnName' exists on '$entityName' but was expected not to"
                        $failCount++
                        Write-Host " FAIL" -ForegroundColor Red
                    }
                }
            }

            "relationship_exists" {
                Write-Host "`n[$($validation.name)]" -ForegroundColor White -NoNewline
                
                # Relationship validation — check lookup column exists as proxy
                $entityName = $validation.table
                $lookupColumn = $validation.lookupColumn

                $output = pac org fetch `
                    --entity $entityName `
                    --attributes $lookupColumn `
                    --top 1 2>&1

                $outputStr = $output -join "`n"

                if ($outputStr -match "error" -or $outputStr -match "not found" -or $LASTEXITCODE -ne 0) {
                    $testResult.status = "FAIL"
                    $testResult.message = "Relationship lookup '$lookupColumn' not found on '$entityName'"
                    $failCount++
                    Write-Host " FAIL" -ForegroundColor Red
                } else {
                    $testResult.status = "PASS"
                    $testResult.message = "Relationship lookup '$lookupColumn' exists on '$entityName'"
                    $passCount++
                    Write-Host " PASS" -ForegroundColor Green
                }
            }

            "record_count" {
                Write-Host "`n[$($validation.name)]" -ForegroundColor White -NoNewline

                $entityName = $validation.table
                $minCount = if ($validation.PSObject.Properties["minCount"]) { $validation.minCount } else { 0 }

                $output = pac org fetch `
                    --entity $entityName `
                    --filter "statecode eq 0" 2>&1

                $outputStr = $output -join "`n"
                # Count result rows (rough heuristic)
                $rowCount = ($output | Where-Object { $_ -match "^\|" }).Count - 1
                if ($rowCount -lt 0) { $rowCount = 0 }

                if ($rowCount -ge $minCount) {
                    $testResult.status = "PASS"
                    $testResult.message = "Table '$entityName' has $rowCount records (minimum: $minCount)"
                    $passCount++
                    Write-Host " PASS" -ForegroundColor Green
                } else {
                    $testResult.status = "FAIL"
                    $testResult.message = "Table '$entityName' has $rowCount records but expected at least $minCount"
                    $failCount++
                    Write-Host " FAIL" -ForegroundColor Red
                }
            }

            default {
                Write-Host "`n[$($validation.name)]" -ForegroundColor White -NoNewline
                $testResult.status = "SKIP"
                $testResult.message = "Unknown validation type: $($validation.type)"
                $skipCount++
                Write-Host " SKIP" -ForegroundColor Yellow
                Write-Host "  Unknown validation type: $($validation.type)" -ForegroundColor Yellow
            }
        }
    } catch {
        $testResult.status = "ERROR"
        $testResult.message = "Exception: $($_.Exception.Message)"
        $failCount++
        Write-Host " ERROR" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    }

    $testResult.duration_ms = [math]::Round(((Get-Date) - $testStart).TotalMilliseconds)
    $results += $testResult
}

$totalDuration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Results: $passCount passed, $failCount failed, $skipCount skipped" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host " Duration: ${totalDuration}s" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Write JSON report
$report = @{
    suiteName = $validationSuite.testSuiteName
    description = $validationSuite.description
    timestamp = (Get-Date -Format "o")
    duration_seconds = $totalDuration
    summary = @{
        total = $results.Count
        passed = $passCount
        failed = $failCount
        skipped = $skipCount
    }
    results = $results
}

$reportPath = Join-Path $OutputDirectory "schema-validation-results.json"
$report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding utf8
Write-Host "`nReport saved: $reportPath"

# Write markdown summary (for PR comments / GitHub Actions summary)
$mdPath = Join-Path $OutputDirectory "schema-validation-summary.md"
$md = @"
## 🧪 Dataverse Schema Validation Results

| Metric | Value |
|--------|-------|
| **Suite** | $($validationSuite.testSuiteName) |
| **Total Tests** | $($results.Count) |
| **Passed** | ✅ $passCount |
| **Failed** | ❌ $failCount |
| **Skipped** | ⏭️ $skipCount |
| **Duration** | ${totalDuration}s |

### Test Details

| Status | Test | Message |
|--------|------|---------|
"@

foreach ($r in $results) {
    $icon = switch ($r.status) {
        "PASS"  { "✅" }
        "FAIL"  { "❌" }
        "SKIP"  { "⏭️" }
        "ERROR" { "💥" }
        default { "❓" }
    }
    $md += "| $icon | $($r.name) | $($r.message) |`n"
}

$md | Out-File -FilePath $mdPath -Encoding utf8
Write-Host "Summary saved: $mdPath"

# Exit with failure code if any tests failed
if ($failCount -gt 0) {
    Write-Host "`n❌ $failCount validation(s) failed!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ All validations passed!" -ForegroundColor Green
    exit 0
}
