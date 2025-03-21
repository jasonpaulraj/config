@echo off
setlocal enabledelayedexpansion

:: Backup Configuration
set SOURCE_DIR=E:\WebDevelopment
set DESTINATION_DIR=D:\Backups\group\WebDevelopment
set BACKUP_NAME=backup_webdevelopment_hourly
set LOG_DIR=D:\Backups\core\logs
set COMPRESSION_LEVEL=9

:: Get source directory size before backup
for /f "tokens=3" %%a in ('dir /-c "%SOURCE_DIR%" ^| findstr "File(s)"') do set SOURCE_SIZE=%%a
set SOURCE_SIZE_MB=%SOURCE_SIZE:~0,-3%.%SOURCE_SIZE:~-3,2% MB

:: Calculate estimated compressed sizes based on compression level
set /a SIZE_LEVEL1=%SOURCE_SIZE% * 65 / 100
set /a SIZE_LEVEL5=%SOURCE_SIZE% * 45 / 100
set /a SIZE_LEVEL9=%SOURCE_SIZE% * 35 / 100
set SIZE_LEVEL1_MB=%SIZE_LEVEL1:~0,-3%.%SIZE_LEVEL1:~-3,2% MB
set SIZE_LEVEL5_MB=%SIZE_LEVEL5:~0,-3%.%SIZE_LEVEL5:~-3,2% MB
set SIZE_LEVEL9_MB=%SIZE_LEVEL9:~0,-3%.%SIZE_LEVEL9:~-3,2% MB

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
set GZIP_LOG_FILE=%LOG_DIR%\%BACKUP_NAME%_gzip_%TIMESTAMP%.txt

:: Create log file with proper path
echo %date% %time% - Backup started > "%MAIN_LOG_FILE%"

:: Display compression information in a pretty format
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                   COMPRESSION LEVEL INFORMATION                 ║
echo ╠════════════════════════════════════════════════════════════════╣
echo ║ Source Directory Size: %-43s ║
echo ╠════════════════════════════════════════════════════════════════╣
echo ║ Level 1: Fastest      - ~65%% of original size                  ║
echo ║          Estimated size: %-39s ║
echo ╠════════════════════════════════════════════════════════════════╣
echo ║ Level 5: Balanced     - ~45%% of original size (default)        ║
echo ║          Estimated size: %-39s ║
echo ╠════════════════════════════════════════════════════════════════╣
echo ║ Level 9: Best         - ~35%% of original size (slowest)        ║
echo ║          Estimated size: %-39s ║
echo ╚════════════════════════════════════════════════════════════════╝

:: Log compression information
echo ===== COMPRESSION LEVEL INFORMATION ===== >> "%MAIN_LOG_FILE%"
echo Source Directory Size: %SOURCE_SIZE_MB% >> "%MAIN_LOG_FILE%"
echo Level 1: Fastest - ~65%% of original size - Estimated: %SIZE_LEVEL1_MB% >> "%MAIN_LOG_FILE%"
echo Level 5: Balanced - ~45%% of original size (default) - Estimated: %SIZE_LEVEL5_MB% >> "%MAIN_LOG_FILE%"
echo Level 9: Best - ~35%% of original size (slowest) - Estimated: %SIZE_LEVEL9_MB% >> "%MAIN_LOG_FILE%"
echo. >> "%MAIN_LOG_FILE%"

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
echo Compression Level: %COMPRESSION_LEVEL% >> "%MAIN_LOG_FILE%"
echo. >> "%MAIN_LOG_FILE%"

:: Set the output archive name
set ARCHIVE_NAME=%BACKUP_DIR%\%BACKUP_NAME%_%TIMESTAMP%.tar.gz

:: Check if 7-Zip is installed
where 7z >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %date% %time% - 7-Zip not found in PATH, checking common installation locations... >> "%MAIN_LOG_FILE%"
    
    :: Check common installation paths
    set "FOUND_7ZIP="
    if exist "C:\Program Files\7-Zip\7z.exe" (
        set "FOUND_7ZIP=C:\Program Files\7-Zip\7z.exe"
    ) else if exist "C:\Program Files (x86)\7-Zip\7z.exe" (
        set "FOUND_7ZIP=C:\Program Files (x86)\7-Zip\7z.exe"
    )
    
    if defined FOUND_7ZIP (
        echo %date% %time% - Found 7-Zip at: %FOUND_7ZIP% >> "%MAIN_LOG_FILE%"
        echo Found 7-Zip at: %FOUND_7ZIP%
    ) else (
        echo %date% %time% - WARNING: 7-Zip not found. Attempting to use PowerShell for compression... >> "%MAIN_LOG_FILE%"
        echo WARNING: 7-Zip not found. Attempting to use PowerShell for compression...
        
        :: Use PowerShell as fallback
        set USE_POWERSHELL=1
    )
) else (
    set "FOUND_7ZIP=7z"
)

:: Perform the backup using either 7-Zip or PowerShell for compression
echo %date% %time% - Creating compressed backup >> "%MAIN_LOG_FILE%"

if defined USE_POWERSHELL (
    :: PowerShell compression method
    echo %date% %time% - Using PowerShell for compression >> "%MAIN_LOG_FILE%"
    echo %date% %time% - Command: PowerShell -Command "Compress-Archive -Path '%SOURCE_DIR%\*' -DestinationPath '%BACKUP_DIR%\%BACKUP_NAME%_%TIMESTAMP%.zip' -CompressionLevel Optimal" >> "%MAIN_LOG_FILE%"
    
    PowerShell -Command "Compress-Archive -Path '%SOURCE_DIR%\*' -DestinationPath '%BACKUP_DIR%\%BACKUP_NAME%_%TIMESTAMP%.zip' -CompressionLevel Optimal" > "%GZIP_LOG_FILE%" 2>&1
    set COMPRESS_EXIT=%ERRORLEVEL%
    set ARCHIVE_NAME=%BACKUP_DIR%\%BACKUP_NAME%_%TIMESTAMP%.zip
) else (
    :: 7-Zip compression method
    echo %date% %time% - Using 7-Zip for compression >> "%MAIN_LOG_FILE%"
    echo %date% %time% - Command: 7z a -ttar -so "%SOURCE_DIR%" | 7z a -si -tgzip -mx=%COMPRESSION_LEVEL% "%ARCHIVE_NAME%" >> "%MAIN_LOG_FILE%"

:: Create a temporary batch file to capture the output
set TEMP_BATCH=%TEMP%\gzip_backup_%RANDOM%.bat
echo @echo off > "%TEMP_BATCH%"
echo 7z a -ttar -so "%SOURCE_DIR%" ^| 7z a -si -tgzip -mx=%COMPRESSION_LEVEL% "%ARCHIVE_NAME%" ^> "%GZIP_LOG_FILE%" 2^>^&1 >> "%TEMP_BATCH%"
echo exit /b %%ERRORLEVEL%% >> "%TEMP_BATCH%"

:: Run the temporary batch file
call "%TEMP_BATCH%"
set GZIP_EXIT=%ERRORLEVEL%
del "%TEMP_BATCH%"

echo. >> "%MAIN_LOG_FILE%"
echo 7-Zip compression completed with exit code: %GZIP_EXIT% >> "%MAIN_LOG_FILE%"

:: Check if compression was successful
if %GZIP_EXIT% NEQ 0 (
    echo %date% %time% - ERROR: Compression failed with exit code %GZIP_EXIT% >> "%MAIN_LOG_FILE%"
    echo ERROR: Compression failed. See log file for details: "%MAIN_LOG_FILE%"
    goto :cleanup
)

:: Get the size of the compressed file
for /f "tokens=3" %%a in ('dir "%ARCHIVE_NAME%" ^| findstr /r /c:"[0-9] File(s)"') do set ARCHIVE_SIZE=%%a
set ARCHIVE_SIZE_MB=%ARCHIVE_SIZE:~0,-3%.%ARCHIVE_SIZE:~-3,2% MB

:: Calculate actual compression ratio
set /a RATIO=ARCHIVE_SIZE*100/SOURCE_SIZE
echo %date% %time% - Original size: %SOURCE_SIZE_MB% >> "%MAIN_LOG_FILE%"
echo %date% %time% - Compressed size: %ARCHIVE_SIZE_MB% >> "%MAIN_LOG_FILE%"
echo %date% %time% - Actual compression ratio: %RATIO%%% of original size >> "%MAIN_LOG_FILE%"

echo Backup completed at %time% on %date% >> "%MAIN_LOG_FILE%"
echo GZip log file created at: %GZIP_LOG_FILE% >> "%MAIN_LOG_FILE%"

:cleanup
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