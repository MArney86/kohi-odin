REM Build script for the engine
@ECHO OFF

mkdir ..\bin

SET assembly=engine
REM SET -collection:<name>=<filepath>
SET buildFlags=-build-mode:dll -debug -pdb-name:"../bin/engine.pdb" -define:KEXPORT=true
SET outputFlag=-out:"../bin/engine.dll"

ECHO "Building %assembly% with flags: %buildFlags%"
odin build "./src" %buildFlags% %outputFlag%