# pscheck
Simple script to capture information about processes with PowerShell.

```
Usage:
pscheck.ps1 [-SearchProcess] <ProcessName> [-OutFile]
            [-CaptureNew] [-AllInfo]
            

[-SearchProcess] Searches a process by name, if 'all'
                 it's used as the name of the process or left empty
                 it checks for every running process
[-CaptureNew]  Captures all running processes since it's execution
[-AllInfo] Can be used with CaptureNew to display all information
[-OutFile] Can be used with -SearchProcess to create a file with the output
```
