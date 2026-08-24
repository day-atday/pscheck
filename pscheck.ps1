<#
.SYNOPSIS
    Simple script to capture information about processes with PowerShell.
.PARAMETER SearchProcess
    Search a process by name, 
.PARAMETER process_name
    The name of the process to capture, if 'all' it's used or left empty it checks for every running process
.PARAMETER CaptureNew
    Captures all running processes since it's execution
.PARAMETER AllInfo
    Can be used with CaptureNew to display all information
.PARAMETER OutFile
    Can be used with -SearchProcess to create a file with the output
.LINK
    https://github.com/day-atday/pscheck
.EXAMPLE
    pscheck.ps1 [-SearchProcess] <ProcessName> [-OutFile]
                [-CaptureNew] [-AllInfo]
#>

param(
    [switch]$SearchProcess,
    [string]$process_name,
    [switch]$CaptureNew,
    [switch]$AllInfo,
    [switch]$OutFile
)

function get_processinfo{
    param(
        [string]$process_name,
        [switch]$AllProcess
    )

    $processes = Get-Process
    $IsRunning = $processes | Where-Object {$_.Name -eq $process_name}

    if($process_name -ieq "all" -or [string]::IsNullOrEmpty($process_name)){
        $IsRunning = $processes
    }

    $HasService = Get-CimInstance Win32_Service |
        Where-Object {$_.PathName -like "*$($process_name)*"} |
        Select-Object PathName, State, Name, Description


    $wmiProcesses = Get-CimInstance Win32_Process

    $tcpConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue |
        Where-Object {$_.State -eq "Established"}

    $info_ToProcess = [PSCustomObject]@{
        IsRunning   = [bool]$IsRunning
        HasService  = [bool]$HasService
        ServicePath = $HasService.PathName

        Processes = $IsRunning | ForEach-Object {
            $Id = $_.Id

            $wmiProcess = $wmiProcesses |
                Where-Object {$_.ProcessId -eq $Id}

            $tcpconnection = $tcpConnections |
                Where-Object {$_.OwningProcess -eq $Id} |
                Select-Object RemoteAddress, RemotePort, LocalAddress, LocalPort

            [PSCustomObject]@{
                ProcessName   = $_.ProcessName
                Id            = $Id
                CommandLine   = $wmiProcess.CommandLine
                TCPConnection = $tcpconnection 
            }
        }
    }

    return $info_ToProcess
}

function capture_NewProcess{
    Write-Host -ForegroundColor Yellow "Waiting for new processes... `n[CTRL+C TO EXIT]"

    $process_IdKeys = @{}

    foreach ($process in Get-Process) {
        $process_IdKeys[$process.Id] = $true
    }
    
    while ($true) {

        $new_processes = Get-Process

        foreach ($process in $new_processes) {

            if ($process_IdKeys.ContainsKey($process.Id)) {
                continue
            }

            $process_IdKeys[$process.Id] = $true

            if($AllInfo){
                get_processinfo -process_name $process.Name | Format-List * -Force
            }
            else{
                Write-Host -Foreground yellow "`n[Name] $($process.Name) "
                Write-Host -NoNewline -ForegroundColor yellow "[PID] $($process.Id)`n"
            }

            Start-Sleep -Seconds 1
        }
    }
}
function process_info{
    param(
        [PSCustomObject]$info_ToProcess,
        [switch]$ToTerminal
    )
    $info = $info_ToProcess | Select-Object * -ExcludeProperty Processes | Format-List * -Force 
    $info_processes = $info_ToProcess.Processes | Select-Object * | Format-List * -Force
    
    
    if($OutFile){
        $path = "$($PSScriptRoot)\$($process_name).txt"
        $info | Out-File $path
        $info_processes >> $path
    }

    $info
    $info_processes
    return
}

try {
    if($SearchProcess){

        $info_ToProcess = get_processinfo -process_name $process_name
        process_info $info_ToProcess
    }
    elseif($CaptureNew){
        capture_NewProcess
    }

}    

catch {
    Write-Warning $_
}


