# Deploying to Microsoft Fabric

This guide explains how to deploy the WideWorld Sales Power BI Project to Microsoft Fabric using the included PowerShell deployment script.

## Prerequisites

### 1. Microsoft Fabric Access
- Active Microsoft Fabric subscription
- Fabric capacity assigned to your workspace
- Contributor or Admin permissions in the target workspace

### 2. PowerShell Requirements
- **PowerShell 7.0 or higher** (recommended)
  - Download: https://github.com/PowerShell/PowerShell/releases
- **Az.Accounts module** (will be auto-installed if missing)

### 3. Authentication
- Azure AD account with Fabric access
- Ability to perform interactive browser authentication

## Deployment Process

### Quick Start

1. **Open PowerShell 7** in the project directory

2. **Run the deployment script**:
   ```powershell
   .\Deploy-ToFabric.ps1 -WorkspaceName "Sales Analytics"
   ```

3. **Authenticate** when prompted (browser window will open)

4. **Wait for deployment** to complete (typically 2-5 minutes)

### Detailed Steps

The deployment script performs the following operations:

#### Step 1: Module Setup
- Downloads the `FabricPS-PBIP` module from Microsoft's GitHub
- Installs `Az.Accounts` module if not present
- Imports required modules

#### Step 2: Authentication
- Opens browser for Azure AD authentication
- Obtains access token for Fabric APIs
- Validates authentication success

#### Step 3: Workspace Creation
- Creates the specified workspace if it doesn't exist
- Retrieves workspace ID if it already exists
- Verifies workspace access

#### Step 4: Semantic Model Deployment
- Deploys the `WideWorldSales.SemanticModel` folder
- Creates tables, relationships, and measures in Fabric
- Returns semantic model ID for report binding

#### Step 5: Report Deployment
- Deploys the `WideWorldSales.Report` folder
- Binds report to the deployed semantic model
- Creates all pages and visuals

## Post-Deployment Configuration

After successful deployment, you need to configure the data source:

### 1. Navigate to Fabric Workspace
- Go to https://app.fabric.microsoft.com
- Select your workspace (e.g., "Sales Analytics")

### 2. Configure Data Source Credentials
- Click on the **semantic model** (WideWorldSales)
- Go to **Settings** → **Data source credentials**
- Click **Edit credentials**
- Enter SQL Server credentials:
  - **Server**: sql1.orb.local,1433
  - **Database**: WideWorldImporters-Full
  - **Authentication**: Basic
  - **Username**: lars
  - **Password**: DevPassword123!
- Click **Save**

### 3. Refresh the Semantic Model
- In the semantic model settings, click **Refresh now**
- Wait for the refresh to complete
- Verify data is loaded successfully

### 4. Open the Report
- Navigate back to the workspace
- Click on the **report** (WideWorldSales)
- View your Sales Overview dashboard!

## Script Parameters

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-WorkspaceName` | Name of the Fabric workspace | `"Sales Analytics"` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-SemanticModelPath` | Path to semantic model folder | `WideWorldSales.SemanticModel` |
| `-ReportPath` | Path to report folder | `WideWorldSales.Report` |

### Example with Custom Paths

```powershell
.\Deploy-ToFabric.ps1 `
    -WorkspaceName "Production Analytics" `
    -SemanticModelPath ".\WideWorldSales.SemanticModel" `
    -ReportPath ".\WideWorldSales.Report"
```

## Troubleshooting

### Authentication Fails
**Issue**: Browser doesn't open or authentication times out

**Solutions**:
- Ensure you have an active internet connection
- Check if your organization allows Azure AD authentication
- Try running: `Connect-AzAccount` manually first
- Clear browser cookies and try again

### Module Download Fails
**Issue**: Cannot download FabricPS-PBIP module

**Solutions**:
- Check internet connectivity
- Verify GitHub is accessible from your network
- Try manually downloading files from:
  - https://github.com/microsoft/Analysis-Services/tree/master/pbidevmode/fabricps-pbip

### Workspace Creation Fails
**Issue**: "Insufficient permissions" or capacity errors

**Solutions**:
- Verify you have Fabric capacity assigned
- Check you have Contributor/Admin role in Fabric
- Ensure workspace name doesn't already exist with different settings

### Semantic Model Deployment Fails
**Issue**: Deployment errors or validation failures

**Solutions**:
- Verify TMDL files are valid
- Check for syntax errors in table definitions
- Ensure all required files exist in SemanticModel folder

### Data Refresh Fails
**Issue**: Cannot connect to SQL Server after deployment

**Solutions**:
- Verify SQL Server is accessible from Fabric
- Check firewall rules allow Fabric IP addresses
- Confirm database credentials are correct
- Ensure database exists and user has permissions

## CI/CD Integration

For automated deployments in CI/CD pipelines:

### GitHub Actions Example

```yaml
name: Deploy to Fabric

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v3

    - name: Deploy to Fabric
      shell: pwsh
      run: |
        .\Deploy-ToFabric.ps1 -WorkspaceName "Production Analytics"
      env:
        AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
```

### Azure DevOps Pipeline Example

```yaml
trigger:
- main

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'Deploy to Fabric'
  inputs:
    targetType: 'filePath'
    filePath: './Deploy-ToFabric.ps1'
    arguments: '-WorkspaceName "Production Analytics"'
```

## API Rate Limits

The Fabric REST APIs have rate limits:
- **Requests**: 1000 per hour per user
- **Payload**: Maximum 100 MB per request

The deployment script handles these automatically with retry logic.

## Security Best Practices

1. **Never commit credentials** to the repository
2. **Use service principals** for automated deployments
3. **Enable row-level security** in the semantic model if needed
4. **Review workspace permissions** after deployment
5. **Use separate workspaces** for dev, test, and production

## Additional Resources

- [Fabric REST API Documentation](https://learn.microsoft.com/en-us/rest/api/fabric/)
- [FabricPS-PBIP Module Source](https://github.com/microsoft/Analysis-Services/tree/master/pbidevmode/fabricps-pbip)
- [Power BI Projects Overview](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview)
- [Fabric Workspace Management](https://learn.microsoft.com/en-us/fabric/admin/workspace-management)

## Support

For issues with:
- **This script**: Open an issue in this repository
- **FabricPS-PBIP module**: Check the [GitHub repository](https://github.com/microsoft/Analysis-Services)
- **Fabric APIs**: Contact Microsoft Support or post in [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/)
