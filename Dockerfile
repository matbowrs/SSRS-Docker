FROM mcr.microsoft.com/windows/servercore:ltsc2019

LABEL Name=SSRS2019 Version=0.0.2 Maintainer="Matthew Bowers"

ENV ssrsInstallerLocation "https://download.microsoft.com/download/1/a/a/1aaa9177-3578-4931-b8f3-373b24f63342/SQLServerReportingServices.exe"

ENV sa_password="_" \
    attach_dbs="[]" \
    ACCEPT_EULA="_" \
    sa_password_path="C:\ProgramData\Docker\secrets\sa-password" \
    ssrs_user="_" \
    ssrs_password="_" \
    SSRS_edition="Dev" \
    ssrs_password_path="C:\ProgramData\Docker\secrets\ssrs-password"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# make install files accessible
COPY start.ps1 /
COPY SQLServer2019-DEV-x64-ENU.box /
COPY SQLServer2019-DEV-x64-ENU.exe /

WORKDIR /

RUN  Invoke-WebRequest -Uri $env:ssrsInstallerLocation -OutFile SQLServerReportingServices.exe ; \
    Start-Process -Wait -FilePath .\SQLServerReportingServices.exe -ArgumentList "/quiet", "/norestart", "/IAcceptLicenseTerms", "/Edition=$env:SSRS_edition" -PassThru -Verbose

# Set the default command to run your start script
#CMD ["powershell", "-File", "C:\start.ps1"]