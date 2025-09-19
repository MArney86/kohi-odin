REM Build script for engine
@ECHO OFF
SETLOCAL EnableDelayedExpansion

SET BINDIR=..\bin
SET VERSION_FILE=src\core\version.odin

REM Check if we're in the right directory
IF "%CD:~-6%" == "engine" (
    REM Running from engine directory - continue
) ELSE IF "%CD:~-10%" == "kohi-odin" (
    CD engine
    IF ERRORLEVEL 1 (
        ECHO Failed to change directory to engine
        EXIT /B 1
    )
) ELSE (
    ECHO Working directory is invalid: Please run this script from the main project folder or the engine folder.
    EXIT /B 1
)

REM Check if version file exists
IF NOT EXIST "%VERSION_FILE%" (
    ECHO Error: Version file "%VERSION_FILE%" not found
    EXIT /B 1
)

REM Extract version numbers (using KAPI_ prefix to match your file)
FOR /F "tokens=4" %%A IN ('FINDSTR "KAPI_VERSION" "%VERSION_FILE%" 2^>nul') DO SET "MAJORVER=%%A"
FOR /F "tokens=4" %%A IN ('FINDSTR "KAPI_SUBVERSION" "%VERSION_FILE%" 2^>nul') DO SET "SUBVER=%%A"
FOR /F "tokens=4" %%A IN ('FINDSTR "KAPI_REVISION" "%VERSION_FILE%" 2^>nul') DO SET "REVVER=%%A"

REM Validate version numbers
IF "%MAJORVER%"=="" (
    ECHO Error: Could not extract a valid number for KAPI_VERSION
    EXIT /B 1
)
IF "%SUBVER%"=="" (
    ECHO Error: Could not extract a valid number for KAPI_SUBVERSION
    EXIT /B 1
)
IF "%REVVER%"=="" (
    ECHO Error: Could not extract a valid number for KAPI_REVISION
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
ECHO Now compiling library version %MAJORVER%.%SUBVER%.%REVVER%

SET assembly=engine-core
SET compilerFlags=-build-mode:shared -debug
SET outputFile=..\bin\lib%assembly%.dll

REM Check if Odin compiler exists
WHERE odin >nul 2>nul
IF ERRORLEVEL 1 (
    ECHO Odin compiler not found. Please install Odin and try again.
    EXIT /B 1
)

ECHO Building %assembly%...
odin build .\src\core %compilerFlags% -out:%outputFile%

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
    IF "!line!" == "KAPI_VERSION: u8 = !MAJORVER!" (
        ECHO KAPI_VERSION: u8 = %MAJORVER%
    ) ELSE IF "!line:KAPI_VERSION: u8 =!" NEQ "!line!" (
        ECHO KAPI_VERSION: u8 = %MAJORVER%
    ) ELSE IF "!line:KAPI_SUBVERSION: u8 =!" NEQ "!line!" (
        ECHO KAPI_SUBVERSION: u8 = %SUBVER%
    ) ELSE IF "!line:KAPI_REVISION: u16 =!" NEQ "!line!" (
        ECHO KAPI_REVISION: u16 = %REVVER%
    ) ELSE (
        ECHO !line!
    )
)
) > "%VERSION_FILE%.tmp"

MOVE "%VERSION_FILE%.tmp" "%VERSION_FILE%" >nul
GOTO :EOF