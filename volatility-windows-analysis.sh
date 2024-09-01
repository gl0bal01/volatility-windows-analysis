#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 <memory_dump> [output_directory] [options]"
    echo "  <memory_dump>: Path to the memory dump file"
    echo "  [output_directory]: Optional. Directory to store output (default: volatility_output)"
    echo "Options:"
    echo "  --dump-registry: Run only the Volatility 2 registry dump"
    echo "  --dump-files: Dump file contents from Memory"
    exit 1
}

# Function to run Volatility plugin and handle errors
run_plugin() {
    local plugin="$1"
    local output_file="$2"
    echo "Running: $plugin"
    if ! vol -f "$MEMORY_DUMP" "$plugin" > "$output_file" 2>&1; then
        echo "Warning: Error occurred while running $plugin. Check $output_file for details."
    fi
}

# Function to check if Volatility 2 is available
check_volatility2() {
    if command -v volatility2 &> /dev/null; then
        echo "volatility2"
        return 0
    elif [ -n "$VOLATILITY2_ALIAS" ]; then
        echo "$VOLATILITY2_ALIAS"
        return 0
    else
        return 1
    fi
}

# Function to run Volatility 2 command
run_volatility2() {
    local vol2_cmd=$(check_volatility2)
    if [ $? -eq 0 ]; then
        $vol2_cmd "$@"
    else
        echo "Error: Volatility 2 is not available. Please set the VOLATILITY2_ALIAS environment variable."
        return 1
    fi
}

# Function to dump registry using Volatility 2
dump_registry_vol2() {
    echo "Attempting to dump registry using Volatility 2..."

    # Get profile suggestions
    echo "Determining suggested profiles..."
    SUGGESTED_PROFILES=$(run_volatility2 -f "$MEMORY_DUMP" imageinfo | grep "Suggested Profile(s)" | cut -d ':' -f2 | tr -d ' ')

    if [ -z "$SUGGESTED_PROFILES" ]; then
        echo "Error: Could not determine suggested profiles for Volatility 2."
        return 1
    fi

    echo "Suggested profiles: $SUGGESTED_PROFILES"

    # Allow user to choose profile
    PS3="Select a profile or enter a custom one: "
    select PROFILE in $(echo $SUGGESTED_PROFILES | tr ',' ' ') "Enter custom profile"; do
        case $PROFILE in
            "Enter custom profile")
                read -p "Enter the custom profile name: " CUSTOM_PROFILE
                PROFILE=$CUSTOM_PROFILE
                break
                ;;
            *)
                if [ -n "$PROFILE" ]; then
                    break
                else
                    echo "Invalid selection. Please try again."
                fi
                ;;
        esac
    done

    echo "Using profile: $PROFILE"

    # Dump registry
    echo "Dumping registry..."
    mkdir -p "$OUTPUT_DIR/registry_dump"
    run_volatility2 -f "$MEMORY_DUMP" --profile="$PROFILE" dumpregistry -D "$OUTPUT_DIR/registry_dump"

    echo "Registry dump completed. Check $OUTPUT_DIR/registry_dump for output files."
}

# Function to dump files using Volatility 3
dump_files() {
    echo "Running windows.dumpfiles..."
    mkdir -p "$OUTPUT_DIR/dump_files"
    vol -o "$OUTPUT_DIR/dump_files/" -f "$MEMORY_DUMP" windows.dumpfiles > "$OUTPUT_DIR/dump_files.txt" 2>&1
    echo "File dump completed. Check $OUTPUT_DIR/dump_files for output files."
}

# Parse command line arguments
DUMP_REGISTRY=false
DUMP_FILES=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --dump-registry)
            DUMP_REGISTRY=true
            shift
            ;;
        --dump-files)
            DUMP_FILES=true
            shift
            ;;
        *)
            if [ -z "$MEMORY_DUMP" ]; then
                MEMORY_DUMP="$1"
            elif [ -z "$OUTPUT_DIR" ]; then
                OUTPUT_DIR="$1"
            else
                usage
            fi
            shift
            ;;
    esac
done

# Check if memory dump file is provided
if [ -z "$MEMORY_DUMP" ]; then
    usage
fi

# Set default output directory if not specified
OUTPUT_DIR=${OUTPUT_DIR:-"volatility_output"}

# Check if Volatility 3 is installed
if ! command -v vol &> /dev/null; then
    echo "Error: Volatility 3 (vol) is not installed or not in PATH."
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# If only dump operations are requested, perform them and exit
if [ "$DUMP_REGISTRY" = true ] || [ "$DUMP_FILES" = true ]; then
    [ "$DUMP_REGISTRY" = true ] && dump_registry_vol2
    [ "$DUMP_FILES" = true ] && dump_files
    echo "Requested dump operations completed."
    exit 0
fi

# List of plugins to run
plugins=(
    "windows.info"
    "windows.pslist"
    "windows.psscan"
    "windows.pstree"
    "windows.filescan"
    "windows.dlllist"
    "windows.cmdline"
    "windows.sessions"
    "windows.netscan"
    "windows.netstat"
    "windows.handles"
    "windows.registry.hivelist"
    "windows.registry.printkey"
    "windows.lsadump"
    "windows.driverscan"
    "windows.malfind"
    "windows.modscan"
    "windows.mutantscan"
    "windows.getsids"
    "windows.vadinfo"
    "windows.hashdump"
    "windows.mbrscan"
    "windows.callbacks"
    "windows.envars"
    "windows.ssdt"
    "windows.modules"
    "windows.privileges"
    "windows.svcscan"
    "windows.registry.userassist"
)

echo "Starting comprehensive memory analysis on $MEMORY_DUMP..."
echo "Output will be saved to $OUTPUT_DIR"

# Run all plugins
for plugin in "${plugins[@]}"; do
    output_file="$OUTPUT_DIR/${plugin//windows./}.txt"
    run_plugin "$plugin" "$output_file"
done

# Run strings separately
echo "Running: Memory Strings"
strings "$MEMORY_DUMP" > "$OUTPUT_DIR/strings.txt" 2>&1 || echo "Warning: Error occurred while running strings."

# Calculate MD5 checksum
echo "Calculating MD5 checksum..."
MD5SUM=$(md5sum "$MEMORY_DUMP" | cut -d ' ' -f1)

# Generate summary report
echo "Generating summary report..."
{
    echo "Volatility 3 Analysis Summary"
    echo "=============================="
    echo "Memory Dump: $MEMORY_DUMP"
    echo "MD5 Checksum: $MD5SUM"
    echo "Output Directory: $OUTPUT_DIR"
    echo "Analysis Date: $(date)"
    echo ""
    echo "Plugins Run:"
    for plugin in "${plugins[@]}"; do
        echo "- $plugin"
    done
    echo "- strings"
} > "$OUTPUT_DIR/analysis_summary.txt"

echo "Summary report generated: $OUTPUT_DIR/analysis_summary.txt"

# Ask about dumpfiles
read -p "Do you want to run windows.dumpfiles? This can take a long time. (y/n) " answer
case ${answer:0:1} in
    y|Y )
        dump_files
        ;;
    * )
        echo "Skipping windows.dumpfiles."
        ;;
esac

# Ask about Volatility 2 registry dump
read -p "Do you want to dump the registry using Volatility 2? (y/n) " answer
case ${answer:0:1} in
    y|Y )
        dump_registry_vol2
        ;;
    * )
        echo "Skipping registry dump with Volatility 2."
        ;;
esac

echo "Analysis complete."
