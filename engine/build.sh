#!/bin/bash
#Build script for engine
set -x

BINDIR=../bin
VERSION_FILE="src/core/version.odin"
CURRENTDIR=$(basename "$PWD")

if [[ "$CURRENTDIR" == "engine" || "$CURRENTDIR" == "kohi-odin" ]]; then
    if [[ "$CURRENTDIR" == "kohi-odin" ]]; then
        cd engine || { echo "Failed to change directory to engine"; exit 1; }
    fi
else
    echo "Working directory is invalid: Please run this script from the main project folder or the engine folder."
    exit 1
fi




if [ ! -d "$BINDIR" ]; then
    echo "Creating bin folder"
    mkdir -p ../bin
else
    echo "bin folder found"
fi

OPTIONS=("MAJOR_VERSION" "SUB_VERSION" "REVISION" "NO_UPDATE")

PS3="Select which version number to update for this compilation: "
select opt in "${OPTIONS[@]}"; do
    case $opt in
        "MAJOR_VERSION")
            ((MAJORVER++))
            SUBVER=0
            REVVER=0
            sed -i "s/$MAJSEARCH [0-9]*/$MAJSEARCH $MAJORVER/" "$VERSION_FILE"
            sed -i "s/$SUBSEARCH [0-9]*/$SUBSEARCH $SUBVER/" "$VERSION_FILE"
            sed -i "s/$REVSEARCH [0-9]*/$REVSEARCH $REVVER/" "$VERSION_FILE"
            break
            ;;
        "SUBVERSION")
            ((SUBVER++))
            REVVER=0
            sed -i "s/$SUBSEARCH [0-9]*/$SUBSEARCH $SUBVER/" "$VERSION_FILE"
            sed -i "s/$REVSEARCH [0-9]*/$REVSEARCH $REVVER/" "$VERSION_FILE"
            break
            ;;
        "REVISION")
            ((REVVER++))
            sed -i "s/$REVSEARCH [0-9]*/$REVSEARCH $REVVER/" "$VERSION_FILE"
            break
            ;;
        "NO_UPDATE")
            break
            ;;
        *)
        echo "INVALID OPTION. PLEASE TRY AGAIN"
        ;;
    esac
done

echo ""
echo "Now compiling library version $MAJORVER.$SUBVER.$REVVER"

assembly="engine-core"
compilerFlags="-build-mode:shared -debug"
outputFile="../bin/lib$assembly.so"

if ! command -v odin &> /dev/null; then
    echo "Odin compiler not found. Please install Odin and try again."
    exit 1
fi

odin build ./src/core ${compilerFlags} -out:${outputFile}