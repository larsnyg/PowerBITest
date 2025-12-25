# Manual Fabric Deployment Guide (macOS)

This guide provides a simple, step-by-step process for deploying to Fabric on macOS, avoiding authentication compatibility issues.

## Prerequisites

1. PowerShell 7+ installed
2. Az.Accounts module installed
3. Access to Microsoft Fabric with appropriate permissions

## Step 1: Install Required Module

```powershell
# Install Az.Accounts if not already installed
Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
```

## Step 2: Authenticate to Azure

Use device code authentication (works reliably on macOS):

```powershell
# This will display a code and URL
Connect-AzAccount -UseDeviceAuthentication
```

**What to do:**
1. A code will be displayed (e.g., "LH5XXJCHU")
2. Open https://microsoft.com/devicelogin in your browser
3. Enter the code
4. Sign in with your Microsoft account
5. Return to the terminal - it will show "Account" and "Subscription" when successful

## Step 3: Download and Import FabricPS-PBIP Module

```powershell
# Navigate to project directory
cd ~/Github/PowerBITest

# Create modules directory
mkdir -p modules
cd modules

# Download the module files
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psm1" -OutFile "FabricPS-PBIP.psm1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psd1" -OutFile "FabricPS-PBIP.psd1"

# Import the module
Import-Module ./FabricPS-PBIP.psm1 -Force

# Go back to project root
cd ..
```

## Step 4: Set Fabric Authentication Token

```powershell
# Get Azure access token and set it for Fabric
Set-FabricAuthToken
```

This will use your existing Azure authentication from Step 2.

## Step 5: Create/Verify Workspace

```powershell
# Create or get existing workspace
$workspaceId = New-FabricWorkspace -name "PowerBITest" -skipErrorIfExists

# Display the workspace ID
Write-Host "Workspace ID: $workspaceId"
```

## Step 6: Deploy Semantic Model

```powershell
# Deploy the semantic model
$semanticModelImport = Import-FabricItem `
    -workspaceId $workspaceId `
    -path "./WideWorldSales.SemanticModel"

# Display results
Write-Host "Semantic Model ID: $($semanticModelImport.Id)"
Write-Host "Semantic Model Name: $($semanticModelImport.DisplayName)"
```

## Step 7: Deploy Report

```powershell
# Deploy the report and bind it to the semantic model
$reportImport = Import-FabricItem `
    -workspaceId $workspaceId `
    -path "./WideWorldSales.Report" `
    -itemProperties @{"semanticModelId" = $semanticModelImport.Id}

# Display results
Write-Host "Report ID: $($reportImport.Id)"
Write-Host "Report Name: $($reportImport.DisplayName)"
```

## Step 8: Configure Data Source

After deployment, you need to configure the SQL Server connection:

1. Open https://app.fabric.microsoft.com
2. Navigate to the "PowerBITest" workspace
3. Find the "WideWorldSales" semantic model
4. Click on Settings (gear icon)
5. Go to "Data source credentials"
6. Click "Edit credentials"
7. Enter:
   - **Server**: sql1.orb.local,1433
   - **Database**: WideWorldImporters-Full
   - **Authentication**: Basic
   - **Username**: lars
   - **Password**: DevPassword123!
8. Click "Save"

## Step 9: Refresh the Data

1. Still in the semantic model settings
2. Click "Refresh now"
3. Wait for the refresh to complete (may take a few minutes)
4. Check the refresh history to verify success

## Step 10: View Your Report

1. Go back to the "PowerBITest" workspace
2. Click on the "WideWorldSales" report
3. View your Sales Overview dashboard!

---

## All Steps in One Script

If you want to run all deployment steps at once (after authentication):

```powershell
# Navigate to project
cd ~/Github/PowerBITest

# Authenticate first
Connect-AzAccount -UseDeviceAuthentication

# Download and import module
mkdir -p modules
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psm1" -OutFile "modules/FabricPS-PBIP.psm1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psd1" -OutFile "modules/FabricPS-PBIP.psd1"
Import-Module ./modules/FabricPS-PBIP.psm1 -Force

# Set Fabric token
Set-FabricAuthToken

# Deploy
$workspaceId = New-FabricWorkspace -name "PowerBITest" -skipErrorIfExists
$semanticModelImport = Import-FabricItem -workspaceId $workspaceId -path "./WideWorldSales.SemanticModel"
$reportImport = Import-FabricItem -workspaceId $workspaceId -path "./WideWorldSales.Report" -itemProperties @{"semanticModelId" = $semanticModelImport.Id}

# Display results
Write-Host ""
Write-Host "====================================="
Write-Host "Deployment Successful!"
Write-Host "====================================="
Write-Host ""
Write-Host "Workspace ID: $workspaceId"
Write-Host "Semantic Model ID: $($semanticModelImport.Id)"
Write-Host "Report ID: $($reportImport.Id)"
Write-Host ""
Write-Host "Next: Configure data source credentials at https://app.fabric.microsoft.com"
```

## Troubleshooting

### "Cannot find workspace"
- Ensure you have Fabric capacity assigned
- Verify you have Contributor or Admin permissions

### "Cannot deploy semantic model"
- Check that the WideWorldSales.SemanticModel folder exists
- Verify all TMDL files are present and valid

### "Cannot bind report to semantic model"
- Ensure the semantic model deployed successfully first
- Verify the semantic model ID is correct

### "Authentication token expired"
- Run `Connect-AzAccount -UseDeviceAuthentication` again
- Then run `Set-FabricAuthToken` to refresh the Fabric token
