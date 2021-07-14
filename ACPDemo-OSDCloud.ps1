# ACP Demo OSDCloud Add-On
Write-Host "Starting ACP Demo OS-Deployment"
Start-Sleep -Seconds 5

Uninstall-Module OSD -Force -AllVersions
Install-Module OSD -Force
Import-Module OSD -Force

Start-OSDCloud -OSBuild 21H1 -OSLanguage de-de -OSEdition Enterprise -ZTI


# Create Install Folder
New-Item "C:\Install" -ItemType Directory -ErrorAction SilentlyContinue

# Create Install-CMD-File
$('@echo off') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force

# Integrate VMWare Tools
    $UserName = "testlab\OSDCloud"
    $PlainPassword = "TestlabOSD21"
    $SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
    $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
    New-PSDrive -NAME Z -PSprovider Filesystem -root '\\172.19.68.12\OSDCloud' -Credential $Credentials
    Copy-Item -Path Z:\Install\VMWare -Destination C:\Install\VMWare -Container -Recurse
    Remove-PSDrive -Name Z -Force
# Add Install to CMD
    $('echo Installing VMWare Tools') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
    $('"%~dp0VMWare\setup64.exe" /s /v"/qb REBOOT=REALLYSUPPRESS"') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
    $('echo VMWare Setup Errorocode: %ERRORLEVEL%') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
    $('TIMEOUT /T 15') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append

# Download AnyDesk
    $OutFile = "C:\Install\AnyDesk.exe"
    $Source = "https://download.anydesk.com/AnyDesk.exe"
    & curl.exe --location --output $OutFile --url $Source
# Add Install to CMD
    $('echo Installing AnyDesk') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
    $('"%~dp0AnyDesk.exe" --install "%ProgramFiles(x86)%\AnyDesk" --start-with-win --silent --create-shortcuts --update-disabled') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
    $('echo AnyDesk Setup Errorocode: %ERRORLEVEL%') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
    $('TIMEOUT /T 5') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
# Add Anydesk Password Config
    $('echo ACPdemo21 | "%ProgramFiles(x86)%\AnyDesk\anydesk.exe" --set-password') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
    $('echo AnyDesk Password Errorocode: %ERRORLEVEL%') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append
    $('TIMEOUT /T 5') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append

# finish Install-CMD-File
    $('echo.') | Out-File -FilePath "C:\Install\01.Install.cmd" -Encoding utf8 -Force -Append


# Add Command to Unattend.xml
    $Panther = 'C:\Windows\Panther'
    $UnattendPath = "$Panther\Invoke-OSDSpecialize.xml"
    [XML]$Unattend = Get-Content -Path $UnattendPath

    $SpecializePass = $Unattend.unattend.settings | Where pass -eq "specialize"
    $WinDeployComponent = $SpecializePass.component | where name -eq "Microsoft-Windows-Deployment"

    $ExisitingRun = $WinDeployComponent.RunSynchronous.RunSynchronousCommand
    If ( $ExisitingRun.GetType().Name -eq "XmlElement" ) {
        $NewEntry = $ExisitingRun.CloneNode($true)
        $NewEntry.Order = [string]$([int]$($ExisitingRun | Sort Order -Descending).Order + 1).ToString()
    }
    ElseIf ( $ExisitingRun1.GetType().BaseType.Name -eq "Array" ) {
        $NewEntry = $ExisitingRun[0].CloneNode($true)
        $NewEntry.Order = [string]$([int]$($ExisitingRun | Sort Order -Descending)[0].Order + 1).ToString()
    }
    $NewEntry.Description = "Run Custom Installs $($NewEntry.Order)"
    $NewEntry.Path = "cmd /c c:\Install\01.install.cmd"
    $WinDeployComponent.RunSynchronous.AppendChild($NewEntry)

    $NewUnattend = "C:\temp\OSDCloud\Customizations\unattend_1.xml"
    $Unattend.Save($UnattendPath)

# Customization finished

Write-Host "Finished OS Installation - Rebooting in 60 Seconds"
Start-Sleep -Seconds 60
wpeutil reboot