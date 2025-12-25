# WideWorld Sales Power BI Project

This Power BI project connects to the WideWorldImporters-Full SQL Server database and provides sales analysis using the new TMDL (Tabular Model Definition Language) and PBIR (Power BI Enhanced Report) formats.

## Project Structure

```
PowerBITest/
├── WideWorldSales.Dataset/          # TMDL Dataset
│   ├── .pbi/
│   │   └── localSettings.json
│   ├── definition/
│   │   ├── database.tmdl            # Main database definition
│   │   ├── relationships.tmdl       # Table relationships
│   │   └── tables/                  # Individual table definitions
│   │       ├── Calendar.tmdl        # Date/time dimension
│   │       ├── Customers.tmdl
│   │       ├── InvoiceLines.tmdl
│   │       ├── Invoices.tmdl
│   │       ├── Measures.tmdl        # DAX measures
│   │       ├── OrderLines.tmdl
│   │       ├── Orders.tmdl
│   │       ├── People.tmdl
│   │       └── StockItems.tmdl
│   └── definition.pbism             # Dataset metadata
│
└── WideWorldSales.Report/           # PBIR Report
    ├── .pbi/
    │   └── localSettings.json
    ├── definition/
    │   ├── pages/
    │   │   ├── pages.json           # Pages list
    │   │   └── SalesOverview/
    │   │       └── page.json        # Sales overview page with visuals
    │   ├── report.json              # Report-level settings
    │   └── version.json             # PBIR version
    ├── StaticResources/
    │   └── RegisteredResources/
    └── definition.pbir               # Report metadata

```

## Data Model

### Tables
- **Calendar**: Date dimension table (2013-2025) for time intelligence
- **Customers**: Customer master data
- **Orders**: Sales orders header
- **OrderLines**: Sales order line items
- **Invoices**: Invoice header
- **InvoiceLines**: Invoice line items (fact table)
- **StockItems**: Product catalog
- **People**: Employee/salesperson information
- **Measures**: DAX measure calculations

### Key Measures
- **Total Revenue**: Sum of invoice line extended prices
- **Total Profit**: Sum of line profit
- **Total Quantity Sold**: Sum of quantities
- **Profit Margin %**: Profit divided by revenue
- **Total Invoices**: Count of distinct invoices
- **Total Customers**: Count of distinct customers
- **Average Order Value**: Revenue per invoice
- **Revenue YoY Growth %**: Year-over-year revenue growth

### Relationships
- Orders ➜ Customers (many-to-one)
- OrderLines ➜ Orders (many-to-one)
- OrderLines ➜ StockItems (many-to-one)
- Orders ➜ People (many-to-one, salesperson)
- Invoices ➜ Customers (many-to-one)
- InvoiceLines ➜ Invoices (many-to-one)
- InvoiceLines ➜ StockItems (many-to-one)
- Invoices ➜ People (many-to-one, salesperson)
- Orders ➜ Calendar (many-to-one, active, bi-directional)
- Invoices ➜ Calendar (many-to-one, inactive)

## Report

The Sales Overview page includes:

1. **KPI Cards** (top row):
   - Total Revenue
   - Total Profit
   - Profit Margin %
   - Total Customers

2. **Revenue Trend by Month** (line chart):
   - Shows revenue trends over time

3. **Top 10 Customers by Revenue** (bar chart):
   - Highlights top customers

4. **Product Sales Performance** (table):
   - Detailed product-level metrics with quantities, revenue, profit, and margin

## Database Connection

The dataset connects to:
- **Server**: sql1.orb.local,1433
- **Database**: WideWorldImporters-Full
- **Authentication**: SQL Server Authentication (credentials stored in Power BI)

## Prerequisites

To open and edit this project, you need:

1. **Power BI Desktop** (latest version)
2. **Enable Preview Features** in Power BI Desktop:
   - Go to: File → Options and settings → Options → Preview features
   - Enable: "Store semantic model using TMDL format"
   - Enable: "Store reports using enhanced metadata format (PBIR)"
3. **Database Access**: Ensure you can connect to sql1.orb.local:1433

## Opening the Project

1. Open Power BI Desktop
2. Go to: File → Open → Browse this folder
3. Navigate to the `WideWorldSales.Report` folder
4. Open the folder as a project (Power BI will recognize it as a PBIR project)
5. When prompted, enter database credentials:
   - Username: lars
   - Password: DevPassword123!

## Editing with VS Code

You can edit TMDL files directly in VS Code:

1. Install the [TMDL extension](https://marketplace.visualstudio.com/items?itemName=analysis-services.TMDL)
2. Open the `WideWorldSales.Dataset` folder in VS Code
3. Navigate to `definition/tables/` to edit table definitions
4. Edit `definition/relationships.tmdl` to modify relationships
5. After saving changes, restart Power BI Desktop to see updates

## Format Benefits

### TMDL (Dataset)
- Human-readable table and relationship definitions
- Git-friendly with clean diffs
- Easy to resolve merge conflicts
- Individual files for each table
- Better for team collaboration

### PBIR (Report)
- Structured JSON files instead of binary
- Better version control
- Easier to review changes
- Individual files for pages and visuals
- Supports external editing

## Next Steps

- Add more measures in `Measures.tmdl`
- Create additional report pages
- Add bookmarks for navigation
- Apply custom themes
- Add more visuals to the Sales Overview page
- Create drill-through pages for detailed analysis

## Resources

- [TMDL Documentation](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-dataset)
- [PBIR Documentation](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-report)
- [Power BI Desktop Projects Overview](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview)
