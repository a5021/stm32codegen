#!/bin/bash

: <<'EOC'
https://raw.githubusercontent.com/STMicroelectronics/cmsis-device-h5/refs/heads/main/Include/stm32h503xx.h
https://raw.githubusercontent.com/STMicroelectronics/cmsis-device-h5/refs/heads/main/Include/stm32h5xx.h
https://raw.githubusercontent.com/STMicroelectronics/cmsis-device-h5/refs/heads/main/Include/system_stm32h5xx.h
https://raw.githubusercontent.com/STMicroelectronics/cmsis-device-h5/refs/heads/main/Include/partition_stm32h5xx.h

https://raw.githubusercontent.com/STMicroelectronics/cmsis-device-h5/refs/heads/main/Source/Templates/gcc/linker/STM32H503xx_FLASH.ld
https://raw.githubusercontent.com/STMicroelectronics/cmsis-device-h5/refs/heads/main/Source/Templates/gcc/startup_stm32h503xx.s
https://raw.githubusercontent.com/STMicroelectronics/cmsis-device-h5/refs/heads/main/Source/Templates/system_stm32h5xx.c

https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/develop/CMSIS/Core/Include/core_cm33.h
https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/develop/CMSIS/Core/Include/cmsis_version.h
https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/develop/CMSIS/Core/Include/cmsis_compiler.h
https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/develop/CMSIS/Core/Include/cmsis_gcc.h
https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/develop/CMSIS/Core/Include/mpu_armv8.h
EOC

#!/bin/bash

# Base domain
GITHUB_RAW="https://raw.githubusercontent.com"

# Repositories and branches
REPO1="STMicroelectronics/cmsis-device-h5/refs/heads/main"
REPO2="ARM-software/CMSIS_5/refs/heads/develop"
REPO3="modm-io/cmsis-svd-stm32/refs/heads/main"

# File paths
PATHS1=(
"Include/stm32h503xx.h"
"Include/stm32h5xx.h"
"Include/system_stm32h5xx.h"
"Include/partition_stm32h5xx.h"
"Source/Templates/gcc/linker/STM32H503xx_FLASH.ld"
"Source/Templates/gcc/startup_stm32h503xx.s"
"Source/Templates/system_stm32h5xx.c"
)

PATHS2=(
"CMSIS/Core/Include/core_cm33.h"
"CMSIS/Core/Include/cmsis_version.h"
"CMSIS/Core/Include/cmsis_compiler.h"
"CMSIS/Core/Include/cmsis_gcc.h"
"CMSIS/Core/Include/mpu_armv8.h"
)

PATHS3=(
"stm32h5/STM32H503.svd"
)

# Choose download tool
if command -v curl >/dev/null 2>&1; then
    DOWNLOAD_CMD="curl -fsSL -o"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD_CMD="wget -q -O"
else
    echo "Error: curl or wget is required." >&2
    exit 1
fi

# Function to download files from a repository
download_from_repo() {
    local repo="$1"
    shift
    local paths=("$@")
    for path in "${paths[@]}"; do
        local url="$GITHUB_RAW/$repo/$path"
        local filename=$(basename "$path")
        
        # Determine the destination directory based on file extension
        if [[ "$filename" == *.h ]]; then
            DEST_DIR="inc"
        elif [[ "$filename" == *.c || "$filename" == *.s ]]; then
            DEST_DIR="src"
        else
            DEST_DIR="."
        fi

        # Create destination directory if it doesn't exist
        if [ ! -d "$DEST_DIR" ]; then
            echo "Creating directory $DEST_DIR..."
            mkdir -p "$DEST_DIR"
        fi

        # Check if the file exists and is empty, then re-download
        if [ -f "$DEST_DIR/$filename" ]; then
            if [ ! -s "$DEST_DIR/$filename" ]; then
                echo "File $filename exists but is empty, re-downloading..."
            else
                echo "File $filename already exists, skipping."
                continue
            fi
        else
            echo "Downloading $filename..."
        fi

        # Download the file
        $DOWNLOAD_CMD "$DEST_DIR/$filename" "$url"
        if [ $? -ne 0 ]; then
            echo "Error downloading $filename." >&2
            exit 1
        fi
    done
}

# Download all files
download_from_repo "$REPO1" "${PATHS1[@]}"
download_from_repo "$REPO2" "${PATHS2[@]}"
download_from_repo "$REPO3" "${PATHS3[@]}"

echo "All files downloaded."
