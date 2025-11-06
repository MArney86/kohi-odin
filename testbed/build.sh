#!/bin/bash
#Build script for engine
set -x

BINDIR=../bin
CURRENTDIR=$(basename "$PWD")

if [[ "$CURRENTDIR" == "engine" || "$CURRENTDIR" == "kohi-odin" || "$CURRENTDIR" == "testbed" ]]; then
    if [[ "$CURRENTDIR" == "kohi-odin" ]]; then
        cd testbed || { echo "Failed to change directory to testbed"; exit 1; }
    fi

    if [[ "$CURRENTDIR" == "engine" ]]; then
        cd ../testbed || { echo Failed to change directory to testbed; exit 1; }
    fi
else
    echo "Working directory is invalid: Please run this script from the main project folder or the testbed folder."
    exit 1
fi

if [ ! -d "$BINDIR" ]; then
    echo "Creating bin folder"
    mkdir -p ../bin
else
    echo "bin folder found"
fi

echo "Now compiling library"

assembly="testbed"
compilerFlags="-build-mode:exe -debug"
outputFile="../bin/$assembly"

if ! command -v odin &> /dev/null; then
    echo "Odin compiler not found. Please install Odin and try again."
    exit 1
fi

odin build ./src ${compilerFlags} -out:${outputFile}
