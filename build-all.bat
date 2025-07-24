@ECHO OFF
REM Build everything

ECHO "Building everything..."

PUSHD engine
CALL build.bat
POPD
IF %ERRORLEVEL% NEQ 0 (ECHO Error: %ERRORLEVEL% && EXIT)

PUSHD testbed
CALL build.bat
POPD
IF %ERRORLEVEL% NEQ 0 (ECHO Error: %ERRORLEVEL% && EXIT)

ECHO "All builds completed successfully."