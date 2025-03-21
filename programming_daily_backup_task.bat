@echo off
setlocal enabledelayedexpansion

:: Configuration - Change these variables
set SOURCE_DIR=E:\WebDevelopment\projects
set DESTINATION_DIR=D:\Backups
set BACKUP_NAME=ProjectsBackup

:: Create timestamp for the backup folder (format: YYYY-MM-DD)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%

:: Create backup directory with timestamp
set BACKUP_DIR=%DESTINATION_DIR%\%BACKUP_NAME%_%TIMESTAMP%
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo Starting backup at %time% on %date%
echo Source: %SOURCE_DIR%
echo Destination: %BACKUP_DIR%

:: Perform the backup using robocopy (more reliable than xcopy)
robocopy "%SOURCE_DIR%" "%BACKUP_DIR%" /E /ZB /R:3 /W:10 /MT:16 /LOG:"%BACKUP_DIR%\backup_log.txt"

echo Backup completed at %time% on %date%
echo Log file created at: %BACKUP_DIR%\backup_log.txt

:: Optional: Keep only the last 7 backups (remove this section if you want to keep all backups)
echo Cleaning up old backups...
set count=0
for /f "tokens=*" %%A in ('dir /b /ad /o-d "%DESTINATION_DIR%\%BACKUP_NAME%_*"') do (
    set /a count+=1
    if !count! GTR 7 (
        echo Removing old backup: %DESTINATION_DIR%\%%A
        rd /s /q "%DESTINATION_DIR%\%%A"
    )
)

echo Backup process completed successfully.
pause