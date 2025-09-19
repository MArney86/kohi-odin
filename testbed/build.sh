#!/bin/bash
#Build script for engine
set -x

BINDIR=../bin
VERSION_FILE="src/version.odin"
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


MAJSEARCH="APP_VERSION: u8 ="
MAJORVER=$(grep "$MAJSEARCH" "$VERSION_FILE" | cut -d' ' -f4)
if [[ -z "$MAJORVER" || ! "$MAJORVER" =~ ^[0-9]+$ ]]; then
    echo "Error: Could not extract a valid number for APP_VERSION"
    exit 1
fi
SUBSEARCH="APP_SUBVERSION: u8 ="
SUBVER=$(grep "$SUBSEARCH" "$VERSION_FILE" | cut -d' ' -f4)
if [[ -z "$SUBVER" || ! "$SUBVER" =~ ^[0-9]+$ ]]; then
    echo "Error: Could not extract a valid number for APP_SUBVERSION"
    exit 1
fi
REVSEARCH="APP_REVISION: u16 ="
REVVER=$(grep "$REVSEARCH" "$VERSION_FILE" | cut -d' ' -f4)
if [[ -z "$REVVER" || ! "$REVVER" =~ ^[0-9]+$ ]]; then
    echo "Error: Could not extract a valid number for APP_REVISION"
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

assembly="testbed"
compilerFlags="-build-mode:exe -debug"
outputFile="../bin/$assembly"

if ! command -v odin &> /dev/null; then
    echo "Odin compiler not found. Please install Odin and try again."
    exit 1
fi

odin build ./src ${compilerFlags} -out:${outputFile}

echo "creating APPversion.txt"
echo "$MAJORVER $SUBVER $REVVER" > APPversion.txt