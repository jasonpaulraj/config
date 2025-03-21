@echo off
setlocal enabledelayedexpansion

:: Backup Configuration
set SOURCE_DIR=E:\WebDevelopment
set DESTINATION_DIR=D:\Backups\group\WebDevelopment
set BACKUP_NAME=backup_webdevelopment_hourly
set LOG_DIR=D:\Backups\core\logs

:: Set up log directory
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%" 2>nul
    if not exist "%LOG_DIR%" (
        echo Warning: Could not create log directory. Using script directory instead.
        set LOG_DIR=%~dp0
    )
)

:: Create a simple timestamp (simpler method)
set TIMESTAMP=%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%
set TIMESTAMP=%TIMESTAMP: =0%

:: Set up log files
set MAIN_LOG_FILE=%LOG_DIR%\%BACKUP_NAME%_%TIMESTAMP%.txt
set ROBOCOPY_LOG_FILE=%LOG_DIR%\%BACKUP_NAME%_robocopy_%TIMESTAMP%.txt

:: Create log file with proper path
echo %date% %time% - Backup started > "%MAIN_LOG_FILE%"

:: Verify directories exist
if not exist "%SOURCE_DIR%" (
    echo %date% %time% - WARNING: Source directory does not exist: %SOURCE_DIR% >> "%MAIN_LOG_FILE%"
    echo %date% %time% - Attempting to create source directory... >> "%MAIN_LOG_FILE%"
    mkdir "%SOURCE_DIR%" 2>nul
    if not exist "%SOURCE_DIR%" (
        echo %date% %time% - CRITICAL: Failed to create source directory. Continuing but backup may fail. >> "%MAIN_LOG_FILE%"
    ) else (
        echo %date% %time% - Created source directory successfully. >> "%MAIN_LOG_FILE%"
    )
)

if not exist "%DESTINATION_DIR%" (
    echo %date% %time% - WARNING: Destination directory does not exist: %DESTINATION_DIR% >> "%MAIN_LOG_FILE%"
    echo %date% %time% - Attempting to create destination directory... >> "%MAIN_LOG_FILE%"
    mkdir "%DESTINATION_DIR%" 2>nul
    if not exist "%DESTINATION_DIR%" (
        echo %date% %time% - CRITICAL: Failed to create destination directory. Continuing but backup may fail. >> "%MAIN_LOG_FILE%"
    ) else (
        echo %date% %time% - Created destination directory successfully. >> "%MAIN_LOG_FILE%"
    )
)

:: Log the timestamp
echo %date% %time% - Created timestamp for backup folder: %TIMESTAMP% >> "%MAIN_LOG_FILE%"

:: Create backup directory with timestamp
set BACKUP_DIR=%DESTINATION_DIR%\%BACKUP_NAME%_%TIMESTAMP%
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
:: Log the backup directory creation
echo %date% %time% - Created backup directory: %BACKUP_DIR% >> "%MAIN_LOG_FILE%"

:: Log the backup process
echo ===== Backup Process Started ===== >> "%MAIN_LOG_FILE%"
echo Starting backup at %time% on %date% >> "%MAIN_LOG_FILE%"
echo Source: %SOURCE_DIR% >> "%MAIN_LOG_FILE%"
echo Destination: %BACKUP_DIR% >> "%MAIN_LOG_FILE%"
echo. >> "%MAIN_LOG_FILE%"

:: Perform the backup using robocopy (more reliable than xcopy)
echo %date% %time% - Running robocopy command >> "%MAIN_LOG_FILE%"
echo %date% %time% - Command: robocopy "%SOURCE_DIR%" "%BACKUP_DIR%" /E /R:3 /W:10 /MT:16 /LOG:"%ROBOCOPY_LOG_FILE%" >> "%MAIN_LOG_FILE%"

:: Run robocopy with a separate log file to avoid overwriting the main log
robocopy "%SOURCE_DIR%" "%BACKUP_DIR%" /E /R:3 /W:10 /MT:16 /LOG:"%ROBOCOPY_LOG_FILE%"
set ROBOCOPY_EXIT=%ERRORLEVEL%

echo. >> "%MAIN_LOG_FILE%"
echo Robocopy completed with exit code: %ROBOCOPY_EXIT% >> "%MAIN_LOG_FILE%"
echo Backup completed at %time% on %date% >> "%MAIN_LOG_FILE%"
echo Robocopy log file created at: %ROBOCOPY_LOG_FILE% >> "%MAIN_LOG_FILE%"

:: Optional: Keep only the last 7 backups
echo. >> "%MAIN_LOG_FILE%"
echo Cleaning up old backups... >> "%MAIN_LOG_FILE%"
set count=0
for /f "tokens=*" %%A in ('dir /b /ad /o-d "%DESTINATION_DIR%\%BACKUP_NAME%_*"') do (
    set /a count+=1
    if !count! GTR 7 (
        echo Removing old backup: %DESTINATION_DIR%\%%A >> "%MAIN_LOG_FILE%"
        rd /s /q "%DESTINATION_DIR%\%%A"
    )
)

:: Optional: Keep only the last 30 log files
echo. >> "%MAIN_LOG_FILE%"
echo Cleaning up old log files... >> "%MAIN_LOG_FILE%"
set count=0
for /f "tokens=*" %%A in ('dir /b /o-d "%LOG_DIR%\%BACKUP_NAME%_*.txt"') do (
    set /a count+=1
    if !count! GTR 30 (
        echo Removing old log file: %LOG_DIR%\%%A >> "%MAIN_LOG_FILE%"
        del /q "%LOG_DIR%\%%A"
    )
)

echo. >> "%MAIN_LOG_FILE%"
echo ===== Backup Process Completed Successfully ===== >> "%MAIN_LOG_FILE%"

:: Display output for interactive runs but also log everything
echo ===== Backup Process Completed Successfully =====
echo See log file for details: "%MAIN_LOG_FILE%"