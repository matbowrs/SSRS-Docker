# start.ps1
$ErrorActionPreference = 'Stop'

Write-Host "Starting SQL Server installation process..."

# Extract SQL Server files if not already extracted
if (!(Test-Path "C:\SQLServer2019-DEV-x64-ENU")) {
    Write-Host "Extracting SQL Server files..."
    Start-Process -FilePath ".\SQLServer2019-DEV-x64-ENU.exe" -ArgumentList "/ACTION=Extract", "/Q", "/IACCEPTSQLSERVERLICENSETERMS", "/HIDECONSOLE", "/MEDIAPATH=C:\SQLInstall" -Wait -PassThru
}

# Install SQL Server if not already installed
if (!(Get-Service -Name MSSQLSERVER -ErrorAction SilentlyContinue)) {
    Write-Host "Installing SQL Server..."
    try {
        Set-Location "C:\SQLServer2019-DEV-x64-ENU"
        $setupProcess = Start-Process -FilePath ".\setup.exe" `
            -ArgumentList "/Q", "/IACCEPTSQLSERVERLICENSETERMS", "/ACTION=Install", "/FEATURES=SQLEngine", 
                         "/INSTANCENAME=MSSQLSERVER", "/SQLSYSADMINACCOUNTS=BUILTIN\Administrators",
                         "/SECURITYMODE=SQL", "/SAPWD=YourStrongPassword123!" `
            -Wait -PassThru -NoNewWindow
        Set-Location "C:\"
        
        if ($setupProcess.ExitCode -ne 0) {
            Write-Host "Error: SQL Server installation failed with exit code $($setupProcess.ExitCode)"
            exit 1
        }
    } catch {
        Write-Host "Error during installation: $_"
        exit 1
    }
}

# Wait for a moment to ensure services are registered
Start-Sleep -Seconds 10

# Check SQL Server service status
$maxRetries = 3
$retryCount = 0
$sqlService = $null

while ($retryCount -lt $maxRetries) {
    try {
        $sqlService = Get-Service -Name MSSQLSERVER
        Write-Host "SQL Server Service Status: $($sqlService.Status)"
        
        if ($sqlService.Status -ne 'Running') {
            Write-Host "Starting SQL Server service..."
            Start-Service MSSQLSERVER
            Start-Sleep -Seconds 30
        }
        break
    } catch {
        $retryCount++
        Write-Host "Attempt $retryCount to get SQL Server service status failed. Retrying..."
        Start-Sleep -Seconds 10
    }
}

if ($retryCount -eq $maxRetries) {
    Write-Host "Failed to get SQL Server service status after $maxRetries attempts"
    exit 1
}

# Verify SQL Server version
try {
    $sqlcmd = "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"
    $query = "SELECT @@VERSION"
    $result = & $sqlcmd -S localhost -Q $query
    Write-Host "SQL Server Version:"
    Write-Host $result
} catch {
    Write-Host "Error verifying SQL Server version: $_"
    exit 1
}

# Check Reporting Services
$reportingServices = Get-Service | Where-Object {$_.Name -like "*Reporting*"}
Write-Host "Reporting Services Status:"
$reportingServices | Format-Table Name, Status, DisplayName

# configure ssrs reporting services
try {
    # Get SSRS WMI object
    $rsConfig = Get-WmiObject -Namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v15\Admin" -Class "MSReportServer_ConfigurationSetting"
    
    # Generate database creation script
    Write-Host "Generating SSRS database script..."
    $result = $rsConfig.GenerateDatabaseCreationScript(
        "ReportServer",  # Database Name
        1033            # LCID
    )
    
    if ($result.Error -eq 0) {
        Write-Host "Database script generated successfully"
        # Save the script to a file and execute it
        $script = $result.Script
        Write-Host "Creating temporary SQL file..."
        $script | Out-File -FilePath "C:\CreateReportServerDB.sql" -Encoding UTF8
        
        Write-Host "Executing database creation script..."
        & $sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -i "C:\CreateReportServerDB.sql"
        
        # Clean up the temporary file
        Remove-Item "C:\CreateReportServerDB.sql"
    }

    # Set database connection
    Write-Host "Setting database connection..."
    $result = $rsConfig.SetDatabaseConnection(
        "localhost",      # Server Name
        "ReportServer",   # Database Name
        2,               # Authentication Type (2 for SQL Authentication)
        "sa",            # Username
        "YourStrongPassword123!"  # Password
    )

    # Configure URLs
    Write-Host "Configuring SSRS URLs..."
    $result = $rsConfig.ReserveURL("ReportServerWebService", "http://+:8080", 1033)
    $result = $rsConfig.ReserveURL("ReportManager", "http://+:8081", 1033)

    # Set virtual directories
    Write-Host "Configuring virtual directories..."
    $result = $rsConfig.SetVirtualDirectory("ReportServer", "ReportServer", 1033)
    $result = $rsConfig.SetVirtualDirectory("Reports", "Reports", 1033)

    Write-Host "SSRS Configuration completed successfully"
    
    # Display configured URLs
    Write-Host "SSRS Web Service URL: http://localhost:8080/ReportServer"
    Write-Host "SSRS Web Portal URL: http://localhost:8081/Reports"

    Write-Host "Restarting SQLServerReportingServices..."
    Restart-Service SQLServerReportingServices
} catch {
    Write-Host "Error configuring SSRS: $_"
    exit 1
}