<#
.SYNOPSIS
    Deploys WideWorld Sales Power BI Project to Microsoft Fabric (macOS Compatible)

.DESCRIPTION
    This script deploys the PBIP project (semantic model and report) to a Fabric workspace
    using the FabricPS-PBIP PowerShell module and Fabric REST APIs.
    This version is optimized for macOS to avoid console color issues.

.PARAMETER WorkspaceName
    Name of the Fabric workspace to deploy to (will be created if it doesn't exist)

.PARAMETER SemanticModelPath
    Path to the semantic model folder (default: WideWorldSales.SemanticModel)

.PARAMETER ReportPath
    Path to the report folder (default: WideWorldSales.Report)

.EXAMPLE
    pwsh -File Deploy-ToFabric-macOS.ps1 -WorkspaceName "Sales Analytics"

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

# Disable PSStyle to avoid color issues on macOS
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSStyle.OutputRendering = 'PlainText'
}

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "====================================="
Write-Host "WideWorld Sales - Fabric Deployment"
Write-Host "====================================="
Write-Host ""

# Get current script location
$currentPath = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location $currentPath

# Resolve full paths
$pbipSemanticModelPath = Join-Path $currentPath $SemanticModelPath
$pbipReportPath = Join-Path $currentPath $ReportPath

# Validate paths exist
if (-not (Test-Path $pbipSemanticModelPath)) {
    Write-Host "ERROR: Semantic model path not found: $pbipSemanticModelPath"
    exit 1
}

if (-not (Test-Path $pbipReportPath)) {
    Write-Host "ERROR: Report path not found: $pbipReportPath"
    exit 1
}

Write-Host "Configuration:"
Write-Host "  Workspace: $WorkspaceName"
Write-Host "  Semantic Model: $pbipSemanticModelPath"
Write-Host "  Report: $pbipReportPath"
Write-Host ""

# Step 1: Download and install FabricPS-PBIP module
Write-Host "[1/5] Setting up FabricPS-PBIP module..."

$modulesPath = Join-Path $currentPath "modules"
New-Item -ItemType Directory -Path $modulesPath -ErrorAction SilentlyContinue | Out-Null

$moduleFiles = @(
    "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psm1",
    "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psd1"
)

foreach ($fileUrl in $moduleFiles) {
    $fileName = Split-Path $fileUrl -Leaf
    $outPath = Join-Path $modulesPath $fileName

    Write-Host "  Downloading $fileName..."
    Invoke-WebRequest -Uri $fileUrl -OutFile $outPath -UseBasicParsing
}

# Check and install Az.Accounts module
if (-not (Get-Module Az.Accounts -ListAvailable)) {
    Write-Host "  Installing Az.Accounts module..."
    Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber -ErrorAction SilentlyContinue
}

# Import FabricPS-PBIP module
Import-Module (Join-Path $modulesPath "FabricPS-PBIP.psm1") -Force -WarningAction SilentlyContinue
Write-Host "  Module setup complete!"
Write-Host ""

# Step 2: Authenticate to Fabric
Write-Host "[2/5] Authenticating to Microsoft Fabric..."
Write-Host "  A browser window will open for authentication."
Write-Host ""

try {
    # Suppress color-related errors by redirecting stderr temporarily
    $ErrorActionPreference = "Continue"

    # Try to authenticate - suppress formatting errors
    $null = Set-FabricAuthToken -reset -ErrorAction SilentlyContinue 2>&1

    $ErrorActionPreference = "Stop"

    # Verify we have a token
    $token = Get-FabricAuthToken

    if ($token) {
        Write-Host "  Authentication successful!"
    } else {
        throw "Failed to obtain authentication token"
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: Authentication failed!"
    Write-Host "Please try the following:"
    Write-Host "  1. Ensure you have Az.Accounts module installed:"
    Write-Host "     Install-Module Az.Accounts -Scope CurrentUser -Force"
    Write-Host "  2. Try authenticating manually first:"
    Write-Host "     Connect-AzAccount -UseDeviceAuthentication"
    Write-Host "  3. Then run this script again"
    Write-Host ""
    Write-Host "Technical details: $_"
    exit 1
}
Write-Host ""

# Step 3: Ensure workspace exists
Write-Host "[3/5] Ensuring workspace exists..."

try {
    $workspaceId = New-FabricWorkspace -name $WorkspaceName -skipErrorIfExists
    Write-Host "  Workspace ID: $workspaceId"
} catch {
    Write-Host "ERROR: Failed to create/access workspace: $_"
    exit 1
}
Write-Host ""

# Step 4: Deploy semantic model
Write-Host "[4/5] Deploying semantic model..."
Write-Host "  Path: $pbipSemanticModelPath"

try {
    $semanticModelImport = Import-FabricItem -workspaceId $workspaceId -path $pbipSemanticModelPath
    Write-Host "  Semantic Model ID: $($semanticModelImport.Id)"
    Write-Host "  Semantic Model Name: $($semanticModelImport.DisplayName)"
} catch {
    Write-Host "ERROR: Failed to deploy semantic model: $_"
    exit 1
}
Write-Host ""

# Step 5: Deploy report
Write-Host "[5/5] Deploying report..."
Write-Host "  Path: $pbipReportPath"
Write-Host "  Binding to Semantic Model ID: $($semanticModelImport.Id)"

try {
    $reportImport = Import-FabricItem `
        -workspaceId $workspaceId `
        -path $pbipReportPath `
        -itemProperties @{"semanticModelId" = $semanticModelImport.Id}

    Write-Host "  Report ID: $($reportImport.Id)"
    Write-Host "  Report Name: $($reportImport.DisplayName)"
} catch {
    Write-Host "ERROR: Failed to deploy report: $_"
    exit 1
}
Write-Host ""

# Summary
Write-Host "====================================="
Write-Host "Deployment Successful!"
Write-Host "====================================="
Write-Host ""
Write-Host "Summary:"
Write-Host "  Workspace: $WorkspaceName"
Write-Host "  Workspace ID: $workspaceId"
Write-Host "  Semantic Model: $($semanticModelImport.DisplayName)"
Write-Host "  Semantic Model ID: $($semanticModelImport.Id)"
Write-Host "  Report: $($reportImport.DisplayName)"
Write-Host "  Report ID: $($reportImport.Id)"
Write-Host ""
Write-Host "Next Steps:"
Write-Host "  1. Open Microsoft Fabric in your browser"
Write-Host "  2. Navigate to the '$WorkspaceName' workspace"
Write-Host "  3. Configure data source credentials for SQL Server"
Write-Host "  4. Refresh the semantic model to load data"
Write-Host "  5. Open and view your report!"
Write-Host ""
Write-Host "Fabric URL: https://app.fabric.microsoft.com"
Write-Host ""
