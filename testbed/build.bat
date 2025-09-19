REM Build script for the testbed
@ECHO OFF
SETLOCAL EnableDelayedExpansion

SET BINDIR=..\bin
SET VERSION_FILE=src\version.odin

REM Check if we're in the right directory and adjust accordingly
IF "%CD:~-7%" == "testbed" (
    REM Running from testbed directory - continue
    ECHO Running from testbed directory
) ELSE IF "%CD:~-10%" == "kohi-odin" (
    REM Running from project root - change to testbed
    ECHO Running from project root, changing to testbed directory
    CD testbed
    IF ERRORLEVEL 1 (
        ECHO Failed to change directory to testbed
        EXIT /B 1
    )
) ELSE IF "%CD:~-6%" == "engine" (
    REM Running from engine directory - go up then into testbed
    ECHO Running from engine directory, changing to testbed
    CD ..
    CD testbed
    IF ERRORLEVEL 1 (
        ECHO Failed to change directory to testbed
        EXIT /B 1
    )
) ELSE (
    ECHO Working directory is invalid: %CD%
    ECHO Please run this script from the main project folder, engine folder, or the testbed folder.
    EXIT /B 1
)

REM Check if version file exists
IF NOT EXIST "%VERSION_FILE%" (
    ECHO Error: Version file "%VERSION_FILE%" not found in %CD%
    EXIT /B 1
)

REM Extract version numbers (using APP_ prefix to match your file)
FOR /F "tokens=4" %%A IN ('FINDSTR "APP_VERSION" "%VERSION_FILE%" 2^>nul') DO SET "MAJORVER=%%A"
FOR /F "tokens=4" %%A IN ('FINDSTR "APP_SUBVERSION" "%VERSION_FILE%" 2^>nul') DO SET "SUBVER=%%A"
FOR /F "tokens=4" %%A IN ('FINDSTR "APP_REVISION" "%VERSION_FILE%" 2^>nul') DO SET "REVVER=%%A"

REM Validate version numbers
IF "%MAJORVER%"=="" (
    ECHO Error: Could not extract a valid number for APP_VERSION
    EXIT /B 1
)
IF "%SUBVER%"=="" (
    ECHO Error: Could not extract a valid number for APP_SUBVERSION
    EXIT /B 1
)
IF "%REVVER%"=="" (
    ECHO Error: Could not extract a valid number for APP_REVISION
    EXIT /B 1
)

REM Create bin directory if it doesn't exist
IF NOT EXIST "%BINDIR%" (
    ECHO Creating bin folder
    MKDIR "%BINDIR%" >nul
) ELSE (
    ECHO bin folder found
)

REM Version update menu
ECHO.
ECHO Select which version number to update for this compilation:
ECHO 1^) MAJOR_VERSION
ECHO 2^) SUB_VERSION
ECHO 3^) REVISION
ECHO 4^) NO_UPDATE
ECHO.

SET /P choice="Please select option (1-4): "

IF "%choice%"=="1" (
    SET /A MAJORVER+=1
    SET SUBVER=0
    SET REVVER=0
    CALL :UPDATE_VERSION_FILE
    ECHO Updated to MAJOR version %MAJORVER%.%SUBVER%.%REVVER%
) ELSE IF "%choice%"=="2" (
    SET /A SUBVER+=1
    SET REVVER=0
    CALL :UPDATE_VERSION_FILE
    ECHO Updated to SUB version %MAJORVER%.%SUBVER%.%REVVER%
) ELSE IF "%choice%"=="3" (
    SET /A REVVER+=1
    CALL :UPDATE_VERSION_FILE
    ECHO Updated to REVISION %MAJORVER%.%SUBVER%.%REVVER%
) ELSE IF "%choice%"=="4" (
    ECHO No version update selected.
) ELSE (
    ECHO INVALID OPTION. PLEASE TRY AGAIN
    EXIT /B 1
)

ECHO.
ECHO Building testbed.exe version %MAJORVER%.%SUBVER%.%REVVER%
ECHO.

SET assembly=testbed
SET buildFlags=-build-mode:exe -debug -pdb-name:"../bin/testbed.pdb"
SET outputFlag=-out:"../bin/testbed.exe"

ECHO "Building %assembly% with flags: %buildFlags%"
odin build "./src" %buildFlags% %outputFlag%

IF ERRORLEVEL 1 (
    ECHO Build failed!
    EXIT /B 1
) ELSE (
    ECHO Done.
)

GOTO :EOF

:UPDATE_VERSION_FILE
REM Create a temporary file with updated version numbers
(
FOR /F "delims=" %%A IN (%VERSION_FILE%) DO (
    SET "line=%%A"
    IF "!line!" == "APP_VERSION: u8 = !MAJORVER!" (
        ECHO APP_VERSION: u8 = %MAJORVER%
    ) ELSE IF "!line:APP_VERSION: u8 =!" NEQ "!line!" (
        ECHO APP_VERSION: u8 = %MAJORVER%
    ) ELSE IF "!line:APP_SUBVERSION: u8 =!" NEQ "!line!" (
        ECHO APP_SUBVERSION: u8 = %SUBVER%
    ) ELSE IF "!line:APP_REVISION: u16 =!" NEQ "!line!" (
        ECHO APP_REVISION: u16 = %REVVER%
    ) ELSE (
        ECHO !line!
    )
)
) > "%VERSION_FILE%.tmp"

MOVE "%VERSION_FILE%.tmp" "%VERSION_FILE%" >nul
GOTO :EOF