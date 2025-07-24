REM Build script for the testbed
@ECHO OFF

IF NOT EXIST "../bin" mkdir ../bin

SET assembly=testbed
SET buildFlags=-build-mode:exe -debug -pdb-name:"../bin/testbed.pdb"
SET outputFlag=-out:"../bin/testbed.exe"

ECHO "Building %assembly% with flags: %buildFlags%"
odin build "./src" %buildFlags% %outputFlag%