FROM mcr.microsoft.com/windows/servercore:ltsc2019

ENV ACCEPT_EULA=Y \
   SA_PASSWORD="YourStrongP@ssw0rd" \
   SSRS_USER="SSRSAdmin" \
   SSRS_PASSWORD="StrongP@ssw0rd123!" \
   SSRS_DOWNLOAD_URL="https://download.microsoft.com/download/1/a/a/1aaa9177-3578-4931-b8f3-373b24f63342/SQLServerReportingServices.exe"

# Install SQL Server with SQLPS
RUN powershell -Command \
   Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?LinkId=2216019" -OutFile sqlserver.exe; \
   Start-Process -Wait -FilePath .\sqlserver.exe -ArgumentList /ENU, /IAcceptSQLServerLicenseTerms, /Quiet, /Action=install, /InstanceName=MSSQLSERVER, /Features=SQLEngine,Tools, /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM", /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS", /TCPENABLED=1; \
   Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; \
   Install-Module -Name SqlServer -Force -AllowClobber; \
   Remove-Item sqlserver.exe

# Install SQLCMD
RUN powershell -Command \
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
   Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2142258" -OutFile sqlcmd.msi; \
   Start-Process -Wait -FilePath msiexec -ArgumentList "/i", "sqlcmd.msi", "/qn", "IACCEPTMSSQLCMDLICENSETEREMS=YES"; \
   Remove-Item sqlcmd.msi; \
   setx /M PATH $($Env:PATH + ';C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn')

# Install SSRS
RUN powershell -Command \
   Invoke-WebRequest -Uri $env:SSRS_DOWNLOAD_URL -OutFile ssrs.exe; \
   Start-Process -Wait -FilePath .\ssrs.exe -ArgumentList "/quiet", "/norestart", "/IAcceptLicenseTerms", "/Edition=Dev" -PassThru; \
   Stop-Service 'SQLServerReportingServices' -Force -ErrorAction SilentlyContinue; \
   Remove-Item ssrs.exe

COPY start.ps1 /
COPY configureSSRS.ps1 /
COPY newadmin.ps1 /
COPY sqlstart.ps1 /

RUN powershell -Command ./start.ps1 -sa_password $env:SA_PASSWORD -ACCEPT_EULA $env:ACCEPT_EULA -ssrs_user $env:SSRS_USER -ssrs_password $env:SSRS_PASSWORD -Verbose

EXPOSE 80

CMD powershell -Command \
   Start-Service MSSQLSERVER; \
   Start-Service SQLServerReportingServices; \
   while ($true) { Start-Sleep -Seconds 3600 }