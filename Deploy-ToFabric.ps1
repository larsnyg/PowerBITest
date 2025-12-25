<#
.SYNOPSIS
    Deploys WideWorld Sales Power BI Project to Microsoft Fabric

.DESCRIPTION
    This script deploys the PBIP project (semantic model and report) to a Fabric workspace
    using the FabricPS-PBIP PowerShell module and Fabric REST APIs.

.PARAMETER WorkspaceName
    Name of the Fabric workspace to deploy to (will be created if it doesn't exist)

.PARAMETER SemanticModelPath
    Path to the semantic model folder (default: WideWorldSales.SemanticModel)

.PARAMETER ReportPath
    Path to the report folder (default: WideWorldSales.Report)

.EXAMPLE
    .\Deploy-ToFabric.ps1 -WorkspaceName "Sales Analytics"

.NOTES
    Prerequisites:
    - PowerShell 7.0 or higher
    - Az.Accounts module
    - Internet connection to download FabricPS-PBIP module
    - Fabric capacity assigned to the workspace
    - Appropriate permissions in Fabric workspace
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceName,

    [Parameter(Mandatory=$false)]
    [string]$SemanticModelPath = "WideWorldSales.SemanticModel",

    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "WideWorldSales.Report"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "WideWorld Sales - Fabric Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Get current script location
$currentPath = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location $currentPath

# Resolve full paths
$pbipSemanticModelPath = Join-Path $currentPath $SemanticModelPath
$pbipReportPath = Join-Path $currentPath $ReportPath

# Validate paths exist
if (-not (Test-Path $pbipSemanticModelPath)) {
    Write-Error "Semantic model path not found: $pbipSemanticModelPath"
    exit 1
}

if (-not (Test-Path $pbipReportPath)) {
    Write-Error "Report path not found: $pbipReportPath"
    exit 1
}

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Workspace: $WorkspaceName" -ForegroundColor White
Write-Host "  Semantic Model: $pbipSemanticModelPath" -ForegroundColor White
Write-Host "  Report: $pbipReportPath" -ForegroundColor White
Write-Host ""

# Step 1: Download and install FabricPS-PBIP module
Write-Host "[1/5] Setting up FabricPS-PBIP module..." -ForegroundColor Yellow

$modulesPath = Join-Path $currentPath "modules"
New-Item -ItemType Directory -Path $modulesPath -ErrorAction SilentlyContinue | Out-Null

$moduleFiles = @(
    "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psm1",
    "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psd1"
)

foreach ($fileUrl in $moduleFiles) {
    $fileName = Split-Path $fileUrl -Leaf
    $outPath = Join-Path $modulesPath $fileName

    Write-Host "  Downloading $fileName..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $fileUrl -OutFile $outPath -UseBasicParsing
}

# Check and install Az.Accounts module
if (-not (Get-Module Az.Accounts -ListAvailable)) {
    Write-Host "  Installing Az.Accounts module..." -ForegroundColor Gray
    Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
}

# Import FabricPS-PBIP module
Import-Module (Join-Path $modulesPath "FabricPS-PBIP.psm1") -Force
Write-Host "  Module setup complete!" -ForegroundColor Green
Write-Host ""

# Step 2: Authenticate to Fabric
Write-Host "[2/5] Authenticating to Microsoft Fabric..." -ForegroundColor Yellow
Write-Host "  A browser window will open for authentication." -ForegroundColor Gray

try {
    Set-FabricAuthToken -reset
    Write-Host "  Authentication successful!" -ForegroundColor Green
} catch {
    Write-Error "Authentication failed: $_"
    exit 1
}
Write-Host ""

# Step 3: Ensure workspace exists
Write-Host "[3/5] Ensuring workspace exists..." -ForegroundColor Yellow

try {
    $workspaceId = New-FabricWorkspace -name $WorkspaceName -skipErrorIfExists
    Write-Host "  Workspace ID: $workspaceId" -ForegroundColor Green
} catch {
    Write-Error "Failed to create/access workspace: $_"
    exit 1
}
Write-Host ""

# Step 4: Deploy semantic model
Write-Host "[4/5] Deploying semantic model..." -ForegroundColor Yellow
Write-Host "  Path: $pbipSemanticModelPath" -ForegroundColor Gray

try {
    $semanticModelImport = Import-FabricItem -workspaceId $workspaceId -path $pbipSemanticModelPath
    Write-Host "  Semantic Model ID: $($semanticModelImport.Id)" -ForegroundColor Green
    Write-Host "  Semantic Model Name: $($semanticModelImport.DisplayName)" -ForegroundColor Green
} catch {
    Write-Error "Failed to deploy semantic model: $_"
    exit 1
}
Write-Host ""

# Step 5: Deploy report
Write-Host "[5/5] Deploying report..." -ForegroundColor Yellow
Write-Host "  Path: $pbipReportPath" -ForegroundColor Gray
Write-Host "  Binding to Semantic Model ID: $($semanticModelImport.Id)" -ForegroundColor Gray

try {
    $reportImport = Import-FabricItem `
        -workspaceId $workspaceId `
        -path $pbipReportPath `
        -itemProperties @{"semanticModelId" = $semanticModelImport.Id}

    Write-Host "  Report ID: $($reportImport.Id)" -ForegroundColor Green
    Write-Host "  Report Name: $($reportImport.DisplayName)" -ForegroundColor Green
} catch {
    Write-Error "Failed to deploy report: $_"
    exit 1
}
Write-Host ""

# Summary
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Deployment Successful!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Workspace: $WorkspaceName" -ForegroundColor White
Write-Host "  Workspace ID: $workspaceId" -ForegroundColor White
Write-Host "  Semantic Model: $($semanticModelImport.DisplayName)" -ForegroundColor White
Write-Host "  Semantic Model ID: $($semanticModelImport.Id)" -ForegroundColor White
Write-Host "  Report: $($reportImport.DisplayName)" -ForegroundColor White
Write-Host "  Report ID: $($reportImport.Id)" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open Microsoft Fabric in your browser" -ForegroundColor White
Write-Host "  2. Navigate to the '$WorkspaceName' workspace" -ForegroundColor White
Write-Host "  3. Configure data source credentials for SQL Server" -ForegroundColor White
Write-Host "  4. Refresh the semantic model to load data" -ForegroundColor White
Write-Host "  5. Open and view your report!" -ForegroundColor White
Write-Host ""
