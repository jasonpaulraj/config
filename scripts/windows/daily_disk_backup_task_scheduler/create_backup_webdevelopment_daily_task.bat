@echo off
echo Creating backup task with wake computer option...

:: Create a temporary XML file for the task
echo ^<?xml version="1.0" encoding="UTF-16"?^> > task.xml
echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^> >> task.xml
echo   ^<RegistrationInfo^> >> task.xml
echo     ^<Description^>Daily WebDevelopment Backup^</Description^> >> task.xml
echo   ^</RegistrationInfo^> >> task.xml
echo   ^<Triggers^> >> task.xml
echo     ^<CalendarTrigger^> >> task.xml
echo       ^<StartBoundary^>2025-03-21T03:00:00^</StartBoundary^> >> task.xml
echo       ^<Enabled^>true^</Enabled^> >> task.xml
echo       ^<ScheduleByDay^> >> task.xml
echo         ^<DaysInterval^>1^</DaysInterval^> >> task.xml
echo       ^</ScheduleByDay^> >> task.xml
echo     ^</CalendarTrigger^> >> task.xml
echo   ^</Triggers^> >> task.xml
echo   ^<Principals^> >> task.xml
echo     ^<Principal id="Author"^> >> task.xml
echo       ^<LogonType^>InteractiveToken^</LogonType^> >> task.xml
echo       ^<RunLevel^>HighestAvailable^</RunLevel^> >> task.xml
echo     ^</Principal^> >> task.xml
echo   ^</Principals^> >> task.xml
echo   ^<Settings^> >> task.xml
echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^> >> task.xml
echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^> >> task.xml
echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^> >> task.xml
echo     ^<AllowHardTerminate^>true^</AllowHardTerminate^> >> task.xml
echo     ^<StartWhenAvailable^>true^</StartWhenAvailable^> >> task.xml
echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^> >> task.xml
echo     ^<IdleSettings^> >> task.xml
echo       ^<StopOnIdleEnd^>true^</StopOnIdleEnd^> >> task.xml
echo       ^<RestartOnIdle^>false^</RestartOnIdle^> >> task.xml
echo     ^</IdleSettings^> >> task.xml
echo     ^<AllowStartOnDemand^>true^</AllowStartOnDemand^> >> task.xml
echo     ^<Enabled^>true^</Enabled^> >> task.xml
echo     ^<Hidden^>false^</Hidden^> >> task.xml
echo     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^> >> task.xml
echo     ^<WakeToRun^>true^</WakeToRun^> >> task.xml
echo     ^<ExecutionTimeLimit^>PT72H^</ExecutionTimeLimit^> >> task.xml
echo     ^<Priority^>7^</Priority^> >> task.xml
echo   ^</Settings^> >> task.xml
echo   ^<Actions Context="Author"^> >> task.xml
echo     ^<Exec^> >> task.xml
echo       ^<Command^>D:\Backups\core\backup_webdevelopment_daily.bat^</Command^> >> task.xml
echo     ^</Exec^> >> task.xml
echo   ^</Actions^> >> task.xml
echo ^</Task^> >> task.xml

:: Import the XML task definition
schtasks /create /tn "backup_webdevelopment_daily" /xml task.xml /f

:: Check if task was created successfully
if %ERRORLEVEL% equ 0 (
    echo Task created successfully with wake computer option enabled.
) else (
    echo Failed to create task. Error code: %ERRORLEVEL%
)

:: Clean up the temporary XML file
del task.xml

exit