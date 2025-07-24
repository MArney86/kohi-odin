#!/bin/bash
#Build script for testbed
set -x

mkdir -p ../bin

assembly="testbed"
compilerFlags="-build-mode:exe -debug"
outputFile="../bin/$assembly"

if ! command -v odin &> /dev/null; then
    echo "Odin compiler not found. Please install Odin and try again."
    exit 1
fi

odin build ./src ${compilerFlags} -out:${outputFile}