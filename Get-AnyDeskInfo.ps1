$AnyDeskId = $(& "C:\Program Files (x86)\AnyDesk\AnyDesk.exe" --get-id | Out-String).Trim()
Write-Host "-$AnyDeskId-"

$Hostname = $env:COMPUTERNAME

$Serial = (Get-WmiObject -Query "Select SerialNumber from Win32_BIOS").SerialNumber
$CSystem = Get-WmiObject -Query "Select * from Win32_ComputerSystem"
$CSProd = Get-WmiObject -Query "Select * from Win32_ComputerSystemProduct"

$OutInfo = [PSCustomObject]@{
    AnyDeskID = $AnyDeskId
    Hostname = $env:COMPUTERNAME
    Serial = $Serial
    Manufacturer = $CSystem.Manufacturer
    HWModel = $CSystem.Model
    HWVersion = $CSProd.Version
    }

$OutInfo | Export-Csv C:\Install\AnyDesk.txt -Force -Encoding UTF8 -Delimiter ";" -NoTypeInformation
