#!/bin/bash
#Build script for engine
set -x

mkdir -p ../bin

assembly="engine"
compilerFlags="-build-mode:dll -debug -define:KEXPORT=true"
outputFile="../bin/lib$assembly.so"

if ! command -v odin &> /dev/null; then
    echo "Odin compiler not found. Please install Odin and try again."
    exit 1
fi

odin build ./src ${compilerFlags} -out:${outputFile}