:: WRITTEN BY: BEN STOUT & BRIAN GRADIN
:: SPU BITLOCKED HARD DRIVE UNLOCKING UTILITY
:: RECOVERY CERTIFICATE MUST BE LOCATED IN SAME FOLDER TO INSTALL

@echo off

setlocal enabledelayedexpansion

:: Permissions
::--------------------------------------
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
Echo Requesting administrative privileges...
goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
Echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
Echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"

"%temp%\getadmin.vbs"

Exit /B

:gotAdmin
if exist "%temp%\getadmin.vbs" ( Del "%temp%\getadmin.vbs" )
Pushd "%CD%"
CD /D "%~dp0"
::--------------------------------------

cls

:: Input drive letter
:input

set inp=
set /p inp=Enter drive letter: 

IF "%inp%"=="" (
    cls
    echo Incorrect drive letter
    echo.
    goto input
)
IF x%inp::=%==x%inp% (
    set inp=%inp%:
)

:: Check if the drive exists
FOR /F "tokens=*" %%A IN ('manage-bde -status %inp%') DO (
    FOR /F "tokens=*" %%B in ('echo %%A ^| find /c "could not be opened by BitLocker."') DO (
        IF "%%B"=="1" (
	    cls
	    echo There was an error opening the specified drive.
	    echo Make sure the drive is connected.
    	    echo.
	    goto input
	)
    )
)

:: Check if the drive is already unlocked
FOR /F "tokens=*" %%A IN ('manage-bde -status %inp%') DO (
    FOR /F "tokens=*" %%B in ('echo %%A ^| find /c "Unlocked"') DO (
        IF "%%B"=="1" (
	    cls
	    echo This drive is already unlocked.
	    echo.
    	    goto repeat
	)
    )
)

:: Unlock the drive
:unlock
FOR /F "tokens=*" %%A IN ('manage-bde -unlock %inp% -certificate -ct fcf438661b3c7c0dd4527f33b37bd9201425ed04') DO (
    FOR /F "tokens=*" %%B in ('echo %%A ^| find /c "successfully unlocked"') DO (
        IF "%%B"=="1" (
	    echo.
	    echo The drive was successfully unlocked!
	    echo.
	    set /p dr=Open the drive? [y/n]:
	    IF "!dr!"=="y" explorer %inp%
	)
    )
    FOR /F "tokens=*" %%B in ('echo %%A ^| find /c "ERROR: The certificate failed"') DO (
	:: Install the certificate
        IF "%%B"=="1" (
	    echo.
	    set /p pass=SPUAdmin password:
	    @certutil -user –f –p !pass! –importpfx "%~dp0\Data Recovery Certificate.pfx"
	    goto unlock
	)
    )
)

echo.

:: Unlock multiple drives?
:repeat
set /p rpt=Unlock another drive? [y/n]:

IF "%rpt%"=="y" (
    cls
    goto input
)