@echo off
setlocal enabledelayedexpansion

:: ======================================================
:: Backup Configuration
:: ======================================================
set SOURCE_DIR=E:\Wallpapers
set DESTINATION_DIR=D:\Backups\group\Wallpapers
set BACKUP_NAME=gzip_backup_wallpapers_daily
set LOG_DIR=D:\Backups\core\logs
set COMPRESSION_LEVEL=9
set WEBHOOK_URL=https://webhook-test.com/bd90d0a224b6a800ce87b9d6b2a4f564
set MAX_BACKUPS=7
set MAX_LOGS=30
set BACKUP_DIR=%DESTINATION_DIR%

:: ======================================================
:: Setup Log Files and Timestamps
:: ======================================================
:: Set up log directory
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%" 2>nul
    if not exist "%LOG_DIR%" (
        echo [!] Warning: Could not create log directory. Using script directory instead.
        set LOG_DIR=%~dp0
    )
)

:: Create a simple timestamp (date only)
set TIMESTAMP=%date:~10,4%%date:~4,2%%date:~7,2%

:: Set archive name AFTER timestamp is defined
set ARCHIVE_NAME=%BACKUP_DIR%\%BACKUP_NAME%_%TIMESTAMP%.7z

:: Set up log files
set MAIN_LOG_FILE=%LOG_DIR%\%BACKUP_NAME%_%TIMESTAMP%.txt
set GZIP_LOG_FILE=%LOG_DIR%\%BACKUP_NAME%_gzip_%TIMESTAMP%.txt

:: Helper function to log to both console and file
call :log "Backup started" "▶️"

:: Log compression information
call :log_file "===== COMPRESSION LEVEL INFORMATION =====" ""
call :log_file "Source Directory Size: %SOURCE_SIZE_MB%" ""
call :log_file "Level 1: Fastest - ~65%% of original size - Estimated: %SIZE_LEVEL1_MB%" ""
call :log_file "Level 5: Balanced - ~45%% of original size (default) - Estimated: %SIZE_LEVEL5_MB%" ""
call :log_file "Level 9: Best - ~35%% of original size (slowest) - Estimated: %SIZE_LEVEL9_MB%" ""
call :log_file "" ""

:: ======================================================
:: Verify Directories
:: ======================================================
if not exist "%SOURCE_DIR%" (
    call :log "WARNING: Source directory does not exist: %SOURCE_DIR%" "⚠️"
    call :log "Attempting to create source directory..." "🔄"
    mkdir "%SOURCE_DIR%" 2>nul
    if not exist "%SOURCE_DIR%" (
        call :log "CRITICAL: Failed to create source directory. Continuing but backup may fail." "❌"
        call :send_webhook "CRITICAL" "Failed to create source directory: %SOURCE_DIR%"
    ) else (
        call :log "Created source directory successfully." "✅"
    )
)

if not exist "%DESTINATION_DIR%" (
    call :log "WARNING: Destination directory does not exist: %DESTINATION_DIR%" "⚠️"
    call :log "Attempting to create destination directory..." "🔄"
    mkdir "%DESTINATION_DIR%" 2>nul
    if not exist "%DESTINATION_DIR%" (
        call :log "CRITICAL: Failed to create destination directory. Continuing but backup may fail." "❌"
        call :send_webhook "CRITICAL" "Failed to create destination directory: %DESTINATION_DIR%"
    ) else (
        call :log "Created destination directory successfully." "✅"
    )
)

:: Log the timestamp
call :log "Created timestamp for backup folder: %TIMESTAMP%" "🕒"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
:: Log the backup directory creation
call :log "Created backup directory: %BACKUP_DIR%" "📁"

:: ======================================================
:: Backup Process
:: ======================================================
:: Log the backup process
call :log_file "===== Backup Process Started =====" ""
call :log_file "Starting backup at %time% on %date%" ""
call :log_file "Source: %SOURCE_DIR%" ""
call :log_file "Destination: %BACKUP_DIR%" ""
call :log_file "Compression Level: %COMPRESSION_LEVEL%" ""
call :log_file "" ""

:: Check if 7-Zip is installed
call :log "Checking for 7-Zip installation..." "🔍"

:: Check for 7-Zip in Program Files
set "SEVENZIP_PATH="
if exist "C:\Program Files\7-Zip\7z.exe" (
    set "SEVENZIP_PATH=C:\Program Files\7-Zip\7z.exe"
) else if exist "C:\Program Files (x86)\7-Zip\7z.exe" (
    set "SEVENZIP_PATH=C:\Program Files (x86)\7-Zip\7z.exe"
)

if not defined SEVENZIP_PATH (
    call :log "ERROR: 7-Zip not found. Please install 7-Zip." "❌"
    call :send_webhook "ERROR" "7-Zip not found. Backup failed."
    goto :cleanup_and_exit
) else (
    call :log "7-Zip found at: %SEVENZIP_PATH%" "✅"
)

:: Create the archive
call :log "Creating backup archive..." "🔄"
call :log "Archive name: %ARCHIVE_NAME%" "📦"

:: First, delete any existing archive with the same name to avoid update issues
if exist "%ARCHIVE_NAME%" (
    call :log "Removing existing archive with same name" "🗑️"
    del "%ARCHIVE_NAME%" > nul 2>&1
)

:: Display progress message to console
call :log "Running 7-Zip compression (this may take a while)..." "🔄"

:: Run 7-Zip with solid mode for better compression
"%SEVENZIP_PATH%" a -t7z -mx=%COMPRESSION_LEVEL% -ms=on "%ARCHIVE_NAME%" "%SOURCE_DIR%\*.*" -r

:: Log completion and capture the error level
set COMPRESSION_ERROR=%ERRORLEVEL%
call :log "7-Zip compression completed with exit code: %COMPRESSION_ERROR%" "📦"

:: Check if backup was successful
if %COMPRESSION_ERROR% EQU 0 (
    call :log "Backup completed successfully" "✅"
    
    :: Get archive size
    for %%A in ("%ARCHIVE_NAME%") do set ARCHIVE_SIZE=%%~zA
    set /a ARCHIVE_SIZE_MB=%ARCHIVE_SIZE% / 1048576
    set /a ARCHIVE_SIZE_KB=(%ARCHIVE_SIZE% %% 1048576) / 1024
    
    call :log "Archive size: %ARCHIVE_SIZE_MB%.%ARCHIVE_SIZE_KB% MB" "📊"
    
    :: Get source directory size first (fix for missing SOURCE_SIZE)
    set SOURCE_SIZE=0
    for /f "tokens=3" %%a in ('dir /s /a "%SOURCE_DIR%" ^| findstr "File(s)"') do set SOURCE_SIZE=%%a
    
    :: Convert source size to MB for display
    set /a SOURCE_SIZE_MB=%SOURCE_SIZE% / 1048576
    set /a SOURCE_SIZE_KB=(%SOURCE_SIZE% %% 1048576) / 1024
    call :log "Source directory size: %SOURCE_SIZE_MB%.%SOURCE_SIZE_KB% MB" "📊"
    
    :: Calculate compression ratio (with error handling)
    if %SOURCE_SIZE% NEQ 0 (
        set /a COMPRESSION_PERCENT=(%ARCHIVE_SIZE% * 100) / %SOURCE_SIZE%
        set /a SAVINGS_PERCENT=100 - %COMPRESSION_PERCENT%
        call :log "Compression ratio: %COMPRESSION_PERCENT%%% of original size (saved %SAVINGS_PERCENT%%% space)" "📉"
    ) else (
        call :log "Could not calculate compression ratio - source size is zero or unknown" "⚠️"
    )
    
    call :send_webhook "SUCCESS" "Backup completed successfully. Archive size: %ARCHIVE_SIZE_MB%.%ARCHIVE_SIZE_KB% MB (saved %SAVINGS_PERCENT%%% space)"
) else (
    call :log "Backup failed with error code: %COMPRESSION_ERROR%" "❌"
    type "%GZIP_LOG_FILE%" >> "%MAIN_LOG_FILE%"
    call :send_webhook "ERROR" "Backup failed with error code: %COMPRESSION_ERROR%"
)

:: Clean up old backups
call :log "Cleaning up old backups..." "🧹"
call :cleanup_old_files "%BACKUP_DIR%" "%BACKUP_NAME%_*.7z" %MAX_BACKUPS%
call :cleanup_old_files "%BACKUP_DIR%" "%BACKUP_NAME%_*.zip" %MAX_BACKUPS%
call :cleanup_old_files "%LOG_DIR%" "%BACKUP_NAME%_*.txt" %MAX_LOGS%
call :cleanup_old_files "%LOG_DIR%" "%BACKUP_NAME%_gzip_*.txt" %MAX_LOGS%

call :log "Backup process completed" "🏁"
goto :eof

:: ======================================================
:: Helper Functions
:: ======================================================
:log
:: Parameters: %1=message, %2=icon
setlocal
set "MESSAGE=%~1"
set "ICON=%~2"
echo %date% %time% - %MESSAGE%
echo %date% %time% - %ICON% %MESSAGE% >> "%MAIN_LOG_FILE%"
endlocal
goto :eof

:log_file
:: Parameters: %1=message, %2=icon (only logs to file)
setlocal
set "MESSAGE=%~1"
set "ICON=%~2"
echo %MESSAGE% >> "%MAIN_LOG_FILE%"
endlocal
goto :eof

:send_webhook
:: Parameters: %1=status, %2=message
setlocal
set "STATUS=%~1"
set "MESSAGE=%~2"
set "PAYLOAD={\"status\":\"%STATUS%\",\"message\":\"%MESSAGE%\",\"timestamp\":\"%date%\",\"backup_name\":\"%BACKUP_NAME%\"}"

call :log "Sending webhook notification..." "📡"
curl -s -X POST -H "Content-Type: application/json" -d "%PAYLOAD%" "%WEBHOOK_URL%"
if %ERRORLEVEL% EQU 0 (
    call :log "Webhook notification sent" "✅"
) else (
    call :log "Failed to send webhook notification" "⚠️"
)
endlocal
goto :eof

:cleanup_old_files
:: Parameters: %1=directory, %2=file pattern, %3=max files to keep
setlocal
set "DIR=%~1"
set "PATTERN=%~2"
set "MAX_KEEP=%~3"

call :log "Cleaning up old files matching %PATTERN% in %DIR%, keeping %MAX_KEEP% newest" "🧹"

:: Count files
set "COUNT=0"
for /f %%F in ('dir /b /o-d "%DIR%\%PATTERN%" 2^>nul ^| find /c /v ""') do set COUNT=%%F

call :log "Found %COUNT% files matching pattern" "📊"

if %COUNT% LEQ %MAX_KEEP% (
    call :log "No cleanup needed, fewer than %MAX_KEEP% files exist" "✅"
    goto :cleanup_end
)

:: Calculate how many to delete
set /a DELETE_COUNT=%COUNT%-%MAX_KEEP%
call :log "Will delete %DELETE_COUNT% oldest files" "🗑️"

:: Delete oldest files
set "DELETED=0"
for /f "skip=%MAX_KEEP% delims=" %%F in ('dir /b /o-d "%DIR%\%PATTERN%" 2^>nul') do (
    if !DELETED! LSS %DELETE_COUNT% (
        call :log "Deleting: %%F" "🗑️"
        del "%DIR%\%%F" > nul 2>&1
        set /a DELETED+=1
    )
)

call :log "Deleted %DELETED% old files" "✅"

:cleanup_end
endlocal
goto :eof

:cleanup_and_exit
call :log "Exiting script due to errors" "🛑"
endlocal
exit /b 1
