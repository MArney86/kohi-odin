REM Build script for engine
@ECHO OFF
SETLOCAL EnableDelayedExpansion

SET BINDIR=..\bin

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

REM Create bin directory if it doesn't exist
IF NOT EXIST "%BINDIR%" (
    ECHO Creating bin folder
    MKDIR "%BINDIR%" >nul
) ELSE (
    ECHO bin folder found
)

ECHO Now compiling library

SET assembly=engine
SET compilerFlags=-build-mode:shared -debug
SET outputFile=..\bin\kohi_%assembly%.dll

REM Check if Odin compiler exists
WHERE odin >nul 2>nul
IF ERRORLEVEL 1 (
    ECHO Odin compiler not found. Please install Odin and try again.
    EXIT /B 1
)

ECHO Building %assembly%...
odin build .\src %compilerFlags% -out:%outputFile%

IF ERRORLEVEL 1 (
    ECHO Build failed!
    EXIT /B 1
) ELSE (
    ECHO Done.
)

GOTO :EOF