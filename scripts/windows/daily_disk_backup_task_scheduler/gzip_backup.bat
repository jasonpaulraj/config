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

:: Create a simple timestamp (simpler method)
set TIMESTAMP=%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%
set TIMESTAMP=%TIMESTAMP: =0%

:: Set up log files
set MAIN_LOG_FILE=%LOG_DIR%\%BACKUP_NAME%_%TIMESTAMP%.txt
set GZIP_LOG_FILE=%LOG_DIR%\%BACKUP_NAME%_gzip_%TIMESTAMP%.txt

:: Create log file with proper path
echo %date% %time% - ▶️ Backup started > "%MAIN_LOG_FILE%"

:: Log compression information
echo ===== COMPRESSION LEVEL INFORMATION ===== >> "%MAIN_LOG_FILE%"
echo Source Directory Size: %SOURCE_SIZE_MB% >> "%MAIN_LOG_FILE%"
echo Level 1: Fastest - ~65%% of original size - Estimated: %SIZE_LEVEL1_MB% >> "%MAIN_LOG_FILE%"
echo Level 5: Balanced - ~45%% of original size (default) - Estimated: %SIZE_LEVEL5_MB% >> "%MAIN_LOG_FILE%"
echo Level 9: Best - ~35%% of original size (slowest) - Estimated: %SIZE_LEVEL9_MB% >> "%MAIN_LOG_FILE%"
echo. >> "%MAIN_LOG_FILE%"

:: ======================================================
:: Verify Directories
:: ======================================================
if not exist "%SOURCE_DIR%" (
    echo %date% %time% - ⚠️ WARNING: Source directory does not exist: %SOURCE_DIR% >> "%MAIN_LOG_FILE%"
    echo %date% %time% - 🔄 Attempting to create source directory... >> "%MAIN_LOG_FILE%"
    mkdir "%SOURCE_DIR%" 2>nul
    if not exist "%SOURCE_DIR%" (
        echo %date% %time% - ❌ CRITICAL: Failed to create source directory. Continuing but backup may fail. >> "%MAIN_LOG_FILE%"
        call :send_webhook "CRITICAL" "Failed to create source directory: %SOURCE_DIR%"
    ) else (
        echo %date% %time% - ✅ Created source directory successfully. >> "%MAIN_LOG_FILE%"
    )
)

if not exist "%DESTINATION_DIR%" (
    echo %date% %time% - ⚠️ WARNING: Destination directory does not exist: %DESTINATION_DIR% >> "%MAIN_LOG_FILE%"
    echo %date% %time% - 🔄 Attempting to create destination directory... >> "%MAIN_LOG_FILE%"
    mkdir "%DESTINATION_DIR%" 2>nul
    if not exist "%DESTINATION_DIR%" (
        echo %date% %time% - ❌ CRITICAL: Failed to create destination directory. Continuing but backup may fail. >> "%MAIN_LOG_FILE%"
        call :send_webhook "CRITICAL" "Failed to create destination directory: %DESTINATION_DIR%"
    ) else (
        echo %date% %time% - ✅ Created destination directory successfully. >> "%MAIN_LOG_FILE%"
    )
)

:: Log the timestamp
echo %date% %time% - 🕒 Created timestamp for backup folder: %TIMESTAMP% >> "%MAIN_LOG_FILE%"

:: Create backup directory with timestamp
set BACKUP_DIR=%DESTINATION_DIR%\%BACKUP_NAME%_%TIMESTAMP%
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
:: Log the backup directory creation
echo %date% %time% - 📁 Created backup directory: %BACKUP_DIR% >> "%MAIN_LOG_FILE%"

:: ======================================================
:: Backup Process
:: ======================================================
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
:: Check if 7-Zip is installed
echo %date% %time% - 🔍 Checking for 7-Zip installation... >> "%MAIN_LOG_FILE%"
where 7z >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %date% %time% - 🔍 7-Zip not found in PATH, checking common installation locations... >> "%MAIN_LOG_FILE%"
    
    :: Check common installation paths
    set "FOUND_7ZIP="
    if exist "C:\Program Files\7-Zip\7z.exe" (
        set "FOUND_7ZIP=C:\Program Files\7-Zip\7z.exe"
    ) else if exist "C:\Program Files (x86)\7-Zip\7z.exe" (
        set "FOUND_7ZIP=C:\Program Files (x86)\7-Zip\7z.exe"
    )
    
    if defined FOUND_7ZIP (
        echo %date% %time% - ✅ Found 7-Zip at: %FOUND_7ZIP% >> "%MAIN_LOG_FILE%"
        echo ✅ Found 7-Zip at: %FOUND_7ZIP%
    ) else (
        echo %date% %time% - ⚠️ WARNING: 7-Zip not found. Attempting to install it... >> "%MAIN_LOG_FILE%"
        echo ⚠️ WARNING: 7-Zip not found. Attempting to install it...
        
        :: Try to install 7-Zip using PowerShell and Chocolatey
        echo %date% %time% - 🔄 Checking if Chocolatey is installed... >> "%MAIN_LOG_FILE%"
        
        :: Check if Chocolatey is installed
        if not exist "%ALLUSERSPROFILE%\chocolatey\bin\choco.exe" (
            echo %date% %time% - 🔄 Installing Chocolatey... >> "%MAIN_LOG_FILE%"
            echo 🔄 Installing Chocolatey...
            
            :: Create a temporary batch file to run PowerShell with admin rights
            set "TEMP_INSTALL=%TEMP%\install_choco_%RANDOM%.bat"
            echo @echo off > "%TEMP_INSTALL%"
            echo setlocal >> "%TEMP_INSTALL%"
            echo echo Installing Chocolatey... >> "%TEMP_INSTALL%"
            echo powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" >> "%TEMP_INSTALL%"
            echo exit /b %%ERRORLEVEL%% >> "%TEMP_INSTALL%"
            
            :: Run the temporary batch file with admin privileges
            echo %date% %time% - 🔄 Requesting admin privileges to install Chocolatey... >> "%MAIN_LOG_FILE%"
            echo 🔄 Requesting admin privileges to install Chocolatey...
            powershell -Command "Start-Process -FilePath '%TEMP_INSTALL%' -Verb RunAs -Wait"
            del "%TEMP_INSTALL%"
            
            :: Check if Chocolatey was installed
            if not exist "%ALLUSERSPROFILE%\chocolatey\bin\choco.exe" (
                echo %date% %time% - ❌ ERROR: Failed to install Chocolatey. Falling back to direct 7-Zip download... >> "%MAIN_LOG_FILE%"
                echo ❌ ERROR: Failed to install Chocolatey. Falling back to direct 7-Zip download...
                goto :direct_7zip_download
            )
        )
        
        :: Install 7-Zip using Chocolatey
        echo %date% %time% - 🔄 Installing 7-Zip using Chocolatey... >> "%MAIN_LOG_FILE%"
        echo 🔄 Installing 7-Zip using Chocolatey...
        
        :: Create a temporary batch file to run Chocolatey with admin rights
        set "TEMP_INSTALL=%TEMP%\install_7zip_%RANDOM%.bat"
        echo @echo off > "%TEMP_INSTALL%"
        echo setlocal >> "%TEMP_INSTALL%"
        echo echo Installing 7-Zip... >> "%TEMP_INSTALL%"
        echo "%ALLUSERSPROFILE%\chocolatey\bin\choco.exe" install 7zip -y >> "%TEMP_INSTALL%"
        echo exit /b %%ERRORLEVEL%% >> "%TEMP_INSTALL%"
        
        :: Run the temporary batch file with admin privileges
        powershell -Command "Start-Process -FilePath '%TEMP_INSTALL%' -Verb RunAs -Wait"
        del "%TEMP_INSTALL%"
        
        :: Check if 7-Zip was installed
        if exist "C:\Program Files\7-Zip\7z.exe" (
            set "FOUND_7ZIP=C:\Program Files\7-Zip\7z.exe"
            echo %date% %time% - ✅ Successfully installed 7-Zip at: %FOUND_7ZIP% >> "%MAIN_LOG_FILE%"
            echo ✅ Successfully installed 7-Zip at: %FOUND_7ZIP%
        ) else if exist "C:\Program Files (x86)\7-Zip\7z.exe" (
            set "FOUND_7ZIP=C:\Program Files (x86)\7-Zip\7z.exe"
            echo %date% %time% - ✅ Successfully installed 7-Zip at: %FOUND_7ZIP% >> "%MAIN_LOG_FILE%"
            echo ✅ Successfully installed 7-Zip at: %FOUND_7ZIP%
        ) else (
            echo %date% %time% - ❌ ERROR: Failed to install 7-Zip using Chocolatey. Falling back to direct download... >> "%MAIN_LOG_FILE%"
            echo ❌ ERROR: Failed to install 7-Zip using Chocolatey. Falling back to direct download...
            goto :direct_7zip_download
        )
    )
) else (
    set "FOUND_7ZIP=7z"
    echo %date% %time% - ✅ 7-Zip found in PATH >> "%MAIN_LOG_FILE%"
)

goto :perform_backup

:direct_7zip_download
:: Direct download of 7-Zip portable
echo %date% %time% - 🔄 Downloading 7-Zip portable version... >> "%MAIN_LOG_FILE%"
echo 🔄 Downloading 7-Zip portable version...

:: Create a directory for 7-Zip portable
set "SEVENZIP_DIR=%~dp0\7zip_portable"
if not exist "%SEVENZIP_DIR%" mkdir "%SEVENZIP_DIR%"

:: Download 7-Zip using PowerShell
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://www.7-zip.org/a/7z2201-x64.exe', '%SEVENZIP_DIR%\7z_setup.exe')"
if not exist "%SEVENZIP_DIR%\7z_setup.exe" (
    echo %date% %time% - ❌ ERROR: Failed to download 7-Zip. Using built-in Windows compression... >> "%MAIN_LOG_FILE%"
    echo ❌ ERROR: Failed to download 7-Zip. Using built-in Windows compression...
    set USE_POWERSHELL=1
) else (
    :: Extract the portable version
    echo %date% %time% - 🔄 Extracting 7-Zip portable... >> "%MAIN_LOG_FILE%"
    echo 🔄 Extracting 7-Zip portable...
    
    :: Use PowerShell to extract the 7-Zip self-extracting archive
    powershell -Command "Start-Process -FilePath '%SEVENZIP_DIR%\7z_setup.exe' -ArgumentList '/S', '/D=%SEVENZIP_DIR%' -Wait"
    
    if exist "%SEVENZIP_DIR%\7z.exe" (
        set "FOUND_7ZIP=%SEVENZIP_DIR%\7z.exe"
        echo %date% %time% - ✅ Successfully extracted 7-Zip portable to: %SEVENZIP_DIR% >> "%MAIN_LOG_FILE%"
        echo ✅ Successfully extracted 7-Zip portable to: %SEVENZIP_DIR%
    ) else (
        echo %date% %time% - ❌ ERROR: Failed to extract 7-Zip portable. Using built-in Windows compression... >> "%MAIN_LOG_FILE%"
        echo ❌ ERROR: Failed to extract 7-Zip portable. Using built-in Windows compression...
        set USE_POWERSHELL=1
    )
)

:perform_backup
:: Perform the backup using either 7-Zip or PowerShell for compression
echo %date% %time% - 🔄 Creating compressed backup >> "%MAIN_LOG_FILE%"

if defined USE_POWERSHELL (
    :: PowerShell compression method (Windows built-in)
    echo %date% %time% - 🔄 Using PowerShell for compression >> "%MAIN_LOG_FILE%"
    echo 🔄 Using PowerShell for compression
    echo %date% %time% - Command: PowerShell -Command "Compress-Archive -Path '%SOURCE_DIR%\*' -DestinationPath '%BACKUP_DIR%\%BACKUP_NAME%_%TIMESTAMP%.zip' -CompressionLevel Optimal" >> "%MAIN_LOG_FILE%"
    
    :: Create a temporary batch file to run PowerShell without admin rights
    set "TEMP_COMPRESS=%TEMP%\compress_%RANDOM%.bat"
    echo @echo off > "%TEMP_COMPRESS%"
    echo PowerShell -Command "Compress-Archive -Path '%SOURCE_DIR%\*' -DestinationPath '%BACKUP_DIR%\%BACKUP_NAME%_%TIMESTAMP%.zip' -CompressionLevel Optimal" > "%GZIP_LOG_FILE%" 2>&1 >> "%TEMP_COMPRESS%"
    echo exit /b %%ERRORLEVEL%% >> "%TEMP_COMPRESS%"
    
    call "%TEMP_COMPRESS%"
    set COMPRESS_EXIT=%ERRORLEVEL%
    del "%TEMP_COMPRESS%"
    
    set ARCHIVE_NAME=%BACKUP_DIR%\%BACKUP_NAME%_%TIMESTAMP%.zip
) else (
    :: 7-Zip compression method
    echo %date% %time% - 🔄 Using 7-Zip for compression >> "%MAIN_LOG_FILE%"
    echo 🔄 Using 7-Zip for compression
    
    :: Use a simpler approach - just create a zip file directly
    echo %date% %time% - Command: "%FOUND_7ZIP%" a -tzip -mx=%COMPRESSION_LEVEL% "%BACKUP_DIR%\%BACKUP_NAME%_%TIMESTAMP%.zip" "%SOURCE_DIR%\*" >> "%MAIN_LOG_FILE%"
    
    :: Create a temporary batch file to run 7-Zip
    set "TEMP_COMPRESS=%TEMP%\compress_%RANDOM%.bat"
    echo @echo off > "%TEMP_COMPRESS%"
    echo "%FOUND_7ZIP%" a -tzip -mx=%COMPRESSION_LEVEL% "%BACKUP_DIR%\%BACKUP_NAME%_%TIMESTAMP%.zip" "%SOURCE_DIR%\*" > "%GZIP_LOG_FILE%" 2>&1 >> "%TEMP_COMPRESS%"
    echo exit /b %%ERRORLEVEL%% >> "%TEMP_COMPRESS%"
    
    call "%TEMP_COMPRESS%"
    set COMPRESS_EXIT=%ERRORLEVEL%
    del "%TEMP_COMPRESS%"
    
    set ARCHIVE_NAME=%BACKUP_DIR%\%BACKUP_NAME%_%TIMESTAMP%.zip
    
    echo. >> "%MAIN_LOG_FILE%"
    echo %date% %time% - 7-Zip compression completed with exit code: %COMPRESS_EXIT% >> "%MAIN_LOG_FILE%"
)

:: Check if compression was successful
if %COMPRESS_EXIT% NEQ 0 (
    echo %date% %time% - ❌ ERROR: Compression failed with exit code %COMPRESS_EXIT% >> "%MAIN_LOG_FILE%"
    echo ❌ ERROR: Compression failed. See log file for details: "%MAIN_LOG_FILE%"
    call :send_webhook "ERROR" "Backup compression failed with exit code %COMPRESS_EXIT%"
    goto :cleanup
)

:: ======================================================
:: Verify Backup Success
:: ======================================================
:: Check if the archive was created
if not exist "%ARCHIVE_NAME%" (
    echo %date% %time% - ❌ ERROR: Archive file was not created: %ARCHIVE_NAME% >> "%MAIN_LOG_FILE%"
    echo ❌ ERROR: Archive file was not created. See log file for details: "%MAIN_LOG_FILE%"
    call :send_webhook "ERROR" "Backup archive was not created: %ARCHIVE_NAME%"
    goto :cleanup
