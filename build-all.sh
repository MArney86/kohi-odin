#!/bin/bash
# Build script for building everything
set -x

echo "Building Everything..."

pushd engine || exit
source build.sh
popd || exit

pushd testbed || exit
source build.sh
popd || exit

echo "Build completed successfully."