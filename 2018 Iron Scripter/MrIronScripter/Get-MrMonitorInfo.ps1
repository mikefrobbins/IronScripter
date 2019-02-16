#Requires -Version 4.0
function Get-MrMonitorInfo {

<#
.SYNOPSIS
    Retrieves information about the monitors connected to the specified system.
 
.DESCRIPTION
    Get-MrMonitorInfo is an advanced function that retrieves information about the monitors
    connected to the specified system.
 
.PARAMETER CimSession
    Specifies the CIM session to use for this function. Enter a variable that contains the CIM session or a command that
    creates or gets the CIM session, such as the New-CimSession or Get-CimSession cmdlets. For more information, see
    about_CimSessions.
 
.EXAMPLE
     Get-MrMonitorInfo

.EXAMPLE
     Get-MrMonitorInfo -CimSession (New-CimSession -ComputerName Server01, Server02)
 
.INPUTS
    None
 
.OUTPUTS
    Mr.MonitorInfo
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    [OutputType('Mr.MonitorInfo')]
    param (
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession
    )

    $Params = @{
        ErrorAction = 'SilentlyContinue'
        ErrorVariable = 'Problem'
    }

    if ($PSBoundParameters.CimSession) {
        $Params.CimSession = $CimSession
    }

    $ComputerInfo = Get-CimInstance @Params -ClassName Win32_ComputerSystem -Property Name, Manufacturer, Model
    $BIOS = Get-CimInstance @Params -ClassName Win32_BIOS -Property SerialNumber
    $Monitors = Get-CimInstance @Params -ClassName WmiMonitorID -Namespace root/WMI -Property ManufacturerName, UserFriendlyName, ProductCodeID, SerialNumberID, WeekOfManufacture, YearOfManufacture

    foreach ($Computer in $ComputerInfo) {
        
        foreach ($Monitor in $Monitors | Where-Object {-not $_.PSComputerName -or $_.PSComputerName -eq $Computer.Name}) {

            if (-not $PSBoundParameters.CimSession) {
                
                Write-Verbose -Message "Running against the local system. Setting value for PSComputerName (a read-only property) to $env:COMPUTERNAME."
                ($BIOS.GetType().GetField('_CimSessionComputerName','static,nonpublic,instance')).SetValue($BIOS,$Computer.Name)

            }

            [pscustomobject]@{
                ComputerName = $Computer.Name
                ComputerManufacturer = $Computer.Manufacturer
                ComputerModel = $Computer.Model
                ComputerSerial = ($BIOS | Where-Object PSComputerName -eq $Computer.Name).SerialNumber
                MonitorManufacturer = -join $Monitor.ManufacturerName.ForEach({[char]$_})
                MonitorModel = -join $Monitor.UserFriendlyName.ForEach({[char]$_})
                ProductCode = -join $Monitor.ProductCodeID.ForEach({[char]$_})
                MonitorSerial = -join $Monitor.SerialNumberID.ForEach({[char]$_})
                MonitorManufactureWeek = $Monitor.WeekOfManufacture
                MonitorManufactureYear = $Monitor.YearOfManufacture
                PSTypeName = 'Mr.MonitorInfo'
            }
                
        }
    
    }
    
    foreach ($p in $Problem) {
        Write-Warning -Message "An error occurred on $($p.OriginInfo). $($p.Exception.Message)"
    }

}