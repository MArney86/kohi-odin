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

REM Create bin directory if it doesn't exist
IF NOT EXIST "%BINDIR%" (
    ECHO Creating bin folder
    MKDIR "%BINDIR%" >nul
) ELSE (
    ECHO bin folder found
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