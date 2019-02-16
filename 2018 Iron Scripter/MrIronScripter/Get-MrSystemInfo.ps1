#Requires -Version 3.0
function Get-MrSystemInfo {

<#
.SYNOPSIS
    Retrieves information about the operating system, memory, and logical disks from the specified system.
 
.DESCRIPTION
    Get-MrSystemInfo is an advanced function that retrieves information about the operating system, memory,
    and logical disks from the specified system.
 
.PARAMETER CimSession
    Specifies the CIM session to use for this function. Enter a variable that contains the CIM session or a command that
    creates or gets the CIM session, such as the New-CimSession or Get-CimSession cmdlets. For more information, see
    about_CimSessions.

.PARAMETER DriveType
    Specifies the type of drive to query the information for. By default, all drive types are returned, but they can be
    narrowed down to a specific type of drive such as only fixed disks. The parameter autocompletes based on the built-in
    DriveType enumeration. 
 
.EXAMPLE
     Get-MrSystemInfo

.EXAMPLE
     Get-MrSystemInfo -DriveType Fixed

.EXAMPLE
     Get-MrSystemInfo -CimSession (New-CimSession -ComputerName Server01, Server02)

.EXAMPLE
     Get-MrSystemInfo -DriveType Fixed -CimSession (New-CimSession -ComputerName Server01, Server02)
 
.INPUTS
    None
 
.OUTPUTS
    Mr.SystemInfo
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    [OutputType('Mr.SystemInfo')]
    param (
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,

        [System.IO.DriveType]$DriveType
    )

    $Params = @{
        ErrorAction = 'SilentlyContinue'
        ErrorVariable = 'Problem'
    }

    if ($PSBoundParameters.CimSession) {
        $Params.CimSession = $CimSession
    }

    $OSInfo = Get-CimInstance @Params -ClassName Win32_OperatingSystem -Property CSName, Caption, Version, ServicePackMajorVersion, ServicePackMinorVersion,
                                                 Manufacturer, WindowsDirectory, Locale, FreePhysicalMemory, TotalVirtualMemorySize, FreeVirtualMemory
    
    $ReleaseId = Invoke-CimMethod @Params -Namespace root\cimv2 -ClassName StdRegProv -MethodName GetSTRINGvalue -Arguments @{
                 hDefKey=[uint32]2147483650; sSubKeyName='SOFTWARE\Microsoft\Windows NT\CurrentVersion'; sValueName='ReleaseId'}

    if ($PSBoundParameters.DriveType) {
        $Params.Filter = "DriveType = $($DriveType.value__)" 
    }

    $LogicalDisk = Get-CimInstance @Params -ClassName Win32_LogicalDisk -Property SystemName, DeviceID, Description, Size, FreeSpace, Compressed

    foreach ($OS in $OSInfo) {
    
        foreach ($Disk in $LogicalDisk | Where-Object SystemName -eq $OS.CSName) {
            if (-not $PSBoundParameters.CimSession) {
                $ReleaseId.PSComputerName = $OS.CSName
            }

            [pscustomobject]@{
                ComputerName = $OS.CSName
                OSName = $OS.Caption
                OSVersion = $OS.Version
                ReleaseId = ($ReleaseId | Where-Object PSComputerName -eq $OS.CSName).sValue
                ServicePackMajorVersion = $OS.ServicePackMajorVersion
                ServicePackMinorVersion = $OS.ServicePackMinorVersion
                OSManufacturer = $OS.Manufacturer
                WindowsDirectory = $OS.WindowsDirectory
                Locale = [int]"0x$($OS.Locale)"
                AvailablePhysicalMemory = $OS.FreePhysicalMemory
                TotalVirtualMemory = $OS.TotalVirtualMemorySize
                AvailableVirtualMemory = $OS.FreeVirtualMemory
                Drive = $Disk.DeviceID
                DriveType = $Disk.Description
                Size = $Disk.Size
                FreeSpace = $Disk.FreeSpace
                Compressed = $Disk.Compressed
                PSTypeName = 'Mr.SystemInfo'
            }
    
        }
    
    }

    foreach ($p in $Problem) {
        Write-Warning -Message "An error occurred on $($p.OriginInfo). $($p.Exception.Message)"
    }

}