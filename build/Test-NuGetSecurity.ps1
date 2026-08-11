param(
    [string]$SolutionPath = "Source/RatioForge.sln"
)

$ErrorActionPreference = "Stop"

$auditOutput = & dotnet list $SolutionPath package --vulnerable --include-transitive --format json
if ($LASTEXITCODE -ne 0) {
    throw "NuGet vulnerability audit failed with exit code $LASTEXITCODE."
}

$audit = ($auditOutput -join [Environment]::NewLine) | ConvertFrom-Json
$vulnerablePackages = @(
    foreach ($project in $audit.projects) {
        foreach ($framework in @($project.frameworks)) {
            if ($null -eq $framework) {
                continue
            }

            $packages = @($framework.topLevelPackages) + @($framework.transitivePackages)
            foreach ($package in $packages) {
                if ($null -ne $package -and $null -ne $package.vulnerabilities -and @($package.vulnerabilities).Count -gt 0) {
                    [PSCustomObject]@{
                        Project = $project.path
                        Framework = $framework.framework
                        Package = $package.id
                        Version = $package.resolvedVersion
                    }
                }
            }
        }
    }
)

if ($vulnerablePackages.Count -gt 0) {
    $details = $vulnerablePackages | Format-Table -AutoSize | Out-String
    throw "NuGet vulnerabilities detected:`n$details"
}

Write-Host "NuGet vulnerability audit passed for $SolutionPath."
